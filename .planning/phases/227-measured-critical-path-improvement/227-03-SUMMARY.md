---
phase: 227-measured-critical-path-improvement
plan: "03"
subsystem: ci-evidence
tags: [github-actions, rollback, proof-vector, critical-path]
requires:
  - phase: 227-02
    provides: retained candidate exclusions and negative-control evidence
provides:
  - terminal candidate and restoration proof vectors
  - exact D-11 inverse rollback evidence
  - exhausted restoration-run budget and terminal external-proof diagnosis
affects: [PATH-02, CI workflow, live-stripe proof]
tech-stack:
  added: []
  patterns: [repository-bound-actions-evidence, staged-rollback-state]
key-files:
  created:
    - .planning/phases/227-measured-critical-path-improvement/227-03-SUMMARY.md
  modified:
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md
key-decisions:
  - "Rollback is rollback_applied_unverified: the exact inverse passed local controls, but the sole post-correction restoration run failed during application boot because the Stripe webhook signing secret was absent."
  - "Task 3 was not entered because its kept-only precondition is false."
requirements-completed: []
coverage:
  - id: D1
    description: Terminal candidate and rollback evidence is retained with immutable Actions URLs.
    verification:
      - kind: integration
        ref: node Task-2 branch-aware terminal verifier
        status: pass
    human_judgment: false
status: blocked
---

# Phase 227 Plan 03: Terminal Rollback Evidence Summary

**Exact host-prerequisite rollback is applied and locally preserved; the exhausted restoration proof remains unverified after the live suite failed at application boot.**

## Performance

- **Completed:** 2026-08-28
- **Tasks:** 2 of 3 (Task 3 correctly skipped by its precondition)
- **Files modified:** 6

## Accomplishments

- Recorded all three final candidate first-attempt proof vectors and their repository-bound classifications.
- Retained exact inverse commit `80f6019374107fa1086eafc701090234c5e1b31f` and the historical restoration evidence without rewriting it.
- Recorded the one post-correction restoration dispatch, [33188858334](https://github.com/szTheory/accrue/actions/runs/33188858334), including its successful required path, artifact inventory, and provider failure.
- Closed the restoration budget with no rerun, replacement, or next dispatch command authorized.

## Task Commits

1. **Task 1: Restore, preflight, and type the bounded dispatch contract** — `c9073592`, `d1244ee5`, `80f60193`.
2. **Task 2: Spend the final three-run budget and keep or exactly restore** — `778f0fe2`.
3. **Task 3: Seal kept requirement, threat, validation, and maintainer evidence** — not run; its explicit kept-only precondition is false.

## Decisions Made

- After correcting the impossible setup-facts requirement, two candidates are admitted; the third retains a deterministic required-lane failure, so the exact-three predicate still fails.
- The post-correction restoration run’s host/browser/finalizer path passed, but `ACCRUE-DX-WEBHOOK-SECRET-MISSING` stopped provider testing before selection and prevents `rollback_verified`.
- PATH-02 remains unmet. Do not launch an additional restoration run from this plan’s budget.

## Verification

- Passed: branch-aware terminal verifier for the complete failed restoration vector and exhausted run budget.
- Passed: live GitHub reconciliation of the corrected candidates, restoration run/jobs/artifacts/workflow revision, and removed temporary ref.
- Passed: `node --check scripts/ci/verify_ci_critical_path.mjs`.
- Passed: critical-path fixtures and restored workflow contract.
- Passed: frozen Phase 226 baseline verifier, provider fixtures, setup diagnostics, and Phase 225 preservation verifier.

## Deviations from Plan

The post-recovery contract correction and one explicitly authorized restoration dispatch extended the original terminal record. Historical NDJSON bytes remain unchanged; all correction, transport, and outcome facts are appended.

## Issues Encountered

The three Stripe key/price inputs passed preflight. The live suite then failed during application boot because the Stripe processor webhook signing secret was absent. This is a distinct external proof gap, not a candidate rerun or a reason to leave the candidate graph active.

## Next Phase Readiness

Terminally blocked at `rollback_applied_unverified`. The single restoration-run budget is exhausted, so no further dispatch is authorized by Phase 227. Phase 227 remains incomplete and Task 3 must remain skipped.

## Self-Check: PASSED

- `227-CI-CRITICAL-PATH.ndjson` and `227-CI-CRITICAL-PATH.md` exist.
- All Task 1 and Task 2 commits are present in Git history.
- No untracked planning artifact was included.
