---
phase: 229-repository-truth-recovery-safety
plan: 12
subsystem: ci-observation
tags: [github-actions, deadline, subprocess, run-identity, tdd]
requires:
  - phase: 229-08
    provides: "Fixed-repository read-only CI monitor and compatibility wrapper"
provides:
  - "One monotonic absolute deadline spanning CI watch resolution, reads, polling, sleep, and return"
  - "Exact selected/viewed run ID, SHA, and requested-workflow binding before job attribution"
  - "Real-process delayed-read and run-switch regression coverage"
affects: [repository-truth, ci-monitoring, phase-229-verification]
actuals:
  tokens: 3033
  tasks: 2
  commits: 4
plan_head_before: 7fd402d7ea98b33d87a5b82f2a938225b040a523
tech-stack:
  added: []
  patterns: [monotonic-absolute-deadline, remaining-budget-propagation, selection-view-identity-binding]
key-files:
  created: []
  modified: [scripts/ci/ci_monitor.cjs]
key-decisions:
  - "Use performance.now() for one monotonic watch deadline and pass a remaining-budget function through every read boundary."
  - "Validate viewed run ID, SHA, and requested workflow before reading jobs or returning a conclusion."
patterns-established:
  - "Deadline propagation: derive every subprocess timeout and sleep duration from one positive remaining budget."
  - "Evidence attribution: bind a detail response to its selected summary row before consuming detail fields."
requirements-completed: [REPO-03]
coverage:
  - id: D1
    description: "CI watch enforces one absolute deadline across resolution, GitHub reads, polling, sleep, and success return."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "scripts/ci/ci_monitor.cjs#watch absolute deadline bounds delayed GitHub reads"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI inspection rejects selected/viewed run ID or requested-workflow changes before job attribution."
    requirement: REPO-03
    verification:
      - kind: unit
        ref: "scripts/ci/ci_monitor.cjs#inspect binds selected run identity before job summary"
        status: pass
    human_judgment: false
  - id: D3
    description: "Read-only repository binding, wrapper defaults, exact-SHA precedence, non-success exit 69, and provider-proof separation remain intact."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 12: Absolute CI Deadline and Run Identity Summary

**Read-only CI observation now applies one end-to-end monotonic timeout and rejects run-switch responses before attributing jobs or conclusions.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-13T19:10:52Z
- **Completed:** 2026-09-13T19:17:22Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Moved the watch timeout boundary ahead of SHA/branch resolution and propagated its remaining budget through list, view, poll, sleep, and final return.
- Capped each real `gh` subprocess by the lesser of its fixed read ceiling and the positive remaining watch budget, translating deadline exhaustion to exit 68 with repository/SHA attribution.
- Bound viewed responses to the selected numeric run ID, exact SHA, and requested workflow before failure details or conclusions can be consumed.
- Added deterministic real-process and in-memory regression fixtures while preserving the fixed `szTheory/accrue`, `run list|view`-only surface and `provider_proof: non_run` semantics.

## Task Commits

Each task was committed atomically with its TDD RED and GREEN stages:

1. **Task 1 RED: expose CI watch deadline overrun** - `97d821ae` (test)
2. **Task 1 GREEN: enforce an absolute CI watch deadline** - `406a7cc7` (feat)
3. **Task 2 RED: expose CI run identity switching** - `afb39a95` (test)
4. **Task 2 GREEN: bind CI view results to selection** - `4e11409b` (feat)

## Files Created/Modified

- `scripts/ci/ci_monitor.cjs` - Adds remaining-budget propagation, bounded subprocess reads and sleeps, exact run/workflow binding, and regression fixtures.

## Decisions Made

- Used `performance.now()` so clock adjustments cannot extend or prematurely shorten the absolute watch deadline.
- Kept standalone `list` and `inspect` reads on the existing 30-second ceiling; only `watch` injects the stricter shared remaining budget.
- Allowed an omitted workflow in a viewed response only when the caller supplied no workflow selector, preserving selector-free compatibility.

## TDD Gate Compliance

- **Task 1 RED:** `watch absolute deadline bounds delayed GitHub reads` failed because the pre-change monitor returned success after about 2.7 seconds; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 1 GREEN:** the same real subprocess fixture exits 68 in about 1.0 seconds, and the full Node suite passes.
- **Task 2 RED:** `inspect binds selected run identity before job summary` failed because the pre-change monitor accessed jobs from run 8 after selecting run 7; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** ID/workflow mismatches fail with attributed exit 67 before job access, while exact and selector-free positive controls pass.

## Verification

- `node --check scripts/ci/ci_monitor.cjs` — PASS
- `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh` — PASS
- `node --test scripts/ci/ci_monitor.cjs` — PASS, 4/4 tests
- Adapter-operation inspection — PASS: all production GitHub calls retain `-R szTheory/accrue`, and the argv gate permits only `gh run list` and `gh run view`.
- External recovery capsule integrity — PASS: all six SHA-256 digests remain identical to the pre-task capture.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. Nullable run fields and empty fixture arrays are intentional representations of GitHub response state, not unwired UI or placeholder behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

CR-09 and WR-02 are closed with executable process-boundary evidence. The remaining Phase 229 gap-closure plans can rely on bounded, attributable read-only CI evidence without changing the existing wrapper contract.

## Self-Check: PASSED

- Modified implementation exists at `scripts/ci/ci_monitor.cjs`.
- Task commits `97d821ae`, `406a7cc7`, `afb39a95`, and `4e11409b` exist in repository history.
- `229-12-SUMMARY.md` exists and records measured commits from plan base `7fd402d7ea98b33d87a5b82f2a938225b040a523`.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
