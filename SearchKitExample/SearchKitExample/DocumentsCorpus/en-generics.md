---
id: en-generics
title: Generics and Type Constraints
language: en
family: swift-fundamentals
---
Generics let you write one implementation that works across many types without sacrificing compile-time safety. The standard library is built on them: collections, optionals, and result types are all generic containers.

You introduce type parameters in angle brackets and constrain them by protocol: `func largest<T: Comparable>(in items: [T]) -> T?`. Constraints are the real power — they tell the compiler which operations are legal inside the function body, and they document requirements to callers. `where` clauses express relationships between multiple type parameters, such as two sequences sharing an element type.

Swift specializes generic code during compilation whenever possible, emitting type-specific machine code with zero abstraction cost. This differs fundamentally from type-erased generics in other languages.

Opaque return types (`some View`, `some Sequence<Int>`) flip generics around: the implementation chooses the concrete type, the caller sees only the capability. SwiftUI relies on this to hide enormous composed view types.

Practical advice: write the concrete version first, and extract a generic only when a second concrete use case appears. Constraints should be as loose as the implementation allows — require `Sequence` rather than `Array` when iteration is all you need.
