import Foundation

/// Reorders retrieved candidates using a (potentially expensive) signal.
///
/// A reranker is a post-retrieval stage: it never touches the index or the
/// vector space, it only reorders the short fused list (typically 10–50
/// candidates), so per-candidate costs that would be prohibitive at corpus
/// scale — a cross-encoder scoring `(query, candidate)` pairs, an LLM
/// listwise pass, catalog-signal boosts — stay affordable here.
///
/// `SearchService` invokes the reranker after retrieval and **before**
/// deterministic recall, deduplication and filter re-validation, so a
/// reranker can neither suppress an exact-title injection nor resurrect
/// filtered-out candidates. With filters active it only ever receives
/// filter-compliant candidates and does not need to know the filter.
public protocol Reranker: Sendable {
    /// Reorders the candidate list for a query.
    ///
    /// - Parameters:
    ///   - query: The user's free-text query, trimmed.
    ///   - candidates: Retrieved candidates, best first, in the retrieval
    ///     mode's order.
    /// - Returns: The same candidates in the new order. Implementations may
    ///   drop candidates but must not fabricate new ones.
    /// - Throws: Any error from the underlying signal; `SearchService`
    ///   propagates it to the caller (no silent fallback).
    func rerank(query: String, candidates: [SearchCandidate]) async throws -> [SearchCandidate]
}

/// Default implementation: keeps the store's ranking untouched.
public struct NoOpReranker: Reranker {
    /// Creates the no-op reranker.
    public init() {}

    /// Returns `candidates` unchanged.
    ///
    /// - Parameters:
    ///   - query: Ignored.
    ///   - candidates: Retrieved candidates.
    /// - Returns: `candidates`, in the same order.
    public func rerank(query: String, candidates: [SearchCandidate]) async throws -> [SearchCandidate] {
        candidates
    }
}
