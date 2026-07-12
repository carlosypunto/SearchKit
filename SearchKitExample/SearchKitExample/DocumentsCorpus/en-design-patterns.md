---
id: en-design-patterns
title: Design Patterns, the Swift Edition
language: en
family: architecture
---
Design patterns are named, reusable answers to recurring design forces. Half their value is the catalog; the other half is vocabulary — "wrap it in an adapter" compresses a design discussion into four words.

Swift absorbs many classics into language features. Strategy is a closure parameter. Observer ships as Observation and AsyncSequence. Iterator is Sequence conformance. Builder reaches its final form in result builders, the machinery behind SwiftUI's DSL. Recognizing these disguises prevents reimplementing ceremony the language already provides.

The patterns that still earn explicit use in app code: Repository hides persistence behind a domain-owned protocol, keeping SQLite or CloudKit swappable and tests fast. Adapter converts third-party interfaces into ones you control — indispensable at SDK boundaries, where you quarantine external types at the edge. Coordinator lifts navigation decisions out of views into a testable layer. Decorator layers behavior through composition: a caching wrapper around a network client, a retrying wrapper around that. Facade gives subsystems one honest front door.

Swift's enums enable the most protective pattern of all: state machines with associated values, where `case loading` carries no data and `case loaded([Item])` carries exactly what exists — illegal states become unrepresentable and a class of bugs becomes compile errors.

Patterns are responses to felt complexity. Applied speculatively, they are the complexity.

The Repository pattern deserves a closer look because it is the one most frequently implemented halfway. The protocol must belong to the domain layer and speak domain types — `func documents() async throws -> [Document]` — never leaking the persistence vocabulary of fetch requests, managed objects, or SQL rows. Get this boundary right and the payoffs compound: unit tests inject an in-memory fake and run in milliseconds, previews get canned data for free, and swapping Core Data for SQLite (or SQLite for a remote API) becomes an isolated change instead of a codebase-wide surgery. Get it wrong — one `NSManagedObject` escaping through the protocol — and the abstraction is decorative: every consumer silently depends on the store you meant to hide.

Dependency injection is the connective tissue between these patterns, and in Swift it can stay lightweight. Constructor injection through protocol-typed parameters covers most needs; a composition root near the app's entry point wires the object graph in one visible place. Property-wrapper containers and service locators trade that visibility for convenience and are rarely worth it in app-scale code. The rule of thumb: if you cannot tell what a type depends on by reading its initializer, the injection strategy has failed, whatever its framework pedigree.

Concurrency reshapes several classics. The actor pattern is no longer something you build from queues and locks — it is a keyword, and with it Facade often becomes "an actor owning a subsystem", serialization guarantees included. Publisher-subscriber pipelines that once required Combine or hand-rolled observers now fall out of `AsyncStream` and async sequences, with backpressure and cancellation inherited from structured concurrency rather than bolted on. Even Memento shows up naturally: value-type snapshots of an actor's state, captured and restored without defensive copying, because value semantics make the copy the default.

Anti-patterns are the catalog's shadow, and three dominate iOS codebases. The massive view controller (or its SwiftUI reincarnation, the thousand-line view with embedded business logic) is a missing-pattern symptom — usually an absent coordinator plus an absent repository. Singleton abuse turns every `shared` into invisible global state that makes tests order-dependent and previews flaky; the honest alternative is passing the dependency explicitly, however tedious that feels on day one. And protocol-for-everything ceremony — a protocol with exactly one conformance and no test double — adds indirection without options; introduce abstractions when a second implementation exists or is genuinely imminent, not as reflex.

A team's pattern maturity shows less in which patterns it uses than in how it talks about them. "This screen needs a coordinator because navigation logic is leaking into views" is an argument grounded in a felt force. "We always wrap services in protocols" is cargo cult. The catalog is a menu, not a checklist — order what the problem in front of you actually calls for.
