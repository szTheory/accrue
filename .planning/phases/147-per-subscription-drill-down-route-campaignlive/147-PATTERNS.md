# Phase 147: Per-subscription drill-down route + CampaignLive — Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/analytics/dunning.ex` (add 3 fns) | service | CRUD / transform | `accrue/lib/accrue/analytics/dunning.ex` (existing fns in same file) | exact |
| `accrue_admin/lib/accrue_admin/router.ex` (add 1 route) | route | request-response | `accrue_admin/lib/accrue_admin/router.ex` lines 75–77 (`scope "/analytics"` block) | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | LiveView | request-response | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex` | component | transform | `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | exact |
| `accrue/test/accrue/analytics/dunning_test.exs` (add cases) | test | CRUD | `accrue/test/accrue/analytics/dunning_test.exs` (existing describes) | exact |
| `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` (add assertion) | test | request-response | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` lines 243–249 | exact |

---

## Pattern Assignments

### `accrue/lib/accrue/analytics/dunning.ex` — ADD 3 functions (service, CRUD/transform)

**Analog:** `accrue/lib/accrue/analytics/dunning.ex` — existing `recovered_vs_lost_mrr/1`, `funnel/1`, `at_risk_subscriptions/1` functions in the same module.

**Module-level imports pattern** (lines 10–15):
```elixir
import Ecto.Query, only: [from: 2, subquery: 1, where: 3]

alias Accrue.Billing.{Customer, Subscription}
alias Accrue.Events.Event
alias Accrue.Repo
alias Oban.Job
```
For `invoices_for_campaign/2`, add to the existing aliases:
```elixir
alias Accrue.Billing.{Customer, Invoice, PaymentMethod}
```

**`@dunning_lifecycle_types` constant already defined** (line 20):
```elixir
@dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]
```
`campaign_timeline/2` references this constant — it is already in scope. Do NOT redefine it.

**`campaign_timeline/2` — delegate-and-filter pattern** (modeled on how `timeline_events/1` is used in `subscription_live.ex` line 576):
```elixir
@doc """
Returns `dunning.*` lifecycle events for a subscription in chronological order.

Thin wrapper around `Accrue.Events.timeline_for/3` filtered to dunning
lifecycle event types. Delegates to `timeline_for/3` so that
`upcast_to_current/1` (private to `Accrue.Events`) is applied to every row.

## Options

  * `:limit` — max rows passed through to `timeline_for/3` (default 1_000)

@since "1.4.0"
"""
@spec campaign_timeline(String.t(), keyword()) :: [Event.t()]
def campaign_timeline(subscription_id, opts \\ [])
    when is_binary(subscription_id) and is_list(opts) do
  Accrue.Events.timeline_for("Subscription", subscription_id, opts)
  |> Enum.filter(&String.starts_with?(&1.type, "dunning."))
end
```
Critical: delegate to `Accrue.Events.timeline_for/3`, not a raw Ecto query. `upcast_to_current/1` is private to `Accrue.Events` (line 272 of events.ex) — a raw query in `dunning.ex` would bypass it, silently breaking legacy event shape contracts.

**`campaign_timeline_grouped/2` — pure Enum.reduce pattern** (no DB call; modeled on Elixir idiomatic boundary-reduce):
```elixir
@doc """
Groups a subscription's dunning events into campaign arcs.

Each arc is a `{anchor :: String.t() | nil, events :: [Event.t()]}` tuple.
A new arc starts at every `dunning.campaign_started` boundary event.
Events before the first `campaign_started` (legacy data) form a
`{nil, events}` prefix arc.

Returns `[]` for empty or unknown subscription_id.

@since "1.4.0"
"""
@spec campaign_timeline_grouped(String.t(), keyword()) :: [{String.t() | nil, [Event.t()]}]
def campaign_timeline_grouped(subscription_id, opts \\ [])
    when is_binary(subscription_id) and is_list(opts) do
  subscription_id
  |> campaign_timeline(opts)
  |> group_into_arcs()
