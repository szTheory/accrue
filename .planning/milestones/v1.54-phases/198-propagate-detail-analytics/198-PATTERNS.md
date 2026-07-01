# Phase 198: Propagate DETAIL + analytics - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 33 planned new/modified files
**Analogs found:** 33 / 33

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---:|---:|---|---|
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | component | request-response + event-driven | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | component | request-response + event-driven | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | component | request-response + event-driven | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/coupon_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/coupon_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` | component | request-response + event-driven | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | component | request-response + event-driven | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/event_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/coupon_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | component | transform | `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | exact |
| `accrue_admin/test/accrue_admin/live/customer_live_test.exs` | test | request-response + event-driven | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | test | request-response + event-driven | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/charge_live_test.exs` | test | request-response + event-driven | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/connect_account_live_test.exs` | test | request-response + event-driven | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` | test | request-response + event-driven | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/live/event_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` | test | transform | `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` | exact |
| `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` | test | browser request-response + event-driven | `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` | exact |
| `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` | test | browser request-response | `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` | exact |
| `accrue_admin/package.json` | config | batch | `accrue_admin/package.json` | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy.ex` | exact |
| `accrue_admin/lib/accrue_admin/copy/invoice.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/coupon.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/promotion_code.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/coupon.ex` | exact |
| `accrue_admin/lib/accrue_admin/copy/connect.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/invoice.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/billing_event.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/invoice.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/locked.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/locked.ex` | exact |

## Pattern Assignments

### Detail LiveViews: `customer_live.ex`, `invoice_live.ex`, `charge_live.ex`, `coupon_live.ex`, `promotion_code_live.ex`, `connect_account_live.ex`, `webhook_live.ex`, `event_live.ex`

**Primary analog:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`

**Imports pattern** (lines 12-30): use component aliases only for the primitives the page actually renders; add `DetailDrawer`, `DropdownMenu`, `Timeline`, `JsonViewer`, `StepUpAuthModal` where Phase 198 moves content into that shape.

```elixir
alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  Detail,
  DetailDrawer,
  DropdownMenu,
  FlashGroup,
  JsonViewer,
  RelatedResources,
  StatusBadge,
  StepUpAuthModal,
  Timeline
}

alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Subscriptions
alias AccrueAdmin.ScopedPath
alias AccrueAdmin.StepUp
```

**Mount/state pattern** (lines 59-76): assign page resource, lazy flags, related items, flashes, and drawer/action state in `mount/3`.

```elixir
{:ok,
 socket
 |> assign_shell(admin)
 |> assign(:subscription, subscription)
 |> assign(:customer, subscription.customer)
 |> assign(:timeline_events, [])
 |> assign(:timeline_events_loaded?, false)
 |> assign(:raw_json_loaded?, false)
 |> assign(:related_items, related_items(subscription, mount_path, scope))
 |> assign(:flashes, [])
 |> assign(:drawer_action_type, nil)
 |> assign(:pending_action, nil)}
```

**Summary/drill/render order pattern** (lines 210-222, 270-350): render summary card, then `Detail.summary_list`, then drills, one related wrapper, lazy Activity, lazy Raw JSON.

```elixir
<Detail.summary_card eyebrow={Copy.subscription_detail_eyebrow()} title={@subscription.processor_id || @subscription.id}>
  <:status><StatusBadge.status_badge status={@subscription.status} /></:status>
  <:facts>
    <span><%= @customer.name || @customer.email || @customer.id %></span>
    <span>period ends <%= format_datetime(@subscription.current_period_end) %></span>
    <span><%= lifecycle_operator_summary(@subscription) %></span>
  </:facts>
</Detail.summary_card>

<Detail.summary_list rows={summary_rows(@subscription, @customer, @admin_mount_path, @current_owner_scope)} />
```

```elixir
<section class="ax-stack-xl" aria-label="Subscription details">
  <details class="ax-detail-section" data-ax-drill-section="billing-items">
    <summary class="ax-detail-section-head">
      <span class="ax-detail-section-title">Billing & items</span>
    </summary>
    <Detail.detail_field_list fields={billing_fields(@subscription)} />
  </details>
</section>

<div data-ax-related-resources>
  <RelatedResources.related_resources items={@related_items} />
</div>

<details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
  ...
</details>

<details class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
  ...
</details>
```

**Summary row helper pattern** (lines 635-668): build resource-specific rows in pure helpers; row actions can link or open LiveView actions.

