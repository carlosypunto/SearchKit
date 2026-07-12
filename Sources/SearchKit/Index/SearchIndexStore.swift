import Foundation
internal import SQLiteVecStore

/// The only layer that knows `SQLiteVecStore.VectorStore`.
///
/// Owns two consumer tables in the same SQLite file (`search_manifest`,
/// `indexed_documents`) via `execute`/`query`, and never touches the store's
/// internal `chunks`/`chunks_fts` tables directly.
///
/// On open it validates the persisted `EmbeddingSpaceManifest`: any semantic
/// mismatch (model, dimension, pooling, transform…) wipes the index — rows are
/// never migrated between vector spaces. The index file is a regenerable cache.
public actor SearchIndexStore {

    private let store: VectorStore
    public nonisolated let manifest: EmbeddingSpaceManifest
    /// True when opening detected an incompatible previous index and wiped it
    /// (or recreated the file after a frozen-schema mismatch).
    public nonisolated let didInvalidatePreviousIndex: Bool

    public init(dbURL: URL, manifest: EmbeddingSpaceManifest) async throws {
        let store: VectorStore
        var invalidated = false
        let metric = Self.storeMetric(for: manifest)
        do {
            store = try Self.openStore(dbURL: dbURL, dimension: manifest.dimension, metric: metric)
        } catch SQLiteError.schemaMismatch {
            // The file was created with another dimension/metric/layout.
            // It cannot even be opened, so recreate it from scratch.
            try Self.removeDatabaseFiles(at: dbURL)
            store = try Self.openStore(dbURL: dbURL, dimension: manifest.dimension, metric: metric)
            invalidated = true
        }

        _ = try await store.execute("""
            CREATE TABLE IF NOT EXISTS search_manifest(
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
            """)
        _ = try await store.execute("""
            CREATE TABLE IF NOT EXISTS indexed_documents(
                document_id TEXT PRIMARY KEY,
                content_hash TEXT NOT NULL,
                chunk_count INTEGER NOT NULL,
                indexed_at TEXT NOT NULL
            )
            """)

        do {
            if let stored = try await Self.readManifest(from: store) {
                if !stored.isCompatible(with: manifest) {
                    try await Self.wipe(store)
                    try await Self.writeManifest(manifest, to: store)
                    invalidated = true
                }
            } else {
                // No manifest but existing rows: unknown vector space, wipe.
                if try await store.count() > 0 {
                    try await Self.wipe(store)
                    invalidated = true
                }
                try await Self.writeManifest(manifest, to: store)
            }
        } catch SearchSystemError.manifestDecodingFailed {
            // Undecodable manifest (corrupt, or written by an older/newer
            // schema): unknown vector space — the index is a regenerable
            // cache, so wipe instead of failing to open.
            try await Self.wipe(store)
            try await Self.writeManifest(manifest, to: store)
            invalidated = true
        }

        self.store = store
        self.manifest = manifest
        self.didInvalidatePreviousIndex = invalidated
    }

    // MARK: - Indexing

    /// Document IDs currently indexed, with their content hash.
    public func indexedContentHashes() async throws -> [String: String] {
        let rows = try await store.query("SELECT document_id, content_hash FROM indexed_documents")
        var hashes: [String: String] = [:]
        for row in rows {
            if let id = row.text("document_id"), let hash = row.text("content_hash") {
                hashes[id] = hash
            }
        }
        return hashes
    }

    /// Replaces a whole document: `delete(source:)` + `insertBatch` + bookkeeping.
    public func reindex(document: SearchDocument, chunks: [SearchChunk], vectors: [[Float]]) async throws {
        guard chunks.count == vectors.count else {
            throw SearchSystemError.embeddingDimensionMismatch(expected: chunks.count, got: vectors.count)
        }
        var entries: [VectorEntry] = []
        entries.reserveCapacity(chunks.count)
        for (chunk, vector) in zip(chunks, vectors) {
            entries.append(try VectorEntry(
                id: chunk.id,
                content: chunk.content,
                source: chunk.documentID,
                encoding: chunk.metadata,
                vector: vector
            ))
        }
        try await store.delete(source: document.id)
        try await store.insertBatch(entries)
        _ = try await store.execute("""
            INSERT INTO indexed_documents(document_id, content_hash, chunk_count, indexed_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(document_id) DO UPDATE SET
                content_hash = excluded.content_hash,
                chunk_count = excluded.chunk_count,
                indexed_at = excluded.indexed_at
            """, bindings: [
                .text(document.id),
                .text(document.contentHash),
                .int(chunks.count),
                .text(Date.now.ISO8601Format())
            ])
    }

    /// Removes a document that disappeared from the catalog.
    public func removeDocument(id: String) async throws {
        try await store.delete(source: id)
        _ = try await store.execute("DELETE FROM indexed_documents WHERE document_id = ?", bindings: [.text(id)])
    }

    public func chunkCount() async throws -> Int {
        try await store.count()
    }

    public func chunkCount(documentID: String) async throws -> Int {
        try await store.count(source: documentID)
    }

    // MARK: - Retrieval

    /// Default retrieval: RRF fusion of vector KNN and FTS5/BM25, done by the
    /// store. With a restrictive filter the store may return fewer than
    /// `topK` rows — expected, not an error.
    public func searchHybrid(
        text: String,
        vector: [Float],
        topK: Int,
        filter: SearchFilter = SearchFilter()
    ) async throws -> [SearchCandidate] {
        let (sql, bindings) = Self.whereFragment(for: filter)
        return try await store.searchHybrid(text: text, vector: vector, topK: topK, where: sql, bindings: bindings).map {
            Self.candidate(id: $0.id, content: $0.content, source: $0.source, metadata: $0.metadata,
                           score: $0.score, vectorRank: $0.vectorRank, textRank: $0.textRank)
        }
    }

    /// Vector-only retrieval. Score = −distance; `rawDistance` keeps the raw value.
    public func searchVector(
        _ vector: [Float],
        topK: Int,
        filter: SearchFilter = SearchFilter()
    ) async throws -> [SearchCandidate] {
        let (sql, bindings) = Self.whereFragment(for: filter)
        // The store applies `where:` AFTER the KNN selection, so a filter can
        // leave fewer than topK rows: overfetch to compensate, then truncate.
        let fetchK = sql == nil ? topK : min(topK * 4, VectorStore.maxTopK)
        let results = try await store.search(vector: vector, topK: fetchK, where: sql, bindings: bindings)
        return results.prefix(topK).map {
            Self.candidate(id: $0.id, content: $0.content, source: $0.source, metadata: $0.metadata,
                           score: -$0.distance, rawDistance: $0.distance)
        }
    }

    /// Lexical-only retrieval. Score = −BM25; `rawDistance` keeps the raw value.
    public func searchText(
        _ text: String,
        topK: Int,
        filter: SearchFilter = SearchFilter()
    ) async throws -> [SearchCandidate] {
        let (sql, bindings) = Self.whereFragment(for: filter)
        return try await store.searchText(text, topK: topK, where: sql, bindings: bindings).map {
            Self.candidate(id: $0.id, content: $0.content, source: $0.source, metadata: $0.metadata,
                           score: -$0.distance, rawDistance: $0.distance)
        }
    }

    /// First chunk of a document, for deterministic recall injection.
    public func firstChunk(documentID: String) async throws -> SearchCandidate? {
        let id = ChunkingService.stableChunkID(documentID: documentID, ordinal: 0)
        guard let entry = try await store.fetch(id: id) else { return nil }
        return Self.candidate(id: entry.id, content: entry.content, source: entry.source,
                              metadata: entry.metadata, score: 0)
    }

    // MARK: - Private

    private static func openStore(dbURL: URL, dimension: Int, metric: DistanceMetric) throws -> VectorStore {
        try VectorStore(
            dbURL: dbURL,
            dimension: dimension,
            distanceMetric: metric,
            tableName: "chunks",
            lexicalSearch: true
        )
    }

    private static func storeMetric(for manifest: EmbeddingSpaceManifest) -> DistanceMetric {
        switch IndexDistanceMetric(rawValue: manifest.distanceMetric) ?? .cosine {
        case .cosine: .cosine
        case .l2: .l2
        }
    }

    /// Builds an unqualified WHERE fragment valid in all three store search
    /// paths (vector post-filter, FTS join, and hybrid — which forwards it to
    /// both). Values always go through bindings, never interpolated.
    private static func whereFragment(for filter: SearchFilter) -> (sql: String?, bindings: [SQLValue]) {
        var clauses: [String] = []
        var bindings: [SQLValue] = []
        if let family = filter.family {
            clauses.append("json_extract(metadata, '$.family') = ?")
            bindings.append(.text(family))
        }
        if let language = filter.language {
            clauses.append("json_extract(metadata, '$.language') = ?")
            bindings.append(.text(language))
        }
        guard !clauses.isEmpty else { return (nil, []) }
        return (clauses.joined(separator: " AND "), bindings)
    }

    private static func removeDatabaseFiles(at dbURL: URL) throws {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm", "-journal"] {
            let url = URL(fileURLWithPath: dbURL.path + suffix)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private static func wipe(_ store: VectorStore) async throws {
        try await store.deleteAll()
        _ = try await store.execute("DELETE FROM indexed_documents")
        _ = try await store.execute("DELETE FROM search_manifest")
    }

    private static let manifestKey = "embedding_space"

    private static func readManifest(from store: VectorStore) async throws -> EmbeddingSpaceManifest? {
        let rows = try await store.query(
            "SELECT value FROM search_manifest WHERE key = ?",
            bindings: [.text(manifestKey)]
        )
        guard let json = rows.first?.text("value") else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let manifest = try? decoder.decode(EmbeddingSpaceManifest.self, from: Data(json.utf8)) else {
            // Corrupt manifest: treat as unknown vector space.
            throw SearchSystemError.manifestDecodingFailed
        }
        return manifest
    }

    private static func writeManifest(_ manifest: EmbeddingSpaceManifest, to store: VectorStore) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(manifest), as: UTF8.self)
        _ = try await store.execute("""
            INSERT INTO search_manifest(key, value) VALUES (?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
            """, bindings: [.text(manifestKey), .text(json)])
    }

    /// Single mapping point from store rows to the domain candidate.
    private static func candidate(
        id: Int,
        content: String,
        source: String,
        metadata: String?,
        score: Double,
        vectorRank: Int? = nil,
        textRank: Int? = nil,
        rawDistance: Double? = nil
    ) -> SearchCandidate {
        let decoded = metadata.flatMap {
            try? JSONDecoder().decode(ChunkMetadata.self, from: Data($0.utf8))
        }
        return SearchCandidate(
            id: id,
            documentID: decoded?.documentID ?? source,
            title: decoded?.title ?? source,
            language: decoded?.language ?? "",
            family: decoded?.family ?? "",
            ordinal: decoded?.ordinal ?? 0,
            content: content,
            score: score,
            vectorRank: vectorRank,
            textRank: textRank,
            rawDistance: rawDistance
        )
    }
}

/// Internal bridge so SearchService can react to FTS query syntax errors
/// without importing SQLiteVecStore.
func isInvalidTextQueryError(_ error: any Error) -> Bool {
    if case SQLiteError.invalidTextQuery = error { return true }
    return false
}
