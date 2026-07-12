import Foundation

/// Compact per-chunk metadata persisted as JSON in `VectorEntry.metadata`.
/// Must stay well under the store's 16 KB metadata byte limit.
public struct ChunkMetadata: Sendable, Equatable, Codable {
    public let documentID: String
    public let title: String
    public let language: String
    public let family: String
    public let ordinal: Int

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
    public let id: Int
    public let documentID: String
    public let title: String
    public let language: String
    public let family: String
    public let ordinal: Int
    public let content: String

    public init(id: Int, documentID: String, title: String, language: String, family: String, ordinal: Int, content: String) {
        self.id = id
        self.documentID = documentID
        self.title = title
        self.language = language
        self.family = family
        self.ordinal = ordinal
        self.content = content
    }

    public var metadata: ChunkMetadata {
        ChunkMetadata(documentID: documentID, title: title, language: language, family: family, ordinal: ordinal)
    }
}
