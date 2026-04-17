---
phase: 12-first-user-dx-stabilization
plan: 02
subsystem: testing
tags: [installer, host-app, hex, smoke-test, dx]
requires:
  - phase: 10-host-app-dogfood-harness
    provides: canonical examples/accrue_host app and installer-facing host proofs
  - phase: 11-ci-user-facing-integration-gate
    provides: host UAT shell patterns for scripted validation
provides:
  - named Hex-mode smoke scaffold for the canonical host app
  - skipped installer contract tests for rerun taxonomy and conflict artifacts
affects: [phase-12, installer, ci, host-app]
tech-stack:
  added: []
  patterns:
    - scaffold scripts reserve future command order behind explicit activation messaging
    - skipped ExUnit contracts pin future installer behavior without changing runtime code
key-files:
  created:
    - scripts/ci/accrue_host_hex_smoke.sh
  modified:
    - accrue/test/mix/tasks/accrue_install_test.exs
    - accrue/test/mix/tasks/accrue_install_uat_test.exs
key-decisions:
  - "The Hex smoke stays pinned to examples/accrue_host and exits early with an activation message until plan 12-08 turns on real Hex-mode execution."
  - "Installer rerun behavior is reserved with skipped tests inside the existing installer modules so plan 12-03 can activate the contract in place."
patterns-established:
  - "Validation scaffold pattern: reserve exact CLI flags, output labels, and artifact paths before behavior changes land."
  - "Conflict artifact contract: pin .accrue/conflicts/ root plus .new and .snippet suffixes in tests before implementation."
requirements-completed: [DX-01, DX-07]
duration: 2min
completed: 2026-04-16
---

# Phase 12 Plan 02: Installer conflict contracts and Hex smoke scaffolds Summary

**Hex-mode host smoke scaffolding plus skipped installer conflict-contract tests that pin rerun taxonomy, sidecar roots, and artifact suffixes**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-16T21:55:00Z
- **Completed:** 2026-04-16T21:56:37Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `scripts/ci/accrue_host_hex_smoke.sh` as the named Hex-mode scaffold for `examples/accrue_host` with the exact future env flag and command order reserved.
- Expanded the installer unit test module with a skipped contract test for `--force`, `--write-conflicts`, summary labels, `.accrue/conflicts/`, and sidecar headers.
- Expanded the installer UAT module with a skipped host-visible contract test that repeats the same artifact-root and suffix guarantees at the higher-level fixture surface.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the Hex-mode smoke script scaffold** - `a37c708` (chore)
2. **Task 2: Reserve the installer conflict-artifact and summary taxonomy in tests** - `e44eb22` (test)

## Files Created/Modified
- `scripts/ci/accrue_host_hex_smoke.sh` - executable scaffold entrypoint for future Hex dependency smoke.
- `accrue/test/mix/tasks/accrue_install_test.exs` - skipped installer contract assertions for summary labels, no-clobber semantics, and conflict artifacts.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - skipped host-level installer contract assertions for `.accrue/conflicts/` visibility and artifact headers.

## Decisions Made
- Kept the Hex smoke scaffold hard-pinned to `examples/accrue_host` and the literal `ACCRUE_HOST_HEX_RELEASE=1` toggle from the plan.
- Reserved the future installer behavior with skipped tests instead of comments so the strings, paths, and suffixes are executable once plan 12-03 lands.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

- `scripts/ci/accrue_host_hex_smoke.sh`: intentionally prints `Phase 12 plan 08 activates Hex smoke` and exits before the commented command block runs. This is the requested Wave 1 scaffold.
- `accrue/test/mix/tasks/accrue_install_test.exs`: the new conflict-artifact contract test is intentionally skipped with `Phase 12 plan 03 activates this installer contract`.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs`: the new host-visible conflict-artifact contract test is intentionally skipped with `Phase 12 plan 03 activates this installer contract`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 12-03 can implement installer rerun safety against pinned labels, sidecar locations, and artifact headers without inventing new naming.
- Plan 12-08 can replace the scaffold exit in the Hex smoke script with the reserved command sequence.

## Self-Check: PASSED

---
*Phase: 12-first-user-dx-stabilization*
*Completed: 2026-04-16*
