import Foundation

/// How a set of candidates was retrieved. Anything other than `.hybrid`
/// means the service degraded to a fallback path.
public enum RetrievalMode: String, Sendable, Equatable {
    /// Weighted RRF fusion of the vector KNN and FTS5/BM25 rank lists.
    case hybrid
    /// Vector KNN only (in `.auto`, the fallback when the query has no
    /// usable FTS terms or the FTS query fails).
    case vectorOnly
    /// FTS5/BM25 only (in `.auto`, the fallback when embedding fails).
    case textOnly
}

/// A retrieval result mapped to the domain.
///
/// `score` is always "higher = better", but its scale depends on the mode:
/// RRF score for hybrid, negated distance for vector-only, negated BM25 for
/// text-only. Scores from different modes must not be compared.
public struct SearchCandidate: Sendable, Equatable, Hashable, Identifiable {
    /// The matched chunk's deterministic ID (SQLite rowid).
    public let id: Int
    /// Identifier of the document the chunk belongs to.
    public let documentID: String
    /// Title of the owning document.
    public let title: String
    /// BCP-47-style language code of the chunk.
    public let language: String
    /// Content family of the owning document.
    public let family: String
    /// 0-based position of the chunk within its document.
    public let ordinal: Int
    /// Indexed chunk text (title prefix included); see ``bodyText``/``snippet``
    /// for display-ready variants.
    public let content: String
    /// Ranking score — higher is better, but the scale is mode-specific and
    /// must never be compared across modes.
    public let score: Double
    /// 1-based rank in the vector result list (hybrid mode only).
    public let vectorRank: Int?
    /// 1-based rank in the lexical result list (hybrid mode only).
    public let textRank: Int?
    /// Raw store measure: vector distance in vector-only mode, BM25 in
    /// text-only mode, nil in hybrid mode (which only has the RRF score).
    public let rawDistance: Double?

    /// Creates a candidate. Normally produced by ``SearchIndexStore``; the
    /// public initializer exists for tests and previews.
    ///
    /// - Parameters:
    ///   - id: Matched chunk ID.
    ///   - documentID: Identifier of the owning document.
    ///   - title: Title of the owning document.
    ///   - language: BCP-47-style language code.
    ///   - family: Content family grouping.
    ///   - ordinal: 0-based chunk position within the document.
    ///   - content: Indexed chunk text.
    ///   - score: Mode-specific ranking score (higher is better).
    ///   - vectorRank: 1-based vector-branch rank (hybrid only).
    ///   - textRank: 1-based lexical-branch rank (hybrid only).
    ///   - rawDistance: Raw distance/BM25 measure (single-branch modes only).
    public init(
        id: Int,
        documentID: String,
        title: String,
        language: String,
        family: String,
        ordinal: Int,
        content: String,
        score: Double,
        vectorRank: Int? = nil,
        textRank: Int? = nil,
        rawDistance: Double? = nil
    ) {
        self.id = id
        self.documentID = documentID
        self.title = title
        self.language = language
        self.family = family
        self.ordinal = ordinal
        self.content = content
        self.score = score
        self.vectorRank = vectorRank
        self.textRank = textRank
        self.rawDistance = rawDistance
    }

    /// Chunk text without the title prefix added at indexing time.
    public var bodyText: String {
        if content.hasPrefix(title) {
            return String(content.dropFirst(title.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return content
    }

    /// Short single-line preview for result lists.
    public var snippet: String {
        let flattened = bodyText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > 160 else { return flattened }
        return String(flattened.prefix(160)) + "…"
    }
}

/// Final result of a query: ranked candidates plus the mode actually used.
/// `requestedMode` lets callers distinguish an `.auto` degradation from an
/// explicitly forced mode.
public struct SearchOutcome: Sendable, Equatable {
    /// Ranked candidates, best first, at most `topK` entries.
    public let candidates: [SearchCandidate]
    /// The retrieval mode actually used to produce ``candidates``.
    public let mode: RetrievalMode
    /// The mode the caller asked for; compare with ``mode`` to detect
    /// an `.auto` degradation.
    public let requestedMode: SearchMode

    /// Creates an outcome. Normally produced by ``SearchService/search(_:options:)``.
    ///
    /// - Parameters:
    ///   - candidates: Ranked candidates, best first.
    ///   - mode: Retrieval mode actually used.
    ///   - requestedMode: Mode the caller asked for.
    public init(candidates: [SearchCandidate], mode: RetrievalMode, requestedMode: SearchMode = .auto) {
        self.candidates = candidates
        self.mode = mode
        self.requestedMode = requestedMode
    }
}
