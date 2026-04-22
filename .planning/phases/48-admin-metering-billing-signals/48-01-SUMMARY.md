---
phase: 48-admin-metering-billing-signals
plan: "01"
subsystem: ui
tags: [liveview, metering, kpi, accrue_admin_copy]

requires:
  - phase: v1.10 metering
    provides: MeterEvent schema, failed terminal status semantics
provides:
  - Dashboard KPI counting accrue_meter_events with stripe_status failed
  - Honest /events deep link with Copy-backed aria + meta
affects: [phase-49-drill-flows, phase-50-copy-verify]

tech-stack:
  added: []
  patterns:
    - "KPI stats: Repo.aggregate on MeterEvent like existing webhook backlog pattern"
    - "Operator strings: dashboard_meter_reporting_failures_* prefix in AccrueAdmin.Copy"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs

key-decisions:
  - "Linked KPI targets Events index (/events) with copy that does not imply meter-only filtering"
  - "Task 5 (CSS grid) skipped after five-tile layout deemed acceptable without app.css changes"

patterns-established:
  - "Meter-adjacent dashboard signals use MeterEvent + Copy SSOT + ScopedPath.build"

requirements-completed: [ADM-01]

duration: 25min
completed: 2026-04-22
---

# Phase 48: Admin metering & billing signals — Plan 01 summary

**Terminal failed `MeterEvent` rows surface as the first dashboard KPI with `AccrueAdmin.Copy` strings and an honest deep link to the billing event ledger.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 4 executed (Task 5 conditional skipped)
- **Files modified:** 3

## Accomplishments

- `dashboard_stats/0` exposes `failed_meter_event_count` from `accrue_meter_events` where `stripe_status == "failed"`.
- First `ax-kpi-grid` card links to `ScopedPath.build(..., "/events", ...)` with meta naming the table and status predicate.
- LiveView test inserts a failed meter event and asserts copy, href, and rendered count.

## Task commits

1. **Task 1: Extend dashboard_stats** — `b542b8f`
2. **Task 2: Copy helpers** — `7563f0f`
3. **Task 3: KpiCard** — `9b21c80`
4. **Task 4: Tests** — `19019f8`

## Deviations from plan

None for shipped tasks. **Task 5** skipped: five KPI tiles did not require `app.css` breakpoint edits (noted here per plan acceptance).

## Issues encountered

- Initial test assertions used `:binary.match` on substrings that also appear in shell/nav (`Customers`, `/billing/customers`); replaced with unique meter copy anchor + segment assertion.

## Next phase readiness

- ADM-01 satisfied; Phases 49–50 remain for ADM-02..06.

## Self-check: PASSED

- `cd accrue_admin && mix compile --warnings-as-errors` — exit 0
- `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` — exit 0
- `cd accrue_admin && mix test` — exit 0
