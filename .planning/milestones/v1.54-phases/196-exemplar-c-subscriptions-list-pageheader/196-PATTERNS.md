# Phase 196: Exemplar C - Subscriptions List + PageHeader - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 19 target or conditional files
**Analogs found:** 19 / 19

Project context: `AGENTS.md` is absent; local `.codex/skills/` and `.agents/skills/` are absent. `CLAUDE.md` and `accrue_admin/guides/admin_ui.md` keep this phase in `accrue_admin`, on Phoenix LiveView/function components, with custom `ax-*` CSS and committed admin bundles.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/components/page_header.ex` | component | request-response render | `Detail.summary_card/1`, `Breadcrumbs.breadcrumbs/1`, `StatStrip.stat_strip/1` | role-match |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | LiveView/controller | event-driven + request-response | same file plus `invoices_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | LiveComponent | CRUD + event-driven + request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | component | request-response navigation render | same file | exact |
| `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | query/model | CRUD + transform | same file | exact conditional |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | copy utility | transform | `copy/invoice.ex`, same module | role-match |
| `accrue_admin/lib/accrue_admin/copy.ex` | copy facade | transform | same file defdelegates | exact |
| `accrue_admin/assets/css/app.css` | CSS config | render transform | existing page/header/chip/table/skeleton CSS | exact |
| `accrue_admin/assets/css/theme.css` | token config | render transform | same file token map | exact conditional |
| `accrue_admin/priv/static/accrue_admin.css` | generated asset | batch/generated | `mix accrue_admin.assets.build` output | exact generated |
| `accrue_admin/priv/static/accrue_admin.js` | generated asset | batch/generated | `mix accrue_admin.assets.build` output | exact generated |
| `accrue_admin/test/accrue_admin/components/page_header_test.exs` | test | render assertions | `navigation_components_test.exs`, `display_components_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/components/data_table_test.exs` | test | LiveComponent event/render | same file | exact |
| `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs` | test | render assertions | same file | exact |
| `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` | test | LiveView request/event | same file plus `invoices_live_test.exs` | exact |
| `accrue_admin/e2e/admin-spec-list-phase196.spec.js` | test | Playwright page-flow | `admin-spec-detail-phase195.spec.js`, `admin-spec-overview-phase194.spec.js` | role-match |
| `accrue_admin/package.json` | config | batch/test command | existing phase e2e scripts | exact |
| `storybook/components/page_header.story.exs` | Storybook story | request-response dev render | `detail.story.exs`, `subscription_detail.story.exs` | role-match |
| `examples/accrue_host/e2e/generated/copy_strings.json` | generated fixture | batch/generated | `mix accrue_admin.export_copy_strings` output | exact conditional |

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/components/page_header.ex` (component, request-response render)

**Analog:** `accrue_admin/lib/accrue_admin/components/detail.ex`, `breadcrumbs.ex`, `stat_strip.ex`.

**Function component + slots pattern** (`detail.ex` lines 11-32):
```elixir
use Phoenix.Component

attr(:title, :string, required: true)
attr(:class, :any, default: nil)
slot(:actions)
slot(:inner_block, required: true)

def detail_section(assigns) do
  ~H"""
  <section class={["ax-detail-section", @class]}>
    <header class="ax-detail-section-head">
      <h3 class="ax-detail-section-title"><%= @title %></h3>
      <div :if={@actions != []} class="ax-detail-section-actions"><%= render_slot(@actions) %></div>
    </header>
    <%= render_slot(@inner_block) %>
  </section>
  """
end
```

**Breadcrumb composition** (`breadcrumbs.ex` lines 8-30):
```elixir
attr(:items, :list, required: true)

def breadcrumbs(assigns) do
  ~H"""
  <nav class="ax-breadcrumbs" aria-label="Breadcrumb">
    <ol class="ax-breadcrumbs-list">
      <li :for={{item, index} <- Enum.with_index(@items)} class="ax-breadcrumbs-item">
        <a :if={item[:href]} href={item[:href]} class="ax-breadcrumbs-link">
          <%= item[:label] %>
        </a>
        <span
          :if={!item[:href]}
          class="ax-breadcrumbs-current"
          aria-current={if(index == length(@items) - 1, do: "page", else: nil)}
        >
          <%= item[:label] %>
        </span>
      </li>
    </ol>
  </nav>
  """
end
```

**Slot content to support inside PageHeader** (`stat_strip.ex` lines 18-30):
```elixir
attr(:label, :string, required: true)
attr(:component_group, :string, default: nil)

slot :stat do
  attr(:label, :string)
  attr(:value, :string)
  attr(:tone, :string)
  attr(:href, :string)
end

def stat_strip(assigns) do
  ~H"""
```

**Implementation instruction:** create `AccrueAdmin.Components.PageHeader` as a stateless `Phoenix.Component`. Import/alias `Breadcrumbs`; declare attrs `:breadcrumbs`, `:title`, `:heading_id`, `:class`, `:component_group`, `:rest`; declare slots `:description`, `:stat_strip`, `:actions`, `:filter_toolbar`; render exactly one `<h1 class="ax-display" data-ax-page-title>`. PageHeader must not import `DataTableNav`, query modules, or path/filter helpers.

### `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` (LiveView/controller, event-driven + request-response)

**Analog:** same file; use `invoices_live.ex` for copy-backed list labels.

**Imports and current component composition** (`subscriptions_live.ex` lines 4-23):
```elixir
use Phoenix.LiveView

import Ecto.Query

alias Accrue.Billing.{Query, Subscription}
alias Accrue.Repo
alias AccrueAdmin.BillingPresentation

alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  DataTable,
  FilterChipBar,
  FlashGroup,
  StatStrip
}

alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Subscriptions
```

