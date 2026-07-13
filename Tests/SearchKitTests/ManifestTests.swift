import Foundation
import Testing
@testable import SearchKit

@Suite("EmbeddingSpaceManifest")
struct ManifestTests {

    @Test func makeManifestDefaultsToMeanCentering() async {
        let manifest = await EmbeddingPipeline(provider: FakeEmbeddingProvider()).makeManifest()

        #expect(manifest.transformIdentifier == VectorTransformKind.meanCentering.identifier)
        #expect(manifest.transformVersion == VectorTransformKind.meanCentering.version)
    }

    @Test func makeManifestCanSelectIdentityTransformExplicitly() async {
        let manifest = await EmbeddingPipeline(provider: FakeEmbeddingProvider()).makeManifest(transform: .identity)

        #expect(manifest.transformIdentifier == VectorTransformKind.identity.identifier)
        #expect(manifest.transformVersion == VectorTransformKind.identity.version)
    }

    @Test func manifestSurvivesReopen() async throws {
        try await withTemporaryDatabase { dbURL in
            let provider = FakeEmbeddingProvider()
            let stack = try await makeSearchStack(dbURL: dbURL, provider: provider)
            try await stack.service.sync(documents: [
                makeDocument(id: "a", title: "A", body: "contenido de prueba")
            ])
            #expect(try await stack.indexStore.chunkCount() == 1)

            // Same pipeline → compatible manifest → data preserved.
            let reopened = try await makeSearchStack(dbURL: dbURL, provider: provider)
            #expect(reopened.indexStore.didInvalidatePreviousIndex == false)
            #expect(try await reopened.indexStore.chunkCount() == 1)
        }
    }

    @Test func modelChangeInvalidatesIndex() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL, provider: FakeEmbeddingProvider(modelIdentifier: "model-v1"))
            try await stack.service.sync(documents: [
                makeDocument(id: "a", title: "A", body: "contenido de prueba")
            ])
            #expect(try await stack.indexStore.chunkCount() == 1)

            // Same dimension, different model identifier → wipe, not migrate.
            let reopened = try await makeSearchStack(dbURL: dbURL, provider: FakeEmbeddingProvider(modelIdentifier: "model-v2"))
            #expect(reopened.indexStore.didInvalidatePreviousIndex == true)
            #expect(try await reopened.indexStore.chunkCount() == 0)
            #expect(try await reopened.indexStore.indexedContentHashes().isEmpty)
        }
    }

    @Test func dimensionChangeRecreatesDatabaseFile() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL, provider: FakeEmbeddingProvider(dimension: 64))
            try await stack.service.sync(documents: [
                makeDocument(id: "a", title: "A", body: "contenido de prueba")
            ])

            // Different dimension: VectorStore cannot even open the file
            // (frozen schema) — the store must recreate it.
            let reopened = try await makeSearchStack(dbURL: dbURL, provider: FakeEmbeddingProvider(dimension: 32))
            #expect(reopened.indexStore.didInvalidatePreviousIndex == true)
            #expect(try await reopened.indexStore.chunkCount() == 0)
        }
    }

    @Test func transformChangeInvalidatesIndex() async throws {
        try await withTemporaryDatabase { dbURL in
            let provider = FakeEmbeddingProvider()
            let stack = try await makeSearchStack(dbURL: dbURL, provider: provider)
            try await stack.service.sync(documents: [
                makeDocument(id: "a", title: "A", body: "contenido de prueba")
            ])

            // A future transform would declare its own identifier/version in
            // the manifest; same model and dimension, different vector space.
            let base = await EmbeddingPipeline(provider: provider).makeManifest()
            let manifest = EmbeddingSpaceManifest(
                modelIdentifier: base.modelIdentifier,
                modelRevision: base.modelRevision,
                dimension: base.dimension,
                languageStrategy: base.languageStrategy,
                poolingStrategy: base.poolingStrategy,
                transformIdentifier: "matrix",
                transformVersion: "v1"
            )
            let indexStore = try await SearchIndexStore(dbURL: dbURL, manifest: manifest)
            #expect(indexStore.didInvalidatePreviousIndex == true)
            #expect(try await indexStore.chunkCount() == 0)
        }
    }

    @Test func metricChangeRecreatesDatabaseFile() async throws {
        try await withTemporaryDatabase { dbURL in
            let provider = FakeEmbeddingProvider()
            let stack = try await makeSearchStack(dbURL: dbURL, provider: provider, metric: .cosine)
            try await stack.service.sync(documents: [
                makeDocument(id: "a", title: "A", body: "contenido de prueba")
            ])
            #expect(try await stack.indexStore.chunkCount() == 1)

            // The metric is frozen into the SQLite file: reopening with a
            // different one cannot even open it — the store must recreate it.
            let reopened = try await makeSearchStack(dbURL: dbURL, provider: provider, metric: .l2)
            #expect(reopened.indexStore.didInvalidatePreviousIndex == true)
            #expect(try await reopened.indexStore.chunkCount() == 0)
        }
    }

    @Test func chunkingChangeInvalidatesIndex() async throws {
        try await withTemporaryDatabase { dbURL in
            let provider = FakeEmbeddingProvider()
            let stack = try await makeSearchStack(dbURL: dbURL, provider: provider)
            try await stack.service.sync(documents: [
                makeDocument(id: "a", title: "A", body: "contenido de prueba")
            ])
            #expect(try await stack.indexStore.chunkCount() == 1)

            // Chunking changes are invisible to the contentHash diff — the
            // manifest must invalidate so stale windows never survive.
            let reopened = try await makeSearchStack(
                dbURL: dbURL,
                provider: provider,
                chunking: ChunkingConfiguration(maxTokens: 120, overlap: 24)
            )
            #expect(reopened.indexStore.didInvalidatePreviousIndex == true)
            #expect(try await reopened.indexStore.chunkCount() == 0)
            #expect(try await reopened.indexStore.indexedContentHashes().isEmpty)
        }
    }

    @Test func compatibilityIgnoresCreatedAt() {
        let a = EmbeddingSpaceManifest(
            modelIdentifier: "m", modelRevision: "1", dimension: 64,
            languageStrategy: "s", poolingStrategy: "p",
            transformIdentifier: "identity", transformVersion: "v1",
            createdAt: .distantPast
        )
        let b = EmbeddingSpaceManifest(
            modelIdentifier: "m", modelRevision: "1", dimension: 64,
            languageStrategy: "s", poolingStrategy: "p",
            transformIdentifier: "identity", transformVersion: "v1",
            createdAt: .now
        )
        #expect(a.isCompatible(with: b))
        #expect(a != b)
    }
}
