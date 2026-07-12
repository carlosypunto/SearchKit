---
id: es-swiftui-navigation
title: Navegación con NavigationStack
language: es
family: swiftui
---
`NavigationStack` sustituyó a `NavigationView` con un modelo basado en datos: la pila de navegación es un array observable, y navegar es mutar ese array. Esta inversión hace la navegación programática, testeable y serializable.

El patrón central combina `navigationDestination(for:)` con `NavigationLink(value:)`. Los enlaces empujan valores tipados; el modificador declara cómo convertir cada tipo de valor en una vista de destino. Con un `NavigationPath` en el estado, puedes empujar pantallas desde código (`path.append(receta)`), volver a la raíz (`path.removeLast(path.count)`) o restaurar una sesión guardando y recargando la ruta.

Para interfaces maestro-detalle en iPad y Mac existe `NavigationSplitView`, con columnas de barra lateral, contenido y detalle que colapsan a pila en iPhone automáticamente.

Las presentaciones modales siguen otra vía: `sheet(item:)` y `fullScreenCover` se controlan con estado opcional — el sheet se muestra cuando el item no es nil y se cierra al ponerlo a nil. Un consejo estructural: centraliza las rutas en un enum (`enum Route: Hashable { case detalle(Receta), ajustes }`) y tendrás un mapa completo de la navegación de tu app en un solo tipo.