```elixir
defp summary_rows(subscription, customer, mount_path, scope) do
  subscription_label = subscription.processor_id || subscription.id

  base_rows = [
    %{label: "Lifecycle state", value: "#{humanize(subscription.status)} - #{predicate_summary(subscription)}"},
    %{
      label: "Customer",
      value: customer_label(customer),
      action_label: "View",
      action_context: "customer for subscription #{subscription_label}",
      action_href: ScopedPath.build(mount_path, "/customers/#{customer.id}", scope)
    },
    %{
      label: "Plan / price",
      value: current_price_id(subscription) || "-"
    }
    |> maybe_put_summary_action(swap_plan_available?(subscription), %{
      action_label: "Change",
      action_context: "plan for subscription #{subscription_label}",
      action_event: "open_action_drawer",
      action_value: "swap_plan"
    })
  ]

  base_rows
  |> maybe_add_quantity_row(subscription, subscription_label)
  |> maybe_add_dunning_row(subscription, subscription_label)
end
```

**Action band/menu pattern** (lines 226-259, 819-866): at most two visible primary buttons; overflow is grouped and only opens page-owned LiveView events.

```elixir
<section class="ax-card ax-detail-action-band" data-ax-action-band>
  <header class="ax-page-header">
    <div>
      <p class="ax-eyebrow">Actions</p>
      <h2 class="ax-heading">Subscription actions</h2>
    </div>
    <div class="ax-page-actions">
      <button :if={@swap_plan_available} phx-click="open_action_drawer" phx-value-action_type="swap_plan" data-ax-primary-action>
        <%= action_label("swap_plan") %>
      </button>
      <DropdownMenu.action_menu label="More actions" groups={action_menu_groups(@subscription)} id="subscription-action-menu" />
    </div>
  </header>
</section>
```

```elixir
defp action_menu_groups(subscription) do
  [
    %{label: "Edit billing", items: [...] |> Enum.reject(&(&1 in [false, nil]))},
    %{label: "Collection", items: [...]},
    %{label: "Danger zone", items: [action_item("cancel_now", subscription_label, danger?: true)]}
  ]
  |> Enum.reject(&(Map.get(&1, :items) == []))
end

defp action_item(action_type, subscription_label, opts \\ []) do
  %{
    label: action_label(action_type),
    event: "open_action_drawer",
    value: action_type,
    danger?: Keyword.get(opts, :danger?, false),
    hidden_context: "for subscription #{subscription_label}"
  }
end
```

**Drawer pattern** (lines 352-386): forms and confirmations appear only after operator intent.

```elixir
<DetailDrawer.detail_drawer
  id="subscription-action-drawer"
  open={drawer_open?(@drawer_action_type, @pending_action)}
  title={drawer_title(@drawer_action_type, @pending_action)}
  subtitle="Review the staged billing change before confirming it."
  close_event="cancel_pending_action"
>
  <%= if @pending_action do %>
    <.pending_action_content pending_action={@pending_action} subscription={@subscription} customer={@customer} />
  <% else %>
    <.action_form action_type={@drawer_action_type} subscription={@subscription} events={@timeline_events} />
  <% end %>

  <:footer>
    <button :if={@pending_action} phx-click="confirm_action" class="ax-button ax-button-primary" data-role="confirm-action" data-ax-action-drawer-confirm>
      Confirm <%= action_label(@pending_action.type) %>
    </button>
    <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost">Cancel</button>
  </:footer>
</DetailDrawer.detail_drawer>
```

**Validation / server-side action allowlist pattern** (lines 936-999): parse params into typed action maps, reject malformed params, and check action availability server-side.

```elixir
defp pending_action(params, socket) do
  source_event = selected_source_event(params, socket.assigns.timeline_events)

  with {:ok, new_price_id} <- optional_string(params["new_price_id"]),
       {:ok, item_id} <- optional_string(params["item_id"]),
       {:ok, pause_behavior} <- pause_behavior_param(params["pause_behavior"]),
       {:ok, proration} <- proration_param(params["proration"]) do
    {:ok, %{type: Map.fetch!(params, "action_type"), new_price_id: new_price_id, item_id: item_id, source_event_id: source_event && source_event.id}}
  else
    _ -> :error
  end
end

defp action_available?(_subscription, _action), do: false

defp reject_unavailable_action(socket) do
  socket
  |> assign(:drawer_action_type, nil)
  |> assign(:pending_action, nil)
  |> push_flash(:error, Copy.subscription_action_braintree_guidance())
end
```

**Related links pattern** (lines 1556-1606): preserve owner scope with `ScopedPath.build/4`; use one related strip only.

```elixir
defp related_items(subscription, mount_path, scope) do
  [
    %{icon: :users, label: "Customer", value: label, href: ScopedPath.build(mount_path, "/customers/#{subscription.customer_id}", scope)},
    %{icon: :invoices, label: "Invoices", href: ScopedPath.build(mount_path, "/invoices", scope, %{"subscription_id" => subscription.id})},
    %{icon: :events, label: "Events", href: ScopedPath.build(mount_path, "/events", scope, %{"subject_type" => "Subscription", "subject_id" => subscription.id})}
  ]
end
```

#### Per-file Notes

