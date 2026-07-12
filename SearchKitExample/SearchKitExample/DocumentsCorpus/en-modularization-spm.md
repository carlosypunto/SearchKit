---
id: en-modularization-spm
title: Modular Apps with SPM
language: en
family: architecture
---
Modularization draws compile-time boundaries through your codebase, and Swift Package Manager makes those boundaries cheap: local packages beside your app project, each with its own manifest, targets, tests, and resources.

The payoffs are measurable. Build times drop because unchanged modules skip recompilation — the difference between a ninety-second and nine-second iteration loop compounds hourly. Access control gains teeth: `internal` actually hides implementation across module lines, so architectural rules ("features never import each other") become compile errors rather than review comments. Tests and previews sharpen — a feature module builds without dragging the whole app, and SwiftUI previews stop timing out.

Layered decomposition works well: feature modules (Search, Profile, Checkout) atop service modules (Networking, Persistence, Analytics) atop foundation modules (DomainModels, DesignSystem, Utilities). Dependencies point strictly downward. Sibling features communicate through protocols defined in lower layers, resolved by the app's composition root — which is also where cross-feature navigation gets wired.

Known potholes: the "Common" module that accretes into coupled-to-everything sludge (prefer several purposeful foundations); resources now accessed via `Bundle.module`, which bites hard-coded `Bundle.main` assumptions; and premature fragmentation — twenty packages for a five-screen app taxes every change with manifest bookkeeping.

Extract domain and services first. Feature modules pay off when team size, not file count, demands them.
