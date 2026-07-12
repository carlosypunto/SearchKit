---
id: es-optionals
title: Optionals en Swift
language: es
family: swift-fundamentals
---
Los opcionales son la respuesta de Swift a la ausencia de valor. Un `Optional<T>` es un enum con dos casos: `some`, que envuelve un valor, y `none`, que representa la nada. Esta decisión de diseño elimina de raíz los errores de puntero nulo que plagaban Objective-C.

Para extraer el valor de un opcional tienes varias herramientas. El `if let` desenvuelve dentro de un bloque; el `guard let` desenvuelve con salida temprana y mantiene el valor disponible en el resto de la función, lo que aplana el código y evita pirámides de condicionales anidados. El operador de coalescencia `??` proporciona un valor por defecto en una sola expresión.

El encadenamiento opcional con `?.` permite navegar propiedades que pueden no existir sin explotar en tiempo de ejecución. El desempaquetado forzoso con `!` debe reservarse para invariantes que conoces con certeza absoluta, como un outlet ya cargado; usarlo por pereza es la causa más común de crashes en producción.

Una buena regla: modela con opcionales solo lo que de verdad puede faltar. Si un valor siempre existe tras la inicialización, hazlo no opcional y deja que el compilador trabaje para ti.
