---
phase: 220-first-adopter-proof-and-release-gates
plan: 18
subsystem: entitlement reference scenario conformance
tags: [entitlements, ordering, idempotency, concurrency, ecto-sandbox]
requires: [220-13]
provides: [fixture-driven-ordering-proof, barrier-controlled-parallel-delivery]
affects: [reference-scenarios, entitlement-projector]
tech-stack:
  added: []
  patterns: [strict fixture schedules, production idempotency collector, SQL Sandbox start barrier]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/ordering.ex
    - accrue/test/accrue/entitlements/reference_scenario_ordering_test.exs
  modified:
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
decisions:
  - "Ordering schedules are strict data: every delivery, permutation, repeat count, and worker index is fixture-owned."
  - "Equal-order permutation runs use rolled-back isolated transactions so global provider identities stay unchanged."
  - "Parallel workers use separate unboxed SQL Sandbox connections and a ready/release barrier."
metrics:
  duration: 6 minutes
  tasks_completed: 2
  files_changed: 4
  completed_date: 2026-08-05
status: complete
---

# Phase 220 Plan 18: Fixture-Driven Ordering Delivery Summary

Closed reference-scenario ordering proof now derives permutation, repeat, and concurrent delivery inputs solely from strict fixture data and observes production idempotency, projection, and durable state.

## Tasks Completed

1. Added strict schedule fields to the reference corpus and a production-backed collector for equal-order permutations and repeat delivery.
2. Added a real SQL Sandbox start barrier for parallel delivery, exact durable-count collection, and adversarial sequential/no-effect rejection.

## Verification

- `cd accrue && mix test test/accrue/entitlements/reference_scenario_ordering_test.exs test/accrue/entitlements/projector_test.exs --seed 458442 --max-failures 1` — passed (8 tests, 0 failures).
- `git diff --check` — passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Missing critical fixture contract] Added closed ordering schedules to the strict scenario schema.
   - Found during: Task 1
   - Issue: ordering actions had no fixture-owned delivery arrays, permutations, repeat count, or worker entries, so the planned collector could only fabricate them locally.
   - Fix: extended the fixture and strict loader validation with complete deliveries and action-specific schedules.
   - Files modified: `accrue/priv/entitlements/v1.59-reference-scenarios.json`, `accrue/lib/accrue/entitlements/reference_scenarios.ex`
   - Verification: focused ordering and projector suite passed.
   - Commit: d2114973

2. [Rule 1 - Test isolation] Preserved global provider-identity and append-only audit constraints during ordering proof.
   - Found during: Tasks 1–2
   - Issue: provider identities are globally unique and audit rows cannot be deleted, which invalidated naïve isolated permutation accounts and cleanup.
   - Fix: run permutations in rolled-back transactions; capture concurrent durable facts before removing only mutable rows, leaving append-only audit evidence intact.
   - Files modified: `accrue/test/support/entitlements/reference_scenario_executor/ordering.ex`
   - Verification: focused ordering and projector suite passed.
   - Commit: 9afb5099

**Total deviations:** 2 auto-fixed (Rule 1: 1; Rule 2: 1). **Impact:** the proof is fixture-authoritative and compatible with the production database constraints.

## Key Files

- `accrue/test/support/entitlements/reference_scenario_executor/ordering.ex` — production observation/projection collector, permutation rollback isolation, and barrier-controlled concurrent workers.
- `accrue/test/accrue/entitlements/reference_scenario_ordering_test.exs` — equal-order, repeat, parallel, and substitute-adapter conformance tests.
- `accrue/lib/accrue/entitlements/reference_scenarios.ex` — strict validation and normalization of complete ordering schedules.
- `accrue/priv/entitlements/v1.59-reference-scenarios.json` — declared deliveries, permutations, repeat count, and worker indexes.

## Known Stubs

None.

## Self-Check

PASSED — all four implementation commits and all key files are present; `git diff --check` passes.
