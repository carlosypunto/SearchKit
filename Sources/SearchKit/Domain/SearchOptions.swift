import Foundation

/// Requested retrieval mode. `.auto` keeps the fallback tree
/// (hybrid → vectorOnly/textOnly); the other modes force a single path and
/// surface their failures instead of degrading.
public enum SearchMode: String, Sendable, CaseIterable, Equatable {
    /// Hybrid retrieval with controlled degradation (the recommended default).
    case auto
    /// Force hybrid fusion; throws instead of falling back.
    case hybrid
    /// Force vector KNN only; throws instead of falling back.
    case vector
    /// Force FTS5/BM25 only; works without the embedding model.
    case text
}

/// Metadata filters applied by the store via `json_extract` on the chunk
/// metadata JSON, in every retrieval mode.
public struct SearchFilter: Sendable, Equatable {
    /// Keep only chunks whose document family equals this value; nil = any.
    public var family: String?
    /// Keep only chunks in this language ("es", "en"); nil = any. Also used
    /// as the query's embedding-language hint.
    public var language: String?

    /// Creates a filter; both criteria are optional and combined with AND.
    ///
    /// - Parameters:
    ///   - family: Content family to require, or nil for any.
    ///   - language: BCP-47-style language code to require, or nil for any.
    public init(family: String? = nil, language: String? = nil) {
        self.family = family
        self.language = language
    }

    /// True when the filter imposes no constraint.
    public var isEmpty: Bool { family == nil && language == nil }

    /// Domain-side check, used to re-validate candidates injected after the
    /// SQL filter ran (deterministic recall).
    func allows(_ candidate: SearchCandidate) -> Bool {
        (family == nil || candidate.family == family)
            && (language == nil || candidate.language == language)
    }
}

/// Per-query knobs for `SearchService.search`.
public struct SearchOptions: Sendable, Equatable {
    /// Requested retrieval mode; see ``SearchMode``.
    public var mode: SearchMode
    /// Maximum number of candidates to return.
    public var topK: Int
    /// Metadata filter applied in every retrieval mode.
    public var filter: SearchFilter

    /// Creates search options.
    ///
    /// - Parameters:
    ///   - mode: Requested retrieval mode.
    ///   - topK: Maximum number of candidates to return.
    ///   - filter: Metadata filter; ``SearchFilter/init(family:language:)``
    ///     with no arguments means unfiltered.
    public init(mode: SearchMode = .auto, topK: Int = 10, filter: SearchFilter = SearchFilter()) {
        self.mode = mode
        self.topK = topK
        self.filter = filter
    }
}
