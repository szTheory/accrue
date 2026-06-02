---
phase: 165-e2e-automation-shift-left-ci
plan: 03
subsystem: "e2e"
tags: ["playwright", "billing", "onboarding", "serial"]
requires: ["165-01", "165-02"]
provides: ["E2E-01", "E2E-02"]
affects: ["examples/accrue_host"]
tech-stack:
  added: []
  patterns: ["serial-playwright-flow", "sandbox-fixture", "fake-processor-determinism"]
key-files:
  created:
    - examples/accrue_host/e2e/onboarding_and_billing.spec.js
  modified:
    - examples/accrue_host/playwright.config.js
decisions:
  - Consolidate onboarding and billing management coverage into one serial Playwright spec because Accrue.Processor.Fake is a singleton GenServer and shared mutable processor state made parallel flows flaky.
  - Disable full Playwright parallelism for the host suite to avoid Postgres connection exhaustion and Fake processor races during subscription mutations.
metrics:
  completed_date: "2026-06-01"
---
# Phase 165 Plan 03: Core Functional E2E Tests Summary

The core user journey E2E coverage now lives in `examples/accrue_host/e2e/onboarding_and_billing.spec.js`. The spec logs into the seeded host app, opens billing, saves tax location when required, starts a Basic subscription, changes to Pro, records metered usage through the demo action, and cancels the subscription.

## Deviations from Plan

The original plan called for separate `onboarding.spec.js` and `billing.spec.js` files. Implementation consolidated both flows into a single serial spec so checkout, plan changes, metered usage, and cancellation run deterministically against the shared Fake processor state.

`examples/accrue_host/playwright.config.js` also keeps `fullyParallel: false`; the earlier full-parallel approach exposed Postgres `FATAL 53300 (too_many_connections)` failures and Fake processor state races.

## Verification

- `cd examples/accrue_host && npm run e2e -- onboarding_and_billing.spec.js --workers=1` passed during closeout: 1 test passed in 7.2s.

## Threat Flags

- Parallel execution remains unsafe for subscription-mutating flows until the Fake processor state is isolated per test process.
- CI integration should preserve serial execution for the sensitive billing journey, even if other future specs are sharded.

## Self-Check: PASSED
