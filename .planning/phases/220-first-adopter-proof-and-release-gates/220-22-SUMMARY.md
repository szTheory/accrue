---
phase: 220-first-adopter-proof-and-release-gates
plan: 22
subsystem: testing
tags: [elixir, exunit, entitlements, offline, conformance]
requires:
  - phase: 220-21
    provides: production-derived declared transition comparisons for lifecycle, read, and offline families
provides:
  - Exact reconnect, device/key, ordering, and resume declared-transition comparisons
  - Exhaustive scalar mutation proof across all 27 deterministic actions
affects: [PROOF-01, PROOF-02, PROOF-03, PROOF-04, PROOF-05, reference-scenario-conformance]
tech-stack:
  added: []
  patterns: [bounded production-derived declared transitions, unchanged-observation leaf mutation]
key-files:
  created: []
  modified:
    - accrue/test/support/entitlements/reference_scenario_executor.ex
    - accrue/test/support/entitlements/reference_scenario_executor/reconnect_cache.ex
    - accrue/test/support/entitlements/reference_scenario_executor/device_keys.ex
    - accrue/test/support/entitlements/reference_scenario_executor/ordering.ex
    - accrue/test/support/entitlements/reference_scenario_executor/resume.ex
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
key-decisions:
  - "Expected transitions are compared only after production collectors produce bounded declared projections."
  - "Mutation diagnostics identify scenario, action order, kind, and leaf path without rendering private values."
patterns-established:
  - "Every family combines its richer semantic assertion with exact declared-transition equality."
requirements-completed: [PROOF-01, PROOF-02, PROOF-03, PROOF-04, PROOF-05]
coverage:
  - id: D1
    description: "All 27 deterministic actions reject each scalar result/durable/cache mutation against one unchanged production observation."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Reconnect/cache and device/key families compare bounded production-derived transitions without leaking proof material."
    requirement: PROOF-03
    verification:
      - kind: integration
        ref: "mix test reference_scenario_reconnect_test.exs reference_scenario_device_keys_test.exs"
        status: pass
    human_judgment: false
metrics:
  duration: 14min
  completed: 2026-08-05
status: blocked
---

# Phase 220 Plan 22: Complete Reference Transition Oracle Summary

**Every declared transition leaf now has a production-derived comparison and unchanged-observation mutation proof across the 27 deterministic actions.**

## Accomplishments

- Added exact bounded declared-transition projections for reconnect/cache, device/key, ordering, and interruption/resume families.
- Kept family-specific semantic proofs and made them pass alongside exact equality at the shared assertion boundary.
- Added a recursive action-wide scalar leaf inventory and mutation harness; failure messages contain only scenario ID, order, kind, and field path.

## Verification

- `cd accrue && mix format --check-formatted …reference_scenario_executor*.ex …reference_scenario_*_test.exs` — passed.
- `cd accrue && mix test test/accrue/entitlements/reference_scenario_reconnect_test.exs test/accrue/entitlements/reference_scenario_device_keys_test.exs test/accrue/entitlements/reference_scenario_conformance_test.exs --seed 458442 --max-failures 1` — 13 tests, 0 failures.
- `bash scripts/ci/verify_reference_scenario_contract.sh` — blocked: it recursively invokes `verify_release_contract.sh`, which invokes the reference scenario script again. The spawned recursive process group was terminated after confirming repeated self-invocation; no script was changed because it is outside this plan's owned files.

## Task Commits

1. Task 1 RED: `05d941a7` — reconnect/device leaf-mutation tests expose the missing exact matcher.
2. Task 1 GREEN: `5107d4aa` — reconnect/device production-derived exact comparisons.
3. Task 1 formatting: `c1870c5e` — formatted mutation helpers.
4. Task 2: `440c281e` — ordering/resume comparisons and all-action scalar mutation inventory.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Fixture/collector alignment] Seeded the rotated-key action's production snapshot before retaining keys.**

- **Found during:** Task 1
- **Issue:** The fixture correctly declares snapshot revision 1, while the key-retention collector initially queried a fresh revision-0 account.
- **Fix:** Seeded the declared production grant before issuance-retention collection, then queried the resulting revision.
- **Files modified:** `accrue/test/support/entitlements/reference_scenario_executor/device_keys.ex`
- **Verification:** Focused reconnect/device/conformance suite passed.
- **Committed in:** `5107d4aa`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** preserves fixture-to-production equality without allowing fixture expectations to construct observations.

## Issues Encountered

The plan-owned focused suites pass, but the required root verifier is recursively composed: `verify_reference_scenario_contract.sh` calls `verify_release_contract.sh`, which calls `verify_reference_scenario_contract.sh` with the same root. This must be fixed in the CI script composition before the coordinated command can complete.

## Known Stubs

None.

## Next Phase Readiness

Exact oracle enforcement is complete and focused evidence is green. Final release-gate certification remains blocked by the pre-existing recursive CI verifier composition.

## Self-Check: PASSED

- All eight plan-owned source and test files exist.
- Task commits `05d941a7`, `5107d4aa`, `c1870c5e`, and `440c281e` exist in git history.
