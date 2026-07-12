---
id: es-dependency-injection
title: Inyección de dependencias
language: es
family: architecture
---
La inyección de dependencias es una idea humilde con consecuencias grandes: los objetos no crean sus colaboradores, los reciben. Un view model no construye su repositorio; se lo entregan por el inicializador.

El primer beneficio es la honestidad: la firma del init declara todo lo que el objeto necesita — nada de dependencias sorpresa vía singletons escondidos en el cuerpo. El segundo es la sustituibilidad: producción inyecta el repositorio real, el test inyecta uno falso, y el mismo código sirve a ambos sin condicionales.

La inyección por inicializador es la forma preferente: dependencias inmutables, objeto completo desde su nacimiento, imposible de construir a medias. La inyección por propiedad queda para casos de ciclo de vida impuesto por frameworks. El service locator — un contenedor global al que los objetos piden lo que necesitan — invierte la ventaja: oculta las dependencias en vez de declararlas.

En Swift el patrón se apoya en protocolos: el consumidor define el contrato que necesita, la implementación real vive en otra capa, y la composición ocurre en la raíz — el punto de entrada de la app monta el grafo completo de objetos. SwiftUI aporta el Environment como mecanismo de inyección jerárquica para dependencias transversales.

Sin necesidad de frameworks: en la mayoría de las apps, la inyección manual en la raíz de composición es suficiente y gratuita de entender.
