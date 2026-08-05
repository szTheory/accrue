---
phase: 220-first-adopter-proof-and-release-gates
plan: 20
subsystem: entitlement reference-scenario conformance
tags: [elixir, swift, phoenix, conformance, release-gate]
requires:
  - phase: 220-13
    provides: closed tagged action contract
  - phase: 220-14..19
    provides: production-backed family executors
provides:
  - Exhaustive 27-row aggregate executor proof
  - Tagged Phoenix and Swift public consumers
  - Credential-free coordinated Phase 220 verifier
affects: [proof-02, release-contract, crosswake-tracer]
tech-stack:
  added: []
  patterns: [family-owned bounded observations, ordered corpus execution, fixture-root-safe verifier]
key-files:
  created: []
  modified:
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
    - accrue/test/support/entitlements/reference_scenario_executor.ex
    - examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift
    - scripts/ci/verify_reference_scenario_contract.sh
key-decisions:
  - Keep opaque chained runtime state inside the shared executor while aggregate assertions see bounded collector output only.
  - Run the full coordinated verifier only from the repository root so contract mutation fixtures remain self-contained.
metrics:
  tasks: 2
  files: 5
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 20: Final Aggregate Proof and Release Gate Summary

**All 27 deterministic scenario actions now traverse their declared production family through one aggregate proof and one credential-free release command.**

## Accomplishments

- Replaced aggregate fixture dispatch and local lifecycle/order/resume examples with ordered `ReferenceScenarioExecutor.execute_action/3` execution and family-owned assertions.
- Completed the shared dispatcher for the already-proven reconnect, resume, ordering, device, and key-retention families; chained runtime values stay executor-local.
- Kept Phoenix a host-owned convergence consumer and expanded Swift's tagged command/expected-state decoding while retaining `feasibility_blocked`.
- Extended the reference-scenario script to compose core family/aggregate tests, repair coverage, host, Swift, generator, adoption-matrix, and release-contract gates.

## Verification

- `cd accrue && mix test test/accrue/entitlements/reference_scenario_conformance_test.exs --seed 458442 --max-failures 1` — passed (3 tests, 0 failures).
- `cd examples/accrue_host && mix test test/accrue_host/reference_scenario_conformance_test.exs` — passed (2 tests, 0 failures).
- `cd examples/crosswake_tracer && swift test` — passed (28 tests).
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed without credentials.

## Task Commits

1. Task 1 — `fba6abc4` — exhaustive aggregate routing and central family dispatch.
2. Task 2 — `fd224dc4` — tagged public consumers and coordinated verifier.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking dispatch] Added central routes for previously focused-only reconnect, resume, ordering, device, and key executor families.
   - Found during: Task 1
   - Issue: the aggregate could not call `execute_action/3` for every declared action.
   - Fix: extended the test-support dispatcher and bounded family transition matcher.
   - Files modified: `accrue/test/support/entitlements/reference_scenario_executor.ex`
   - Commit: `fba6abc4`

**Total deviations:** 1 auto-fixed. **Impact:** test-support-only routing required for the aggregate contract; no runtime authority changed.

## Known Stubs

None.

## Self-Check: PASSED

- All five plan output files exist and the two task commits are present in git history.
