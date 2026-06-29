---
phase: 198-propagate-detail-analytics
status: issues_found
depth: standard
reviewer: gsd-code-reviewer
reviewed_at: 2026-06-29T02:37:21Z
files_reviewed: 33
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
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/package.json
  - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
  - accrue_admin/test/accrue_admin/live/customer_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
---

# Phase 198: Code Review Report

**Reviewed:** 2026-06-29T02:37:21Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Reviewed the Phase 198 DETAIL and analytics propagation changes across LiveViews, copy modules, E2E specs, and focused LiveView tests. The main defects are owner-scope enforcement gaps: several direct detail routes and the recovery analytics routes can render or act on rows outside the active organization scope. There is also one robustness issue where invoice drawer action state is still accepted from client params instead of the server-owned drawer state.

Verification evidence supplied with the phase: compile, focused LiveView matrix, package docs, `e2e:phase194`, `e2e:phase195`, and `e2e:phase198` passed. I did not rerun the full suites during this review.

## Critical Issues

### CR-01 [BLOCKER]: Billing Detail Routes Bypass Owner Scope

**File:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex:37`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex:731`, `accrue_admin/lib/accrue_admin/live/charge_live.ex:32`, `accrue_admin/lib/accrue_admin/live/charge_live.ex:453`, `accrue_admin/lib/accrue_admin/live/event_live.ex:25`, `accrue_admin/lib/accrue_admin/live/event_live.ex:154`

**Issue:** `InvoiceLive`, `ChargeLive`, and `EventLive` load detail rows by primary key with `Repo.get/2` and do not prove the row belongs to `socket.assigns.current_owner_scope`. `EventLive.load_event/2` even accepts an owner-scope argument but ignores it. An organization-scoped admin who knows or guesses an id can open `/billing/invoices/:id`, `/billing/payments/:id`, or `/billing/events/:id` for another organization. For invoice and charge pages this also exposes action drawers, raw JSON, customer details, and StepUp-protected destructive actions on the out-of-scope row.

**Fix:**
```elixir
# InvoiceLive: use the existing scoped query instead of load_invoice/1.
case AccrueAdmin.Queries.Invoices.detail(invoice_id, socket.assigns.current_owner_scope) do
  {:ok, invoice} ->
    {:ok, socket |> assign_shell(admin) |> assign_invoice(invoice)}

  :not_found ->
    {:ok,
     socket
     |> put_flash(:error, Copy.Locked.owner_access_denied())
     |> redirect(to: ScopedPath.build(admin["mount_path"] || "/billing", "/invoices", socket.assigns.current_owner_scope))}
end
```

Add equivalent scoped `detail/2` functions for charges and events, then use them for initial load and refresh:

```elixir
def detail(id, owner_scope) when is_binary(id) do
  Charge
  |> join(:inner, [charge], customer in Customer, on: customer.id == charge.customer_id)
  |> scope_query(owner_scope)
  |> where([charge, _customer], charge.id == ^id)
  |> select([charge, _customer], charge)
  |> Repo.one()
  |> case do
    nil -> :not_found
    charge -> {:ok, Repo.preload(charge, [:customer, :refunds])}
  end
end
```

Event detail should use the same owner-scope predicate as `AccrueAdmin.Queries.Events.list/1`, not a raw `Repo.get/2`. Add LiveView tests that open allowed and denied detail ids with an organization `OwnerScope`, not only query-module tests.

### CR-02 [BLOCKER]: Recovery Analytics Ignores Active Organization Scope

**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:31`, `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:33`, `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex:10`, `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex:12`, `accrue_admin/lib/accrue_admin/components/at_risk_table.ex:79`, `accrue_admin/lib/accrue_admin/components/at_risk_table.ex:165`

**Issue:** `RecoveryLive` calls global dunning analytics functions without passing or applying `current_owner_scope`, so org-scoped admins can see aggregate recovered/lost MRR plus at-risk subscription rows and customer labels for all organizations. `CampaignLive` then accepts any subscription id and calls `Dunning.campaign_timeline_grouped/1` and `Dunning.invoices_for_campaign/1` without first proving the subscription is in scope. The at-risk table links also build bare paths from `@base_path`, so even a scoped recovery page would drop the `org` query param when drilling into a campaign.

**Fix:**
```elixir
# RecoveryLive: call an admin-scoped analytics wrapper or extend Dunning opts.
owner_scope = socket.assigns.current_owner_scope

stats = AccrueAdmin.Queries.Dunning.recovered_vs_lost_mrr(owner_scope, since: since, until: until)
funnel = AccrueAdmin.Queries.Dunning.funnel(owner_scope, since: since, until: until)
at_risk = AccrueAdmin.Queries.Dunning.at_risk_subscriptions(owner_scope, since: since, until: until)
```

```elixir
# CampaignLive: prove the subscription before loading dunning history.
with {:ok, _subscription} <-
       AccrueAdmin.Queries.Subscriptions.detail(subscription_id, socket.assigns.current_owner_scope) do
  arcs = Dunning.campaign_timeline_grouped(subscription_id)
  invoice_map = Dunning.invoices_for_campaign(subscription_id)
  {:ok, socket |> assign(:arcs, arcs) |> assign(:invoice_map, invoice_map)}
else
  :not_found ->
    {:ok,
     socket
     |> put_flash(:error, Copy.Locked.owner_access_denied())
     |> redirect(to: ScopedPath.build(admin["mount_path"] || "/billing", "/analytics/recovery", socket.assigns.current_owner_scope))}
end
```

Also build campaign links with `ScopedPath.build/4` or pass a prebuilt scoped href into each at-risk row so org scope survives navigation. Add tests that seed allowed and denied organization subscriptions and verify the overview and direct campaign route exclude denied rows.

## Warnings

### WR-01 [WARNING]: Invoice Drawer Action State Still Trusts Client Params

**File:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex:75`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex:899`

**Issue:** `prepare_action` builds the pending action from `Map.fetch!(params, "action_type")`. That hidden field is client-controlled, so a forged LiveView event can stage a different available invoice action than the server-side `drawer_action_type`, and omitting the field raises `KeyError` and crashes the LiveView process instead of returning the existing unavailable-action error. StepUp still protects destructive actions, but this violates the server-owned action-state requirement and makes the action path brittle.

**Fix:**
```elixir
def handle_event("prepare_action", params, socket) do
  socket = ensure_timeline_events(socket)
  action_type = socket.assigns.drawer_action_type

  with type when is_binary(type) <- action_type,
       true <- action_available?(socket.assigns.invoice, type) do
    action = pending_action(type, params, socket.assigns.timeline_events)

    {:noreply,
     socket
     |> assign(:drawer_action_type, type)
     |> assign(:pending_action, action)}
  else
    _ -> {:noreply, reject_unavailable_invoice_action(socket)}
  end
end

defp pending_action(action_type, params, events) do
  source_event = selected_source_event(params, events)

  %{
    type: action_type,
    source_event_id: source_event && source_event.id,
    source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
  }
end
```

---

_Reviewed: 2026-06-29T02:37:21Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
