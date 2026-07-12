---
id: es-async-await
title: Async/await en Swift
language: es
family: swift-concurrency
---
Async/await sustituye las pirámides de closures de finalización por código asíncrono que se lee como código secuencial. Una función marcada `async` puede suspenderse; cada punto de suspensión se señala con `await`, recordando al lector que ahí el hilo puede dedicarse a otra cosa mientras llega el resultado.

La suspensión no bloquea: el hilo queda libre y la continuación se reanuda más tarde, posiblemente en otro hilo del pool cooperativo. Por eso el código entre dos `await` no debe asumir afinidad de hilo, y los recursos compartidos necesitan aislamiento (actores) o sincronización.

Para llamar código async desde un contexto síncrono se crea una `Task { }`, que hereda prioridad y valores del contexto. Las funciones que además pueden fallar combinan efectos: `async throws`, y se llaman con `try await`.

El puente con APIs antiguas de callbacks se hace con `withCheckedContinuation` y su variante throwing, que convierten un manejador de finalización en un punto de suspensión. La regla de oro: reanudar la continuación exactamente una vez.

Async/await no es paralelismo por sí solo; es concurrencia estructurada legible. El paralelismo llega con `async let` y los grupos de tareas.
