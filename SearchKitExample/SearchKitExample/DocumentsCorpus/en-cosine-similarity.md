---
id: en-cosine-similarity
title: Distance Metrics for Embeddings
language: en
family: ai-ml
---
Every similarity search rests on a distance metric, and the choice is less mysterious than it looks. Cosine similarity measures the angle between vectors — identical direction scores 1, orthogonal scores 0 — and ignores magnitude entirely. That property fits text: verbosity shouldn't make a document more or less similar, only its direction in meaning-space matters.

Euclidean (L2) distance measures straight-line separation and does respond to magnitude. Dot product responds to both angle and magnitude, and is the cheapest to compute.

Normalization collapses the debate. Scale every vector to unit length and the three metrics agree on ranking: on unit vectors, squared L2 equals 2 − 2·cosine, a monotonic relationship. This is why embedding pipelines L2-normalize as their final step — afterwards, brute-force search is a matrix of dot products, ideal for SIMD and Accelerate.

Practical notes for on-device work: declare your metric when creating a vector index (sqlite-vec supports cosine and L2 per column) and keep it consistent between ingestion and query — indexes freeze it. Remember that engines return cosine distance (1 − similarity), so smaller is better and 0 means identical direction. And beware comparing raw scores across different embedding models; scores are only meaningful within one vector space.