**Parent-owned filters stay in LiveView** (`subscriptions_live.ex` lines 53-60):
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

**Default queue first-paint risk to fix** (`subscriptions_live.ex` lines 63-80):
```elixir
def handle_params(%{"view" => "all"} = params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end

def handle_params(params, _uri, socket) when map_size(params) == 0 do
  if connected?(socket) do
    default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)

    {:noreply,
     push_patch(socket, to: socket.assigns.table_path <> "?" <> URI.encode_query(default))}
  else
    {:noreply, assign(socket, :params, params)}
  end
end
```

**Current page grammar to wrap with PageHeader** (`subscriptions_live.ex` lines 94-122):
```elixir
<section class="ax-page">
  <header class="ax-page-header">
    <Breadcrumbs.breadcrumbs
      items={[
        %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
        %{label: "Subscriptions"}
      ]}
    />
    <h1 class="ax-display"><%= Copy.subscriptions_index_heading() %></h1>
    <p class="ax-body ax-page-copy"><%= Copy.subscriptions_index_subtitle() %></p>
  </header>

  <FlashGroup.flash_group flashes={flash_messages(@flash)} />

  <StatStrip.stat_strip label="Subscription summary">
    ...
  </StatStrip.stat_strip>

  <FilterChipBar.filter_chip_bar
    items={work_queue_chips(@params, @table_path)}
    label="Work queue"
  />
```

**DataTable configuration to refine, not rebuild** (`subscriptions_live.ex` lines 124-168):
```elixir
<.live_component
  module={DataTable}
  id="subscriptions"
  query_module={Subscriptions}
  current_owner_scope={@current_owner_scope}
  path={@table_path}
  params={@params}
  columns={[
    %{
      label: "Subscription",
      render: &subscription_link(&1, @admin_mount_path, @current_owner_scope)
    },
    %{label: "Customer", render: &customer_link(&1, @admin_mount_path, @current_owner_scope)},
    %{label: "Billing signals", render: &billing_signals_cell/1},
    %{label: "Lifecycle", render: &lifecycle_summary/1},
    %{id: :current_period_end, label: "Current period end"}
  ]}
  card_title={&card_title/1}
  card_fields={[
    %{label: "Customer", render: &customer_label/1},
    %{label: "Billing signals", render: &billing_signals_cell/1},
    %{label: "Lifecycle", render: &lifecycle_summary/1},
    %{id: :current_period_end, label: "Current period end"}
  ]}
  ...
/>
```

**Safe HTML helper pattern for custom cell strings** (`subscriptions_live.ex` lines 209-237):
```elixir
defp billing_signals_cell(row) do
  ownership = BillingPresentation.ownership_label(row)
  tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
  escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  Phoenix.HTML.raw(
    ~s(<span class="ax-chip ax-label">#{escaped_o}</span> <span class="ax-chip ax-label">#{escaped_t}</span>)
  )
end

defp safe_link(href, label) do
  escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
end
```

**Work queue and scoped path pattern** (`subscriptions_live.ex` lines 268-321):
```elixir
defp work_queue_chips(params, table_path) do
  queue_active = Map.get(params, "status") == @default_queue_status
  all_active = Map.get(params, "view") == "all"

  [
    %{
      id: :status_queue,
      label: "Queue",
      value: "past due · canceling",
      tone: :cobalt,
      active: queue_active,
      remove_href: if(queue_active, do: table_path <> "?view=all", else: nil)
    },
    %{
      id: :view_all,
      label: "All",
      tone: :slate,
      active: queue_active or all_active,
      remove_href: if(all_active, do: table_path, else: nil)
    }
  ]
end

defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
     when is_binary(slug) do
  %{"status" => status, "org" => slug}
end

defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
     when is_binary(slug) do
  mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
end
```

**Implementation instruction:** replace inline header with `<PageHeader.page_header ...>` while keeping `AppShell` and `FlashGroup` outside. Move `StatStrip` and the filter toolbar through PageHeader slots, keep `FilterChipBar` below the header as the persistent chip/count/clear row, and update columns to identity -> state -> plan/amount -> renews/ends -> signals. Use `StatusBadge` for lifecycle status if possible.

### `accrue_admin/lib/accrue_admin/components/data_table.ex` (LiveComponent, CRUD/event-driven/request-response)

**Analog:** same file.

**Current state setup and empty resolution** (`data_table.ex` lines 14-35, 67-91):
```elixir
@impl true
def update(assigns, socket) do
  params = Map.get(assigns, :params, %{})
  params_signature = signature(params)
  action = Map.get(assigns, :action, :sync)

  socket =
    socket
    |> assign(assigns)
    |> assign(
      :filter_submit_label,
      Map.get(assigns, :filter_submit_label) || Copy.data_table_filter_submit_label()
    )
    |> assign(:table_caption, Map.get(assigns, :table_caption))
    |> assign_new(:selected_ids, fn -> MapSet.new() end)
    |> assign_new(:filter_fields, fn -> [] end)
    |> assign_new(:card_fields, fn -> [] end)
    |> assign_new(:empty_title, fn -> Copy.data_table_default_empty_title() end)
    |> assign_new(:empty_copy, fn -> Copy.data_table_default_empty_copy() end)

  socket = resolve_empty_state(socket)
  {:ok, maybe_schedule_poll(socket)}
end

defp resolve_empty_state(socket) do
  filtered? = any_filter_active?(socket.assigns[:filter_params] || %{})
  ...
end
```

