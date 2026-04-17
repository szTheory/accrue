---
phase: 12-first-user-dx-stabilization
plan: 03
subsystem: testing
tags: [installer, dx, conflicts, host-app, exunit]
requires:
  - phase: 12-first-user-dx-stabilization
    provides: skipped installer conflict-contract tests and reserved Hex smoke entrypoints
  - phase: 10-host-app-dogfood-harness
    provides: canonical host-shaped fixture boundaries for installer-generated files
provides:
  - no-clobber rerun semantics for stamped pristine, stamped edited, and unmarked host files
  - conflict sidecars under .accrue/conflicts/templates and .accrue/conflicts/patches
  - active installer tests for rerun summary categories and artifact headers
affects: [installer, host-app, ci, dx]
tech-stack:
  added: []
  patterns:
    - installer writes return typed result tuples with optional conflict artifact paths
    - conflict artifacts stay outside compile and config paths under a dedicated .accrue/conflicts tree
key-files:
  created: []
  modified:
    - accrue/lib/accrue/install/fingerprints.ex
    - accrue/lib/accrue/install/patches.ex
    - accrue/lib/mix/tasks/accrue.install.ex
    - accrue/lib/mix/tasks/accrue.gen.handler.ex
    - accrue/test/mix/tasks/accrue_install_test.exs
    - accrue/test/mix/tasks/accrue_install_uat_test.exs
key-decisions:
  - "Template writes now emit optional sidecars only for skipped stamped-edited or skipped-unmarked files, while --force remains allowed only for unmarked files."
  - "Patch-side manual fallbacks write snippets under .accrue/conflicts/patches/<relative-path>.snippet and report the artifact as a separate summary category."
patterns-established:
  - "Installer output should normalize file-write outcomes into user-facing labels rather than leaking raw internal reasons."
  - "Host-owned generated files stay stamped and safe to rerun, with replacement bodies preserved as sidecars instead of adjacent live-code files."
requirements-completed: [DX-01]
duration: 4m
completed: 2026-04-16
---

# Phase 12 Plan 03: Installer rerun conflict contract Summary

**Installer reruns now update only pristine stamped files, preserve host edits behind .accrue/conflicts sidecars, and surface exact rerun outcome categories in active tests.**

## Performance

- **Duration:** 4m
- **Started:** 2026-04-16T21:56:40Z
- **Completed:** 2026-04-16T22:00:40Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Implemented the no-clobber rerun contract so stamped pristine files are updated, stamped edited files stay skipped even with `--force`, and skipped replacements can be written to `.accrue/conflicts/templates/... .new`.
- Added patch-side conflict artifacts under `.accrue/conflicts/patches/... .snippet` for manual installer outcomes and exposed them as `conflict artifact` entries in installer output.
- Activated the reserved installer unit and UAT coverage so rerun categories, artifact paths, and `target:` / `reason:` headers are enforced by ExUnit.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement no-clobber rerun semantics and conflict-artifact writes** - `00356b0` (`fix`)
2. **Task 2: Activate the installer rerun and conflict-artifact tests** - `4b76abb` (`test`)

## Files Created/Modified
- `accrue/lib/accrue/install/fingerprints.ex` - expands installer write results, preserves stamped edited files, and writes template or patch conflict sidecars with `target:` and `reason:` headers.
- `accrue/lib/accrue/install/patches.ex` - emits manual patch results with optional `.accrue/conflicts/patches/... .snippet` artifacts.
- `accrue/lib/mix/tasks/accrue.install.ex` - normalizes per-file output and summary counts into `created`, `updated pristine`, `skipped user-edited`, `skipped exists`, `manual`, and `conflict artifact`.
- `accrue/lib/mix/tasks/accrue.gen.handler.ex` - adapts the handler generator to the expanded installer write tuple shape.
- `accrue/test/mix/tasks/accrue_install_test.exs` - activates installer unit coverage for user-edited, unmarked, forced, and conflict-artifact reruns.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - activates host-style installer assertions for `.accrue/conflicts/templates/... .new` and `.accrue/conflicts/patches/... .snippet`.

## Decisions Made
- Kept `--force` narrow by leaving the stamped edited-file branch ahead of the unmarked overwrite branch and generating sidecars instead of allowing overwrite.
- Counted conflict artifacts as their own summary category so reruns and CI logs can distinguish a skip from the generated replacement body that accompanies it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the handler generator for the expanded write tuple**
- **Found during:** Task 1 (Implement no-clobber rerun semantics and conflict-artifact writes)
- **Issue:** `Mix.Tasks.Accrue.Gen.Handler` still expected the old two-element return from `Accrue.Install.Fingerprints.write/3`, which raised a compile warning during verification.
- **Fix:** Switched the generator to match the new `{status, path, reason}` write contract while preserving its existing reporting behavior.
- **Files modified:** `accrue/lib/mix/tasks/accrue.gen.handler.ex`
- **Verification:** `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs`
- **Committed in:** `00356b0`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The auto-fix was required to keep the installer/generator surface compiling against the new write contract. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later DX plans can now build setup diagnostics and docs on top of a stable rerun contract that already exposes the real installer outcomes in logs and tests.
- No blocker remains for plan 12-04 or the later docs/validation plans.

## Self-Check: PASSED

- Found `.planning/phases/12-first-user-dx-stabilization/12-03-SUMMARY.md`
- Found commit `00356b0`
- Found commit `4b76abb`

---
*Phase: 12-first-user-dx-stabilization*
*Completed: 2026-04-16*
