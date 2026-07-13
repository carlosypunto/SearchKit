import Foundation

/// On-device text embedding source. Implementations decide the model and the
/// pooling strategy; they must always return `[Float]` of exactly `dimension`
/// elements. The store never sees the provider.
public protocol TextEmbeddingProvider: Sendable {
    /// Identifier of the underlying model, recorded in the manifest.
    var modelIdentifier: String { get async }
    /// Revision of the underlying model, recorded in the manifest.
    var modelRevision: String { get async }
    /// Label of the token-to-sentence pooling recipe, recorded in the manifest.
    var poolingStrategy: String { get async }
    /// Number of components in every vector this provider returns.
    var dimension: Int { get async }

    /// Ensures model assets are available (may download on first use).
    ///
    /// - Throws: An error when the assets cannot be obtained
    ///   (`SearchSystemError.embeddingAssetsUnavailable` for the real provider).
    func prepare() async throws

    /// Embeds a single text.
    ///
    /// - Parameters:
    ///   - text: Text to embed.
    ///   - language: BCP-47-style hint ("es", "en") or nil to let the model
    ///     infer it.
    /// - Returns: A vector of exactly ``dimension`` elements.
    /// - Throws: An error when no vector can be produced
    ///   (`SearchSystemError.embeddingGenerationFailed` for the real provider).
    func embedding(for text: String, language: String?) async throws -> [Float]
}
