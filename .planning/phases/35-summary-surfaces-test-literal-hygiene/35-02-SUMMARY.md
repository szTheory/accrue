---
phase: 35-summary-surfaces-test-literal-hygiene
plan: "02"
subsystem: testing
tags: [exunit, playwright, copy, e2e]

requires:
  - phase: 35-summary-surfaces-test-literal-hygiene
    plan: "01"
    provides: AccrueAdmin.Copy dashboard_* strings and DashboardLive wiring
provides:
  - ExUnit and host tests asserting dashboard chrome via AccrueAdmin.Copy
  - CommonJS copy_dashboard.js mirror for Node/Playwright + CI smoke
affects:
  - operator-dashboard-test-maintenance

tech-stack:
  added: []
  patterns:
    - "Playwright and CI import examples/accrue_host/e2e/support/copy_dashboard.js; Elixir tests alias AccrueAdmin.Copy."

key-files:
  created:
    - examples/accrue_host/e2e/support/copy_dashboard.js
  modified:
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
    - accrue_admin/test/accrue_admin/live/auth_hook_test.exs
    - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
    - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
    - accrue_admin/e2e/phase7-uat.spec.js
    - scripts/ci/accrue_host_browser_smoke.cjs

key-decisions:
  - "Used relative require from scripts/ci and accrue_admin/e2e into examples/accrue_host per plan."

patterns-established:
  - "JS mirror header documents SYNC target in copy.ex; constants named DASHBOARD_* align to dashboard_* functions."

requirements-completed: [OPS-04, OPS-05]

duration: 25min
completed: 2026-04-21
---

# Phase 35 — Plan 02 Summary

**Tests and Playwright now bind static dashboard assertions to `AccrueAdmin.Copy` and a single `copy_dashboard.js` mirror so headline and KPI labels cannot drift from HEEx.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3
- **Files modified:** 6 (+1 created)

## Accomplishments

- Replaced duplicated dashboard literals in admin ExUnit, host mount test, phase13 Playwright, admin phase7 UAT, and CI browser smoke with `Copy.*()` or imported constants.
- Added `examples/accrue_host/e2e/support/copy_dashboard.js` with byte-aligned strings for `DASHBOARD_DISPLAY_HEADLINE`, breadcrumb home, and two KPI labels used in JS.

## Task Commits

1. **Task 35-02-01** — `1fd5273` (test)
2. **Task 35-02-02** — `16bcf7b` (test)
3. **Task 35-02-03** — `e574d26` (test)

## Files Created/Modified

- `examples/accrue_host/e2e/support/copy_dashboard.js` — CommonJS exports synced with `AccrueAdmin.Copy`.
- Test and e2e files updated per plan acceptance greps.

## Decisions Made

- None beyond plan — followed specified require paths and constant names.

## Deviations from Plan

None.

## Issues Encountered

None.

## Self-Check: PASSED

- `mix test` (scoped): accrue_admin dashboard + auth hook tests; accrue_host `admin_mount_test.exs`.
- `npx playwright test e2e/phase13-canonical-demo.spec.js --project=chromium-desktop` in `examples/accrue_host`.

## Next Phase Readiness

Phase 36 can assume dashboard copy SSOT is shared across Elixir and Node runners.

---
*Phase: 35-summary-surfaces-test-literal-hygiene*
*Completed: 2026-04-21*
