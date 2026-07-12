---
id: es-prompt-engineering
title: Ingeniería de prompts para RAG
language: es
family: ai-ml
---
En un sistema RAG, el prompt es el contrato entre tu recuperación y el modelo generativo. Su misión es delimitar: el modelo debe responder desde el contexto proporcionado, no desde su memoria de entrenamiento.

La estructura clásica tiene tres partes. Las instrucciones fijan las reglas: "Usa únicamente el contexto siguiente para responder. Si la respuesta no está en el contexto, di que no lo sabes." Esta cláusula de escape es la defensa principal contra alucinaciones: sin ella, el modelo rellena huecos con inventiva. El contexto presenta los chunks recuperados, cada uno con su procedencia — título del documento y posición — separados por delimitadores claros. La pregunta cierra el prompt, después del contexto, para que quede fresca en la atención del modelo.

Incluir la procedencia por chunk habilita respuestas con citas y permite al usuario verificar. El orden importa: los modelos atienden mejor al principio y al final del prompt, así que coloca los chunks más relevantes en los extremos si son muchos.

Resiste la tentación de meter más contexto del necesario: chunks irrelevantes distraen al modelo y degradan la respuesta. Cinco chunks buenos superan a veinte mediocres — otra razón por la que la calidad de la recuperación es la mitad del sistema.
