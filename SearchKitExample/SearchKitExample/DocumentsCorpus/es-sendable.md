---
id: es-sendable
title: Sendable y seguridad entre hilos
language: es
family: swift-concurrency
---
`Sendable` es el protocolo marcador que declara que un valor puede cruzar fronteras de concurrencia sin riesgo. No tiene requisitos de código: es una promesa verificada por el compilador de que compartir el valor entre tareas o actores no producirá data races.

Los tipos de valor con miembros Sendable lo son automáticamente: structs y enums de datos puros viajan gratis. Las clases solo son Sendable si son final y todo su estado es inmutable, o si gestionan su propia sincronización, en cuyo caso se marcan `@unchecked Sendable` — una afirmación tuya, no del compilador, que exige un comentario justificando el mecanismo de protección.

Las funciones también cruzan fronteras: los closures `@Sendable` no pueden capturar estado mutable por referencia, y las APIs de concurrencia (Task, TaskGroup, actores) los exigen en sus firmas.

Con el modo estricto de Swift 6, pasar un tipo no-Sendable a otro actor es error de compilación. Las estrategias de adaptación son: convertir clases de datos en structs, aislar la clase a un actor global como `@MainActor`, o encapsular el estado compartido dentro de un actor propio. `Sendable` convierte una categoría entera de bugs de producción en fricción de compilación, que es exactamente donde quieres pagarla.
