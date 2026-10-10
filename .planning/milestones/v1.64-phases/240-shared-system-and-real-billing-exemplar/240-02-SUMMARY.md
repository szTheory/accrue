---
phase: 240-shared-system-and-real-billing-exemplar
plan: "02"
subsystem: testing
tags: [visual-regression, node-test, github-actions, linux]
requires:
  - phase: 240-01
    provides: Existing Phase 211 Linux visual-regression owner retained as the comparison gate.
provides:
  - Explicit expected-set validator for the eight Phase 211 light/dark screenshots.
  - Hermetic Node coverage for complete, all-missing, absent-directory, and every one-file-missing set.
  - Unconditional CI preflight and focused guard tests immediately before the existing blocking pixel gate.
affects: [phase-240, admin-ui, visual-regression, ci]
actuals:
  tokens: 1483
  tasks: 2
  commits: 3
plan_head_before: b48168f1c708b86735a6fcc6b7689739f96584c6
plan_head_after: b1e3042056fc005f5862cdf58cf8a59c9465f714
tech-stack:
  added: []
  patterns:
    - Expected fixture membership is an explicit immutable list, independent of directory glob results.
    - CI runs focused preflight tests, exact-set validation, then the existing blocking pixel comparison.
key-files:
  created:
    - accrue_admin/e2e/visual-baseline-set.cjs
    - accrue_admin/test/js/visual_baseline_set_test.mjs
  modified:
    - .github/workflows/accrue_admin_browser.yml
key-decisions:
  - "Require all eight exact Linux Phase 211 PNG names before comparison; do not infer a valid set from any matching PNG."
  - "Keep the pixel comparison unconditional and preserve all existing thresholds, baselines, and narrow timestamp masks."
requirements-completed: [EVR-02]
coverage:
  - id: D1
    description: "A deterministic validator requires all eight named Phase 211 light/dark screenshots and reports every missing name."
    requirement: EVR-02
    verification:
      - kind: unit
        ref: "test/js/visual_baseline_set_test.mjs — 12 tests; complete, absent directory, empty directory, and each of eight one-file omissions"
        status: pass
    human_judgment: false
  - id: D2
    description: "The existing Admin browser workflow runs guard tests, exact-set preflight, and then the blocking Phase 211 pixel comparison without an any-PNG skip condition."
    requirement: EVR-02
    verification:
      - kind: integration
        ref: "actionlint .github/workflows/accrue_admin_browser.yml; static order assertion for guard test → exact-set check → pixel gate; complete-set CLI check found all 8"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-10-09
status: complete
---

# Phase 240 Plan 02: Complete Linux Visual Baseline Guard Summary

**The Linux visual owner now rejects any incomplete Phase 211 baseline set and always reaches its original blocking pixel comparison.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-10-09T19:44:20Z
- **Completed:** 2026-10-09T19:51:22Z
- **Tasks:** 2
- **Files modified:** 5 (three implementation files and two planning records; summary and state tracking follow)

## Accomplishments

- Added a CommonJS validator that requires the eight explicit dashboard, subscriptions, subscription-detail, and component-kitchen light/dark PNG filenames. Missing paths and non-file entries fail closed and list the absent names.
- Added 12 hermetic Node tests covering the exact expected names, complete set, missing directory, empty directory, and omission of each PNG independently.
- Updated the existing Admin browser UAT workflow to run those focused tests and the exact-set validator before the original `e2e:visual-regression` command. Removed the former any-PNG output and conditional pixel-step skip.
- Left committed PNGs, pixel thresholds, and timestamp-only masks unchanged.

## Task Commits

1. **Task 1 RED: Add baseline-set behavior tests** — `305afd31` (`test`)
2. **Task 1 GREEN: Implement exact expected-set validation** — `61dbc0c8` (`feat`)
3. **Task 2: Make the existing visual owner blocking** — `b1e30420` (`ci`)

**Plan metadata:** summary commit recorded separately; state/roadmap tracking is committed after this summary.

## Files Created/Modified

- `accrue_admin/e2e/visual-baseline-set.cjs` — explicit expected-set API and CLI.
- `accrue_admin/test/js/visual_baseline_set_test.mjs` — hermetic positive and negative controls.
- `.github/workflows/accrue_admin_browser.yml` — blocking guard tests, preflight, and unconditional pixel gate.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/deferred-items.md` — records pre-existing unrelated Node-suite failures found during broad validation.
- `.planning/WINDOWS.md` — records the Linux-only pixel run not performed on this macOS host.

## Decisions Made

- The expected set is the named Phase 211 matrix, not a glob of whichever PNG files happen to remain.
- The guard tests run in the existing browser workflow before the preflight and pixel comparison, so both positive and negative guard behavior stay covered in recurring CI.
- No baseline refresh or pixel-policy change is part of this plan; final reviewed goldens remain Phase 243 work.

## Deviations from Plan

None. The planned validator and CI changes were implemented without changing baseline data or pixel-comparison policy.

## Issues Encountered

- The broader `node --test test/js/*.mjs` suite reported 30 passing and 9 failing tests. Failures are in untouched `focus_trap_test.mjs` and `command_palette_test.mjs` harnesses, where `window` or `window.requestAnimationFrame` is missing during existing focus-restoration cleanup. The issue is recorded in `deferred-items.md`; unrelated source and tests were not changed. The independent dropdown and scroll-lock suites passed (12/12).
- The Phase 211 pixel comparison could not be run locally because this host is macOS and the committed images are Linux-specific. The exact-set guard passed against all eight committed files; the Linux pixel run remains recorded as an open unrun verification for CI/phase follow-up.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

The guard is integrated into the recurring Linux browser job and blocks incomplete fixture sets before pixel comparison. The phase should close the recorded Linux-run verification on a Linux CI runner before final acceptance; subsequent Phase 240 plans may now build on the protected visual gate.

---
*Phase: 240-shared-system-and-real-billing-exemplar*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary, validator, and test files exist at their expected paths.
- All three task commits are ancestors of the current plan head.
- The plan-scoped commit check found the RED, GREEN, and CI task commits on this branch.
- `git diff --check` passed.

## Orchestrator Recovery and Wave 1 Gate

The server restarted after the task commits and summary write but before the metadata commit. The orchestrator reconciled the summary and three task commits on this branch, reran all 12 baseline guard tests and the eight-file CLI preflight, then ran `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` in `accrue_admin`: exit 0, 614 tests, 0 failures. Schema and UI capability checks returned `block: false`; codebase drift was explicitly skipped because no STRUCTURE.md exists. No implementation task was repeated. The Linux pixel comparison remains unrun locally; the existing Linux owner and Phase 243 final reviewed-golden closure retain that work.