- `customer_live.ex`: keep link/patched subviews only for `subscriptions`, `invoices`, `payments`. Current broad tab list is at lines 33-35 and current More menu render is lines 245-280; replace it with summary/drill/lazy sections. Preserve payment method operations at lines 96-160 and move delete confirmation currently at lines 387-418 into drawer state.
- `invoice_live.ex`: preserve operation execution and audit code at lines 571-656. Replace current KPI-first and inline action forms at lines 232-323 with summary rows, primary actions, overflow groups, and `DetailDrawer`.
- `charge_live.ex`: preserve refund event flow at lines 51-97 and execution/audit code at lines 412-492. Move current refund form/confirm panel at lines 217-257 into `DetailDrawer`; leave only one visible `Refund charge` primary action.
- `coupon_live.ex`: copy read-only DETAIL structure from the shared pattern, but omit action band. Current KPI grid at lines 77-89 should become summary rows; current raw `JsonViewer` at line 119 should become lazy Raw data.
- `promotion_code_live.ex`: same as coupon. Current KPI grid at lines 73-85 should become summary rows; raw `JsonViewer` at lines 101-105 should become lazy Raw data.
- `connect_account_live.ex`: preserve override validation and audit helpers at lines 250-353. Move current always-visible form at lines 156-229 into `DetailDrawer`; add step-up around save unless planning records a lower-risk reason.
- `webhook_live.ex`: preserve scoped loader and replay audit flow at lines 30-88 and 340-353. Replace disabled replay button at lines 159-168 with omitted action plus state copy; move confirmation at lines 174-193 into drawer/step-up.
- `event_live.ex`: read-only. Add `Detail.summary_list`, wrap exactly one related strip, and add lazy Raw data only if payload/data exists. Keep related subject link mapping from lines 120-181.

### `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`

**Imports/data pattern** (lines 8-18, 27-67): Recovery owns its window params and assembles analytics assigns directly.

```elixir
alias Accrue.Analytics.Dunning
alias AccrueAdmin.Copy

alias AccrueAdmin.Components.{
  AppShell,
  AtRiskTable,
  Breadcrumbs,
  FunnelChart,
  KpiCard,
  WindowSelector
}

def handle_params(params, uri, socket) do
  window = parse_window(params["window"])
  {since, until} = window_bounds(window)

  stats = Dunning.recovered_vs_lost_mrr(since: since, until: until)
  funnel = Dunning.funnel(since: since, until: until)
  at_risk = Dunning.at_risk_subscriptions(since: since, until: until)

  {:noreply,
   socket
   |> assign(:window, window)
   |> assign(:window_selector_base_path, window_selector_base_path(uri))
   |> assign(:funnel, funnel)
   |> assign(:kpi_pairs, kpi_pairs)
   |> assign(:at_risk, at_risk)}
end
```

**Core render order** (lines 100-154): keep orientation/window selector, hero metric pair, at-risk work queue, then funnel. Do not apply Dashboard zone order to Recovery.

```elixir
<header class="ax-page-header">
  <h1 class="ax-display"><%= Copy.recovery_index_heading() %></h1>
  <p class="ax-body ax-page-copy"><%= Copy.recovery_index_subtitle() %></p>
  <WindowSelector.window_selector current_window={@window} base_path={@window_selector_base_path} />
</header>

<%= for kpi <- @kpi_pairs do %>
  <section class="ax-kpi-grid ax-section-gap" data-ax-zone="kpi-cluster">
    ...
  </section>
<% end %>

<section data-ax-zone="task-launcher">
  <AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />
</section>

<FunnelChart.funnel_chart entered={@funnel.entered} recovered={@funnel.recovered} exhausted={@funnel.exhausted} active={@funnel.active} />
```

**Window/query pattern** (lines 160-197): preserve valid windows and unrelated query params.

```elixir
defp parse_window(w) when w in ["7d", "30d", "90d"], do: w
defp parse_window(_), do: "30d"

defp window_selector_base_path(uri) do
  parsed = URI.parse(uri)

  query =
    parsed.query
    |> decode_query()
    |> Map.delete("window")
    |> URI.encode_query()

  case query do
    "" -> parsed.path
    _ -> parsed.path <> "?" <> query
  end
end
```

### `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex`

**Core detail drill pattern** (lines 10-20, 34-48): Campaign is a drill-down detail page, not an overview dashboard.

```elixir
def mount(%{"id" => subscription_id}, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  arcs = Dunning.campaign_timeline_grouped(subscription_id)
  invoice_map = Dunning.invoices_for_campaign(subscription_id)

  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:subscription_id, subscription_id)
   |> assign(:arcs, arcs)
   |> assign(:invoice_map, invoice_map)}
end
```

