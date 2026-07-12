---
id: en-prompt-engineering
title: Prompt Design for Grounded Generation
language: en
family: ai-ml
---
The prompt is where retrieval hands off to generation, and its design decides whether the model actually uses your carefully retrieved context. The goal is grounding: answers derived from the provided passages, not from the model's parametric memory.

A grounded prompt has three sections. Instructions state the rules — answer only from the context below; if the answer is not present, say so explicitly. That escape clause is your main defense against hallucination; without permission to say "I don't know", models improvise confidently. The context section lists retrieved chunks, each labeled with its provenance (document title, section) and separated by unambiguous delimiters. The question comes last, keeping it closest in the model's attention.

Provenance labels enable citations, which transform user trust: an answer pointing to "Setup Guide, section 3" is verifiable. Position effects are real — models attend best to the start and end of long prompts — so if you include many chunks, place the strongest ones at the edges.

More context is not better context. Irrelevant chunks actively degrade answers by diluting attention and inviting tangents. A disciplined topK with high-precision retrieval beats a generous one; measure answer quality against retrieval size rather than assuming bigger is safer.
