# Phase 146: At-risk query + at-risk table + last-failure enrichment — Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 9 (5 source files + 4 test files)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/billing/query.ex` | query-composer | CRUD | same file — `dunning_sweep_candidates/2` | exact |
| `accrue/lib/accrue/analytics/dunning.ex` | analytics-service | CRUD + batch | same file — `funnel/1`, `apply_window/2` | exact |
| `accrue/lib/accrue/webhook/default_handler.ex` | webhook-handler | event-driven | same file — `emit_campaign_started/1` | exact |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | LiveView | request-response | same file — current `handle_params/3` | exact |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | component | request-response | `funnel_chart.ex` (Phoenix.Component, article/dl shape) | role-match |
| `accrue/test/accrue/billing/query_test.exs` | test | CRUD | same file — `dunning_sweep_candidates/1` test (not yet present; existing predicate tests) | exact |
| `accrue/test/accrue/analytics/dunning_test.exs` | test | CRUD | same file — `funnel/1` + `recovered_vs_lost_mrr/1` test structure | exact |
| `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` | test | event-driven | same file — `campaign_started observability (DUN-08)` describe block | exact |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | test | request-response | same file — `window parameter (DAN-10)` describe block | exact |

---

## Pattern Assignments

### `accrue/lib/accrue/billing/query.ex` (query-composer, CRUD)

**Analog:** `dunning_sweep_candidates/2` in the same file — lines 133–145 (read confirmed).

**Imports pattern** (lines 1–26):
```elixir
defmodule Accrue.Billing.Query do
  import Ecto.Query

  alias Accrue.Billing.Subscription
```
No per-function `import Ecto.Query` — the module-level `import Ecto.Query` gives every function access to `from/2`, `where/3`, `is_nil/1`, etc.

**Core pattern — `dunning_sweep_candidates/2`** (lines 133–145):
```elixir
@spec dunning_sweep_candidates(pos_integer(), Ecto.Queryable.t()) :: Ecto.Query.t()
def dunning_sweep_candidates(grace_days, query \\ Subscription)
    when is_integer(grace_days) and grace_days > 0 do
  cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)

  from(s in query,
    where:
      s.status == :past_due and
        not is_nil(s.past_due_since) and
        s.past_due_since < ^cutoff and
        is_nil(s.dunning_sweep_attempted_at)
  )
end
```

**New function to add** — replicate the single-predicate pattern from `paused/1` (lines 122–126):
```elixir
@doc "Subscriptions currently in an active dunning campaign (anchor column is non-nil)."
@spec in_active_dunning_campaign(Ecto.Queryable.t()) :: Ecto.Query.t()
def in_active_dunning_campaign(query \\ Subscription) do
  from(s in query, where: not is_nil(s.dunning_campaign_started_at))
end
```
Place immediately after `dunning_sweep_candidates/2` (before the module `end`).

---

### `accrue/lib/accrue/analytics/dunning.ex` (analytics-service, CRUD + batch)

**Analog:** `funnel/1` and `apply_window/2` in the same file — lines 1–159 (full file read confirmed).

**Current imports + aliases** (lines 10–18):
```elixir
import Ecto.Query, only: [from: 2, subquery: 1, where: 3]

alias Accrue.Events.Event
alias Accrue.Repo
```

**Required import extension for `at_risk_subscriptions/1`** — add these functions to the `only:` list and the `Oban.Job` alias:
```elixir
import Ecto.Query, only: [from: 2, subquery: 1, where: 3, left_join: 5, select: 3, fragment: 1, min: 1]

alias Accrue.Billing.{Customer, Invoice, Subscription}
alias Accrue.Events.Event
alias Accrue.Repo
alias Oban.Job
```
(Exact arity of `left_join`, `select`, `fragment` varies — use `import Ecto.Query` without `only:` restriction if the list gets unwieldy; `funnel/1` already shows selective import is the existing style.)

**Core pattern — `funnel/1`** (lines 117–143) — the public function + `Repo.one` + `|| default` fallback:
```elixir
def funnel(opts \\ []) when is_list(opts) do
  per_campaign =
    from(e in Event,
      where: e.type in ^@dunning_lifecycle_types,
      group_by: [...],
      select: %{...}
    )
    |> apply_window(opts)

  query =
    from(c in subquery(per_campaign),
      select: %{entered: count(), ...}
    )

  Repo.one(query) || %{entered: 0, ...}
end
```
`at_risk_subscriptions/1` is flat (no two-level subquery). Use `Repo.all` not `Repo.one`. No `|| default` fallback needed (empty list is a valid result).

