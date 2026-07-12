---
id: es-fine-tuning
title: Fine-tuning frente a RAG
language: es
family: ai-ml
---
Ante un modelo que no sabe lo que tu aplicación necesita, hay dos caminos: enseñárselo (fine-tuning) o dárselo a leer (RAG). Elegir bien ahorra meses.

El fine-tuning reentrena parcialmente un modelo con ejemplos de tu dominio. Cambia su comportamiento: estilo, formato, vocabulario especializado, obediencia a instrucciones concretas. Las técnicas eficientes como LoRA ajustan una fracción mínima de los pesos, abaratando el proceso. Su límite fundamental: el conocimiento queda congelado en el momento del entrenamiento, y actualizarlo significa reentrenar y redesplegar.

RAG mantiene el modelo intacto y le inyecta conocimiento en el prompt, recuperado de un índice en el momento de la consulta. El conocimiento se actualiza editando documentos — sin entrenar nada — y cada respuesta puede citar sus fuentes. Su límite: no cambia cómo se comporta el modelo, solo lo que sabe.

La regla práctica: conocimiento que cambia o debe ser verificable → RAG; comportamiento, tono o formato especializado → fine-tuning; dominios muy técnicos con ambas necesidades → combinar ambos, un modelo ajustado al dominio alimentado por recuperación actualizada.

Para desarrollo de apps, RAG casi siempre gana como primer paso: más barato, más rápido de iterar, y auditable — condición frecuente en entornos corporativos.