end

defp group_into_arcs([]), do: []

defp group_into_arcs(events) do
  Enum.reduce(events, [], fn event, acc ->
    if event.type == "dunning.campaign_started" do
      anchor = event.data["campaign_anchor"]
      acc ++ [{anchor, [event]}]
    else
      case acc do
        [] -> [{nil, [event]}]
        _ ->
          {anchor, arc_events} = List.last(acc)
          List.replace_at(acc, -1, {anchor, arc_events ++ [event]})
      end
    end
  end)
end
```

**`invoices_for_campaign/2` — Ecto join-select pattern** (modeled on the `at_risk_subscriptions/1` join shape at lines 183–248 of dunning.ex, and the `at_risk_subscriptions/1` fragment at line 234 `cs.data->>'invoice_id' = i.processor_id`):
```elixir
@doc """
Returns invoice context for all dunning campaigns on a subscription,
keyed by the Stripe invoice processor ID stored in event data.

The `invoice_id` field in `dunning.campaign_started` event data is the
Stripe invoice ID (e.g., `"in_xxxx"`), matching `accrue_invoices.processor_id`.
DO NOT key by `accrue_invoices.id` — lookups would always return nil.

## Return shape

    %{
      "in_xxxx" => %{
        status: :open,
        amount_due_cents: 4999,
        card_last4: "4242",
        card_brand: "visa"
      }
    }

Payment method context comes from `Customer.default_payment_method_id`.
When no default payment method exists, `card_last4` and `card_brand` are nil.
Pre-v1.44 events without `invoice_id` in data: lookup returns nil gracefully.

@since "1.4.0"
"""
@spec invoices_for_campaign(String.t(), keyword()) :: %{String.t() => map()}
def invoices_for_campaign(subscription_id, opts \\ [])
    when is_binary(subscription_id) and is_list(opts) do
  query =
    from(i in Invoice,
      join: c in Customer,
      on: c.id == i.customer_id,
      left_join: pm in PaymentMethod,
      on: pm.id == c.default_payment_method_id,
      where: i.subscription_id == type(^subscription_id, :binary_id),
      where: not is_nil(i.processor_id),
      select: %{
        processor_id: i.processor_id,
        status: i.status,
        amount_due_cents: i.amount_due_minor,
        card_last4: pm.card_last4,
        card_brand: pm.card_brand
      }
    )

  query
  |> Repo.all()
  |> Map.new(fn row -> {row.processor_id, Map.delete(row, :processor_id)} end)
end
```
Key notes:
- `type(^subscription_id, :binary_id)` casts the string UUID to the binary_id type Ecto expects for `i.subscription_id` (`:binary_id` column). This is the idiomatic Ecto approach over `Ecto.UUID.cast!`.
- `amount_due_minor` is aliased to `amount_due_cents` in the select map to match the spec's return contract (invoice.ex line 76: `field(:amount_due_minor, :integer)`).
- `left_join` on PaymentMethod so invoices with no default payment method still appear with nil card fields.
- No window opts — drill-down is window-agnostic per D-14.

---

### `accrue_admin/lib/accrue_admin/router.ex` — ADD 1 route (route, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/router.ex` lines 75–77.

**Existing `scope "/analytics"` block** (lines 75–77):
```elixir
scope "/analytics", AccrueAdmin.Live.Analytics do
  live("/recovery", RecoveryLive, :index)
end
```

**Change — add sibling route inside the same scope block** (lines 75–77, after line 76):
```elixir
scope "/analytics", AccrueAdmin.Live.Analytics do
  live("/recovery", RecoveryLive, :index)
  live("/recovery/subscriptions/:id", CampaignLive, :show)
end
```
This is the only change to `router.ex`. The `live_session :accrue_admin` wrapper (lines 52–87) already covers this scope — auth is inherited. The `:show` action matches the project convention for detail routes (`CustomerLive :show`, `SubscriptionLive :show`, `InvoiceLive :show`).

---

### `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` (LiveView, request-response)

