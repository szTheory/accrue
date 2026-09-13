---
phase: 225-required-lane-signal-repair
plan: 02
subsystem: ci-testing
tags: [playwright, github-actions, ci, evidence, regression]
requires:
  - phase: 225-01
    provides: "Page 191 capacity incident diagnosis and normalized CI evidence record"
provides:
  - "Five independently reported, 30-second Page 191 viewport traversals retaining 5 × 2 × 21 coverage"
  - "Fail-closed Phase 192 generated-evidence artifact paths backed by archived outputs"
affects: [admin-hardening-guardrails, release-gate, phase192, REL-02]
tech-stack:
  added: []
  patterns:
    - "Native Playwright test generation makes each deterministic capacity partition independently reportable."
    - "CI artifact contracts pin checked-in evidence paths and reject silent missing-file uploads."
key-files:
  created: []
  modified:
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js
    - accrue_admin/mix.lock
    - .github/workflows/ci.yml
    - scripts/ci/verify_phase192_ci_contract.sh
key-decisions:
  - "Partition Page 191 by existing viewport, retaining both themes and every page flow inside each native test."
  - "Use the archived Phase 192 outputs as generated-evidence sources and fail the upload if any source is absent."
patterns-established:
  - "Capacity repairs preserve first-failure attribution by splitting coherent work into bounded native test cases rather than inflating a global timeout."
requirements-completed: [REL-02]
coverage:
  - id: D1
    description: "Page 191 retains five viewport partitions, two themes, and 21 flows with per-case failure attribution."
    requirement: REL-02
    verification:
      - kind: e2e
        ref: "cd accrue_admin && npm run e2e:phase191"
        status: pass
    human_judgment: false
  - id: D2
    description: "The required Admin CI job uploads truthful archived Phase 192 evidence and fails closed on missing sources."
    requirement: REL-02
    verification:
      - kind: other
        ref: "bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-09
status: complete
---

# Phase 225 Plan 02: Required-Lane Signal Repair Summary

**Page 191 now reports five bounded viewport traversals without losing its 210 browser checks, and Phase 192 evidence uploads point to real archived outputs that fail closed when absent.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-09T03:26:00Z
- **Completed:** 2026-08-09T03:32:03Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Replaced the 60-second, 210-cycle Page 191 test with five native viewport tests, each with a 30-second budget while retaining reset/seed boundaries, both themes, all 21 flows, and every original assertion.
- Added the 5 × 2 × 21 fixture invariant and proved the list exposes exactly five independently named viewport cases.
- Pointed `phase192-generated-evidence` at the five real archived Phase 192 outputs and changed its missing-file policy from silent ignore to `error`.
- Updated the static CI contract to require archived evidence paths, fail-closed upload behavior, and absence of the obsolete unarchived prefix.

## Task Commits

1. **Task 1: Partition the Page 191 Cartesian traversal into per-viewport native tests** — `06414655` (test, RED), `700474d9` (fix, GREEN)
2. **Task 2: Point Phase 192 generated evidence at real archived outputs and lock the contract** — `9570d475` (test, RED), `3cd28c37` (fix, GREEN)

## Files Created/Modified

- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` — adds the coverage invariant and five bounded native viewport cases.
- `accrue_admin/mix.lock` — locks the already-declared `jose` test-server dependency.
- `.github/workflows/ci.yml` — uploads the real archived Phase 192 evidence with `if-no-files-found: error`.
- `scripts/ci/verify_phase192_ci_contract.sh` — asserts real artifact paths, fail-closed behavior, and obsolete-path rejection.

## Decisions Made

- Per-viewport native tests are the reporting and timeout boundary; no retries, sleeps, global timeout inflation, worker change, or coverage reduction was introduced.
- Historical Phase 192 artifacts remain archival evidence only; the repair does not claim that they are fresh Phase 225 proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Lock the declared Admin test-server dependency**

- **Found during:** Task 1 verification
- **Issue:** `accrue_admin/mix.exs` already declares `jose`, but its lock entry was absent, preventing the local Playwright web server from starting in a clean checkout.
- **Fix:** Ran `mix deps.get` against the declared dependency and committed the resulting single lockfile entry; no dependency declaration or version selection changed.
- **Files modified:** `accrue_admin/mix.lock`
- **Verification:** `cd accrue_admin && npm run e2e:phase191` passed after the lock correction.
- **Committed in:** `ff5b32ee`

**Total deviations:** 1 auto-fixed (Rule 3)

**Impact on plan:** Necessary to make the prescribed browser verification runnable; no runtime or CI topology change.

## Issues Encountered

- The initial RED browser invocation could not start because the declared `jose` dependency was missing from `accrue_admin/mix.lock`; the narrow lockfile correction resolved it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 225-03 can use the bounded Page 191 cases and truthful artifact contract as required-lane proof surfaces.
- Fresh GitHub Actions evidence remains the release-level confirmation and is not claimed by this local plan execution.

## Self-Check: PASSED

- Confirmed all four modified task artifacts exist and all five task commits are present in git history.
- Re-ran the Page 191 Playwright list and `npm run e2e:phase191`; the full suite passed with 22 tests using one worker.
- Re-ran `bash scripts/ci/verify_phase192_ci_contract.sh` and `bash scripts/ci/verify_phase192_guardrail_contract.sh`; both passed.
