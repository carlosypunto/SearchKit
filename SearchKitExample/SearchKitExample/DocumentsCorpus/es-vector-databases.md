---
id: es-vector-databases
title: Bases de datos vectoriales
language: es
family: data-persistence
---
Una base de datos vectorial almacena embeddings — vectores de números en coma flotante que representan el significado de textos, imágenes o audio — y responde una pregunta central: dados estos miles de vectores, ¿cuáles son los K más cercanos a este vector de consulta?

Esa búsqueda de vecinos más próximos (KNN) usa métricas de distancia: la distancia coseno mide el ángulo entre vectores (ideal para texto, donde la magnitud importa poco) y la euclidiana o L2 mide distancia geométrica. Con vectores normalizados a longitud uno, ambas ordenan igual.

A escala de millones de vectores, la búsqueda exacta se vuelve cara y entran los índices aproximados (ANN) como HNSW o IVF, que sacrifican exactitud marginal por velocidad. Pero para catálogos on-device de miles de documentos, la búsqueda exacta por fuerza bruta es perfectamente viable y elimina toda la complejidad de indexación.

En el ecosistema Apple, la extensión sqlite-vec añade tablas virtuales vectoriales a SQLite: los embeddings viven junto a tus datos relacionales, se consultan con SQL y participan en transacciones. Combinada con FTS5 para señal léxica y una fusión de rankings como RRF, tienes búsqueda híbrida completa en un solo fichero, sin servidores ni servicios externos.
