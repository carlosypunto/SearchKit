import Foundation

/// Deterministic post-retrieval rule: when the query is an exact (case- and
/// diacritic-insensitive) document title, that document must appear in the
/// results even if hybrid retrieval missed it. Explicit and testable; more
/// rules (families, slugs, catalog relations) are post-MVP.
public struct DeterministicRecallPolicy: Sendable {

    public init() {}

    /// - Parameters:
    ///   - titles: documentID → title map for the current catalog.
    ///   - fetchFirstChunk: loads a representative chunk for an injected document.
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
