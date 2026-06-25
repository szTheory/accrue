# Phase 190: Navigation, Data-Display & Meta-Component Cohesion - Pattern Map

**Mapped:** 2026-06-18  
**Files analyzed:** 40  
**Analogs found:** 38 / 40

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---:|---|---|
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | config / utility | transform | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | exact |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | component / route | request-response | `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | route / component composition | request-response | `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | route / component composition | request-response | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | route / component composition | event-driven | `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | route / component composition | event-driven | `accrue_admin/lib/accrue_admin/live/customer_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/app_shell.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/app_shell.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/sidebar.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/sidebar.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/topbar.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/topbar.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/tabs.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/tabs.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/window_selector.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/window_selector.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/global_search.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/flash_group.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/flash_group.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | component | CRUD / event-driven | `accrue_admin/lib/accrue_admin/components/data_table.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/data_table.ex` | role-match |
| `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/kpi_card.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/kpi_card.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` | component | transform | `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/detail.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/timeline.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/timeline.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/related_resources.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/related_resources.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | exact |
| `accrue_admin/assets/css/app.css` | config / utility | transform | `accrue_admin/assets/css/app.css` | exact |
| `accrue_admin/assets/css/theme.css` | config | transform | `accrue_admin/assets/css/theme.css` | exact |
| `accrue_admin/e2e/baseline-manifest.js` | config / test | batch | `accrue_admin/e2e/baseline-manifest.js` | exact |
| `accrue_admin/e2e/admin-baseline.spec.js` | test | batch | `accrue_admin/e2e/admin-baseline.spec.js` | exact |
| `accrue_admin/e2e/admin-a11y.spec.js` | test | batch | `accrue_admin/e2e/admin-a11y.spec.js` | exact |
| `accrue_admin/e2e/admin-interactions.spec.js` | test | event-driven | `accrue_admin/e2e/admin-interactions.spec.js` | exact |
| `accrue_admin/e2e/admin-group-contracts.spec.js` | test | batch / event-driven | `accrue_admin/e2e/admin-baseline.spec.js` + `admin-interactions.spec.js` | role-match |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | test | transform / request-response | `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | exact |
| `accrue_admin/test/accrue_admin/dev/component_kitchen_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/dev/component_kitchen_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/components/data_table_test.exs` | test | CRUD / event-driven | `accrue_admin/test/accrue_admin/components/data_table_test.exs` | exact |
| `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/components/display_components_test.exs` | role-match |
| `accrue_admin/test/accrue_admin/components/display_components_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/components/display_components_test.exs` | exact |
| `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` | exact |
| `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md` | config / docs | transform | none | no-analog |
| `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-PHASE-191-HANDOFF.md` | docs | batch | none | no-analog |

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/dev/component_registry.ex` (config / utility, transform)

**Analog:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex`

Use this file as the primary pattern if Phase 190 keeps group contracts in the existing registry. If a sibling module is introduced, copy the same `Mix.env() != :prod` guard, static map-list shape, type specs, and `variants_for/1`-style accessors.

**Dev-only module and schema pattern** (lines 1-13):

```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
    @moduledoc false

    @type entry :: %{
            family: String.t(),
            variant: String.t(),
            ax_class: String.t(),
            tokens: [String.t()],
            applicable_states: [String.t()] | nil,
            na_states: [%{state: String.t(), reason: String.t()}] | nil,
            specimens: [%{label: String.t(), props: map(), content: String.t() | nil}] | nil
          }
```

**Static entry pattern** (lines 38-56):

```elixir
%{
  family: "button",
  variant: "primary",
  ax_class: "ax-button ax-button-primary",
  tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"],
  applicable_states: ["default", "hover", "focus", "active", "pressed", "disabled", "loading", "overflow"],
  na_states: [
    %{state: "selected", reason: "button has no selection state — use aria-pressed for toggle buttons separately"},
    %{state: "empty", reason: "button always has a label"},
    %{state: "error", reason: "button conveys intent via variant, not validation state"}
  ],
  specimens: [
    %{label: "Default", props: %{variant: "primary", type: "button"}, content: "Save changes"},
    %{label: "Short", props: %{variant: "primary", type: "button"}, content: "Go"},
    %{label: "Long label (overflow)", props: %{variant: "primary", type: "button"}, content: "Export all subscription events to CSV"},
```

**Accessor pattern** (lines 703-707):

```elixir
@doc "All entries for a given family string."
@spec variants_for(String.t()) :: [entry()]
def variants_for(family) do
  Enum.filter(entries(), &(&1.family == family))
end
```

**Apply to:** group contract registry data: `name`, `slug`, `states`, `proof_id`, `component_roots`, `phase191_handoff_tags`, and `specimens`.

### `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (component / route, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex`

Use the existing kitchen rather than adding PhoenixStorybook or new routes. Group specimens should be rendered under `/billing/dev/components` and should follow the global theme toggle.

**Imports and LiveView shell pattern** (lines 5-33):

```elixir
use Phoenix.LiveView

alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  Button,
  Checkbox,
  Detail,
  DropdownMenu,
  EmptyState,
  FlashGroup,
  Icon,
  InlineId,
  Input,
  JsonViewer,
  KpiCard,
  MoneyFormatter,
  Radio,
  RelatedResources,
  Select,
  Spinner,
  StatusBadge,
  Tabs,
  Textarea,
  Toggle,
  Tooltip
}

alias AccrueAdmin.Dev.ComponentRegistry
```

**Mount availability pattern** (lines 35-57):

```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  if fake_processor?() do
    {:ok,
     socket
     |> assign_shell(admin, "/dev/components", "Component Kitchen")
     |> assign(:available?, true)
     |> assign(:flashes, [
       %{
         kind: :info,
         message: "Previewing shared admin components against the shipped package CSS."
       }
     ])}
```

**Page-header proof surface pattern** (lines 70-83):

```elixir
<section class="ax-page">
  <header class="ax-page-header">
    <Breadcrumbs.breadcrumbs
      items={[
        %{label: "Dashboard", href: @admin_mount_path},
        %{label: "Component kitchen"}
      ]}
    />
    <h2 class="ax-display">Component Kitchen</h2>
    <p class="ax-page-description">Primitive and form components — full state matrix. Use the topbar theme toggle to review light and dark.</p>
  </header>

  <FlashGroup.flash_group flashes={@flashes} />
```

**Registry-driven render loop** (lines 184-227):

