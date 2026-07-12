---
id: en-swiftui-animations
title: Animation Principles in SwiftUI
language: en
family: swiftui
---
SwiftUI animation is state interpolation. You never command a view to move; you change state inside an animated context and the framework interpolates every affected property from old to new — position, opacity, color, path data.

There are two entry points. `withAnimation(.spring) { model.expanded.toggle() }` animates all consequences of a mutation; `.animation(.easeOut, value: progress)` attaches to a view and animates whenever the observed value changes. Springs became the default vocabulary because they compose naturally — interrupting a spring mid-flight retargets smoothly instead of jarring.

Transitions govern insertion and removal: `.transition(.move(edge: .bottom).combined(with: .opacity))` describes how a view enters and leaves. Hero effects between screens use `matchedGeometryEffect`, which tells two distinct views to share a geometry identity so SwiftUI renders the illusion of one view traveling.

For multi-step choreography, `PhaseAnimator` cycles through discrete phases and `KeyframeAnimator` interpolates independent tracks with explicit timing. Test animations with slow-motion in the simulator, and honor Reduce Motion by swapping movement for crossfades — accessibility settings are part of the animation design, not an afterthought.
