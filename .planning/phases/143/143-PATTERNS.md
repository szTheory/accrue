# Phase 143: Recovered-Revenue Analytics Dashboard - Pattern Map

**Mapped:** `$(date +%Y-%m-%d)`
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | component/controller | request-response | `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/router.ex` | route | request-response | `accrue_admin/lib/accrue_admin/router.ex` | exact |
| `accrue/lib/accrue/analytics/dunning.ex` | context | CRUD/analytics | `accrue/lib/accrue/billing/dunning.ex` | role-match |
| `accrue/lib/accrue/webhook/default_handler.ex` | handler | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (component/controller, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`

**Imports and Initialization pattern** (lines 1-28):
```elixir
defmodule AccrueAdmin.Live.Analytics.RecoveryLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, KpiCard, Timeline}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    # Load initial analytics payload via API
    stats = Dunning.recovered_vs_lost()

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:stats, stats)}
  end
```

**Core Render Layout pattern** (lines 30-50):
```elixir
  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs items={[%{label: "Analytics"}, %{label: "Recovery"}]} />
          <p class="ax-eyebrow">Recovery Dashboard</p>
          <h2 class="ax-display">Revenue Recovery</h2>
        </header>

        <section class="ax-kpi-grid">
          <!-- KPI Cards go here -->
        </section>
      </section>
    </AppShell.app_shell>
    """
  end
```

---

### `accrue_admin/lib/accrue_admin/router.ex` (route, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/router.ex`

**Router wire-up** (lines 55-60):
```elixir
          live("/connect/:id", AccrueAdmin.Live.ConnectAccountLive, :show)
          live("/events", AccrueAdmin.Live.EventsLive, :index)
          live("/webhooks", AccrueAdmin.Live.WebhooksLive, :index)
          live("/webhooks/:id", AccrueAdmin.Live.WebhookLive, :show)
          
          # New Section
          scope "/analytics", AccrueAdmin.Live.Analytics do
            live("/recovery", RecoveryLive, :index)
          end
```

---

### `accrue/lib/accrue/analytics/dunning.ex` (context, CRUD/analytics)

**Analog:** `accrue/lib/accrue/billing/dunning.ex` and `accrue_admin/lib/accrue_admin/queries/events.ex`

**Analytics Query structure** (lines 130-160 of analog `dunning.ex`):
```elixir
defmodule Accrue.Analytics.Dunning do
  @moduledoc """
  Analytics boundary encapsulating Ecto queries for MRR recovery over time.
  """
  
  import Ecto.Query

  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Billing.Subscription

  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"

  @doc """
  Sums MRR value based on event types. Both bounds are bound as Ecto query
  parameters (`^since` / `^until`).
  """
  @spec recovered_vs_lost_mrr(keyword()) :: %{recovered_cents: integer(), lost_cents: integer()}
  def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
    # Perform aggregation over `Accrue.Events.Event` `data` field JSONB.
  end
end
```

---

### `accrue/lib/accrue/webhook/default_handler.ex` (handler, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Event Injection Pattern** (lines 780-820):
```elixir
      # Incorporate `mrr_value_cents` and `currency` into the event.data map payload.
      # Data + metadata carry only IDs + bounded enums + integer amounts — no PII.
      Events.record(%{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: updated.id,
        data: %{
          to_status: to_status, 
          source: source,
          mrr_value_cents: mrr_value,
          currency: updated.currency
        }
      })
```

## Shared Patterns

### Centralized App Shell rendering
**Source:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`
**Apply to:** `RecoveryLive` component
All top-level views in `accrue_admin` must wrap their output in the `<AppShell.app_shell>` component and receive layout assigns via a `assign_shell/2` helper.

## No Analog Found

None. All files have concrete existing analogues.

## Metadata

**Analog search scope:** `accrue/lib/accrue/`, `accrue_admin/lib/`
**Files scanned:** 277
**Pattern extraction date:** $(date +%Y-%m-%d)