```elixir
<%= for {family, entries} <- registry_families() do %>
  <section :if={@available?} class="ax-card ax-dev-stack" data-ax-family={family}>
    <div class="ax-dev-family-header">
      <h3 class="ax-type-eyebrow"><%= family_label(family) %></h3>
      <p class="ax-body-sm ax-muted">
        <%= length(entries) %> variant(s) ·
        <%= entries |> hd() |> Map.get(:applicable_states, []) |> length() %> applicable states
      </p>
    </div>

    <div class="ax-dev-state-grid">
      <div class="ax-dev-state-grid-col">
        <%= for entry <- entries do %>
          <%= for state <- Map.get(entry, :applicable_states, []) do %>
            <div class="ax-dev-state-cell" data-ax-state={state}>
              <span class="ax-dev-state-cell-label ax-type-code-xs ax-muted"><%= state %></span>
              <%= render_specimen(entry, state) %>
            </div>
```

**Specimen helper pattern** (lines 472-518):

```elixir
defp registry_families do
  ComponentRegistry.entries()
  |> Enum.filter(&Map.has_key?(&1, :applicable_states))
  |> Enum.group_by(& &1.family)
end

defp family_label("button"), do: "Button"
defp family_label("input"), do: "Input"
defp family_label("textarea"), do: "Textarea"
...
defp render_specimen(entry, state) do
  specimen = pick_specimen(entry.specimens, state)
  do_render_specimen(entry.family, state, specimen, "lab")
end
```

**Apply to:** `data-component-group` sections for page-header/actions/breadcrumbs, toolbar/search/filter/sort, table states, KPI/chart/table, detail-header/metadata/actions, modal-confirm, drawer/form, and tabs/subviews.

### List / Toolbar Pages: `invoices_live.ex` and Similar (route composition, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex`

Use list pages as production probes, not as the primary lab. This page has the correct order for orientation, KPIs, active filters, then `DataTable`.

**Imports and state pattern** (lines 8-26):

```elixir
alias Accrue.Billing.Invoice
alias Accrue.Repo
alias AccrueAdmin.BillingPresentation
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, FilterChipBar, KpiCard}
alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Invoices

@default_queue_status "open,uncollectible"

@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:params, %{})
   |> assign(:table_path, admin_path(admin, "/invoices"))
   |> assign(:summary, invoice_summary())}
end
```

**Group order pattern** (lines 60-99):

```elixir
<section class="ax-page">
  <header class="ax-page-header">
    <Breadcrumbs.breadcrumbs
      items={[
        %{label: Copy.dashboard_breadcrumb_home(), href: @admin_mount_path},
        %{label: Copy.invoices_index_breadcrumb_invoices()}
      ]}
    />
    <p class="ax-eyebrow"><%= Copy.invoices_index_eyebrow() %></p>
    <h2 class="ax-display"><%= Copy.invoices_index_headline() %></h2>
    <p class="ax-body ax-page-copy">
      <%= Copy.invoices_index_body() %>
    </p>
  </header>

  <section class="ax-kpi-grid" aria-label={Copy.invoices_kpi_section_aria_label()}>
    ...
  </section>

  <FilterChipBar.filter_chip_bar
    items={work_queue_chips(@params, @table_path)}
    label="Work queue"
  />

  <.live_component
    module={DataTable}
```

**Explicit mobile card fields pattern** (lines 99-140):

```elixir
<.live_component
  module={DataTable}
  id="invoices"
  query_module={Invoices}
  current_owner_scope={@current_owner_scope}
  path={@table_path}
  params={@params}
  columns={[
    %{label: Copy.invoices_column_invoice(), render: &invoice_link(&1, @admin_mount_path)},
    %{label: Copy.invoices_column_customer(), render: &customer_link(&1, @admin_mount_path)},
    %{label: Copy.invoices_column_billing_signals(), render: &billing_signals_cell/1},
    %{label: Copy.invoices_column_status(), render: &status_summary/1},
    %{label: Copy.invoices_column_balance(), render: &balance_summary/1},
    %{id: :collection_method, label: Copy.invoices_column_collection()}
  ]}
  card_title={&card_title/1}
  card_fields={[
    %{label: Copy.invoices_card_customer(), render: &customer_label/1},
    %{label: Copy.invoices_column_billing_signals(), render: &billing_signals_cell/1},
```

**Apply to:** representative list/table probe and any production `data-component-group` locator added around toolbar/table roots.

### KPI / Chart / Specialized Table: `recovery_live.ex`, `funnel_chart.ex`, `at_risk_table.ex`

**Analogs:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`, `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`, `accrue_admin/lib/accrue_admin/components/data_table.ex`

Use `recovery_live.ex` as the KPI/chart/table composition analog. Use `DataTable` as the behavior contract for `AtRiskTable` mobile cards, filtered-empty/true-empty distinction, and pagination/no-pagination semantics.

**KPI -> chart -> table ordering** (recovery live lines 99-146):

```elixir
<header class="ax-page-header">
  <Breadcrumbs.breadcrumbs items={[%{label: "Analytics"}, %{label: "Recovery"}]} />
  <p class="ax-eyebrow">Recovery Dashboard</p>
  <div class="ax-heading-row">
    <h2 class="ax-display">Revenue Recovery</h2>
    <a ... class="ax-help-link">
      Showing data since 2024-01-01
    </a>
  </div>
  <WindowSelector.window_selector current_window={@window} base_path={@current_path} />
</header>

<%= for kpi <- @kpi_pairs do %>
  <section class="ax-kpi-grid ax-section-gap">
    <KpiCard.kpi_card
      label={"Recovered MRR (#{String.upcase(kpi.currency)})"}
      value={kpi.recovered_str}
      delta="Amount saved by successful Dunning"
      delta_tone="moss"
    >
      <:meta>Money Saved</:meta>
    </KpiCard.kpi_card>
...
<FunnelChart.funnel_chart
  entered={@funnel.entered}
  recovered={@funnel.recovered}
  exhausted={@funnel.exhausted}
  active={@funnel.active}
/>

<AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />
```

**Accessible chart pattern** (`funnel_chart.ex` lines 45-61):

```elixir
<article class={["ax-card", "ax-funnel-chart", @class]}>
  <header class="ax-funnel-header">
    <p class="ax-label">Recovery Funnel</p>
    <span class="ax-funnel-active-chip"><%= @active %> currently in dunning</span>
  </header>

  <svg
    viewBox="0 0 100 36"
    role="img"
    aria-labelledby="funnel-title funnel-desc"
    preserveAspectRatio="none"
    class="ax-funnel-svg"
  >
    <title id="funnel-title">Dunning recovery funnel</title>
    <desc id="funnel-desc">
      <%= @entered %> campaigns entered, <%= @recovered %> recovered, <%= @exhausted %> exhausted.
