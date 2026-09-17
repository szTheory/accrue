---
phase: 227-measured-critical-path-improvement
plan: "05"
subsystem: ci-evidence
tags: [github-actions, critical-path, rollback, bounded-experiment]
dependency_graph:
  requires: [227-04]
  provides: [v2-candidate-reconciliation, exact-inverse-rollback, closed-external-authority]
  affects: [PATH-02, ci-workflow, critical-path-evidence]
tech-stack:
  added: []
  patterns: [append-only-run-ledger, repository-bound-live-reconciliation, exact-inverse-rollback]
key-files:
  created: [227-05-SUMMARY.md]
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/verify_ci_critical_path.mjs
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md
key-decisions:
  - "Both externally created v2 candidate runs are retained as deterministic required-release-lane failures; neither is an admissible timing observation."
  - "The D-11 inverse is restored, candidate authority is closed, and the optional restoration slot is closed unspent rather than used to manufacture PATH-02 evidence."
requirements-completed: []
metrics:
  duration: 4h 16m
  completed: 2026-09-11
  tasks: 3
  commits: 3
  plan_head_before: 10b969189535a03e4b0f850ee7579f1cecffc83a
status: complete
actuals:
  tokens: 8789
  tasks: 3
  commits: 3
---

# Phase 227 Plan 05: Bounded v2 rollback closure Summary

The v2 one-edge experiment is terminally closed: both real attempt-1 candidates failed required release lanes, the exact host prerequisite inverse is restored, and PATH-02 remains unmet.

## Performance

- **Duration:** 4h 16m
- **Completed:** 2026-09-11
- **Tasks:** 3/3
- **Files modified:** 4

## Accomplishments

- Preserved the exhausted v1 ledger and appended distinct v2 authority, two repository-bound candidate exclusions, and one closed rollback decision.
- Reconciled [run 34637686199](https://github.com/szTheory/accrue/actions/runs/34637686199) and [run 34638355743](https://github.com/szTheory/accrue/actions/runs/34638355743): both use SHA `1bbda64e3b2dd6e6b9b6ed1281979376903346d7`, `workflow_dispatch`, `run_live_stripe:false`, and attempt 1, but each failed all required release-gate lanes while host and Playwright completed.
- Restored the exact v2 workflow inverse and removed the remaining temporary candidate ref only after terminal evidence binding; no extra candidate, rerun, replacement, or restoration workflow was created.

## Task Commits

1. **Task 1: Trace one unspent v2 budget slot** — `f24e6013`
2. **Task 2: Stage the v2 one-edge candidate** — `1bbda64e`
3. **Task 3: Reconcile consumed slots and exactly restore** — `6b3b9b18`

## Verification

- `node scripts/ci/verify_ci_critical_path.mjs --verify-workflow ... --expected-state inverse_rollback` — passed.
- `node scripts/ci/verify_ci_critical_path.mjs --verify-evidence ... --require-final-decision` — passed.
- `node scripts/ci/verify_ci_critical_path.mjs --verify-live-actions ... --require-final-decision` — passed against both terminal GitHub runs.
- `node --check scripts/ci/verify_ci_critical_path.mjs`, `node --test scripts/ci/verify_ci_critical_path.test.mjs`, baseline/provider/Stripe fixture verifiers, and `verify_ci_setup_diagnostics.sh` — passed.

## Decisions Made

- A required release-lane failure is a stop condition: the two consumed candidates are exclusions, not a partial cohort and not grounds for a replacement.
- `rollback_applied_unverified` records the exact restored graph with an intentionally unspent restoration slot. It proves safe restoration only; it cannot satisfy PATH-02.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical verification] Hardened the v2 live verifier and terminal closure schema**
- **Found during:** Task 3
- **Issue:** The uncommitted verifier hardening did not yet bind every terminal candidate ID to a closed rollback decision or render restoration authority accurately.
- **Fix:** Preserved the existing live candidate reconciliation, added terminal-decision schema/authority checks, and rendered the exact inverse and closed authority state.
- **Files modified:** `scripts/ci/verify_ci_critical_path.mjs`
- **Commit:** `6b3b9b18`

## Issues Encountered

- The first checkpoint's rate-limit interruption obscured whether one or two candidate runs existed. Repository-bound Actions API reconciliation proved both IDs are real consumed slots; their required release-lane failures closed the experiment.

## Next Phase Readiness

PATH-02 is explicitly unmet. No v2 authority remains: candidate authority is closed after two failed attempts, restoration authority is closed unspent, and the temporary candidate refs are absent from `origin`. Any future measurement needs a separately planned and authorized event class and budget.

## Known Stubs

None.

## Self-Check: PASSED

- Required evidence ledger, rendered report, workflow, verifier, and this summary exist.
- Task commits `f24e6013`, `1bbda64e`, and `6b3b9b18` exist in Git history.
