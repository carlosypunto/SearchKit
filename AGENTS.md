# AGENTS.md

Guidance for AI coding agents (opencode, Codex, Cursor, Claude Code) working in this repository. Canonical, tool-agnostic.

## What this is

`SearchKit` is a Swift Package: the on-device RAG (retrieval-augmented generation) consumer
layer for a documentation-corpus search app. It sits on top of `SQLiteVecStore` (from the sibling
package `SQLiteVecKit`, pulled via SPM from `https://github.com/carlosypunto/SQLiteVecKit`,
`main` branch) and owns everything domain-specific: catalog ingestion, chunking, embedding,
hybrid retrieval, and prompt construction. `SQLiteVecStore` itself is out of scope here — treat
it as an external dependency, not code to modify.

`SearchKitExample/` is a SwiftUI demo app (iOS 17+/macOS 14+, Xcode project, not part of the
package) that exercises the whole pipeline against a bundled bilingual Markdown corpus
(`DocumentsCorpus/`). Real embeddings only work on macOS or a physical device, never on the
iOS Simulator.

## Commands

```bash
swift build
swift test

# Run one suite or test (Swift Testing filter syntax, regex-based)
swift test --filter SearchTests
swift test --filter hybridFindsExactTerm

# Exclude the two opt-in/slow suites from a normal run
swift test --skip Benchmark --skip RealEmbedding

# Real NLContextualEmbedding integration test — needs model assets on-device;
# never works on the iOS Simulator, only macOS or a real device
SEARCHKIT_REAL_EMBEDDING=1 swift test --filter RealEmbedding

# Retrieval-quality evaluation (real model + the example-app corpus): prints
# hit@5 / MRR@10 per retrieval mode and language over a gold set. Run it
# before AND after any change to embeddings, chunking, or fusion, and append
# the results to docs/retrieval-quality.md.
SEARCHKIT_EVAL=1 swift test --filter Evaluation
```

Tests use **Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`), not XCTest.

## Architecture

Pipeline, in order: `CatalogRepository` → `ChunkingService` → `EmbeddingPipeline` →
`SearchIndexStore` (sync/indexing), and `SearchService` → `SearchIndexStore` →
`DeterministicRecallPolicy` (query). Each stage is a separate, independently testable type;
`SearchService` (`Sources/SearchKit/Search/SearchService.swift`) is the only orchestrator that
wires them together — start there to see the whole flow.

- **Catalog** (`Catalog/`): `CatalogRepository` protocol + `BundleCatalogRepository`, which reads
  every `.md` resource with YAML-ish front matter (`FrontMatterParser`) into a `SearchDocument`.
  `contentHash` is a SHA-256 of the *entire raw file* (front matter included), so editing
  metadata alone triggers reingestion.
- **Chunking** (`ChunkingService`): overlapping word-token windows via `NLTokenizer`, with
  deterministic 63-bit FNV-1a chunk IDs (`documentID#ordinal`) kept positive for use as SQLite
  rowids. Determinism is load-bearing: it's what makes per-document reingestion
  (`delete(source:)` + `insertBatch`) idempotent.
- **Embedding** (`Embedding/`): `TextEmbeddingProvider` protocol, `ContextualEmbeddingProvider`
  (real, `NLContextualEmbedding`-backed, mean-pooled + L2-normalized, Latin-script model shared
  across es/en) and `EmbeddingPipeline`, which enforces that indexing and query vectors go
  through identical steps and validates dimension against the manifest. `VectorTransformKind`
  selects the post-embedding transform recorded in the manifest; `.meanCentering` is applied by
  `SearchService` (not the pipeline — it needs the corpus centroid, which only exists once the
  index does).
