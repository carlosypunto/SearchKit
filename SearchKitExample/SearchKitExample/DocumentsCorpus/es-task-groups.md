---
id: es-task-groups
title: Grupos de tareas y paralelismo
language: es
family: swift-concurrency
---
Cuando necesitas ejecutar un número variable de operaciones en paralelo — descargar cien imágenes, procesar todos los ficheros de una carpeta — el grupo de tareas es la herramienta estructurada. `withTaskGroup(of:)` abre un ámbito donde añades tareas hijas con `group.addTask { }` y consumes sus resultados iterando el grupo con `for await`.

Los resultados llegan en orden de finalización, no de inserción. Si necesitas preservar el orden, haz que cada tarea devuelva su índice junto al resultado y reconstruye al final. Para limitar la concurrencia — no abras quinientas conexiones a la vez — usa el patrón ventana: añade N tareas, y por cada resultado consumido añade la siguiente.

La variante `withThrowingTaskGroup` propaga errores: si una hija lanza y el error sale del cuerpo del grupo, las demás se cancelan automáticamente. Es fan-out con semántica de fallo rápido sin código extra.

El grupo no retorna hasta que todas las tareas terminan, cumpliendo el contrato de la concurrencia estructurada. Comparado con `async let`, el grupo gana cuando la cantidad de trabajo es dinámica; `async let` es más ligero para un puñado fijo de operaciones conocidas en compilación.
