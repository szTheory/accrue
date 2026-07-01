---
phase: 197-propagate-list
reviewed: 2026-06-28T19:37:35Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - accrue_admin/e2e/admin-spec-list-phase197.spec.js
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/billing_event.ex
  - accrue_admin/lib/accrue_admin/copy/connect.ex
  - accrue_admin/lib/accrue_admin/copy/coupon.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
  - accrue_admin/lib/accrue_admin/live/coupons_live.ex
  - accrue_admin/lib/accrue_admin/live/customers_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/queries/charges.ex
  - accrue_admin/lib/accrue_admin/queries/connect_accounts.ex
  - accrue_admin/lib/accrue_admin/queries/webhooks.ex
  - accrue_admin/package.json
  - accrue_admin/test/accrue_admin/copy_test.exs
  - accrue_admin/test/accrue_admin/live/charges_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
  - accrue_admin/test/accrue_admin/live/customers_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
  - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
  - accrue_admin/test/support/list_contracts.ex
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 197: Code Review Report

**Reviewed:** 2026-06-28T19:37:35Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** clean / passed

## Summary

Reviewed the declared Phase 197 LIST propagation source, query modules, browser smoke, and focused ExUnit coverage at standard depth. A remediation review of the Connect accounts owner-scope blocker fix committed as `3f08803e` (`fix(197): scope connect accounts by owner`) confirmed the prior critical finding is resolved: `ConnectAccounts.list/1` and `count_newer_than/1` now apply the active organization owner scope before filtering, cursor handling, ordering, and counting, and `ConnectAccountsLive` now derives KPI summary counts from the same organization-scoped Connect account base query.

A final narrow remediation review of `8e174eb9` (`fix(197): align list copy with UI spec`) found no remaining issues. Events and Connect render the locked Phase 197 list subtitle helpers, Webhooks renders the bulk replay cancel label through `AccrueAdmin.Copy`, and the affected copy/LiveView tests cover those render paths.

All reviewed files meet quality standards. No blocking issues remain.

## Narrative Findings (AI reviewer)

No actionable bugs, regressions, security issues, or test gaps were found in the reviewed Phase 197 scope.

Final UI-copy remediation review covered commit `8e174eb9` and confirmed:

- `accrue_admin/lib/accrue_admin/live/events_live.ex` renders `Copy.events_list_subtitle()` in the PageHeader description.
- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` renders `Copy.connect_accounts_list_subtitle()` in the PageHeader description.
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` renders `Copy.webhooks_retry_cancel_label()` instead of an inline Cancel label.
- `accrue_admin/lib/accrue_admin/copy.ex` exposes `webhooks_retry_cancel_label/0`, and the affected copy/LiveView tests assert the helper-backed strings.

Prior `CR-01 (BLOCKER): Connect accounts LIST ignores active organization scope` is resolved by commit `3f08803e`. The focused remediation review covered the four changed files:

- `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex`
- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex`
- `accrue_admin/test/accrue_admin/queries/query_modules_test.exs`
- `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs`

## Verification

- `mix test test/accrue_admin/queries/query_modules_test.exs:416 test/accrue_admin/live/connect_accounts_live_test.exs:133` from `accrue_admin/` passed: 2 tests, 0 failures.
- `mix test test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` from `accrue_admin/` passed: 29 tests, 0 failures.
- `mix test test/accrue_admin/copy_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/webhooks_live_test.exs --max-failures 3` from `accrue_admin/` passed: 32 tests, 0 failures.
- Post-`8e174eb9` remediation context also records the full Phase 197 LiveView gate as 63 tests, 0 failures; the query/copy/component gate as 64 tests, 0 failures; and `mix compile --warnings-as-errors` as passed.
- `mix format --check-formatted` on the four reviewed files passed.
- `mix compile --warnings-as-errors` from `accrue_admin/` passed.

---

_Reviewed: 2026-06-28T19:37:35Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
