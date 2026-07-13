import Foundation

/// Result of an incremental catalog sync.
public struct SyncSummary: Sendable, Equatable {
    /// Documents (re-)embedded and reingested (new or changed content hash).
    public let indexed: Int
    /// Documents removed because they disappeared from the catalog.
    public let removed: Int
    /// Documents skipped because their content hash was already indexed.
    public let unchanged: Int

    /// Creates a summary (returned by `SearchService.sync`; public for tests).
    ///
    /// - Parameters:
    ///   - indexed: Count of (re-)ingested documents.
    ///   - removed: Count of removed documents.
    ///   - unchanged: Count of skipped documents.
    public init(indexed: Int, removed: Int, unchanged: Int) {
        self.indexed = indexed
        self.removed = removed
        self.unchanged = unchanged
    }
}

/// Progress callback payload for `sync`.
public struct SyncProgress: Sendable, Equatable {
    /// Pending documents embedded so far.
    public let completed: Int
    /// Total pending documents in this sync (not the whole catalog).
    public let total: Int
}

/// Orchestrates the whole consumer pipeline: incremental indexing (diff by
/// content hash), query embedding, hybrid retrieval, controlled fallbacks,
/// reranking and deterministic recall.
public actor SearchService {

    private let indexStore: SearchIndexStore
    private let pipeline: EmbeddingPipeline
    private let chunker: ChunkingService
    private let reranker: any Reranker
    private let recallPolicy: DeterministicRecallPolicy
    /// documentID → title for the current catalog, fed by `sync`.
    private var titlesByDocumentID: [String: String] = [:]
    /// Corpus centroid for the mean-centering transform, lazily loaded from
    /// the store (or computed by `sync` on the first full indexing pass).
    private var cachedCentroid: [Float]?

    /// Creates the orchestrator.
    ///
    /// - Parameters:
    ///   - indexStore: The open index this service reads and writes.
    ///   - pipeline: Embedding pipeline; must be the one whose manifest the
    ///     store was opened with, so query vectors match the indexed space.
    ///   - chunker: Chunking service; its configuration must match the
    ///     manifest's chunking window.
    ///   - reranker: Post-retrieval reordering stage, invoked on the fused
    ///     candidate list before deterministic recall. Defaults to
    ///     ``NoOpReranker`` (retrieval order untouched).
    ///   - recallPolicy: Post-retrieval exact-title injection rule.
    public init(
        indexStore: SearchIndexStore,
        pipeline: EmbeddingPipeline,
        chunker: ChunkingService = ChunkingService(),
        reranker: any Reranker = NoOpReranker(),
        recallPolicy: DeterministicRecallPolicy = DeterministicRecallPolicy()
    ) {
        self.indexStore = indexStore
        self.pipeline = pipeline
        self.chunker = chunker
        self.reranker = reranker
        self.recallPolicy = recallPolicy
    }

    // MARK: - Indexing

    /// Incrementally syncs the index with the catalog: only new or modified
    /// documents (by content hash) are re-embedded and reingested; documents
    /// missing from the catalog are removed.
    ///
    /// - Parameters:
    ///   - documents: The full current catalog (not a delta — anything absent
    ///     here is removed from the index).
    ///   - progress: Called after each pending document is embedded (the slow
    ///     phase). Total counts pending documents only.
    /// - Returns: Counts of indexed / removed / unchanged documents.
    /// - Throws: Provider errors (`SearchSystemError.embeddingAssetsUnavailable`,
    ///   `.embeddingGenerationFailed`, `.embeddingDimensionMismatch`), storage
    ///   errors, and `CancellationError` — the sync checks for task
    ///   cancellation between documents.
    @discardableResult
    public func sync(
        documents: [SearchDocument],
        progress: (@Sendable (SyncProgress) -> Void)? = nil
    ) async throws -> SyncSummary {
        try await pipeline.prepare()

        titlesByDocumentID = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0.title) })

        let indexedHashes = try await indexStore.indexedContentHashes()
        let catalogIDs = Set(documents.map(\.id))

        var removed = 0
        for staleID in indexedHashes.keys where !catalogIDs.contains(staleID) {
            try await indexStore.removeDocument(id: staleID)
            removed += 1
        }

        let pending = documents.filter { indexedHashes[$0.id] != $0.contentHash }
        let unchanged = documents.count - pending.count

        // Pass 1 (the slow phase, so progress reports here): embed every
        // pending chunk with raw provider vectors.
        var jobs: [(document: SearchDocument, chunks: [SearchChunk], vectors: [[Float]])] = []
        jobs.reserveCapacity(pending.count)
        for (offset, document) in pending.enumerated() {
            try Task.checkCancellation()
            let chunks = chunker.chunks(for: document)
            var vectors: [[Float]] = []
            vectors.reserveCapacity(chunks.count)
            for chunk in chunks {
                try Task.checkCancellation()
                vectors.append(try await pipeline.vector(for: chunk.content, language: chunk.language))
            }
            jobs.append((document, chunks, vectors))
            progress?(SyncProgress(completed: offset + 1, total: pending.count))
        }

        // Pass 2: apply the manifest's vector transform (needs the corpus
        // centroid, hence two passes), then reindex per document.
        if isMeanCentering {
            var centroid = try await currentCentroid()
            if centroid == nil {
                // First full indexing pass of this index generation: freeze
                // the centroid of everything being indexed. Incremental syncs
                // reuse it; only a rebuild recomputes it.
                centroid = VectorTransform.centroid(of: jobs.flatMap(\.vectors))
                if let centroid {
                    try await indexStore.storeCentroid(centroid)
                    cachedCentroid = centroid
                }
            }
            if let centroid {
                for index in jobs.indices {
                    jobs[index].vectors = jobs[index].vectors.map {
                        VectorTransform.meanCenter($0, centroid: centroid)
                    }
                }
            }
        }
        for job in jobs {
            try Task.checkCancellation()
            try await indexStore.reindex(document: job.document, chunks: job.chunks, vectors: job.vectors)
        }

        return SyncSummary(indexed: pending.count, removed: removed, unchanged: unchanged)
    }

    // MARK: - Vector transform

    private var isMeanCentering: Bool {
        indexStore.manifest.transformIdentifier == VectorTransformKind.meanCentering.identifier
    }

    private func currentCentroid() async throws -> [Float]? {
        if cachedCentroid == nil {
            cachedCentroid = try await indexStore.storedCentroid()
        }
        return cachedCentroid
    }

    /// Embeds a query and applies the manifest's transform, so query vectors
    /// live in the same space as the indexed chunk vectors.
    private func queryVector(for query: String, language: String?) async throws -> [Float] {
        let raw = try await pipeline.vector(for: query, language: language)
        guard isMeanCentering, let centroid = try await currentCentroid() else { return raw }
        return VectorTransform.meanCenter(raw, centroid: centroid)
    }

    // MARK: - Query

    /// Searches with the given options. In `.auto` mode degradation is
    /// controlled (embedding failure → lexical-only, FTS syntax failure or no
    /// usable terms → vector-only); forced modes surface their failures.
    ///
    /// - Parameters:
    ///   - query: Free user text; sanitized for FTS, so FTS5 operators and
    ///     punctuation can never break the query.
    ///   - options: Mode, result budget and metadata filter. The filter's
    ///     language doubles as the query's embedding hint.
    /// - Returns: Ranked candidates (deduplicated, filter re-validated after
    ///   deterministic recall injection) plus the mode actually used —
    ///   compare it with `options.mode` to detect an `.auto` degradation.
    /// - Throws: `SearchSystemError.emptyQuery` for whitespace-only input;
    ///   `SearchSystemError.textQueryUnusable` when a forced `.text`/`.hybrid`
    ///   query has no usable FTS terms; embedding/storage errors that the
    ///   requested mode does not degrade around; any error thrown by the
    ///   configured ``Reranker``.
    public func search(_ query: String, options: SearchOptions = SearchOptions()) async throws -> SearchOutcome {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SearchSystemError.emptyQuery }

        let ftsQuery = FTSQuerySanitizer.sanitize(trimmed)
        let raw = try await retrieve(query: trimmed, ftsQuery: ftsQuery, options: options)

        // Reranking happens before deterministic recall (which keeps the last
        // word on exact-title injection) and before the final dedup + filter
        // re-validation, so a reranker can never resurrect filtered candidates.
        let reranked = try await reranker.rerank(query: trimmed, candidates: raw.candidates)

        let withRecall = try await recallPolicy.apply(
            query: trimmed,
            candidates: reranked,
            titles: titlesByDocumentID,
            fetchFirstChunk: { [indexStore] documentID in
                try await indexStore.firstChunk(documentID: documentID)
            }
        )
        // Recall injection bypasses the SQL filter; re-validate the final list.
        let candidates = Self.deduplicated(withRecall).filter { options.filter.allows($0) }
        return SearchOutcome(candidates: candidates, mode: raw.mode, requestedMode: options.mode)
    }

    private func retrieve(
        query: String,
        ftsQuery: String?,
        options: SearchOptions
    ) async throws -> (candidates: [SearchCandidate], mode: RetrievalMode) {
        let topK = options.topK
        let filter = options.filter

        switch options.mode {
        case .auto:
            return try await retrieveAuto(query: query, ftsQuery: ftsQuery, options: options)

        case .vector:
            // Forced: embedding errors propagate, FTS is never touched.
            let vector = try await queryVector(for: query, language: filter.language)
            return (try await indexStore.searchVector(vector, topK: topK, filter: filter), .vectorOnly)

        case .text:
            // Forced: works even when the embedding model is unavailable.
            guard let ftsQuery else { throw SearchSystemError.textQueryUnusable }
            do {
                return (try await indexStore.searchText(ftsQuery, topK: topK, filter: filter), .textOnly)
            } catch where isInvalidTextQueryError(error) {
                throw SearchSystemError.textQueryUnusable
            }

        case .hybrid:
            guard let ftsQuery else { throw SearchSystemError.textQueryUnusable }
            let vector = try await queryVector(for: query, language: filter.language)
            do {
                return (try await indexStore.searchHybrid(text: ftsQuery, vector: vector, topK: topK, filter: filter), .hybrid)
            } catch where isInvalidTextQueryError(error) {
                throw SearchSystemError.textQueryUnusable
            }
        }
    }

    private func retrieveAuto(
        query: String,
        ftsQuery: String?,
        options: SearchOptions
    ) async throws -> (candidates: [SearchCandidate], mode: RetrievalMode) {
        let topK = options.topK
        let filter = options.filter

        // The language filter doubles as the query's embedding hint: language
        // auto-detection on short query strings is unreliable, and indexed
        // chunks were embedded with an explicit hint.
        let vector: [Float]
        do {
            vector = try await queryVector(for: query, language: filter.language)
        } catch {
            // Embedding unavailable: lexical-only fallback.
            guard let ftsQuery else { throw error }
            return (try await indexStore.searchText(ftsQuery, topK: topK, filter: filter), .textOnly)
        }

        guard let ftsQuery else {
            // Nothing lexically usable in the query (e.g. only punctuation).
            return (try await indexStore.searchVector(vector, topK: topK, filter: filter), .vectorOnly)
        }

        do {
            return (try await indexStore.searchHybrid(text: ftsQuery, vector: vector, topK: topK, filter: filter), .hybrid)
        } catch where isInvalidTextQueryError(error) {
            return (try await indexStore.searchVector(vector, topK: topK, filter: filter), .vectorOnly)
        }
    }

    private static func deduplicated(_ candidates: [SearchCandidate]) -> [SearchCandidate] {
        var seen = Set<Int>()
        return candidates.filter { seen.insert($0.id).inserted }
    }
}
