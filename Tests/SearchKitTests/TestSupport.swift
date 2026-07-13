import Foundation
@testable import SearchKit

/// Deterministic embedding provider: bag-of-hashed-buckets over lowercased
/// tokens, L2-normalised. A `synonyms` map canonicalises tokens before
/// hashing, which lets tests simulate semantic matches ("automóvil" ≈ "coche")
/// without a real model.
struct FakeEmbeddingProvider: TextEmbeddingProvider {
    let modelIdentifier: String
    let modelRevision: String
    let poolingStrategy = "fake-bag-of-buckets:v1"
    let dimension: Int
    let synonyms: [String: String]
    let shouldFailEmbedding: Bool

    init(
        modelIdentifier: String = "fake-model",
        modelRevision: String = "1",
        dimension: Int = 64,
        synonyms: [String: String] = [:],
        shouldFailEmbedding: Bool = false
    ) {
        self.modelIdentifier = modelIdentifier
        self.modelRevision = modelRevision
        self.dimension = dimension
        self.synonyms = synonyms
        self.shouldFailEmbedding = shouldFailEmbedding
    }

    func prepare() async throws {}

    func embedding(for text: String, language: String?) async throws -> [Float] {
        if shouldFailEmbedding { throw SearchSystemError.embeddingGenerationFailed }
        let tokens = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { throw SearchSystemError.embeddingGenerationFailed }

        var vector = [Float](repeating: 0, count: dimension)
        for token in tokens {
            let canonical = synonyms[token] ?? token
            vector[Self.bucket(for: canonical, dimension: dimension)] += 1
        }
        let norm = vector.reduce(Float(0)) { $0 + $1 * $1 }.squareRoot()
        return vector.map { $0 / norm }
    }

    private static func bucket(for token: String, dimension: Int) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in token.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(dimension))
    }
}

// MARK: - Helpers

func withTemporaryDatabase<T>(_ body: (URL) async throws -> T) async throws -> T {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("SearchKitTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    return try await body(directory.appendingPathComponent("index.sqlite3"))
}

func makeDocument(
    id: String,
    title: String,
    language: String = "es",
    family: String = "general",
    body: String
) -> SearchDocument {
    SearchDocument(
        id: id,
        title: title,
        language: language,
        family: family,
        body: body,
        contentHash: SearchDocument.hash(of: body)
    )
}

struct SearchStack {
    let service: SearchService
    let indexStore: SearchIndexStore
    let pipeline: EmbeddingPipeline
}

func makeSearchStack(
    dbURL: URL,
    provider: FakeEmbeddingProvider = FakeEmbeddingProvider(),
    chunking: ChunkingConfiguration = ChunkingConfiguration(),
    metric: IndexDistanceMetric = .cosine,
    transform: VectorTransformKind = .identity,
    reranker: any Reranker = NoOpReranker()
) async throws -> SearchStack {
    let pipeline = EmbeddingPipeline(provider: provider)
    let manifest = await pipeline.makeManifest(distanceMetric: metric, chunking: chunking, transform: transform)
    let indexStore = try await SearchIndexStore(dbURL: dbURL, manifest: manifest)
    let service = SearchService(
        indexStore: indexStore,
        pipeline: pipeline,
        chunker: ChunkingService(configuration: chunking),
        reranker: reranker
    )
    return SearchStack(service: service, indexStore: indexStore, pipeline: pipeline)
}