```elixir
<section class="ax-page" aria-label="Dunning timeline for subscription">
  <Breadcrumbs.breadcrumbs items={[...]} />

  <Detail.summary_card eyebrow="Campaign history" title="Dunning Timeline">
    <:facts>
      <span>{@subscription_id}</span>
    </:facts>
  </Detail.summary_card>

  <CampaignTimeline.campaign_timeline arcs={@arcs} invoice_map={@invoice_map} />
</section>
```

### `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` (component, transform)

**Analog:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex`

**Doc fix target** (lines 1-6): update stale doc copy that says the table renders below the funnel. Runtime component shape remains valid.

```elixir
defmodule AccrueAdmin.Components.AtRiskTable do
  @moduledoc """
  Table of subscriptions currently in an active dunning campaign.

  Renders below the Recovery Funnel on `/billing/analytics/recovery`.
```

**Core component pattern** (lines 39-47, 63-89, 122-128): preserve state-based table/card rendering and campaign detail links.

```elixir
def at_risk_table(assigns) do
  assigns = assign(assigns, :state, state(assigns))

  ~H"""
  <section class={["ax-card", "ax-at-risk-table", @class]} data-component-group="table-empty-loading-error-pagination" data-state={@state}>
```

```elixir
<a href={@base_path <> "/analytics/recovery/subscriptions/" <> row.subscription_id} class="ax-link">
  {row.customer_label || "-"}
</a>

<a href={subscription_href(@base_path, row)} class="ax-button ax-button-secondary" aria-label={"Open recovery campaign for #{row.customer_label || row.subscription_id}"}>
  Review campaign
</a>
```

### ExUnit LiveView Tests

**Primary analog:** `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`

Apply this pattern to:

- `customer_live_test.exs`
- `invoice_live_test.exs`
- `charge_live_test.exs`
- `coupon_live_test.exs`
- `promotion_code_live_test.exs`
- `connect_account_live_test.exs`
- `webhook_live_test.exs`
- `event_live_test.exs`

**Imports/setup pattern** (lines 1-14, 50-78): use `AccrueAdmin.LiveCase`, fixtures/factory aliases, and `init_test_session`.

```elixir
defmodule AccrueAdmin.SubscriptionLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias Accrue.Events
  alias Accrue.Repo
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.TestRepo

  import Ecto.Query
```

**DETAIL contract assertion pattern** (lines 80-105): each target detail test should assert structural markers and absence of initial forms/KPI grids.

```elixir
assert page_wrapper_count(html) == 1
assert heading_count(html, "h1") == 1

assert data_attr_count(html, "data-ax-summary-list") == 1
assert data_attr_count(html, "data-ax-action-band") == 1
assert data_attr_count(html, "data-ax-primary-action") <= 2
assert data_attr_count(html, "data-ax-related-resources") == 1
assert data_attr_count(html, "data-ax-lazy-activity") == 1
assert data_attr_count(html, "data-ax-lazy-json") == 1

refute has_element?(view, "[data-ax-action-band] form")
refute has_element?(view, "[data-role='confirm-panel']")
refute html =~ ~s(class="ax-kpi-grid")
```

For read-only pages, omit action-band assertions and assert no action band or no visible primary actions, depending on final markup.

**Drawer/step-up interaction pattern** (lines 179-240): use rendered drawer mirrors for LiveViewTest and assert audit linkage for sensitive operations.

```elixir
render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

assert has_element?(
         view,
         "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
       )

html =
  render_submit(
    element(view, "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"),
    %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
  )

assert html =~ "Confirm action"

html = render_click(element(view, "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='confirm-action']"))
assert html =~ "Step-up required"

html = render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})
assert html =~ Copy.subscription_action_recorded_info()
```

**Malformed action rejection pattern** (lines 404-450): keep server-side action allowlists tested against crafted payloads.

```elixir
for params <- malformed_payloads do
  html = render_submit(view, "prepare_action", params)

  refute html =~ "Confirm action"
  refute html =~ ~s(data-role="confirm-action")
  refute html =~ ~s(data-ax-action-drawer-form)
end
```

**Test helper pattern** (lines 734-769): copy these helpers into target tests if not already present.

```elixir
defp data_attr_count(html, attr) do
  attr
  |> Regex.escape()
  |> then(&Regex.compile!("\\b" <> &1 <> "(?:\\s|=|>)"))
  |> Regex.scan(html)
  |> length()
end

defp heading_count(html, tag) do
  tag
  |> Regex.escape()
  |> then(&Regex.compile!("<" <> &1 <> "\\b"))
  |> Regex.scan(html)
  |> length()
end
```

### Analytics Tests

**Recovery analog:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`

**Window test pattern** (lines 176-218): preserve `handle_params` and query-param behavior.

```elixir
test "?window=7d renders 7d button as active", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=7d")
  assert active_window_label(html) =~ "7 days"
end

test "window links preserve unrelated query params on the live route", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?owner=platform&window=30d")

  assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=7d/
end
```

