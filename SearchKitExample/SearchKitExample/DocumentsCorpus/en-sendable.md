---
id: en-sendable
title: Sendable Types Explained
language: en
family: swift-concurrency
---
`Sendable` marks types whose values can safely cross concurrency domains — between tasks, into actors, out of task groups. It has no method requirements; its meaning is entirely about thread safety, and the compiler checks conformance structurally.

Value types earn `Sendable` automatically when all stored properties are Sendable: a struct of strings and integers is safe because each domain gets its own copy. Classes are the hard case — a reference shared across tasks is only safe if the class is final with immutable state, or if it synchronizes internally. The escape hatch `@unchecked Sendable` shifts the proof burden from compiler to author; treat every use as a code-review flag that demands an explanation (a lock, a serial queue, atomics).

Closures cross boundaries too. `@Sendable` closures cannot capture mutable variables by reference and everything they capture must itself be Sendable — this is why `Task { }` bodies complain about mutating captured locals.

Under strict concurrency checking, non-Sendable values simply cannot leave their isolation domain. When the compiler objects, the productive responses are: make the type a struct, confine it to an actor, or redesign so the value never needs to travel. Suppressing the warning is the one wrong answer.
