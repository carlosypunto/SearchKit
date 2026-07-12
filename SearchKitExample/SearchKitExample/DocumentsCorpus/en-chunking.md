---
id: en-chunking
title: Chunking Strategies for Retrieval
language: en
family: ai-ml
---
Chunking defines the retrieval unit of your RAG system, and it quietly determines the ceiling of answer quality. Embeddings average meaning over their input: feed them a whole chapter and every topic in it blurs together; feed them a lone sentence and the retriever finds text that matches words but lacks the surrounding answer.

Fixed-size windows are the reliable baseline — 200 to 500 tokens with 10–20% overlap between consecutive windows. Overlap is not waste; it insures against ideas severed at boundaries, since the continuation appears intact in the next chunk. Tokenize consistently (the NLTokenizer word unit works well for mixed-language corpora) so chunk boundaries are reproducible.

Structure-aware refinements respect the document's own seams: split at paragraphs and headings, never mid-sentence, keep code blocks and tables whole. Semantic chunking goes further by embedding sentences and cutting where inter-sentence similarity drops — coherent topics per chunk at the cost of heavier ingestion.

Two habits pay off regardless of strategy. Prepend the document title to each chunk's text before embedding; it injects topical context that isolated paragraphs lack and markedly improves both lexical and semantic recall. And derive chunk IDs deterministically from document ID and position, so re-ingesting a changed document replaces exactly its own chunks.

Choosing the window size is a negotiation between recall and precision. Small chunks — a hundred tokens or so — embed sharply, because each vector represents one idea, but they strand the reader: the retrieved fragment matches the query yet lacks the sentences around it that actually answer the question. Large chunks carry their own context but embed mushily, averaging three topics into a vector that matches none of them well. The practical answer depends on the corpus: dense reference material tolerates smaller windows than narrative prose, and question-answering workloads want chunks big enough to contain a full answer, while search-and-browse workloads can go smaller because a human will open the source document anyway.

Corpus shape should drive the configuration more than any published heuristic. A collection of short notes — a few hundred words each — barely exceeds a single default-sized window per document, which means chunking effectively never happens and every "chunk" is a whole document. That silently disables everything chunking is supposed to buy: sub-document ranking, focused context, precise citations. For such corpora, shrink the window until typical documents produce several chunks, or accept document-level retrieval deliberately. The failure mode to avoid is assuming chunking is happening when the numbers guarantee it is not.

Overlap deserves more precision than the usual hand-wave. Its purpose is boundary insurance: any sentence cut by a window edge appears whole in the next window. That implies the overlap should be at least as long as a typical sentence — fifteen to twenty-five tokens for most prose — and that overlap much beyond a quarter of the window wastes index space and biases retrieval toward boundary content, which gets embedded twice. Overlap also interacts with deduplication at query time: adjacent chunks of the same document often both match a query, so result assembly should either collapse neighbors or diversify across documents.

A subtle operational trap: chunking parameters are invisible to content-hash-based incremental sync. The hash covers the document's bytes, not the window size, so changing the chunk configuration leaves every previously indexed document untouched — the index keeps serving windows cut with the old settings while new documents get the new ones. Two chunking regimes end up interleaved in one index, and relevance degrades in ways that are maddening to reproduce. The fix is to version chunking parameters alongside the embedding model in the index manifest, so a configuration change invalidates the index just like a model change would.

Finally, evaluate chunking with retrieval metrics, not aesthetics. A chunking change is good if known queries rank their known source passages higher — hit rate at K, mean reciprocal rank — and bad otherwise, no matter how tidy the boundaries look. Build the golden query set first; it turns chunking from a matter of taste into a measurable engineering decision, and it catches regressions when someone later touches the window size, the tokenizer, or the overlap.
