import Foundation

/// Describes the vector space an index was built with. `VectorStore` freezes
/// dimension/metric into the SQLite file, but knows nothing about the model,
/// pooling or transforms that produced the vectors — this manifest does.
/// Any semantic mismatch invalidates the index (no row migration, ever).
///
/// `transformIdentifier`/`transformVersion` are kept even though the
/// `VectorTransform` stage was removed (fixed to "identity"/"v1"): a future
/// transform declares different values and invalidation just works.
/// See `futuras_evoluciones.md`.
public struct EmbeddingSpaceManifest: Sendable, Equatable, Codable {
    public let schemaVersion: Int
    public let modelIdentifier: String
    public let modelRevision: String
    public let dimension: Int
    public let distanceMetric: String
    public let languageStrategy: String
    public let poolingStrategy: String
    public let transformIdentifier: String
    public let transformVersion: String
    /// Chunking window that produced the indexed rows. Chunking changes are
    /// invisible to the per-document `contentHash` diff, so they must
    /// invalidate through the manifest like any other semantic mismatch.
    public let chunkMaxTokens: Int
    public let chunkOverlap: Int
    public let createdAt: Date

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
