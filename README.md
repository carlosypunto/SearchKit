# SearchKit

![CI](https://github.com/carlosypunto/SearchKit/actions/workflows/ci.yml/badge.svg)
![Docs](https://github.com/carlosypunto/SearchKit/actions/workflows/docs.yml/badge.svg)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)

On-device RAG (retrieval-augmented generation) consumer layer for a documentation-corpus search app, written in Swift. SearchKit owns everything domain-specific — catalog ingestion, chunking, embedding, hybrid retrieval, deterministic recall and prompt construction — on top of [`SQLiteVecKit`](https://github.com/carlosypunto/SQLiteVecKit)'s `SQLiteVecStore`, which provides the SQLite vector + FTS5 storage.

Everything runs locally: embeddings come from Apple's `NLContextualEmbedding` (Natural Language framework), storage is a single SQLite file, and the final prompt is handed to whatever LLM the caller chooses. No network calls are made by this package.

## Requirements

- Swift 6.0 toolchain (strict concurrency)
- iOS 17+ / macOS 14+
- `ContextualEmbeddingProvider` (the real embedding backend) does **not** work on the iOS Simulator — use macOS or a physical device. Tests cover this with a deterministic fake.

## Installation

Add SearchKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/carlosypunto/SearchKit", exact: "0.2.0")
]
```

SearchKit itself depends on [`SQLiteVecKit`](https://github.com/carlosypunto/SQLiteVecKit) (pinned to `0.1.1`), pulled transitively via SPM.

## Quick start

```swift
import SearchKit

// 1. Embedding stack: real provider + pipeline (indexing and query vectors
//    are guaranteed to go through identical steps).
let provider = try ContextualEmbeddingProvider(languageCode: "es")
let pipeline = EmbeddingPipeline(provider: provider)
let manifest = await pipeline.makeManifest() // model, dimension, pooling, metric, mean-centering…

// 2. Index store: a single SQLite file, treated as a regenerable cache.
//    Any manifest mismatch (model change, dimension change…) wipes it.
let dbURL = URL.applicationSupportDirectory.appending(path: "search-index.sqlite")
let indexStore = try await SearchIndexStore(dbURL: dbURL, manifest: manifest)

// 3. Orchestrator.
let service = SearchService(indexStore: indexStore, pipeline: pipeline)

// 4. Ingest the catalog (Markdown files with front matter, bundled as resources).
let catalog = BundleCatalogRepository(bundle: .main)
let documents = try await catalog.documents()
let summary = try await service.sync(documents: documents)
print("indexed \(summary.indexed), removed \(summary.removed), unchanged \(summary.unchanged)")

// 5. Query. `.auto` mode degrades gracefully (hybrid → vector-only → text-only).
let outcome = try await service.search(
    "How work strict concurrency?",
    options: SearchOptions(mode: .auto, topK: 8, filter: SearchFilter(language: "es"))
)

// 6. Build a grounded RAG prompt and forward it to your LLM of choice.
let prompt = PromptBuilder().prompt(
    question: "How work strict concurrency?",
    candidates: outcome.candidates,
    language: .spanish
)
```

## Architecture

```
Indexing:  CatalogRepository → ChunkingService → EmbeddingPipeline → SearchIndexStore
Querying:  SearchService → SearchIndexStore → Reranker → DeterministicRecallPolicy → PromptBuilder
```

Each stage is a separate, independently testable type. `SearchService` is the only orchestrator that wires them together — start there to see the whole flow. The `Reranker` protocol (default: `NoOpReranker`) is an extension point for post-retrieval reordering of the fused candidate list — e.g. an on-device cross-encoder; it runs before deterministic recall and the final filter re-validation, so it can never suppress an exact-title injection or resurrect filtered-out candidates. Design invariants (score scales, filter re-validation, manifest invalidation) are documented in [`AGENTS.md`](AGENTS.md) and in the DocC catalog (`Sources/SearchKit/Documentation.docc`).

The rendered API documentation is published at
[carlosypunto.github.io/SearchKit](https://carlosypunto.github.io/SearchKit/documentation/searchkit/)
on every push to `main` (the same workflow gates PRs with `docc --warnings-as-errors`).

### Search modes

| Mode      | Retrieval                          | On failure                                   |
| --------- | ---------------------------------- | -------------------------------------------- |
| `.auto`   | Hybrid (RRF of vector KNN + BM25)  | Degrades: → vector-only → text-only          |
| `.hybrid` | Hybrid                             | Throws (no fallback)                         |
| `.vector` | Vector KNN only                    | Throws                                       |
| `.text`   | FTS5/BM25 only                     | Throws                                       |

`SearchOutcome.mode` reports the mode actually used, so callers can detect an `.auto` degradation. Scores are always "higher = better" but their scale differs per mode — never compare scores across modes.

## Example app

[`SearchKitExample/`](SearchKitExample) is a SwiftUI demo (iOS 17+ / macOS 14+) that runs the
whole pipeline against a bundled bilingual corpus of ~100 Markdown documents: hybrid, vector
and text modes, family/language filters, distance metric switching (watch the index rebuild)
and a RAG prompt preview per result. Open the Xcode project and run the macOS scheme —
real embeddings do not work on the iOS Simulator.

## Testing

Tests use [Swift Testing](https://developer.apple.com/documentation/testing) (`@Suite`, `@Test`, `#expect`), not XCTest.

```bash
swift build
swift test

# Exclude the two opt-in/slow suites from a normal run
swift test --skip Benchmark --skip RealEmbedding

# Real NLContextualEmbedding integration test — needs model assets on-device;
# never works on the iOS Simulator, only macOS or a real device
SEARCHKIT_REAL_EMBEDDING=1 swift test --filter RealEmbedding

# Retrieval-quality evaluation (real model + the example-app corpus; macOS or
# a real device). Results log: docs/retrieval-quality.md
SEARCHKIT_EVAL=1 swift test --filter Evaluation
```

## License

MIT — see [LICENSE](LICENSE).
