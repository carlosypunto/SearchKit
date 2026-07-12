---
id: en-swiftui-state
title: State Management in SwiftUI
language: en
family: swiftui
---
Every SwiftUI question eventually reduces to state ownership. Views are cheap, disposable structs; state lives elsewhere and drives them. Choosing the right property wrapper is choosing who owns the data.

`@State` is for transient, view-private values — SwiftUI persists them across view rebuilds and invalidates the body on change. `@Binding` shares read-write access to someone else's state; the `$` prefix produces a binding from a state, wiring a TextField or Toggle directly to its source of truth.

The `@Observable` macro is the modern engine for shared models. Applied to a class, it instruments property access so that each view tracks exactly the properties it reads — finer-grained invalidation than the older `ObservableObject`/`@Published` pair, with less boilerplate. Pass observable models down the hierarchy directly or via `@Environment` for cross-cutting dependencies like a session or theme.

Two habits prevent most SwiftUI bugs. First, single source of truth: never copy state between views; share bindings or references. Second, keep views dumb — when a body starts making decisions, move the logic into the model where it can be unit tested without rendering anything.
