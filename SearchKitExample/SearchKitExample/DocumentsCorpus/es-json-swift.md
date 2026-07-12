---
id: es-json-swift
title: JSON y Codable en Swift
language: es
family: web-backend
---
`Codable` es el mecanismo declarativo de Swift para serializar tipos: conforma tus structs y el compilador sintetiza la codificación y decodificación completas. Para el JSON típico de una API, no escribes ni una línea de parsing manual.

Cuando los nombres difieren — snake_case del backend contra camelCase de Swift — hay dos herramientas: la estrategia global `keyDecodingStrategy = .convertFromSnakeCase` del decoder, o un enum `CodingKeys` por tipo para mapeos arbitrarios. Las fechas merecen atención: configura `dateDecodingStrategy` con `.iso8601` o un formateador propio, porque el default (segundos desde referencia) casi nunca coincide con lo que envía un servidor.

Los campos que pueden faltar se modelan como opcionales y la decodificación continúa; un campo requerido ausente lanza un `DecodingError` detallado con la ruta exacta del fallo — imprímelo entero al depurar, contiene la clave y el contexto.

Para JSON complejos, implementa `init(from:)` a mano: contenedores anidados, valores polimórficos discriminados por un campo `type`, o tolerancia a elementos corruptos en arrays decodificando con un wrapper que absorbe errores. La regla arquitectónica: decodifica a DTOs que reflejen el JSON tal cual, y mapea después a tus modelos de dominio; acoplar el dominio al formato del backend sale caro cuando la API cambia.
