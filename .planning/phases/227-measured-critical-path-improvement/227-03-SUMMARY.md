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
  - literal external-proof recovery command
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
  - "Rollback is rollback_applied_unverified: the exact inverse passed local controls, but the sole normal-CI proof run failed live-Stripe configuration."
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

**Exact host-prerequisite rollback is applied and locally preserved; the sole normal-CI restoration proof remains externally unverified after its live-Stripe configuration failure.**

## Performance

- **Completed:** 2026-08-13
- **Tasks:** 2 of 3 (Task 3 correctly skipped by its precondition)
- **Files modified:** 2

## Accomplishments

- Recorded all three final candidate first-attempt proof vectors and their repository-bound classifications.
- Retained exact inverse commit `80f6019374107fa1086eafc701090234c5e1b31f` and its sole restoration run [31716216311](https://github.com/szTheory/accrue/actions/runs/31716216311).
- Rendered the literal `rollback_applied_unverified` state, owner, and immutable-SHA recovery command without dispatching any additional run.

## Task Commits

1. **Task 1: Restore, preflight, and type the bounded dispatch contract** — `c9073592`, `d1244ee5`, `80f60193`.
2. **Task 2: Spend the final three-run budget and keep or exactly restore** — `778f0fe2`.
3. **Task 3: Seal kept requirement, threat, validation, and maintainer evidence** — not run; its explicit kept-only precondition is false.

## Decisions Made

- The exact-three-success predicate failed: one candidate had a deterministic required-lane failure and two raw-success candidates lacked the required host setup-facts artifact.
- The restoration run’s successful host/browser/finalizer path is useful immutable rollback evidence, but its failed normal live-Stripe proof prevents `rollback_verified`.
- PATH-02 remains unmet. Do not launch an additional restoration run from this plan’s budget.

## Verification

- Passed: branch-aware Task 2 terminal verifier, which emitted the prescribed blocking human-action command.
- Passed: `node --check scripts/ci/verify_ci_critical_path.mjs`.
- Passed: critical-path fixtures and restored workflow contract.
- Passed: frozen Phase 226 baseline verifier, provider fixtures, setup diagnostics, and Phase 225 preservation verifier.

## Deviations from Plan

None - the plan’s `rollback_applied_unverified` terminal branch was followed exactly after the sole authorized restoration proof completed unsuccessfully.

## Issues Encountered

The normal restoration run failed the live-Stripe configuration preflight. This is an external proof gap, not a candidate rerun or a reason to leave the candidate graph active.

## Next Phase Readiness

Blocked at `rollback_applied_unverified`. The external owner must resolve the live-Stripe configuration issue before using the literal command in the evidence report; Phase 227 remains incomplete and Task 3 must remain skipped.

## Self-Check: PASSED

- `227-CI-CRITICAL-PATH.ndjson` and `227-CI-CRITICAL-PATH.md` exist.
- All Task 1 and Task 2 commits are present in Git history.
- No untracked planning artifact was included.
