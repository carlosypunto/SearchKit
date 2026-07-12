---
id: es-actors
title: Actores y aislamiento de estado
language: es
family: swift-concurrency
---
Un actor es un tipo de referencia que protege su estado mutable serializando el acceso: solo una tarea puede ejecutar código del actor a la vez. Donde antes ponías un lock o una cola serial de GCD, hoy declaras `actor` y el compilador garantiza que no hay data races.

Desde fuera, toda interacción con un actor es asíncrona: `await contador.incrementar()`. Ese `await` refleja que tu tarea quizá espere su turno. Dentro del actor el código es síncrono y puede tocar sus propiedades libremente. Las propiedades declaradas `nonisolated` escapan del aislamiento para valores inmutables que no necesitan protección.

Cuidado con la reentrada: cuando un método del actor hace `await` a mitad de su cuerpo, otras tareas pueden entrar y modificar el estado antes de que la primera continúe. Las invariantes deben restablecerse antes de cada punto de suspensión, no asumirse a través de él.

`@MainActor` es un actor global que representa el hilo principal; marcar una clase, método o propiedad con él garantiza ejecución en main, esencial para UI. Swift 6 con concurrencia estricta convierte las violaciones de aislamiento en errores de compilación, transformando bugs de carrera en diagnósticos.
