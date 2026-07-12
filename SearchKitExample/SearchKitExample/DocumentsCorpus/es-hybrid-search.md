---
id: es-hybrid-search
title: Búsqueda híbrida y fusión RRF
language: es
family: ai-ml
---
La búsqueda semántica y la léxica fallan en sitios opuestos. Los embeddings entienden paráfrasis — "cómo cocinar pasta" encuentra "preparación de espaguetis" — pero difuminan identificadores exactos, códigos de error y nombres propios raros. BM25 clava el término exacto pero no sabe que "coche" y "automóvil" hablan de lo mismo. La búsqueda híbrida ejecuta ambas y combina resultados.

El problema de combinar es que las puntuaciones viven en escalas incompatibles: una distancia coseno entre cero y dos no se puede sumar con un BM25 negativo y sin cotas. Las fusiones por puntuación exigen calibración frágil.

Reciprocal Rank Fusion elude el problema ignorando las puntuaciones y usando solo las posiciones: cada documento recibe la suma de 1/(k + posición) en cada lista donde aparece, con k=60 como constante estándar. Aparecer en ambas listas suma doble, y las posiciones altas pesan más. Sin calibración, sin hiperparámetros sensibles, y con resultados empíricamente competitivos frente a métodos entrenados.

Un detalle de implementación importa: recupera más candidatos de los que muestras (fetchK igual a tres o cuatro veces topK en cada rama) para que la fusión tenga material con que trabajar, porque un documento en la posición quince de ambas listas puede merecer el top cinco fusionado.