**Filter form contract** (`data_table.ex` lines 171-214):
```elixir
<header class="ax-data-table-header">
  <form
    phx-change="data_table_filter"
    phx-submit="data_table_filter"
    class="ax-data-table-filters"
    data-role="filter-form"
    data-phase191-focus="filter-form"
  >
    <div
      :for={field <- @filter_fields}
      class={["ax-data-table-filter", filter_field_class(field)]}
    >
      <label for={field_id(@id, field)} class="ax-visually-hidden"><%= field_label(field) %></label>
      <.filter_input
        id={field_id(@id, field)}
        field={field}
        value={Map.get(@filter_params, field_param(field))}
        focus_key={field_param(field)}
      />
    </div>
    ...
    <.link
      :if={any_filter_active?(@filter_params)}
      patch={@path}
      class="ax-button ax-button-ghost ax-data-table-filter-clear"
      data-role="clear-filters"
      data-phase191-focus="clear-filters"
    >
      <%= Copy.data_table_clear_filters_label() %>
    </.link>
  </form>
</header>
```

**Empty/table/card/footer render pattern** (`data_table.ex` lines 236-351):
```elixir
<div :if={Enum.empty?(@rows)} class="ax-card ax-empty ax-data-table-empty" data-role="empty-state">
  <Icon.icon name={:inbox} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
  <p class="ax-empty-title"><%= @resolved_empty_title %></p>
  <p class="ax-body ax-empty-copy"><%= @resolved_empty_copy %></p>
  <.link
    :if={any_filter_active?(@filter_params)}
    patch={@path}
    class="ax-button ax-button-secondary"
    data-role="clear-filters"
    data-phase191-focus="clear-filters"
  >
    <%= Copy.data_table_clear_filters_label() %>
  </.link>
</div>

<div
  :if={!Enum.empty?(@rows)}
  class="ax-card ax-data-table-shell"
  phx-mounted={Phoenix.LiveView.JS.show(...)}
>
  <table class="ax-data-table-grid">
    ...
  </table>
</div>

<div :if={!Enum.empty?(@rows)} class="ax-data-table-cards" data-role="card-list">
  <article :for={row <- @rows} class="ax-card ax-data-table-card" data-row-id={row_identity(row, @row_id)}>
    ...
  </article>
</div>

<footer :if={!Enum.empty?(@rows)} class="ax-data-table-footer">
  <p class="ax-body" data-role="row-count"><%= Copy.data_table_row_count(length(@rows), @row_label) %></p>
```

**Query reload and cursor flow** (`data_table.ex` lines 480-505):
```elixir
defp reload(socket, params, opts) do
  filter = socket.assigns.query_module.decode_filter(params)
  filter_params = socket.assigns.query_module.encode_filter(filter) |> stringify_map()
  cursor = Map.get(params, "cursor") || Map.get(params, :cursor)

  {rows, next_cursor} =
    socket.assigns.query_module.list(
      query_opts(
        filter,
        cursor,
        socket.assigns.limit,
        Map.get(socket.assigns, :current_owner_scope)
      )
    )

  socket
  |> assign(:params_signature, Keyword.fetch!(opts, :params_signature))
  |> assign(:params, params)
  |> assign(:filter, filter)
  |> assign(:filter_params, filter_params)
  |> assign(:rows, rows)
  |> assign(:next_cursor, next_cursor)
end
```

**Implementation instruction:** add explicit list-state assigns/attrs without replacing existing `data-role` hooks. Target rendered root should gain markers like `data-ax-list={@list_id}` and `data-ax-state={@list_state}`. Do not use `any_filter_active?/1` alone for first-run vs queue vs filtered-empty. Add loading skeleton as a truthful fixture/dev/test state, not a fake production delay.

### `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` (component, request-response navigation render)

**Analog:** same file.

**Current attrs and active filtering** (`filter_chip_bar.ex` lines 6-31):
```elixir
use Phoenix.Component

attr(:items, :list, required: true)
attr(:label, :string, default: "Active filters")
attr(:empty_label, :string, default: "No filters applied")
attr(:class, :string, default: nil)

def filter_chip_bar(assigns) do
  assigns =
    assigns
    |> assign(:active_items, Enum.filter(assigns.items, &chip_active?/1))
    |> assign(:has_items, Enum.any?(assigns.items, &chip_active?/1))

  ~H"""
  <section class={["ax-filter-chip-bar", @class]} aria-label={@label} data-phase191-focus="filter-chip-bar">
    <header class="ax-filter-chip-header">
      <p class="ax-eyebrow">Filters</p>
      <p class="ax-body"><%= @label %></p>
    </header>

    <div :if={@has_items} class="ax-filter-chip-list">
      <.chip :for={item <- @active_items} item={item} />
    </div>
```

**Chip link pattern** (`filter_chip_bar.ex` lines 47-68):
```elixir
<span class={["ax-filter-chip", "ax-filter-chip-" <> @tone]} data-filter={Map.get(@item, :id)}>
  <a
    :if={@activation_href}
    href={@activation_href}
    class="ax-filter-chip-label ax-filter-chip-activation"
    data-phase191-focus="filter-chip-apply"
    aria-label={"Apply #{chip_accessible_label(@item)} filter"}
  ><%= @label_text %></a>
  <span :if={!@activation_href} class="ax-filter-chip-label"><%= @label_text %></span>
  <span :if={@value_text} class="ax-filter-chip-value"><%= @value_text %></span>
  <a
    :if={Map.get(@item, :remove_href)}
    href={Map.get(@item, :remove_href)}
    class="ax-filter-chip-action"
    data-phase191-focus="filter-chip-clear"
    aria-label={"Remove #{chip_accessible_label(@item)} filter"}
  >
    Clear
  </a>
</span>
```

**Implementation instruction:** extend this component or add a thin sibling wrapper to emit `data-ax-filter-chips`, `data-ax-result-count`, and `data-ax-clear-all`. Preserve existing `data-phase191-focus` anchors. Result count should be visible-row copy such as `Showing N subscriptions`, not an exact query total.