**At-risk queue test pattern** (lines 231-257): assert work queue exists and links to Campaign drill-down.

```elixir
test "renders At-Risk Subscriptions section on recovery dashboard", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

  assert html =~ "At-Risk Subscriptions"
  assert html =~ "No active dunning campaigns" or html =~ "active dunning campaigns in this window"
end

test "at-risk table row links to per-subscription drill-down route", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

  assert html =~ "/analytics/recovery/subscriptions/" or html =~ "No active dunning campaigns"
end
```

**Campaign analog:** `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs`

**Campaign detail test pattern** (lines 66-75, 115-119, 171-177): assert summary-card detail shape and timeline content.

```elixir
{:ok, _view, html} =
  conn
  |> init_test_session(%{"admin_token" => "admin", "accrue_admin" => %{"mount_path" => "/billing"}})
  |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

assert html =~ "Campaign History" || html =~ "Dunning Timeline"
assert html =~ "Campaign started"
assert html =~ "ax-summary-card"
assert html =~ "ax-summary-title"
```

### Playwright: `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`

**Analog:** `accrue_admin/e2e/admin-spec-detail-phase195.spec.js`

**Imports/helper pattern** (lines 8-19): use the same Playwright and Phase 191 helper scaffold.

```javascript
const { test, expect } = require("@playwright/test");

const {
  assertFocusWithin,
  assertTopPointerTarget,
  setPhase191Theme,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });
```

**Initial DETAIL invariant helper** (lines 131-149): adapt to all target pages; parameterize expected action/related/lazy counts per page.

```javascript
async function assertInitialDetailInvariants(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);

  const actionBand = page.locator("[data-ax-action-band]");
  await expect(actionBand.locator("form:visible"), `${label}: no action-band forms`).toHaveCount(0);
  await expect(page.locator("[data-ax-action-drawer-form]:visible"), `${label}: no drawer forms on load`).toHaveCount(0);

  const primaryActions = page.locator("[data-ax-primary-action]");
  expect(await primaryActions.count(), `${label}: DETAIL pages may expose at most two primary actions`).toBeLessThanOrEqual(2);

  await expect(page.locator("[data-ax-related-resources]"), `${label}: one related strip`).toHaveCount(1);
  await expect(page.locator("[data-ax-summary-list]"), `${label}: summary list`).toHaveCount(1);
}
```

**Drawer browser behavior pattern** (lines 64-129, 174-207): use Playwright for portal geometry, focus, pointer target, inert shell, scroll lock, Escape, and backdrop.

```javascript
const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
await expect(drawer).toBeVisible();
await expect(page.locator("#accrue-admin-shell")).toHaveAttribute("inert", "");

await assertDrawerGeometry(page, drawer);
await assertDrawerInteractive(page, drawer);
await assertBodyScrollStable(page, "Escape close flow");

await page.keyboard.press("Escape");
await expect(drawer).toBeHidden();
await expect(page.locator("#accrue-admin-shell")).not.toHaveAttribute("inert", "");
```

### Playwright: `accrue_admin/e2e/admin-spec-overview-phase194.spec.js`

**Analog:** `accrue_admin/e2e/admin-spec-overview-phase194.spec.js`

**Recovery-specific assertion pattern** (lines 158-202): keep Dashboard order checks separate; Recovery should assert hero pair before task-launcher before funnel, not `attention-rail -> task-launcher -> kpi-cluster`.

```javascript
test("Recovery: one h1, at-risk table DOM index < funnel chart DOM index (D-01)", async ({
  page,
  request,
}) => {
  await reset(request);
  await seedScenario(request, "phase191-matrix");
  await login(page, "/billing/analytics/recovery");

  await expect(page.locator("h1")).toHaveCount(1);

  const order = await page.evaluate(() => {
    const taskLauncher = document.querySelector("[data-ax-zone='task-launcher']");
    if (!taskLauncher) return { taskLauncherIndex: -1, funnelIndex: -1 };

    const parent = taskLauncher.parentElement;
    const children = [...parent.children];
    const taskLauncherIndex = children.indexOf(taskLauncher);
    let funnelIndex = -1;

    for (let i = taskLauncherIndex + 1; i < children.length; i++) {
      if (!children[i].hasAttribute("data-ax-zone")) {
        funnelIndex = i;
        break;
      }
    }

    return { taskLauncherIndex, funnelIndex };
  });

  expect(order.funnelIndex).toBeGreaterThan(order.taskLauncherIndex);
});
```

### `accrue_admin/package.json` (config, batch)

**Analog:** `accrue_admin/package.json`

**Script pattern** (lines 8-12): add `e2e:phase198` with same `env -u NO_COLOR`, timeout, and single-worker shape.

