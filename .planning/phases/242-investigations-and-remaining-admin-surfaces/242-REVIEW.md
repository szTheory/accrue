---
phase: 242-investigations-and-remaining-admin-surfaces
reviewed: 2026-10-10T14:04:01Z
depth: standard
files_reviewed: 49
files_reviewed_list:
  - accrue_admin/assets/js/hooks/command_palette.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase191.spec.js
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/connect.ex
  - accrue_admin/lib/accrue_admin/copy/coupon.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/live/coupons_live.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/scoped_path.ex
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/app_shell_test.exs
  - accrue_admin/test/accrue_admin/components/global_search_test.exs
  - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
  - accrue_admin/test/accrue_admin/copy/connect_test.exs
  - accrue_admin/test/accrue_admin/copy_test.exs
  - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
  - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
  - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
  - accrue_admin/test/accrue_admin/queries/events_test.exs
  - accrue_admin/test/accrue_admin/scoped_path_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - examples/accrue_host/e2e/phase234-search-completion.spec.js
  - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 242: Code Review Report

**Reviewed:** 2026-10-10T14:04:01Z  
**Depth:** standard  
**Files Reviewed:** 49  
**Status:** issues_found

## Summary

Reviewed all 49 scoped files, with detailed tracing of scoped return decoding, search lifecycle, Connect fee review, and single/bulk replay state. One retry-path defect loses successful search groups after retrying a failed group. No source files were changed; this review did not run tests.

## Warnings

### WR-01: Retrying a failed search group discards successful results

**Severity:** WARNING  
**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:127-153,173-200`  
**Issue:** The retry path passes the currently successful `socket.assigns.results` as `initial_results`, but `fetch_results/3` ignores that argument and initializes its accumulator with `empty_results()`. On completion, the update replaces the entire result map with that accumulator. For example, if customers loaded and invoice lookup failed, retrying invoices returns an empty customers list along with the invoice retry result; the UI loses the successful group despite its stated partial-result behavior.
**Fix:** Seed the retry fetch accumulator with the existing results (or merge only fetched groups into the current results when applying the result update). Keep the normal full-search path seeded with empty results, and retain prior failed-group results only according to the intended retry semantics.

---

_Reviewed: 2026-10-10T14:04:01Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
