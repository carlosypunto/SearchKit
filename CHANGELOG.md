# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-07-13

### Added

- `Reranker` protocol and `NoOpReranker` default: an additive extension point
  for post-retrieval reordering of the fused candidate list (e.g. an on-device
  cross-encoder). `SearchService.init` takes `reranker:` (default
  `NoOpReranker()`, behavior unchanged) and invokes it between retrieval and
  deterministic recall, so a reranker can never suppress an exact-title
  injection or resurrect filtered-out candidates.
- Complete symbol-level API documentation: every public type, initializer,
  method, property, and enum case now documents its parameters, return value,
  and thrown errors.
- `docs.yml` workflow (mirrors SQLiteVecKit's): DocC build with
  `--warnings-as-errors` as a gate on pushes and PRs, and automatic publishing
  of the rendered catalog to GitHub Pages on every push to `main`.

### Changed

- SQLiteVecKit dependency bumped to `0.1.1` (documentation-only upstream release:
  expanded inline DocC; no API or on-disk changes).
- `EmbeddingPipeline.makeManifest()` now defaults to `.meanCentering`. Existing
  indexes built with the previous `.identity` default invalidate and rebuild once;
  callers that intentionally need raw provider vectors can still pass
  `transform: .identity`.
- Hybrid fusion is now weighted RRF (k = 10, text weight 1.0, vector weight 0.5;
  previously k = 20, unweighted). The weak on-device vector branch no longer
  dilutes lexical rank-1 hits: on the expanded eval gold set, `hybrid+lf` goes
  from 46.2% to 53.8% hit@1 and 0.539 to 0.615 MRR@10, and the demo paraphrase
  queries move to top 1–2 (see `docs/retrieval-quality.md`). Fusion constants
  are not part of the manifest — no index invalidation.
- The `Evaluation` suite now reports hit@1/hit@3 (position inside the top 5),
  prints a per-query rank table, measures `.auto` (asserting it never silently
  degrades), and adds 8 stem-free paraphrase queries (zero token overlap with
  their target doc) that keep fusion tuning honest — gold set re-baselined at
  26 queries.

### Removed

- Removed the redundant `SearchService.search(_:topK:)` convenience overload. Use
  `SearchService.search(_:options:)` with `SearchOptions(topK:)`.

## [0.1.1] - 2026-07-13

### Added

- `VectorTransformKind` and the `transform:` parameter on
  `EmbeddingPipeline.makeManifest` (default `.identity`, preserving 0.1.0 behavior).
  `.meanCentering` subtracts the corpus centroid from every indexed and query vector and
  re-L2-normalizes, countering the anisotropy of mean-pooled contextual embeddings. The
  centroid is computed on the first full indexing pass, persisted next to the manifest,
  and frozen for the lifetime of the index generation (incremental syncs reuse it; a
  rebuild recomputes it). Enabling or disabling the transform is a manifest mismatch, so
  existing indexes wipe and rebuild — a one-time full re-embed, by design.
- Opt-in retrieval-quality evaluation suite (`SEARCHKIT_EVAL=1 swift test --filter
  Evaluation`): hit@5 and MRR@10 per retrieval mode and language over a gold set grounded
  in the example-app corpus.

### Changed

- Query embeddings now use the search filter's language as the embedding hint (indexing
  always used the chunk's explicit language; auto-detection on short query strings is
  unreliable).
- `FTSQuerySanitizer` drops es/en stopwords and single-character tokens before building
  the OR query; stopword-only queries fall back to the raw tokens.
- Hybrid retrieval fuses the vector and BM25 rank lists in `SearchIndexStore` with
  RRF k = 20 instead of delegating to `SQLiteVecStore.searchHybrid` (k = 60): with two
  overfetched lists of ~4×topK, k = 60 flattens ranks enough that a chunk sitting
  mid-list in both branches outscores a rank-1 single-branch hit.
- Example app: mean-centering enabled, and the language filter defaults to the device
  language (the bilingual corpus otherwise fills half the visible slots with the
  other-language twin of every result).

## [0.1.0] - 2026-07-12

### Added

- Catalog ingestion: `CatalogRepository` protocol and `BundleCatalogRepository` reading
  Markdown resources with YAML-ish front matter (`FrontMatterParser`); document identity by
  SHA-256 content hash for incremental sync.
- `SearchIndexStore` wipes and rebuilds the index when the persisted manifest fails to
  decode (older or corrupt JSON) instead of failing to open.
- Chunking: overlapping word-token windows via `NLTokenizer` with deterministic 63-bit
  FNV-1a chunk IDs, making per-document reingestion idempotent.
- Embedding: `TextEmbeddingProvider` protocol, `ContextualEmbeddingProvider` backed by
  `NLContextualEmbedding` (mean-pooled + L2-normalized, Latin-script model shared across
  es/en) and `EmbeddingPipeline` guaranteeing identical steps for indexing and query vectors.
- Index: `SearchIndexStore` on top of `SQLiteVecStore`, with persisted
  `EmbeddingSpaceManifest` validation — any semantic mismatch wipes and rebuilds the index
  (regenerable cache, no row migration).
- Search: `SearchService` orchestrating `.auto` mode's controlled degradation
  (hybrid → vector-only → text-only) and forced `.hybrid`/`.vector`/`.text` modes;
  `FTSQuerySanitizer` for safe FTS5 queries; `DeterministicRecallPolicy` guaranteeing exact
  title matches appear in results; metadata filters (`family`/`language`) applied in SQL and
  re-validated in Swift after recall injection.
- Prompt construction: `PromptBuilder`, a pure function turning candidates into a grounded
  RAG prompt (Spanish/English).
- Test suite using Swift Testing, with deterministic `FakeEmbeddingProvider` fixtures,
  opt-in `Benchmark` suite and env-gated `RealEmbedding` integration suite.
- `SearchKitExample`: SwiftUI demo app (iOS 17+/macOS 14+) exercising the full pipeline
  against a bundled bilingual Markdown corpus — hybrid/vector/text modes, filters, distance
  metric switching and RAG prompt preview.
- `SearchKitExample`: English/Spanish localization via a String Catalog
  (`Localizable.xcstrings`) covering all user-facing and accessibility strings, with
  pluralized result counts and a locale-aware search prompt (language-filter-forced example
  queries stay verbatim by design).
- `SearchKitExample`: accessibility pass — localized and pluralized VoiceOver result
  announcements, hints for consequential actions (reindex, RAG-prompt disclosure), combined
  mode-banner/error elements, and Dynamic Type-aware line limits in result rows.
- `EmbeddingSpaceManifest` now records the chunking window (`chunkMaxTokens`/`chunkOverlap`),
  and `EmbeddingPipeline.makeManifest` accepts a `chunking:` parameter. Changing the chunking
  configuration now invalidates and rebuilds the index automatically (chunking changes are
  invisible to the per-document content-hash diff). Existing indexes are wiped once on first
  open after upgrading.