```json
"e2e:phase194": "env -u NO_COLOR playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1",
"e2e:phase195": "env -u NO_COLOR playwright test e2e/admin-spec-detail-phase195.spec.js --timeout=60000 --workers=1",
"e2e:phase196": "env -u NO_COLOR playwright test e2e/admin-spec-list-phase196.spec.js --timeout=60000 --workers=1",
"e2e:phase197": "env -u NO_COLOR playwright test e2e/admin-spec-list-phase197.spec.js --timeout=60000 --workers=1"
```

### Copy Modules

**Primary analogs:** `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/accrue_admin/copy/invoice.ex`

Apply to:

- `accrue_admin/lib/accrue_admin/copy.ex`
- `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `accrue_admin/lib/accrue_admin/copy/coupon.ex`
- `accrue_admin/lib/accrue_admin/copy/promotion_code.ex`
- `accrue_admin/lib/accrue_admin/copy/connect.ex`
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex`
- `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex`
- `accrue_admin/lib/accrue_admin/copy/locked.ex`

Existing Dunning copy is reused unchanged in Phase 198. Recovery and Campaign work keeps Dunning analytics data calls explicit in the analytics LiveViews, but no Phase 198 plan modifies `accrue_admin/lib/accrue_admin/copy/dunning.ex`.

**Facade pattern** (copy.ex lines 9-17, 129-186): alias resource modules and expose stable `defdelegate`s from `AccrueAdmin.Copy`.

```elixir
alias AccrueAdmin.Copy.BillingEvent
alias AccrueAdmin.Copy.Connect
alias AccrueAdmin.Copy.Coupon
alias AccrueAdmin.Copy.CustomerPaymentMethods
alias AccrueAdmin.Copy.Dunning
alias AccrueAdmin.Copy.Entitlements
alias AccrueAdmin.Copy.Invoice
alias AccrueAdmin.Copy.PromotionCode
alias AccrueAdmin.Copy.Subscription
```

```elixir
defdelegate invoice_detail_eyebrow(), to: Invoice
defdelegate invoice_actions_heading(), to: Invoice
defdelegate invoice_action_finalize(), to: Invoice
defdelegate invoice_action_manual_pay(), to: Invoice
defdelegate invoice_action_void(), to: Invoice
defdelegate invoice_confirm_workflow_message(action_label, source_suffix), to: Invoice
defdelegate invoice_line_items_heading(), to: Invoice
defdelegate invoice_timeline_heading(), to: Invoice
```

**Module string pattern** (`copy/subscription.ex` lines 1-29): group by page/surface comments and use zero-arity functions for labels.

```elixir
defmodule AccrueAdmin.Copy.Subscription do
  @moduledoc false

  # Subscription detail (SubscriptionLive) - Phase 50, ADM-04

  def subscription_breadcrumb_subscriptions, do: "Subscriptions"
  def subscription_detail_eyebrow, do: "Subscription detail"
  def subscription_action_cancel_now, do: "Cancel immediately"
  def subscription_action_cancel_at_period_end, do: "Cancel renewal"
  def subscription_action_resume, do: "Resume"
  def subscription_action_swap_plan, do: "Change plan"
end
```

**Parameterized copy pattern** (`copy/subscription.ex` lines 65-72; `copy.ex` lines 732-738): build confirmation copy from explicit opts, not inline LiveView strings.

```elixir
def subscription_confirm_workflow_message(action_type, opts) do
  subscription_id = Keyword.get(opts, :subscription_id, "this subscription")
  customer_id = Keyword.get(opts, :customer_id, "this customer")
  source_event_id = Keyword.get(opts, :source_event_id)
  source = source_suffix(source_event_id)

  "#{subscription_action_label(action_type)} #{subscription_id}: This will #{subscription_billing_effect(action_type)} for customer #{customer_id} and record an admin audit row.#{source} Continue?"
end
```

```elixir
def charge_refund_confirm_message(opts) do
  charge_id = option(opts, :charge_id, "this charge")
  amount = option(opts, :amount, "the selected amount")
  audit_subject = option(opts, :audit_subject, "a refund ledger row")

  "Refund charge #{charge_id}: This will create a #{amount} refund, record #{audit_subject}, and record an admin audit row. Continue?"
end
```

**Locked replay copy pattern** (`copy/locked.ex` lines 6-29): keep cross-surface replay/security strings in `Copy.Locked`.

```elixir
def ambiguous_replay_blocked,
  do:
    "Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."

def replay_blocked,
  do:
    "Replay is blocked because this webhook isn't linked to a billable row in the active organization."

def single_replay_confirmation(webhook_id, opts) do
  owner_scope = opts |> Keyword.get(:owner_scope, "the active organization") |> to_string()

  "Replay webhook #{webhook_id} for #{owner_scope}: This will requeue the webhook delivery and record an admin audit event. Continue?"
end
```

## Shared Patterns

### Auth And Owner Scope

