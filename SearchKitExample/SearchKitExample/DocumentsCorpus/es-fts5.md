---
id: es-fts5
title: Búsqueda de texto completo con FTS5
language: es
family: data-persistence
---
FTS5 es el módulo de búsqueda de texto completo de SQLite. Crea una tabla virtual que indexa el contenido por tokens y responde consultas léxicas en milisegundos, con ranking de relevancia BM25 incorporado.

Se usa creando la tabla con `CREATE VIRTUAL TABLE docs USING fts5(contenido)` y consultando con el operador MATCH: `SELECT * FROM docs WHERE docs MATCH 'sqlite AND rendimiento'`. La sintaxis de consulta admite frases entre comillas, prefijos con asterisco, operadores booleanos AND, OR y NOT, y NEAR para proximidad.

BM25 puntúa cada documento según la frecuencia del término, penalizando términos comunes en el corpus y normalizando por longitud del documento. En FTS5 los valores más bajos indican mayor relevancia (la función devuelve valores negativos), un detalle que sorprende la primera vez.

Los tokenizadores importan: el `unicode61` por defecto separa por caracteres no alfanuméricos y puede configurarse para eliminar diacríticos, útil en español para que "cancion" encuentre "canción". La función auxiliar `highlight()` marca coincidencias y `snippet()` extrae fragmentos con contexto.

Cuidado con la entrada del usuario: caracteres como comillas desbalanceadas rompen la sintaxis MATCH. Sanea las consultas envolviendo tokens en comillas dobles antes de pasarlas al motor.