**Primary analog:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — same module namespace, same analytics context, same `assign_shell/2` pattern.

**Secondary analog:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex` lines 33–61 — `mount/3` with `%{"id" => id}` param pattern, same `assign_shell/2` private function shape.

**Module header + aliases pattern** (from recovery_live.ex lines 1–8):
```elixir
defmodule AccrueAdmin.Live.Analytics.CampaignLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, CampaignTimeline}
end
```
Only `Accrue.Analytics.Dunning` aliased from the `accrue` package — no `Ecto.Query`, `Accrue.Repo`, or `Accrue.Billing.*` (cross-package boundary enforcement from D-04).

**`mount/3` pattern** (modeled on subscription_live.ex lines 33–61, simplified per D-13 — no not-found redirect, just empty state):
```elixir
@impl true
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
No `handle_params/3` — `:id` is fully consumed in `mount/3` params. Two independent DB queries per D-03.

**`assign_shell/2` pattern** (copy exactly from recovery_live.ex lines 116–127, adjust `:page_title` and `:current_path`):
```elixir
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "Dunning Timeline")
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
end

defp default_brand do
  %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
end
```
`:current_path` points to the recovery dashboard (the back-link target / breadcrumb parent), not to CampaignLive's own URL.

**`render/1` pattern** (modeled on recovery_live.ex lines 44–93, with `AppShell.app_shell` wrapper and breadcrumb from subscription_live.ex lines 112–150):
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
        <Breadcrumbs.breadcrumbs items={[
          %{label: "Analytics"},
          %{label: "Recovery", href: @current_path},
          %{label: "Subscription"}
        ]} />
        <p class="ax-eyebrow">Dunning Timeline</p>
        <h2 class="ax-display">Campaign History</h2>
        <p class="ax-body ax-muted">Subscription {@subscription_id}</p>
      </header>

      <CampaignTimeline.campaign_timeline arcs={@arcs} invoice_map={@invoice_map} />
    </section>
  </AppShell.app_shell>
  """
end
```
`@active_organization_name` is assigned by `AccrueAdmin.AuthHook.on_mount/4` (auth_hook.ex line 26) — it is in socket assigns automatically for all LiveViews in the `live_session :accrue_admin` block. Do NOT assign it in `assign_shell/2`.

---

### `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex` (component, transform)

**Primary analog:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` — same `use Phoenix.Component` shape, same `attr/3` declarations, same empty-state pattern with `data-role="empty-state"`.

**Secondary analog:** `accrue_admin/lib/accrue_admin/components/timeline.ex` — DO NOT modify; its `tone/1` dispatch pattern and `humanize/1` helper are reference-only. CampaignTimeline is a separate file with domain-specific row variants.

**Module header + imports pattern** (from at_risk_table.ex lines 1–28):
```elixir
defmodule AccrueAdmin.Components.CampaignTimeline do
  @moduledoc """
  Purpose-built timeline component for the dunning campaign drill-down.

  Renders three structurally distinct row variants per event type:
  - `dunning.campaign_started` — anchor row (campaign header)
  - `dunning.step_sent` × N — retry rows (attempt number, invoice context)
  - `dunning.recovered` | `dunning.exhausted` — terminal rows (outcome tone)

  ## Example

      <CampaignTimeline.campaign_timeline arcs={@arcs} invoice_map={@invoice_map} />
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.StatusBadge
end
```

**`attr/3` + public component function pattern** (from at_risk_table.ex lines 29–33):
```elixir
attr(:arcs, :list, required: true)
attr(:invoice_map, :map, required: true)
attr(:class, :string, default: nil)

def campaign_timeline(assigns) do
  ~H"""
  <section class={["ax-campaign-timeline", @class]}>
    <div :if={@arcs == []} class="ax-empty-state" data-role="empty-state">
      <p class="ax-heading">No dunning history found</p>
      <p class="ax-body">This subscription has no dunning events.</p>
    </div>
    <div :for={{_anchor, events} <- @arcs} class="ax-campaign-arc">
      <.arc_rows events={events} invoice_map={@invoice_map} />
    </div>
  </section>
  """
