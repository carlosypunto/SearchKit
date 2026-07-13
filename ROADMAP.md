# Roadmap

**Future work only.** Shipped releases live in `CHANGELOG.md`; the
retrieval-quality numbers backing these decisions live in
[`docs/retrieval-quality.md`](docs/retrieval-quality.md). When a release
ships, its section is **deleted** from this file (the CHANGELOG entry is the
record) — see the release checklist in `AGENTS.md`, which exists so no
document goes stale.

## Deferred designs (0.2.x+)

Two stages were designed before 0.1.0, removed from the MVP, and are worth
keeping on the record. Both were originally sketched in a pre-release design
doc (`futuras_evoluciones.md`, never committed); this section replaces it and
updates each design with what the 0.1.1 work taught us. Decisions closed with
0.2.0, for the record: `EmbeddingPipeline` stays as-is (single embedding path,
dimension validation, manifest building still earn the type its keep), and the
FTS stopword list stays internal (exposing it later is additive).

### VectorTransform protocol

**What it was:** a post-embedding transform applied identically at indexing
and query time, identified in the manifest so a change invalidates the index.

```swift
public protocol VectorTransform: Sendable {
    var identifier: String { get }
    var version: String { get }
    func apply(_ vector: [Float]) -> [Float]
}
```

**Status: superseded, not resurrect-as-is.** 0.1.1 shipped the closed enum
`VectorTransformKind` instead, and the first real transform (mean-centering)
proved the protocol sketch wrong in three ways:

1. **Transforms can be stateful.** Mean-centering needs the corpus centroid,
   which does not exist until the index does — so a stateless
   `apply(_:)`-inside-`EmbeddingPipeline` cannot express it. Application lives
   in `SearchService`, and the parameters (the centroid) are persisted next to
   the manifest and frozen per index generation.
2. **Transforms can change dimension** (PCA). The manifest and the store
   schema must then record the *output* dimension, not the provider's.
3. **Consumer-supplied transforms are a symmetry footgun.** The whole contract
   is "identical at indexing and query time"; an open protocol invites
   violations the compiler can't catch. The closed enum keeps the invariant
   enforceable.

**Reintroduce when** a second fitted transform actually lands — the concrete
candidates, in likely order:

- **PCA / dimension reduction**: project `NLContextualEmbedding`'s 512d down
  to speed up KNN and shrink the index file. Requires: offline fitting,
  persisted projection matrix, output-dimension bookkeeping. **Trigger:** a
  corpus far larger than the demo's (~100 docs) — PCA buys KNN speed and
  index size, not retrieval quality, and at demo scale both are already
  negligible. Revisit when a real corpus makes either cost measurable.
- **Model-adaptation matrix**: a learned linear map aligning a new embedding
  model's space with an existing index, avoiding a full corpus re-embed.
  Note this fights the "index is a regenerable cache" principle — evaluate
  whether it is ever worth the complexity on-device.

At that point, design the abstraction around the real requirements (fitting
step, persisted parameters, dimension mapping, generation freezing) rather
than the 0.1.0-era sketch.

### Reranker implementations

The **hook shipped in 0.2.0**: `Reranker` protocol + `NoOpReranker` default,
invoked by `SearchService.search` between retrieval and deterministic recall
(recall keeps the last word on exact-title injection; the final dedup +
filter re-validation run after the reranker, so it can never resurrect
filtered-out candidates, and with filters active it only ever sees
filter-compliant candidates). What remains is future work: a *real* reranker —
a post-retrieval stage that reorders the few fused candidates using a more
expensive, more precise signal. It never touches the index or the vector
space; it only reorders a short list.

**When one lands, wire it into the evaluation suite**: a reranker is precisely
the kind of change `docs/retrieval-quality.md` exists to measure. This is also
the most promising lever for the remaining quality gap — the stem-free block
of the gold set (queries with zero token overlap with their target doc) misses
almost entirely in every mode because the on-device vector branch is weak
(~31% hit@5); a cross-encoder over ~10–50 candidates attacks exactly that.

**Candidate implementations** — all three were reviewed for 0.2.0 and
deliberately deferred; costs differ by an order of magnitude between them:

- **Catalog signals** (`family` boost from session context, document
  freshness, preferred language): pure Swift, deterministic, CI-testable and
  evaluable today — the cheapest first reranker and a good way to shake down
  the hook with a real implementation. Its limit: it re-scores with metadata,
  not meaning, so it does **not** attack the stem-free gap.
- **Apple Foundation Models listwise reranking**: the on-device LLM reorders
  the top candidates given the query — the only native option that attacks
  the semantic gap. Requires macOS 26 / iOS 26 plus an Apple
  Intelligence-capable device, so it must be `#available`-gated with a
  controlled fallback (the hook's contract already supports this: throw or
  return the input unchanged). Not CI-testable; latency and quality must be
  measured with the eval suite on real hardware before it can be a default.
- **Core ML / MLX cross-encoder** scoring `(query, chunk)` pairs: the highest
  expected precision (this is the standard retrieval-literature answer to the
  stem-free block). Viable on-device because only the top candidates are
  scored, never the corpus — but there is no ready-made es/en cross-encoder
  in Core ML format, so this means sourcing, converting and validating an
  external model: a parallel project in its own right, not a SearchKit task.

## Related, tracked elsewhere

- **SQLiteVecKit**: SearchKit no longer uses `VectorStore.searchHybrid`
  (fusion happens in `SearchIndexStore` since 0.1.1). Whether SQLiteVecKit
  exposes a tunable `rrfK` (additive, 0.x minor there) is that repo's
  decision — nothing in SearchKit depends on it.
- **FTS5 stemming** (es/en morphology in the lexical branch) requires a
  tokenizer change in SQLiteVecKit's frozen schema — a major-version event
  there. Known limitation, not planned.
