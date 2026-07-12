---
id: en-http-rest
title: REST API Design
language: en
family: web-backend
---
A REST API models your domain as resources addressed by URLs and manipulated through HTTP's uniform verbs. The discipline pays off in predictability: any developer can guess that `GET /orders/42` fetches an order and `DELETE` removes it.

Verb semantics carry real contracts. GET must be safe (no side effects) so caches and prefetchers can act freely. PUT and DELETE are idempotent — replaying them yields the same state — which tells clients they can retry after a network timeout without fear of duplicates. POST promises neither, which is why payment APIs add idempotency keys.

Status codes are the response's headline: 2xx success (201 for creation, 204 for no body), 4xx client errors (400 malformed, 401 unauthenticated, 403 forbidden, 404 missing, 422 semantically invalid), 5xx server faults. Error bodies should be structured and consistent — a machine-readable code plus a human message — so clients branch on data rather than parsing prose.

URL design favors plural nouns, shallow nesting, and query parameters for filtering, sorting, and pagination (cursor-based pagination scales; offset-based breaks under concurrent writes). Version from day one, because shipped mobile clients pin your past decisions in place for years.
