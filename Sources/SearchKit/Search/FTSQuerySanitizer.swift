import Foundation

/// Converts free user text into a safe FTS5 query: each token is quoted (so
/// FTS5 operators and punctuation lose special meaning) and tokens are joined
/// with OR for ranked-union recall — BM25 still rewards rows matching more terms.
enum FTSQuerySanitizer {
    /// Returns nil when the text contains no usable tokens.
    static func sanitize(_ text: String) -> String? {
        let tokens = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }
        return tokens.map { "\"\($0)\"" }.joined(separator: " OR ")
    }
}
