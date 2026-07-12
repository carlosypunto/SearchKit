import Foundation

/// How a set of candidates was retrieved. Anything other than `.hybrid`
/// means the service degraded to a fallback path.
public enum RetrievalMode: String, Sendable, Equatable {
    case hybrid
    case vectorOnly
    case textOnly
}

/// A retrieval result mapped to the domain.
///
/// `score` is always "higher = better", but its scale depends on the mode:
/// RRF score for hybrid, negated distance for vector-only, negated BM25 for
/// text-only. Scores from different modes must not be compared.
public struct SearchCandidate: Sendable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let documentID: String
    public let title: String
    public let language: String
    public let family: String
    public let ordinal: Int
    public let content: String
    public let score: Double
    /// 1-based rank in the vector result list (hybrid mode only).
    public let vectorRank: Int?
    /// 1-based rank in the lexical result list (hybrid mode only).
    public let textRank: Int?
    /// Raw store measure: vector distance in vector-only mode, BM25 in
    /// text-only mode, nil in hybrid mode (which only has the RRF score).
    public let rawDistance: Double?

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
    public let candidates: [SearchCandidate]
    public let mode: RetrievalMode
    public let requestedMode: SearchMode

    public init(candidates: [SearchCandidate], mode: RetrievalMode, requestedMode: SearchMode = .auto) {
        self.candidates = candidates
        self.mode = mode
        self.requestedMode = requestedMode
    }
}
