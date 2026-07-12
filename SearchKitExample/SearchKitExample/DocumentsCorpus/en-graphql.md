---
id: en-graphql
title: GraphQL for API Consumers
language: en
family: web-backend
---
GraphQL is a query language over a typed schema: instead of many fixed REST endpoints, one endpoint answers queries that specify the exact shape of data required. The response mirrors the query — nothing extra, nothing missing.

Mobile clients benefit most. A screen renders from one round trip that walks the relationship graph — user, their recent orders, each order's shipment status — where REST forces sequential requests or bespoke backend-for-frontend endpoints. On constrained networks, requesting only needed fields is a real bandwidth and latency win.

The schema is introspectable and tooling thrives on it: code generators produce Swift types for every query, so a typo in a field name fails at build time. Apollo iOS is the mature client, adding a normalized cache that recognizes the same entity across different queries and keeps screens consistent after mutations. Subscriptions deliver server-pushed updates over websockets within the same type system.

Trade-offs to respect: HTTP caching largely stops working since everything POSTs to one URL, so caching moves into the client; servers need depth limits and query cost analysis to survive hostile or accidental complexity; and naive resolvers turn flexible queries into N+1 database storms — DataLoader-style batching is essential server-side.
