---
id: es-generics
title: Genéricos en Swift
language: es
family: swift-fundamentals
---
Los genéricos permiten escribir código que funciona con cualquier tipo manteniendo la seguridad de tipos en tiempo de compilación. `Array<Element>`, `Dictionary<Key, Value>` y `Optional<Wrapped>` son genéricos que usas a diario sin pensarlo.

Una función genérica declara parámetros de tipo entre ángulos: `func swap<T>(_ a: inout T, _ b: inout T)`. Las restricciones acotan lo que el tipo debe cumplir: `<T: Comparable>` exige que exista el operador `<`. Con cláusulas `where` se expresan condiciones más finas, como que los elementos de dos secuencias coincidan.

A diferencia de los genéricos borrados de Java, Swift especializa el código genérico en compilación cuando puede, generando versiones optimizadas por tipo sin coste de ejecución. Esto hace que la abstracción sea gratuita en la mayoría de los casos.

Los tipos opacos (`some`) devuelven un genérico concreto sin nombrarlo, clave en SwiftUI donde `some View` oculta tipos compuestos imposibles de escribir a mano. Los parámetros genéricos implícitos de Swift 5.9 (`some Collection<Int>`) acercan aún más la sintaxis ligera a la potencia completa del sistema de tipos.

Empieza escribiendo el código concreto y generaliza cuando aparezca la duplicación real: la abstracción prematura es más cara que el copy-paste temporal.
