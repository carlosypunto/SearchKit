# Architecture

The pipeline stages, how they fit together, and the invariants to respect when changing
things.

## Overview

SearchKit is organized as a pipeline of small, independently testable stages.
``SearchService`` is the only orchestrator that wires them together.

**Indexing** (``SearchService/sync(documents:progress:)``):

1. A ``CatalogRepository`` (typically ``BundleCatalogRepository``) reads every Markdown
   resource with front matter into a ``SearchDocument``. The `contentHash` is a SHA-256 of
   the *entire raw file* — front matter included — so editing metadata alone triggers
   reingestion.
2. ``ChunkingService`` splits each document into overlapping word-token windows
   (`NLTokenizer`) with deterministic 63-bit FNV-1a chunk IDs (`documentID#ordinal`), kept
   positive for use as SQLite rowids. Determinism is load-bearing: it makes per-document
   reingestion (delete + insert) idempotent.
3. ``EmbeddingPipeline`` produces one vector per chunk, guaranteeing that indexing and query
   vectors go through identical steps and match the manifest dimension.
4. ``SearchIndexStore`` persists chunks and vectors. It is the only type that imports
   `SQLiteVecStore`, and it owns two consumer tables (`search_manifest`,
   `indexed_documents`) alongside the store's own `chunks`/`chunks_fts` tables, which it
   never touches directly.

**Querying** (``SearchService/search(_:options:)``):

1. The query is embedded through the same ``EmbeddingPipeline`` and retrieved from
   ``SearchIndexStore`` in the requested ``SearchMode``.
2. ``DeterministicRecallPolicy`` runs *after* retrieval: an exact (case/diacritic-insensitive)
   title match must appear in results even if hybrid retrieval missed it. Injected
   candidates are re-validated against the request's ``SearchFilter``.
3. ``PromptBuilder`` — a pure function, no store access, no LLM call — turns the final
   candidates into a grounded RAG prompt.

## Search modes and controlled degradation

`.auto` mode degrades gracefully: hybrid → vector-only (on FTS syntax failure or no usable
terms) → text-only (on embedding failure). Forced modes (`.hybrid`/`.vector`/`.text`)
surface their failures instead of falling back. ``SearchOutcome`` reports both the requested
and the actually used mode.

## Invariants

- ``SearchCandidate/score`` is always "higher = better", but its scale differs by retrieval
  mode: RRF for hybrid, negated distance for vector-only, negated BM25 for text-only.
  **Scores from different modes must never be compared or mixed.**
- Filters (``SearchFilter/family`` / ``SearchFilter/language``) are applied as SQL
  (`json_extract` on chunk metadata) in every retrieval mode, and applied *again* in Swift
  after deterministic recall injection, since injected candidates bypass the SQL filter.
- On open, ``SearchIndexStore`` validates the persisted ``EmbeddingSpaceManifest``. Any
  semantic mismatch (model, dimension, pooling, transform, chunking window) wipes the whole
  index, and so does a manifest that fails to decode. **There is no row migration between
  vector spaces, ever** — the index file is a fully regenerable cache, not a database to
  preserve.
- ``ChunkingConfiguration`` is part of the manifest (``EmbeddingSpaceManifest/chunkMaxTokens``,
  ``EmbeddingSpaceManifest/chunkOverlap``) because chunking changes are invisible to the
  per-document content-hash diff. Always pass the same configuration to ``ChunkingService``
  and to ``EmbeddingPipeline/makeManifest(languageStrategy:distanceMetric:chunking:)``.
- ``EmbeddingPipeline``'s `transformIdentifier`/`transformVersion` are vestigial (fixed to
  `"identity"`/`"v1"`): a post-embedding vector-transform stage was designed but removed
  from the MVP. The manifest fields remain so a future transform can invalidate old indexes
  correctly.
- ``IndexDistanceMetric`` (cosine/l2) is frozen into the SQLite schema by `SQLiteVecStore`
  itself — changing it always recreates the index file and forces a full re-embed; it is
  never migrated.