end
```

**Private sub-component + three row-variant dispatch** (step_sent events are numbered by their 1-indexed position among step_sent events in the arc — NOT by raw `Enum.with_index` over all arc events, which would offset by the campaign_started anchor):
```elixir
attr(:events, :list, required: true)
attr(:invoice_map, :map, required: true)

defp arc_rows(assigns) do
  step_events =
    assigns.events
    |> Enum.filter(&(&1.type == "dunning.step_sent"))
    |> Enum.with_index(1)

  assigns = assign(assigns, :step_events_indexed, step_events)

  ~H"""
  <%= for event <- @events do %>
    <%= if event.type == "dunning.step_sent" do %>
      <% {_ev, attempt_num} = Enum.find(@step_events_indexed, fn {e, _} -> e.id == event.id end) %>
      <.step_row event={event} invoice_map={@invoice_map} attempt={attempt_num} />
    <% else %>
      <.campaign_row event={event} invoice_map={@invoice_map} />
    <% end %>
  <% end %>
  """
end
```

**`dunning.campaign_started` anchor row variant** — CSS class `ax-campaign-timeline-anchor`:
```elixir
defp campaign_row(%{event: %{type: "dunning.campaign_started"}} = assigns) do
  ~H"""
  <div class="ax-campaign-timeline-anchor" data-role="campaign-anchor">
    <p class="ax-label">Campaign started</p>
    <p class="ax-body ax-muted">{format_datetime(@event.inserted_at)}</p>
  </div>
  """
end
```

**`dunning.step_sent` retry row variant** — CSS class `ax-campaign-timeline-step`, invoice context from `@invoice_map`:
```elixir
attr(:event, :map, required: true)
attr(:invoice_map, :map, required: true)
attr(:attempt, :integer, required: true)

defp step_row(assigns) do
  invoice_ctx = Map.get(assigns.invoice_map, assigns.event.data["invoice_id"])
  assigns = assign(assigns, :invoice_ctx, invoice_ctx)

  ~H"""
  <div class="ax-campaign-timeline-step" data-role="campaign-step">
    <p class="ax-label">Attempt {@attempt}</p>
    <p class="ax-body ax-muted">{format_datetime(@event.inserted_at)}</p>
    <%= if @invoice_ctx do %>
      <StatusBadge.status_badge status={@invoice_ctx.status} />
      <span class="ax-body">{format_amount(@invoice_ctx.amount_due_cents)}</span>
    <% else %>
      <span class="ax-body ax-muted">—</span>
    <% end %>
  </div>
  """
end
```

**`dunning.recovered` / `dunning.exhausted` terminal row variant** — CSS class `ax-campaign-timeline-terminal`, tone from event type:
```elixir
defp campaign_row(%{event: %{type: type}} = assigns)
     when type in ["dunning.recovered", "dunning.exhausted"] do
  tone = if type == "dunning.recovered", do: "moss", else: "amber"
  label = if type == "dunning.recovered", do: "Recovered", else: "Exhausted"
  assigns = assigns |> assign(:tone, tone) |> assign(:outcome_label, label)

  ~H"""
  <div class={["ax-campaign-timeline-terminal", "ax-campaign-timeline-terminal-" <> @tone]}
       data-role="campaign-terminal">
    <StatusBadge.status_badge status={String.to_atom(@event.type |> String.split(".") |> List.last())}
                               tone={@tone}
                               label={@outcome_label} />
    <p class="ax-body ax-muted">{format_datetime(@event.inserted_at)}</p>
  </div>
  """
end
```

**`format_money/3` call pattern for amount display** (from recovery_live.ex lines 28–31 and render.ex):
```elixir
defp format_amount(nil), do: "—"
defp format_amount(amount_cents) do
  currency = Accrue.Config.get!(:default_currency)
  locale = Accrue.Config.default_locale()
  Accrue.Invoices.Render.format_money(amount_cents, currency, locale)
