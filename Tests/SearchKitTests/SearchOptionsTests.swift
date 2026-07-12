import Foundation
import Testing
@testable import SearchKit

@Suite("SearchOptions")
struct SearchOptionsTests {

    /// Two families and two languages; "rendimiento" appears in every body so
    /// lexical matches exist in all of them and filters do the narrowing.
    private func makeCatalog() -> [SearchDocument] {
        [
            makeDocument(
                id: "actors", title: "Actores en Swift", language: "es", family: "concurrencia",
                body: "Los actores protegen el estado y mejoran el rendimiento del código concurrente."
            ),
            makeDocument(
                id: "sqlite", title: "Índices en SQLite", language: "es", family: "datos",
                body: "Los índices mejoran el rendimiento de las consultas en SQLite."
            ),
            makeDocument(
                id: "fts", title: "Full text search", language: "en", family: "datos",
                body: "FTS5 improves the search rendimiento using the BM25 ranking algorithm."
            )
        ]
    }

    private func makeSyncedStack(dbURL: URL, provider: FakeEmbeddingProvider = FakeEmbeddingProvider()) async throws -> SearchStack {
        let stack = try await makeSearchStack(dbURL: dbURL)
        try await stack.service.sync(documents: makeCatalog())
        // Recreate the service with the (possibly failing) provider but reuse
        // the already-populated index, mirroring SearchTests' fallback setup.
        guard provider.shouldFailEmbedding else { return stack }
        let pipeline = EmbeddingPipeline(provider: provider)
        let service = SearchService(indexStore: stack.indexStore, pipeline: pipeline)
        try await service.sync(documents: makeCatalog())
        return SearchStack(service: service, indexStore: stack.indexStore, pipeline: pipeline)
    }

    // MARK: - Forced modes

    @Test func forcedTextWorksWithoutEmbedding() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(
                dbURL: dbURL,
                provider: FakeEmbeddingProvider(shouldFailEmbedding: true)
            )
            let outcome = try await stack.service.search(
                "rendimiento",
                options: SearchOptions(mode: .text)
            )
            #expect(outcome.mode == .textOnly)
            #expect(!outcome.candidates.isEmpty)
        }
    }

    @Test func forcedVectorPropagatesEmbeddingFailure() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(
                dbURL: dbURL,
                provider: FakeEmbeddingProvider(shouldFailEmbedding: true)
            )
            await #expect(throws: SearchSystemError.embeddingGenerationFailed) {
                _ = try await stack.service.search("rendimiento", options: SearchOptions(mode: .vector))
            }
        }
    }

    @Test func forcedVectorIgnoresFTSOperators() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            let outcome = try await stack.service.search(
                "rendimiento AND (",
                options: SearchOptions(mode: .vector)
            )
            #expect(outcome.mode == .vectorOnly)
            #expect(!outcome.candidates.isEmpty)
        }
    }

    @Test func forcedHybridThrowsOnPunctuationOnlyQuery() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            await #expect(throws: SearchSystemError.textQueryUnusable) {
                _ = try await stack.service.search("¿¿?? --", options: SearchOptions(mode: .hybrid))
            }
        }
    }

    @Test func forcedTextThrowsOnPunctuationOnlyQuery() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            await #expect(throws: SearchSystemError.textQueryUnusable) {
                _ = try await stack.service.search("¿¿?? --", options: SearchOptions(mode: .text))
            }
        }
    }

    // MARK: - Filters (exercise json_extract via the store's `where:` in all paths)

    @Test func familyFilterRestrictsResultsInAllModes() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            for mode in [SearchMode.hybrid, .vector, .text] {
                let outcome = try await stack.service.search(
                    "rendimiento",
                    options: SearchOptions(mode: mode, filter: SearchFilter(family: "datos"))
                )
                #expect(!outcome.candidates.isEmpty, "mode \(mode) returned nothing")
                #expect(outcome.candidates.allSatisfy { $0.family == "datos" }, "mode \(mode) leaked other families")
            }
        }
    }

    @Test func languageFilterRestrictsResults() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            let outcome = try await stack.service.search(
                "rendimiento",
                options: SearchOptions(filter: SearchFilter(language: "en"))
            )
            #expect(!outcome.candidates.isEmpty)
            #expect(outcome.candidates.allSatisfy { $0.language == "en" })
        }
    }

    @Test func filterMayReturnFewerThanTopK() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            let outcome = try await stack.service.search(
                "rendimiento",
                options: SearchOptions(topK: 10, filter: SearchFilter(family: "concurrencia"))
            )
            // Only one single-chunk document matches the filter: fewer than
            // topK results is the expected outcome, not an error.
            #expect(outcome.candidates.count == 1)
            #expect(outcome.candidates.allSatisfy { $0.family == "concurrencia" })
        }
    }

    @Test func recallInjectionRespectsFilter() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            // Exact-title query for a "datos" document, filtered to another
            // family: deterministic recall must not bypass the filter.
            let outcome = try await stack.service.search(
                "Índices en SQLite",
                options: SearchOptions(filter: SearchFilter(family: "concurrencia"))
            )
            #expect(outcome.candidates.allSatisfy { $0.documentID != "sqlite" })
        }
    }

    // MARK: - Outcome metadata

    @Test func outcomeCarriesRequestedMode() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            let auto = try await stack.service.search("rendimiento")
            #expect(auto.requestedMode == .auto)
            #expect(auto.mode == .hybrid)

            let forced = try await stack.service.search("rendimiento", options: SearchOptions(mode: .text))
            #expect(forced.requestedMode == .text)
            #expect(forced.mode == .textOnly)
        }
    }

    @Test func rawDistanceExposedInSingleModes() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSyncedStack(dbURL: dbURL)
            let vector = try await stack.service.search("rendimiento", options: SearchOptions(mode: .vector))
            #expect(vector.candidates.allSatisfy { $0.rawDistance != nil })

            let text = try await stack.service.search("rendimiento", options: SearchOptions(mode: .text))
            #expect(text.candidates.allSatisfy { $0.rawDistance != nil })

            let hybrid = try await stack.service.search("rendimiento", options: SearchOptions(mode: .hybrid))
            #expect(hybrid.candidates.allSatisfy { $0.rawDistance == nil })
        }
    }
}
