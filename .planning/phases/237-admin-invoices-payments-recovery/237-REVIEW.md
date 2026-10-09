---
phase: 237-admin-invoices-payments-recovery
reviewed: 2026-10-09T01:40:40Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - accrue/lib/accrue/analytics/dunning.ex
  - accrue_admin/assets/css/app.css
  - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  - accrue_admin/lib/accrue_admin/components/money_formatter.ex
  - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/queries/dunning.ex
  - accrue_admin/lib/accrue_admin/scoped_path.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/charges_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - scripts/ci/accrue_host_seed_e2e.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 237: Code Review Report

**Reviewed:** 2026-10-09T01:40:40Z  
**Depth:** standard  
**Files Reviewed:** 21  
**Status:** issues_found

## Summary

Reviewed the supplied billing, recovery analytics, scoped navigation, stylesheet, fixture, and test changes. The invoice and refund confirmation flows revalidate current scoped records before dispatch, and return destinations are rebuilt from an allowlist. One recovery loading/error state presents a misleading zero count.

## Warnings

### WR-01: Recovery table reports zero rows before the query succeeds

**File:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex:65`  
**Issue:** RecoveryLive initializes `rows` to `[]` while its asynchronous query is loading and also clears the rows on query failure. This header unconditionally renders that length as the number of active campaigns, so users see “0 active dunning campaigns” alongside a loading or error message. That can be mistaken for a successful empty result.
**Fix:** Render the count only in ready states; show a neutral loading label while loading and omit the count or label it unavailable on error.

---

_Reviewed: 2026-10-09T01:40:40Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