```

**Current specialized-table gap to harden** (`at_risk_table.ex` lines 33-73):

```elixir
def at_risk_table(assigns) do
  ~H"""
  <section class={["ax-card", "ax-at-risk-table", @class]}>
    <header class="ax-at-risk-header">
      <p class="ax-label">At-Risk Subscriptions</p>
      <p class="ax-body ax-muted">{length(@rows)} active dunning campaigns in this window</p>
    </header>

    <table :if={not Enum.empty?(@rows)} class="ax-at-risk-grid">
      ...
    </table>

    <div :if={Enum.empty?(@rows)} class="ax-empty-state" data-role="empty-state">
      <p class="ax-heading">No active dunning campaigns</p>
      <p class="ax-body">All subscriptions in this window have recovered or exhausted their campaign.</p>
    </div>
  </section>
  """
end
```

**Apply to:** `AtRiskTable` must copy `DataTable`'s mobile-card/empty/pagination contract rather than remaining desktop-table-only.

### `accrue_admin/lib/accrue_admin/components/data_table.ex` (component, CRUD / event-driven)

**Analog:** `accrue_admin/lib/accrue_admin/components/data_table.ex`

This is the canonical data-display contract. Copy its assign defaults, query boundary, filtered-empty behavior, card/table split, and cursor-gated pagination.

**Update defaults and query state** (lines 15-61):

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
    |> assign_new(:card_title, fn -> nil end)
```

**Filters, empty state, selection, table, cards, footer** (lines 122-260):

```elixir
<section id={@id} class="ax-data-table" data-role="data-table">
  <header class="ax-data-table-header">
    <form action={@path} method="get" class="ax-data-table-filters" data-role="filter-form">
      <div :for={field <- @filter_fields} class="ax-data-table-filter">
        <label for={field_id(@id, field)} class="ax-label"><%= field_label(field) %></label>
        <.filter_input id={field_id(@id, field)} field={field} value={Map.get(@filter_params, field_param(field))} />
      </div>
      ...
      <button type="submit" class="ax-button ax-button-primary"><%= @filter_submit_label %></button>
      <a href={@path} class="ax-button ax-button-ghost">Clear</a>
    </form>
  </header>

  <div :if={Enum.empty?(@rows)} class="ax-card ax-empty ax-data-table-empty" data-role="empty-state">
    <Icon.icon name={:inbox} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
    <p class="ax-empty-title"><%= @empty_title %></p>
    <p class="ax-body ax-empty-copy"><%= @empty_copy %></p>
    <a
      :if={any_filter_active?(@filter_params)}
      href={@path}
      class="ax-button ax-button-secondary"
      data-role="clear-filters"
    >
      <%= Copy.data_table_clear_filters_label() %>
    </a>
  </div>
...
  <div :if={!Enum.empty?(@rows)} class="ax-data-table-cards" data-role="card-list">
    <article :for={row <- @rows} class="ax-card ax-data-table-card" data-row-id={row_identity(row, @row_id)}>
...
  <footer :if={!Enum.empty?(@rows)} class="ax-data-table-footer">
    <p class="ax-body" data-role="row-count"><%= "#{length(@rows)} rows loaded" %></p>
    <button
      :if={@next_cursor}
      type="button"
      phx-click="load-more"
```

**Reload/query boundary** (lines 302-327):

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
```

**Filtered-empty distinction** (lines 436-442):

```elixir
# True when any filter param carries a value — distinguishes "filtered to zero"
# (offer Clear filters) from a genuinely empty first-use list.
defp any_filter_active?(filter_params) when is_map(filter_params) do
  Enum.any?(filter_params, fn {_key, value} -> value not in [nil, ""] end)
end
```

**Apply to:** all entity queues and `AtRiskTable` hardening.

### Detail / Metadata / Timeline Components (component, request-response)

**Analogs:** `detail.ex`, `kpi_card.ex`, `timeline.ex`, `related_resources.ex`

Use these for detail-header/metadata/actions and detail evidence sections. Add group locators at reusable roots where the group root is unambiguous.

**Detail summary and actions slot** (`detail.ex` lines 58-82):

```elixir
attr(:eyebrow, :string, default: nil)
attr(:title, :string, required: true)
slot(:status)
slot(:facts)
slot(:actions)

def summary_card(assigns) do
  ~H"""
  <header class="ax-card ax-summary-card">
    <div class="ax-summary-main">
      <p :if={@eyebrow} class="ax-eyebrow"><%= @eyebrow %></p>
      <div class="ax-summary-title-row">
        <h2 class="ax-summary-title"><%= @title %></h2>
        <%= render_slot(@status) %>
      </div>
      <div :if={@facts != []} class="ax-summary-facts"><%= render_slot(@facts) %></div>
    </div>
    <div :if={@actions != []} class="ax-summary-actions"><%= render_slot(@actions) %></div>
  </header>
```

**KPI card slot pattern** (`kpi_card.ex` lines 22-59):

```elixir
def kpi_card(assigns) do
  ~H"""
  <%= if @href do %>
    <a
      href={@href}
      class={["ax-card ax-kpi-card ax-kpi-card--linked", @class]}
      aria-label={@aria_label}
    >
      <.kpi_inner {assigns} />
    </a>
  <% else %>
    <article class={["ax-card ax-kpi-card", @class]}>
      <.kpi_inner {assigns} />
    </article>
  <% end %>
  """
end
```

**Timeline empty and expandable details pattern** (`timeline.ex` lines 13-43):

```elixir
def timeline(assigns) do
  ~H"""
  <section class={["ax-timeline", @class]} aria-label={@label}>
    <ol :if={@items != []} class="ax-timeline-list">
      <li :for={item <- @items} class="ax-timeline-item">
        <span class={["ax-timeline-dot", "ax-timeline-dot-" <> tone(item)]} aria-hidden="true"></span>

        <div class="ax-timeline-card">
          <div class="ax-timeline-header">
...
          <details :if={Map.get(item, :details)} class="ax-timeline-details" open={Map.get(item, :expanded, false)}>
            <summary>Inspect details</summary>
            <pre><%= Map.get(item, :details) %></pre>
          </details>
...
    <p :if={@items == []} class="ax-body ax-filter-chip-empty"><%= @empty_label %></p>
