---
id: en-dependency-injection
title: Dependency Injection Patterns
language: en
family: architecture
---
Dependency injection means objects receive their collaborators instead of constructing or locating them. The technique is trivial; the architectural consequences are not.

Explicit dependencies make code honest: an initializer listing `(repository:clock:analytics:)` documents the object's true requirements, while a singleton accessed mid-method is a hidden contract discovered only when tests mysteriously interact. Substitutability follows — production wires real implementations, tests wire deterministic fakes, previews wire sample data, all through the same seam.

Prefer initializer injection: dependencies arrive immutable and complete, and a half-configured object is unrepresentable. Property injection exists for framework-managed lifecycles. Service locators — global registries objects pull from — technically decouple but hide the dependency graph, reintroducing the original problem with extra steps.

Swift's protocol-based approach keeps it lightweight. Define the protocol where it is consumed, sized to what the consumer needs rather than everything the implementation offers. Compose at the root: the app's entry point builds the object graph, and construction knowledge lives in exactly one place. SwiftUI's environment adds hierarchical injection for cross-cutting values, and libraries like swift-dependencies offer ergonomics at scale — but manual composition covers most apps with zero magic and total clarity.

Warning sign of missing DI: `Thing.shared` sprinkled through business logic. Each one is a test you cannot easily write.
