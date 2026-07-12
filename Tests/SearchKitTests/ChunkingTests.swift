import Foundation
import Testing
@testable import SearchKit

@Suite("Chunking")
struct ChunkingTests {

    private func longBody(words: Int) -> String {
        (0..<words).map { "palabra\($0)" }.joined(separator: " ")
    }

    @Test func sameDocumentProducesSameChunkIDs() {
        let document = makeDocument(id: "doc-1", title: "Título", body: longBody(words: 900))
        let chunker = ChunkingService()
        let first = chunker.chunks(for: document)
        let second = chunker.chunks(for: document)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(first.map(\.content) == second.map(\.content))
    }

    @Test func longDocumentProducesMultipleOverlappingChunks() {
        let config = ChunkingConfiguration(maxTokens: 100, overlap: 20)
        let document = makeDocument(id: "doc-1", title: "Título", body: longBody(words: 250))
        let chunks = ChunkingService(configuration: config).chunks(for: document)
        #expect(chunks.count > 1)
        #expect(chunks.map(\.ordinal) == Array(0..<chunks.count))
        // Overlap: last words of chunk N appear in chunk N+1.
        #expect(chunks[1].content.contains("palabra80"))
    }

    @Test func chunkIDsAreStableAndPositive() {
        let a = ChunkingService.stableChunkID(documentID: "doc-1", ordinal: 0)
        let b = ChunkingService.stableChunkID(documentID: "doc-1", ordinal: 0)
        let c = ChunkingService.stableChunkID(documentID: "doc-1", ordinal: 1)
        let d = ChunkingService.stableChunkID(documentID: "doc-2", ordinal: 0)
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)
        #expect(a > 0 && c > 0 && d > 0)
    }

    @Test func chunkContentIncludesTitlePrefix() {
        let document = makeDocument(id: "doc-1", title: "Concurrencia en Swift", body: "Los actores aíslan estado mutable.")
        let chunks = ChunkingService().chunks(for: document)
        #expect(chunks.count == 1)
        #expect(chunks[0].content.hasPrefix("Concurrencia en Swift"))
        #expect(chunks[0].content.contains("actores"))
    }

    @Test func emptyBodyProducesNoChunks() {
        let document = makeDocument(id: "doc-1", title: "Título", body: "")
        #expect(ChunkingService().chunks(for: document).isEmpty)
    }

    @Test func changedContentChangesHash() {
        let a = makeDocument(id: "doc-1", title: "Título", body: "contenido original")
        let b = makeDocument(id: "doc-1", title: "Título", body: "contenido modificado")
        #expect(a.contentHash != b.contentHash)
    }
}
