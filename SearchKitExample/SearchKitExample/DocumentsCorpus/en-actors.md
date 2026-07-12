---
id: en-actors
title: Actors and Data Isolation
language: en
family: swift-concurrency
---
Actors solve the oldest problem in concurrent programming — shared mutable state — by construction. An `actor` serializes access to its stored properties: at most one task executes actor-isolated code at any moment, so data races on that state are impossible rather than merely unlikely.

Calling into an actor from outside requires `await`, because your task may need to wait its turn. Inside, code runs synchronously with full access to the actor's state. Immutable `let` properties and `nonisolated` members can be read without hopping, since they need no protection.

The subtle hazard is reentrancy. If an actor method awaits something mid-body, the actor is free to process other messages during that suspension; when your method resumes, the state may have changed. Check invariants after every await instead of carrying assumptions across suspension points.

`@MainActor` is the global actor bound to the main thread. Annotate view models and UI-facing APIs with it and the compiler — not code review — enforces main-thread access. Under Swift 6 strict concurrency, sending non-`Sendable` values across actor boundaries is a compile error, which is exactly the point: race conditions become diagnostics.
