---
phase: 49-drill-flows-navigation
plan: "01"
subsystem: ui
requirements-completed: [ADM-02]
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
completed: 2026-04-22
---

# Phase 49 plan 01 summary

**Subscription detail now matches the invoice drill pattern:** `ScopedPath` breadcrumbs through Dashboard → Subscriptions → Customer → subscription label, plus a bounded “Related billing” card (customer, invoices, charges, events) using only `customer_id` list filters where supported.

## Task commits

1. **Copy helpers** — `feat(49-01): add subscription drill copy helpers for ADM-02`
2. **LiveView** — `feat(49-01): ScopedPath breadcrumbs and related billing on SubscriptionLive`

## Verification

- `cd accrue_admin && mix compile --warnings-as-errors` — exit 0
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` — exit 0 (after 049-02 tests landed)

## Self-Check: PASSED
