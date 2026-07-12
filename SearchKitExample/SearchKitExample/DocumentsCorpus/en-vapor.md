---
id: en-vapor
title: Server-Side Swift with Vapor
language: en
family: web-backend
---
Vapor brings Swift to the server with a full web framework: routing, middleware, an ORM, authentication, websockets, and templating, all built on SwiftNIO's event-loop concurrency. Since async/await landed, route handlers read exactly like app code — async functions that take a request and return encodable content.

Routing is expressive and type-safe: path parameters decode to typed values, and request bodies arrive through `Content`, Vapor's Codable integration, so your DTOs deserialize without ceremony. Middleware wraps the request pipeline for cross-cutting concerns — CORS, error mapping, token validation.

Fluent, the ORM, defines models as classes with property wrappers and writes schema changes as migration code, portable across Postgres, MySQL, and SQLite. Its query builder covers common needs; raw SQL remains available for the rest.

The killer feature for Apple-stack teams is sharing: put DTOs and validation logic in a Swift package imported by both the iOS app and the server, and API contract drift becomes a compile error instead of a production incident.

Deploy as a Docker container behind any load balancer. Mind the operational realities: you own monitoring, scaling, and security patching — a language you love doesn't waive the responsibilities of running a service.
