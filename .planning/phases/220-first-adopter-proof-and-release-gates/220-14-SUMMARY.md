---
phase: 220
plan: 14
subsystem: entitlements-reference-scenarios
tags: [proof-02, snapshots, purchase-preflight, expiry-boundaries]
requires: [220-13]
provides: [production-read-executor, persisted-expiry-proof]
affects: [220-20, reference-scenario-conformance]
tech-stack:
  added: []
  patterns: [bounded-read-collector, repository-backed-frozen-snapshot]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/read.ex
    - accrue/test/accrue/entitlements/reference_scenario_read_test.exs
  modified:
    - accrue/test/support/entitlements/reference_scenario_executor.ex
    - accrue/lib/accrue/entitlements.ex
    - accrue/lib/accrue/entitlements/snapshot.ex
decisions:
  - Read fixtures seed only persisted authority inputs; collectors assert bounded production outputs and write deltas.
  - Snapshot's existing option-bearing public seam forwards a frozen now value to repository folding for deterministic boundary proof.
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: Web/iOS login and duplicate-purchase preflight execute through canonical production read APIs.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_read_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Persisted grants distinguish expiry immediately before, at, and after the declared microsecond boundary.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_read_test.exs
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
  files_changed: 5
  completed: 2026-08-05
status: complete
---

# Phase 220 Plan 14: Production Read Proof Summary

Production snapshot and purchase-decision reads now prove login, duplicate-preflight, and persisted expiry behavior without fixture-derived outcomes.

## Completed Tasks

1. Added the read scenario executor for web/iOS snapshots and duplicate-purchase preflight, including bounded public decision facts and zero-write collection.
2. Added repository-backed expiry-boundary execution for all three frozen microsecond rows and rejection proofs for generic, no-effect, snapshot-only, and in-memory substitutions.

## Verification

- `mix test test/accrue/entitlements/reference_scenario_read_test.exs test/accrue/entitlements/purchase_decision_test.exs test/accrue/entitlements/snapshot_test.exs --seed 458442 --max-failures 1` — 30 tests, 0 failures.
- `mix test test/accrue/entitlements/reference_scenario_conformance_test.exs test/accrue/entitlements/reference_scenario_lifecycle_test.exs --seed 458442 --max-failures 1` — 16 tests, 0 failures.

## Task Commits

1. Task 1 RED: `71be99b4` — failing read scenario coverage.
2. Task 1 GREEN: `ecc3e688` — production read scenario executor.
3. Task 2 RED: `07c9739f` — failing expiry boundary coverage.
4. Task 2 GREEN: `c307d1ec` — persisted expiry-boundary proof.

## Decisions Made

- The read collector exports only revision, plans, source rails, decision fields, durable expiry, and write counts.
- Preflight setup resolves the equivalent other-rail product from the configured catalog; it never computes the expected decision.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Forwarded the supplied snapshot clock to repository-backed grant folding.
- **Found during:** Task 2
- **Issue:** `Accrue.Entitlements.snapshot/2` accepted options but discarded `:now`, preventing frozen-clock expiry verification through the production read seam.
- **Fix:** Passed options through `Snapshot.fetch/3` and used the optional clock when folding persisted grants.
- **Files modified:** `accrue/lib/accrue/entitlements.ex`, `accrue/lib/accrue/entitlements/snapshot.ex`
- **Verification:** Focused read, snapshot, purchase-decision, conformance, and lifecycle suites pass.
- **Commit:** `c307d1ec`

## Known Stubs

None.

## Self-Check: PASSED

- Read executor and focused test suite exist.
- Task commits `71be99b4`, `ecc3e688`, `07c9739f`, and `c307d1ec` exist.
