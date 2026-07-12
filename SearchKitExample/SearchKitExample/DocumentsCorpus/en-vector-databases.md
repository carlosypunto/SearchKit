---
id: en-vector-databases
title: Vector Databases and Similarity Search
language: en
family: data-persistence
---
Vector databases exist to answer nearest-neighbor queries over embeddings: high-dimensional float arrays that encode the meaning of text, images, or audio. Store a few thousand — or a few billion — vectors, then ask which K are closest to a query vector.

Closeness needs a metric. Cosine distance compares directions and dominates text retrieval because document length shouldn't drive similarity; L2 (Euclidean) distance suits spaces where magnitude carries signal. Normalize vectors to unit length and the two rankings coincide, which is why embedding pipelines normalize by default.

Exact brute-force KNN scans every vector — trivially correct, and entirely adequate up to hundreds of thousands of vectors on modern hardware. Beyond that, approximate indexes (HNSW graphs, IVF partitions, product quantization) trade a sliver of recall for orders-of-magnitude speedups. On-device catalogs rarely need them.

For Apple-platform work, sqlite-vec brings vector search into SQLite as a virtual table: embeddings live beside relational data, joins work, transactions cover both. Pair it with FTS5 for lexical matching and fuse the two rankings with Reciprocal Rank Fusion, and a single database file delivers hybrid semantic search with zero infrastructure.
