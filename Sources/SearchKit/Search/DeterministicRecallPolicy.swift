import Foundation

/// Deterministic post-retrieval rule: when the query is an exact (case- and
/// diacritic-insensitive) document title, that document must appear in the
/// results even if hybrid retrieval missed it. Explicit and testable; more
/// rules (families, slugs, catalog relations) are post-MVP.
public struct DeterministicRecallPolicy: Sendable {

    /// Creates the policy (stateless).
    public init() {}

    /// Injects exact-title matches that retrieval missed.
    ///
    /// - Parameters:
    ///   - query: The user's query, compared case/diacritic-insensitively
    ///     against every title.
    ///   - candidates: The ranked list retrieval produced.
    ///   - titles: documentID → title map for the current catalog.
    ///   - fetchFirstChunk: Loads a representative chunk for an injected document.
    /// - Returns: `candidates`, with any missing exact-title document's first
    ///   chunk inserted at the front. Injected candidates bypass the SQL
    ///   filter, so `SearchService` re-validates the final list.
    public func apply(
        query: String,
        candidates: [SearchCandidate],
        titles: [String: String],
        fetchFirstChunk: (String) async throws -> SearchCandidate?
    ) async rethrows -> [SearchCandidate] {
        let normalizedQuery = Self.normalize(query)
        guard !normalizedQuery.isEmpty else { return candidates }

        var result = candidates
        for (documentID, title) in titles where Self.normalize(title) == normalizedQuery {
            guard !result.contains(where: { $0.documentID == documentID }) else { continue }
            if let injected = try await fetchFirstChunk(documentID) {
                result.insert(injected, at: 0)
            }
        }
        return result
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
