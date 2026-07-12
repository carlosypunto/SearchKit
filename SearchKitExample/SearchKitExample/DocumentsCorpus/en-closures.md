---
id: en-closures
title: Closures and Capture Semantics
language: en
family: swift-fundamentals
---
Closures are self-contained blocks of functionality that can be passed around as values. Swift's collection APIs — `map`, `filter`, `reduce`, `sorted(by:)` — all accept closures, and mastering their concise syntax (shorthand `$0` arguments, trailing closure position, implicit returns) makes functional-style code pleasant to read.

The defining feature of a closure is capture: it keeps alive any variable from the enclosing scope that it references. Captured class instances are held strongly by default, which is how retain cycles are born — a view controller owns a closure that captures `self` strongly, and neither can ever be deallocated. Capture lists like `[weak self]` or `[unowned self]` are the cure; `weak` produces an optional you must unwrap, `unowned` trades safety for convenience and crashes if the object is gone.

Mark a closure parameter `@escaping` when it outlives the function call, as completion handlers do. Non-escaping closures, the default, allow the compiler to optimize aggressively and let you use `self` without ceremony.

Even in the async/await era, closures remain the backbone of SwiftUI view builders, Combine operators, and countless callback-based APIs.
