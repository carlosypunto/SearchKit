---
id: en-fine-tuning
title: Fine-Tuning versus Retrieval
language: en
family: ai-ml
---
When a language model lacks what your product needs, you either change the model or change its input. Fine-tuning and retrieval-augmented generation are the two levers, and they solve different problems more often than they compete.

Fine-tuning continues training on curated examples, reshaping behavior: output format, domain vocabulary, tone, task-specific skills. Parameter-efficient methods like LoRA touch a small adapter instead of every weight, making the process affordable. What fine-tuning does poorly is facts — knowledge bakes in at training time, updates require retraining, and the model cannot cite where an answer came from.

RAG leaves weights alone and supplies knowledge through the prompt, retrieved from your index per query. Facts update by editing documents; answers carry provenance; access control applies at retrieval time. What RAG cannot do is change how the model behaves — a chaotic formatter stays chaotic no matter how good the context is.

Decision heuristic: dynamic or auditable knowledge → RAG; consistent behavior, style, or structured output → fine-tuning; both needs → both techniques, a domain-tuned model fed by fresh retrieval.

Start with RAG plus prompt engineering; it iterates in minutes rather than training runs, and it usually proves sufficient.
