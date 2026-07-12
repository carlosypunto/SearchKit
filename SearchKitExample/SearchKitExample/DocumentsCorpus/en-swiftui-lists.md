---
id: en-swiftui-lists
title: Lists, Identity and Performance
language: en
family: swiftui
---
`List` gives you lazy rendering, cell reuse, native styling, swipe actions and edit mode with almost no code. What it demands in return is stable identity: SwiftUI tracks rows by their `Identifiable` id (or the `id:` key path), and every diffing, animation and state-preservation behavior hangs on that.

Unstable identity produces the classic bugs — rows flashing on unrelated changes, animations jumping to wrong positions, scroll position lost. Never use array indices as ids for mutable collections; give your model a real, persistent identifier.

Performance tuning is mostly about cheap bodies. A row's body runs on the main thread every time SwiftUI re-evaluates it, so hoist expensive work out: create date formatters once (they are notoriously costly), resolve strings and images in the model layer, and split complex rows into small subviews so invalidation stays narrow. The SwiftUI template in Instruments reveals which views re-render and which state change triggered them.

When `List` styling is too constraining, `LazyVStack` inside `ScrollView` offers full visual freedom while keeping lazy instantiation — though without cell recycling, memory grows with scroll distance. Prefer `List` until a design genuinely cannot be expressed with it.
