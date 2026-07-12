---
id: es-swiftui-lists
title: Listas y rendimiento en SwiftUI
language: es
family: swiftui
---
`List` es el caballo de batalla de las interfaces iOS: filas perezosas, reciclado automático, swipe actions, reordenación y estilos de plataforma gratis. Su requisito fundamental es la identidad: cada fila necesita un identificador estable, vía `Identifiable` o el parámetro `id:`.

La identidad estable es lo que permite a SwiftUI animar inserciones y borrados correctamente y no regenerar filas que no cambiaron. Usar índices como identidad es el antipatrón clásico: al insertar un elemento, todos los índices posteriores cambian y SwiftUI redibuja media lista sin necesidad.

Para colecciones grandes, `List` ya es perezosa; `LazyVStack` dentro de `ScrollView` es la alternativa cuando necesitas control visual total a cambio de perder el reciclado de celdas. Las secciones agrupan contenido con cabeceras; `.searchable` añade búsqueda integrada con la barra del sistema.

Los problemas de rendimiento en listas casi siempre son bodies caros: formateadores creados por fila, imágenes sin cachear, cálculos en el body. Extrae las filas a vistas propias, precalcula en el modelo y deja el body como una descripción barata. Instruments con la plantilla de SwiftUI muestra exactamente qué vistas se reevalúan y por qué.
