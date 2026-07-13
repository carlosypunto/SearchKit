import Foundation

/// Wraps a provider, guaranteeing that indexing and query vectors go through
/// exactly the same steps and match the manifest dimension.
///
/// The optional post-embedding transform (`VectorTransformKind`) is applied by
/// `SearchService`, not here — mean-centering needs the corpus centroid, which
/// only exists once the index does. The pipeline's job is to record the chosen
/// transform in the manifest so a change invalidates existing indexes.
public struct EmbeddingPipeline: Sendable {
    /// The wrapped embedding backend.
    public let provider: any TextEmbeddingProvider

    /// Creates a pipeline around a provider.
    ///
    /// - Parameter provider: The embedding backend; both indexing and query
    ///   vectors will go through it via ``vector(for:language:)``.
    public init(provider: any TextEmbeddingProvider) {
        self.provider = provider
    }

    /// Forwards to ``TextEmbeddingProvider/prepare()`` — ensures model
    /// assets are available (may download on first use).
    ///
    /// - Throws: `SearchSystemError.embeddingAssetsUnavailable` when the
    ///   assets cannot be obtained (always on the iOS Simulator).
    public func prepare() async throws {
        try await provider.prepare()
    }

    /// Embeds a text and validates the result against the provider dimension.
    /// The single embedding path for chunks *and* queries.
    ///
    /// - Parameters:
    ///   - text: Text to embed.
    ///   - language: BCP-47-style hint ("es", "en") or nil to let the model
    ///     infer the language.
    /// - Returns: The provider's raw vector (post-embedding transforms are
    ///   applied later by `SearchService`).
    /// - Throws: `SearchSystemError.embeddingDimensionMismatch` when the
    ///   provider returns the wrong size, plus whatever the provider throws
    ///   (`.embeddingGenerationFailed`, `.embeddingAssetsUnavailable`).
    public func vector(for text: String, language: String?) async throws -> [Float] {
        let raw = try await provider.embedding(for: text, language: language)
        let expected = await provider.dimension
        guard raw.count == expected else {
            throw SearchSystemError.embeddingDimensionMismatch(expected: expected, got: raw.count)
        }
        return raw
    }

    /// Manifest describing this pipeline's vector space.
    ///
    /// - Parameters:
    ///   - languageStrategy: Label describing how languages map to models
    ///     (default "latin-script-shared": one model covers es and en).
    ///   - distanceMetric: Metric to freeze into the store schema.
    ///   - chunking: Pass the **same** configuration given to
    ///     `ChunkingService`, so chunking changes invalidate the index like
    ///     any other semantic mismatch.
    ///   - transform: Post-embedding transform `SearchService` applies;
    ///     changing it likewise invalidates the index. Mean-centering is the
    ///     default for real contextual embeddings; choose `.identity`
    ///     explicitly for raw provider vectors, tests or ablations.
    /// - Returns: A manifest whose model/dimension/pooling fields are read
    ///   from the live provider.
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