**Source:** `accrue_admin/lib/accrue_admin/router.ex` lines 68-95 and `accrue_admin/lib/accrue_admin/auth_hook.ex` lines 11-28
**Apply to:** all target LiveViews

```elixir
live_session :accrue_admin,
  root_layout: {AccrueAdmin.Layouts, :root},
  on_mount: on_mount,
  session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do
  live("/customers/:id", AccrueAdmin.Live.CustomerLive, :show)
  live("/invoices/:id", AccrueAdmin.Live.InvoiceLive, :show)
  live("/payments/:id", AccrueAdmin.Live.ChargeLive, :show)
  live("/analytics/recovery", RecoveryLive, :index)
  live("/analytics/recovery/subscriptions/:id", CampaignLive, :show)
end
```

```elixir
def on_mount(:ensure_admin, params, session, socket) do
  case OwnerScope.resolve(session, params) do
    {:ok, owner_scope} ->
      user = owner_scope.current_admin

      {:cont,
       socket
       |> assign(:accrue_admin_session, session)
       |> assign(:current_admin, user)
       |> assign(:current_owner_scope, owner_scope)
       |> assign(:step_up_pending, false)
       |> assign(:step_up_challenge, nil)
       |> assign(:step_up_error, nil)}
  end
end
```

### DETAIL Components

**Source:** `accrue_admin/lib/accrue_admin/components/detail.ex` lines 70-127
**Apply to:** all detail and Campaign pages

```elixir
attr(:rows, :list, required: true)
attr(:class, :any, default: nil)

def summary_list(assigns) do
  ~H"""
  <dl class={["ax-summary-list", @class]} data-ax-summary-list>
    <div :for={row <- @rows} class="ax-summary-list-row">
      <dt class="ax-summary-list-key"><%= row_value(row, :label) %></dt>
      <dd class="ax-summary-list-value"><%= row_value(row, :value) %></dd>
      <dd :if={row_action?(row)} class="ax-summary-list-actions">
        ...
      </dd>
    </div>
  </dl>
  """
end

attr(:eyebrow, :string, default: nil)
attr(:title, :string, required: true)
slot(:status)
slot(:facts)
slot(:actions)

def summary_card(assigns) do
  ~H"""
  <header class="ax-card ax-summary-card" data-component-group="detail-header-metadata-actions">
    <div class="ax-summary-main">
      <p :if={@eyebrow} class="ax-eyebrow"><%= @eyebrow %></p>
      <div class="ax-summary-title-row">
        <h1 class="ax-summary-title"><%= @title %></h1>
        <%= render_slot(@status) %>
      </div>
      <div :if={@facts != []} class="ax-summary-facts"><%= render_slot(@facts) %></div>
    </div>
    <div :if={@actions != []} class="ax-summary-actions"><%= render_slot(@actions) %></div>
  </header>
  """
end
```

### Action Overflow

**Source:** `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` lines 47-115
**Apply to:** detail pages with more than two valid actions

```elixir
attr(:label, :string, required: true)
attr(:groups, :list, default: [])
attr(:id, :string, default: nil)

def action_menu(assigns) do
  ~H"""
  <details id={@id} class="ax-dropdown ax-action-menu" data-component-group="detail-action-menu" data-ax-action-overflow-menu>
    <summary class="ax-button ax-button-secondary ax-dropdown-trigger ax-action-menu-trigger" aria-haspopup="menu">
      <span><%= @label %></span>
      <span aria-hidden="true">v</span>
    </summary>

    <div class="ax-dropdown-panel ax-action-menu-panel" role="menu" aria-label={@label}>
      <button :for={item <- group_items(group)} type="button" role="menuitem" phx-click={item_event(item)} phx-value-action_type={item_value(item)}>
        <span class="ax-dropdown-item-label"><%= item_label(item) %></span>
      </button>
    </div>
  </details>
  """
end
```

### Drawer And Step-Up

**Source:** `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` lines 10-55 and `accrue_admin/lib/accrue_admin/step_up.ex` lines 23-84
**Apply to:** invoice, charge, webhook, connect account, customer payment-method delete/default flows

```elixir
attr(:id, :string, default: "detail-drawer")
attr(:open, :boolean, default: false)
attr(:title, :string, required: true)
attr(:close_event, :string, default: nil)
slot(:inner_block, required: true)
slot(:footer)

def detail_drawer(assigns) do
  ~H"""
  <Overlay.overlay id={@id} open={@open} presentation={:drawer} title={@title} close_event={@focus_trap_close_event}>
    <%= render_slot(@inner_block) %>
    <:footer :if={@footer != []}>
      <%= render_slot(@footer) %>
    </:footer>
  </Overlay.overlay>
  """
end
```

