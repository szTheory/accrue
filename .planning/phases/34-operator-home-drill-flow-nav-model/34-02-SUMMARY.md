---
phase: 34-operator-home-drill-flow-nav-model
plan: 02
subsystem: ui
tags: [liveview, navigation, drill-flow]

requires:
  - plan 01 ScopedPath
provides:
  - Linked invoice rows on customer invoices tab
  - Scoped invoice breadcrumbs including customer ancestor
affects: []

tech-stack:
  added: []
  patterns:
    - "Drill paths use ScopedPath.build/4 with @current_owner_scope"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs

key-decisions:
  - "Invoice breadcrumb adds Customer between Invoices and current invoice"

patterns-established: []

requirements-completed: [OPS-02]

duration: 10min
completed: 2026-04-21
---

# Phase 34 Plan 02 Summary

Customer → Invoices tab rows now deep-link into invoice detail with org-safe URLs, and invoice detail breadcrumbs include a scoped Customer ancestor.

## Task Commits

1. **Customer invoices tab links** — `1918f34`
2. **InvoiceLive breadcrumbs** — `8893a04`
3. **LiveView tests** — `4afa491`

## Verification

Ran: `cd accrue_admin && mix test --warnings-as-errors` — passed.

## Self-Check: PASSED
