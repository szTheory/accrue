# Phase 197: Propagate LIST - Pattern Map

**Mapped:** 2026-06-27
**Files analyzed:** 29
**Analogs found:** 29 / 29

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/charges_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/coupons_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | component (LiveView) | request-response + event-driven | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` + current `webhooks_live.ex` bulk pattern | exact |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` + current `events_live.ex` lens pattern | exact |
| `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` | component (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/webhooks.ex` | service | CRUD + transform | `accrue_admin/lib/accrue_admin/queries/invoices.ex` | role-match |
| `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex` | service | CRUD + transform | current `connect_accounts.ex` + `invoices.ex` scope/decode shape | role-match |
| `accrue_admin/lib/accrue_admin/queries/charges.ex` | service | CRUD | `accrue_admin/lib/accrue_admin/queries/invoices.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy.ex` delegate sections | exact |
| `accrue_admin/lib/accrue_admin/copy/invoice.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/coupon.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/promotion_code.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/connect.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/lib/accrue_admin/copy/billing_event.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | role-match |
| `accrue_admin/test/accrue_admin/live/customers_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/invoices_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/charges_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/coupons_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` | test | request-response + event-driven | `subscriptions_live_test.exs` + current `webhooks_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/events_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs` | test | request-response | `subscriptions_live_test.exs` + current `connect_accounts_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/queries/query_modules_test.exs` | test | CRUD + transform | current `query_modules_test.exs` | exact |
| `accrue_admin/test/support/list_contracts.ex` | test utility | transform | `accrue_admin/test/support/live_case.ex` + `subscriptions_live_test.exs` tables | role-match |
| `accrue_admin/e2e/admin-spec-list-phase197.spec.js` | test | request-response | `accrue_admin/e2e/admin-spec-list-phase196.spec.js` | exact |
| `accrue_admin/package.json` | config | batch | current `e2e:phase196` script | exact |

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/live/customers_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Copy the common LIST composition from Subscriptions. Keep the current customer row/cell semantics from `customers_live.ex` lines 116-145 and 188-221, but move chrome to `PageHeader`, put `DataTable.filter_toolbar` in the header slot, pass `render_filter_toolbar={false}`, and add `FilterChipBar` in `:list_status`.

Customer-specific pattern sources:
- Current URL-backed filter event: `customers_live.ex` lines 61-69.
- Current owner-scope table path: `customers_live.ex` lines 22-41.
- Current customer columns/cards/filter fields: `customers_live.ex` lines 109-145.
- Current customer identity cell: `customers_live.ex` lines 186-221.

### `accrue_admin/lib/accrue_admin/live/invoices_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Copy Subscriptions' default lens and clear-all shape. Preserve invoice columns and money/status cells from `invoices_live.ex` lines 106-151 and 185-224. Replace current string-appended default patch and chip links from `invoices_live.ex` lines 44-51 and 259-284 with `DataTableNav.merge_query/2`.

### `accrue_admin/lib/accrue_admin/live/charges_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Use the same pattern as Invoices, but keep route/UI language as Payments. Preserve current `/payments` table path from `charges_live.ex` lines 21-26 and row links from lines 180-186. Do not introduce `/charges` UI copy. Replace current queue chip links at lines 248-269 with merge-query clear-all links.

### `accrue_admin/lib/accrue_admin/live/coupons_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Add default `valid=true` handling with the Subscriptions default-patch shape. Preserve coupon-specific stat strip, promotion-code cross-link, columns, and filters from `coupons_live.ex` lines 53-127. Add `FilterChipBar` as the visible "Valid coupons" / "All" surface in the `DataTable` `:list_status` slot.

### `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Add default `active=true` handling with the Subscriptions default-patch shape. Preserve code/coupon/status/redemption/expiry table semantics from `promotion_codes_live.ex` lines 82-127 and 174-210. Add chips/count/clear-all through `FilterChipBar`.

### `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` (component, request-response + event-driven)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Use Subscriptions for LIST structure and keep the current Webhooks bulk replay event flow. Preserve:
- Parent message from DataTable bulk action: `webhooks_live.ex` lines 50-57.
- Filter patch event: `webhooks_live.ex` lines 59-67.
- Confirmation and replay side effect: `webhooks_live.ex` lines 73-99.
- Scope guard before replay: `webhooks_live.ex` lines 110-118.
- Current selectable DataTable config: `webhooks_live.ex` lines 186-236.

### `accrue_admin/lib/accrue_admin/live/events_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Use Subscriptions for `PageHeader`/`DataTable`/`FilterChipBar` placement, but preserve Events as an all-ledger default rather than a narrowed queue. Current compliance chip behavior is a partial analog at `events_live.ex` lines 167-190, but replace `append_query/2` at lines 192-194 with `DataTableNav.merge_query/2` so `org` survives.

### `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

Add default `needs_attention=true` handling using the Subscriptions default-patch shape. Preserve current readiness columns and filter controls from `connect_accounts_live.ex` lines 82-164 and readiness/status helpers from lines 215-253. Add "Needs attention" / "All" chips through `FilterChipBar`.

### Common LiveView LIST Excerpts To Copy

**Imports pattern** from `subscriptions_live.ex` lines 4-23:

```elixir
use Phoenix.LiveView

import Ecto.Query

alias Accrue.Billing.{Query, Subscription}
alias Accrue.Repo
alias AccrueAdmin.BillingPresentation

alias AccrueAdmin.Components.{
  AppShell,
  DataTable,
  FilterChipBar,
  FlashGroup,
  PageHeader,
  StatStrip
}

alias AccrueAdmin.Components.StatusBadge
alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Subscriptions
```

**URL-backed filter event** from `subscriptions_live.ex` lines 54-62:

```elixir
@impl true
def handle_event("data_table_filter", params, socket) do
  {:noreply,
   AccrueAdmin.DataTableNav.patch_with_filters(
     socket,
     socket.assigns.table_path,
     Map.drop(params, ["_target", "_csrf_token"])
   )}
end
```

**Default lens canonicalization** from `subscriptions_live.ex` lines 64-82:

```elixir
@impl true
def handle_params(%{"view" => "all"} = params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end

def handle_params(params, _uri, socket) do
  if map_size(params) == 0 or map_only_scope?(params) do
    default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
    to = AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, default)

    if connected?(socket) do
      {:noreply, push_patch(socket, to: to)}
    else
      {:noreply, assign(socket, :params, default)}
    end
  else
    {:noreply, assign(socket, :params, params)}
  end
end
```

**PageHeader + filter-toolbar slot** from `subscriptions_live.ex` lines 96-130:

```elixir
<PageHeader.page_header
  breadcrumbs={[
    %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
    %{label: "Subscriptions"}
  ]}
  title={Copy.subscriptions_index_heading()}
>
  <:description>
    <p class="ax-body"><%= Copy.subscriptions_index_subtitle() %></p>
  </:description>

  <:stat_strip>
    <StatStrip.stat_strip label="Subscription summary">
      <:stat label="Active" value={Integer.to_string(@summary.active_count)} />
    </StatStrip.stat_strip>
  </:stat_strip>

  <:filter_toolbar>
    <DataTable.filter_toolbar
      id="subscriptions"
      filter_fields={subscription_filter_fields()}
      filter_params={filter_params(@params)}
      path={@table_path}
      clear_href={clear_all_href(@params, @table_path)}
      clear_visible={filter_active?(@params)}
    />
  </:filter_toolbar>
</PageHeader.page_header>
```

**DataTable with caller-positioned toolbar and chip slot** from `subscriptions_live.ex` lines 134-185:

```elixir
<.live_component
  module={DataTable}
  id="subscriptions"
  query_module={Subscriptions}
  current_owner_scope={@current_owner_scope}
  path={@table_path}
  params={@params}
  list_id="subscriptions"
  list_state={list_state(@params, @summary)}
  empty_reason={empty_reason(@params, @summary)}
  loading_fixture={phase196_loading_fixture?(@params)}
  loading_label={Copy.subscriptions_list_loading_label()}
  render_filter_toolbar={false}
  clear_href={clear_all_href(@params, @table_path)}
>
  <:list_status :let={status}>
    <FilterChipBar.filter_chip_bar
      items={work_queue_chips(@params, @table_path)}
      label="Work queue"
      result_count={status.visible_count}
      result_label={{"subscription", "subscriptions"}}
      clear_all_href={active_clear_all_href(@params, @table_path)}
      clear_all_label={Copy.data_table_clear_filters_label()}
    />
  </:list_status>
</.live_component>
```

**Chip construction pattern** from `subscriptions_live.ex` lines 338-374:

```elixir
defp work_queue_chips(params, table_path) do
  queue_active = Map.get(params, "status") == @default_queue_status
  all_active = Map.get(params, "view") == "all"
  clear_href = clear_all_href(params, table_path)

  filter_chips =
    params
    |> filter_params()
    |> Enum.reject(fn {key, _value} -> key == "status" and queue_active end)
    |> Enum.map(fn {key, value} ->
      %{
        id: String.to_atom(key),
        label: filter_chip_label(key),
        value: filter_chip_value(key, value),
        tone: :slate,
        active: true,
        remove_href: AccrueAdmin.DataTableNav.merge_query(table_path, %{key => nil})
      }
    end)

  [
    %{id: :status_queue, label: "At risk", tone: :cobalt, active: queue_active, remove_href: if(queue_active, do: clear_href, else: nil)},
    %{id: :view_all, label: "All", tone: :slate, active: queue_active or all_active, href: if(queue_active, do: clear_href, else: nil)}
  ] ++ filter_chips
end
```

**Clear-all and state helpers** from `subscriptions_live.ex` lines 384-420 and 424-452:

```elixir
defp clear_all_href(_params, table_path) do
  AccrueAdmin.DataTableNav.merge_query(table_path, %{
    "view" => "all",
    "q" => nil,
    "status" => nil,
    "customer_id" => nil,
    "cursor" => nil,
    "phase196_state" => nil
  })
end

defp active_clear_all_href(params, table_path) do
  if filter_active?(params), do: clear_all_href(params, table_path)
end

defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
     when is_binary(slug) do
  %{"status" => status, "org" => slug}
end

defp queue_active?(params),
  do: Map.get(params, "status") == @default_queue_status and Map.get(params, "view") != "all"

defp phase196_loading_fixture?(params) do
  Application.get_env(:accrue_admin, :env) == :test and
    Map.get(params, "phase196_state") == "loading-skeleton"
end
```

### `accrue_admin/lib/accrue_admin/queries/webhooks.ex` (service, CRUD + transform)

**Analog:** `accrue_admin/lib/accrue_admin/queries/invoices.ex`

Use Invoices' allowlisted comma-status pattern, but return atoms/list atoms because `Webhooks.filter_query/2` already supports a status list.

**Current Webhooks decode/encode and list-status support** from `webhooks.ex` lines 52-70 and 144-180:

```elixir
def decode_filter(params) when is_map(params) do
  %{
    type: Behaviour.normalize_string(Map.get(params, "type") || Map.get(params, :type)),
    status: decode_status(Map.get(params, "status") || Map.get(params, :status)),
    livemode: Behaviour.parse_boolean(Map.get(params, "livemode") || Map.get(params, :livemode))
  }
  |> Behaviour.compact_filter()
end

defp filter_query(query, filter) do
  Enum.reduce(filter, query, fn
    {:status, statuses}, query when is_list(statuses) ->
      where(query, [event], event.status in ^statuses)

    {:status, status}, query ->
      where(query, [event], event.status == ^status)
  end)
end

defp decode_status(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> nil
    status -> String.to_existing_atom(status)
  end
end
```

**Allowlisted comma-status analog** from `invoices.ex` lines 137-160:

```elixir
@valid_invoice_statuses ~w(draft open paid uncollectible void)

defp filter_status(query, status) when is_binary(status) do
  values =
    status
    |> String.split(",", trim: true)
    |> Enum.filter(&(&1 in @valid_invoice_statuses))

  case values do
    [] ->
      query

    [single] ->
      where(query, [invoice, _customer], invoice.status == ^String.to_existing_atom(single))

    multiple ->
      atoms = Enum.map(multiple, &String.to_existing_atom/1)
      where(query, [invoice, _customer], invoice.status in ^atoms)
  end
end
```

### `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex` (service, CRUD + transform)

**Analog:** current `connect_accounts.ex`; partial gap is the OR lens.

Current filters are AND-reduced. Add `needs_attention` decode and one OR predicate instead of combining existing booleans.

**Current decode/filter shape** from `connect_accounts.ex` lines 57-80 and 82-116:

```elixir
def decode_filter(params) when is_map(params) do
  %{
    q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
    type: Behaviour.normalize_string(Map.get(params, "type") || Map.get(params, :type)),
    charges_enabled:
      Behaviour.parse_boolean(
        Map.get(params, "charges_enabled") || Map.get(params, :charges_enabled)
      ),
    deauthorized:
      Behaviour.parse_boolean(Map.get(params, "deauthorized") || Map.get(params, :deauthorized))
  }
  |> Behaviour.compact_filter()
end

defp filter_query(query, filter) do
  Enum.reduce(filter, query, fn
    {:charges_enabled, value}, query ->
      where(query, [account], account.charges_enabled == ^value)

    {:details_submitted, value}, query ->
      where(query, [account], account.details_submitted == ^value)

    {:deauthorized, true}, query ->
      where(query, [account], not is_nil(account.deauthorized_at))
  end)
end
```

### `accrue_admin/lib/accrue_admin/queries/charges.ex` (service, CRUD)

**Analog:** `accrue_admin/lib/accrue_admin/queries/invoices.ex`

If implementation adds Payments owner-scope support, copy Invoices' `owner_scope` threading and `scope_query/2`. Current Charges ignores `owner_scope`.

**Invoices owner-scope query pattern** from `invoices.ex` lines 18-27 and 162-171:

```elixir
def list(opts \\ []) do
  filter = Keyword.get(opts, :filter, %{})
  limit = Behaviour.normalize_limit(opts)
  cursor = Behaviour.decode_cursor(opts)
  owner_scope = Keyword.get(opts, :owner_scope)

  Invoice
  |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
  |> scope_query(owner_scope)
  |> filter_query(filter)
end

defp scope_query(query, nil), do: query
defp scope_query(query, %OwnerScope{mode: :global}), do: query

defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
  where(
    query,
    [_invoice, customer],
    customer.owner_type == "Organization" and customer.owner_id == ^organization_id
  )
end
```

### Copy Files (utility, transform)

**Analogs:** `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/accrue_admin/copy.ex`

Apply to:
- `accrue_admin/lib/accrue_admin/copy.ex`
- `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `accrue_admin/lib/accrue_admin/copy/coupon.ex`
- `accrue_admin/lib/accrue_admin/copy/promotion_code.ex`
- `accrue_admin/lib/accrue_admin/copy/connect.ex`
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex`

For pages without a resource copy module today, keep existing `AccrueAdmin.Copy` functions unless the planner chooses to split a narrow module. If splitting, copy the module shape from `copy/subscription.ex` and add defdelegates in `copy.ex`.

**Resource copy module pattern** from `copy/subscription.ex` lines 78-95:

```elixir
def subscriptions_list_first_run_empty_title, do: "No subscriptions yet."

def subscriptions_list_first_run_empty_body,
  do: "Subscriptions appear after a customer completes checkout."

def subscriptions_list_queue_empty_title, do: "Nothing at risk."

def subscriptions_list_queue_empty_body,
  do: "No past-due or canceling subscriptions. View All to see every subscription."

def subscriptions_list_filtered_empty_title, do: "No subscriptions match these filters."

def subscriptions_list_filtered_empty_body,
  do: "Clear filters or adjust the search to see subscriptions."

def subscriptions_list_loading_label, do: "Loading subscriptions."
```

**Central alias/delegate pattern** from `copy.ex` lines 9-17 and 52-60:

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

defdelegate subscription_page_title(), to: Subscription
defdelegate subscriptions_list_first_run_empty_title(), to: Subscription
defdelegate subscriptions_list_first_run_empty_body(), to: Subscription
defdelegate subscriptions_list_queue_empty_title(), to: Subscription
defdelegate subscriptions_list_queue_empty_body(), to: Subscription
defdelegate subscriptions_list_filtered_empty_title(), to: Subscription
defdelegate subscriptions_list_filtered_empty_body(), to: Subscription
defdelegate subscriptions_list_loading_label(), to: Subscription
```

### LiveView Tests (test, request-response)

**Analog:** `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`

Apply to all eight target LiveView tests:
- `customers_live_test.exs`
- `invoices_live_test.exs`
- `charges_live_test.exs`
- `coupons_live_test.exs`
- `promotion_codes_live_test.exs`
- `webhooks_live_test.exs`
- `events_live_test.exs`
- `connect_accounts_live_test.exs`

**PageHeader contract test** from `subscriptions_live_test.exs` lines 78-94:

```elixir
test "renders Subscriptions through PageHeader with exactly one h1", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/subscriptions?view=all")

  assert html =~ ~s(data-ax-page-header)
  assert html =~ ~s(data-ax-page-title)
  assert html =~ ~s(data-component-group="page-header-actions-breadcrumbs")
  assert html =~ ~s(data-ax-page-filter-toolbar)
  refute html =~ ~s(data-ax-page-actions)
  assert_one_h1(html)

  assert html
         |> Floki.parse_document!()
         |> Floki.find(~s([data-role="filter-form"]))
         |> length() == 1
end
```

**Default lens and owner-scope clear-all tests** from `subscriptions_live_test.exs` lines 96-129:

```elixir
test "bare subscriptions route represents the default At risk queue without first-run flash", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/subscriptions")

  assert html =~ ~s(data-ax-filter-chips)
  assert html =~ "At risk"
  assert html =~ "All"
  assert html =~ ~s(data-ax-state="filtered-empty") or html =~ ~s(data-ax-state="populated")
  refute html =~ "No subscriptions yet."
end

test "default queue chip clears to view all while preserving organization scope", %{conn: conn} do
  assert {:ok, _view, html} =
           live(conn, "/billing/subscriptions?org=allowed-org&status=past_due,canceling")

  assert html =~ ~s(data-ax-clear-all)
  assert html =~ ~s(href="/billing/subscriptions?org=allowed-org&amp;view=all")
  assert html =~ "At risk"
  assert html =~ "All"
end
```

**Four-state and loading fixture test** from `subscriptions_live_test.exs` lines 143-215:

```elixir
test "distinguishes populated, first-run-empty, filtered-empty, queue-empty, and loading states", %{conn: conn} do
  assert {:ok, _view, populated_html} = live(populated_conn, "/billing/subscriptions?view=all")
  assert populated_html =~ ~s(data-ax-list="subscriptions")
  assert populated_html =~ ~s(data-ax-state="populated")

  assert first_run_html =~ ~s(data-ax-state="first-run-empty")
  assert first_run_html =~ ~s(data-ax-empty-reason="first-run")
  refute first_run_html =~ ~s(data-ax-clear-all)

  assert filtered_html =~ ~s(data-ax-state="filtered-empty")
  assert filtered_html =~ ~s(data-ax-empty-reason="filter")
  assert filtered_html =~ ~s(data-ax-clear-all)

  assert queue_html =~ ~s(data-ax-state="filtered-empty")
  assert queue_html =~ ~s(data-ax-empty-reason="queue")

  assert loading_html =~ ~s(data-ax-state="loading-skeleton")
  assert loading_html =~ ~s(aria-busy="true")
  assert loading_html =~ Copy.subscriptions_list_loading_label()
end
```

**SPA filter patch test** from `subscriptions_live_test.exs` lines 258-274:

```elixir
test "submitting the shared filter form push_patches the table path with filter params", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, view, _html} = live(conn, "/billing/subscriptions?view=all")

  view
  |> form(~s([data-role="filter-form"]), %{"q" => "acme"})
  |> render_submit()

  to = assert_patch(view)
  assert to =~ "/billing/subscriptions"
  assert to =~ "q=acme"
