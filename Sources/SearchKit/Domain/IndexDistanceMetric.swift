import Foundation

/// Distance metric for the vector index. Mirrors the store's metric enum,
/// which is not re-exported; `rawValue` is what the manifest persists.
/// Changing the metric recreates the index file (the store freezes it into
/// the SQLite schema) and forces a full re-embed on the next sync.
public enum IndexDistanceMetric: String, Sendable, CaseIterable, Equatable {
    /// Cosine distance — the right choice for L2-normalized embeddings.
    case cosine
    /// Euclidean (L2) distance.
    case l2
}
