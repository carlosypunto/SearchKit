import Foundation

/// Wraps a provider, guaranteeing that indexing and query vectors go through
/// exactly the same steps and match the manifest dimension.
///
/// The optional post-embedding transform (`VectorTransformKind`) is applied by
/// `SearchService`, not here — mean-centering needs the corpus centroid, which
/// only exists once the index does. The pipeline's job is to record the chosen
/// transform in the manifest so a change invalidates existing indexes.
public struct EmbeddingPipeline: Sendable {
    public let provider: any TextEmbeddingProvider

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
    /// `transform` selects the post-embedding transform `SearchService`
    /// applies; changing it likewise invalidates the index. Mean-centering is
    /// the default for real contextual embeddings; choose `.identity`
    /// explicitly for raw provider vectors, tests or ablations.
    public func makeManifest(
        languageStrategy: String = "latin-script-shared",
        distanceMetric: IndexDistanceMetric = .cosine,
        chunking: ChunkingConfiguration = ChunkingConfiguration(),
        transform: VectorTransformKind = .meanCentering
    ) async -> EmbeddingSpaceManifest {
        EmbeddingSpaceManifest(
            modelIdentifier: await provider.modelIdentifier,
            modelRevision: await provider.modelRevision,
            dimension: await provider.dimension,
            distanceMetric: distanceMetric.rawValue,
            languageStrategy: languageStrategy,
            poolingStrategy: await provider.poolingStrategy,
            transformIdentifier: transform.identifier,
            transformVersion: transform.version,
            chunkMaxTokens: chunking.maxTokens,
            chunkOverlap: chunking.overlap
        )
    }
}