**`apply_window/2` gotcha — do NOT reuse for Subscription queries** (lines 145–159):
```elixir
# WRONG for at_risk_subscriptions/1 — [e] binding maps to Subscription.inserted_at, not dunning_campaign_started_at
defp maybe_since(query, %DateTime{} = since),
  do: where(query, [e], e.inserted_at >= ^since)
```

**New private helper to add** — campaign-specific window, placed alongside existing `apply_window/2`:
```elixir
defp apply_campaign_window(query, opts) do
  query
  |> maybe_since_campaign(opts[:since])
  |> maybe_until_campaign(opts[:until])
end

defp maybe_since_campaign(query, %DateTime{} = since),
  do: where(query, [s], s.dunning_campaign_started_at >= ^since)

defp maybe_since_campaign(query, _), do: query

defp maybe_until_campaign(query, %DateTime{} = until),
  do: where(query, [s], s.dunning_campaign_started_at <= ^until)

defp maybe_until_campaign(query, _), do: query
```

**Oban.Job args-fragment pattern** from `accrue/lib/accrue/dunning/engine/oban.ex` lines 77–82:
```elixir
from(j in Oban.Job,
  where: j.worker == "Accrue.Workers.DunningStep",
  where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub.id),
  where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)
)
```
For the LEFT JOIN in `at_risk_subscriptions/1`, `iso_anchor` must be computed in Elixir before the query:
```elixir
iso_anchor = DateTime.to_iso8601(s.dunning_campaign_started_at)
# But s is a binding, not an Elixir value — use fragment on both sides:
# fragment("? ->> 'campaign_started_at' = to_char(?, 'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"')", j.args, s.dunning_campaign_started_at)
# Simpler: compute iso_anchor per-row via fragment using Postgres to_char or ::text cast.
# See RESEARCH.md Pitfall 4 for the exact ISO8601 format the DunningStep worker stores.
```

**NOT EXISTS correlated subquery pattern** — use `fragment/1` (not Ecto `subquery/1`):
```elixir
# From RESEARCH.md Pitfall 5:
where: fragment(
  "NOT EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ? AND inserted_at >= ?)",
  s.id,
  s.dunning_campaign_started_at
)
```

**`days_in_campaign` Fake-clock-safe pattern** (from RESEARCH.md Pattern 6 + `query.ex` line 99):
```elixir
now = Accrue.Clock.utc_now()
# ... in the select:
fragment("EXTRACT(EPOCH FROM (? - ?))/86400", ^now, s.dunning_campaign_started_at)
```

---

### `accrue/lib/accrue/webhook/default_handler.ex` (webhook-handler, event-driven)

**Analog:** `emit_campaign_started/1` and `maybe_start_dunning_campaign/2` in the same file — lines 1224–1272 (read confirmed).

**Current call site** (line 1236):
```elixir
emit_campaign_started(sub)
opts = [invoice_id: get(canonical, :id)]
Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)
```

**Current function body** (lines 1256–1272):
```elixir
defp emit_campaign_started(%Subscription{} = sub) do
  step_count = length(Accrue.Config.dunning_campaign_steps())

  Events.record(%{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub.id,
    data: %{step_count: step_count}
  })

  Accrue.Telemetry.Ops.emit(:dunning_campaign_started, %{count: 1}, %{
    subscription_id: sub.id,
    step_count: step_count
  })

  :ok
end
```

**Modified call site** — thread `canonical` as second arg (D-04):
```elixir
emit_campaign_started(sub, canonical)   # <-- pass canonical
opts = [invoice_id: get(canonical, :id)]
Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)
```

**Modified function signature + data map** (D-04):
```elixir
defp emit_campaign_started(%Subscription{} = sub, canonical) do
  step_count = length(Accrue.Config.dunning_campaign_steps())

  Events.record(%{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub.id,
    data: %{step_count: step_count, invoice_id: get(canonical, :id)}  # <-- ADDED invoice_id
  })

  Accrue.Telemetry.Ops.emit(:dunning_campaign_started, %{count: 1}, %{
    subscription_id: sub.id,
    step_count: step_count
  })

  :ok
end
```
The `get/2` import is already active in the surrounding function scope (`import` for `get` is at the `reduce_invoice` level). Telemetry metadata is unchanged — no PII, no `invoice_id` in telemetry (only in the ledger event data).

---

### `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (LiveView, request-response)

**Analog:** Current `handle_params/3` and `render/1` in the same file — lines 1–128 (full file read confirmed).