### `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` (query/model, CRUD + transform)

**Analog:** same file.

**Query select projection** (`queries/subscriptions.ex` lines 19-53):
```elixir
@impl true
def list(opts \\ []) do
  filter = Keyword.get(opts, :filter, %{})
  limit = Behaviour.normalize_limit(opts)
  cursor = Behaviour.decode_cursor(opts)
  owner_scope = Keyword.get(opts, :owner_scope)

  Subscription
  |> join(:inner, [subscription], customer in Customer,
    on: customer.id == subscription.customer_id
  )
  |> scope_query(owner_scope)
  |> filter_query(filter)
  |> Behaviour.apply_cursor(@time_field, cursor)
  |> order_by([subscription, _customer], desc: subscription.inserted_at, desc: subscription.id)
  |> limit(^Enum.max([limit + 1, 2]))
  |> select([subscription, customer], %{
    id: subscription.id,
    customer_id: subscription.customer_id,
    customer_name: customer.name,
    customer_email: customer.email,
    owner_type: customer.owner_type,
    owner_id: customer.owner_id,
    automatic_tax: subscription.automatic_tax,
    automatic_tax_disabled_reason: subscription.automatic_tax_disabled_reason,
    processor_id: subscription.processor_id,
    status: subscription.status,
    cancel_at_period_end: subscription.cancel_at_period_end,
    current_period_end: subscription.current_period_end,
    trial_end: subscription.trial_end,
    ended_at: subscription.ended_at,
    inserted_at: subscription.inserted_at
  })
  |> Repo.all()
  |> Behaviour.paginate(limit, @time_field)
end
```

**Filter decode and status handling** (`queries/subscriptions.ex` lines 89-126, 129-156):
```elixir
@impl true
def decode_filter(params) when is_map(params) do
  %{
    q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
    status: Behaviour.normalize_string(Map.get(params, "status") || Map.get(params, :status)),
    customer_id:
      Behaviour.normalize_string(
        Map.get(params, "customer_id") || Map.get(params, :customer_id)
      )
  }
  |> Behaviour.compact_filter()
end

defp filter_query(query, filter) do
  Enum.reduce(filter, query, fn
    {:q, term}, query ->
      pattern = "%#{term}%"
      where(query, [subscription, customer],
        ilike(customer.email, ^pattern) or
          ilike(customer.name, ^pattern) or
          ilike(subscription.processor_id, ^pattern)
      )

    {:status, status}, query ->
      filter_status(query, status)
```

**Owner scope pattern** (`queries/subscriptions.ex` lines 207-216):
```elixir
defp scope_query(query, nil), do: query
defp scope_query(query, %OwnerScope{mode: :global}), do: query

defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
  where(
    query,
    [_subscription, customer],
    customer.owner_type == "Organization" and customer.owner_id == ^organization_id
  )
end
```

**Implementation instruction:** only modify this file if the Subscriptions row needs honest plan/amount data available from local records or resolver-backed metadata. Do not widen scope just to fake money. Preserve `scope_query/2`, cursor pagination, and decode/encode filter contract.

### `accrue_admin/lib/accrue_admin/copy/subscription.ex` and `copy.ex` (copy utility/facade, transform)

**Analog:** `copy/invoice.ex` for list copy; `copy.ex` for facade delegates.

**Subscription copy module shape** (`copy/subscription.ex` lines 1-20):
```elixir
defmodule AccrueAdmin.Copy.Subscription do
  @moduledoc false

  # Subscription detail (SubscriptionLive) - Phase 50, ADM-04

  def subscription_breadcrumb_subscriptions, do: "Subscriptions"

  def subscription_detail_eyebrow, do: "Subscription detail"

  def subscription_kpi_section_aria_label, do: "Subscription lifecycle summary"

  def subscription_proration_create, do: "Create prorations"
  ...
  def subscription_kpi_status_label, do: "Status"
```

**List-copy analog with columns and filters** (`copy/invoice.ex` lines 18-58):
```elixir
def invoices_page_title_index, do: "Invoices"

def invoices_index_breadcrumb_invoices, do: "Invoices"

def invoices_index_eyebrow, do: "Invoices"

def invoices_index_headline, do: "Invoices"

def invoices_index_body,
  do:
    "Open and uncollectible invoices first - your collections queue. Switch status or search by customer to widen the view."

def invoices_kpi_section_aria_label, do: "Invoice summary"

def invoices_column_invoice, do: "Invoice"
def invoices_column_customer, do: "Customer"
def invoices_column_billing_signals, do: "Billing signals"
def invoices_column_status, do: "Status"
def invoices_column_balance, do: "Balance"
def invoices_column_collection, do: "Collection"

def invoices_filter_search, do: "Search"
def invoices_filter_status, do: "Status"
def invoices_filter_customer_id, do: "Customer id"
def invoices_filter_collection, do: "Collection"
```

**Facade pattern** (`copy.ex` lines 9-25 and 480-506):
```elixir
alias AccrueAdmin.Copy.Invoice
alias AccrueAdmin.Copy.Subscription

defdelegate subscription_breadcrumb_subscriptions(), to: Subscription
defdelegate subscription_detail_eyebrow(), to: Subscription
defdelegate subscription_kpi_section_aria_label(), to: Subscription
...

def data_table_row_count(count, {singular, plural}) do
  word = if count == 1, do: singular, else: plural
  "Showing #{count} #{word}"
end

def data_table_default_empty_title, do: "Nothing in this list yet"
def data_table_filter_submit_label, do: "Apply filters"
def data_table_clear_filters_label, do: "Clear filters"
```

**Implementation instruction:** move touched Subscriptions list/header/empty/loading strings through `AccrueAdmin.Copy.Subscription` and delegate through `AccrueAdmin.Copy` if called from LiveViews. Add export allowlist entries only for strings needed by browser anti-drift checks.

