import Foundation

/// Consumer-side pipeline errors, kept separate from the store's `SQLiteError`
/// so UI/recovery code can distinguish embedding/manifest problems from
/// storage problems.
public enum SearchSystemError: Error, Sendable, Equatable {
    case missingEmbeddingModel(String)
    case embeddingAssetsUnavailable
    case embeddingGenerationFailed
    case embeddingDimensionMismatch(expected: Int, got: Int)
    case manifestDecodingFailed
    case emptyQuery
    /// A forced text/hybrid search cannot run because the query has no
    /// usable FTS terms (e.g. punctuation only).
    case textQueryUnusable
}
