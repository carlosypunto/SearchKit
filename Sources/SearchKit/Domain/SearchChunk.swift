import Foundation

/// Compact per-chunk metadata persisted as JSON in `VectorEntry.metadata`.
/// Must stay well under the store's 16 KB metadata byte limit.
public struct ChunkMetadata: Sendable, Equatable, Codable {
    /// Identifier of the ``SearchDocument`` the chunk belongs to.
    public let documentID: String
    /// Title of the owning document.
    public let title: String
    /// BCP-47-style language code of the owning document.
    public let language: String
    /// Content family of the owning document.
    public let family: String
    /// 0-based position of the chunk within its document.
    public let ordinal: Int

    /// Creates the metadata payload persisted next to a chunk.
    ///
    /// - Parameters:
    ///   - documentID: Identifier of the owning ``SearchDocument``.
    ///   - title: Title of the owning document.
    ///   - language: BCP-47-style language code.
    ///   - family: Content family grouping.
    ///   - ordinal: 0-based chunk position within the document.
    public init(documentID: String, title: String, language: String, family: String, ordinal: Int) {
        self.documentID = documentID
        self.title = title
        self.language = language
        self.family = family
        self.ordinal = ordinal
    }
}

/// A chunk of a document, ready to be embedded and indexed.
/// `id` is deterministic: the same document always produces the same chunk IDs.
public struct SearchChunk: Sendable, Equatable, Identifiable {
    /// Deterministic 63-bit ID (see ``ChunkingService/stableChunkID(documentID:ordinal:)``),
    /// used directly as the SQLite rowid.
    public let id: Int
    /// Identifier of the ``SearchDocument`` the chunk belongs to.
    public let documentID: String
    /// Title of the owning document.
    public let title: String
    /// BCP-47-style language code, used as the embedding hint at indexing time.
    public let language: String
    /// Content family of the owning document.
    public let family: String
    /// 0-based position of the chunk within its document.
    public let ordinal: Int
    /// Text that gets embedded and FTS-indexed (the document title is
    /// prepended to the window by ``ChunkingService``).
    public let content: String

    /// Creates a chunk. Prefer ``ChunkingService/chunks(for:)``, which
    /// derives every field consistently from a ``SearchDocument``.
    ///
    /// - Parameters:
    ///   - id: Deterministic chunk ID (valid positive SQLite rowid).
    ///   - documentID: Identifier of the owning document.
    ///   - title: Title of the owning document.
    ///   - language: BCP-47-style language code.
    ///   - family: Content family grouping.
    ///   - ordinal: 0-based chunk position within the document.
    ///   - content: Text to embed and index.
    public init(id: Int, documentID: String, title: String, language: String, family: String, ordinal: Int, content: String) {
        self.id = id
        self.documentID = documentID
        self.title = title
        self.language = language
        self.family = family
        self.ordinal = ordinal
        self.content = content
    }

    /// The ``ChunkMetadata`` payload persisted next to this chunk in the store.
    public var metadata: ChunkMetadata {
        ChunkMetadata(documentID: documentID, title: title, language: language, family: family, ordinal: ordinal)
    }
}
