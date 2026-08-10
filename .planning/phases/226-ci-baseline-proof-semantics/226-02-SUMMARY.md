---
phase: 226-ci-baseline-proof-semantics
plan: 02
subsystem: ci-evidence
tags: [github-actions, ci, baseline, proof-semantics]
requires: [226-01]
provides: [three-run-comparable-cohort, phase-227-selection-gate]
affects: [phase-227, release-gate]
key-decisions:
  - "Use immutable branch phase-226-baseline-5da8e6b88735 for the two comparison dispatches."
  - "Treat the parked Admin UI ratchet failures as advisory evidence, never required proof."
status: complete
---

# Phase 226 Plan 02: Measured Three-Run Baseline Summary

**Three first-attempt workflow_dispatch runs now provide a SHA- and blob-bound CI baseline for Phase 227.**

## Accomplishments

- Verified the current snapshot against the Phase 225 anchor’s workflow and six lockfile blobs, then published the immutable provenance branch.
- Collected eligible runs `31322443304`, `31332551817`, and `31344524124`; all required lanes passed and each run is attempt 1.
- Recorded wall-time range 2182–2686 seconds with a 2380-second median and a mechanical measured-evidence gate for Phase 227.

## Task Commits

1. `dfde44ee` — record comparable CI dispatch cohort
2. `44f7ca9e` — publish measured three-run baseline

## Deviations from Plan

None - plan executed exactly as written. The parked Admin UI ratchet failure is retained as advisory evidence in both new run records.

## Self-Check: PASSED

- `bash scripts/ci/verify_ci_baseline_contract.sh` passed.
- Cohort count, median, and selection-gate JSON assertions passed.