### `accrue_admin/assets/css/app.css` and `theme.css` (CSS/token config, render transform)

**Analog:** existing `ax-*` CSS blocks.

**Page header baseline** (`app.css` lines 2066-2073):
```css
.ax-page-header {
  display: grid;
  gap: var(--ax-space-sm);
  width: 100%;
  max-width: min(52rem, calc(100vw - 2.5rem));
  min-width: 0;
  box-sizing: border-box;
}
```

**Filter chip styling** (`app.css` lines 995-1013, 1059-1074):
```css
.ax-filter-chip-bar,
.ax-json-viewer,
.ax-detail-drawer,
.ax-timeline-card,
.ax-kpi-card {
  border: 1px solid var(--ax-border);
  background: var(--ax-elevated);
  min-width: 0;
}

.ax-filter-chip-list {
  flex-wrap: wrap;
}

.ax-filter-chip {
  display: inline-flex;
  align-items: center;
  gap: var(--ax-space-sm);
  padding: 0.5rem 0.875rem;
  border-radius: 999px;
  border: 1px solid var(--ax-border);
  font-size: 0.875rem;
  font-weight: 600;
  line-height: var(--ax-leading-normal);
}
```

**DataTable/card degradation pattern** (`app.css` lines 2363-2434):
```css
.ax-data-table-shell {
  display: none;
  overflow-x: auto;
}

.ax-data-table {
  display: flex;
  flex-direction: column;
  gap: var(--ax-space-lg);
}

.ax-data-table,
.ax-data-table-cards,
.ax-data-table-card,
.ax-data-table-card-header,
.ax-data-table-card-fields,
.ax-data-table-card-field,
.ax-data-table-filter,
.ax-data-table-selection,
.ax-data-table-footer {
  min-width: 0;
}

@media (min-width: 768px) { /* --ax-bp-md ↑ */
  .ax-data-table-shell {
    display: block;
  }

  .ax-data-table-cards {
    display: none;
  }
}
```

**Skeleton pattern** (`app.css` lines 3846-3869):
```css
.ax-skeleton {
  display: block;
  height: 0.875rem;
  border-radius: var(--ax-radius-2xs);
  background:
    linear-gradient(
      90deg,
      var(--ax-sunken) 25%,
      color-mix(in srgb, var(--ax-sunken) 60%, var(--ax-elevated)) 50%,
      var(--ax-sunken) 75%
    );
  background-size: 200% 100%;
  animation: ax-skeleton-shimmer 1.4s var(--ax-ease-inout) infinite;
}

@media (prefers-reduced-motion: reduce) {
  .ax-skeleton {
    animation: none;
    background: var(--ax-sunken);
```

**Token source of truth** (`theme.css` lines 25-40, 82-106):
```css
/* Spacing - 4px base, with a tight 2px rung for dense tables and a 64px layout rung */
--ax-space-2xs: 0.125rem; /* 2px */
--ax-space-xs: 0.25rem;   /* 4px */
--ax-space-sm: 0.5rem;    /* 8px */
--ax-space-md: 1rem;      /* 16px */
--ax-space-lg: 1.5rem;    /* 24px */
--ax-space-xl: 2rem;      /* 32px */
--ax-space-2xl: 3rem;     /* 48px */
--ax-space-3xl: 4rem;     /* 64px */

/* Composed typography roles - semantic bundles consumed by app.css utilities. */
--ax-type-body-font: 400 var(--ax-type-md)/var(--ax-leading-normal) var(--ax-font-sans);
--ax-type-label-font: 600 var(--ax-type-sm)/var(--ax-leading-normal) var(--ax-font-sans);
--ax-type-display-font: 600 var(--ax-type-3xl)/var(--ax-leading-tight) var(--ax-font-sans);
--ax-type-code-font: 400 var(--ax-type-sm)/var(--ax-leading-normal) var(--ax-font-mono);
```

**Implementation instruction:** prefer `app.css` class additions using existing tokens. Do not edit `theme.css` unless a genuinely missing semantic token is required. If source CSS changes, rebuild committed bundle with `cd accrue_admin && mix accrue_admin.assets.build`.

### Generated assets: `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js`

**Analog:** asset build task.

**Build task behavior** (`mix/tasks/accrue_admin.assets.build.ex` lines 3-14, 57-60, 63-83):
```elixir
@moduledoc """
Rebuilds the package-local CSS and JS bundle committed under `priv/static/`.

This task intentionally stays inside `accrue_admin/`:

  * reads source files from `assets/`
  * writes only `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js`
  * does not require host-app Tailwind or JS bootstrap changes

## Examples

    mix accrue_admin.assets.build
"""

run_step!(runner, "tailwind", "npx", tailwind_args(root), cd: root)
run_step!(runner, "esbuild", "npx", esbuild_args(root), cd: root)

Path.join(root, "assets/css/app.css")
Path.join(root, "priv/static/accrue_admin.css")
...
"--outfile=" <> Path.join(root, "priv/static/accrue_admin.js")
```

**Implementation instruction:** these are generated artifacts only. Do not hand-edit. Include them in implementation only when `mix accrue_admin.assets.build` changes them.

### Component tests: `page_header_test.exs`, `data_table_test.exs`, `filter_chip_bar_test.exs`

**Analog:** `navigation_components_test.exs`, `display_components_test.exs`, existing component tests.

**Component render assertion pattern** (`navigation_components_test.exs` lines 1-25):
```elixir
defmodule AccrueAdmin.NavigationComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.{Breadcrumbs, Button, FlashGroup, StatusBadge}

  describe "Breadcrumbs" do
    test "renders linked ancestors and current page" do
      html =
        render_component(&Breadcrumbs.breadcrumbs/1, %{
          items: [
            %{label: "Billing", href: "/billing"},
            %{label: "Invoices", href: "/billing/invoices"},
            %{label: "INV-0001"}
          ]
        })

      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(href="/billing")
      assert html =~ ~s(aria-current="page")
```

