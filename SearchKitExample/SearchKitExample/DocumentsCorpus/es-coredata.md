---
id: es-coredata
title: Core Data para proyectos existentes
language: es
family: data-persistence
---
Core Data es el framework de grafos de objetos y persistencia veterano de Apple. No es una base de datos: es una capa que gestiona ciclos de vida de objetos, relaciones, validación, deshacer y migraciones, usando normalmente SQLite como almacenamiento.

Sus piezas: el modelo (`.xcdatamodeld`) define entidades y relaciones; `NSPersistentContainer` monta la pila; `NSManagedObjectContext` es el espacio de trabajo donde creas, modificas y borras objetos; y `NSFetchRequest` con `NSPredicate` recupera datos con filtrado y ordenación empujados a SQL.

La concurrencia es la fuente clásica de errores: cada contexto pertenece a una cola, y sus objetos no deben cruzar hilos. El contexto principal (`viewContext`) sirve a la UI; los contextos de fondo (`newBackgroundContext` o `performBackgroundTask`) hacen importaciones pesadas, y los cambios se fusionan con `automaticallyMergesChangesFromParent`.

Para listas eficientes, `NSFetchedResultsController` entrega cambios incrementales por secciones. Las migraciones ligeras cubren renombrados y campos nuevos casi gratis; las pesadas requieren mapping models y ensayo con datos reales.

Aunque SwiftData es el futuro declarado, Core Data sigue siendo la elección sensata para bases de código existentes, esquemas grandes y necesidades finas de rendimiento.
