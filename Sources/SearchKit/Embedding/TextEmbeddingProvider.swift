import Foundation

/// On-device text embedding source. Implementations decide the model and the
/// pooling strategy; they must always return `[Float]` of exactly `dimension`
/// elements. The store never sees the provider.
public protocol TextEmbeddingProvider: Sendable {
    var modelIdentifier: String { get async }
    var modelRevision: String { get async }
    var poolingStrategy: String { get async }
    var dimension: Int { get async }

    /// Ensures model assets are available (may download on first use).
    func prepare() async throws

    /// Embeds a single text. `language` is a BCP-47-style hint ("es", "en")
    /// or nil to let the model infer it.
    func embedding(for text: String, language: String?) async throws -> [Float]
}
