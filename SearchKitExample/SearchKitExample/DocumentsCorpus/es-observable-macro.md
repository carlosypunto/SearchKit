---
id: es-observable-macro
title: El macro @Observable
language: es
family: swiftui
---
El macro `@Observable`, introducido con iOS 17, reemplaza al protocolo `ObservableObject` como mecanismo de observación en SwiftUI. Se aplica a una clase y genera en compilación el código de seguimiento de accesos: no necesitas `@Published` en cada propiedad ni suscripciones manuales.

La mejora clave es la granularidad. Con `ObservableObject`, cualquier cambio en cualquier `@Published` invalidaba todas las vistas suscritas al objeto. Con `@Observable`, SwiftUI registra qué propiedades concretas lee cada body y solo invalida las vistas afectadas por la propiedad que cambió. En modelos grandes compartidos por muchas vistas, la reducción de renders es drástica.

El uso cambia ligeramente: las vistas guardan el modelo como propiedad normal (o `@State` si son dueñas de su ciclo de vida), `@Bindable` genera bindings hacia propiedades del modelo, y `@Environment(MiModelo.self)` lo inyecta por el entorno. Ya no se usa `@StateObject` ni `@ObservedObject`.

Las propiedades que no deben observarse se marcan `@ObservationIgnored`. El macro requiere clases, no structs: la observación implica identidad y mutación compartida. Para migrar, cambia la conformancia por el macro, elimina los `@Published` y ajusta los wrappers de las vistas; el comportamiento resultante es igual o más eficiente.
