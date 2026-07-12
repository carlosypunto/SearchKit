---
id: en-hybrid-search
title: Hybrid Search with Reciprocal Rank Fusion
language: en
family: ai-ml
---
Semantic and lexical retrieval have complementary blind spots. Vector search understands paraphrase and crosses vocabulary gaps, but smears exact identifiers — error codes, SKUs, rare proper nouns — into fuzzy neighborhoods. BM25 nails exact terms and phrases but is blind to synonymy. Hybrid search runs both legs and merges their rankings, capturing each one's strength.

Merging is the interesting problem, because the scores are incommensurable: cosine distances live in [0, 2], BM25 values are negative and unbounded, and no linear combination of the two is principled. Score-based fusion requires per-corpus calibration that breaks as data drifts.

Reciprocal Rank Fusion sidesteps scores entirely. Each document earns 1/(k + rank) from every result list containing it, with k = 60 the conventional damping constant; sum the contributions and sort. Documents ranked well by both retrievers rise to the top, single-list hits still surface, and there is nothing to calibrate. Despite its simplicity, RRF remains a strong baseline that trained fusion models only modestly beat.

Implementation notes: over-fetch each leg (three to four times the final K) so fusion sees enough candidates; deduplicate by document before display when multiple chunks of one document surface; and keep tie-breaking deterministic so results are reproducible.
