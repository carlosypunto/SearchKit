---
id: en-mocks-stubs
title: Test Doubles Taxonomy
language: en
family: testing
---
Test doubles stand in for real dependencies so tests stay fast, deterministic, and focused. The taxonomy is not pedantry — each kind answers a different question, and mixing them up produces brittle suites.

Stubs supply canned answers: a repository returning a fixed user, a clock frozen at a known instant. They control the indirect inputs of the code under test. Mocks record and verify interactions — assert that `send` was called once with this payload. Spies record without asserting, letting the test inspect afterwards. Fakes are real-but-simplified implementations: an in-memory store backing the repository protocol, behaving genuinely without infrastructure.

The craft guideline: prefer state verification over interaction verification. Asserting on observable outcomes survives refactoring; asserting on which internal collaborators were called in what order welds the test to today's implementation. Reserve mocks for side effects that are the contract — the analytics event, the email, the payment call.

Swift lacks runtime mocking magic, and that is a feature in disguise: doubles are hand-written types conforming to protocols you define at dependency seams. The discipline yields explicit contracts and simple doubles. Invest in one good fake per major dependency — a fake persistence layer pays dividends across hundreds of tests — rather than scattering ad-hoc mocks that each encode assumptions differently.
