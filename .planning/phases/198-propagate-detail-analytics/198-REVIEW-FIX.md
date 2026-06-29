---
phase: 198-propagate-detail-analytics
status: all_fixed
findings_in_scope: 5
fixed: 5
skipped: 0
iteration: 1
fixed_at: 2026-06-29T17:00:36Z
---

# Phase 198 Review Fix Report

## Findings Fixed

- CR-01: Billing detail routes now reload invoices, charges, and events through owner-scoped query helpers so direct detail URLs and refresh paths cannot bypass the active owner scope.
  - Commit: `21d60bb8 fix(198): CR-01 enforce billing detail owner scope`
- CR-02: Recovery analytics now use owner-scoped Dunning query wrappers, At Risk campaign/pagination links preserve scoped org params, and direct campaign routes validate subscription ownership before rendering timelines.
  - Commit: `33fa5977 fix(198): scope recovery analytics by owner`
- WR-01: Invoice action preparation now derives the pending action type from server-held drawer state instead of trusting submitted `action_type` params. The regression test for void actions submits a forged action type and verifies the audit/action remains `void`.
  - Commit: `33fa5977 fix(198): scope recovery analytics by owner`
- E2E contract follow-up: Destructive invoice pending-action confirmation now keeps explicit step-up copy visible before execution, preserving the Phase 198 drawer contract without changing the two-step confirmation flow.
  - Commit: `11237a9e fix(198): keep invoice step-up cue in confirmation`
- WR-02: Coupon detail child promotion-code drilldown links now preserve the active organization scope through `ScopedPath.build/3`.
  - Commit: `07e84725 fix(198): preserve coupon promotion code scope`
- WR-03: Organization-scoped event queries now include `Charge` subjects through `accrue_charges.customer_id`, with query/list/detail and EventLive route coverage for allowed and denied organization access.
  - Commit: `3d805e50 fix(198): include charge events in owner scope`

## Verification

- `cd accrue_admin && mix compile --warnings-as-errors` passed.
- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/event_live_test.exs --max-failures 10` passed: 34 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs test/accrue_admin/components/at_risk_table_test.exs --max-failures 10` passed: 31 tests, 0 failures.
- `cd accrue_admin && mix compile --warnings-as-errors && mix test test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs --max-failures 10` passed: 16 tests, 0 failures.
- `cd accrue_admin && mix compile --warnings-as-errors && mix test test/accrue_admin/queries/events_test.exs test/accrue_admin/live/event_live_test.exs --max-failures 10` passed: 14 tests, 0 failures.
- `cd accrue_admin && npm run e2e:phase198` passed: 24 passed, 4 skipped.

## Residual Risk

- The Dunning wrapper preserves global analytics behavior by delegating to `Accrue.Analytics.Dunning` when no organization scope is active. Organization-scoped behavior has targeted LiveView coverage for metrics, at-risk rows, campaign links, and direct-route denial.
