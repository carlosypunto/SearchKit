---
id: es-swift-testing
title: El framework Swift Testing
language: es
family: testing
---
Swift Testing es el framework de pruebas moderno de Apple, sustituto de XCTest para tests unitarios. Los tests son funciones marcadas con `@Test`, las suites son structs, y la macro `#expect` sustituye a la familia entera de XCTAssert con una sola forma expresiva.

La ergonomía es el salto: `#expect(resultado == esperado)` captura la expresión completa, y al fallar muestra los valores de cada subexpresión — se acabó el "XCTAssertTrue failed" sin contexto. `#require` es la variante que aborta el test y desenvuelve opcionales: `let usuario = try #require(await repo.buscar(id))`.

Los tests parametrizados eliminan duplicación: `@Test(arguments: [...])` ejecuta la misma función con cada valor, y cada caso aparece como test independiente en el navegador. Los traits configuran comportamiento: `.disabled("razón")`, `.timeLimit`, `.tags(.regresion)` para agrupar transversalmente, y `.serialized` cuando una suite no tolera paralelismo.

Porque por defecto todo corre en paralelo y las suites son structs: cada test recibe una instancia fresca, el `init` reemplaza al `setUp`, y el estado compartido mutable se vuelve error de diseño visible. El soporte async/await es nativo — un test async se escribe como cualquier función async.

XCTest sigue siendo necesario para UI tests y performance; ambos frameworks conviven en el mismo target durante la migración.
