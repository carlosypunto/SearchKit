import Foundation
import Testing
@testable import SearchKit

/// Retrieval-quality evaluation against the real example-app corpus and the
/// real `NLContextualEmbedding` model. Opt-in (needs model assets; macOS or a
/// real device, never the iOS Simulator) and slow (~250 chunk embeddings).
/// Run with:
///
///     SEARCHKIT_EVAL=1 swift test --filter Evaluation
///
/// Reports hit@5 and MRR@10 per forced retrieval mode (vector / text / hybrid)
/// and per language over a hand-built gold set. The printed table is the
/// deliverable; assertions are loose sanity floors only. Use it as a baseline
/// before and after any change to embeddings, chunking, or fusion.
@Suite(
    "Evaluation",
    .enabled(if: ProcessInfo.processInfo.environment["SEARCHKIT_EVAL"] == "1")
)
struct EvaluationTests {

    // MARK: - Gold set

    struct GoldQuery {
        let query: String
        let expectedDocumentID: String
        let language: String
        /// "title" | "paraphrase" | "lexical" — what the query is probing.
        let kind: String
    }

    /// Queries are grounded in the demo corpus (`DocumentsCorpus/`). A hit is
    /// any chunk of the expected document; the language-specific twin counts
    /// as a miss on purpose, so cross-language crowding shows up in the table.
    static let goldSet: [GoldQuery] = [
        // Spanish — exact titles (deterministic recall should also fire).
        GoldQuery(query: "Actores y aislamiento de estado", expectedDocumentID: "es-actors", language: "es", kind: "title"),
        GoldQuery(query: "Búsqueda híbrida y fusión RRF", expectedDocumentID: "es-hybrid-search", language: "es", kind: "title"),
        // Spanish — paraphrases (vector-favoring, no literal overlap).
        GoldQuery(query: "cómo evitar data races con estado mutable compartido", expectedDocumentID: "es-actors", language: "es", kind: "paraphrase"),
        GoldQuery(query: "descargar muchas imágenes a la vez en paralelo", expectedDocumentID: "es-task-groups", language: "es", kind: "paraphrase"),
        GoldQuery(query: "combinar resultados de búsqueda semántica y léxica", expectedDocumentID: "es-hybrid-search", language: "es", kind: "paraphrase"),
        GoldQuery(query: "manejar la ausencia de valor sin punteros nulos", expectedDocumentID: "es-optionals", language: "es", kind: "paraphrase"),
        GoldQuery(query: "contenedores ligeros frente a máquinas virtuales", expectedDocumentID: "es-docker", language: "es", kind: "paraphrase"),
        // Spanish — exact/lexical terms (BM25-favoring).
        GoldQuery(query: "ranking BM25 tabla virtual SQLite", expectedDocumentID: "es-fts5", language: "es", kind: "lexical"),
        GoldQuery(query: "withTaskGroup addTask", expectedDocumentID: "es-task-groups", language: "es", kind: "lexical"),
        // Spanish — morphological variant ("reentrada" in the body).
        GoldQuery(query: "actores reentrantes", expectedDocumentID: "es-actors", language: "es", kind: "lexical"),

        // English — exact title.
        GoldQuery(query: "Hybrid Search with Reciprocal Rank Fusion", expectedDocumentID: "en-hybrid-search", language: "en", kind: "title"),
        // English — paraphrases.
        GoldQuery(query: "protecting shared mutable state from data races", expectedDocumentID: "en-actors", language: "en", kind: "paraphrase"),
        GoldQuery(query: "merge lexical and semantic rankings into one list", expectedDocumentID: "en-hybrid-search", language: "en", kind: "paraphrase"),
        GoldQuery(query: "map sentences into dense vectors", expectedDocumentID: "en-embeddings", language: "en", kind: "paraphrase"),
        GoldQuery(query: "find the K nearest vectors to a query", expectedDocumentID: "en-vector-databases", language: "en", kind: "paraphrase"),
        // English — exact/lexical terms.
        GoldQuery(query: "subword tokenization rare words", expectedDocumentID: "en-tokenization", language: "en", kind: "lexical"),
        GoldQuery(query: "rebase versus merge", expectedDocumentID: "en-git-branching", language: "en", kind: "lexical"),
        GoldQuery(query: "chunk overlap sliding window", expectedDocumentID: "en-chunking", language: "en", kind: "lexical")
    ]

    // MARK: - Corpus loading

