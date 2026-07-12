---
id: es-mocks-stubs
title: Dobles de prueba - mocks, stubs y fakes
language: es
family: testing
---
Un doble de prueba sustituye a una dependencia real durante un test. El vocabulario importa porque cada tipo verifica algo distinto, y elegir mal produce tests frágiles.

El stub devuelve respuestas predefinidas: un `RepositorioStub` que siempre entrega el mismo usuario. Sirve para controlar las entradas indirectas del sistema bajo prueba. El mock registra las llamadas recibidas y permite afirmar sobre la interacción: que se llamó a `enviar` exactamente una vez con este argumento. El fake es una implementación funcional simplificada — un repositorio sobre un diccionario en memoria — que se comporta de verdad sin la infraestructura real. El spy es un stub que además toma notas.

La preferencia práctica: verifica estados, no interacciones. Afirmar sobre el resultado observable resiste refactors; afirmar sobre qué métodos internos se llamaron acopla el test a la implementación. Los mocks quedan para efectos que son el propio contrato — enviar el email es el comportamiento, no un detalle.

En Swift, sin reflexión en tiempo de ejecución, los dobles se escriben a mano detrás de protocolos: el protocolo define el contrato, producción inyecta la implementación real, el test inyecta el doble. Los fakes bien hechos se amortizan: un fake del almacén de datos sirve a cientos de tests y los mantiene rápidos y deterministas.