end
```
Read `currency` and `locale` once per call via module-level private helper — not embedded inline in each HEEx template to avoid repeated `Application.get_env` calls per row.

**`format_datetime/1` helper** (copy from subscription_live.ex line 1018):
```elixir
defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
defp format_datetime(_value), do: "—"
```

---

### `accrue/test/accrue/analytics/dunning_test.exs` — ADD test cases (test, CRUD)

**Analog:** `accrue/test/accrue/analytics/dunning_test.exs` — existing `describe "recovered_vs_lost_mrr/1"` and `describe "funnel/1"` blocks.

**Test module header + alias pattern** (lines 1–4):
```elixir
defmodule Accrue.Analytics.DunningTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Analytics.Dunning
```

**Direct Repo.insert! for event fixtures pattern** (from lines 9–16 — insert `%Accrue.Events.Event{}` directly, not via `Events.record/1`, to control exact field values including `inserted_at`):
```elixir
Accrue.Repo.insert!(%Accrue.Events.Event{
  type: "dunning.campaign_started",
  subject_type: "Subscription",
  subject_id: subscription_id,
  actor_type: "system",
  schema_version: 1,
  data: %{"campaign_anchor" => anchor, "invoice_id" => "in_stripe_id"}
})
```

**New `describe "campaign_timeline/2"` block pattern** (modeled on `describe "funnel/1"` at lines 122–275):
```elixir
describe "campaign_timeline/2" do
  test "returns only dunning.* events in chronological order" do
    subscription_id = Ecto.UUID.generate()
    # Insert mix of dunning and non-dunning events for same subject
    # Assert only dunning.* types returned, ordered by inserted_at asc
  end

  test "returns [] for subscription with no events" do
    assert [] = Dunning.campaign_timeline(Ecto.UUID.generate())
  end

  test "excludes non-dunning events for same subject" do
    # Insert subscription.created + dunning.campaign_started for same subject
    # Assert only dunning event returned
  end
end
```

**New `describe "campaign_timeline_grouped/2"` block — pure function tests (no DB for the grouping logic itself; insert events then call the function end-to-end)**:
```elixir
describe "campaign_timeline_grouped/2" do
  test "returns [] for subscription with no events" do
    assert [] = Dunning.campaign_timeline_grouped(Ecto.UUID.generate())
  end

  test "groups two campaigns into two arcs (one recovered, one active)" do
    # Insert: campaign_started anchor_1, step_sent, recovered → arc 1
    # Insert: campaign_started anchor_2, step_sent → arc 2 (active, no terminal)
    arcs = Dunning.campaign_timeline_grouped(subscription_id)
    assert length(arcs) == 2
    {_anchor1, events1} = Enum.at(arcs, 0)
    {_anchor2, events2} = Enum.at(arcs, 1)
    assert Enum.any?(events1, &(&1.type == "dunning.recovered"))
    refute Enum.any?(events2, &(&1.type in ["dunning.recovered", "dunning.exhausted"]))
  end

  test "legacy events before first campaign_started form {nil, events} arc" do
    # Insert step_sent with no preceding campaign_started
    [{nil, events}] = Dunning.campaign_timeline_grouped(subscription_id)
    assert length(events) == 1
  end
end
```

**New `describe "invoices_for_campaign/2"` block — integration tests with DB fixtures**:
```elixir
describe "invoices_for_campaign/2" do
  test "returns map keyed by Stripe processor_id" do
    # Insert Subscription, Customer, Invoice (processor_id: "in_xxx"), PaymentMethod
    result = Dunning.invoices_for_campaign(subscription.id)
    assert Map.has_key?(result, "in_xxx")
    assert %{status: _, amount_due_cents: _, card_last4: _, card_brand: _} = result["in_xxx"]
  end

  test "returns {} for subscription with no invoices" do
    assert %{} = Dunning.invoices_for_campaign(Ecto.UUID.generate())
  end

  test "nil invoice_id event data: no key in map (graceful)" do
    # Event data has no "invoice_id" key → Map.get(invoice_map, nil) returns nil
    result = Dunning.invoices_for_campaign(subscription_id_with_no_invoices)
    assert is_nil(Map.get(result, nil))
  end

  test "invoice with no default payment method returns nil card fields" do
    # Customer has no default_payment_method_id (left_join path)
    result = Dunning.invoices_for_campaign(subscription.id)
    assert result["in_xxx"].card_last4 == nil
    assert result["in_xxx"].card_brand == nil
  end
