---
phase: 220-first-adopter-proof-and-release-gates
plan: 10
subsystem: entitlements-conformance
tags: [elixir, entitlements, offline, conformance, adversarial-tests]
requires:
  - phase: 220-09
    provides: closed deterministic scenario inventory
provides:
  - Mandatory command and expected-transition contracts for deterministic actions
  - Executable generic-grant and no-effect negative controls
  - Fixture-bound ordering, replay, parallel, interruption, and resume checks
affects: [reference-scenarios, offline-entitlements, release-gates]
tech-stack:
  added: []
  patterns: [closed-action-contract, production-seam-dispatch, adversarial-fallback-controls]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/test/support/entitlements/reference_scenario_executor.ex
    - accrue/test/support/entitlements/reference_scenario_executor/ordering.ex
    - accrue/test/accrue/entitlements/reference_scenarios_test.exs
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
decisions:
  - Deterministic actions must own both a typed command and an expected transition; non-deterministic evidence lanes remain command-free.
  - Generic-grant and no-effect controls execute through the shared transition assertion and must be rejected for every deterministic action.
metrics:
  duration: 9m
  completed: 2026-08-05
status: complete
---

# Phase 220 Plan 10: Action-Closed Conformance Summary

Deterministic lifecycle, offline, ordering, and resume scenarios now reject missing contracts and executable generic/no-effect substitutions through the same production-transition matcher.

## Completed Tasks

1. Closed the reconnect/replacement tracer contract and added action-contract negative controls.
2. Tagged and certified lifecycle, offline, device, and key production seam dispatch.
3. Bound ordering, replay, parallel, interruption, and resume inputs to fixture-owned commands.

## Verification

- `mix test test/accrue/entitlements/reference_scenarios_test.exs test/accrue/entitlements/reference_scenario_conformance_test.exs --only action_contract --seed 458442` — 2 tests, 0 failures.
- `mix test test/accrue/entitlements/reference_scenarios_test.exs test/accrue/entitlements/reference_scenario_conformance_test.exs test/accrue/entitlements/projector_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs test/accrue/entitlements/purchase_decision_test.exs --only special_dispatch --include test --seed 458442` — 45 tests, 0 failures.
- Full Plan 220-10 Entitlement suite — 65 tests, 0 failures.
- `mix accrue.entitlements.reference_scenarios --check` — passed.
- `bash scripts/ci/verify_reference_scenario_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_release_contract.sh` — passed; Crosswake remains `feasibility_blocked`.

## Task Commits

1. `fad9dfa1` — reject generic action substitutions.
2. `d3073ed0` — certify special action seam dispatch.
3. `518411de` — bind ordering and resume fixture commands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract bug] Require action contracts only in the deterministic lane**
- **Found during:** Task 1
- **Issue:** Tightening action validation globally incorrectly rejected runtime/advisory rows, which intentionally do not carry production commands.
- **Fix:** Made command/transition enforcement lane-aware while retaining the deterministic fail-closed requirement.
- **Files modified:** `accrue/lib/accrue/entitlements/reference_scenarios.ex`
- **Commit:** `fad9dfa1`

**Total deviations:** 1 auto-fixed. **Impact:** Preserves the evidence-lane boundary while making deterministic action contracts mandatory.

## Self-Check: PASSED

- All five modified conformance files exist.
- Task commits `fad9dfa1`, `d3073ed0`, and `518411de` exist in git history.
- Plan-wide automated verification and release gates passed.
