# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
