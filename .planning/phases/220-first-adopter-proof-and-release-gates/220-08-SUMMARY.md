---
phase: 220-first-adopter-proof-and-release-gates
plan: 08
subsystem: entitlements-release-contract
tags: [elixir, entitlements, conformance, documentation, ci]
requires:
  - phase: 220-07
    provides: production tracer execution path
provides:
  - Canonical release-guide adoption gate
affects: [reference-scenarios, adoption-proof, release-contract]
tech-stack:
  added: []
  patterns: [closed-scenario-inputs, canonical-guide-ownership]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - scripts/ci/verify_adoption_proof_matrix.sh
decisions:
  - The adoption gate directly validates the canonical Accrue guide; no host-doc duplicate is introduced.
metrics:
  duration: 12m
  completed: 2026-08-04
status: blocked
---

# Phase 220 Plan 08: First-adopter Proof and Release Gates Summary

The adoption matrix now links to, and CI directly validates, the canonical multi-rail/offline release guide without creating a duplicate host guide. The full deterministic production-context expansion remains incomplete.

## Completed Tasks

1. Added a closed execution-input inventory for deterministic reference rows and a TDD contract ensuring runtime/advisory lanes are excluded from production authority.
2. Added a direct adoption-gate dependency on `accrue/guides/multi-rail-offline-release.md`, including its Evidence/App Review, privacy/security, and release-checklist anchors.

## Verification

- `cd accrue && mix test test/accrue/entitlements/reference_scenario_conformance_test.exs test/accrue/entitlements/reference_scenarios_test.exs test/accrue/docs/v159_release_contract_test.exs --seed 458442` — passed (16 tests).
- `cd accrue && mix accrue.entitlements.reference_scenarios --check` — passed.
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed.
- `bash scripts/ci/verify_adoption_proof_matrix.sh` — passed.
- `bash scripts/ci/verify_release_contract.sh` — passed.

## Blocker

Task 1 cannot truthfully be marked complete. The corpus has no per-case closed operation payloads for the lifecycle/offline/order/replay/race/resume rows, and the conformance suite therefore still only performs real Intake/Observation/Projector/Snapshot/PurchaseDecision/Offline assertions for the two Plan-220-07 tracer rows. Implementing the missing cases requires defining their operation inputs and expected production transitions without deriving decisions from fixture helpers.

## Deviations from Plan

None auto-fixed. Execution stopped before claiming the unimplemented production-context coverage as complete.

## Known Stubs

- `accrue/lib/accrue/entitlements/reference_scenarios.ex`: `synthetic_operation/1` enumerates bounded inputs for non-tracer rows but is not yet consumed by a real-context bounded-output comparator; this does not fulfill PROOF-02 and must be replaced by per-case execution data and tests.

## Self-Check: PASSED

- Task commits `364038e4`, `aeadfac8`, `f5b9c6c8`, and `7c901f94` exist.
- The canonical guide remains the only hand-authored release guide used by the adoption path.
