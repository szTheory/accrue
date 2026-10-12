---
phase: 247-evidence-true-details-and-analytics
reviewed: 2026-10-11T23:46:55Z
depth: standard
files_reviewed: 41
files_reviewed_list:
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/app.js
  - accrue_admin/assets/js/hooks/clipboard.js
  - accrue_admin/assets/js/hooks/json_viewer_tabs.js
  - accrue_admin/assets/js/hooks/time_display.js
  - accrue_admin/lib/accrue_admin/components/breadcrumbs.ex
  - accrue_admin/lib/accrue_admin/components/json_viewer.ex
  - accrue_admin/lib/accrue_admin/components/timestamp.ex
  - accrue_admin/lib/accrue_admin/components/window_selector.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/display_components_test.exs
  - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
  - accrue_admin/test/accrue_admin/components/timestamp_test.exs
  - accrue_admin/test/accrue_admin/copy_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
  - accrue_admin/test/accrue_admin/live/charges_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - accrue_admin/test/js/time_display_test.mjs
  - examples/accrue_host/e2e/phase247-time-tracer.spec.js
  - examples/accrue_host/playwright.phase247.config.js
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 247: Code Review Report

**Reviewed:** 2026-10-11T23:46:55Z  
**Depth:** standard  
**Files Reviewed:** 41  
**Status:** issues_found

## Summary

Reviewed the 41-file resolver scope, including the timestamp and preference lifecycle, webhook detail/replay presentation, recovery analytics, shared components, and changed tests. One robustness defect can make timestamps display and copy a non-UTC wall time while labeling it UTC.

## Warnings

### WR-01: UTC timestamp component labels non-UTC DateTime values as UTC

**File:** `accrue_admin/lib/accrue_admin/components/timestamp.ex:12`
**Issue:** `DateTime.to_iso8601(value)` preserves the DateTime's existing offset, while line 17 formats that same value's local wall clock and appends `UTC`. The rendered `<time>` starts with the false UTC label, and the clipboard-failure message also calls the copied value UTC. Passing a non-UTC DateTime (supported by the component's unrestricted `:any` value attribute) therefore misstates both the instant representation and its wall time. This violates the shared component's UTC fallback/exact UTC copy contract.
**Fix:** Convert the instant to UTC before deriving both the ISO copy value and fallback display, preserving the instant and precision; for example, `utc = DateTime.shift_zone!(value, "Etc/UTC")`, then derive `iso` and `utc_text` from `utc`. Alternatively, remove UTC claims and display the source offset consistently, but keep the copy payload unchanged from the displayed source value.

---

_Reviewed: 2026-10-11T23:46:55Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
