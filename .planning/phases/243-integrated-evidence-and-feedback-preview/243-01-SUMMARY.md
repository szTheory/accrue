---
phase: 243-integrated-evidence-and-feedback-preview
plan: 01
subsystem: testing
tags: [playwright, visual-regression, linux, baselines]
requires: []
provides:
  - Twelve-member selected baseline contract and per-file negative controls
  - Invoice list-to-detail action-review composition in the incumbent visual owner
affects: [EVR-03, 243-02]
actuals:
  tokens: 4322
  tasks: 1
  commits: 1
  commits: 1
plan_head_before: 3ee995a6fe43789a02e51cef03014b1600508090
plan_head_after: dd11264dfda532c8a5f8c4038c06c2c6c5a4b2bf
tech-stack:
  added: []
  patterns: [timestamp-only masking with rendered-target assertions]
key-files:
  created:
    - .planning/phases/243-integrated-evidence-and-feedback-preview/tdd/243-01-01-red.json
  modified:
    - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
    - accrue_admin/e2e/visual-baseline-set.cjs
    - accrue_admin/test/js/visual_baseline_set_test.mjs
key-decisions:
  - "Selected the seeded invoice list and open action-review composition in light and dark themes."
  - "Stopped before minting because the committed source branch has no GitHub ref; publishing its 534-commit divergence would include unrelated history."
requirements-completed: []
coverage:
  - id: D1
    description: Twelve expected Linux baseline names, invoice list/detail review path, and per-file guard controls.
    requirement: EVR-03
    verification:
      - kind: unit
        ref: "cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs"
        status: pass
      - kind: other
        ref: "cd accrue_admin && node --check e2e/admin-visual-regression-phase211.spec.js; npx playwright test --project=visual-desktop --list"
        status: pass
      - kind: integration
        ref: "Ubuntu mint and normal comparison: blocked; gh workflow run returned HTTP 422, no ref found"
        status: unknown
    human_judgment: true
    rationale: The changed browser assertions and screenshot pixels have not executed on Ubuntu; the four required invoice baselines and normal comparison result remain unavailable.
duration: 5min
completed: 2026-10-10
status: halted
---

# Phase 243 Plan 01: Integrated Evidence and Feedback Preview Summary

**The selected visual owner now declares twelve baselines and exercises a seeded invoice list through its staged action-review drawer; Linux goldens remain unminted.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-10T18:14:02Z
- **Completed:** 2026-10-10T18:18:40Z
- **Tasks:** 1 of 2 completed
- **Files modified:** 4 in the task commit

## Accomplishments

- Added light/dark invoice list and invoice detail/action-review compositions to the existing Playwright visual owner.
- Replaced the subscription date column-position mask with value-matched anchors that wrap and mask timestamp substrings only. Added rendered timestamp and protected-fact exclusion assertions.
- Extended the frozen expected set to twelve images and added absent-directory, empty-directory, one-image, complete-set, and twelve individual missing-file controls.
- All 17 Node guard tests passed. Playwright discovered the visual test. The existing guard correctly reports the four new images missing.

## Task Commits

1. **Task 243-01-01: Prove one invoice journey and faithful rendered masks in the incumbent visual owner** - `dd11264d` (feat)

**Task 243-01-02 remains incomplete.** No PNGs were minted or committed.

## Files Created/Modified

- `accrue_admin/e2e/admin-visual-regression-phase211.spec.js` - Invoice list/detail review flow and timestamp-only masks.
- `accrue_admin/e2e/visual-baseline-set.cjs` - Twelve-file frozen set.
- `accrue_admin/test/js/visual_baseline_set_test.mjs` - Complete, missing-all, one-image, and per-file negative controls.
- `.planning/phases/243-integrated-evidence-and-feedback-preview/tdd/243-01-01-red.json` - Classifier-verified RED evidence for the twelve-name contract.

## Decisions Made

- Kept the selected set to the four approved invoice light/dark additions. The invoice detail capture opens the existing void-action review panel and does not confirm the action.
- Did not publish the local branch to enable Actions. It has no remote ref and contains 534 commits beyond the tracked `origin/main`, so a push would publish unrelated history.

## Deviations from Plan

The expected-set tests, incumbent visual owner changes, and static checks completed as planned. Task 243-01-02 could not start because the authorized workflow dispatch requires a remote ref for the committed source.

## Issues Encountered

`gh workflow run accrue_admin_browser.yml --ref gsd/phase-233-shared-direction-portal-contract` returned HTTP 422: `No ref found for: gsd/phase-233-shared-direction-portal-contract`. GitHub authentication is available and the workflow exists. The branch is local only. The normal Linux comparison was not dispatched, and no pass is claimed. The guard reports the four required invoice PNGs missing: `invoices.png`, `invoices-dark.png`, `invoice-detail.png`, and `invoice-detail-dark.png`.

## Resume Instructions

After the orchestrator makes this exact committed source available under an intended remote ref, dispatch `.github/workflows/accrue_admin_browser.yml` with `workflow_dispatch` on that ref. Retrieve `phase211-visual-baselines`, review before/current/diff for all twelve images in one bounded batch, then commit only the reviewed Ubuntu PNGs. Dispatch the normal `AccrueAdmin Browser UAT` workflow on that committed revision and require the expected-set guard and `e2e:visual-regression` job to pass at the unchanged `threshold: 0.2` and `maxDiffPixelRatio: 0.01`. If either workflow is unavailable or fails, retain EVR-03 as unresolved.

**Unrun verification:** Ubuntu mint and normal comparison were unavailable because the committed phase source ref does not exist on origin.

## Next Phase Readiness

Plan 243-01 is halted with Task 1 committed. EVR-03 remains unresolved until genuine Ubuntu mint artifacts are reviewed, committed, and compared by the normal workflow. Resume Task 2 after the intended source ref becomes available.

---
*Phase: 243-integrated-evidence-and-feedback-preview*
*Completed: 2026-10-10 (halted with external execution blocker)*

## Self-Check: PASSED

- Summary and RED evidence files exist.
- All three changed source files exist.
- Task commit `dd11264d` is an ancestor of HEAD.
- Coverage classifier accepted the YAML; the unobserved Ubuntu comparison remains human-routed and unresolved.
