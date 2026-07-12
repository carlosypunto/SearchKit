---
id: es-sqlite-basics
title: SQLite en aplicaciones iOS
language: es
family: data-persistence
---
SQLite es la base de datos embebida más desplegada del mundo y viene incluida en todos los dispositivos Apple. Es una biblioteca C que gestiona un fichero único: sin servidor, sin configuración, con transacciones ACID completas.

En iOS puedes usarla por tres vías: la API C cruda de `sqlite3`, un wrapper Swift como GRDB, o indirectamente a través de Core Data y SwiftData, que la usan como motor de almacenamiento. La API C exige disciplina: preparar statements con `sqlite3_prepare_v2`, enlazar parámetros con las funciones `bind`, iterar con `step` y finalizar siempre para no fugar memoria.

Los parámetros enlazados no son opcionales: interpolar valores en el SQL es la puerta a inyecciones y errores de escapado. El modo WAL (write-ahead logging) mejora la concurrencia permitiendo lectores simultáneos con un escritor. Las transacciones agrupan escrituras: mil inserts en una transacción son órdenes de magnitud más rápidos que mil transacciones implícitas.

SQLite soporta extensiones potentes: FTS5 para búsqueda de texto completo, JSON1 para consultar campos JSON, y R-Tree para índices espaciales. Con la extensión sqlite-vec, incluso búsqueda vectorial para aplicaciones de IA, todo dentro del mismo fichero de base de datos.
