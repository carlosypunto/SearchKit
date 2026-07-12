---
id: en-swift-testing
title: Swift Testing in Depth
language: en
family: testing
---
Swift Testing replaces XCTest's inheritance-and-naming conventions with language-native constructs: `@Test` functions in plain structs, macro-powered assertions, and value-typed suites that make parallel execution the default rather than an aspiration.

The `#expect` macro is the visible upgrade. It accepts any boolean expression and, on failure, prints the evaluated value of every sub-expression — the debugging context XCTest made you reconstruct by hand. `#require` hard-stops the test when its condition fails and doubles as an optional unwrapper, cleaning up the guard-let-else-XCTFail dance.

Parametrized tests multiply coverage without copy-paste: pass `arguments:` collections to `@Test` and each element becomes an independently reported, independently re-runnable case. Traits attach metadata and behavior — `.disabled` with a reason, `.timeLimit`, custom `.tags` for cross-cutting groups, `.serialized` for suites that genuinely cannot parallelize.

Isolation is structural: suites are structs instantiated fresh per test, so instance state cannot leak between tests and `init`/`deinit` replace setUp/tearDown. Async tests are just async functions; confirmations handle callback-style APIs.

Adopt incrementally — Swift Testing and XCTest coexist in one target. UI automation and performance measurement still require XCTest, so migrations focus on the unit layer first.
