---
phase: 198-propagate-detail-analytics
reviewed: 2026-06-29T17:26:48Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
  - accrue_admin/e2e/admin-spec-overview-phase194.spec.js
  - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/billing_event.ex
  - accrue_admin/lib/accrue_admin/copy/connect.ex
  - accrue_admin/lib/accrue_admin/copy/coupon.ex
  - accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/copy/locked.ex
  - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
  - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/queries/charges.ex
  - accrue_admin/lib/accrue_admin/queries/dunning.ex
  - accrue_admin/lib/accrue_admin/queries/events.ex
  - accrue_admin/package.json
  - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
  - accrue_admin/test/accrue_admin/live/customer_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - accrue_admin/test/accrue_admin/queries/events_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
blocking_status: pass
---

# Phase 198: Code Review Report

**Reviewed:** 2026-06-29T17:26:48Z
**Depth:** standard
**Files Reviewed:** 39
**Status:** clean
**Blocking Status:** pass

## Summary

Reviewed current HEAD `b5876182` after the Phase 198 review-fix commits `5d53147f` and `b5876182`, using the Phase 198 source/test scope from the existing review artifact as the guide.

All reviewed files meet quality standards. No new authorization, scope, correctness, or test-coverage issues were found in the current HEAD changes.

Verified closed findings:

- CR-01: Billing detail routes now enforce owner scope for invoices, charges, and events before rendering detail data.
- CR-02: Recovery analytics and campaign detail routes now use organization-scoped query paths and deny out-of-scope records.
- WR-01: Invoice action preparation uses the server-selected drawer action and does not trust submitted `action_type`.
- WR-02: Coupon detail promotion-code drilldowns preserve the active organization scope.
- WR-03: Organization-scoped event list/detail queries include in-scope `Charge` subjects and exclude denied organization charge events.
- WR-04: Events index summary counts and empty-state behavior use the same scoped event relation, including in-scope `Charge` subjects.
- WR-05: Charge refund preparation has a visible submit button, and browser coverage clicks the visible button rather than using `requestSubmit()`.
- WR-06: Coupon, promotion code, and event detail breadcrumbs preserve `?org=...` on dashboard and index breadcrumb links.

## Narrative Findings (AI reviewer)

No Critical, Warning, or Info findings.

## Verification Notes

This review was performed by direct source and test inspection at current HEAD. The refund drawer browser path was rechecked specifically: the E2E flow clicks the visible `Review refund` button, and the LiveView markup exposes that visible preparation submit control.

No additional test suite was rerun during this review pass.

---

_Reviewed: 2026-06-29T17:26:48Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
