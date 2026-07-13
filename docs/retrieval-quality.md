# Retrieval quality — evaluation log

Durable record of how search quality evolves. Every change to embeddings,
chunking, sanitization, or fusion gets measured here — run the suite before
and after, and append a row to the log.

## How to measure

```bash
SEARCHKIT_EVAL=1 swift test --filter Evaluation
```

The suite (`Tests/SearchKitTests/EvaluationTests.swift`) indexes the real
example-app corpus (100 bilingual docs → 301 chunks, chunking 120/24) with the
real `NLContextualEmbedding` model, then runs a hand-built gold set of 26
queries (es + en; exact titles, paraphrases, lexical terms, and stem-free
paraphrases with zero exact-token overlap with their target doc) against each
retrieval mode — including `.auto`, the demo app's path, which the suite
asserts never silently degrades. macOS or a real device only — the model
never works on the iOS Simulator.

Metrics, per mode and per language:

- **hit@1 / hit@3 / hit@5** — fraction of queries whose expected document
  appears in the top k (any chunk of it counts). hit@5 answers "does the user
  see it without scrolling?"; hit@1/hit@3 make position inside the top 5
  visible — a demo-quality result is top 1–2, and aggregate hit@5 alone
  cannot tell rank 1 from rank 5.
- **MRR@10** — mean of `1/rank` of the expected document (0 if absent from the
  top 10). "Is it at the very top or buried?"

The suite also prints a per-query rank table (one column per mode variant) so
marginal hits and per-query regressions are visible without recomputing.

`+lf` rows = the same run with `SearchFilter(language:)` matching each query's
language — this is what the example app does by default, so `hybrid+lf` /
`auto+lf` is the number the demo user experiences.

Caveats: 26 queries means one hit is ~3.8 points of hit@5 — treat single-row
differences near that size as noise. The stem-free block (8 queries) is
deliberately adversarial for BM25; it exists to keep fusion tuning honest
(without it, any down-weighting of the vector branch looks free because
text-only already hits everything else).

## Results log

All rows measured on macOS, same machine, same corpus. Gold-set changes
re-baseline the log (git history of `EvaluationTests.swift` tracks them) —
rows are only comparable within their gold-set section.

### Gold set v1 — 18 queries (2026-07-12)

Cells are hit@5 / MRR@10.

| Date | State | vector | text | text+lf | hybrid | hybrid+lf |
|---|---|---|---|---|---|---|
| 2026-07-12 | 0.1.0 baseline | 44.4% / 0.321 | 100% / 0.958 | — | 83.3% / 0.728 | — |
| 2026-07-12 | + stopwords, query language hint | 44.4% / 0.321 | 100% / 0.931 | 100% / 0.972 | 83.3% / 0.717 | 88.9% / 0.752 |
| 2026-07-12 | + mean-centering (fusion still k=60) | 38.9% / 0.286 | 100% / 0.931 | 100% / 0.972 | 88.9% / 0.730 | 94.4% / 0.733 |
| 2026-07-12 | + SearchKit-side RRF fusion k=20 (**0.1.1**) | 38.9% / 0.286 | 100% / 0.931 | 100% / 0.972 | 88.9% / 0.758 | 94.4% / 0.770 |

(The baseline row predates the `+lf` variant in the suite, hence the dashes.)

Ablations (2026-07-12, not shipped): **k=10** — hybrid 88.9% / 0.784,
hybrid+lf 94.4% / 0.796 (adopted later, see v2). **k=20 without
mean-centering** — hybrid 83.3% / 0.747, hybrid+lf 88.9% / 0.769;
mean-centering is worth +5.6 pp hit@5 on the hybrid path, which is why it
ships despite not improving vector-only.

### Gold set v2 — 26 queries (2026-07-13, +8 stem-free)

Cells are hit@1 / hit@3 / hit@5 / MRR@10 for `hybrid+lf` (`auto+lf` is
identical — auto never degraded). Reference points on this gold set:
vector 19.2 / 26.9 / 30.8 / 0.236 · text+lf 65.4 / 69.2 / 69.2 / 0.673.

| Date | State | hybrid+lf |
|---|---|---|
| 2026-07-13 | 0.1.1 fusion (k=20, unweighted) — re-baseline | 46.2 / 61.5 / 65.4 / 0.539 |
| 2026-07-13 | weighted RRF wV=0.5, k=20 | 46.2 / 65.4 / 69.2 / 0.559 |
| 2026-07-13 | k=10, unweighted | 46.2 / 65.4 / 69.2 / 0.559 |
| 2026-07-13 | **weighted RRF wV=0.5, k=10 (shipped)** | 53.8 / 69.2 / 69.2 / 0.615 |
| 2026-07-13 | wV=0.25, k=10 | 53.8 / 69.2 / 69.2 / 0.615 |
| 2026-07-13 | + `Reranker` hook, `NoOpReranker` default (**0.2.0**) | 53.8 / 69.2 / 69.2 / 0.615 |

wV=0.25 adds nothing over wV=0.5, so the milder weight ships (it leaves the
vector branch more say on corpora where it is stronger).

## Reading the current numbers

- **The demo paraphrases are now top 1–2** under `auto+lf`: "descargar muchas
  imágenes…" went from rank 5 to rank 1 and "find the K nearest vectors…"
  (the former known miss) from absent to rank 2. "cómo evitar data races…"
  stays at rank 2 behind `es-sendable` — a legitimate BM25 tie, both docs
  describe data races over shared mutable state.
- **Hybrid now matches text-only on hit@5** (69.2%) and trails it only
  slightly in MRR (0.615 vs 0.673), while keeping the semantic insurance
  text-only cannot give.
- **The stem-free block is the ceiling of the on-device model**: 7 of its 8
  queries miss in *every* mode, including vector-only — the 512d mean-pooled
  model cannot bridge zero-overlap paraphrases on this topically homogeneous
  corpus. The eighth ("put an application… lightweight box" → `en-docker`,
  vector rank 1) is found by the vector branch but diluted below top 5 by
  fusion. Further gains here need a reranker (see `ROADMAP.md`), not more
  fusion tuning.
