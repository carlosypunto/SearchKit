---
id: es-mvvm
title: MVVM en aplicaciones SwiftUI
language: es
family: architecture
---
MVVM separa la interfaz en tres papeles: el modelo contiene datos y reglas de negocio; la vista describe la presentación; y el view model media entre ambos, transformando el estado del dominio en algo directamente pintable y traduciendo las intenciones del usuario en operaciones del modelo.

En SwiftUI el patrón encaja con naturalidad: el view model es una clase `@Observable` con propiedades que la vista lee y métodos que la vista invoca. La vista queda tonta a propósito — sin decisiones, solo declaración — y el view model concentra la lógica presentacional: formateo, validación, estados de carga, coordinación de operaciones asíncronas.

El beneficio central es la testabilidad: el view model se prueba sin renderizar nada. Un test construye el view model con dependencias falsas, invoca `cargarPedidos()`, y afirma sobre el estado resultante — incluyendo los estados intermedios de carga y error que en la vista serían difíciles de capturar.

Los errores típicos del patrón: view models gigantes que absorben lógica de dominio (esa pertenece al modelo), exceso de ceremonias para pantallas triviales (una vista con dos textos no necesita view model), y view models que conocen tipos de UI (si importa SwiftUI, algo se filtró).

La brújula: el view model debe poder compilar y testearse en un target sin interfaz.
