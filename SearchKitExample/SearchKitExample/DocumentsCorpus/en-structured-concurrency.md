---
id: en-structured-concurrency
title: Structured Concurrency and Task Trees
language: en
family: swift-concurrency
---
Structured concurrency imposes a discipline: child tasks live inside the scope that created them. A function that spawns concurrent work cannot return until that work completes or is cancelled. The payoff is a task tree where cancellation flows down, errors flow up, and nothing leaks.

`async let` is the lightweight tool — bind several child tasks, then await their results together; the siblings run in parallel. When the amount of work is dynamic, `withThrowingTaskGroup` shines: add tasks in a loop, iterate results as they complete, and rely on the group to await stragglers before returning. If one child throws, the group cancels the rest — fan-out with fail-fast semantics for free.

Cancellation in Swift is cooperative, never preemptive. A cancelled task keeps running until it checks: `try Task.checkCancellation()` throws immediately, `Task.isCancelled` lets you exit gracefully. Well-behaved long operations check between iterations and before expensive steps.

Unstructured tasks (`Task { }`, `Task.detached`) opt out of the tree and put lifecycle management back in your hands. They are boundary tools — a button handler, an app-launch kickoff — not something to scatter through business logic.

Task groups reward a few idioms that are not obvious from their signature. Results arrive in completion order, not submission order, so when order matters, have each child return its index alongside its value and reassemble at the end — the classic pattern is filling a pre-sized array or building a dictionary keyed by index. To bound concurrency over a large work list, seed the group with N tasks and add the next item each time one finishes; this sliding window keeps N tasks in flight without materializing thousands up front. And remember the group's scope is the synchronization point: mutating shared state from inside child closures is a data race, while collecting values through the group's async iterator is safe by construction.

Priority and inheritance follow the tree as well. A child task inherits its parent's priority, task-local values, and — for `async let` and groups — the cancellation of its ancestors. Priority escalation propagates automatically when a higher-priority task awaits a lower-priority one, which defuses most priority-inversion scenarios without manual intervention. Task-local values deserve a special mention: they travel with the task tree, not with threads, so request IDs and logging context flow through concurrent code without global dictionaries keyed by thread.

The pre-async patterns this replaces explain the design's value. Callback pyramids lost error context between hops and made partial failure nearly impossible to reason about. Dispatch groups required manual enter/leave bookkeeping that drifted out of sync during refactors. Operations promised cancellation but delivered it only when every subclass diligently checked `isCancelled`. Structured concurrency did not add capability so much as it removed failure modes: the compiler now enforces what convention used to beg for.

A practical checklist when reviewing concurrent Swift code: every `Task { }` should answer "who cancels this, and when?" — if the answer is nobody, it probably belongs to a scope as a child task instead. Every loop spawning children should state its concurrency bound. Every long-running child should show where it checks for cancellation. And `Task.detached` should carry a comment justifying why it abandons priority, task-locals, and the actor context, because ninety-nine times out of a hundred, plain `Task { }` or a child task is the right call.
