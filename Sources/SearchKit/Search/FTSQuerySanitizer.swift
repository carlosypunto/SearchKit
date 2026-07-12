import Foundation

/// Converts free user text into a safe FTS5 query: each token is quoted (so
/// FTS5 operators and punctuation lose special meaning) and tokens are joined
/// with OR for ranked-union recall — BM25 still rewards rows matching more terms.
///
/// Stopwords and single-character tokens are dropped first: they match nearly
/// every chunk, and the rank noise they add to the BM25 list degrades RRF
/// fusion. If nothing survives the cut, the raw tokens are used instead, so a
/// stopword-only query still gets lexical recall.
enum FTSQuerySanitizer {

    /// Minimal es+en function-word list. Content words must never appear here.
    private static let stopwords: Set<String> = [
        // Spanish
        "a", "al", "como", "cómo", "con", "cual", "cuál", "cuando", "cuándo",
        "de", "del", "donde", "dónde", "el", "en", "es", "esta", "este", "esto",
        "la", "las", "lo", "los", "más", "mi", "muy", "no", "o", "para", "pero",
        "por", "que", "qué", "se", "si", "sí", "sin", "son", "su", "sus", "un",
        "una", "y", "ya",
        // English
        "an", "and", "are", "as", "at", "be", "by", "for", "from", "how", "in",
        "into", "is", "it", "its", "of", "on", "or", "that", "the", "this",
        "to", "was", "were", "what", "when", "where", "which", "with"
    ]

    /// Returns nil when the text contains no usable tokens.
    static func sanitize(_ text: String) -> String? {
        let tokens = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }
        let meaningful = tokens.filter { $0.count > 1 && !stopwords.contains($0.lowercased()) }
        let selected = meaningful.isEmpty ? tokens : meaningful
        return selected.map { "\"\($0)\"" }.joined(separator: " OR ")
    }
}
