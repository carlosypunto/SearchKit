---
id: es-unit-testing
title: Tests unitarios efectivos
language: es
family: testing
---
Un test unitario verifica una pieza de lógica en aislamiento, en milisegundos y de forma determinista. Un buen conjunto de tests unitarios es una red de seguridad que convierte el refactor de arriesgado en rutinario: cambias con confianza porque los tests gritan si rompes algo.

La anatomía es siempre la misma: preparar (construir el objeto bajo prueba y sus datos), actuar (ejecutar el comportamiento) y afirmar (comprobar el resultado). Un test, un comportamiento: cuando un test falla, su nombre debería bastar para saber qué se rompió — `alCancelarPedidoSeLiberaElStock` cuenta una historia; `test1` no.

Testea el contrato público, no los detalles internos: los tests acoplados a la implementación se rompen con cada refactor y acaban ignorados. Los casos límite valen más que el camino feliz: colecciones vacías, valores nulos, fronteras numéricas, entradas duplicadas.

El aislamiento exige diseño: las dependencias — reloj, red, base de datos, aleatoriedad — se inyectan detrás de protocolos, y el test las sustituye por dobles deterministas. Si un objeto es difícil de testear, el test te está dando feedback de diseño: demasiadas dependencias, demasiadas responsabilidades.

La cobertura es un indicador, no un objetivo: cien por cien de líneas ejecutadas con aserciones triviales protege menos que sesenta por ciento bien afirmado.