**Current alias block** (lines 7–8):
```elixir
alias Accrue.Analytics.Dunning
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FunnelChart, KpiCard, WindowSelector}
```
Add `AtRiskTable` to the Components alias after the component file is created.

**Current `handle_params/3`** (lines 16–39) — extension pattern:
```elixir
def handle_params(params, _uri, socket) do
  window = parse_window(params["window"])
  {since, until} = window_bounds(window)

  stats = Dunning.recovered_vs_lost_mrr(since: since, until: until)
  funnel = Dunning.funnel(since: since, until: until)
  # ... formatting ...

  # Phase 146 ADD (D-13, D-14, D-15):
  at_risk = Dunning.at_risk_subscriptions(since: since, until: until)

  {:noreply,
   socket
   |> assign(:window, window)
   |> assign(:stats, stats)
   |> assign(:funnel, funnel)
   |> assign(:recovered_str, recovered_str)
   |> assign(:exhausted_str, exhausted_str)
   |> assign(:at_risk, at_risk)}   # <-- ADDED
end
```
Constraint (D-14): Do NOT add `import Ecto.Query`, `alias Accrue.Repo`, or `alias Accrue.Billing.Subscription` to this file. All data loading goes through `Dunning.*`.

**Current `render/1`** (lines 42–88) — extension point is after `<FunnelChart .../>` (line 80–84), before `</section>`:
```elixir
<FunnelChart.funnel_chart
  entered={@funnel.entered}
  recovered={@funnel.recovered}
  exhausted={@funnel.exhausted}
  active={@funnel.active}
/>

<%# Phase 146 ADD — at-risk table below funnel (DAN-11): %>
<AtRiskTable.at_risk_table rows={@at_risk} base_path={@current_path} />
```

---

### `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` (component, request-response)

**Analog:** `funnel_chart.ex` — lines 1–106 (full file read confirmed). Best structural match: `use Phoenix.Component`, `attr` declarations, `~H` template with `<article>` root, `<dl>` legend. No state, no LiveComponent.

**Module skeleton from `funnel_chart.ex`** (lines 1–36):
```elixir
defmodule AccrueAdmin.Components.FunnelChart do
  use Phoenix.Component

  attr(:entered, :integer, required: true)
  # ...
  attr(:class, :string, default: nil)

  def funnel_chart(assigns) do
    ~H"""
    <article class={["ax-card", "ax-funnel-chart", @class]}>
      ...
    </article>
    """
  end
end
```

**`AtRiskTable` skeleton — copy this structure**:
```elixir
defmodule AccrueAdmin.Components.AtRiskTable do
  @moduledoc """
  Table of subscriptions currently in an active dunning campaign.
  Renders below the Recovery Funnel on /billing/analytics/recovery.
  """

  use Phoenix.Component

  attr(:rows, :list, required: true)
  attr(:base_path, :string, required: true)
  attr(:class, :string, default: nil)

  def at_risk_table(assigns) do
    ~H"""
    <article class={["ax-card", "ax-at-risk-table", @class]}>
      <header class="ax-at-risk-header">
        <p class="ax-label">At-Risk Subscriptions</p>
        <span class="ax-at-risk-count-chip"><%= length(@rows) %> in active campaign</span>
      </header>
      ...
      <table class="ax-at-risk-grid">
        <thead>
          <tr>
            <th scope="col" class="ax-label">Customer</th>
            <th scope="col" class="ax-label">Days in campaign</th>
            <th scope="col" class="ax-label">Step</th>
            <th scope="col" class="ax-label">Next step ETA</th>
            <th scope="col" class="ax-label">Last failure</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows}>
            ...
          </tr>
        </tbody>
      </table>
    </article>
    """
  end
end
```
The empty-state pattern follows `data_table.ex` (line 154): `<div :if={Enum.empty?(@rows)} class="ax-card ax-at-risk-table-empty">`. Use `"—"` literal for nil `next_step_eta` and nil `failure_reason` — same honest-default as all pre-v1.44 fields in this module.

---

## Test Pattern Assignments

### `accrue/test/accrue/billing/query_test.exs` (extend existing file)

**Analog:** existing predicate tests in the same file — lines 66–143 (read confirmed).

