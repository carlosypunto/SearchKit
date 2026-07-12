---
id: en-fts5
title: Full-Text Search with FTS5 and BM25
language: en
family: data-persistence
---
FTS5 turns SQLite into a search engine. A virtual table tokenizes your text into an inverted index, and MATCH queries return ranked results fast enough for as-you-type search over substantial corpora.

Query syntax is expressive: bare terms are ANDed, quoted strings match phrases, `term*` matches prefixes, `NEAR(a b, 5)` constrains proximity, and boolean operators compose. Ranking comes from the built-in `bm25()` function — the standard probabilistic relevance formula weighing term frequency against document frequency and length. FTS5's convention trips newcomers: scores are negative and lower means more relevant, so `ORDER BY bm25(table)` ascending gives best-first.

Tokenizer choice shapes recall. The default unicode61 tokenizer can strip diacritics (`remove_diacritics 2`), letting unaccented queries match accented text — essential for Spanish, French, or Portuguese content. Porter stemming folds English inflections ("running" matches "run").

Two operational notes. First, user input is not a valid FTS query: unbalanced quotes or stray operators raise syntax errors, so sanitize by quoting tokens. Second, an external-content FTS table can index text stored in a regular table without duplicating it — keep them in sync within the same transaction.