    /// The demo corpus lives outside the package (in the example app). This
    /// suite is opt-in and local-only, so a `#filePath`-relative URL is fine.
    static func corpusDirectory() -> URL {
        URL(fileURLWithPath: #filePath)          // …/Tests/SearchKitTests/EvaluationTests.swift
            .deletingLastPathComponent()         // …/Tests/SearchKitTests
            .deletingLastPathComponent()         // …/Tests
            .deletingLastPathComponent()         // package root
            .appendingPathComponent("SearchKitExample/SearchKitExample/DocumentsCorpus", isDirectory: true)
    }

    static func loadCorpus() throws -> [SearchDocument] {
        let directory = corpusDirectory()
        let urls = try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try urls.map { url in
            let raw = try String(contentsOf: url, encoding: .utf8)
            return try FrontMatterParser.document(fromRaw: raw, fallbackID: url.deletingPathExtension().lastPathComponent)
        }
    }

    // MARK: - Metrics

    struct ModeReport {
        let mode: SearchMode
        let languageFiltered: Bool
        var hits5 = 0
        var reciprocalRanks: [Double] = []
        var perLanguageHits5: [String: Int] = [:]
        var perLanguageCounts: [String: Int] = [:]
        var misses: [(GoldQuery, top: [String])] = []

        var count: Int { reciprocalRanks.count }
        var hitAt5: Double { count == 0 ? 0 : Double(hits5) / Double(count) }
        var mrrAt10: Double { count == 0 ? 0 : reciprocalRanks.reduce(0, +) / Double(count) }
    }

    // MARK: - Test

    @Test func retrievalQualityBaseline() async throws {
        let documents = try Self.loadCorpus()
        #expect(documents.count > 90, "expected the full bilingual demo corpus")

        try await withTemporaryDatabase { dbURL in
            // Mirror the example app's stack exactly (SearchViewModel.start).
            let chunking = ChunkingConfiguration(maxTokens: 120, overlap: 24)
            let provider = try ContextualEmbeddingProvider(languageCode: "es")
            let pipeline = EmbeddingPipeline(provider: provider)
            try await pipeline.prepare()
            let manifest = await pipeline.makeManifest(chunking: chunking, transform: .meanCentering)
            let indexStore = try await SearchIndexStore(dbURL: dbURL, manifest: manifest)
            let service = SearchService(
                indexStore: indexStore,
                pipeline: pipeline,
                chunker: ChunkingService(configuration: chunking)
            )

            let syncStart = ContinuousClock.now
            try await service.sync(documents: documents)
            let chunkCount = try await indexStore.chunkCount()
            print("[eval] indexed \(documents.count) docs, \(chunkCount) chunks in \(ContinuousClock.now - syncStart)")

            // Unfiltered = raw package behavior; language-filtered = what the
            // demo app does by default (filter matches the query's language).
            var reports: [ModeReport] = []
            for mode in [SearchMode.vector, .text, .hybrid] {
                for languageFiltered in [false, true] {
                    var report = ModeReport(mode: mode, languageFiltered: languageFiltered)
                    for gold in Self.goldSet {
                        let filter = languageFiltered ? SearchFilter(language: gold.language) : SearchFilter()
                        let outcome = try await service.search(
                            gold.query,
                            options: SearchOptions(mode: mode, topK: 10, filter: filter)
                        )
                        let ids = outcome.candidates.map(\.documentID)
                        // First rank (1-based) at which any chunk of the expected doc appears.
                        let rank = ids.firstIndex(of: gold.expectedDocumentID).map { $0 + 1 }

                        report.perLanguageCounts[gold.language, default: 0] += 1
                        if let rank, rank <= 5 {
                            report.hits5 += 1
                            report.perLanguageHits5[gold.language, default: 0] += 1
                        }
                        report.reciprocalRanks.append(rank.map { 1.0 / Double($0) } ?? 0)
                        if rank == nil || rank! > 5 {
                            report.misses.append((gold, top: Array(ids.prefix(3))))
                        }
                    }
                    reports.append(report)
                }
            }

            Self.printTable(reports)

            // Loose sanity floors — the table above is the real deliverable.
            for report in reports {
                #expect(report.hitAt5 > 0, "mode \(report.mode) found nothing from the gold set")
            }
        }
    }

    private static func printTable(_ reports: [ModeReport]) {
        func pct(_ value: Double) -> String { String(format: "%5.1f%%", value * 100) }
        func f3(_ value: Double) -> String { String(format: "%.3f", value) }

        print("")
        print("[eval] gold set: \(goldSet.count) queries — hit@5 / MRR@10")
        print("[eval] mode         hit@5   MRR@10   es hit@5   en hit@5")
        for report in reports {
            let esCount = report.perLanguageCounts["es", default: 0]
            let enCount = report.perLanguageCounts["en", default: 0]
            let esHit = esCount == 0 ? 0 : Double(report.perLanguageHits5["es", default: 0]) / Double(esCount)
            let enHit = enCount == 0 ? 0 : Double(report.perLanguageHits5["en", default: 0]) / Double(enCount)
            let label = report.mode.rawValue + (report.languageFiltered ? "+lf" : "")
            print("[eval] \(label.padding(toLength: 10, withPad: " ", startingAt: 0)) "
                + "\(pct(report.hitAt5))  \(f3(report.mrrAt10))     \(pct(esHit))     \(pct(enHit))")
        }
        for report in reports where !report.misses.isEmpty {
            let label = report.mode.rawValue + (report.languageFiltered ? "+lf" : "")
            print("[eval] misses in \(label):")
            for (gold, top) in report.misses {
                print("[eval]   [\(gold.kind)] \"\(gold.query)\" expected \(gold.expectedDocumentID), top: \(top.joined(separator: ", "))")
            }
        }
        print("")
    }
}