end
```

### `accrue_admin/test/accrue_admin/queries/query_modules_test.exs` (test, CRUD + transform)

**Analog:** current `query_modules_test.exs`

Add Webhooks multi-status decode/list coverage and Connect `needs_attention` OR lens coverage next to existing query module tests.

**Existing multi-status pattern** from `query_modules_test.exs` lines 234-300:

```elixir
describe "multi-status filter handling" do
  test "Invoices.decode_filter/1 passes comma-separated status through unchanged" do
    filter = Invoices.decode_filter(%{"status" => "open,uncollectible"})
    assert filter.status == "open,uncollectible"
  end

  test "Invoices.list/1 with multi-status returns matching rows (open present in setup)" do
    {rows, _cursor} =
      Invoices.list(filter: Invoices.decode_filter(%{"status" => "open,uncollectible"}))

    assert Enum.any?(rows, &(&1.status == :open))
    refute Enum.any?(rows, &(&1.status == :draft))
  end

  test "Charges.list/1 with multi-value status returns matching rows" do
    {rows, _cursor} =
      Charges.list(filter: Charges.decode_filter(%{"status" => "pending,succeeded"}))

    statuses = Enum.map(rows, & &1.status)
    assert "pending" in statuses
    assert "succeeded" in statuses
  end
end
```

**Existing Connect boolean filter test** from `query_modules_test.exs` lines 227-232:

```elixir
test "connect account queries filter by onboarding booleans" do
  {rows, _cursor} =
    ConnectAccounts.list(filter: ConnectAccounts.decode_filter(%{"charges_enabled" => "true"}))

  assert [%{stripe_account_id: "acct_new", payouts_enabled: true}] = rows