**DataTable isolated LiveView fixture** (`data_table_test.exs` lines 125-180):
```elixir
defmodule TableLive do
  use Phoenix.LiveView

  alias AccrueAdmin.Components.DataTable

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> Phoenix.Component.assign(:table_params, Map.get(session, "params", %{}))
     |> Phoenix.Component.assign(:path, "/admin/fixtures")
     |> Phoenix.Component.assign(:poll_interval_ms, Map.get(session, "poll_interval_ms", 5_000))
     |> Phoenix.Component.assign(:table_caption, Map.get(session, "table_caption"))
     |> Phoenix.Component.assign(:test_pid, Map.get(session, "test_pid"))}
  end

  @impl true
  def handle_event("data_table_filter", params, socket) do
    if pid = socket.assigns[:test_pid] do
      send(pid, {:data_table_filter_received, Map.drop(params, ["_target", "_csrf_token"])})
    end

    {:noreply, socket}
  end
end
```

**Existing state tests to extend** (`data_table_test.exs` lines 401-418):
```elixir
test "distinguishes true-empty from filtered-empty recovery actions", %{conn: conn} do
  FixtureStore.put_rows([])

  {:ok, _view, html} =
    live_isolated(conn, TableLive, session: %{"params" => %{}})

  assert html =~ "Nothing in this list yet"
  refute html =~ ~s(data-role="clear-filters")
  refute html =~ "No fixtures match these filters"

  {:ok, _view, html} =
    live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

  refute html =~ "Nothing in this list yet"
  assert html =~ "No fixtures match these filters"
  assert html =~ ~s(data-role="clear-filters")
  assert html =~ "Clear filters"
end
```

**FilterChipBar tests to extend** (`filter_chip_bar_test.exs` lines 10-20, 34-51):
```elixir
test "renders active chips with label and tone" do
  html =
    render_component(&FilterChipBar.filter_chip_bar/1,
      items: [%{id: :status, label: "Status", value: "open", tone: :cobalt, active: true}],
      label: "Filters"
    )

  assert html =~ "Status"
  assert html =~ "open"
  assert html =~ "ax-filter-chip-cobalt"
end

test "renders remove_href as Clear link when set" do
  html =
    render_component(&FilterChipBar.filter_chip_bar/1,
      items: [%{id: :status, label: "Status", tone: :cobalt, active: true, remove_href: "/invoices"}],
      label: "Filters"
    )

  assert html =~ ~s(href="/invoices")
  assert html =~ "Clear"
end
```

**Implementation instruction:** add a new `PageHeaderTest` instead of burying PageHeader under `navigation_components_test.exs`. Cover required attrs, every slot marker, custom `heading_id`, `:rest`, default component group, and exactly one `<h1>`. Extend DataTable tests for `data-ax-list`, four states, no fake production skeleton, skeleton a11y, and clear-all href override. Extend FilterChipBar tests for `data-ax-filter-chips`, `data-ax-result-count`, and `data-ax-clear-all`.

### `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` (test, LiveView request/event)

**Analog:** same file plus `invoices_live_test.exs`.

**Auth setup pattern** (`subscriptions_live_test.exs` lines 1-32):
```elixir
defmodule AccrueAdmin.SubscriptionsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil
    ...
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
```

**Existing Subscriptions assertions** (`subscriptions_live_test.exs` lines 45-76):
```elixir
test "filters subscription rows and renders lifecycle-safe links", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=canceling")

  assert html =~ Copy.subscriptions_index_heading()
  assert html =~ Copy.subscriptions_index_subtitle()
  assert html =~ "cancel at period end"
  assert html =~ "/billing/subscriptions/"
  assert html =~ "ax-chip ax-label"
end

test "bare navigation push_patches to default queue status past_due,canceling", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=past_due,canceling")

  assert html =~ "ax-filter-chip-cobalt"
  assert html =~ "ax-filter-chip-slate"
  assert html =~ "?view=all"
end
```

**Sibling `view=all` sentinel test to copy** (`invoices_live_test.exs` lines 90-99):
```elixir
test "view=all sentinel shows All chip active without redirect", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  # ?view=all must not redirect - the sentinel prevents a push_patch loop
  assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")

  # All chip is active (slate) - not the queue chip (cobalt)
  assert html =~ "ax-filter-chip-slate"
  refute html =~ "ax-filter-chip-cobalt"
end
```

**Implementation instruction:** add tests for PageHeader adoption (`data-ax-page-header`, one `h1`), bare disconnected render not showing first-run empty, At risk/All behavior, clear-all preserving `org` and routing to `view=all`, chip/count/clear markers, first-run vs queue vs filtered empty copy, loading fixture marker, and no primary raw ID column.

### `accrue_admin/e2e/admin-spec-list-phase196.spec.js` and `package.json` (Playwright page-flow + script)

**Analog:** Phase 195 and Phase 194 specs, plus shared Phase 191 helpers.

**Script pattern** (`package.json` lines 4-10):
```json
"scripts": {
  "e2e": "env -u NO_COLOR playwright test",
  "e2e:group-contracts": "env -u NO_COLOR playwright test e2e/admin-group-contracts.spec.js --timeout=60000 --workers=1",
  "e2e:phase191": "env -u NO_COLOR playwright test e2e/admin-page-flow-phase191.spec.js --timeout=60000 --workers=1",
  "e2e:phase194": "env -u NO_COLOR playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1",
  "e2e:phase195": "env -u NO_COLOR playwright test e2e/admin-spec-detail-phase195.spec.js --timeout=60000 --workers=1",
```

