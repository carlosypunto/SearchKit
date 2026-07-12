---
id: en-tdd
title: Test-Driven Development
language: en
family: testing
---
Test-driven development is a design discipline wearing a testing costume. The loop — red, green, refactor — forces behavior to be specified before implemented, implemented before polished, and polished under a safety net.

Red: write a failing test describing the next small behavior. Watching it fail matters; a test that passes immediately is testing nothing. Green: write the least code that passes, resisting speculative abstraction — the point is a working checkpoint, not elegance. Refactor: with tests green, reshape the code freely; duplication extracted here is abstraction earned from evidence rather than guessed upfront.

The underrated payoff is architectural. Code written test-first ends up dependency-injected, loosely coupled, and single-purpose, because anything else is immediately painful to test — the pain arrives during design, when it is cheap to fix, instead of during maintenance.

Apply judgment about where TDD earns its overhead. Domain logic, parsers, pricing rules, state machines: excellent terrain, fast feedback on real complexity. Declarative UI, straight configuration, thin wrappers: poor terrain, ceremony without insight. Legacy code inverts the flow — write characterization tests capturing current behavior before changing anything.

The residual asset is executable documentation: a suite of behavioral examples that cannot drift from reality, because drift makes them fail.
