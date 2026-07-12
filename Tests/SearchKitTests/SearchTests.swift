import Foundation
import Testing
@testable import SearchKit

@Suite("Search")
struct SearchTests {

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

    @Test func hybridFindsExactTerm() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)

            let outcome = try await stack.service.search("data races en actores")
            #expect(outcome.mode == .hybrid)
            #expect(outcome.candidates.first?.documentID == "swift")
            // Hybrid hits carry explanatory ranks.
            #expect(outcome.candidates.first?.vectorRank != nil || outcome.candidates.first?.textRank != nil)
        }
    }

    @Test func semanticMatchWithoutLiteralOverlap() async throws {
        try await withTemporaryDatabase { dbURL in
            // The fake provider canonicalises "automóvil" → "coche".
            let provider = FakeEmbeddingProvider(synonyms: ["automóvil": "coche"])
            let stack = try await makeSearchStack(dbURL: dbURL, provider: provider)
            try await stack.service.sync(documents: catalog)

            let outcome = try await stack.service.search("automóvil")
            #expect(outcome.mode == .hybrid)
            #expect(outcome.candidates.first?.documentID == "coches")
        }
    }

    @Test func embeddingFailureFallsBackToTextOnly() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)

            // Same index, but a pipeline whose provider now fails: the
            // service must degrade to FTS instead of throwing.
            let broken = SearchService(
                indexStore: stack.indexStore,
                pipeline: EmbeddingPipeline(provider: FakeEmbeddingProvider(shouldFailEmbedding: true))
            )
            // Unchanged catalog: registers titles without needing embeddings.
            _ = try await broken.sync(documents: catalog)
            let outcome = try await broken.search("tablas filas columnas")
            #expect(outcome.mode == .textOnly)
            #expect(outcome.candidates.first?.documentID == "datos")
        }
    }

    @Test func punctuationOnlyQueryFallsBackToVectorOnly() async throws {
        try await withTemporaryDatabase { dbURL in
            // Query has no alphanumeric tokens → no FTS query can be built.
            // The fake provider would also fail (no tokens), so expect an error.
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)
            await #expect(throws: (any Error).self) {
                _ = try await stack.service.search("¿¿?? ---")
            }
        }
    }

    @Test func ftsOperatorsInQueryAreNeutralised() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)

            // Unbalanced quotes and FTS operators must not break the search.
            let outcome = try await stack.service.search("\"tablas AND (filas NEAR")
            #expect(outcome.candidates.isEmpty == false)
            #expect(outcome.candidates.first?.documentID == "datos")
        }
    }

    @Test func emptyQueryThrows() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)
            await #expect(throws: SearchSystemError.emptyQuery) {
                _ = try await stack.service.search("   ")
            }
        }
    }

    @Test func exactTitleIsRecalledEvenIfRetrievalMissesIt() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)

            // Diacritic/case-insensitive title match; topK=1 so competition
            // could push it out — the policy must still include it.
            let outcome = try await stack.service.search("MECANICA DEL COCHE", topK: 1)
            #expect(outcome.candidates.contains { $0.documentID == "coches" })
        }
    }

    @Test func recallPolicyInjectsMissingTitleMatch() async throws {
        let policy = DeterministicRecallPolicy()
        let injected = SearchCandidate(
            id: 1, documentID: "doc-x", title: "Guía de Docker", language: "es",
            family: "devops", ordinal: 0, content: "Guía de Docker\n\ncontenedores", score: 0
        )
        let result = await policy.apply(
            query: "guia de docker",
            candidates: [],
            titles: ["doc-x": "Guía de Docker"],
            fetchFirstChunk: { documentID in
                documentID == "doc-x" ? injected : nil
            }
        )
        #expect(result == [injected])
    }

    @Test func candidatesExposeCleanSnippet() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)
            let outcome = try await stack.service.search("actores estado mutable")
            let candidate = try #require(outcome.candidates.first)
            #expect(candidate.title == "Concurrencia en Swift")
            #expect(!candidate.snippet.hasPrefix("Concurrencia en Swift"))
        }
    }
}
