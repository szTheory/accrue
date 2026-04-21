---
phase: 34-operator-home-drill-flow-nav-model
plan: 01
subsystem: ui
tags: [liveview, navigation, accessibility]

requires: []
provides:
  - AccrueAdmin.ScopedPath for org-safe admin URLs
  - Linked KPI cards on dashboard home
affects: []

tech-stack:
  added: []
  patterns:
    - "ScopedPath mirrors CustomerLive scoped_mount_path/4 semantics"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/test/accrue_admin/scoped_path_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/components/kpi_card.ex
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css

key-decisions:
  - "KPI cards use anchor root with aria_label when href is set"

patterns-established:
  - "Central ScopedPath.build/4 for mount + suffix + owner scope + optional query"

requirements-completed: [OPS-01]

duration: 15min
completed: 2026-04-21
---

# Phase 34 Plan 01 Summary

Dashboard home KPIs deep-link into Customers, Subscriptions, Invoices, and Webhooks using the same org-scoped URL rules as customer detail navigation.

## Task Commits

1. **ScopedPath module** — `3df7079`
2. **ExUnit table tests** — `74368e4`
3. **KpiCard href mode + dashboard + CSS** — `73e24d5`

## Verification

Ran: `cd accrue_admin && mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/components/navigation_components_test.exs --warnings-as-errors` — passed.

## Self-Check: PASSED
