---
id: en-protocols
title: Protocol-Oriented Programming
language: en
family: swift-fundamentals
---
Protocols declare requirements — methods, properties, associated types — that conforming types must fulfil. What sets Swift apart is protocol extensions: you can attach default implementations to a protocol, instantly giving every conforming type that behavior. This is composition without inheritance, and it works for structs and enums, not just classes.

Protocol-oriented programming inverts the classic object-oriented instinct. Instead of designing a base class hierarchy, you start with small protocols that describe capabilities (`Identifiable`, `Comparable`, `Codable`) and compose them. A type earns behavior by conforming, and generic functions constrain their parameters by capability rather than lineage.

Associated types make protocols generic. When a protocol has associated types you often reach for generics (`func feed<A: Animal>(_ animal: A)`) or opaque types (`some Animal`) rather than existentials (`any Animal`), because existentials add boxing overhead and hide type identity. Swift 5.7's improved existentials narrowed the gap, but the distinction still matters in hot paths.

A well-designed protocol is small, focused on one capability, and named for what a type can do — `Equatable`, not `BaseModelProtocol`.
