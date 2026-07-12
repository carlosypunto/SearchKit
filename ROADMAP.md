# Roadmap

**Future work only.** Shipped releases live in `CHANGELOG.md`; the
retrieval-quality numbers backing these decisions live in
[`docs/retrieval-quality.md`](docs/retrieval-quality.md). When a release
ships, its section is **deleted** from this file (the CHANGELOG entry is the
record) — see the release checklist in `AGENTS.md`, which exists so no
document goes stale.

## 0.2.0 — simplification pass (next, breaking changes allowed)

Context: 0.1.1 shipped the retrieval-quality work (mean-centering, RRF k = 20,
FTS stopwords, evaluation suite — see the CHANGELOG). 0.2.0 is the cleanup
that work enabled. Candidates, to be decided — a working list, not a
commitment:

- **Make `.meanCentering` the default** in `EmbeddingPipeline.makeManifest`.
  Behavior change: every consumer's index invalidates and rebuilds once. The
  eval numbers justify it as the sensible default for the real model; keep
  `.identity` available (tests and degenerate corpora need it).
- **Revisit `EmbeddingPipeline`'s role.** After 0.1.1 it only forwards to the
  provider, validates dimension, and builds the manifest — transform
  application lives in `SearchService` (it needs index state). Options: fold
  manifest-building into `SearchService`/`SearchIndexStore`, or keep the type
  but rename/shrink its surface. Whatever reads simplest wins.
- **Prune redundant conveniences** (e.g. `SearchService.search(_:topK:)`)
  and any API that exists only because 0.1.0 shipped it.
- **Reconsider the FTS stopword list's visibility** — currently an internal
  constant; decide whether consumers may need to extend it (probably not:
  additive if ever needed).

## Deferred designs (0.2.x+)

Two stages were designed before 0.1.0, removed from the MVP, and are worth
keeping on the record. Both were originally sketched in a pre-release design
doc (`futuras_evoluciones.md`, never committed); this section replaces it and
updates each design with what the 0.1.1 work taught us.

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
  persisted projection matrix, output-dimension bookkeeping.
- **Model-adaptation matrix**: a learned linear map aligning a new embedding
  model's space with an existing index, avoiding a full corpus re-embed.
  Note this fights the "index is a regenerable cache" principle — evaluate
  whether it is ever worth the complexity on-device.

At that point, design the abstraction around the real requirements (fitting
step, persisted parameters, dimension mapping, generation freezing) rather
than the 0.1.0-era sketch.

### Reranker protocol

**What it was — and this design still holds:** a post-retrieval stage that
reorders the few fused candidates using a more expensive, more precise signal.
It never touches the index or the vector space; it only reorders a short list.

```swift
/// Reorders retrieved candidates using a (potentially expensive) signal.
public protocol Reranker: Sendable {
    func rerank(query: String, candidates: [SearchCandidate]) async throws -> [SearchCandidate]
}

/// Default implementation: keeps the store's ranking untouched.
public struct NoOpReranker: Reranker {
    public init() {}
    public func rerank(query: String, candidates: [SearchCandidate]) async throws -> [SearchCandidate] {
        candidates
    }
}
```

**Reintroduction steps** (updated to the current `SearchService.search` flow):

1. Recreate the protocol in `Sources/SearchKit/Search/Reranker.swift`.
2. Add `reranker: any Reranker = NoOpReranker()` to `SearchService.init`
   (additive — this can even land in a 0.1.x).
3. Invoke it in `SearchService.search(_:options:)` **between** `retrieve` and
   `recallPolicy.apply`: the reranker sees the fused list; deterministic
   recall keeps the last word on exact-title injection; and the existing
   dedup + filter re-validation at the end of `search` run *after* it, so a
   reranker cannot accidentally resurrect filtered-out candidates.
4. With filters active the reranker receives filter-compliant candidates
   only; it does not need to know the filter.
5. Wire it into the evaluation suite: a reranker is precisely the kind of
   change `docs/retrieval-quality.md` exists to measure. This is also the most
   promising lever for the remaining quality gap — hybrid still trails
   text-only in MRR (0.770 vs 0.972 on the current gold set) because the
   vector branch of the on-device model is weak; a cross-encoder over ~10–50
   candidates attacks exactly that.

**Candidate signals:** on-device cross-encoder scoring `(query, chunk)` pairs
(Core ML / MLX — viable because only the top candidates are scored, never the
corpus); Apple Foundation Models listwise reranking; catalog signals
(`family` boost from session context, document freshness, preferred
language).

## Related, tracked elsewhere

- **SQLiteVecKit**: SearchKit no longer uses `VectorStore.searchHybrid`
  (fusion happens in `SearchIndexStore` since 0.1.1). Whether SQLiteVecKit
  exposes a tunable `rrfK` (additive, 0.x minor there) is that repo's
  decision — nothing in SearchKit depends on it.
- **FTS5 stemming** (es/en morphology in the lexical branch) requires a
  tokenizer change in SQLiteVecKit's frozen schema — a major-version event
  there. Known limitation, not planned.
