import CryptoKit
import Foundation

/// A source document from the catalog: one lesson or article.
/// `contentHash` covers the full raw file (front matter included) so that
/// title/metadata edits also trigger reingestion of the document.
public struct SearchDocument: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let title: String
    /// BCP-47-style language code, e.g. "es" or "en".
    public let language: String
    /// Content family grouping, used by deterministic recall rules.
    public let family: String
    public let body: String
    public let contentHash: String

    public init(id: String, title: String, language: String, family: String, body: String, contentHash: String) {
        self.id = id
        self.title = title
        self.language = language
        self.family = family
        self.body = body
        self.contentHash = contentHash
    }

    /// SHA-256 hex digest used as the canonical content hash.
    public static func hash(of raw: String) -> String {
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
