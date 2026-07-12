import Accessibility
import Foundation
import SwiftUI
import SearchKit

@Observable
final class SearchViewModel {

    enum IndexState: Equatable {
        case starting
        case indexing(completed: Int, total: Int)
        case ready(chunkCount: Int)
        case failed(String)
    }

    private(set) var indexState: IndexState = .starting
    private(set) var results: [SearchCandidate] = []
    private(set) var retrievalMode: RetrievalMode?
    private(set) var requestedMode: SearchMode?
    private(set) var searchErrorMessage: String?
    private(set) var availableFamilies: [String] = []
    var query: String = ""

    // MARK: Search options exposed to the UI

    var searchMode: SearchMode = .auto
    var topK: Int = 10
    var familyFilter: String?
    var languageFilter: String?
    var distanceMetric: IndexDistanceMetric

    private var service: SearchService?
    private var indexStore: SearchIndexStore?
    private let promptBuilder = PromptBuilder()

    private static let metricDefaultsKey = "search.distanceMetric"

    /// Small windows so the short demo corpus (~200-word docs) still splits
    /// into 2–3 overlapping chunks. Passed to BOTH the chunker and the
    /// manifest: changing it invalidates and rebuilds the index.
    private static let chunking = ChunkingConfiguration(maxTokens: 120, overlap: 24)

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.metricDefaultsKey)
        distanceMetric = stored.flatMap(IndexDistanceMetric.init(rawValue:)) ?? .cosine
        // Default to the device language: the corpus is bilingual (es/en
        // twins of every topic), so an unfiltered search wastes half the
        // visible slots on the other language. The user can clear the filter.
        let deviceLanguage = Locale.current.language.languageCode?.identifier
        languageFilter = deviceLanguage == "es" ? "es" : "en"
    }

    // MARK: - Lifecycle

    func start() async {
        indexState = .starting
        do {
            let provider = try ContextualEmbeddingProvider(languageCode: "es")
            let pipeline = EmbeddingPipeline(provider: provider)
            try await pipeline.prepare()

            // Mean-centering counters the anisotropy of the NL model's
            // mean-pooled vectors; switching it on/off rebuilds the index.
            let manifest = await pipeline.makeManifest(
                distanceMetric: distanceMetric,
                chunking: Self.chunking,
                transform: .meanCentering
            )
            let indexStore = try await SearchIndexStore(dbURL: Self.databaseURL(), manifest: manifest)
            let service = SearchService(
                indexStore: indexStore,
                pipeline: pipeline,
                chunker: ChunkingService(configuration: Self.chunking)
            )
            self.indexStore = indexStore
            self.service = service

            let documents = try await BundleCatalogRepository().documents()
            availableFamilies = Set(documents.map(\.family)).sorted()
            indexState = .indexing(completed: 0, total: documents.count)
            try await service.sync(documents: documents) { progress in
                Task { @MainActor [weak self] in
                    self?.indexState = .indexing(completed: progress.completed, total: progress.total)
                }
            }
            indexState = .ready(chunkCount: try await indexStore.chunkCount())
        } catch {
            indexState = .failed(error.localizedDescription)
        }
    }

    /// Debug action: wipes the index file and rebuilds it from the corpus.
    func reindexAll() async {
        service = nil
        indexStore = nil
        if let dbURL = try? Self.databaseURL() {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: dbURL.path + suffix)
            }
        }
        await start()
    }

    /// Persists the metric and reopens the index. No manual file deletion:
    /// the store detects the frozen-schema mismatch, recreates the file and
    /// `sync` re-embeds the whole corpus.
    func applyDistanceMetricChange() async {
        UserDefaults.standard.set(distanceMetric.rawValue, forKey: Self.metricDefaultsKey)
        await start()
        await search()
    }

    // MARK: - Search

    func search() async {
        guard let service else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            retrievalMode = nil
            requestedMode = nil
            searchErrorMessage = nil
            return
        }
        do {
            let options = SearchOptions(
                mode: searchMode,
                topK: topK,
                filter: SearchFilter(family: familyFilter, language: languageFilter)
            )
            let outcome = try await service.search(trimmed, options: options)
            results = outcome.candidates
            retrievalMode = outcome.mode
            requestedMode = outcome.requestedMode
            searchErrorMessage = nil
            // The list content changes without focus movement; tell VoiceOver.
            AccessibilityNotification.Announcement(String(localized: "\(results.count) results")).post()
        } catch is CancellationError {
            // Superseded by a newer query; keep current results.
        } catch SearchSystemError.emptyQuery {
            results = []
            retrievalMode = nil
            requestedMode = nil
        } catch SearchSystemError.textQueryUnusable {
            results = []
            retrievalMode = nil
            requestedMode = nil
            searchErrorMessage = String(localized: "The query does not contain any searchable terms for the selected mode.")
        } catch {
            results = []
            retrievalMode = nil
            requestedMode = nil
            searchErrorMessage = error.localizedDescription
        }
    }

    func ragPrompt(for candidate: SearchCandidate) -> String {
        let language: PromptBuilder.PromptLanguage = candidate.language == "en" ? .english : .spanish
        return promptBuilder.prompt(question: query, candidates: [candidate], language: language)
    }

    // MARK: - Private

    private static func databaseURL() throws -> URL {
        let directory = try FileManager.default
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("SearchIndex", isDirectory: true)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("index.sqlite3")
    }
}
