import Foundation

/// Consumer-side pipeline errors, kept separate from the store's `SQLiteError`
/// so UI/recovery code can distinguish embedding/manifest problems from
/// storage problems.
public enum SearchSystemError: Error, Sendable, Equatable {
    /// No `NLContextualEmbedding` model exists for the requested language
    /// code (the associated value).
    case missingEmbeddingModel(String)
    /// The model exists but its assets are not downloaded/usable on this
    /// device (always the case on the iOS Simulator).
    case embeddingAssetsUnavailable
    /// The provider could not produce a vector (empty text, no tokens,
    /// zero-norm result…).
    case embeddingGenerationFailed
    /// The provider returned a vector whose size does not match the
    /// manifest dimension.
    case embeddingDimensionMismatch(expected: Int, got: Int)
    /// The persisted manifest (or centroid) could not be decoded; the index
    /// is treated as an unknown vector space and wiped.
    case manifestDecodingFailed
    /// The query is empty or whitespace-only.
    case emptyQuery
    /// A forced text/hybrid search cannot run because the query has no
    /// usable FTS terms (e.g. punctuation only).
    case textQueryUnusable
}
