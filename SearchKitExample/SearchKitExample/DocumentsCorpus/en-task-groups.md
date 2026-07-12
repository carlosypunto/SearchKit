---
id: en-task-groups
title: Parallel Work with Task Groups
language: en
family: swift-concurrency
---
Task groups are the structured answer to dynamic fan-out: run one child task per element of a collection, in parallel, and gather results without leaking a single task. Open a scope with `withTaskGroup(of:returning:)`, add children via `group.addTask`, and consume completions by iterating the group asynchronously.

Completion order is arrival order, not submission order. Tag results with their input index when order matters. To throttle parallelism — polite behavior toward servers and memory — seed the group with a fixed window of tasks and add one more as each finishes; this sliding-window pattern caps concurrent work at any width you choose.

Error semantics reward good structure: in a throwing group, the first error that escapes cancels every remaining child. Combined with cooperative cancellation checks inside the children, an entire parallel operation can be abandoned promptly when any part fails or the user navigates away.

Every child inherits the parent's priority and task-local values, and the group cannot outlive its scope — the compiler guarantees all children complete or cancel before the function returns. Reach for `async let` when the number of concurrent operations is small and fixed; reach for groups when it is data-driven.
