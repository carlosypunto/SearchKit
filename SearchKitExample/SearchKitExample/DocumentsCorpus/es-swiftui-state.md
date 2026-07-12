---
id: es-swiftui-state
title: Gestión de estado en SwiftUI
language: es
family: swiftui
---
SwiftUI es declarativo: la vista es una función del estado. Toda la gestión de estado gira en torno a una pregunta: ¿quién es el dueño de este dato?

`@State` declara estado local y privado de una vista: un toggle, un texto de búsqueda, una selección. SwiftUI almacena el valor fuera de la vista (que es un struct efímero) y reconstruye el body cuando cambia. `@Binding` presta acceso de lectura y escritura a un estado que pertenece a otra vista, conectando controles con su fuente de verdad mediante el prefijo `$`.

Para modelos compartidos, el macro `@Observable` de la era moderna sustituye a `ObservableObject`: marcas la clase, y las vistas que leen sus propiedades se actualizan automáticamente con seguimiento fino por propiedad, no por objeto entero. `@Environment` inyecta dependencias hacia abajo por el árbol de vistas sin pasarlas parámetro a parámetro.

La regla de oro es la fuente única de verdad: cada dato tiene un dueño, y el resto de vistas reciben referencias o bindings. Duplicar estado entre vistas es la receta de las inconsistencias. Si una vista crece en lógica, extráela a un modelo observable y deja a la vista solo la presentación.
