---
phase: 35-summary-surfaces-test-literal-hygiene
plan: "01"
subsystem: ui
tags: [phoenix, liveview, copy, ops]

requires:
  - phase: 34-operator-home-drill-flow-nav-model
    provides: Dashboard KPI layout and KpiCard wiring used unchanged
provides:
  - Canonical dashboard operator strings in AccrueAdmin.Copy
  - DashboardLive HEEx bound to Copy for chrome, KPI labels, meta, aria-labels, timelines
affects:
  - phase-35-plan-02-test-literals

tech-stack:
  added: []
  patterns:
    - "Operator dashboard copy: dashboard_* functions on AccrueAdmin.Copy"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex

key-decisions:
  - "Used function-return attributes (e.g. label={Copy...}) where HEEx accepts expressions; used <%= %> for eyebrow/headings inside text nodes."

patterns-established:
  - "DashboardLive: no raw operator English in HEEx — only Copy.dashboard_* plus numeric/format composition."

requirements-completed: [OPS-04, OPS-05]

duration: 15min
completed: 2026-04-21
---

# Phase 35 — Plan 01 Summary

**Dashboard operator copy centralized in `AccrueAdmin.Copy` with twenty-nine `dashboard_*` functions and LiveView HEEx wired exclusively to those strings.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added full dashboard string surface to `AccrueAdmin.Copy` (breadcrumb, chrome, KPI grid, activity cards, timeline labels, delta suffixes).
- Replaced all matching literals in `DashboardLive` render and `page_title` assign with `Copy` calls; query logic unchanged.

## Task Commits

1. **Task 35-01-01** — `7715e91` (feat)
2. **Task 35-01-02** — `b3bf2f9` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/copy.ex` — `dashboard_*` SSOT strings.
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — HEEx uses `alias AccrueAdmin.Copy` and `Copy.*()` throughout the dashboard surface.

## Decisions Made

- Extended `page_title` to use `Copy.dashboard_breadcrumb_home()` so the shell title stays aligned with breadcrumb copy without a second literal.

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

None.

## Next Phase Readiness

Plan 35-02 can bind ExUnit, host tests, Playwright, and CI smoke to `Copy` / shared JS mirror using `dashboard_display_headline/0` and related keys.

---
*Phase: 35-summary-surfaces-test-literal-hygiene*
*Completed: 2026-04-21*
