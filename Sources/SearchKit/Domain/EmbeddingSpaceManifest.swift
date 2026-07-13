import Foundation

/// Describes the vector space an index was built with. `VectorStore` freezes
/// dimension/metric into the SQLite file, but knows nothing about the model,
/// pooling or transforms that produced the vectors — this manifest does.
/// Any semantic mismatch invalidates the index (no row migration, ever).
///
/// `transformIdentifier`/`transformVersion` record the post-embedding
/// transform (`VectorTransformKind`) the rows were built with: a different
/// transform declares different values and invalidation just works. Future
/// transforms (PCA, model adaptation) are sketched in `ROADMAP.md`.
public struct EmbeddingSpaceManifest: Sendable, Equatable, Codable {
    /// Version of the manifest layout itself (not of the vector space).
    public let schemaVersion: Int
    /// Identifier of the embedding model that produced the vectors.
    public let modelIdentifier: String
    /// Revision of the embedding model.
    public let modelRevision: String
    /// Number of components per vector.
    public let dimension: Int
    /// ``IndexDistanceMetric`` raw value frozen into the store schema.
    public let distanceMetric: String
    /// How languages map to models, e.g. "latin-script-shared" (one
    /// Latin-script model covering both es and en).
    public let languageStrategy: String
    /// Token-to-sentence pooling recipe, e.g. "mean-pooling+l2norm:v1".
    public let poolingStrategy: String
    /// Identifier of the ``VectorTransformKind`` the rows were built with.
    public let transformIdentifier: String
    /// Version of the post-embedding transform.
    public let transformVersion: String
    /// Chunking window that produced the indexed rows. Chunking changes are
    /// invisible to the per-document `contentHash` diff, so they must
    /// invalidate through the manifest like any other semantic mismatch.
    public let chunkMaxTokens: Int
    /// Token overlap between consecutive chunks.
    public let chunkOverlap: Int
    /// When the manifest was created. Ignored by ``isCompatible(with:)``.
    public let createdAt: Date

    /// Creates a manifest. Prefer
    /// ``EmbeddingPipeline/makeManifest(languageStrategy:distanceMetric:chunking:transform:)``,
    /// which fills every field consistently from the live provider.
    ///
    /// - Parameters:
    ///   - schemaVersion: Manifest layout version.
    ///   - modelIdentifier: Embedding model identifier.
    ///   - modelRevision: Embedding model revision.
    ///   - dimension: Components per vector.
    ///   - distanceMetric: ``IndexDistanceMetric`` raw value.
    ///   - languageStrategy: Language-to-model mapping label.
    ///   - poolingStrategy: Pooling recipe label.
    ///   - transformIdentifier: ``VectorTransformKind`` identifier.
    ///   - transformVersion: Post-embedding transform version.
    ///   - chunkMaxTokens: Chunk window size in tokens.
    ///   - chunkOverlap: Token overlap between consecutive chunks.
    ///   - createdAt: Creation timestamp (excluded from compatibility).
    public init(
        schemaVersion: Int = 1,
        modelIdentifier: String,
        modelRevision: String,
        dimension: Int,
        distanceMetric: String = "cosine",
        languageStrategy: String,
        poolingStrategy: String,
        transformIdentifier: String,
        transformVersion: String,
        chunkMaxTokens: Int = ChunkingConfiguration().maxTokens,
        chunkOverlap: Int = ChunkingConfiguration().overlap,
        createdAt: Date = .now
    ) {
        self.schemaVersion = schemaVersion
        self.modelIdentifier = modelIdentifier
        self.modelRevision = modelRevision
        self.dimension = dimension
        self.distanceMetric = distanceMetric
        self.languageStrategy = languageStrategy
        self.poolingStrategy = poolingStrategy
        self.transformIdentifier = transformIdentifier
        self.transformVersion = transformVersion
        self.chunkMaxTokens = chunkMaxTokens
        self.chunkOverlap = chunkOverlap
        self.createdAt = createdAt
    }

    /// Compatibility ignores `createdAt`: two manifests describe the same
    /// vector space if every semantic field matches.
    ///
    /// - Parameter other: The persisted manifest to compare against.
    /// - Returns: True when indexed rows built under `other` remain valid for
    ///   this manifest; false means ``SearchIndexStore`` wipes and rebuilds.
    public func isCompatible(with other: EmbeddingSpaceManifest) -> Bool {
        schemaVersion == other.schemaVersion
            && modelIdentifier == other.modelIdentifier
            && modelRevision == other.modelRevision
            && dimension == other.dimension
            && distanceMetric == other.distanceMetric
            && languageStrategy == other.languageStrategy
            && poolingStrategy == other.poolingStrategy
            && transformIdentifier == other.transformIdentifier
            && transformVersion == other.transformVersion
            && chunkMaxTokens == other.chunkMaxTokens
            && chunkOverlap == other.chunkOverlap
    }
}
