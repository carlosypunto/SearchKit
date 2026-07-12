import Foundation

/// Requested retrieval mode. `.auto` keeps the fallback tree
/// (hybrid → vectorOnly/textOnly); the other modes force a single path and
/// surface their failures instead of degrading.
public enum SearchMode: String, Sendable, CaseIterable, Equatable {
    case auto
    case hybrid
    case vector
    case text
}

/// Metadata filters applied by the store via `json_extract` on the chunk
/// metadata JSON, in every retrieval mode.
public struct SearchFilter: Sendable, Equatable {
    public var family: String?
    public var language: String?

    public init(family: String? = nil, language: String? = nil) {
        self.family = family
        self.language = language
    }

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
    public var mode: SearchMode
    public var topK: Int
    public var filter: SearchFilter

    public init(mode: SearchMode = .auto, topK: Int = 10, filter: SearchFilter = SearchFilter()) {
        self.mode = mode
        self.topK = topK
        self.filter = filter
    }
}
