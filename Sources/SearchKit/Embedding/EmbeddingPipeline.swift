import Foundation

/// Wraps a provider, guaranteeing that indexing and query vectors go through
/// exactly the same steps and match the manifest dimension.
///
/// Post-embedding vector transforms were removed from the MVP; the manifest
/// still records `transformIdentifier`/`transformVersion` (fixed to
/// "identity"/"v1") so a future transform can invalidate existing indexes.
/// See `futuras_evoluciones.md`.
public struct EmbeddingPipeline: Sendable {
    public let provider: any TextEmbeddingProvider

    /// Manifest constants for the (removed) vector-transform stage.
    static let transformIdentifier = "identity"
    static let transformVersion = "v1"

    public init(provider: any TextEmbeddingProvider) {
        self.provider = provider
    }

    public func prepare() async throws {
        try await provider.prepare()
    }

    public func vector(for text: String, language: String?) async throws -> [Float] {
        let raw = try await provider.embedding(for: text, language: language)
        let expected = await provider.dimension
        guard raw.count == expected else {
            throw SearchSystemError.embeddingDimensionMismatch(expected: expected, got: raw.count)
        }
        return raw
    }

    /// Manifest describing this pipeline's vector space. Pass the same
    /// `chunking` configuration given to `ChunkingService`, so chunking
    /// changes invalidate the index like any other semantic mismatch.
    public func makeManifest(
        languageStrategy: String = "latin-script-shared",
        distanceMetric: IndexDistanceMetric = .cosine,
        chunking: ChunkingConfiguration = ChunkingConfiguration()
    ) async -> EmbeddingSpaceManifest {
        EmbeddingSpaceManifest(
            modelIdentifier: await provider.modelIdentifier,
            modelRevision: await provider.modelRevision,
            dimension: await provider.dimension,
            distanceMetric: distanceMetric.rawValue,
            languageStrategy: languageStrategy,
            poolingStrategy: await provider.poolingStrategy,
            transformIdentifier: Self.transformIdentifier,
            transformVersion: Self.transformVersion,
            chunkMaxTokens: chunking.maxTokens,
            chunkOverlap: chunking.overlap
        )
    }
}
