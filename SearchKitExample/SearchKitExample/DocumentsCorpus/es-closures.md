---
id: es-closures
title: Closures y capturas en Swift
language: es
family: swift-fundamentals
---
Un closure es un bloque de código autocontenido que puede pasarse como valor y ejecutarse más tarde. En Swift las funciones son closures con nombre; la sintaxis `{ parámetros in cuerpo }` define closures anónimos que alimentan APIs como `map`, `filter` o los manejadores de finalización.

Lo que distingue a un closure de una simple función es la captura de contexto: el closure retiene las variables externas que usa. Esa captura es por referencia para clases, lo que abre la puerta a ciclos de retención. La lista de captura `[weak self]` rompe el ciclo declarando una referencia débil que se convierte en opcional dentro del cuerpo.

Swift ofrece azúcar sintáctico generoso: parámetros abreviados como `$0`, closures finales (trailing closures) que se escriben fuera de los paréntesis, y la inferencia de tipos que elimina anotaciones redundantes. Un `@escaping` en la firma indica que el closure sobrevivirá al retorno de la función, típico en operaciones asíncronas.

Desde Swift 5.5 muchos patrones basados en closures de finalización han migrado a async/await, pero los closures siguen siendo el mecanismo fundamental de personalización de comportamiento en las APIs de Apple, de SwiftUI a Combine.
