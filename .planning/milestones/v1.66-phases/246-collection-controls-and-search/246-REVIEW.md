---
phase: 246-collection-controls-and-search
reviewed: 2026-10-11T19:30:00Z
depth: standard
files_reviewed: 43
files_reviewed_list:
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/hooks/command_palette.js
  - accrue_admin/lib/accrue_admin/components/data_table.ex
  - accrue_admin/lib/accrue_admin/components/empty_state.ex
  - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/components/topbar.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
  - accrue_admin/lib/accrue_admin/live/coupons_live.ex
  - accrue_admin/lib/accrue_admin/live/customers_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/queries/invoices.ex
  - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/data_table_test.exs
  - accrue_admin/test/accrue_admin/components/empty_state_test.exs
  - accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs
  - accrue_admin/test/accrue_admin/components/global_search_test.exs
  - accrue_admin/test/accrue_admin/live/charges_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
  - accrue_admin/test/accrue_admin/live/customers_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - examples/accrue_host/e2e/phase246-collection-filters.spec.js
  - examples/accrue_host/e2e/phase246-global-search.spec.js
  - examples/accrue_host/e2e/phase246-invoice-filters.spec.js
  - examples/accrue_host/e2e/phase246-table-reading.spec.js
  - examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/playwright.phase246.config.js
  - examples/accrue_host/priv/repo/seeds/ordinary.exs
  - examples/accrue_host/test/ordinary_preview_seed_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 246: Code Review Report

**Reviewed:** 2026-10-11T19:30:00Z  
**Depth:** standard  
**Files Reviewed:** 43  
**Status:** issues_found

## Summary

Reviewed the 43 files resolved from Phase 246 task commits, including the identity repair. The invoice and subscription status sets are allowlisted and canonicalized, and owner scope is retained through the filter navigation paths reviewed. Two defects remain: the ordinary seed's test-mode database guard can accept a remote database with a matching name, and an overlong global-search query is presented as a valid search with no matches.

## Critical Issues

### CR-01: Test-mode ordinary seed can run against a remote matching database

**Severity:** BLOCKER  
**File:** `examples/accrue_host/priv/repo/seeds/ordinary.exs:18-20`  
**Issue:** In test mode, the target check accepts any connected PostgreSQL server when its database is named `accrue_host_test` (optionally suffixed with digits) and its role is `postgres`. Unlike the development branch, it does not verify `server_address` against the isolated Compose database. If `DATABASE_URL` or `PGHOST` points at a remote database using that name, the remaining environment guards can still pass, after which this script deletes Phase 191 rows and rewrites the demo operator password.  
**Fix:** Require the test Repo connection to match an explicitly configured isolated test host/network (or a per-run database identity token) in addition to the test database name and role; fail closed when that identity cannot be verified.

## Warnings

### WR-01: Overlong search is reported as a no-results search

**Severity:** WARNING  
**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:103-104`  
**Issue:** When the trimmed query exceeds `@max_query_length`, the handler clears results and loading state but keeps the oversized query. The render path then meets `not @loading and @failures == [] and no_results?(@results)` and displays the normal “No results” message. This falsely tells the user a search completed and found nothing, while the server deliberately did not run the query.  
**Fix:** Track a query-too-long validation state and render an explicit length message (or trim/reject the input with clear feedback); exclude that state from the ordinary no-results condition.

---

_Reviewed: 2026-10-11T19:30:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
