---
id: en-error-handling
title: Error Handling Strategies
language: en
family: swift-fundamentals
---
Swift's error handling is explicit by design: functions that can fail declare `throws`, call sites mark risk with `try`, and errors propagate up until a `do/catch` block handles them. Nothing fails silently, and the compiler enforces the whole chain.

Model errors as enums conforming to `Error`, with associated values carrying diagnostic context — a status code, an underlying error, the file that failed to parse. Catch clauses pattern-match on those cases, letting callers react differently to a timeout versus an authentication failure.

Choose your `try` flavor deliberately. Plain `try` propagates; `try?` collapses failure into nil, appropriate when any failure means "use the fallback"; `try!` asserts success and should be as rare as force unwrapping. `defer` blocks run on every exit path and are the right place for closing files or releasing locks.

Typed throws, added in Swift 6, let a signature promise a specific error type: `func load() throws(LoadError) -> Data`. Use them in closed systems like parsers; keep untyped `throws` at module boundaries where new failure modes may appear. The `Result` type complements throwing functions when you need to store an outcome or send it across a callback boundary.