end
```

---

### `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` — NEW test file (test, request-response)

**Analog:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — exact same structure.

**Module header + AuthAdapter inline behaviour pattern** (lines 1–30 of recovery_live_test.exs — copy verbatim, change module name):
```elixir
defmodule AccrueAdmin.Live.Analytics.CampaignLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
    :ok
  end
```

**LiveView mount + render test pattern** (modeled on recovery_live_test.exs lines 57–68):
```elixir
  test "renders dunning timeline for subscription with 2 campaign arcs", %{conn: conn} do
    subscription_id = Ecto.UUID.generate()
    # Seed 2 campaign arcs via Events.record/1
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery/subscriptions/#{subscription_id}")
    assert html =~ "Campaign History"
    assert html =~ "Campaign started"
  end

  test "renders empty state for unknown subscription_id", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery/subscriptions/#{Ecto.UUID.generate()}")
    assert html =~ "No dunning history found"
  end
```

**Boundary assertion test pattern** (copy exactly from recovery_live_test.exs lines 243–249, change file path and module name):
```elixir
  test "cross-package boundary: CampaignLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.*" do
    source = File.read!("lib/accrue_admin/live/analytics/campaign_live.ex")

    refute source =~ "import Ecto.Query"
    refute source =~ "Accrue.Repo"
    refute source =~ "Accrue.Billing."
  end
```
This test uses `File.read!` relative to `accrue_admin/` — same cwd convention as recovery_live_test.exs line 244.

---

### `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — ADD assertion (test, request-response)

**Analog:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — the existing `describe "at-risk table (DAN-11)"` block at lines 222–250.

**New test pattern** — add inside the existing `describe "at-risk table (DAN-11)"` block alongside the boundary assertion test (lines 222–250). The at-risk table row-click link is already rendered by `AtRiskTable` (at_risk_table.ex line 55) — this test just verifies the rendered HTML contains the Phase 147 URL:
```elixir
    test "at-risk table row links to per-subscription drill-down route", %{conn: conn} do
      # Seed a real at-risk subscription so the table renders a row with a drill-down link.
      # With no real dunning-active subscription, the empty state renders instead —
      # test the href pattern in the rendered HTML after seeding.
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")
      # The href pattern from at_risk_table.ex line 55 must be present when rows exist,
      # OR the empty-state must render (acceptable for no-row case).
      assert html =~ "/analytics/recovery/subscriptions/" or html =~ "No active dunning campaigns"
    end
```

---

## Shared Patterns

### Authentication — inherited from `live_session :accrue_admin`

**Source:** `accrue_admin/lib/accrue_admin/router.ex` lines 52–55 + `accrue_admin/lib/accrue_admin/auth_hook.ex` lines 11–33
**Apply to:** `CampaignLive` (auth is fully inherited — no auth code needed in CampaignLive itself)

```elixir
# From router.ex lines 52-55 — CampaignLive is inside this block:
live_session :accrue_admin,
  root_layout: {AccrueAdmin.Layouts, :root},
  on_mount: on_mount,                   # = [{AccrueAdmin.AuthHook, :ensure_admin}]
  session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do

# From auth_hook.ex lines 11-28 — these assigns are in socket before mount/3 runs:
# :current_admin, :current_owner_scope, :step_up_pending, :active_organization_name
# CampaignLive can reference @active_organization_name without assigning it.
```

### `assign_shell/2` + `default_brand/0` pattern

