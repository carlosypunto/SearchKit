---
id: es-embeddings
title: Embeddings de texto
language: es
family: ai-ml
---
Un embedding es la traducción de un texto a un vector de números reales donde la geometría codifica el significado: textos semánticamente parecidos producen vectores cercanos. Es la pieza que permite buscar "automóvil" y encontrar documentos que solo dicen "coche".

Los modelos de embeddings se entrenan para que la distancia refleje similitud semántica. Las dimensiones típicas van de 256 a 1536 componentes; más dimensiones capturan más matices a cambio de más memoria y cómputo por comparación.

En el ecosistema Apple, el framework NaturalLanguage ofrece dos niveles: `NLEmbedding` da vectores estáticos por palabra o frase, y `NLContextualEmbedding` genera vectores contextuales por token usando un modelo transformer — la palabra "banco" recibe vectores distintos en "banco de peces" y "banco de inversión". Para representar una frase completa desde vectores de tokens se aplica pooling, típicamente el promedio (mean pooling), seguido de normalización L2 para que la similitud coseno funcione correctamente.

Regla crítica de los sistemas con embeddings: indexación y consulta deben usar exactamente el mismo modelo, el mismo pooling y las mismas transformaciones. Mezclar espacios vectoriales de modelos distintos produce resultados sin sentido, y por eso los índices se versionan con un manifiesto del espacio vectorial.
