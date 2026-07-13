import Foundation
import Testing
@testable import SearchKit

/// Integration test against the real `NLContextualEmbedding` model. Opt-in
/// because it needs model assets on the machine (macOS or a real device;
/// never the iOS Simulator). Run with:
///
///     SEARCHKIT_REAL_EMBEDDING=1 swift test --filter RealEmbedding
///
@Suite(
    "RealEmbedding",
    .enabled(if: ProcessInfo.processInfo.environment["SEARCHKIT_REAL_EMBEDDING"] == "1")
)
struct RealEmbeddingIntegrationTests {

    @Test func indexesAndFindsParaphrasedQueries() async throws {
        try await withTemporaryDatabase { dbURL in
            let provider = try ContextualEmbeddingProvider(languageCode: "es")
            let pipeline = EmbeddingPipeline(provider: provider)
            try await pipeline.prepare()

            let manifest = await pipeline.makeManifest()
            let indexStore = try await SearchIndexStore(dbURL: dbURL, manifest: manifest)
            let service = SearchService(indexStore: indexStore, pipeline: pipeline)

            let documents = [
                makeDocument(
                    id: "actores", title: "Actores en Swift", language: "es", family: "swift",
                    body: "Los actores serializan el acceso a su estado mutable y evitan condiciones de carrera en programas concurrentes."
                ),
                makeDocument(
                    id: "recetas", title: "Cocina mediterránea", language: "es", family: "cocina",
                    body: "El aceite de oliva, el tomate y el pescado fresco forman la base de la dieta mediterránea tradicional."
                ),
                makeDocument(
                    id: "embeddings", title: "Text Embeddings", language: "en", family: "ai",
                    body: "Embedding models map sentences into dense vectors so that semantically similar texts end up close together."
                )
            ]
            try await service.sync(documents: documents)
            #expect(try await indexStore.chunkCount() == 3)

            // Paraphrase in Spanish: no literal overlap with "actores" body wording.
            let concurrent = try await service.search(
                "evitar data races con concurrencia",
                options: SearchOptions(topK: 2)
            )
            #expect(concurrent.candidates.first?.documentID == "actores")

            // Cross-language: English query should still rank the English doc first.
            let english = try await service.search(
                "vector representation of sentences",
                options: SearchOptions(topK: 2)
            )
            #expect(english.candidates.first?.documentID == "embeddings")

            print("[real-embedding] model=\(await provider.modelIdentifier) rev=\(await provider.modelRevision) dim=\(await provider.dimension)")
        }
    }
}
