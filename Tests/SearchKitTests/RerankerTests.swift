import Foundation
import Testing
@testable import SearchKit

/// Reranker whose behavior is a plain closure — enough to simulate
/// reordering, dropping, misbehaving or throwing rerankers.
private struct ClosureReranker: Reranker {
    let body: @Sendable (String, [SearchCandidate]) async throws -> [SearchCandidate]

    func rerank(query: String, candidates: [SearchCandidate]) async throws -> [SearchCandidate] {
        try await body(query, candidates)
    }
}

private struct RerankerError: Error {}

@Suite("Reranker")
struct RerankerTests {

    private var catalog: [SearchDocument] {
        [
            makeDocument(
                id: "coches", title: "Mecánica del coche",
                body: "el coche tiene motor ruedas y frenos que necesitan revisión periódica"
            ),
            makeDocument(
                id: "datos", title: "Bases de datos",
                body: "una base de datos guarda tablas filas y columnas con índices"
            ),
            makeDocument(
                id: "swift", title: "Concurrencia en Swift",
                body: "los actores de swift aíslan estado mutable y evitan data races"
            )
        ]
    }

    @Test func rerankedOrderIsReflectedInResults() async throws {
        try await withTemporaryDatabase { dbURL in
            let reversing = ClosureReranker { _, candidates in candidates.reversed() }
            let stack = try await makeSearchStack(dbURL: dbURL, reranker: reversing)
            try await stack.service.sync(documents: catalog)

            // Separate index file with the default reranker: deterministic
            // chunk IDs make candidates comparable across index files.
            let baselineURL = dbURL.deletingLastPathComponent().appendingPathComponent("baseline.sqlite3")
            let baseline = try await makeSearchStack(dbURL: baselineURL).service
            try await baseline.sync(documents: catalog)

            let plain = try await baseline.search("motor y frenos")
            let reranked = try await stack.service.search("motor y frenos")
            try #require(plain.candidates.count > 1)
            #expect(reranked.candidates == Array(plain.candidates.reversed()))
        }
    }

    @Test func noOpRerankerKeepsRetrievalOrder() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL, reranker: NoOpReranker())
            try await stack.service.sync(documents: catalog)

            let baselineURL = dbURL.deletingLastPathComponent().appendingPathComponent("baseline.sqlite3")
            let baseline = try await makeSearchStack(dbURL: baselineURL).service
            try await baseline.sync(documents: catalog)

            let plain = try await baseline.search("data races en actores")
            let noOp = try await stack.service.search("data races en actores")
            #expect(noOp.candidates == plain.candidates)
        }
    }

    @Test func throwingRerankerPropagates() async throws {
        try await withTemporaryDatabase { dbURL in
            let throwing = ClosureReranker { _, _ in throw RerankerError() }
            let stack = try await makeSearchStack(dbURL: dbURL, reranker: throwing)
            try await stack.service.sync(documents: catalog)

            await #expect(throws: RerankerError.self) {
                _ = try await stack.service.search("motor y frenos")
            }
        }
    }

    @Test func deterministicRecallRunsAfterReranker() async throws {
        try await withTemporaryDatabase { dbURL in
            // A reranker that drops everything cannot suppress the exact-title
            // injection: recall runs after it.
            let droppingAll = ClosureReranker { _, _ in [] }
            let stack = try await makeSearchStack(dbURL: dbURL, reranker: droppingAll)
            try await stack.service.sync(documents: catalog)

            let outcome = try await stack.service.search("mecanica del coche")
            #expect(outcome.candidates.contains { $0.documentID == "coches" })
        }
    }

    @Test func rerankerCannotResurrectFilteredCandidates() async throws {
        try await withTemporaryDatabase { dbURL in
            // A misbehaving reranker fabricating a candidate that violates the
            // active filter must be caught by the final re-validation.
            let smuggled = SearchCandidate(
                id: 999, documentID: "intruso", title: "Intruso", language: "en",
                family: "general", ordinal: 0, content: "Intruso\n\nsmuggled chunk", score: 99
            )
            let smuggling = ClosureReranker { _, candidates in [smuggled] + candidates }
            let stack = try await makeSearchStack(dbURL: dbURL, reranker: smuggling)
            try await stack.service.sync(documents: catalog)

            let options = SearchOptions(filter: SearchFilter(language: "es"))
            let outcome = try await stack.service.search("motor y frenos", options: options)
            #expect(!outcome.candidates.contains { $0.documentID == "intruso" })
        }
    }

    @Test func duplicatesReturnedByRerankerAreDeduplicated() async throws {
        try await withTemporaryDatabase { dbURL in
            let duplicating = ClosureReranker { _, candidates in candidates + candidates }
            let stack = try await makeSearchStack(dbURL: dbURL, reranker: duplicating)
            try await stack.service.sync(documents: catalog)

            let outcome = try await stack.service.search("motor y frenos")
            let ids = outcome.candidates.map(\.id)
            #expect(ids.count == Set(ids).count)
        }
    }
}