**Test module header + setup** (lines 1–64 already present — extend, do not duplicate):
```elixir
# Existing: use Accrue.BillingCase, async: false
# Existing setup block inserts subscriptions with various statuses (no dunning_campaign_started_at column set)

# Add to setup: one subscription with dunning_campaign_started_at set
now = Accrue.Clock.utc_now()
{:ok, dunning_sub} =
  %Subscription{}
  |> Subscription.changeset(%{
    customer_id: customer.id,
    processor: "fake",
    processor_id: "sub_dunning_active",
    status: :past_due,
    dunning_campaign_started_at: now
  })
  |> Repo.insert()
```

**Test case pattern** (copy from `dunning_sweep_candidates/1` style — not yet present but same shape as lines 66–84):
```elixir
test "in_active_dunning_campaign/1 returns subscriptions with non-nil dunning_campaign_started_at" do
  rows = Query.in_active_dunning_campaign() |> Repo.all()
  assert Enum.any?(rows, &(&1.processor_id == "sub_dunning_active"))
  refute Enum.any?(rows, &is_nil(&1.dunning_campaign_started_at))
end

test "in_active_dunning_campaign/1 composes with an existing query" do
  result =
    from(s in Subscription, where: s.status == :past_due)
    |> Query.in_active_dunning_campaign()
    |> Repo.all()

  assert Enum.all?(result, &(not is_nil(&1.dunning_campaign_started_at)))
end
```

---

### `accrue/test/accrue/analytics/dunning_test.exs` (extend) or new `at_risk_subscriptions_test.exs`

**Analog:** existing `funnel/1` describe block in the same file — lines 122–275 (full file read confirmed).

**Key distinction:** Existing `dunning_test.exs` uses `use Accrue.RepoCase, async: false` (line 2). The at_risk tests require `use Oban.Testing, repo: Accrue.TestRepo` (for Oban job queries). Use a **new file** `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs` with:
```elixir
defmodule Accrue.Analytics.AtRiskSubscriptionsTest do
  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Analytics.Dunning
  alias Accrue.Billing.{Customer, Subscription}
```

**Projection-lag race scenario pattern** (from RESEARCH.md test structure):
```elixir
test "excludes subscription whose most recent dunning event is recovered (projection-lag race)" do
  # 1. subscription with non-nil dunning_campaign_started_at
  # 2. dunning.campaign_started event for it
  # 3. dunning.recovered event (inserted_at >= dunning_campaign_started_at)
  # assert result does NOT contain this subscription
end
```

**ETA nil fallback pattern** (from RESEARCH.md test structure):
```elixir
test "next_step_eta is nil when no pending Oban job exists" do
  # 1. subscription with non-nil dunning_campaign_started_at
  # 2. dunning.campaign_started event (post-v1.44 with invoice_id)
  # 3. NO Oban jobs inserted
  # assert hd(at_risk_subscriptions()).next_step_eta == nil
end
```

**Pre-v1.44 honest-default pattern** (mirrors `safe_cast` test at line 49):
```elixir
@tag :pre_v144
test "pre-v1.44 campaign_started event (no invoice_id key) returns nil failure_reason" do
  # dunning.campaign_started event with data %{step_count: 3} (no invoice_id)
  # assert hd(at_risk_subscriptions()).failure_reason == nil
end
```

**Window-filter test** — use the same `inserted_at` override pattern from lines 87–119:
```elixir
# Override dunning_campaign_started_at to past value by direct Repo.insert! with explicit timestamp
# (Subscription changeset or force_status_changeset with the field set directly)
```

---

### `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` (extend existing file)

**Analog:** `campaign_started observability (DUN-08)` describe block — lines 214–250 (read confirmed).

**Module header already present** (lines 1–30): `use Accrue.BillingCase, async: false` + `use Oban.Testing, repo: Accrue.TestRepo`.

**Existing assertion to extend** (lines 229–231):
```elixir
events = ledger_events("dunning.campaign_started", sub.id)
assert [event] = events
assert event.data["step_count"] == step_count
```

**New assertion to add alongside** (D-04):
```elixir
assert event.data["invoice_id"] == "in_fake_obs_start1"
```
Where `"in_fake_obs_start1"` matches the invoice ID passed to `stub_invoice_fetch/3`. The canonical fetched via the stub has `"id" => invoice_id` (line 77 in the existing test), which is what `get(canonical, :id)` returns.

---

### `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` (extend existing file)

**Analog:** `window parameter (DAN-10)` describe block and `funnel rendering (DAN-09)` describe block — full file read confirmed.

**Module header already present** (lines 1–55): `use AccrueAdmin.LiveCase, async: false`, `AuthAdapter` inline module, setup with Events.record.

