---
id: es-nlp-apple
title: NaturalLanguage framework a fondo
language: es
family: ai-ml
---
El framework NaturalLanguage concentra el procesamiento de lenguaje on-device de Apple: identificación de idioma, tokenización, etiquetado gramatical, reconocimiento de entidades, análisis de sentimiento y embeddings, todo sin red.

`NLLanguageRecognizer` identifica el idioma de un texto con hipótesis ponderadas; funciona bien desde frases cortas. `NLTokenizer` segmenta en palabras, frases o párrafos con conciencia lingüística real. `NLTagger` recorre el texto asignando etiquetas: categoría gramatical, lema (forma canónica de cada palabra) o entidades nombradas como personas, lugares y organizaciones — útil para extraer términos clave o anonimizar.

En la capa semántica, `NLEmbedding` ofrece vectores estáticos de palabra y frase con vecinos más próximos incorporados, y `NLContextualEmbedding` (desde iOS 17) expone un transformer multilingüe que produce vectores contextuales por token. Sus assets se descargan bajo demanda con `requestAssets`, se consulta su dimensión, y del resultado se enumeran los vectores por token para agregarlos con pooling.

Detalles operativos que ahorran sorpresas: los modelos contextuales no funcionan en el Simulador (requieren dispositivo real o Mac), la primera petición puede disparar una descarga de assets, y conviene fijar y persistir la revisión del modelo usada porque un cambio de revisión invalida embeddings previos.
