---
id: en-swiftui-navigation
title: Data-Driven Navigation
language: en
family: swiftui
---
Modern SwiftUI navigation is state you can read and write. `NavigationStack` binds to a path — typically a `NavigationPath` or a typed array — and the current screen hierarchy is exactly the contents of that collection. Push by appending, pop by removing, deep-link by constructing the whole path at once.

Destinations are declared with `navigationDestination(for: SomeType.self)`, which maps pushed values to views. `NavigationLink(value:)` pushes a value rather than a view, keeping links lightweight and letting the stack decide lazily what to build. Because paths are `Codable` when their elements are, persisting and restoring navigation state across launches becomes an encoding exercise.

`NavigationSplitView` handles multi-column layouts: sidebar, optional content column, and detail, gracefully collapsing to a stack on compact width. It is the correct root for iPad and Mac apps rather than a hand-rolled arrangement.

Modality is separate from the stack: `.sheet(item:)` presents when an optional identifiable becomes non-nil, `.popover` and `.fullScreenCover` follow the same state-driven convention. Teams that model routes as a single hashable enum gain a compile-time inventory of every screen and a trivial deep-linking implementation.
