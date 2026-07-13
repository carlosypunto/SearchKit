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
/// Reports hit@1/3/5 and MRR@10 per retrieval mode (vector / text / hybrid,
/// plus `.auto` — the demo app's path, asserted to never silently degrade)
/// and per language over a hand-built gold set, then a per-query rank table
/// so marginal hits (rank 4–5) are visible. The printed tables are the
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
        /// "title" | "paraphrase" | "lexical" | "stem-free" — what the query
        /// is probing. "stem-free" queries share no exact token with their
        /// target document (verified against FTS5 unicode61 folding), so BM25
        /// cannot find them — they isolate the vector branch's contribution.
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
        // Spanish — stem-free paraphrases (zero exact-token overlap with the
        // target doc; BM25-blind by construction, only the vector branch can
        // score the target directly).
        GoldQuery(query: "trabajar con datos que quizá no estén presentes", expectedDocumentID: "es-optionals", language: "es", kind: "stem-free"),
        GoldQuery(query: "convertir oraciones en listas de decimales comparables", expectedDocumentID: "es-embeddings", language: "es", kind: "stem-free"),
        GoldQuery(query: "guardar un trozo de lógica para ejecutarlo luego", expectedDocumentID: "es-closures", language: "es", kind: "stem-free"),
        GoldQuery(query: "reaccionar cuando una operación sale mal y avisar a quien llama", expectedDocumentID: "es-error-handling", language: "es", kind: "stem-free"),

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
        GoldQuery(query: "chunk overlap sliding window", expectedDocumentID: "en-chunking", language: "en", kind: "lexical"),
        // English — stem-free paraphrases (see the Spanish block).
        GoldQuery(query: "turn a phrase into numbers whose distance reflects its meaning", expectedDocumentID: "en-embeddings", language: "en", kind: "stem-free"),
        GoldQuery(query: "a piece of behavior that remembers surrounding variables", expectedDocumentID: "en-closures", language: "en", kind: "stem-free"),
        GoldQuery(query: "put an application and everything it needs inside a lightweight box", expectedDocumentID: "en-docker", language: "en", kind: "stem-free"),
        GoldQuery(query: "recovering when something goes wrong at runtime", expectedDocumentID: "en-error-handling", language: "en", kind: "stem-free")
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
        /// Rank (1-based) of the expected document per gold query, aligned
        /// with `goldSet` order; nil = absent from the top 10.
        var ranks: [Int?] = []
        var misses: [(GoldQuery, top: [String])] = []

        var label: String { mode.rawValue + (languageFiltered ? "+lf" : "") }
        var count: Int { ranks.count }

        func hitRate(at cutoff: Int, language: String? = nil) -> Double {
            let scoped = zip(goldSet, ranks).filter { language == nil || $0.0.language == language }
            guard !scoped.isEmpty else { return 0 }
            let hits = scoped.count { if let rank = $0.1 { rank <= cutoff } else { false } }
            return Double(hits) / Double(scoped.count)
        }

        var mrrAt10: Double {
            count == 0 ? 0 : ranks.map { $0.map { 1.0 / Double($0) } ?? 0 }.reduce(0, +) / Double(count)
        }
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
            // `.auto` is the mode the demo app actually runs in; it must never
            // silently degrade on gold queries (they all have usable FTS terms).
            var reports: [ModeReport] = []
            for mode in [SearchMode.vector, .text, .hybrid, .auto] {
                for languageFiltered in [false, true] {
                    var report = ModeReport(mode: mode, languageFiltered: languageFiltered)
                    for gold in Self.goldSet {
                        let filter = languageFiltered ? SearchFilter(language: gold.language) : SearchFilter()
                        let outcome = try await service.search(
                            gold.query,
                            options: SearchOptions(mode: mode, topK: 10, filter: filter)
                        )
                        if mode == .auto {
                            #expect(outcome.mode == .hybrid,
                                    "auto degraded to \(outcome.mode) for \"\(gold.query)\"")
                        }
                        let ids = outcome.candidates.map(\.documentID)
                        // First rank (1-based) at which any chunk of the expected doc appears.
                        let rank = ids.firstIndex(of: gold.expectedDocumentID).map { $0 + 1 }
                        report.ranks.append(rank)
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
                #expect(report.hitRate(at: 5) > 0, "mode \(report.mode) found nothing from the gold set")
            }
        }
    }

    private static func printTable(_ reports: [ModeReport]) {
        func pct(_ value: Double) -> String { String(format: "%5.1f%%", value * 100) }
        func f3(_ value: Double) -> String { String(format: "%.3f", value) }
        func pad(_ text: String, _ length: Int) -> String {
            text.count >= length ? String(text.prefix(length)) : text.padding(toLength: length, withPad: " ", startingAt: 0)
        }

        print("")
        print("[eval] gold set: \(goldSet.count) queries — hit@k / MRR@10")
        print("[eval] mode        hit@1   hit@3   hit@5   MRR@10   es hit@5   en hit@5")
        for report in reports {
            print("[eval] \(pad(report.label, 10)) "
                + "\(pct(report.hitRate(at: 1)))  \(pct(report.hitRate(at: 3)))  \(pct(report.hitRate(at: 5)))  "
                + "\(f3(report.mrrAt10))     \(pct(report.hitRate(at: 5, language: "es")))     "
                + "\(pct(report.hitRate(at: 5, language: "en")))")
        }

        // Per-query rank of the expected document ("-" = not in top 10), one
        // column per mode variant: makes marginal hits (rank 4–5) visible,
        // not just misses.
        print("")
        let header = reports.map { pad($0.label, 9) }.joined(separator: " ")
        print("[eval] \(pad("rank of expected doc (- = not in top 10)", 53))\(header)")
        for (index, gold) in goldSet.enumerated() {
            let cells = reports
                .map { $0.ranks[index].map(String.init) ?? "-" }
                .map { pad($0, 9) }
                .joined(separator: " ")
            print("[eval] [\(pad(gold.kind, 9))] \(pad(gold.query, 40)) \(cells)")
        }

        for report in reports where !report.misses.isEmpty {
            print("[eval] misses in \(report.label):")
            for (gold, top) in report.misses {
                print("[eval]   [\(gold.kind)] \"\(gold.query)\" expected \(gold.expectedDocumentID), top: \(top.joined(separator: ", "))")
            }
        }
        print("")
    }
}
