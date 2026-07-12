---
id: es-error-handling
title: Manejo de errores en Swift
language: es
family: swift-fundamentals
---
Swift modela los errores como valores que se lanzan y se capturan. Cualquier tipo que conforme `Error` puede lanzarse con `throw`, y las funciones que pueden fallar se marcan con `throws` en la firma, haciendo el fallo visible en el contrato de la API.

La forma idiomática de definir errores es un enum: `enum NetworkError: Error { case timeout, badStatus(Int) }`. Los casos con valores asociados transportan contexto del fallo. En el punto de llamada, `try` marca cada expresión que puede lanzar, y el bloque `do/catch` captura por patrón, del caso más específico al más general.

Las variantes de `try` cambian la estrategia: `try?` convierte el error en un opcional nil, útil cuando el motivo del fallo no importa; `try!` promete que no habrá error y revienta si lo hay. `defer` garantiza limpieza al salir del ámbito, se lance o no.

Swift 6 introduce los errores tipados (`throws(NetworkError)`), que documentan en la firma exactamente qué error puede salir, útil en librerías donde el catálogo de fallos es cerrado. `Result<Success, Failure>` sigue siendo valioso para almacenar o pasar resultados de operaciones que pueden fallar como valores de primera clase.
