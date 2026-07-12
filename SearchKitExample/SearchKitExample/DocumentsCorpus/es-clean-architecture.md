---
id: es-clean-architecture
title: Arquitectura limpia en móvil
language: es
family: architecture
---
La arquitectura limpia organiza el código en capas concéntricas con una regla única e innegociable: las dependencias apuntan hacia dentro. El dominio — entidades y casos de uso — no conoce a nadie; las capas exteriores — persistencia, red, interfaz — dependen del centro y nunca al revés.

El dominio contiene las reglas de negocio en tipos puros de Swift, sin imports de frameworks. Los casos de uso orquestan operaciones: `RealizarPedido` valida, cobra y notifica, hablando con el exterior solo a través de protocolos que el propio dominio define. Que el repositorio real use SQLite, una API o un fichero es un detalle de la capa de datos, invisible desde dentro.

La inversión de dependencias es el mecanismo que lo hace posible: el dominio declara `protocol RepositorioPedidos`, la capa de datos lo implementa, y la raíz de composición conecta ambos. El dominio compila solo — literalmente puede ser un paquete SPM sin dependencias.

El beneficio es longevidad: los frameworks cambian (UIKit ayer, SwiftUI hoy), las reglas de negocio permanecen. El coste es ceremonia: DTOs, mappers y protocolos que en una app pequeña pesan más de lo que protegen.

El criterio adulto es proporcionalidad: apps pequeñas con MVVM y buen gusto; la separación estricta de capas cuando el dominio es complejo de verdad o compartido entre plataformas.
