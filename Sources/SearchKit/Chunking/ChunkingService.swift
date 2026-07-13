import Foundation
internal import NaturalLanguage

/// Sliding-window parameters for ``ChunkingService``. Part of the persisted
/// ``EmbeddingSpaceManifest`` — changing either value invalidates the index.
public struct ChunkingConfiguration: Sendable, Equatable {
    /// Maximum word tokens per chunk window.
    public let maxTokens: Int
    /// Word tokens shared between consecutive windows.
    public let overlap: Int

    /// Creates a configuration.
    ///
    /// - Parameters:
    ///   - maxTokens: Window size in word tokens; must exceed `overlap`.
    ///   - overlap: Tokens shared between consecutive windows.
    /// - Precondition: `maxTokens > overlap`.
    public init(maxTokens: Int = 400, overlap: Int = 50) {
        precondition(maxTokens > overlap, "overlap must be smaller than maxTokens")
        self.maxTokens = maxTokens
        self.overlap = overlap
    }
}

/// Splits documents into overlapping word-token windows with deterministic,
/// stable chunk IDs: the same document always yields the same IDs, which keeps
/// per-document reingestion (`delete(source:)` + `insertBatch`) idempotent.
public struct ChunkingService: Sendable {
    /// The window/overlap parameters this service splits with.
    public let configuration: ChunkingConfiguration

    /// Creates a chunking service.
    ///
    /// - Parameter configuration: Window parameters. Pass the **same** value
    ///   to `EmbeddingPipeline.makeManifest(chunking:)` — the manifest must
    ///   describe how the rows were actually chunked.
    public init(configuration: ChunkingConfiguration = ChunkingConfiguration()) {
        self.configuration = configuration
    }

    /// Splits a document into overlapping windows.
    ///
    /// - Parameter document: The catalog document to split.
    /// - Returns: Chunks in document order, each with a deterministic ID and
    ///   the document title prepended to its content (so the title
    ///   participates in both FTS and embeddings). Empty for an empty body.
    public func chunks(for document: SearchDocument) -> [SearchChunk] {
        let pieces = split(document.body)
        return pieces.enumerated().map { ordinal, window in
            // Prepend the title so it participates in both FTS and embeddings.
            let content = document.title + "\n\n" + window
            return SearchChunk(
                id: Self.stableChunkID(documentID: document.id, ordinal: ordinal),
                documentID: document.id,
                title: document.title,
                language: document.language,
                family: document.family,
                ordinal: ordinal,
                content: content
            )
        }
    }

    /// 63-bit FNV-1a hash of "documentID#ordinal". Collision probability is
    /// negligible for catalogs of thousands of chunks; IDs stay positive so
    /// they are valid SQLite rowids.
    ///
    /// - Parameters:
    ///   - documentID: Identifier of the owning document.
    ///   - ordinal: 0-based chunk position within the document.
    /// - Returns: The same positive ID for the same inputs, always — this
    ///   determinism is what makes per-document reingestion idempotent.
    public static func stableChunkID(documentID: String, ordinal: Int) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in "\(documentID)#\(ordinal)".utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(bitPattern: UInt(hash & 0x7FFF_FFFF_FFFF_FFFF))
    }

    private func split(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(range)
            return true
        }
        guard !tokens.isEmpty else { return [] }

        var chunks: [String] = []
        var start = 0
        while start < tokens.count {
            let end = min(start + configuration.maxTokens, tokens.count)
            let chunkRange = tokens[start].lowerBound..<tokens[end - 1].upperBound
            chunks.append(String(text[chunkRange]))
            start += configuration.maxTokens - configuration.overlap
        }
        return chunks
    }
}
