---
id: en-json-swift
title: Working with JSON and Codable
language: en
family: web-backend
---
Swift's `Codable` turns JSON handling from string-wrangling into type declaration. Conform a struct to `Codable` and the compiler synthesizes both directions of serialization, including nested types, arrays, and optionals.

Real-world APIs require configuration more often than custom code. Key style mismatches dissolve under `keyDecodingStrategy = .convertFromSnakeCase`, or per-type `CodingKeys` enums when names diverge arbitrarily. Dates are the classic trap — JSON has no date type, so set `dateDecodingStrategy` to `.iso8601` or a custom formatter matching your backend, and never trust the default.

Model optionality honestly: fields the server may omit become optionals, and decoding proceeds. When decoding fails, the thrown `DecodingError` pinpoints the failing key path and expected type — log the full error, not just its description, and most mysteries evaporate.

Escape hatches exist for the awkward ten percent: hand-written `init(from:)` for polymorphic payloads discriminated by a type field, lossy array wrappers that skip corrupt elements instead of failing the whole response, and `JSONSerialization` for truly dynamic structures.

Architecturally, decode into transport DTOs that mirror the wire format, then map to domain models. The indirection costs a file; coupling your domain to a backend's naming whims costs refactors forever.