- **Index** (`SearchIndexStore`): the *only* type that imports `SQLiteVecStore`. Owns two extra
  consumer tables (`search_manifest`, `indexed_documents`) alongside the store's own `chunks` /
  `chunks_fts` tables, which it never touches directly. On open it validates the persisted
  `EmbeddingSpaceManifest` — any semantic mismatch (model, dimension, pooling, transform,
  chunking window) wipes the whole index, and so does a manifest that fails to decode (older or
  corrupt JSON). **There is no row migration between vector spaces, ever** — the index file is
  treated as a fully regenerable cache, not a database to preserve.
- **Search** (`Search/`): `SearchService` orchestrates `.auto` mode's controlled degradation
  (hybrid → vector-only on FTS syntax failure or no usable terms → text-only on embedding
  failure), while forced modes (`.hybrid`/`.vector`/`.text`) surface their failures instead of
  falling back. `FTSQuerySanitizer` quotes every token so FTS5 operators/punctuation in free user
  text can never break the query. `DeterministicRecallPolicy` is a testable, explicit rule
  layered *after* retrieval: an exact (case/diacritic-insensitive) title match must appear in
  results even if hybrid retrieval missed it — injected candidates are re-validated against the
  request's `SearchFilter` before being returned. `PromptBuilder` is a pure function (no store,
  no LLM call) that turns candidates into a grounded RAG prompt.

### Invariants worth knowing before changing things

- `SearchCandidate.score` is always "higher = better", but its scale differs by retrieval mode
  (RRF for hybrid, negated distance for vector-only, negated BM25 for text-only) — **scores from
  different modes must never be compared or mixed**.
- Filters (`SearchFilter.family`/`.language`) are applied as SQL (`json_extract` on chunk
  metadata) in every retrieval mode, and applied *again* in Swift after deterministic recall
  injection, since injected candidates bypass the SQL filter.
- The manifest's `transformIdentifier`/`transformVersion` come from the `transform:` argument
  to `makeManifest` (`VectorTransformKind`, default `.identity`). With `.meanCentering`, the
  corpus centroid is computed on the first full indexing pass, persisted in `search_manifest`
  (key `vector_centroid`), and **frozen for the index generation**: incremental syncs reuse it,
  only a rebuild recomputes it. Query and chunk vectors must go through the same centering —
  `SearchService.queryVector(for:language:)` is the single query-side path that guarantees it.
- Hybrid fusion (RRF, k = 20) lives in `SearchIndexStore.searchHybrid`, not in
  `SQLiteVecStore.searchHybrid` (whose k = 60 is hardcoded): both branches are overfetched to
  `min(topK*4, maxTopK)` and fused here so the constant stays tunable. k was chosen against the
  `Evaluation` suite — re-run it before changing the constant.
- `IndexDistanceMetric` (cosine/l2) is frozen into the SQLite schema by `SQLiteVecStore` itself —
  changing it always recreates the index file and forces a full re-embed, it's never migrated.
- `ChunkingConfiguration` is part of the persisted manifest (`chunkMaxTokens`/`chunkOverlap`):
  chunking changes are invisible to the per-document `contentHash` diff, so they invalidate
  through the manifest instead. Pass the **same** configuration to `ChunkingService` and to
  `EmbeddingPipeline.makeManifest(chunking:)` — diverging values mean the manifest lies about
  how the rows were actually chunked.

## Testing conventions

- `Tests/SearchKitTests/TestSupport.swift` provides the shared fixtures used by nearly every
  test: `FakeEmbeddingProvider` (deterministic bag-of-hashed-buckets embedding — supports a
  `synonyms` map to simulate semantic matches like "automóvil" ≈ "coche" without a real model),
  `withTemporaryDatabase`, `makeDocument`, and `makeSearchStack`. Reuse these rather than
  building fixtures from scratch.
- `BenchmarkTests` (`.tags(.benchmark)`), `RealEmbeddingIntegrationTests` (gated on
  `SEARCHKIT_REAL_EMBEDDING=1`) and `EvaluationTests` (gated on `SEARCHKIT_EVAL=1`) are
  opt-in / slow — exclude them for routine iteration with
  `--skip Benchmark --skip RealEmbedding`.
- All test files use `@testable import SearchKit`.
