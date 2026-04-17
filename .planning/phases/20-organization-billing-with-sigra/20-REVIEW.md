---
phase: 20-organization-billing-with-sigra
reviewed: 2026-04-17T20:40:50Z
depth: standard
files_reviewed: 40
files_reviewed_list:
  - accrue/test/accrue/billable_test.exs
  - accrue_admin/lib/accrue_admin/auth_hook.ex
  - accrue_admin/lib/accrue_admin/components/data_table.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/accrue_admin/live/customers_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/owner_scope.ex
  - accrue_admin/lib/accrue_admin/queries/customers.ex
  - accrue_admin/lib/accrue_admin/queries/events.ex
  - accrue_admin/lib/accrue_admin/queries/invoices.ex
  - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
  - accrue_admin/lib/accrue_admin/queries/webhooks.ex
  - accrue_admin/lib/accrue_admin/router.ex
  - accrue_admin/test/accrue_admin/live/customer_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
  - examples/accrue_host/lib/accrue_host/accounts/organization.ex
  - examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex
  - examples/accrue_host/lib/accrue_host/accounts/scope.ex
  - examples/accrue_host/lib/accrue_host/billing.ex
  - examples/accrue_host/lib/accrue_host/organizations.ex
  - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
  - examples/accrue_host/lib/accrue_host_web/user_auth.ex
  - examples/accrue_host/mix.exs
  - examples/accrue_host/priv/repo/migrations/20260417210000_create_organizations.exs
  - examples/accrue_host/priv/repo/migrations/20260417210100_create_organization_memberships.exs
  - examples/accrue_host/test/accrue_host/billing_facade_test.exs
  - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
  - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
  - examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs
  - examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs
  - examples/accrue_host/test/support/conn_case.ex
  - examples/accrue_host/test/support/fixtures/accounts_fixtures.ex
findings:
  critical: 1
  warning: 5
  info: 0
  total: 6
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-04-17T20:40:50Z
**Depth:** standard
**Files Reviewed:** 40
**Status:** issues_found

## Summary

The organization-billing scope is mostly wired through the query layer, but several admin UI surfaces still behave as if every session were global. That leaves one exploitable HTML injection path, one confirmed crash on successful bulk replay, and multiple org-scope regressions where navigation or aggregate cards ignore the active organization.

## Critical Issues

### CR-01: Customer list renders stored names/emails into raw HTML without escaping

**File:** `accrue_admin/lib/accrue_admin/live/customers_live.ex:139-146`
**Issue:** `customer_link/2` builds an `<a>` tag with `Phoenix.HTML.raw/1`, but operator precedence means only `row.id` is escaped. If `row.name` or `row.email` contains HTML, that content is inserted verbatim into the admin page. Customer data is processor- or user-supplied, so this is a stored XSS path in the billing admin.
**Fix:**
```elixir
defp customer_link(row, mount_path) do
  label =
    row.name || row.email || row.processor_id || row.id

  escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  Phoenix.HTML.raw(~s(<a href="#{mount_path}/customers/#{row.id}" class="ax-link">#{escaped}</a>))
end
```

## Warnings

### WR-01: Successful bulk replay crashes when audit payload reads a missing `skipped` field

**File:** `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:88-94`
**Issue:** `replay_scoped_rows/1` returns `{:ok, %{requeued: n}}`, but `record_bulk_replay/4` later reads `result.skipped`. On the first successful bulk replay this raises a `KeyError` instead of showing the success flash.
**Fix:**
```elixir
defp replay_scoped_rows(ids) do
  Enum.reduce_while(ids, {:ok, %{requeued: 0, skipped: 0}}, fn id, {:ok, acc} ->
    case DLQ.requeue(id) do
      {:ok, _row} -> {:cont, {:ok, %{acc | requeued: acc.requeued + 1}}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end)
end
```

### WR-02: Webhook pagination scopes rows after `LIMIT`, so org-scoped pages can hide valid rows

**File:** `accrue_admin/lib/accrue_admin/queries/webhooks.ex:20-45`
**Issue:** `list/1` fetches `limit + 1` rows, then filters them in memory with `scope_rows/2`. If the fetched slice is filled with out-of-scope rows, the page comes back short or empty even though in-scope rows exist later in the result set. `paginate/3` then computes the next cursor from the truncated slice, so those hidden rows may never become reachable.
**Fix:** Move ownership proof into the SQL query before `order_by/limit`, or over-fetch in a loop until you have `limit + 1` scoped rows. The first option is the safer one because it keeps pagination and authorization aligned.

### WR-03: Org-scoped webhook poll banners also miscount because `count_newer_than/1` scopes in memory

**File:** `accrue_admin/lib/accrue_admin/queries/webhooks.ex:49-59`
**Issue:** `count_newer_than/1` loads every newer webhook row, filters them in memory, and returns `length/1`. Besides being expensive, it can disagree with the list cursor behavior above and show incorrect "new rows" counts for organization-scoped admins.
**Fix:** Reuse the same SQL-level scoping predicate in `count_newer_than/1` that the page query uses, then return `Repo.aggregate(:count, :id)` from the scoped query.

### WR-04: Organization scope is dropped from admin navigation links and tabs

**File:** `accrue_admin/lib/accrue_admin/live/customers_live.ex:82-146`
**Issue:** Customer row links are built from `@admin_mount_path` alone, so `/billing/customers/:id?org=...` becomes `/billing/customers/:id`. Non-platform org admins clicking a row from the scoped list are redirected out because `OwnerScope.resolve/2` now sees no `org` param.
**Fix:** Thread the active scope into link helpers and append `?org=<slug>` whenever `current_owner_scope.mode == :organization`.

```elixir
href = scoped_admin_path(current_owner_scope, "#{mount_path}/customers/#{row.id}")
```

The same regression pattern appears in:
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:82-145`
- `accrue_admin/lib/accrue_admin/live/customer_live.ex:70-117`
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex:225-230`
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:343-345`

### WR-05: KPI summaries on scoped list pages still expose global aggregate counts

**File:** `accrue_admin/lib/accrue_admin/live/customers_live.ex:125-136`
**Issue:** `customer_summary/0` always aggregates across the full `accrue_customers` table. In organization mode the table rows are scoped, but the KPI cards still reveal total customer counts and payment-method coverage across every billing owner.
**Fix:** Pass `socket.assigns.current_owner_scope` into the summary builder and apply the same owner filter used by the list query before aggregating.

This same leak exists in:
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:131-137`
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:267-286`

### WR-06: `mix verify` skips the new org-billing access tests

**File:** `examples/accrue_host/mix.exs:157-175`
**Issue:** The curated `verify` alias only runs seven files and omits `test/accrue_host_web/org_billing_access_test.exs` and `test/accrue_host_web/org_billing_live_test.exs`. The newly added organization-scope regressions therefore do not run in the fast verification path.
**Fix:**
```elixir
test_files = [
  "test/install_boundary_test.exs",
  "test/accrue_host/billing_facade_test.exs",
  "test/accrue_host_web/subscription_flow_test.exs",
  "test/accrue_host_web/webhook_ingest_test.exs",
  "test/accrue_host_web/trust_smoke_test.exs",
  "test/accrue_host_web/admin_webhook_replay_test.exs",
  "test/accrue_host_web/admin_mount_test.exs",
  "test/accrue_host_web/org_billing_access_test.exs",
  "test/accrue_host_web/org_billing_live_test.exs"
]
```

---

_Reviewed: 2026-04-17T20:40:50Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
