# ``SearchKit``

On-device RAG consumer layer: catalog ingestion, chunking, embedding, hybrid retrieval,
deterministic recall and prompt construction on top of `SQLiteVecStore`.

## Overview

SearchKit turns a bundle of Markdown documents into a locally searchable corpus and produces
grounded RAG prompts, entirely on-device. Embeddings come from Apple's
`NLContextualEmbedding`; storage is a single SQLite file (vector index + FTS5) owned by the
`SQLiteVecKit` dependency.

The pipeline has two halves, each built from small, independently testable stages:

- **Indexing**: ``CatalogRepository`` → ``ChunkingService`` → ``EmbeddingPipeline`` →
  ``SearchIndexStore``
- **Querying**: ``SearchService`` → ``SearchIndexStore`` → ``Reranker`` →
  ``DeterministicRecallPolicy`` → ``PromptBuilder``

``SearchService`` is the only orchestrator that wires them together. See
<doc:Architecture> for the pipeline in detail and the invariants to respect when changing
things.

## Topics

### Essentials

- <doc:Architecture>
- ``SearchService``
- ``SearchOptions``
- ``SearchOutcome``

### Catalog

- ``CatalogRepository``
- ``BundleCatalogRepository``
- ``SearchDocument``

### Chunking

- ``ChunkingService``
- ``ChunkingConfiguration``
- ``SearchChunk``
- ``ChunkMetadata``

### Embedding

- ``TextEmbeddingProvider``
- ``ContextualEmbeddingProvider``
- ``EmbeddingPipeline``
- ``EmbeddingSpaceManifest``

### Index

- ``SearchIndexStore``
- ``IndexDistanceMetric``

### Search & Prompting

- ``SearchMode``
- ``SearchFilter``
- ``SearchCandidate``
- ``RetrievalMode``
- ``Reranker``
- ``NoOpReranker``
- ``DeterministicRecallPolicy``
- ``PromptBuilder``

### Sync

- ``SyncSummary``
- ``SyncProgress``

### Errors

- ``SearchSystemError``