```elixir
def require_fresh(socket, action, continuation, opts \\ [])
    when is_map(action) and is_function(continuation, 1) and is_list(opts) do
  user = socket.assigns[:current_admin]

  cond do
    fresh?(socket, opts) ->
      {:ok, continuation.(socket)}

    true ->
      challenge = Auth.step_up_challenge(user, action)
      {:challenge,
       socket
       |> assign(:step_up_pending, true)
       |> assign(:step_up_action, action)
       |> assign(:step_up_challenge, challenge)
       |> assign(:step_up_error, nil)
       |> assign(:step_up_continuation, continuation)}
  end
end

def verify(socket, params, opts \\ []) when is_map(params) and is_list(opts) do
  case Auth.verify_step_up(user, params, action) do
    :ok -> {:ok, continuation.(socket)}
    {:error, reason} -> {:error, reason, socket |> assign(:step_up_error, humanize_error(reason)) |> assign(:step_up_pending, true)}
  end
end
```

### Lazy Activity And Raw JSON

**Source:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex` lines 125-130, 624-633, 326-350; `components/timeline.ex` lines 10-45; `components/json_viewer.ex` lines 8-65
**Apply to:** customer, invoice, charge, coupon, promotion-code, webhook, event where data exists

```elixir
def handle_event("load_activity", _params, socket) do
  {:noreply, ensure_timeline_events(socket)}
end

def handle_event("load_raw_json", _params, socket) do
  {:noreply, assign(socket, :raw_json_loaded?, true)}
end

defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

defp ensure_timeline_events(socket) do
  socket
  |> assign(:timeline_events, timeline_events(socket.assigns.subscription.id))
  |> assign(:timeline_events_loaded?, true)
end
```

```elixir
attr(:items, :list, required: true)
attr(:label, :string, default: "Timeline")
attr(:empty_label, :string, default: "No events yet")

def timeline(assigns) do
  ~H"""
  <section class={["ax-timeline", @class]} aria-label={@label}>
    <ol :if={@items != []} class="ax-timeline-list">
      ...
    </ol>
    <p :if={@items == []} class="ax-body ax-timeline-empty"><%= @empty_label %></p>
  </section>
  """
end
```

```elixir
attr(:id, :string, required: true)
attr(:payload, :any, required: true)
attr(:active_tab, :string, default: "tree")
attr(:label, :string, default: "Payload")

def json_viewer(assigns) do
  normalized = normalize_payload(assigns.payload)
  raw_json = Jason.encode_to_iodata!(normalized, pretty: true) |> IO.iodata_to_binary()

  ~H"""
  <section id={@id} class="ax-card ax-json-viewer" aria-label={@label}>
    ...
  </section>
  """
end
```

### Related Resources

**Source:** `accrue_admin/lib/accrue_admin/components/related_resources.ex` lines 25-48 and subscription wrapper lines 322-324
**Apply to:** all target detail pages

```elixir
attr(:title, :string, default: "Related billing")
attr(:items, :list, required: true)

def related_resources(assigns) do
  ~H"""
  <section :if={@items != []} class="ax-card ax-related" aria-label={@title}>
    <ul class="ax-related-list">
      <li :for={item <- @items}>
        <a class="ax-related-item" href={item.href}>
          <span class="ax-related-label"><%= item.label %></span>
          <span :if={item[:value]} class="ax-related-value"><%= item.value %></span>
        </a>
      </li>
    </ul>
  </section>
  """
end
```

Planner instruction: either wrap each page's single strip as below or deliberately update the component contract and tests.

```elixir
<div data-ax-related-resources>
  <RelatedResources.related_resources items={@related_items} />
</div>
```

### Owner-Scoped Links

**Source:** `accrue_admin/lib/accrue_admin/scoped_path.ex` lines 7-27
**Apply to:** related links, summary-list row actions, customer peer tabs

```elixir
def build(mount_path, suffix, owner_scope, params \\ %{})

def build(mount_path, suffix, %OwnerScope{} = owner_scope, params) do
  build(mount_path, suffix, Map.from_struct(owner_scope), params)
end

def build(mount_path, suffix, %{mode: :organization, organization_slug: slug}, params)
    when is_binary(slug) do
  mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
end

def build(mount_path, suffix, _owner_scope, params) when map_size(params) > 0 do
  mount_path <> suffix <> "?" <> URI.encode_query(params)
end

def build(mount_path, suffix, _owner_scope, _params), do: mount_path <> suffix
```

## No Analog Found

None. The only new file, `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`, should copy the Phase 195 Playwright scaffold and broaden the route matrix.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/live`, `accrue_admin/lib/accrue_admin/components`, `accrue_admin/lib/accrue_admin/copy`, `accrue_admin/test/accrue_admin/live`, `accrue_admin/test/accrue_admin/components`, `accrue_admin/e2e`, `accrue_admin/package.json`
**Files scanned:** 135
**Pattern extraction date:** 2026-06-28