**At-risk table rendering test pattern** (mirrors lines 57–68):
```elixir
test "renders at-risk table below funnel when active campaigns exist", %{conn: conn} do
  # Insert a Subscription with dunning_campaign_started_at set
  # (requires seeding via Accrue.Repo since this is a LiveCase, not BillingCase)
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")
  assert html =~ "At-Risk Subscriptions"
end
```

**Window change refreshes at-risk pattern** (mirrors lines 202–207):
```elixir
test "window change via render_patch refreshes at-risk list", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  {:ok, view, _html} = live(conn, "/billing/analytics/recovery")
  html = render_patch(view, "/billing/analytics/recovery?window=7d")
  # assert at-risk section still renders (no crash on re-assign)
  assert html =~ "At-Risk Subscriptions"
end
```

**Cross-package boundary test pattern** (static file-read assertion — RESEARCH.md Pitfall 7):
```elixir
test "cross-package boundary: RecoveryLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.Subscription" do
  source = File.read!("lib/accrue_admin/live/analytics/recovery_live.ex")
  refute source =~ "import Ecto.Query"
  refute source =~ "Accrue.Repo"
  refute source =~ "Accrue.Billing.Subscription"
end
```
Run this test from the `accrue_admin/` directory so the relative path resolves.

---

## Shared Patterns

### Fake-clock pinning
**Source:** `accrue/lib/accrue/billing/query.ex` (multiple functions), `dunning_test.exs` lines 87–93
**Apply to:** `at_risk_subscriptions/1` (days_in_campaign), `at_risk_subscriptions_test.exs` (time comparisons)
```elixir
now = Accrue.Clock.utc_now()
now_usec = %{now | microsecond: {0, 6}}
```
Use `Accrue.Clock.utc_now()` everywhere NOW is needed in a query, never raw `DateTime.utc_now()` or SQL `NOW()`.

### Oban args-fragment
**Source:** `accrue/lib/accrue/dunning/engine/oban.ex` lines 77–82
**Apply to:** `at_risk_subscriptions/1` oban_jobs LEFT JOIN
```elixir
where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub.id),
where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)
```
The `fragment/2` form (with positional `?` placeholders) is the established pattern for JSONB `->>` access with Ecto pinned values.

### Events.record data map additions
**Source:** `default_handler.ex` lines 1256–1264
**Apply to:** `emit_campaign_started/2` change
```elixir
Events.record(%{
  type: "dunning.campaign_started",
  subject_type: "Subscription",
  subject_id: sub.id,
  data: %{step_count: step_count}   # add keys here; data is :map / jsonb — open shape
})
```
Adding keys to the `data` map requires no schema migration. Pre-existing events without the new key return `nil` for that key when queried (`data->>'invoice_id'` = NULL).

### Phoenix.Component function component skeleton
**Source:** `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` lines 1–36
**Apply to:** `at_risk_table.ex`
```elixir
use Phoenix.Component
attr(:..., :type, required: true)
def component_name(assigns) do
  ~H"""
  <article class={["ax-card", "ax-component-name", @class]}>
    ...
  </article>
  """
end
```
Use `Phoenix.Component` (not `Phoenix.LiveComponent`) — this is a stateless function component, not a stateful live component.

### LiveCase auth setup
**Source:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` lines 6–55
**Apply to:** any new RecoveryLive test cases
```elixir
use AccrueAdmin.LiveCase, async: false
# Inline AuthAdapter module (already in the file)
# setup: Application.put_env(:accrue, :auth_adapter, AuthAdapter) + on_exit cleanup
conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
```

---

## No Analog Found

All files have close analogs in the codebase.

| File | Nearest analog gap | Note |
|------|--------------------|------|
| `accrue_admin/assets/css/app.css` | No CSS component file was searched | Add `.ax-at-risk-*` CSS classes following the `.ax-funnel-*` naming conventions in `app.css`. Pattern: modifier classes like `.ax-at-risk-table`, `.ax-at-risk-header`, `.ax-at-risk-count-chip`, `.ax-at-risk-grid`. |

---

## Metadata

**Analog search scope:** `accrue/lib/`, `accrue/test/`, `accrue_admin/lib/`, `accrue_admin/test/`
**Files scanned:** 12 (query.ex, analytics/dunning.ex, default_handler.ex lines 1220–1280, engine/oban.ex lines 1–103, recovery_live.ex, funnel_chart.ex, kpi_card.ex, data_table.ex, dunning_test.exs, query_test.exs, dunning_campaign_start_test.exs lines 1–80 + 200–251, recovery_live_test.exs)
**Pattern extraction date:** 2026-05-27