**Spec scaffold** (`admin-spec-detail-phase195.spec.js` lines 8-19, 27-41):
```javascript
const fs = require("fs");
const path = require("path");

const { test, expect } = require("@playwright/test");

const {
  assertFocusWithin,
  assertTopPointerTarget,
  setPhase191Theme,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario, { optional = false } = {}) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  if (optional && response.status() === 404) return {};
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}
```

**One-h1/theme assertion style** (`admin-spec-detail-phase195.spec.js` lines 131-147, 162-171):
```javascript
async function assertInitialDetailInvariants(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);
  ...
}

test("Subscription detail initial render holds SPEC-DETAIL structure in light and dark themes", async ({
  page,
  request,
}) => {
  await openSubscriptionDetail(page, request);

  for (const theme of ["light", "dark"]) {
    await setPhase191Theme(page, theme);
    await assertInitialDetailInvariants(page, theme);
  }
});
```

**Viewport/helper imports** (`admin-spec-overview-phase194.spec.js` lines 16-25; helpers lines 9-15, 119-130):
```javascript
const { test, expect } = require("@playwright/test");

const {
  PHASE191_VIEWPORTS,
  setPhase191Theme,
  assertFocusWithin,
  assertTopPointerTarget,
} = require("./phase191-page-flow-helpers.js");

const PHASE191_VIEWPORTS = Object.freeze([
  { name: "phone-320", width: 320, height: 844 },
  { name: "phone-375", width: 375, height: 844 },
  { name: "tablet-768", width: 768, height: 1024 },
  { name: "desktop-1024", width: 1024, height: 900 },
  { name: "desktop-1440", width: 1440, height: 1000 },
]);

async function setPhase191Theme(page, theme) {
  document.documentElement.setAttribute("data-theme", value);
  window.localStorage?.setItem("accrue_admin_theme", value);
}
```

**Implementation instruction:** add `e2e:phase196` pointing to `e2e/admin-spec-list-phase196.spec.js`. The spec should assert populated, first-run-empty, filtered-empty, queue-empty, and loading-skeleton selectors across desktop/mobile and light/dark where practical; verify `[data-ax-filter-chips]`, `[data-ax-result-count]`, `[data-ax-clear-all]`, exactly one h1, no horizontal clipping, and mobile card degradation.

### `storybook/components/page_header.story.exs` (Storybook story, request-response dev render)

**Analog:** `storybook/components/detail.story.exs` and `subscription_detail.story.exs`.

**Story module scaffold** (`detail.story.exs` lines 1-17, 43-58):
```elixir
defmodule AccrueAdmin.Storybook.Components.Detail do
  @moduledoc """
  Storybook coverage for Phase 195 detail summary-list rows.
  """

  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias AccrueAdmin.Components.Detail
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.summary_list_story/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Components.Detail) do
      [
        %Variation{id: :read_only, description: "Read-only summary rows", attributes: %{state: :read_only}}
      ]
    else
      []
    end
  end

  def summary_list_story(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:state, fn -> :read_only end)
      |> Phoenix.Component.assign(:rows, rows(assigns[:state] || :read_only))

    ~H"""
    <section class="ax-card ax-stack-md">
      ...
    </section>
    """
  end
```

**Composite component story pattern** (`subscription_detail.story.exs` lines 6-19, 50-61):
```elixir
use PhoenixStorybook.Story, :component
use Phoenix.Component

alias AccrueAdmin.Components.Detail
alias AccrueAdmin.Components.DropdownMenu
alias AccrueAdmin.Components.RelatedResources
alias AccrueAdmin.Components.StatusBadge
alias PhoenixStorybook.Stories.Variation

def variations do
  if Code.ensure_loaded?(AccrueAdmin.Components.Detail) and
       Code.ensure_loaded?(AccrueAdmin.Components.DropdownMenu) do
    [
      %Variation{
        id: :populated,
        description: "Populated Subscription detail exemplar",
        attributes: %{state: :populated}
      }
    ]
  else
    []
  end
end

~H"""
<section class="ax-page ax-stack-xl" data-story-subscription-detail={@state}>
  <Detail.summary_card eyebrow="Subscription detail" title="sub_storybook_phase195">
    <:status><StatusBadge.status_badge status={status_for(@state)} /></:status>
```

**Implementation instruction:** create focused `PageHeader` story only. Include variations for default, with actions, with stat strip, with filter toolbar, and long breadcrumbs/title. Keep Storybook dev/test-only and guarded with `Code.ensure_loaded?`.

### `examples/accrue_host/e2e/generated/copy_strings.json` (generated fixture, batch)

**Analog:** copy export task and Phase 195 fixture test.

**Export task allowlist/output pattern** (`mix/tasks/accrue_admin.export_copy_strings.ex` lines 4-10, 18-24, 112-125):
```elixir
@moduledoc """
Writes UTF-8 JSON `{"function_name" => "returned string"}` for a fixed allowlist of
0-arity `AccrueAdmin.Copy` functions (including `defdelegate` targets).

## Example

    mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json
"""

@allowlist ~w(
  subscription_drill_related_card_title
  subscription_drill_related_region_aria_label
  subscription_drill_link_customer
  subscription_drill_link_invoices_for_customer
  subscription_drill_link_charges_for_customer
  subscription_drill_link_events_index
  ...
)a

Mix.Task.run("compile")
exports = AccrueAdmin.Copy.__info__(:functions)

map =
  for name <- @allowlist,
      {^name, 0} <- exports,
      into: %{} do
    {Atom.to_string(name), apply(AccrueAdmin.Copy, name, [])}
  end

File.mkdir_p!(Path.dirname(out_path))
File.write!(out_path, Jason.encode!(map) <> "\n")
```

