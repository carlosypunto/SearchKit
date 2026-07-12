---
id: en-unit-testing
title: Unit Testing Principles
language: en
family: testing
---
Unit tests earn their keep by being fast, deterministic, and precise about blame. A suite that runs in seconds gets run constantly; a test that fails points at one behavior; together they make refactoring routine instead of frightening.

Structure every test as arrange-act-assert: build the system under test with known inputs, invoke one behavior, verify the outcome. Name tests as behavioral claims — `expiredTokenTriggersRefresh` reads as documentation and, in a failure list, as a diagnosis. One logical assertion per test keeps failures unambiguous.

Test through the public API. Tests that peek at private state or verify internal call sequences calcify the implementation: every refactor breaks them, and teams learn to delete or ignore them. Behavior is the contract; implementation is free to change beneath it.

Determinism requires evicting hidden dependencies. Time, network, disk, randomness, and global singletons get injected behind protocols so tests can substitute controlled doubles — a frozen clock, a canned response, a seeded generator. Difficulty testing a type is design feedback about coupling, not a testing-framework problem.

Prioritize edge cases over happy paths: empty collections, boundary values, nil, duplicates, unexpected ordering. The happy path rarely regresses; the edges are where bugs live and where tests repay their cost.
