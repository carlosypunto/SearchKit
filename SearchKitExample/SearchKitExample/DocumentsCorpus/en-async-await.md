---
id: en-async-await
title: Async/await Fundamentals
language: en
family: swift-concurrency
---
The async/await model turns callback-based asynchronous code into straight-line prose. Declaring a function `async` means it can suspend; every `await` in the body marks a potential suspension point where the thread is released to do other work until the value arrives.

Suspension is not blocking. Swift's cooperative thread pool keeps a small number of threads busy, and awaiting code simply parks its continuation. A consequence worth internalizing: after an `await`, you may resume on a different thread, so thread-affine assumptions must be replaced by actor isolation.

Bridging worlds is routine work. `Task { }` enters async context from synchronous code, inheriting priority and task-local values. `withCheckedThrowingContinuation` wraps legacy completion-handler APIs, converting delegate callbacks or closures into awaitable calls — resume exactly once, or the checked variant will report the bug.

Error handling composes naturally: `async throws` functions are called with `try await`, and `do/catch` works unchanged. Cancellation is cooperative — long-running async functions should periodically call `Task.checkCancellation()`.

Remember that async/await gives you readable concurrency, not automatic parallelism; concurrent child work requires `async let` bindings or task groups.
