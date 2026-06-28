---
phase: 197-propagate-list
reviewed: 2026-06-28T18:57:24Z
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 197: Code Review Report

**Reviewed:** 2026-06-28T18:57:24Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

Reviewed the Phase 197 LIST propagation source, query modules, browser smoke, and focused ExUnit coverage. The Dashboard broad-suite failure documented in `197-07-SUMMARY.md` was not treated as a Phase 197 finding. One blocker remains in the reviewed Connect accounts LIST surface: organization-scoped URLs and page chrome are preserved, but the data query and counters still read global Connect account rows.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 (BLOCKER): Connect accounts LIST ignores active organization scope

**File:** `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex:17`
**Also affects:** `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:49`, `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:432`

**Issue:** `DataTable` passes `current_owner_scope` into query modules, and `ConnectAccountsLive` now preserves `?org=...` in default/clear-all links, but `ConnectAccounts.list/1` and `count_newer_than/1` never read `:owner_scope`; they query `Account` directly. The page summary also calls `connect_summary()` with no scope and aggregates all `Account` rows. Because Connect accounts carry `owner_type` and `owner_id`, an admin viewing `/billing/connect?org=allowed-org` can see rows, owner ids, poll counts, and KPI counts for other organizations.

**Fix:**

```elixir
# accrue_admin/lib/accrue_admin/queries/connect_accounts.ex
alias AccrueAdmin.OwnerScope

def list(opts \\ []) do
  filter = Keyword.get(opts, :filter, %{})
  limit = Behaviour.normalize_limit(opts)
  cursor = Behaviour.decode_cursor(opts)
  owner_scope = Keyword.get(opts, :owner_scope)

  Account
  |> scope_query(owner_scope)
  |> filter_query(filter)
  |> Behaviour.apply_cursor(@time_field, cursor)
  # ...
end

def count_newer_than(opts \\ []) do
  filter = Keyword.get(opts, :filter, %{})
  cursor = Behaviour.decode_cursor(opts)
  owner_scope = Keyword.get(opts, :owner_scope)

  Account
  |> scope_query(owner_scope)
  |> filter_query(filter)
  |> Behaviour.count_newer(@time_field, cursor)
  |> Repo.aggregate(:count)
end

defp scope_query(query, nil), do: query
defp scope_query(query, %OwnerScope{mode: :global}), do: query

defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
  organization_id = to_string(organization_id)

  where(
    query,
    [account],
    account.owner_type == "Organization" and account.owner_id == ^organization_id
  )
end
```

Update `ConnectAccountsLive` to build summary counts from the same scoped base query, for example `connect_summary(socket.assigns.current_owner_scope)`, and add query/LiveView tests that insert `org_allowed` and `org_denied` accounts, then assert the org-scoped Connect LIST includes only the allowed row and that KPI counts match the scoped rows.

---

_Reviewed: 2026-06-28T18:57:24Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
