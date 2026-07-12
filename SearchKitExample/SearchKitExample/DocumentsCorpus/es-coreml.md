---
id: es-coreml
title: Core ML y modelos on-device
language: es
family: ai-ml
---
Core ML es el runtime de aprendizaje automático de Apple: ejecuta modelos entrenados directamente en el dispositivo, repartiendo el trabajo entre CPU, GPU y Neural Engine sin que el desarrollador gestione nada de eso.

Un modelo Core ML es un fichero `.mlmodel` (o el paquete `.mlpackage`) que Xcode compila e integra generando una clase Swift tipada: entradas y salidas con nombres y tipos correctos, sin diccionarios de strings. La predicción es una llamada de método que acepta imágenes, arrays multidimensionales o valores escalares.

Los modelos llegan de tres vías: el catálogo de modelos convertidos de Apple, la conversión desde PyTorch con coremltools (que cuantiza, poda y ajusta el modelo al hardware), y Create ML para entrenar clasificadores sencillos desde la propia Mac con transferencia de aprendizaje.

Las ventajas del on-device son estructurales: latencia sin red, privacidad total y coste cero por inferencia. Los límites, también: memoria del dispositivo, tamaño del binario y modelos necesariamente menores que los gigantes de la nube. La cuantización a 4 u 8 bits recorta el tamaño con pérdida de precisión aceptable.

Frameworks como Vision, NaturalLanguage o Sound Analysis usan Core ML por debajo, ofreciendo tareas comunes — OCR, detección de objetos, análisis de sentimiento — sin traer modelo propio.
