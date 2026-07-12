---
id: es-cosine-similarity
title: Similitud coseno y métricas de distancia
language: es
family: ai-ml
---
Comparar embeddings exige una métrica, y la similitud coseno es la reina en recuperación de texto. Mide el coseno del ángulo entre dos vectores: 1 para vectores paralelos (significado casi idéntico), 0 para ortogonales (sin relación), valores negativos para direcciones opuestas.

Se calcula como el producto punto dividido por el producto de las normas. Su virtud es ignorar la magnitud: un documento largo y uno corto sobre el mismo tema apuntan en la misma dirección aunque sus vectores tengan longitudes distintas.

La distancia euclidiana (L2) mide la distancia geométrica entre las puntas de los vectores y sí es sensible a la magnitud. La elección desaparece con un truco estándar: normalizar todos los vectores a longitud uno. Sobre vectores unitarios, la distancia coseno y la L2 producen exactamente el mismo orden de resultados, porque la L2 al cuadrado es dos menos dos veces el coseno.

Por eso los pipelines serios normalizan al embeber: primero, la métrica se vuelve indiferente; segundo, el producto punto basta para comparar, que es la operación más barata. En sqlite-vec declaras la métrica de la columna (`distance_metric=cosine`) y recuerda que devuelve distancia coseno (uno menos similitud): menor es mejor, cero es idéntico.
