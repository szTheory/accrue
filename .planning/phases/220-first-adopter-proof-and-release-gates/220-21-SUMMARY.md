---
phase: 220-first-adopter-proof-and-release-gates
plan: 21
subsystem: testing
tags: [elixir, exunit, ecto, entitlements, offline]
requires:
  - phase: 220-20
    provides: production-backed named reference-scenario family executors
provides:
  - Exact lifecycle, read, and offline fixture-oracle comparisons
  - Production-derived closed transition projections and leaf mutation regressions
affects: [PROOF-02, reference-scenario-conformance]
tech-stack:
  added: []
  patterns: [production-derived declared transition projections]
key-files:
  created: []
  modified:
    - accrue/test/support/entitlements/reference_scenario_executor.ex
    - accrue/test/support/entitlements/reference_scenario_executor/lifecycle.ex
    - accrue/test/support/entitlements/reference_scenario_executor/read.ex
    - accrue/test/support/entitlements/reference_scenario_executor/offline_policy.ex
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
key-decisions:
  - "Compare fixture leaves only after each family has collected an independent production projection."
  - "Retractions replace the revision-bound cache; expired snapshots and survivor transitions retain their actual collected revisions."
patterns-established:
  - "Family collectors return declared_transition alongside richer semantic evidence."
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: Exact lifecycle, read, and signed-offline expected-transition enforcement.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: mix test reference scenario lifecycle/read/offline/conformance suites
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-08-05
status: complete
---

# Phase 220 Plan 21: Exact Reference Transition Oracle Summary

**Lifecycle, read, and signed-offline fixtures now compare every closed transition leaf against independently collected production facts.**

## Accomplishments

- Added production-derived `declared_transition` maps without allowing fixture expectations into collection or execution.
- Corrected refund and survivor retraction cache expectations to `replace`, and aligned stale revision declarations with live snapshot outcomes.
- Added mutation regression coverage for all result, durable, and cache leaves across lifecycle, read, and offline families.

## Verification

- `mix test test/accrue/entitlements/reference_scenario_lifecycle_test.exs test/accrue/entitlements/reference_scenario_conformance_test.exs --seed 458442 --max-failures 1` — 10 tests, 0 failures.
- `mix test test/accrue/entitlements/reference_scenario_read_test.exs test/accrue/entitlements/reference_scenario_offline_policy_test.exs test/accrue/entitlements/reference_scenario_conformance_test.exs --seed 458442 --max-failures 1` — 16 tests, 0 failures.
- Collector modules contain no `expected_transition` access; the executor accesses it only at the assertion boundary.

## Task Commits

1. Task 1 RED: `5619a147` — lifecycle leaf mutation test proves the prior matcher gap.
2. Task 1 GREEN: `038e4918` — lifecycle comparison and cache-oracle correction.
3. Task 2: `6b2aed48` — exact read/offline comparisons and mutation coverage.
4. Production-fact correction: `712adddb` — revision declarations aligned with collected projections.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Fixture contradiction] Corrected stale per-action snapshot revisions.
   - **Found during:** Task 2
   - **Issue:** Expiry and first survivor-grant declarations did not equal their fresh production snapshots once exact matching was enabled.
   - **Fix:** Recorded revision `0` for expired snapshot reads and `1` for the first survivor grant; retained material survivor retraction at revision `2`.
   - **Verification:** Focused lifecycle/read/offline/conformance suites pass.
   - **Committed in:** `6b2aed48`, `712adddb`

## Self-Check: PASSED

- All eight plan-owned source, fixture, and test files exist.
- All task commits are present in git history.

## Next Phase Readiness

PROOF-02 has a fixture-to-production oracle for lifecycle, read, and signed-offline families. No Crosswake runtime feasibility status changed.
