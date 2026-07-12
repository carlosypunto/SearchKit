---
id: es-tokenization
title: Tokenización de texto
language: es
family: ai-ml
---
La tokenización divide el texto en unidades procesables — tokens — y es el primer paso invisible de todo sistema de lenguaje. Qué cuenta como token depende del nivel: palabras, subpalabras o caracteres.

En Apple, `NLTokenizer` segmenta por unidades lingüísticas: palabra, frase, párrafo o documento. Maneja correctamente los casos que rompen un split ingenuo por espacios: contracciones, puntuación pegada, idiomas sin espacios como el chino, y emojis. Se usa configurando la unidad y enumerando rangos sobre el texto original, sin copiar strings.

Los modelos de lenguaje modernos usan tokenización por subpalabras (BPE, WordPiece, SentencePiece): las palabras frecuentes son un token, las raras se descomponen en fragmentos. "internacionalización" puede volverse tres o cuatro tokens. Este es el motivo de que los límites de contexto de los modelos se midan en tokens y no en palabras, y de que una palabra inventada no rompa el vocabulario.

Para sistemas de recuperación on-device, la tokenización aparece en dos sitios: el chunking (contar palabras para dimensionar ventanas) y la búsqueda léxica (el tokenizador de FTS5 decide qué coincide con qué, incluyendo si los diacríticos se ignoran). Elegir y configurar bien esos tokenizadores afecta directamente al recall de la búsqueda.
