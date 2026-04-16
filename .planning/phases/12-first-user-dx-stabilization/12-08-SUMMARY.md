---
phase: 12-first-user-dx-stabilization
plan: 08
subsystem: infra
tags: [ci, hex, mix, phoenix, dx]
requires:
  - phase: 12-02
    provides: host Hex smoke command contract and dependency-mode validation scope
  - phase: 12-03
    provides: installer rerun behavior expected by the canonical host app
provides:
  - canonical host dependency switching between path and Hex modes
  - focused Hex smoke script for installer rerun, compile, migrations, and narrow host proofs
  - CI wiring that keeps path-mode UAT primary and adds Hex package validation
affects: [examples/accrue_host, ci, package-validation]
tech-stack:
  added: []
  patterns:
    - env-gated Mix dependency helpers derive sibling package versions from package mix.exs files
    - host Hex smoke stays narrow and runs after the primary path-mode UAT gate
key-files:
  created: []
  modified:
    - examples/accrue_host/mix.exs
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - examples/accrue_host/test/install_boundary_test.exs
    - scripts/ci/accrue_host_hex_smoke.sh
    - .github/workflows/ci.yml
key-decisions:
  - "The canonical host app remains path-first and switches to Hex deps only when ACCRUE_HOST_HEX_RELEASE=1."
  - "Hex dependency versions are parsed from sibling package @version declarations to avoid stale hardcoded strings."
  - "The host router keeps macro syntax compatible with the published installer so Hex smoke validates the released package surface."
patterns-established:
  - "Host dependency-mode switches should live in helper functions rather than duplicated deps lists."
  - "Compatibility assertions in host boundary tests should target public router shape, not one exact macro formatting style."
requirements-completed: [DX-07]
duration: 5 min
completed: 2026-04-16
---

# Phase 12 Plan 08: Dependency-mode-switched host app and focused Hex smoke in CI Summary

**Canonical host deps now switch between sibling paths and released Hex packages, with a focused Hex smoke added behind the existing path-mode CI gate**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T22:10:00Z
- **Completed:** 2026-04-16T22:15:18Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added `accrue_dep/0` and `accrue_admin_dep/0` helpers in the canonical host app, gated by `ACCRUE_HOST_HEX_RELEASE=1`.
- Activated the real Hex smoke script for installer rerun, compile, migrations, and narrow host proofs.
- Wired CI to keep `scripts/ci/accrue_host_uat.sh` as the primary host gate and run `scripts/ci/accrue_host_hex_smoke.sh` as an additional package-validation step.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the host dependency-mode switch in the canonical example app** - `7f7fc35` (feat)
2. **Task 2: Activate the Hex smoke script and wire it into CI** - `f563c34` (feat)

## Files Created/Modified
- `examples/accrue_host/mix.exs` - switches between path and Hex deps and derives package versions from sibling `mix.exs` files
- `examples/accrue_host/lib/accrue_host_web/router.ex` - uses installer-compatible macro syntax for the existing webhook and admin mounts
- `examples/accrue_host/test/install_boundary_test.exs` - asserts the router boundary by contract rather than one macro formatting style
- `scripts/ci/accrue_host_hex_smoke.sh` - runs the focused Hex-mode installer, compile, migration, and proof sequence
- `.github/workflows/ci.yml` - adds the Hex smoke after the primary host integration gate

## Decisions Made
- Kept the host app as the single canonical example and used helper functions instead of duplicating two dependency lists.
- Parsed Hex version constraints from sibling package `@version` declarations so the host stays aligned with release metadata.
- Preserved the current router behavior while switching macro syntax to match the published installer’s rerun detection logic.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored Hex smoke compatibility with the published installer**
- **Found during:** Task 2 (Activate the Hex smoke script and wire it into CI)
- **Issue:** The released `accrue` installer only detected the older no-parentheses router macro form, so rerunning `mix accrue.install` in Hex mode duplicated the existing webhook/admin mounts and broke compilation.
- **Fix:** Switched the canonical router macros back to the compatible syntax and broadened the host boundary test to assert the public route/mount contract instead of one exact formatting form.
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/router.ex`, `examples/accrue_host/test/install_boundary_test.exs`
- **Verification:** `bash scripts/ci/accrue_host_hex_smoke.sh`; `cd examples/accrue_host && mix compile --warnings-as-errors && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs`
- **Committed in:** `f563c34` (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix stayed within the host app boundary and was required to make Hex smoke validate the released package surface.

## Issues Encountered
- Hex smoke initially rewrote the router into duplicate webhook/admin mounts because the published installer’s rerun detection lagged behind the current host router formatting.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- CI now exercises both dependency modes on the same host app.
- Future host-router assertions should continue to check boundary presence and uniqueness rather than one exact macro formatting style.

## Self-Check: PASSED
- Found `.planning/phases/12-first-user-dx-stabilization/12-08-SUMMARY.md`
- Found task commits `7f7fc35` and `f563c34` in git history
