import Foundation
import Testing
@testable import SearchKit

@Suite("Indexing")
struct IndexingTests {

    private var catalog: [SearchDocument] {
        [
            makeDocument(id: "a", title: "A", body: "los actores aíslan estado mutable en swift"),
            makeDocument(id: "b", title: "B", body: "las tablas de una base de datos relacional"),
            makeDocument(id: "c", title: "C", body: "los embeddings representan texto como vectores")
        ]
    }

    @Test func initialSyncIndexesEverything() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            let summary = try await stack.service.sync(documents: catalog)
            #expect(summary == SyncSummary(indexed: 3, removed: 0, unchanged: 0))
            #expect(try await stack.indexStore.chunkCount() == 3)
        }
    }

    @Test func unchangedCatalogIsNotReindexed() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)
            let second = try await stack.service.sync(documents: catalog)
            #expect(second == SyncSummary(indexed: 0, removed: 0, unchanged: 3))
        }
    }

    @Test func modifiedDocumentReindexesOnlyItsSource() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)

            var updated = catalog
            updated[1] = makeDocument(id: "b", title: "B", body: "contenido nuevo sobre índices y consultas")
            let summary = try await stack.service.sync(documents: updated)
            #expect(summary == SyncSummary(indexed: 1, removed: 0, unchanged: 2))

            let outcome = try await stack.service.search("índices consultas", options: SearchOptions(topK: 3))
            #expect(outcome.candidates.first?.documentID == "b")
        }
    }

    @Test func removedDocumentIsDeletedFromIndex() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            try await stack.service.sync(documents: catalog)

            let summary = try await stack.service.sync(documents: Array(catalog.dropLast()))
            #expect(summary == SyncSummary(indexed: 0, removed: 1, unchanged: 2))
            #expect(try await stack.indexStore.chunkCount() == 2)
            #expect(try await stack.indexStore.chunkCount(documentID: "c") == 0)
        }
    }

    @Test func multiChunkDocumentReplacesAllItsChunks() async throws {
        try await withTemporaryDatabase { dbURL in
            let longBody = (0..<250).map { "token\($0)" }.joined(separator: " ")
            let stack = try await makeSearchStack(
                dbURL: dbURL,
                chunking: ChunkingConfiguration(maxTokens: 100, overlap: 20)
            )
            try await stack.service.sync(documents: [
                makeDocument(id: "long", title: "Largo", body: longBody)
            ])
            let initialCount = try await stack.indexStore.chunkCount(documentID: "long")
            #expect(initialCount > 1)

            // Shorter body → fewer chunks; stale chunk IDs must disappear.
            try await stack.service.sync(documents: [
                makeDocument(id: "long", title: "Largo", body: "token0 token1 token2")
            ])
            #expect(try await stack.indexStore.chunkCount(documentID: "long") == 1)
        }
    }

    @Test func syncReportsProgress() async throws {
        try await withTemporaryDatabase { dbURL in
            let stack = try await makeSearchStack(dbURL: dbURL)
            nonisolated(unsafe) var updates: [SyncProgress] = []
            try await stack.service.sync(documents: catalog) { progress in
                updates.append(progress)
            }
            #expect(updates.count == 3)
            #expect(updates.last == SyncProgress(completed: 3, total: 3))
        }
    }
}
