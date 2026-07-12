---
id: en-nlp-apple
title: Apple's NaturalLanguage Framework
language: en
family: ai-ml
---
NaturalLanguage is Apple's on-device NLP toolbox, covering the pipeline from raw string to semantic vector without a network call: language identification, tokenization, part-of-speech and named-entity tagging, lemmatization, sentiment, and embeddings.

`NLLanguageRecognizer` guesses languages with confidence scores from surprisingly short inputs. `NLTagger` walks text producing tags per token — grammar categories, lemmas, or entities (people, places, organizations), the raw material for keyword extraction and content redaction. Sentiment scoring returns a −1 to 1 polarity per paragraph.

The semantic tier matters most for search. `NLEmbedding` provides static word and sentence vectors with built-in nearest-neighbor lookup. `NLContextualEmbedding`, added in iOS 17, runs a multilingual transformer that emits context-aware token vectors: request assets (they download on demand), check the model's dimension, then enumerate token vectors from an embedding result and pool them — mean pooling plus L2 normalization is the standard recipe for sentence-level vectors feeding a vector store.

Operational gotchas worth knowing upfront: contextual embeddings are unavailable on the iOS Simulator, so test on hardware or macOS; asset downloads need connectivity once; and persist the model identifier and revision alongside your index, because a revision bump silently changes the vector space.