```

**Related-resource link card pattern** (`related_resources.ex` lines 28-47):

```elixir
def related_resources(assigns) do
  ~H"""
  <section :if={@items != []} class="ax-card ax-related" aria-label={@title}>
    <header class="ax-related-head">
      <h3 class="ax-related-title"><%= @title %></h3>
    </header>
    <ul class="ax-related-list">
      <li :for={item <- @items}>
        <a class="ax-related-item" href={item.href}>
          <span class="ax-related-icon"><Icon.icon name={item.icon} size="sm" /></span>
          <span class="ax-related-text">
            <span class="ax-related-label"><%= item.label %></span>
            <span :if={item[:value]} class="ax-related-value"><%= item.value %></span>
```

### Navigation Components (component, request-response / event-driven)

**Analogs:** `app_shell.ex`, `sidebar.ex`, `breadcrumbs.ex`, `tabs.ex`, `window_selector.ex`, `dropdown_menu.ex`, `global_search.ex`, `flash_group.ex`

Use link navigation semantics for route/patch navigation. Do not introduce APG `tablist` unless same-page tab panels are implemented. For `DropdownMenu`, Phase 190 should switch the current role-overclaimed implementation to disclosure semantics unless Phase 191 supplies the menu keyboard contract.

**App shell composition** (`app_shell.ex` lines 28-52):

```elixir
<div class="ax-shell" data-mount-path={@mount_path}>
  <Sidebar.sidebar brand={@brand} current_path={@current_path} items={@nav_items} />

  <div class="ax-shell-main">
    <div :if={@active_organization_name} class="ax-active-org-banner" role="status">
      <span class="ax-label">Active organization</span>
      <span class="ax-active-org-name"><%= @active_organization_name %></span>
    </div>

    <Topbar.topbar brand={@brand} page_title={@page_title} theme={@theme} />

    <main class="ax-shell-content" id="main-content">
      <%= render_slot(@inner_block) %>
    </main>
  </div>

  <.live_component
    module={AccrueAdmin.Components.GlobalSearch}
    id="global-search"
```

**Sidebar group disclosure pattern** (`sidebar.ex` lines 42-80):

```elixir
<nav class="ax-sidebar-nav">
  <%= for {group, items, group_meta} <- grouped_items(@items) do %>
    <section
      id={"sidebar-group-section-#{slugify(group)}"}
      class="ax-sidebar-nav-group"
      phx-hook={if group_meta.collapsible, do: "SidebarCollapse"}
      data-group={if group_meta.collapsible, do: slugify(group)}
      data-controls={if group_meta.collapsible, do: "sidebar-group-links-#{slugify(group)}"}
    >
      <%= if group_meta.collapsible do %>
        <button
          class="ax-sidebar-group-label ax-sidebar-group-toggle"
          type="button"
          aria-expanded={to_string(group_initially_expanded?(group_meta))}
          aria-controls={"sidebar-group-links-#{slugify(group)}"}
```

**Breadcrumbs pattern** (`breadcrumbs.ex` lines 12-30):

```elixir
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
```

**Link tabs pattern** (`tabs.ex` lines 13-23):

```elixir
<nav class="ax-tabs" aria-label="Page sections">
  <a
    :for={tab <- @tabs}
    href={tab[:href]}
    class={["ax-tab", active_tab?(tab, @active) && "ax-tab-active"]}
    aria-current={if(active_tab?(tab, @active), do: "page", else: nil)}
  >
    <span><%= tab[:label] %></span>
    <span :if={tab[:count]} class="ax-tab-count"><%= tab[:count] %></span>
  </a>
</nav>
```

**Live patch link selector pattern** (`window_selector.ex` lines 29-40):

```elixir
<nav class="ax-tabs" aria-label="Time window (UTC)">
  <.link
    :for={{value, label} <- @windows}
    patch={window_href(@base_path, value)}
    class={["ax-tab", @current_window == value && "ax-tab-active"]}
    aria-current={if @current_window == value, do: "page", else: nil}
  >
    <%= label %> UTC
  </.link>
</nav>
```

**Dropdown role mismatch to fix** (`dropdown_menu.ex` lines 13-30):

```elixir
<details class="ax-dropdown">
  <summary class="ax-button ax-button-secondary ax-dropdown-trigger">
    <span><%= @label %></span>
    <span aria-hidden="true">▾</span>
  </summary>

  <div class="ax-dropdown-panel" role="menu" aria-label={@label}>
    <a
      :for={item <- @items}
      href={item[:href] || "#"}
      class={["ax-dropdown-item", item[:danger] && "ax-dropdown-item-danger"]}
      role="menuitem"
    >
```

For Phase 190, preserve the native `<details>/<summary>` structure but remove `role="menu"` and `role="menuitem"` unless keyboard menu behavior is added in Phase 191.

**Global search bounded query and dialog structure** (`global_search.ex` lines 77-96, 130-165):

```elixir
def handle_event("search", %{"q" => query}, socket) do
  trimmed = String.trim(query)

  cond do
    trimmed == "" ->
      {:noreply,
       assign(socket,
         query: "",
         results: empty_results(),
         loading: false
       )}

    String.length(trimmed) > @max_query_length ->
      {:noreply, assign(socket, query: trimmed, results: empty_results(), loading: false)}

    true ->
      results = fetch_results(trimmed)
      {:noreply, assign(socket, query: trimmed, results: results, loading: false)}
  end
end
```

```elixir
<div id={@id} class="ax-command-palette-wrapper" data-open={to_string(@is_open)}>
  <div 
    class="ax-command-palette-backdrop" 
    phx-click="close" 
    phx-target={@myself}>
  </div>
  
  <div 
    class="ax-command-palette" 
    phx-hook="CommandPalette" 
    id="command-palette-container"
    data-target={@myself}
    role="dialog"
    aria-modal="true"
    aria-label="Global search">
```

### Overlay / Modal Confirm / Drawer Components (component, event-driven)

**Analogs:** `detail_drawer.ex`, `step_up_auth_modal.ex`, `invoice_live.ex`

Phase 190 owns structure, IDs, action order, responsive sizing, scrollable body/footer, and layer roles. Full focus trap, Escape, click-outside, scroll lock, and focus restore remain Phase 191 unless the reusable root itself is clearly responsible.

**Drawer structure and slots** (`detail_drawer.ex` lines 21-67):

```elixir
def detail_drawer(assigns) do
  ~H"""
  <section
    :if={@open}
    id={@id}
    class={["ax-detail-drawer-shell", @class]}
    role="dialog"
    aria-modal="true"
    aria-labelledby={"#{@id}-title"}
    phx-mounted={Phoenix.LiveView.JS.show(transition: {"ax-drawer-entering", "ax-drawer-enter-from", "ax-drawer-enter-to"}, time: 240)}
    phx-remove={Phoenix.LiveView.JS.hide(transition: {"ax-drawer-leaving", "ax-drawer-leave-from", "ax-drawer-leave-to"}, time: 140)}
  >
    <div
      class="ax-detail-drawer-backdrop"
      aria-hidden="true"
