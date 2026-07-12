---
id: en-tokenization
title: Tokenization from Words to Subwords
language: en
family: ai-ml
---
Tokenization is the quiet foundation under every language system: before anything is embedded, indexed, or generated, text becomes a sequence of tokens. The choice of unit shapes everything downstream.

Word-level tokenization suits classical NLP and retrieval. Apple's `NLTokenizer` enumerates word, sentence, or paragraph ranges directly over the original string, handling punctuation, contractions, emoji, and space-free scripts like Japanese — cases where naive whitespace splitting fails immediately. Because it yields ranges rather than copies, it is efficient for chunking large documents.

Modern language models tokenize into subwords using algorithms like byte-pair encoding: common words stay whole, rare words decompose into learned fragments, and any string — typos and neologisms included — is representable from a fixed vocabulary. Context windows are measured in these tokens; as a rule of thumb, English averages three-quarters of a word per token, and morphology-rich languages fragment more.

In on-device search, two tokenizers matter and they are different. Your chunker's tokenizer sizes embedding windows. Your FTS5 tokenizer decides lexical matching — whether "cancion" finds "canción" hinges on its diacritic configuration. Misaligned assumptions between the two are a subtle source of recall bugs.
