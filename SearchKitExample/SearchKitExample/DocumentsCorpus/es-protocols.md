---
id: es-protocols
title: Protocolos y programación orientada a protocolos
language: es
family: swift-fundamentals
---
Un protocolo define un contrato: métodos y propiedades que un tipo se compromete a implementar. Swift lleva esta idea más lejos que la mayoría de lenguajes con las extensiones de protocolo, que aportan implementaciones por defecto y convierten a los protocolos en unidades de comportamiento reutilizable sin herencia.

La programación orientada a protocolos, presentada por Apple en la WWDC 2015, propone empezar el diseño por el protocolo y no por la clase base. Los structs y enums, tipos de valor sin herencia, pueden adoptar cualquier número de protocolos, componiendo capacidades como piezas de Lego: `Codable`, `Equatable`, `Hashable`, `Identifiable`.

Los tipos asociados (`associatedtype`) hacen a los protocolos genéricos, y las cláusulas `where` restringen las extensiones a casos concretos. Desde Swift 5.7, `any Protocol` declara explícitamente un tipo existencial con coste de indirección, mientras que `some Protocol` (tipos opacos) preserva el tipo concreto subyacente con rendimiento pleno; elegir entre ambos es una decisión consciente de API.

Regla práctica: usa protocolos para describir capacidades transversales y genéricos con restricciones para el rendimiento; reserva los existenciales para colecciones heterogéneas.
