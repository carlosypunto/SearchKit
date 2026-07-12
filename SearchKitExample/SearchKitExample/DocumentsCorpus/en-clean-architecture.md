---
id: en-clean-architecture
title: Clean Architecture Boundaries
language: en
family: architecture
---
Clean architecture is one rule enforced ruthlessly: source dependencies point inward. Entities and use cases sit at the center knowing nothing about databases, networks, or screens; every framework-touching detail lives in outer rings that depend on the core, never the reverse.

The center is plain Swift. Entities model business concepts; use cases orchestrate them — `PlaceOrder` validates inventory, charges payment, schedules notification — expressed against protocols the domain itself defines. `OrderRepository` is a domain concept; whether its implementation speaks SQLite, GraphQL, or filesystem is an outer-ring detail the core never learns.

Dependency inversion makes the pointing-inward possible: outer layers implement inner protocols, and a composition root at app startup wires the graph. Enforce the boundary with targets — a domain SPM package that imports nothing framework-shaped cannot cheat, and its compile succeeds as an architectural test.

What you buy: business logic testable in milliseconds without simulators; framework migrations (UIKit to SwiftUI, REST to gRPC) contained in one ring; parallel teams working against agreed protocols. What you pay: mapping layers, DTO/domain duplication, and indirection that makes juniors ask where anything actually happens.

Scale ceremony to stakes. A utility app doesn't need four layers; a banking core shared across platforms does. The principle worth keeping at any size: business rules never import frameworks.