end
```

### `accrue_admin/test/support/list_contracts.ex` (test utility, transform)

**Analog:** `accrue_admin/test/support/live_case.ex` and `subscriptions_live_test.exs`

If the planner creates the test-only LIST contract manifest, keep it under `test/support`, with no runtime dependency. Use plain module functions or attributes, not macros or generated runtime page behavior.

**Test support module style** from `live_case.ex` lines 25-56:

```elixir
defmodule AccrueAdmin.LiveCase do
  @moduledoc """
  ExUnit case template for future admin LiveView tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.LiveViewTest
      import Plug.Conn
      import Phoenix.ConnTest

      @endpoint AccrueAdmin.TestEndpoint
    end
  end

  setup _tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(AccrueAdmin.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

### `accrue_admin/e2e/admin-spec-list-phase197.spec.js` (test, request-response)

**Analog:** `accrue_admin/e2e/admin-spec-list-phase196.spec.js`

Copy the helper style and selector contract, then table-drive all eight target routes. Use representative deeper cases for reference default, status queue, bulk-action queue, ledger lens, and Connect OR lens.

**Imports and helpers** from `admin-spec-list-phase196.spec.js` lines 8-31:

```javascript
const { test, expect } = require("@playwright/test");

const {
  setPhase191Theme,
  assertNoHorizontalClip,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}
```

**PageHeader selector contract** from `admin-spec-list-phase196.spec.js` lines 37-46:

```javascript
async function assertPageHeaderContract(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);
  await expect(page.locator("[data-ax-page-header]"), `${label}: PageHeader marker`).toBeVisible();
  await expect(page.locator("[data-ax-page-title]"), `${label}: title marker`).toBeVisible();
  await expect(
    page.locator('[data-component-group="page-header-actions-breadcrumbs"]'),
    `${label}: component group marker`
  ).toBeVisible();
  await expect(page.locator("[data-ax-page-filter-toolbar]"), `${label}: filter toolbar slot`).toBeVisible();
}
```

**Desktop, default queue, state, and mobile examples** from `admin-spec-list-phase196.spec.js` lines 72-128, 130-195, and 197-221:

```javascript
await assertPageHeaderContract(page, `${theme} desktop`);
await expect(page.locator("[data-ax-filter-chips]"), `${theme}: chip row`).toBeVisible();
await expect(page.locator("[data-ax-result-count]"), `${theme}: result count`).toContainText(
  /Showing \d+ subscriptions?/
);
await assertNoHorizontalClip(page, "#main-content, main, [data-ax-list='subscriptions']", `${theme} desktop`);

await expect(page, "bare route should patch to the default queue").toHaveURL(
  /\/billing\/subscriptions\?status=past_due%2Ccanceling$/
);

await expect(list, contract.name).toHaveAttribute("data-ax-state", contract.state);
await expect(list, contract.name).toHaveAttribute("data-ax-empty-reason", contract.reason);

await page.setViewportSize({ width: 375, height: 844 });
await expect(page.locator("[data-role='card-list']").first(), `${theme}: mobile cards`).toBeVisible();
await assertNoHorizontalClip(page, "#main-content, main, [data-role='card-list']", `${theme} mobile`);
```

### `accrue_admin/package.json` (config, batch)

**Analog:** current Phase 196 e2e script

Add a sibling `e2e:phase197` script matching the existing phase script convention.

**Script pattern** from `package.json` lines 4-13:

```json
"scripts": {
  "e2e": "env -u NO_COLOR playwright test",
  "e2e:phase191": "env -u NO_COLOR playwright test e2e/admin-page-flow-phase191.spec.js --timeout=60000 --workers=1",
  "e2e:phase194": "env -u NO_COLOR playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1",
  "e2e:phase195": "env -u NO_COLOR playwright test e2e/admin-spec-detail-phase195.spec.js --timeout=60000 --workers=1",
  "e2e:phase196": "env -u NO_COLOR playwright test e2e/admin-spec-list-phase196.spec.js --timeout=60000 --workers=1",
  "e2e:a11y": "env -u NO_COLOR playwright test e2e/admin-a11y.spec.js",
  "e2e:install": "playwright install chromium"
}
```

## Shared Patterns

### Authentication And Route Boundary

**Source:** `accrue_admin/lib/accrue_admin/router.ex` lines 68-90 and `accrue_admin/lib/accrue_admin/auth_hook.ex` lines 11-28

**Apply to:** all target LiveViews and LiveView tests.

```elixir
live_session :accrue_admin,
  root_layout: {AccrueAdmin.Layouts, :root},
  on_mount: on_mount,
  session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do
  live("/customers", AccrueAdmin.Live.CustomersLive, :index)
  live("/invoices", AccrueAdmin.Live.InvoicesLive, :index)
  live("/payments", AccrueAdmin.Live.ChargesLive, :index)
  live("/coupons", AccrueAdmin.Live.CouponsLive, :index)
  live("/promotion-codes", AccrueAdmin.Live.PromotionCodesLive, :index)
  live("/connect", AccrueAdmin.Live.ConnectAccountsLive, :index)
  live("/events", AccrueAdmin.Live.EventsLive, :index)
  live("/webhooks", AccrueAdmin.Live.WebhooksLive, :index)
end

def on_mount(:ensure_admin, params, session, socket) do
  case OwnerScope.resolve(session, params) do
    {:ok, owner_scope} ->
      user = owner_scope.current_admin

      {:cont,
       socket
       |> assign(:accrue_admin_session, session)
       |> assign(:current_admin, user)
       |> assign(:current_owner_scope, owner_scope)
       |> assign(:active_organization_name, OwnerScope.active_organization_banner_name(owner_scope))}
  end
end
```

### PageHeader Component Contract

**Source:** `accrue_admin/lib/accrue_admin/components/page_header.ex` lines 14-56

**Apply to:** all target LiveViews.

```elixir
attr(:breadcrumbs, :list, required: true)
attr(:title, :string, required: true)
slot(:description)
slot(:stat_strip)
slot(:actions)
slot(:filter_toolbar)

def page_header(assigns) do
  ~H"""
  <header
    class={["ax-page-header", @class]}
    data-ax-page-header
    data-component-group={@component_group}
    {@rest}
  >
    <Breadcrumbs.breadcrumbs items={@breadcrumbs} />
    <h1 id={@heading_id} class="ax-display" data-ax-page-title><%= @title %></h1>
    <div :if={@filter_toolbar != []} class="ax-page-header-filter-toolbar" data-ax-page-filter-toolbar>
      <%= render_slot(@filter_toolbar) %>
    </div>
  </header>
  """
end
```

### DataTable Contract

**Source:** `accrue_admin/lib/accrue_admin/components/data_table.ex` lines 235-284, 466-535, and 644-657

**Apply to:** all target LiveViews.

```elixir
slot(:list_status)

<section
  id={@id}
  class="ax-data-table"
  data-role="data-table"
  data-component-group="table-empty-loading-error-pagination"
  data-ax-list={@list_id}
  data-ax-state={@list_state}
  data-ax-empty-reason={empty_reason_marker(@list_state, @empty_reason)}
  aria-busy={@render_loading_fixture && "true"}
>
  <header :if={@render_filter_toolbar} class="ax-data-table-header">
    <.filter_toolbar ... />
  </header>

  <div :if={@list_status != []} class="ax-data-table-list-status" data-role="list-status">
    <%= render_slot(@list_status, %{visible_count: length(@rows), list_state: @list_state}) %>
  </div>
</section>

def filter_toolbar(assigns) do
  ~H"""
  <form phx-change="data_table_filter" phx-submit="data_table_filter" class="ax-data-table-filters" data-role="filter-form">
    <button type="submit" class="ax-visually-hidden" data-phase191-focus="filter-submit" tabindex="-1">
      <%= @filter_submit_label %>
    </button>
    <.link :if={@clear_visible} patch={@clear_href} class="ax-button ax-button-ghost ax-data-table-filter-clear" data-role="clear-filters">
      <%= Copy.data_table_clear_filters_label() %>
    </.link>
  </form>
  """
end

socket.assigns.query_module.list(
  query_opts(
    filter,
    cursor,
    socket.assigns.limit,
    Map.get(socket.assigns, :current_owner_scope)
  )
)
```

### FilterChipBar Contract

**Source:** `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` lines 8-18, 27-55, and 123-130

**Apply to:** all target LiveViews.

```elixir
attr(:items, :list, required: true)
attr(:label, :string, default: "Active filters")
attr(:result_count, :integer, default: nil)
attr(:result_label, :any, default: nil)
attr(:clear_all_href, :string, default: nil)
attr(:clear_all_label, :string, default: "Clear filters")

<section class={["ax-filter-chip-bar", @class]} aria-label={@label} data-phase191-focus="filter-chip-bar">
  <div :if={@has_items} class="ax-filter-chip-content">
    <div class="ax-filter-chip-list" data-ax-filter-chips>
      <.chip :for={item <- @active_items} item={item} />
    </div>

    <p :if={!is_nil(@result_count)} class="ax-body ax-filter-chip-count" data-ax-result-count>
      <%= result_count_label(@result_count, @result_label_pair) %>
    </p>
    <a :if={@clear_all_href} href={@clear_all_href} class="ax-filter-chip-clear-all" data-ax-clear-all>
      <%= @clear_all_label %>
    </a>
  </div>
</section>

defp result_count_label(1, {singular, _plural}), do: "Showing 1 #{singular}"
defp result_count_label(count, {_singular, plural}), do: "Showing #{count} #{plural}"
```

### Scope-Safe URL Mutation

**Source:** `accrue_admin/lib/accrue_admin/data_table_nav.ex` lines 35-59 and `accrue_admin/lib/accrue_admin/scoped_path.ex` lines 7-27

**Apply to:** all default, filter, chip, and clear-all hrefs.

```elixir
@spec merge_query(String.t(), map()) :: String.t()
def merge_query(path, params) when is_binary(path) and is_map(params) do
  uri = URI.parse(path)

  merged =
    (uri.query || "")
    |> URI.decode_query()
    |> Map.merge(stringify(params))
    |> Enum.reject(fn {_key, value} -> blank?(value) end)
    |> Map.new()

  query = if merged == %{}, do: nil, else: URI.encode_query(merged)

  %{uri | query: query} |> URI.to_string()
end

def build(mount_path, suffix, %{mode: :organization, organization_slug: slug}, params)
    when is_binary(slug) do
  mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
end
```

### Webhooks Bulk Replay Guard

**Source:** `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` lines 50-118 and `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` lines 134-217

**Apply to:** `webhooks_live.ex` migration and tests. Do not flatten this into generic list code.

```elixir
def handle_info({:data_table_bulk_action, "retry_selected", ids}, socket) do
  if ids == [] do
    {:noreply, push_flash(socket, :warning, Copy.webhooks_retry_no_selection_warning())}
  else
    {:noreply, assign(socket, :pending_bulk_replay, %{ids: ids, count: length(ids)})}
  end
end

def handle_event("confirm_retry_selected", _params, socket) do
  %{ids: ids, count: count} = socket.assigns.pending_bulk_replay

  case scope_selected_ids(socket.assigns.current_owner_scope, ids) do
    [] -> {:noreply, socket |> assign(:pending_bulk_replay, nil) |> push_flash(:warning, Copy.Locked.replay_blocked())}
    scoped_ids -> replay_scoped_rows(scoped_ids)
  end
end

defp scope_selected_ids(owner_scope, ids) do
  Enum.filter(ids, fn id ->
    match?({:ok, _}, Webhooks.detail(id, owner_scope))
  end)
end
```

## No Analog Found

No files lack a usable analog. The weakest match is the Connect `needs_attention=true` OR lens because no existing query module has that exact named OR predicate; use `connect_accounts.ex` for decode/filter structure and add one explicit OR clause in that file.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/live`, `components`, `queries`, `copy`, `test/accrue_admin/live`, `test/accrue_admin/components`, `test/accrue_admin/queries`, `test/support`, `e2e`, `package.json`.
**Files scanned:** 156
**Project instructions:** no `AGENTS.md` found; `CLAUDE.md` read; no project-local `.codex/skills` or `.agents/skills` found.
**Pattern extraction date:** 2026-06-27
