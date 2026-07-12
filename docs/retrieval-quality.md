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
real `NLContextualEmbedding` model, then runs a hand-built gold set of 18
queries (es + en; exact titles, paraphrases, lexical terms) against each
forced retrieval mode. macOS or a real device only — the model never works on
the iOS Simulator.

Metrics, per mode and per language:

- **hit@5** — fraction of queries whose expected document appears in the top 5
  (any chunk of it counts). "Does the user see it without scrolling?"
- **MRR@10** — mean of `1/rank` of the expected document (0 if absent from the
  top 10). "Is it at the very top or buried?"

`+lf` rows = the same run with `SearchFilter(language:)` matching each query's
language — this is what the example app does by default, so `hybrid+lf` is
the number the demo user experiences.

Caveats: 18 queries means one hit is ~5.6 points of hit@5 — treat single-row
differences near that size as noise. The gold set slightly favors the lexical
branch (even the paraphrase queries share some stems with the corpus); a
future revision should add stem-free paraphrases.

## Results log

Cells are hit@5 / MRR@10. All rows measured on macOS, same machine, same
corpus and gold set (git history of `EvaluationTests.swift` tracks gold-set
changes — re-baseline whenever it changes).

| Date | State | vector | text | text+lf | hybrid | hybrid+lf |
|---|---|---|---|---|---|---|
| 2026-07-12 | 0.1.0 baseline | 44.4% / 0.321 | 100% / 0.958 | — | 83.3% / 0.728 | — |
| 2026-07-12 | + stopwords, query language hint | 44.4% / 0.321 | 100% / 0.931 | 100% / 0.972 | 83.3% / 0.717 | 88.9% / 0.752 |
| 2026-07-12 | + mean-centering (fusion still k=60) | 38.9% / 0.286 | 100% / 0.931 | 100% / 0.972 | 88.9% / 0.730 | 94.4% / 0.733 |
| 2026-07-12 | + SearchKit-side RRF fusion k=20 (**0.1.1**) | 38.9% / 0.286 | 100% / 0.931 | 100% / 0.972 | 88.9% / 0.758 | 94.4% / 0.770 |

(The baseline row predates the `+lf` variant in the suite, hence the dashes.)

### Ablations (2026-07-12, not shipped)

- **k=10 instead of k=20** (with mean-centering): hybrid 88.9% / 0.784,
  hybrid+lf 94.4% / 0.796. Slightly better MRR; k=20 kept to avoid tuning the
  constant against only 18 queries. Revisit when the gold set grows.
- **k=20 without mean-centering**: hybrid 83.3% / 0.747, hybrid+lf
  88.9% / 0.769. Mean-centering is worth +5.6 pp hit@5 on the hybrid path in
  both k variants, which is why it ships despite not improving vector-only.

## Reading the current numbers

- **The vector branch is the weak leg** (≈39–44% hit@5) and mean-centering did
  not measurably fix vector-only — its value shows up in fusion. This is the
  ceiling of the on-device model (512d, mean pooling) on a topically
  homogeneous corpus; further gains need a reranker (see `ROADMAP.md`), not
  more transform tuning.
- **Text-only still beats hybrid in MRR** (0.972 vs 0.770). BM25 barely misses
  on this corpus; hybrid is insurance for purely semantic queries where BM25
  fails outright, which the gold set under-represents.
- **Known acceptable miss** (the only hybrid+lf miss): "find the K nearest
  vectors to a query" returns `en-rag-pipelines` above `en-vector-databases` —
  semantically defensible, both documents discuss the topic.
