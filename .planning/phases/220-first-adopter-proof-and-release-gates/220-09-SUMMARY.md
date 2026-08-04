---
phase: 220-first-adopter-proof-and-release-gates
plan: 09
subsystem: entitlements-conformance
tags: [elixir, entitlements, lifecycle, offline, postgres]
requires:
  - phase: 220-08
    provides: deterministic reference-scenario corpus and release gates
provides:
  - Ordered refund and survivor lifecycle delivery evidence
  - Closed deterministic action-kind inventory
  - Whole-delivery equal-order, replay, and parallel coverage
affects: [reference-scenarios, offline-entitlements, proof-gates]
tech-stack:
  added: []
  patterns: [closed-command-inventory, action-timestamp-dispatch, insert-plus-project-delivery]
key-files:
  created: []
  modified:
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
    - accrue/test/accrue/entitlements/reference_scenarios_test.exs
decisions:
  - Fixture action kinds select production calls, while Projector and Offline remain decision authorities.
  - Lifecycle retractions are represented as distinct ordered observations with shared lineage and monotonic provider order.
metrics:
  duration: 24m
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 09: Production Scenario Action Dispatch Summary

Ordered deterministic lifecycle commands now use their declared kind and timestamp at the Observation/Projector boundary, with closed action validation and whole-delivery ordering/replay/race coverage.

## Completed Tasks

1. Added a RED tracer proving that refund cannot be represented by a generic qualified grant.
2. Added ordered grant/refund and cross-rail survivor/retraction fixture commands, then executed their declared production transitions.
3. Closed the action-kind inventory and changed equal-order, repeat, and parallel checks to perform the complete insert-plus-project delivery boundary.

## Verification

- `mix test ...reference_scenario_conformance_test.exs ...reference_scenarios_test.exs ...projector_test.exs ...offline_reconnect_test.exs ...offline_golden_vectors_test.exs ...purchase_decision_test.exs --seed 458442` — 67 tests, 0 failures.
- `cd accrue && mix accrue.entitlements.reference_scenarios --check` — passed.
- `bash scripts/ci/verify_reference_scenario_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_release_contract.sh` — passed.

## Task Commits

1. `e0089322` — RED refund-dispatch tracer.
2. `e66d4a69` — ordered refund retraction dispatch.
3. `13d1ddb7` — ordered lifecycle execution inventory.
4. `800ef3c6` — closed action inventory and complete delivery coverage.

## Deviations from Plan

None - plan executed with the existing production contexts and fixture authorities.

## Self-Check: PASSED

- All four task commits exist in git history.
- All four modified conformance files exist.
- Full specified verification passed.
