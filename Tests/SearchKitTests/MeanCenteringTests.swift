import Foundation
import Testing
@testable import SearchKit

@Suite("MeanCentering")
struct MeanCenteringTests {

    // MARK: - Transform math

    @Test func centroidIsComponentWiseMean() {
        let centroid = VectorTransform.centroid(of: [[1, 0, 3], [3, 2, 1]])
        #expect(centroid == [2, 1, 2])
        #expect(VectorTransform.centroid(of: []) == nil)
    }

    @Test func meanCenterSubtractsAndRenormalizes() {
        let centered = VectorTransform.meanCenter([3, 4], centroid: [3, 0])
        #expect(centered == [0, 1])
        // A vector equal to the centroid has no direction left: raw fallback.
        #expect(VectorTransform.meanCenter([1, 2], centroid: [1, 2]) == [1, 2])
    }

    // MARK: - Pipeline integration

    private func makeCenteredStack(dbURL: URL, provider: FakeEmbeddingProvider = FakeEmbeddingProvider()) async throws -> SearchStack {
        let pipeline = EmbeddingPipeline(provider: provider)
        let manifest = await pipeline.makeManifest(transform: .meanCentering)
        let indexStore = try await SearchIndexStore(dbURL: dbURL, manifest: manifest)
        let service = SearchService(indexStore: indexStore, pipeline: pipeline)
        return SearchStack(service: service, indexStore: indexStore, pipeline: pipeline)
    }

    @Test func syncStoresCentroidAndSearchStillFindsDocuments() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeCenteredStack(dbURL: dbURL)
            try await stack.service.sync(documents: [
                makeDocument(id: "coches", title: "Coches", body: "El coche eléctrico moderno usa baterías de litio."),
                makeDocument(id: "cocina", title: "Cocina", body: "La paella valenciana lleva arroz azafrán y pollo.")
            ])

            let centroid = try await stack.indexStore.storedCentroid()
            #expect(centroid != nil)
            #expect(centroid?.count == 64)

            // Query and index vectors go through the same centering, so
            // retrieval keeps working end to end.
            let outcome = try await stack.service.search("paella arroz", options: SearchOptions(mode: .vector, topK: 1))
            #expect(outcome.candidates.first?.documentID == "cocina")
        }
    }

    @Test func incrementalSyncReusesFrozenCentroid() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeCenteredStack(dbURL: dbURL)
            let initial = [
                makeDocument(id: "a", title: "A", body: "gatos perros animales domésticos"),
                makeDocument(id: "b", title: "B", body: "planetas estrellas galaxias universo")
            ]
            try await stack.service.sync(documents: initial)
            let frozen = try await stack.indexStore.storedCentroid()

            // Adding a document must not move the centroid of the generation.
            let extended = initial + [makeDocument(id: "c", title: "C", body: "barcos puertos mareas océanos")]
            let summary = try await stack.service.sync(documents: extended)
            #expect(summary.indexed == 1)
            #expect(try await stack.indexStore.storedCentroid() == frozen)

            // The new document is searchable in the frozen space.
            let outcome = try await stack.service.search("océanos mareas", options: SearchOptions(mode: .vector, topK: 1))
            #expect(outcome.candidates.first?.documentID == "c")
        }
    }

    @Test func identityIndexIsInvalidatedWhenCenteringIsEnabled() async throws {
        try await withTemporaryDatabase { dbURL in
            let identity = try await makeSearchStack(dbURL: dbURL)
            try await identity.service.sync(documents: [
                makeDocument(id: "doc", title: "Doc", body: "contenido cualquiera para indexar")
            ])
            #expect(try await identity.indexStore.chunkCount() == 1)

            // Reopening the same file with the mean-centering manifest is a
            // semantic mismatch: the index wipes and rebuilds from scratch.
            let centered = try await makeCenteredStack(dbURL: dbURL)
            #expect(centered.indexStore.didInvalidatePreviousIndex)
            #expect(try await centered.indexStore.chunkCount() == 0)
        }
    }
}
