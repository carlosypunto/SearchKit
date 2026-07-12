---
id: en-embeddings
title: Text Embeddings Explained
language: en
family: ai-ml
---
Text embeddings map language into geometry. An embedding model converts a string into a dense vector of floats — typically hundreds of dimensions — positioned so that semantically similar texts land near each other. Similarity search then reduces to measuring distances.

Static embeddings assign each word one fixed vector, which fails on polysemy: "bank" means different things near "river" versus "loan". Contextual embeddings, produced by transformer models, encode each token in light of its surroundings, resolving ambiguity. Apple's NaturalLanguage framework exposes both levels: `NLEmbedding` for static lookups and `NLContextualEmbedding` for contextual token vectors computed on-device.

Sentence-level representations come from pooling token vectors — mean pooling averages them, a robust default — followed by L2 normalization so cosine similarity behaves. Everything downstream depends on consistency: the query must be embedded by the same model, revision, pooling, and normalization as the indexed documents. Change any ingredient and the old vectors are garbage; re-embed the corpus.

Practical quality lever: embed at the right granularity. Whole documents blur topics together; sentences lose context. Paragraph-sized chunks with modest overlap consistently retrieve best in RAG systems.
