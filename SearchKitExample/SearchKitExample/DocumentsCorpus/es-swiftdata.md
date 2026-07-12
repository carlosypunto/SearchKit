---
id: es-swiftdata
title: Persistencia con SwiftData
language: es
family: data-persistence
---
SwiftData es el framework de persistencia declarativo de Apple, construido sobre Core Data pero diseñado para Swift moderno. Un modelo es una clase marcada con `@Model`; el macro genera el esquema desde el código, sin editor de modelos ni ficheros `.xcdatamodeld`.

Las relaciones se declaran como propiedades normales entre modelos, con `@Relationship` para configurar reglas de borrado como cascada. Los atributos aceptan restricciones vía `@Attribute`, por ejemplo `.unique`.

En SwiftUI, el contenedor se inyecta con `.modelContainer(for: Receta.self)` y las vistas consultan con `@Query`, que mantiene los resultados vivos: la lista se actualiza sola cuando insertas o borras en el contexto. Los predicados usan el macro `#Predicate`, que valida las expresiones en compilación contra las propiedades reales del modelo — se acabaron los strings de NSPredicate que fallaban en ejecución.

Las operaciones pasan por el `ModelContext`: insertar, borrar, y guardar (a menudo implícito). Para trabajo en segundo plano se usa `ModelActor`, que aísla un contexto propio en un actor.

SwiftData brilla en apps nuevas con modelos de tamaño razonable y sincronización CloudKit. Para esquemas complejos con migraciones pesadas o control fino de rendimiento, Core Data sigue ofreciendo más palancas.
