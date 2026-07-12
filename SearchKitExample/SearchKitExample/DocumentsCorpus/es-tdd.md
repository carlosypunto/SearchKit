---
id: es-tdd
title: Desarrollo guiado por tests
language: es
family: testing
---
TDD invierte el orden habitual: primero el test que describe el comportamiento deseado, después el código que lo satisface. El ciclo es rojo-verde-refactor: escribe un test que falla, haz lo mínimo para que pase, y con la red en verde mejora el diseño sin cambiar el comportamiento.

Cada fase disciplina algo distinto. El rojo obliga a definir qué significa "funciona" antes de programar — y verifica que el test puede fallar, porque un test que nace pasando no verifica nada. El verde pide la implementación más simple, resistiendo la generalización especulativa. El refactor es donde emerge el diseño, con los tests como garantía de que nada se rompió.

El beneficio menos anunciado es el diseño: el código nacido de tests es inyectable, desacoplado y de responsabilidades pequeñas, porque lo contrario es incómodo de testear y la incomodidad aparece inmediatamente, no seis meses después.

TDD rinde máximo en lógica de dominio: reglas de negocio, parsers, cálculos, máquinas de estados. Rinde poco en capas declarativas como UI o configuración. No es dogma sino herramienta: úsalo donde el bucle de feedback te acelera.

Un efecto secundario valioso: la suite resultante documenta el comportamiento con ejemplos ejecutables, siempre sincronizados con la realidad porque de lo contrario fallan.
