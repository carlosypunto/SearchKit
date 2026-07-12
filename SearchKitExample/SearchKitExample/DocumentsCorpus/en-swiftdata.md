---
id: en-swiftdata
title: SwiftData in Practice
language: en
family: data-persistence
---
SwiftData reimagines Core Data for the Swift era: models are plain classes annotated with `@Model`, the schema is inferred from source code, and queries integrate directly with SwiftUI's update cycle.

Declaring a model takes minutes — stored properties become attributes, references between models become relationships, and `@Attribute(.unique)` or `@Relationship(deleteRule: .cascade)` refine behavior. The `#Predicate` macro type-checks filter expressions at compile time against your actual model properties, catching the typos that NSPredicate strings would only reveal at runtime.

Inside SwiftUI, `.modelContainer(for:)` sets up the stack and `@Query(sort:)` fetches live results that update views automatically as data changes. Mutations go through the environment's `ModelContext`: insert, delete, and let autosave do its work. Background processing belongs in a `ModelActor`, which owns an isolated context and keeps heavy imports off the main thread.

CloudKit sync arrives nearly free — same iCloud entitlement rules as Core Data: no unique constraints, optional or defaulted properties, and inverse relationships. Adopt SwiftData for new apps with moderate schema complexity; large legacy datasets with intricate migrations may still justify Core Data's mature tooling underneath.