...
    <aside class="ax-detail-drawer">
      <header class="ax-detail-drawer-header">
...
      <div class="ax-detail-drawer-body">
        <%= render_slot(@inner_block) %>
      </div>

      <footer :if={@footer != []} class="ax-detail-drawer-footer">
```

**Step-up modal structure** (`step_up_auth_modal.ex` lines 20-55):

```elixir
<section
  :if={@pending}
  id="accrue-admin-step-up-dialog"
  class="ax-card ax-step-up-modal"
  role="dialog"
  aria-labelledby="step-up-title"
  phx-mounted={Phoenix.LiveView.JS.push_focus() |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")}
  phx-remove={Phoenix.LiveView.JS.pop_focus()}
>
  <header class="ax-page-header">
    <p class="ax-eyebrow"><%= Copy.step_up_eyebrow() %></p>
    <h2 id="step-up-title" class="ax-heading"><%= Copy.step_up_title() %></h2>
    <p class="ax-body">
      <%= Map.get(@challenge || %{}, :message) || Copy.step_up_default_challenge_message() %>
    </p>
  </header>
...
  <form phx-submit="step_up_submit" class="ax-page">
```

**Current confirm-panel shape to normalize** (`invoice_live.ex` lines 309-318):

```elixir
<section :if={@pending_action} class="ax-card" data-role="confirm-panel">
  <p class="ax-label"><%= Copy.invoice_confirm_panel_label() %></p>
  <p class="ax-body"><%= confirm_copy(@pending_action) %></p>
  <div class="ax-page-header">
    <button phx-click="confirm_action" class="ax-button ax-button-primary" data-role="confirm-action">
      <%= Copy.invoice_confirm_action_verb() %> <%= humanize(@pending_action.type) %>
    </button>
    <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost"><%= Copy.invoice_confirm_cancel() %></button>
  </div>
</section>
```

**Apply to:** `modal-confirm` specimen and any extracted reusable confirm component. Add `aria-labelledby` / `aria-describedby` IDs and group locator; avoid implementing focus trap/dismiss behavior in this phase.

### CSS: `theme.css` and `app.css` (config / utility, transform)

**Analogs:** `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`

All group CSS should consume Phase 188 `--ax-*` tokens. Avoid one-off pixel values unless they are already paired with breakpoint token comments or documented exceptions.

**Token source of truth** (`theme.css` lines 25-40, 128-134):

```css
/* Spacing — 4px base, with a tight 2px rung for dense tables and a 64px layout rung */
--ax-space-2xs: 0.125rem; /* 2px */
--ax-space-xs: 0.25rem;   /* 4px */
--ax-space-sm: 0.5rem;    /* 8px */
--ax-space-md: 1rem;      /* 16px */
--ax-space-lg: 1.5rem;    /* 24px */
--ax-space-xl: 2rem;      /* 32px */
--ax-space-2xl: 3rem;     /* 48px */
--ax-space-3xl: 4rem;     /* 64px */

/* Radius — tightened ~40% for a crisp financial-tool feel; pill reserved for badges */
--ax-radius-2xs: 0.25rem;  /* 4px — chips, in-table controls */
--ax-radius-sm: 0.5rem;    /* 8px — inputs, small cards */
--ax-radius-md: 0.625rem;  /* 10px — cards, panels */
--ax-radius-lg: 0.875rem;  /* 14px — drawers, modals */
--ax-radius-pill: 999px;
```

```css
--ax-z-base: 0;
--ax-z-sticky: 100;
--ax-z-dropdown: 200;
--ax-z-popover: 300;
--ax-z-drawer: 400;
--ax-z-modal: 500;
--ax-z-toast: 600;
```

**Shared card/elevation rhythm** (`app.css` lines 691-706):

```css
.ax-filter-chip-bar,
.ax-json-viewer,
.ax-detail-drawer,
.ax-timeline-card,
.ax-kpi-card {
  border: 1px solid var(--ax-border);
  background: var(--ax-elevated);
}

.ax-filter-chip-bar,
.ax-json-viewer,
.ax-kpi-card,
.ax-timeline-card {
  border-radius: var(--ax-radius-lg);
  padding: var(--ax-space-lg);
}
```

**Data table responsive DOM contract** (`app.css` lines 1786-1805):

```css
/* Data table: one layout at a time — cards below md, grid table from md (avoids duplicate DOM in a11y scans). */
.ax-data-table-shell {
  display: none;
  overflow-x: auto;
}

.ax-data-table-cards {
  display: grid;
  gap: var(--ax-space-md);
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

**Overlay layer and scroll pattern** (`app.css` lines 919-959):

```css
.ax-detail-drawer-shell {
  position: fixed;
  inset: 0;
  z-index: var(--ax-z-drawer);
}

.ax-detail-drawer-backdrop {
  position: absolute;
  inset: 0;
  background: color-mix(in srgb, var(--accrue-ink) 40%, transparent);
  backdrop-filter: blur(6px);
}

.ax-detail-drawer {
  position: absolute;
  inset: auto 0 0 0;
  min-height: 100vh;
  padding: var(--ax-space-lg);
  overflow: auto;
```

**Dropdown and tabs CSS pattern** (`app.css` lines 1881-1996):

```css
.ax-dropdown {
  position: relative;
  width: fit-content;
}

.ax-dropdown-panel {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  min-width: 15rem;
  padding: var(--ax-space-sm);
  border: 1px solid var(--ax-border);
  border-radius: var(--ax-radius-md);
  background: var(--ax-elevated);
  box-shadow: var(--ax-shadow-sm);
  z-index: var(--ax-z-dropdown);
}
...
.ax-tab-active {
  border-bottom-color: var(--ax-accent);
  color: var(--ax-primary);
}
```

**Current AtRisk desktop-only CSS gap** (`app.css` lines 2330-2365):

```css
/* At-risk table — analytics section below funnel */
.ax-at-risk-table {
  overflow-x: auto;
}

.ax-at-risk-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--ax-space-md);
  margin-bottom: var(--ax-space-md);
}

.ax-at-risk-grid {
  width: 100%;
  border-collapse: collapse;
}
```

**Detail rhythm pattern** (`app.css` lines 2817-2895):

```css
.ax-summary-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--ax-space-lg);
  flex-wrap: wrap;
}

.ax-summary-main {
  display: grid;
  gap: var(--ax-space-sm);
  min-width: 0;
}
...
.ax-field-list {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--ax-space-md);
  margin: 0;
}
```

**Shared focus/selected state contract** (`app.css` lines 2977-3065):

```css
.ax-button:focus-visible,
.ax-sidebar-link:focus-visible,
.ax-theme-button:focus-visible,
.ax-icon-button:focus-visible,
.ax-link:focus-visible,
.ax-dropdown-item:focus-visible,
...
[data-ax-force~="focus"] {
  border-color: var(--ax-focus-ring);
  outline: 2px solid var(--ax-focus-ring);
  outline-offset: 2px;
  box-shadow: var(--ax-focus-shadow);
}
...
.ax-sidebar-link-active,
.ax-tab-active,
[aria-current="page"],
[aria-selected="true"],
.ax-filter-chip-active,
.ax-theme-button.ax-theme-button-active {
  background: var(--ax-interactive-selected);
}
```

## Test Pattern Assignments

### Registry and Kitchen Tests

**Analogs:** `component_registry_test.exs`, `component_kitchen_live_test.exs`

**Mounted route presence assertion** (`component_registry_test.exs` lines 19-33):

```elixir
test "every registry variant appears in the /dev/components page render", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  for %{ax_class: ax_class} <- ComponentRegistry.entries() do
    [_base, variant_class] = String.split(ax_class, " ", parts: 2)

    assert html =~ variant_class,
           "registry variant #{inspect(ax_class)} — variant class #{inspect(variant_class)} " <>
             "was not found in the /dev/components page HTML"
  end
end
```

**Token definition guard** (`component_registry_test.exs` lines 93-120):

```elixir
test "all tokens listed in ComponentRegistry.entries() are defined in the design system" do
  theme_css = File.read!(theme_css_path())
  app_css = File.read!(app_css_path())

  known_in_layouts = ["--ax-accent", "--ax-accent-contrast"]

  phantom_tokens =
    for entry <- ComponentRegistry.entries(),
        token <- entry.tokens,
        token not in known_in_layouts,
        definition = token <> ":",
        not String.contains?(theme_css, definition),
        not String.contains?(app_css, definition) do
      {entry.family, entry.variant, token}
    end

  assert phantom_tokens == [],
```

**Registry shape guard** (`component_registry_test.exs` lines 198-226):

```elixir
test "entries with applicable_states also carry na_states and specimens with valid shapes" do
  for entry <- ComponentRegistry.entries(),
      Map.has_key?(entry, :applicable_states) do
    assert Map.has_key?(entry, :na_states),
           "registry entry #{entry.family}/#{entry.variant} has :applicable_states but is missing :na_states"

    assert Map.has_key?(entry, :specimens),
           "registry entry #{entry.family}/#{entry.variant} has :applicable_states but is missing :specimens"

    for %{state: state, reason: reason} <- entry.na_states do
      assert is_binary(state) and state != ""
      assert is_binary(reason) and reason != ""
    end
```

**State-grid route assertion** (`component_registry_test.exs` lines 238-259):

```elixir
test "mounted /dev/components page has the state grid and data-ax-state cells", %{
  conn: conn
} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  assert html =~ "ax-dev-state-grid",
         "no .ax-dev-state-grid found in /dev/components HTML"

  assert html =~ ~s(data-ax-state="default")
  assert html =~ ~s(data-ax-state="disabled")
  assert html =~ "data-ax-na-reason"
end
```

For Phase 190, copy these tests as group-contract tests: assert each Phase 187 group slug has a registry entry, has a kitchen specimen, renders one `data-component-group`, and lists Phase 191 handoff tags where applicable.

### DataTable Tests

**Analog:** `data_table_test.exs`

**Stateful LiveComponent harness** (lines 125-168):

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
     |> Phoenix.Component.assign(:table_caption, Map.get(session, "table_caption"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={DataTable}
      id="fixtures"
      query_module={AccrueAdmin.DataTableTest.FixtureQuery}
      path={@path}
      params={@table_params}
      limit={2}
```

**Pagination and card selection tests** (lines 256-299):

```elixir
test "loads additional rows via opaque cursor pagination without embedding resource fields", %{
  conn: conn
} do
  {:ok, view, html} =
    live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

  assert html =~ "Newest open"
  assert html =~ "Older open"
  refute html =~ "Oldest open"

  html = render_click(element(view, "[data-role='load-more']"))
...
test "renders card mode markup and supports visible-row bulk selection", %{conn: conn} do
  {:ok, view, html} =
    live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

  assert html =~ ~s(data-role="card-list")
  assert html =~ "Category"
```

**Empty state copy test** (lines 301-309):

```elixir
test "renders default empty state copy from AccrueAdmin.Copy when no rows match", %{conn: conn} do
  FixtureStore.put_rows([])

  assert {:ok, _view, html} =
           live_isolated(conn, TableLive, session: %{"params" => %{}})

  assert html =~ "Nothing in this list yet"
  assert html =~ "Billing records appear here when they match this view"
end
```

Use this harness for `AtRiskTable` if it remains function-component-only, with `render_component/2` tests for table/card/empty/loading/error/no-pagination states.

### Display and Navigation Component Tests

**Analogs:** `display_components_test.exs`, `navigation_components_test.exs`

**Drawer structure test** (`display_components_test.exs` lines 44-70):

```elixir
describe "DetailDrawer" do
  test "renders a page-agnostic drawer shell with mobile-ready close action" do
    html =
      render_component(fn assigns ->
        assigns = assigns

        ~H"""
        <DetailDrawer.detail_drawer open title="Webhook event" subtitle="evt_123" close_href="/billing/webhooks">
          <:actions>
            <span class="ax-body">Queued retry</span>
          </:actions>
          Webhook payload content
          <:footer>
            <span class="ax-body">Footer actions</span>
          </:footer>
        </DetailDrawer.detail_drawer>
        """
      end)

    assert html =~ ~s(role="dialog")
```

**KPI and timeline tests** (`display_components_test.exs` lines 73-128):

```elixir
describe "KpiCard" do
  test "renders KPI value, delta tone, and optional sparkline slot" do
    html =
      render_component(fn assigns ->
        assigns = assigns

        ~H"""
        <KpiCard.kpi_card label="MRR" value="$12,450" delta="+12.5%" delta_tone="moss" trend="vs last month">
          <:meta>
            <span class="ax-body">12 active subscriptions</span>
          </:meta>
          <:sparkline>
            <svg aria-hidden="true"><path d="M0 10 L10 5" /></svg>
          </:sparkline>
        </KpiCard.kpi_card>
        """
      end)
```

```elixir
describe "Timeline" do
  test "renders escaped timeline items with expandable detail blocks" do
    html =
      render_component(&Timeline.timeline/1, %{
        items: [
          %{
            title: "Webhook received",
            at: "April 15, 2026",
            status: :queued,
            body: "<script>alert(1)</script>",
            details: "{error: false}",
            expanded: true
          },
```

**Dropdown test to update if disclosure semantics are chosen** (`navigation_components_test.exs` lines 169-194):

```elixir
describe "DropdownMenu" do
  test "renders accessible text actions instead of icon-only affordances" do
    html =
      render_component(&DropdownMenu.dropdown_menu/1, %{
        label: "Invoice actions",
        items: [
          %{label: "Open PDF", href: "/billing/invoices/in_123/pdf", description: "Preview the live invoice PDF"},
          %{label: "Void invoice", href: "/billing/invoices/in_123/void", description: "Stop further collection", danger: true}
        ]
      })

    assert html =~ ~s(<details)
    assert html =~ ~s(role="menu")
    assert html =~ "Invoice actions"
```

This assertion currently codifies the role mismatch. If `DropdownMenu` switches to disclosure semantics, replace the `role="menu"` assertion with checks for `<details>`, `<summary>`, visible labels/descriptions, no `role="menu"`, and no `role="menuitem"`.

**Tabs and window selector assertions** (`navigation_components_test.exs` lines 197-212, 317-354):

```elixir
describe "Tabs" do
  test "renders link tabs with active detail-page state" do
    html =
      render_component(&Tabs.tabs/1, %{
        active: "events",
        tabs: [
          %{id: "overview", label: "Overview", href: "/billing/customers/cus_123"},
          %{id: "events", label: "Events", href: "/billing/customers/cus_123/events", count: 12}
        ]
      })

    assert html =~ "Overview"
    assert html =~ ~s(aria-current="page")
    assert html =~ "ax-tab-active"
```

```elixir
describe "WindowSelector" do
  test "marks active window with aria-current and ax-tab-active" do
    html =
      render_component(&WindowSelector.window_selector/1, %{
        current_window: "30d",
        base_path: "/billing/analytics/recovery"
      })

    assert html =~ ~s(aria-current="page")
    assert html =~ "ax-tab-active"
    assert 1 == html |> String.split(~s(aria-current="page")) |> length() |> Kernel.-(1)
  end
```

### Playwright / Axe / Baseline Tests

**Analogs:** `baseline-manifest.js`, `admin-baseline.spec.js`, `admin-a11y.spec.js`, `admin-interactions.spec.js`

**Phase 187 group names and slug grammar** (`baseline-manifest.js` lines 181-197):

```javascript
const COMPONENT_GROUPS = [
  ["page-header/actions/breadcrumbs", "Orient the operator, name the task, and expose primary actions."],
  ["toolbar/search/filter/sort", "Refine dense lists without hiding current constraints."],
  ["table/empty/loading/error/pagination", "Move from no data through large data sets without losing actionability."],
  ["KPI/chart/table", "Connect summary metrics to trend and row-level evidence."],
  ["detail-header/metadata/actions", "Anchor identity, facts, status, and detail-level operations."],
  ["modal-confirm", "Confirm destructive or consequential actions with focus containment."],
  ["drawer/form", "Edit or inspect details in a layered panel while preserving page context."],
  ["tabs/subviews", "Move between related resource subviews with stable focus and labels."],
];

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}
```

Do not rename these groups or change `cellId` grammar.

**Visible surface locator pattern** (`admin-baseline.spec.js` lines 119-138):

```javascript
async function visibleSurface(page, surface) {
  if (surface.surface_type === "page-flow") {
    return page.locator("#main-content").isVisible();
  }

  const id = surface.routeBuilder?.anchor || surface.routeBuilder?.group || slug(surface.surface);
  const candidates = [
    page.locator(`#${id}`),
    page.locator(`[data-component="${id}"]`),
    page.locator(`[data-component-group="${id}"]`),
    page.getByText(surface.surface, { exact: false }),
  ];

  for (const locator of candidates) {
    if ((await locator.count()) > 0 && (await locator.first().isVisible())) {
      return true;
    }
  }
  return false;
}
```

**Targeted responsive risk probe** (`admin-baseline.spec.js` lines 227-280):

```javascript
async function captureTargetedSurface(page, surface, route, projectName, observations) {
  if (!targetedRisk(surface)) return;

  const originalViewport = page.viewportSize();
  const mode = projectMode(projectName);
  const cells = cellsForSurface(surface).filter(
    (cell) =>
      cell.mode === mode &&
      cell.theme === "light" &&
      cell.state === "default-populated" &&
      cell.dimension === 5
  );

  if (cells.length === 0) return;

  try {
    for (const breakpoint of TARGETED_BREAKPOINTS) {
      await page.setViewportSize({ width: breakpoint, height: 900 });
      await login(page, route);
      await expect(page.locator("#main-content")).toBeVisible();
```

**Axe light/dark scan pattern** (`admin-a11y.spec.js` lines 19-28, 77-91):

```javascript
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}
```

```javascript
for (const [name, path] of surfaces) {
  await login(page, path);
  await expect(page.locator("#main-content")).toBeVisible();

  for (const theme of ["light", "dark"]) {
    const violations = await scan(page, theme);
    for (const v of violations) {
      const d = v.nodes[0] && (v.nodes[0].any[0] || v.nodes[0].all[0]);
      const detail = d && d.data ? ` fg=${d.data.fgColor} bg=${d.data.bgColor} r=${d.data.contrastRatio}` : "";
      failures.push(`${name} [${theme}] ${v.id}: ${v.nodes[0]?.target.join(" ")}${detail}`);
    }
  }
}
```

**Interaction recorder schema** (`admin-interactions.spec.js` lines 57-101):

```javascript
function makeRecorder(projectName) {
  const rows = [];
  let sequence = 0;
  const evidenceRefs = [
    `accrue_admin/test-results/admin-interactions/${projectName}/observations.ndjson`,
    `playwright-trace:${projectName}:admin-interactions.spec.js`,
  ];

  function observe(row) {
    sequence += 1;
    const complete = {
      probe_id: row.probe_id || `ixn-${String(sequence).padStart(3, "0")}`,
      interaction_class: row.interaction_class,
      cell_id: row.cell_id || `p187__${slug(row.surface || row.interaction_class)}__${projectName}__${slug(row.state || "interactive-open")}__d11`,
      surface: row.surface,
      surface_type: row.surface_type || "page-flow",
      state: row.state || "interactive-open",
      rubric_dimension: row.rubric_dimension || "interaction-integrity",
      overlay_tags: (row.overlay_tags || []).filter((tag) => OVERLAY_TAGS.includes(tag)),
```

**Group-relevant probes to copy** (`admin-interactions.spec.js` lines 487-567, 631-753):

```javascript
async function probeDropdownPopoverToast(page, recorder, fixtureData) {
  await login(page, "/billing");
  await expect(page.locator("#main-content")).toBeVisible();

  const searchTrigger = page.locator("#search-trigger");
  await clickOrObserve(searchTrigger, recorder, {
    interaction_class: "dropdown-popover-toast",
    surface: "command palette",
    target_selector: "#search-trigger, .ax-command-palette-wrapper",
    expected: "Command palette opens and exposes open state.",
    overlay_tags: ["overlay-position", "actionability"],
  });
...
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();
  const nativeSummary = page.locator("details.ax-dropdown > summary").first();
  await clickOrObserve(nativeSummary, recorder, {
    interaction_class: "dropdown-popover-toast",
    surface: "native dropdown menu",
    target_selector: "details.ax-dropdown > summary, .ax-dropdown-panel",
```

```javascript
async function probeAffordanceAndStates(page, recorder) {
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  for (const [selector, label] of [
    [".ax-card", "non-interactive cards"],
    ["tbody tr, [data-role='card-list'] article", "rows"],
    [".ax-status, .ax-badge", "status chips"],
    ["button[disabled], [aria-disabled='true']", "disabled controls"],
    ["input[readonly], textarea[readonly]", "read-only controls"],
  ]) {
...
  await login(page, "/billing/customers?status=no-records");
  await expect(page.locator("#main-content")).toBeVisible();
  recorder.observe({
    interaction_class: "loading-error-empty-state",
    surface: "empty state",
    target_selector: '[data-role="empty-state"], .ax-empty-state',
    state: "empty",
```

For Phase 190, prefer a narrow `admin-group-contracts.spec.js` only if the added assertions would otherwise make `admin-baseline.spec.js` too broad. Reuse `makeRecorder` shape if observations are emitted.

## Shared Patterns

### Stable Group Locator

**Source:** `baseline-manifest.js` lines 181-197 and `admin-baseline.spec.js` lines 119-138  
**Apply to:** kitchen group specimens, reusable group roots, and representative live probes.

Use slug names derived from Phase 187 `COMPONENT_GROUPS`:

```text
page-header-actions-breadcrumbs
toolbar-search-filter-sort
table-empty-loading-error-pagination
kpi-chart-table
detail-header-metadata-actions
modal-confirm
drawer-form
tabs-subviews
```

Do not change Phase 187 cell-id grammar.

### Data Display Contract

**Source:** `data_table.ex` lines 122-260 and `data_table_test.exs` lines 256-309  
**Apply to:** `DataTable`, `AtRiskTable`, KPI/chart/table specimens, timeline/detail metadata.

Contract: label/title, primary value, secondary facts, status/action affordances, empty/loading/error, pagination or explicit no-pagination state, long-content behavior, and mobile card/list readability.

### Link Navigation Contract

**Source:** `tabs.ex` lines 13-23, `window_selector.ex` lines 29-40  
**Apply to:** `tabs/subviews`, `window_selector`, customer more-tabs where route navigation is used.

Use link navigation with `aria-current="page"`. Do not use APG tab roles unless rendering same-page tab panels and implementing tab keyboard behavior.

### Overlay Boundary

**Source:** `detail_drawer.ex` lines 21-67, `step_up_auth_modal.ex` lines 20-55, Phase 190 context D-25/D-26  
**Apply to:** `modal-confirm`, `drawer/form`, `global_search`, `dropdown/menu`.

Phase 190 may standardize role, IDs, action order, sizing, body/footer scroll, and z-index tokens. Full focus trap, focus restore, Escape/click-outside, scroll lock, and LiveView patch focus recovery are Phase 191 handoff items unless the reusable group root is the direct defect.

### Tokenized Group CSS

**Source:** `theme.css` lines 25-40 and 128-134; `app.css` lines 691-706, 1786-1805, 2977-3065  
**Apply to:** all group CSS.

Use `--ax-space-*`, `--ax-radius-*`, `--ax-z-*`, `--ax-interactive-*`, `--ax-status-*`, and composed type roles. Keep breakpoint comments like `/* --ax-bp-md ↑ */` when using numeric media queries.

### Test Layering

**Source:** `component_registry_test.exs`, `data_table_test.exs`, `admin-baseline.spec.js`, `admin-a11y.spec.js`, `admin-interactions.spec.js`  
**Apply to:** all Phase 190 plans.

Use component tests for DOM/semantic contracts, registry tests for slug/specimen shape, Playwright baseline for group visibility/responsive probes, axe for light/dark accessibility, and interaction probes only for representative group drift and Phase 191 handoff evidence.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---:|---|
| `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md` | config / docs | transform | No current group-contract planning artifact exists; derive content from `ComponentRegistry.entries/0`, Phase 187 `COMPONENT_GROUPS`, and this pattern map. |
| `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-PHASE-191-HANDOFF.md` | docs | batch | No dedicated handoff artifact exists; use Phase 187 defect IDs, `OVERLAY_TAGS`, and `admin-interactions.spec.js` observation schema. |

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/components`, `accrue_admin/lib/accrue_admin/dev`, `accrue_admin/lib/accrue_admin/live`, `accrue_admin/test/accrue_admin/components`, `accrue_admin/test/accrue_admin/dev`, `accrue_admin/e2e`, `accrue_admin/assets/css`  
**Files scanned:** 92  
**Pattern extraction date:** 2026-06-18  
**Project instructions:** no root `AGENTS.md`; no project-local `.codex/skills` or `.agents/skills` directories found.