**Fixture anti-drift test shape** (`subscription_live_test.exs` lines 479-517):
```elixir
test "copy fixture exposes all drawer action labels for browser anti-drift checks" do
  fixture = copy_fixture()

  expected = %{
    "subscription_action_swap_plan" => Copy.subscription_action_swap_plan(),
    "subscription_action_cancel_at_period_end" =>
      Copy.subscription_action_cancel_at_period_end(),
    "subscription_action_cancel_now" => Copy.subscription_action_cancel_now(),
    ...
  }

  assert Map.take(fixture, Map.keys(expected)) == expected
end
```

**Implementation instruction:** regenerate this fixture only if new/changed copy is added to the export allowlist or browser anti-drift checks use it. Do not hand-edit JSON.

## Shared Patterns

### Stateless Phoenix Components

**Source:** `Detail`, `Breadcrumbs`, `StatStrip`, `StatusBadge`.
**Apply to:** `PageHeader`, Storybook story, component tests.

Use `use Phoenix.Component`, compile-time `attr`/`slot`, `render_slot/1`, and stable `data-*` markers. Function components render structure only. PageHeader must compose `Breadcrumbs` and slots; it must not own LiveView state or resource behavior.

### Server-Owned URL Filters

**Source:** `DataTable`, `DataTableNav`, `SubscriptionsLive`.
**Apply to:** `SubscriptionsLive`, DataTable filter-toolbar extraction, clear-all behavior.

`DataTable` renders parent-targeted filter forms with no `phx-target`; list LiveViews handle `"data_table_filter"` and call `AccrueAdmin.DataTableNav.patch_with_filters/3`. `DataTableNav.merge_query/2` preserves existing `org` query params and drops blanks (lines 46-58):
```elixir
uri = URI.parse(path)

merged =
  (uri.query || "")
  |> URI.decode_query()
  |> Map.merge(stringify(params))
  |> Enum.reject(fn {_key, value} -> blank?(value) end)
  |> Map.new()

query = if merged == %{}, do: nil, else: URI.encode_query(merged)

%{uri | query: query} |> URI.to_string()
```

For Subscriptions, clear-all/default-queue removal must route to `view=all`, not blank `/subscriptions`, and must preserve owner scope.

### LIST State Markers

**Source:** `accrue_admin/guides/spec-list.md`, `DataTable`.
**Apply to:** `DataTable`, `SubscriptionsLive`, Playwright.

SPEC-LIST requires four distinct states and chips/count/clear together (lines 31-32):
```markdown
| **Renders 4 distinct states with distinct copy strings.** A list page must handle:
(1) populated with data rows, (2) first-run empty, (3) filtered-empty, (4) loading skeleton ...
| **Filter chips, result count, and clear-all are all present when a filter is active.**
```

Add stable markers without removing existing hooks:
- `data-ax-list="subscriptions"`
- `data-ax-state="populated"`
- `data-ax-state="first-run-empty"`
- `data-ax-state="filtered-empty"`
- `data-ax-state="loading-skeleton"`
- `data-ax-empty-reason="first-run|filter|queue"`

### Copy Ownership

**Source:** `AccrueAdmin.Copy`, `AccrueAdmin.Copy.Subscription`, `AccrueAdmin.Copy.Invoice`.
**Apply to:** Subscriptions copy, PageHeader text, empty/loading/error labels.

New operator strings should live in copy modules, not inline in HEEx helpers. If copy is consumed through `AccrueAdmin.Copy`, add a `defdelegate`. If browser anti-drift uses it, add to the export allowlist and regenerate the JSON fixture.

### Style And Bundle Discipline

**Source:** `app.css`, `theme.css`, `AccrueAdmin.Assets.Build`.
**Apply to:** PageHeader CSS, list-state CSS, skeleton CSS, generated bundle.

Use existing `--ax-*` tokens and `ax-*` classes. Keep `min-width: 0` discipline on any flex/grid cell that can truncate. Loading skeleton motion must honor `prefers-reduced-motion`. Rebuild committed assets after source asset edits with:
```bash
cd accrue_admin
mix accrue_admin.assets.build
```

### Security And A11y

**Source:** `SubscriptionsLive.safe_link/2`, `billing_signals_cell/1`, `Breadcrumbs`, `DataTable` selection status.
**Apply to:** custom cell render helpers, PageHeader, skeleton state.

Escape dynamic row text before `Phoenix.HTML.raw`. Breadcrumbs keep `aria-label="Breadcrumb"` and current crumb `aria-current="page"`. Skeleton state should use `aria-busy`, one `role="status"` label, decorative `aria-hidden` cells, and no focus movement.

## No Analog Found

None. All required and conditional target files have exact or role-match analogs. The optional Subscriptions-list composite Storybook story mentioned in research should use `subscription_detail.story.exs` as a partial analog if the planner includes it, but it is not required for Phase 196.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/components`, `accrue_admin/lib/accrue_admin/live`, `accrue_admin/lib/accrue_admin/queries`, `accrue_admin/lib/accrue_admin/copy`, `accrue_admin/test/accrue_admin`, `accrue_admin/e2e`, `storybook/components`, `accrue_admin/assets/css`, `accrue_admin/guides`.

**Strong analogs read:** `Detail`, `Breadcrumbs`, `StatStrip`, `StatusBadge`, `FilterChipBar`, `DataTable`, `SubscriptionsLive`, `InvoicesLive`, `Subscriptions` query, `DataTableNav`, component tests, LiveView tests, Phase 194/195 Playwright specs, Storybook stories, asset/copy export tasks.

**Files scanned:** 55+ across component/live/query/test/e2e/storybook/CSS surfaces.

**Pattern extraction date:** 2026-06-26