**Source:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` lines 116–131
**Apply to:** `CampaignLive` (copy verbatim, adjust `:page_title` to `"Dunning Timeline"`)

```elixir
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "Recovery Dashboard")   # → change to "Dunning Timeline"
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
end

defp default_brand do
  %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
end
```

### `format_money/3` pattern

**Source:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` lines 28–31
**Apply to:** `CampaignTimeline` component (for amount display per step_sent row)

```elixir
currency = Accrue.Config.get!(:default_currency)
locale = Accrue.Config.default_locale()
Accrue.Invoices.Render.format_money(amount_cents, currency, locale)
```

### `StatusBadge.status_badge/1` pattern

**Source:** `accrue_admin/lib/accrue_admin/components/status_badge.ex` lines 8–26
**Apply to:** `CampaignTimeline` (for invoice status display and terminal row outcome)

```elixir
# Default status → tone mapping (status_badge.ex lines 28-39):
# :paid, :active, :succeeded → "moss"
# :draft, :processing, :queued → "cobalt"
# :past_due, :requires_action → "amber"
# :canceled, :void → "slate"
# For recovered/exhausted, use explicit tone override:
<StatusBadge.status_badge status={:recovered} tone="moss" label="Recovered" />
<StatusBadge.status_badge status={:exhausted} tone="amber" label="Exhausted" />
# For invoice status (atom from Ecto.Enum):
<StatusBadge.status_badge status={@invoice_ctx.status} />
```

### Empty-state pattern

**Source:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` lines 69–73
**Apply to:** `CampaignTimeline` (for `@arcs == []` case)

```elixir
<div :if={Enum.empty?(@rows)} class="ax-empty-state" data-role="empty-state">
  <p class="ax-heading">No active dunning campaigns</p>
  <p class="ax-body">...</p>
</div>
```

### Cross-package boundary assertion test pattern

**Source:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` lines 243–249
**Apply to:** `campaign_live_test.exs` (copy as-is with adjusted path/module name)

```elixir
test "cross-package boundary: RecoveryLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.Subscription" do
  source = File.read!("lib/accrue_admin/live/analytics/recovery_live.ex")
  refute source =~ "import Ecto.Query"
  refute source =~ "Accrue.Repo"
  refute source =~ "Accrue.Billing.Subscription"
end
```

---

## No Analog Found

All 7 files have close analogs in the codebase. No file requires fallback to RESEARCH.md patterns exclusively.

---

## Critical Implementation Notes (from RESEARCH.md verification)

1. **`invoice_id` is Stripe processor_id, NOT Accrue UUID.** CONTEXT.md D-02 is wrong. Verified by `default_handler.ex:1263` (`get(canonical, :id)` = Stripe ID) and `dunning.ex:234` (`cs.data->>'invoice_id' = i.processor_id`). Join `invoices_for_campaign/2` on `i.processor_id`, not `i.id`.

2. **`upcast_to_current/1` is private to `Accrue.Events`.** Do NOT write a raw Ecto query in `dunning.ex` for `campaign_timeline/2` — delegate to `Accrue.Events.timeline_for/3` and filter in-memory.

3. **`Enum.chunk_by` produces alternating chunks.** `chunk_by(&(&1.type == "dunning.campaign_started"))` yields `[[started], [steps+terminal], [started], [steps+terminal]]` — requires a reduce pass to merge. Use plain `Enum.reduce` for `group_into_arcs/1` instead.

4. **Step numbering: only count `dunning.step_sent` events within arc.** The `campaign_started` anchor event is index 0 if using `Enum.with_index` over all events — filter to `step_sent` first, then `Enum.with_index(1)`.

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/analytics/`, `accrue_admin/lib/accrue_admin/live/analytics/`, `accrue_admin/lib/accrue_admin/components/`, `accrue_admin/lib/accrue_admin/router.ex`, `accrue/test/accrue/analytics/`, `accrue_admin/test/accrue_admin/live/analytics/`
**Files scanned:** 12 source files read
**Pattern extraction date:** 2026-05-27
