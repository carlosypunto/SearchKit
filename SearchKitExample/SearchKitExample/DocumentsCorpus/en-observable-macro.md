---
id: en-observable-macro
title: Observation with the @Observable Macro
language: en
family: swiftui
---
The Observation framework replaced Combine-based `ObservableObject` as SwiftUI's change-tracking engine. Annotate a class with `@Observable` and the macro rewrites its stored properties to record reads and publish writes — no `@Published`, no `objectWillChange`, no subscription management.

Precision is the headline feature. SwiftUI now records exactly which properties a view's body reads, and a write invalidates only views that read that property. A model with twenty properties shared across a screen no longer re-renders everything when one counter increments. This alone eliminates a whole genre of SwiftUI performance investigations.

Ergonomics simplify too: hold models as plain properties, or in `@State` when the view owns the model's lifetime. `@Bindable` bridges to bindings for form controls. Environment injection takes the type directly: `.environment(session)` paired with `@Environment(Session.self)`. The old `@StateObject`/`@ObservedObject` distinction — and the bugs from choosing wrongly — disappears.

Opt properties out with `@ObservationIgnored` when they are caches or internals. Observable types must be classes, since observation tracks shared mutable identity. When migrating, resist the temptation to keep both systems in one type; mixed observation is where the puzzling bugs live.
