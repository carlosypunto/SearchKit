import Foundation
@preconcurrency internal import NaturalLanguage

/// `NLContextualEmbedding`-backed provider. A single Latin-script model serves
/// both Spanish and English in one vector space, so the whole catalog lives in
/// one store with one dimension.
///
/// Not available on the iOS Simulator; works on real devices and on macOS.
public actor ContextualEmbeddingProvider: TextEmbeddingProvider {

    private let model: NLContextualEmbedding

    /// - Parameter languageCode: BCP-47-style code used to pick the model
    ///   (e.g. "es" resolves to the Latin-script model, which also covers "en").
    public init(languageCode: String = "es") throws {
        guard let model = NLContextualEmbedding(language: NLLanguage(rawValue: languageCode)) else {
            throw SearchSystemError.missingEmbeddingModel(languageCode)
        }
        self.model = model
    }

    /// Identifier reported by `NLContextualEmbedding`.
    public var modelIdentifier: String { model.modelIdentifier }
    /// Model revision reported by `NLContextualEmbedding`.
    public var modelRevision: String { String(model.revision) }
    /// Fixed pooling recipe: mean pooling over token vectors + L2 norm.
    public var poolingStrategy: String { "mean-pooling+l2norm:v1" }
    /// Vector size of the underlying model (512 for the Latin-script model).
    public var dimension: Int { model.dimension }

    /// Requests the model assets if they are not on-device yet.
    ///
    /// - Throws: `SearchSystemError.embeddingAssetsUnavailable` when the
    ///   download is denied or fails (always on the iOS Simulator).
    public func prepare() async throws {
        guard !model.hasAvailableAssets else { return }
        let result = try await model.requestAssets()
        guard result == .available else {
            throw SearchSystemError.embeddingAssetsUnavailable
        }
    }

    /// Embeds a text: contextual token vectors, mean-pooled into a single
    /// sentence vector and L2-normalized.
    ///
    /// - Parameters:
    ///   - text: Text to embed; must not be empty.
    ///   - language: BCP-47-style hint ("es", "en") or nil to let the model
    ///     infer the language. Indexing always passes the chunk's language;
    ///     `SearchService` passes the filter's language for queries.
    /// - Returns: L2-normalized vector of ``dimension`` elements.
    /// - Throws: `SearchSystemError.embeddingAssetsUnavailable` when assets
    ///   are missing; `SearchSystemError.embeddingGenerationFailed` for empty
    ///   text, zero tokens, or a zero-norm result.
    public func embedding(for text: String, language: String?) async throws -> [Float] {
        guard !text.isEmpty else { throw SearchSystemError.embeddingGenerationFailed }
        guard model.hasAvailableAssets else { throw SearchSystemError.embeddingAssetsUnavailable }

        let dimension = model.dimension
        guard dimension > 0 else { throw SearchSystemError.embeddingGenerationFailed }

        let hint = language.map { NLLanguage(rawValue: $0) }
        let result = try model.embeddingResult(for: text, language: hint)

        // Mean pooling: average all token vectors into one sentence vector.
        var pooled = [Double](repeating: 0, count: dimension)
        var tokenCount = 0
        result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { tokenVector, _ in
            for i in 0..<dimension {
                pooled[i] += tokenVector[i]
            }
            tokenCount += 1
            return true
        }
        guard tokenCount > 0 else { throw SearchSystemError.embeddingGenerationFailed }

        let divisor = Double(tokenCount)
        for i in 0..<dimension {
            pooled[i] /= divisor
        }

        // L2-normalise so cosine distance behaves as similarity.
        let norm = (pooled.reduce(0) { $0 + $1 * $1 }).squareRoot()
        guard norm > 0 else { throw SearchSystemError.embeddingGenerationFailed }
        return pooled.map { Float($0 / norm) }
    }
}
