---
phase: 220
plan: 13
subsystem: entitlements-reference-scenarios
tags: [proof-02, lifecycle, refund, strict-contract]
requires: [220-12]
provides: [closed-reference-command-families, lifecycle-production-tracer]
affects: [220-14, 220-15, 220-16, 220-17, 220-18, 220-19, 220-20]
tech-stack:
  added: []
  patterns: [closed-data-contract, family-executor, bounded-persistence-collector]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/lifecycle.ex
    - accrue/test/accrue/entitlements/reference_scenario_lifecycle_test.exs
  modified:
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/test/support/entitlements/reference_scenario_executor.ex
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
decisions:
  - Non-offline command families cannot carry offline verification input fields.
  - Lifecycle observations collect bounded database facts after production authority executes.
metrics:
  tasks_completed: 2
  files_changed: 6
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 13: Closed Lifecycle Reference Contract Summary

The reference corpus now uses closed family command payloads for all 27 deterministic actions, with a production-backed lifecycle tracer for purchases, refunds, retractions, and survivor grants.

## Completed Tasks

1. Replaced copied executor outcomes with a named family dispatch table and a real lifecycle collector. The refund tracer writes a grant and retraction through production authority, then reads bounded observation, grant, snapshot, revision, audit, and cache facts.
2. Migrated non-offline action payloads away from universal offline fields; strict validation rejects cross-family, secret, null-required, and extra payload fields. Added real generic-grant and no-effect substitute proofs.

## Verification

- `mix test test/accrue/entitlements/reference_scenario_lifecycle_test.exs --seed 458442 --max-failures 1` — 5 tests, 0 failures.
- `mix test test/accrue/entitlements/reference_scenario_lifecycle_test.exs test/accrue/entitlements/projector_test.exs test/accrue/entitlements/apple_observation_tracer_test.exs --seed 458442 --max-failures 1` — 18 tests, 0 failures.
- `mix test test/accrue/entitlements/reference_scenario_conformance_test.exs --seed 458442 --max-failures 1` — 11 tests, 0 failures.

## Decisions Made

- Fixtures choose bounded setup references only; lifecycle state is decided by the production Observation, Apple admission, and Projector seams.
- Offline evidence stays exclusive to offline/key families, preventing lifecycle, ordering, reconnect, and expiry commands from smuggling universal verification input.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Lifecycle executor and focused tracer test exist.
- Task commits `0cb213d1`, `c60d0bf4`, `ee5c79be`, and `4d7afe20` exist.
