---
id: en-mvvm
title: MVVM with SwiftUI
language: en
family: architecture
---
MVVM assigns clear jobs: models own domain data and rules, views declare presentation, and view models translate between them — exposing display-ready state and accepting user intents as method calls.

SwiftUI made the pattern nearly native. An `@Observable` class serves as the view model; the view reads its properties (observation keeps them in sync) and calls its methods from buttons and task modifiers. Async operations live in the view model, which flips loading flags, catches errors into user-presentable state, and never touches a view type.

Testability is the point. A view model with injected dependencies is unit-testable without rendering: construct it with a fake repository, call `loadOrders()`, assert the state sequence — loading became true, results arrived sorted, the error path sets the right message. UI tests are slow and brittle; view model tests are milliseconds.

Failure modes to police: the massive view model hoarding business logic that belongs in the model layer; view-model-per-view dogma applied to static screens that need none; and UIKit/SwiftUI imports creeping in, which betray the boundary. Keep formatting deterministic by injecting locale and clock.

Litmus test: your view model file should compile in a target with no UI framework linked. If it cannot, the separation is fictional.
