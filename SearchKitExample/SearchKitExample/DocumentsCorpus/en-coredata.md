---
id: en-coredata
title: Core Data Architecture
language: en
family: data-persistence
---
Core Data is an object-graph management framework with persistence, not a thin database wrapper. It tracks changes to managed objects, enforces relationship integrity, supports undo, and lazily materializes data through faulting — objects load their attributes on first access, keeping memory flat for large datasets.

The stack starts with `NSPersistentContainer`, which loads the model and exposes contexts. Contexts are units of work bound to queues: the `viewContext` serves the main thread and UI; background contexts handle imports and heavy writes. The iron rule of Core Data concurrency is that managed objects never cross queue boundaries — pass `NSManagedObjectID`s and re-fetch on the destination context. Most legendary Core Data crashes are violations of exactly this rule.

Fetch requests push filtering and sorting down to SQLite via predicates and sort descriptors; batch inserts and batch deletes bypass object materialization entirely for bulk operations. `NSFetchedResultsController` feeds table and collection views with fine-grained change notifications.

Migrations deserve rehearsal: lightweight migration handles added attributes and simple renames automatically, but test it against production-shaped stores before shipping. Core Data rewards understanding its rules — and punishes improvisation with crashes that only appear at scale.
