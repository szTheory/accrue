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
status: complete
---

# Phase 220 Plan 08: First-adopter Proof and Release Gates Summary

Closed, fixture-declared operations now drive every deterministic scenario through production entitlement contexts and bounded tuple assertions; the adoption matrix continues to validate the canonical release guide without a duplicate host guide.

## Completed Tasks

1. Replaced synthetic operation fallback with closed per-row operation payloads and complete production snapshot, purchase, offline, and audit execution coverage for deterministic rows.
2. Added microsecond expiry-before/at/after rows, regenerated public-contract/matrix artifacts, and named conformance evidence for equal-order, replay, database-parallel, and resumed durable paths.
3. Added a direct adoption-gate dependency on `accrue/guides/multi-rail-offline-release.md`, including its Evidence/App Review, privacy/security, and release-checklist anchors.

## Verification

- Full Plan 220-08 closure verification — passed (21 tests, scenario generator check, reference-contract gate, adoption-matrix gate, and release-contract gate).
- `cd accrue && mix accrue.entitlements.reference_scenarios --check` — passed.
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed.
- `bash scripts/ci/verify_adoption_proof_matrix.sh` — passed.
- `bash scripts/ci/verify_release_contract.sh` — passed.

## Deviations from Plan

### Recovery completion

- `ef84837f`: required closed fixture operations and asserted production snapshot/purchase/audit results.
- `ad668492`: added and generated expiry-adjacency scenario contract coverage.
- `e731b0ff`: named equal-order, idempotent replay, database-parallel, and resumed durable-path evidence.

## Self-Check: PASSED

- Task/recovery commits `364038e4`, `aeadfac8`, `f5b9c6c8`, `7c901f94`, `00efdd57`, `ef84837f`, `ad668492`, and `e731b0ff` exist.
- The canonical guide remains the only hand-authored release guide used by the adoption path.
