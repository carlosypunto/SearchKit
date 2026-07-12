---
id: es-swiftui-animations
title: Animaciones en SwiftUI
language: es
family: swiftui
---
En SwiftUI no animas vistas: animas cambios de estado. Declaras cómo debe interpolarse la transición entre el estado anterior y el nuevo, y el framework calcula cada fotograma.

`withAnimation { }` envuelve una mutación de estado y anima todos los cambios visuales derivados. El modificador `.animation(_:value:)` es la alternativa declarativa: anima automáticamente cuando el valor observado cambia. Las curvas incluyen `.easeInOut`, `.spring` con respuesta y amortiguación configurables, y desde iOS 17 los springs son el default por su naturalidad física.

Las transiciones (`.transition`) definen cómo entra y sale una vista de la jerarquía: opacidad, movimiento, escala o combinaciones asimétricas. Requieren que el cambio esté dentro de un contexto animado. `matchedGeometryEffect` crea el efecto héroe: una vista que parece viajar entre dos posiciones de la pantalla, cuando en realidad son dos vistas coordinadas por un espacio de nombres compartido.

La API `PhaseAnimator` encadena fases discretas y `KeyframeAnimator` da control fotograma a fotograma para coreografías complejas. La regla estética: las animaciones deben explicar el cambio, no decorarlo; doscientos milisegundos de movimiento con propósito valen más que un segundo de fuegos artificiales.
