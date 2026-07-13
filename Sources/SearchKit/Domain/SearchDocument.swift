import CryptoKit
import Foundation

/// A source document from the catalog: one lesson or article.
/// `contentHash` covers the full raw file (front matter included) so that
/// title/metadata edits also trigger reingestion of the document.
public struct SearchDocument: Sendable, Equatable, Codable, Identifiable {
    /// Stable catalog identifier, e.g. the resource file name without extension.
    public let id: String
    /// Human-readable title; exact matches trigger ``DeterministicRecallPolicy``.
    public let title: String
    /// BCP-47-style language code, e.g. "es" or "en".
    public let language: String
    /// Content family grouping, used by deterministic recall rules.
    public let family: String
    /// Full document text to be chunked and embedded (front matter stripped).
    public let body: String
    /// Canonical hash of the raw file; see ``hash(of:)``.
    public let contentHash: String

    /// Creates a catalog document.
    ///
    /// - Parameters:
    ///   - id: Stable catalog identifier.
    ///   - title: Human-readable title.
    ///   - language: BCP-47-style language code ("es", "en").
    ///   - family: Content family grouping.
    ///   - body: Full text to be chunked and embedded.
    ///   - contentHash: Canonical content hash, normally ``hash(of:)`` over
    ///     the entire raw file so metadata edits also trigger reingestion.
    public init(id: String, title: String, language: String, family: String, body: String, contentHash: String) {
        self.id = id
        self.title = title
        self.language = language
        self.family = family
        self.body = body
        self.contentHash = contentHash
    }

    /// SHA-256 hex digest used as the canonical content hash.
    ///
    /// - Parameter raw: The exact string to hash — pass the *entire* raw file
    ///   (front matter included) so metadata-only edits change the hash.
    /// - Returns: Lowercase hex-encoded SHA-256 digest of `raw`.
    public static func hash(of raw: String) -> String {
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
