---
id: en-urlsession
title: Networking with URLSession
language: en
family: web-backend
---
URLSession handles the entire HTTP lifecycle on Apple platforms — connection pooling, HTTP/2 and HTTP/3, TLS, cookies, caching, and proxies — behind a small API that fits async/await naturally: `try await session.data(for: request)` returns data and response, done.

Requests beyond a simple GET use `URLRequest`: set the method, attach headers, encode a body. On the way back, always inspect `HTTPURLResponse.statusCode`; URLSession treats any completed HTTP exchange as transport success, so a 500 with an error body arrives as "data" unless your code says otherwise. A `validate()` step that throws on non-2xx codes belongs in every networking layer.

Session configuration is where policies live: timeout intervals, `waitsForConnectivity` (wait for network rather than failing instantly), cache behavior, and multipath options. Background sessions survive app suspension for large transfers, at the price of a delegate-based flow and system-controlled scheduling.

For architecture, wrap URLSession behind a protocol with one async method. Production injects the real session; tests inject a stub returning canned data and responses — or register a custom `URLProtocol` to intercept requests system-wide. Add retry with exponential backoff for idempotent requests only, and cap concurrent requests per host out of courtesy and self-defense.
