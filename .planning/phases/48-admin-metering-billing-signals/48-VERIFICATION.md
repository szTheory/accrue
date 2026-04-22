---
status: passed
phase: 48-admin-metering-billing-signals
updated: 2026-04-22
---

# Phase 48 verification

## Plan must-haves (48-01)

| Criterion | Evidence |
|-----------|----------|
| KPI shows count of `accrue_meter_events` with `stripe_status == "failed"`, first in `ax-kpi-grid` | `dashboard_live.ex`: `failed_meter_event_count` aggregate; first `KpiCard` in section |
| Deep link uses `ScopedPath.build(mount, "/events", owner_scope)`; copy does not claim events list is meter-filtered | `ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)`; `Copy.dashboard_meter_reporting_failures_aria_label/0` |
| New strings under `dashboard_meter_reporting_failures_*` in `AccrueAdmin.Copy` | `copy.ex`: label, meta, aria_label |

## Automated checks (executed)

- `cd accrue_admin && mix compile --warnings-as-errors` — pass
- `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` — pass
- `cd accrue_admin && mix test` — pass

## Human verification

None required for this phase scope.

## Gaps

None.
