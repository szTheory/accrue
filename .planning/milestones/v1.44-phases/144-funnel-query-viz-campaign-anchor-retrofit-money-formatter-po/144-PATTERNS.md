# Phase 144: Funnel query + viz + campaign-anchor retrofit + money formatter polish - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 10 (8 modified + 2 created)
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/analytics/dunning.ex` (MOD) | analytics-query | request-response (read-only Ecto JSONB aggregation) | `Dunning.recovered_vs_lost_mrr/1` (same file `:41-56`) | exact (same module + idiom) |
| `accrue/lib/accrue/webhook/default_handler.ex` (MOD) | event-write | event-driven (webhook → ledger) | `maybe_emit_dunning_exhaustion/3` + `maybe_finalize_dunning_campaign/3` (same file) | exact (same module + sites) |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (MOD) | liveview | request-response (mount → assigns → render) | same file's existing `mount/3` + `render/1` (`:9-60`) | exact |
| `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` (NEW) | functional-component | server-side render | `accrue_admin/lib/accrue_admin/components/kpi_card.ex` (full file) | exact (component shell + slot pattern) |
| `accrue_admin/assets/css/app.css` (MOD) | css | static asset | `.ax-kpi-delta-{moss,amber,slate}` block (`:519-560`) | exact (tone palette + SVG idiom) |
| `accrue/test/accrue/analytics/dunning_test.exs` (MOD) | test (unit + regression) | request-response | same file's existing `describe "recovered_vs_lost_mrr/1"` (`:6-82`) | exact |
| `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` (MOD) | test (boundary) | event-driven | same file at `:294-318` | exact |
| `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` (MOD) | test (boundary) | event-driven | same file at `:358-388` | exact |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` (MOD) | test (integration) | request-response | same file at `:1-66` | exact |
| `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` (NEW) | test (component unit) | render-only | (none in accrue_admin/test/accrue_admin/components/) | no-analog (see §No Analog Found) |

## Pattern Assignments

---

### `accrue/lib/accrue/analytics/dunning.ex` (analytics-query, request-response — MOD)

**Analog:** Same file — `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` is the canonical template the new `funnel/1` must mirror. Phase 144 also wraps the cast at `:46` in safe-cast.

**Imports + module shell** (`accrue/lib/accrue/analytics/dunning.ex:1-16`):
```elixir
defmodule Accrue.Analytics.Dunning do
  @moduledoc """
  Analytics context for Dunning.

  Provides MRR-based recovery vs lost metrics without adding new database
  tables, querying directly against the `accrue_events` ledger via Ecto JSONB
  aggregations.
  """

  import Ecto.Query, only: [from: 2, where: 3]

  alias Accrue.Events.Event
  alias Accrue.Repo

  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"
```

**Canonical single-query Ecto JSONB aggregation pattern — the EXACT cast site the safe-cast wrapper retrofits** (`accrue/lib/accrue/analytics/dunning.ex:41-56`):
```elixir
@spec recovered_vs_lost_mrr(keyword()) :: %{recovered_cents: non_neg_integer(), lost_cents: non_neg_integer()}
def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
  query =
    from(e in Event,
      where: e.type in [@recovered_type, @exhausted_type],
      group_by: e.type,
      select: {e.type, sum(fragment("(?->>'mrr_value_cents')::integer", e.data))}
    )
    |> apply_window(opts)

  results = Repo.all(query) |> Map.new()

  %{
    recovered_cents: Map.get(results, @recovered_type) || 0,
    lost_cents: Map.get(results, @exhausted_type) || 0
  }
end
```

The DAN-08 safe-cast retrofit at line 46 swaps the bare `fragment("(?->>'mrr_value_cents')::integer", e.data)` to the canonical CASE-WHEN form. RESEARCH.md confirms the shape (uses `->` returning jsonb inside `jsonb_typeof`, NOT the `::jsonb` round-trip in REQUIREMENTS):
```elixir
sum(
  fragment(
    "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' " <>
      "THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
    e.data,
    e.data
  )
)
```
Note: two `?` placeholders, both bound to `e.data` — Ecto `fragment/1` accepts repeated positional args.

**Window helper to reuse** (`accrue/lib/accrue/analytics/dunning.ex:58-72`):
```elixir
defp apply_window(query, opts) do
  query
  |> maybe_since(opts[:since])
  |> maybe_until(opts[:until])
end

defp maybe_since(query, %DateTime{} = since),
  do: where(query, [e], e.inserted_at >= ^since)

defp maybe_since(query, _), do: query

defp maybe_until(query, %DateTime{} = until),
  do: where(query, [e], e.inserted_at <= ^until)

defp maybe_until(query, _), do: query
```
`funnel/1` reuses `apply_window/2` verbatim against its **inner subquery** so window-bounded campaigns are filtered before grouping.

**`funnel/1` shape (NEW)** — apply this template; see RESEARCH.md §Code Examples §2 for the full skeleton. Key elements:

1. Module attribute `@dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]`.
2. Inner `per_campaign` subquery: `group_by: [e.subject_id, fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data)]`, projecting `bool_or(? = 'dunning.recovered')` and `bool_or(? = 'dunning.exhausted')` via `fragment/1`.
3. Outer query: `from(c in subquery(per_campaign), select: %{entered: count(), recovered: filter(count(), c.has_recovered), exhausted: filter(count(), c.has_exhausted and not c.has_recovered), active: filter(count(), not c.has_recovered and not c.has_exhausted)})`.
4. `Repo.one(query) || %{entered: 0, recovered: 0, exhausted: 0, active: 0}` for the empty-ledger case.

---

### `accrue/lib/accrue/webhook/default_handler.ex` (event-write, event-driven — MOD)

**Analog:** Same file. Two emission sites. Recovered edge already has `iso_anchor` in scope; exhausted edge does NOT.

**Exhausted-edge call site — TARGET LINES 804-814** (`accrue/lib/accrue/webhook/default_handler.ex:777-820`):
```elixir
defp maybe_emit_dunning_exhaustion(%Subscription{} = row, %Subscription{} = updated, canonical) do
  with true <- Subscription.dunning_sweepable?(row),
       to_status when not is_nil(to_status) <-
         Subscription.dunning_exhausted_status(updated) do
    source = dunning_source(row.dunning_sweep_attempted_at)
    mrr_value_cents = calculate_mrr_cents(canonical)
    currency = get(canonical, :currency) || "usd"

    :telemetry.execute(
      [:accrue, :ops, :dunning_exhaustion],
      %{count: 1},
      %{
        subscription_id: updated.id,
        from_status: :past_due,
        to_status: to_status,
        source: source
      }
    )

    # ... DUN-08 observability comment block at :796-803 ...
    Events.record(%{
      type: "dunning.exhausted",
      subject_type: "Subscription",
      subject_id: updated.id,
      data: %{
        to_status: to_status,
        source: source,
        mrr_value_cents: mrr_value_cents,
        currency: currency
      }
    })
```

**Retrofit — compute `iso_anchor` defensively (row may have nil anchor on Stripe-native-immediate-cancel)** then add `campaign_anchor: iso_anchor` to the `data:` map:
```elixir
# Insert BEFORE the Events.record call (after the currency = ... line):
iso_anchor =
  case row.dunning_campaign_started_at do
    %DateTime{} = dt -> DateTime.to_iso8601(dt)
    _ -> nil
  end

Events.record(%{
  type: "dunning.exhausted",
  subject_type: "Subscription",
  subject_id: updated.id,
  data: %{
    to_status: to_status,
    source: source,
    mrr_value_cents: mrr_value_cents,
    currency: currency,
    campaign_anchor: iso_anchor
  }
})
```

**Recovered-edge call site — TARGET LINES 885-894 — `iso_anchor` ALREADY in scope** (`accrue/lib/accrue/webhook/default_handler.ex:865-897`):
```elixir
with true <- Subscription.dunning_campaign_active?(row),
     true <- finalizing_transition?(updated),
     %DateTime{} = anchor <- row.dunning_campaign_started_at do
  iso_anchor = DateTime.to_iso8601(anchor)            # <-- line 868: already here
  recovery? = Subscription.active?(updated)

  multi =
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :clear_anchor,
      Subscription.force_status_changeset(updated, %{dunning_campaign_started_at: nil})
    )

  multi =
    if recovery? do
      mrr_value_cents = calculate_mrr_cents(canonical)
      currency = get(canonical, :currency) || "usd"

      Events.record_multi(multi, :dunning_recovered_event, %{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: updated.id,
        data: %{
          source: dunning_source(row.dunning_sweep_attempted_at),
          mrr_value_cents: mrr_value_cents,
          currency: currency
        }
      })
    else
      multi
    end
```

**Retrofit — just append `campaign_anchor: iso_anchor` to the existing `data:` map** (no new compute; `iso_anchor` from `:868` is already in lexical scope):
```elixir
Events.record_multi(multi, :dunning_recovered_event, %{
  type: "dunning.recovered",
  subject_type: "Subscription",
  subject_id: updated.id,
  data: %{
    source: dunning_source(row.dunning_sweep_attempted_at),
    mrr_value_cents: mrr_value_cents,
    currency: currency,
    campaign_anchor: iso_anchor      # <-- the only new line
  }
})
```

Atomic-write invariant preserved: the ledger record stays folded into the same `Ecto.Multi` as `clear_anchor`; only the `data` jsonb payload widens.

---

### `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (liveview, request-response — MOD)

**Analog:** Same file (self-modifying). Three surgical edits: (1) add `Dunning.funnel/1` call + currency/locale resolution in `mount/3`, (2) replace `format_minor/1` call sites in `render/1` and delete the helper, (3) rename "Lost MRR" → "Exhausted MRR" + render `<FunnelChart.funnel_chart .../>` below `<section class="ax-kpi-grid">`.

**Current `mount/3`** (`accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:9-18`):
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  stats = Dunning.recovered_vs_lost_mrr()

  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:stats, stats)}
end
```

**Retrofit — compute formatted-strings in `mount/3` (KpiCard.value is :string, required: true — see KpiCard analog below; cannot nest `<MoneyFormatter>` inside slot)**:
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  stats = Dunning.recovered_vs_lost_mrr()
  funnel = Dunning.funnel()
  currency = Accrue.Config.get!(:default_currency)
  locale = Accrue.Config.default_locale()

  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:stats, stats)
   |> assign(:funnel, funnel)
   |> assign(:recovered_str, Accrue.Invoices.Render.format_money(stats.recovered_cents, currency, locale))
   |> assign(:exhausted_str, Accrue.Invoices.Render.format_money(stats.lost_cents, currency, locale))}
end
```

**Current `render/1`** (`accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:38-56`):
```elixir
<section class="ax-kpi-grid">
  <KpiCard.kpi_card
    label="Recovered MRR"
    value={format_minor(@stats.recovered_cents)}
    delta="Amount saved by successful Dunning"
    delta_tone="moss"
  >
    <:meta>Money Saved</:meta>
  </KpiCard.kpi_card>

  <KpiCard.kpi_card
    label="Lost MRR"
    value={format_minor(@stats.lost_cents)}
    delta="Amount lost to terminal Dunning failure"
    delta_tone="amber"
  >
    <:meta>Churned Revenue</:meta>
  </KpiCard.kpi_card>
</section>
```

**Retrofit** — swap `value=` to assigns, rename label, append `<FunnelChart.funnel_chart>`:
```elixir
<section class="ax-kpi-grid">
  <KpiCard.kpi_card
    label="Recovered MRR"
    value={@recovered_str}
    delta="Amount saved by successful Dunning"
    delta_tone="moss"
  >
    <:meta>Money Saved</:meta>
  </KpiCard.kpi_card>

  <KpiCard.kpi_card
    label="Exhausted MRR"
    value={@exhausted_str}
    delta="Annualized MRR snapshot at the exhaustion event — e.g., a $120/yr plan contributes $10/mo to Exhausted MRR."
    delta_tone="amber"
  >
    <:meta>Churned Revenue</:meta>
  </KpiCard.kpi_card>
</section>

<FunnelChart.funnel_chart
  entered={@funnel.entered}
  recovered={@funnel.recovered}
  exhausted={@funnel.exhausted}
  active={@funnel.active}
/>
```

**`format_minor/1` helper to DELETE** (`accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:76-81`):
```elixir
defp format_minor(amount_minor) when is_integer(amount_minor) do
  dollars = amount_minor / 100
  "$" <> :erlang.float_to_binary(dollars, decimals: 2)
end

defp format_minor(_), do: "$0.00"
```
This is the canonical USD-only bug that DAN-13 fixes. Delete entirely after the swap.

**Alias retrofit** — extend the existing alias line (`accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:7`):
```elixir
# Current:
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, KpiCard}
# After:
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FunnelChart, KpiCard}
```

---

### `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` (functional-component, server-side render — NEW)

**Analog:** `accrue_admin/lib/accrue_admin/components/kpi_card.ex` — exact match for the functional-component shell pattern (use Phoenix.Component, attr macros, `ax-card` wrapper, helper `defp` for derived values).

**Component shell + attr macros + slot pattern to mirror** (`accrue_admin/lib/accrue_admin/components/kpi_card.ex:1-38`):
```elixir
defmodule AccrueAdmin.Components.KpiCard do
  @moduledoc """
  Shared KPI card for dashboard and detail-page summary rows.

  When `href` is set, the root becomes an anchor for full-card navigation. Linked cards
  should set `aria_label` to a short description for screen readers.
  """

  use Phoenix.Component

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)         # <-- A6 in RESEARCH.md: :string type forbids nesting MoneyFormatter
  attr(:delta, :string, default: nil)
  attr(:delta_tone, :string, default: "slate")
  attr(:trend, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:aria_label, :string, default: nil)
  slot(:meta)
  slot(:sparkline)

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

**Helper-defp pattern for derived assigns** (`accrue_admin/lib/accrue_admin/components/kpi_card.ex:40-67`):
```elixir
defp kpi_inner(assigns) do
  ~H"""
  <header class="ax-kpi-card-header">
    <p class="ax-label"><%= @label %></p>
    <p :if={@trend} class="ax-body ax-kpi-trend"><%= @trend %></p>
  </header>

  <p class="ax-kpi-value"><%= @value %></p>

  <div class="ax-kpi-card-footer">
    <span :if={@delta} class={["ax-kpi-delta", "ax-kpi-delta-" <> normalize_tone(@delta_tone)]}>
      <%= @delta %>
    </span>
    <%= render_slot(@meta) %>
  </div>

  <div :if={@sparkline != []} class="ax-kpi-sparkline">
    <%= render_slot(@sparkline) %>
  </div>
  """
end

defp normalize_tone(tone) when tone in ["moss", "cobalt", "amber", "slate", "ink"], do: tone

defp normalize_tone(tone) when tone in [:moss, :cobalt, :amber, :slate, :ink],
  do: Atom.to_string(tone)

defp normalize_tone(_tone), do: "slate"
end
```

**FunnelChart skeleton to write** — copy `use Phoenix.Component` / `attr(...)` / `def funnel_chart(assigns) do … ~H"""` shell from above; full body in RESEARCH.md §Code Examples §Pattern 3 (lines 336-410). Key contract:
- `attr(:entered, :integer, required: true)` (+ recovered/exhausted/active/class).
- `def funnel_chart(assigns)` computes `recovered_pct`/`exhausted_pct` via private `defp pct(n, 0), do: 0; defp pct(n, total), do: round(n * 100 / total)`.
- Wrapping `<article class={["ax-card", "ax-funnel-chart", @class]}>` mirrors KpiCard's `ax-card` shell.
- Inline `<svg viewBox="0 0 100 36" role="img" aria-labelledby="funnel-title funnel-desc" preserveAspectRatio="none">` with linked `<title>`/`<desc>`.
- Three `<g transform="translate(0, idx*12)" class="ax-funnel-row ax-funnel-row--{slate,moss,amber}">` rows, each with `<rect width={pct} height="10" rx="1.5">` + inline `<title>` (per-bar tooltip; Exhausted carries the worked-example copy).
- External `<dl class="ax-funnel-legend">` with `<dt>`/`<dd>` per stage for a11y-resilient label/count/%.
- Active count rendered as a `<span class="ax-funnel-active-chip">` inside the `<header>` (component owns it — per OQ#2 in RESEARCH.md).

---

### `accrue_admin/assets/css/app.css` (css, static asset — MOD)

**Analog:** Existing `.ax-kpi-delta-*` tone palette and `.ax-kpi-sparkline` SVG idiom — the `.ax-funnel-*` block appends AFTER line 560.

**Tone palette to reuse** (`accrue_admin/assets/css/app.css:519-548`):
```css
.ax-kpi-delta {
  display: inline-flex;
  align-items: center;
  min-height: 2rem;
  padding: 0 0.75rem;
  border-radius: 999px;
  font-size: 0.875rem;
  font-weight: 600;
}

.ax-kpi-delta-moss {
  color: var(--ax-success-readable);
  background: color-mix(in srgb, var(--ax-success) 16%, transparent);
}

.ax-kpi-delta-cobalt {
  color: var(--ax-accent-readable);
  background: color-mix(in srgb, var(--ax-accent) 16%, transparent);
}

.ax-kpi-delta-amber {
  color: var(--ax-warning-readable);
  background: color-mix(in srgb, var(--ax-warning) 16%, transparent);
}

.ax-kpi-delta-slate,
.ax-kpi-delta-ink {
  color: var(--ax-primary);
  background: color-mix(in srgb, var(--ax-muted) 12%, transparent);
}
```

**Inline-SVG + `currentColor` + `var(--ax-accent)` idiom to mirror** (`accrue_admin/assets/css/app.css:550-560`):
```css
.ax-kpi-sparkline svg {
  width: 100%;
  height: 3rem;
  color: var(--ax-accent);
}

.ax-kpi-sparkline path {
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
}
```

**Block to append after `:560`** — see RESEARCH.md §Code Examples §9. Pattern: reuse `var(--ax-success)` (moss), `var(--ax-warning)` (amber), `var(--ax-muted)` (slate); use `color-mix(in srgb, ... %, transparent)` for the bar fills; declare `.ax-funnel-active-chip` with the same `color-mix(in srgb, var(--ax-accent) 16%, transparent)` background as `.ax-kpi-delta-cobalt`.

---

### `accrue/test/accrue/analytics/dunning_test.exs` (test unit + regression — MOD)

**Analog:** Same file's existing `describe "recovered_vs_lost_mrr/1"` — direct `Accrue.Repo.insert!(%Accrue.Events.Event{...})` seeding pattern.

**Direct-insert seeding pattern** (`accrue/test/accrue/analytics/dunning_test.exs:1-46`):
```elixir
defmodule Accrue.Analytics.DunningTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Analytics.Dunning

  describe "recovered_vs_lost_mrr/1" do
    test "aggregates mrr_value_cents correctly from events" do
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 1000, "source" => "webhook"}
      })
      # ... 3 more inserts ...

      assert %{recovered_cents: 3000, lost_cents: 500} = Dunning.recovered_vs_lost_mrr()
    end
```

**Window-test pattern (`:since`/`:until` precedent)** (`accrue/test/accrue/analytics/dunning_test.exs:49-81`):
```elixir
test "respects time windows" do
  now = Accrue.Clock.utc_now()
  now_usec = %{now | microsecond: {elem(now.microsecond, 0), 6}}
  past = DateTime.add(now_usec, -10, :day)
  past_usec = %{past | microsecond: {elem(past.microsecond, 0), 6}}
  yesterday = DateTime.add(now_usec, -1, :day)
  yesterday_usec = %{yesterday | microsecond: {elem(yesterday.microsecond, 0), 6}}

  Accrue.Repo.insert!(%Accrue.Events.Event{
    type: "dunning.recovered",
    subject_type: "Subscription",
    subject_id: Ecto.UUID.generate(),
    actor_type: "system",
    schema_version: 1,
    data: %{"mrr_value_cents" => 1000},
    inserted_at: past_usec
  })
  # ...
  assert %{recovered_cents: 2000, lost_cents: 0} = Dunning.recovered_vs_lost_mrr(since: yesterday_usec)
end
```

**Tests to add (DAN-08 + DAN-01):**
1. `describe "recovered_vs_lost_mrr/1"` — add malformed-JSONB regression: insert event with `data: %{"mrr_value_cents" => "5000"}` (string) AND a valid event with integer 1000; assert `%{recovered_cents: 1000, lost_cents: 0}` (string row contributes 0, query does NOT raise).
2. New `describe "funnel/1"` block — mirror the same direct-insert pattern. Seed cycled-dunning fixtures (same subject_id, 2 anchors), assert `%{entered: N, recovered: ..., exhausted: ..., active: ...}` matches DISTINCT-tuple semantics.
3. Property test file is NEW: `accrue/test/property/dunning_funnel_property_test.exs` (per RESEARCH.md §Code Examples §6). Uses `use Accrue.RepoCase, async: false` + `use ExUnitProperties`; pre-existing precedent at `accrue/test/property/dunning_campaign_property_test.exs`.

---

### `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` (test boundary — MOD)

**Analog:** Same file's existing `describe "dunning.exhausted observability (DUN-08)"` block at `:294-318` — the test that asserts `ledger.data["to_status"]` is the direct pattern to extend.

**Existing ledger-data assertion shape** (`accrue/test/accrue/webhook/dunning_exhaustion_test.exs:294-318`):
```elixir
describe "dunning.exhausted observability (DUN-08)" do
  test "the confirmed terminal transition records a ledger event AND fires telemetry",
       %{sub: sub, sub_id: sub_id} do
    stub_subscription_fetch(sub_id, :canceled)
    attach_telemetry("test-dun-exhausted", [:accrue, :ops, :dunning_exhausted])

    event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "canceled"})
      )

    assert {:ok, %Subscription{status: :canceled}} = DefaultHandler.handle(event)

    # Ledger: data carries to_status + source (bounded enums), no PII.
    assert [ledger] = ledger_events("dunning.exhausted", sub.id)
    assert ledger.data["to_status"] == "canceled"
    assert ledger.data["source"] == "stripe_native"

    # Telemetry: %{count: 1}; metadata IDs + bounded enums only.
    assert_received {:telemetry, [:accrue, :ops, :dunning_exhausted], %{count: 1}, meta}
    # ...
  end
```

**Tests to add (DAN-02):**
1. Extend the existing test (or add a sibling) — after setting an anchor on `sub` via `Accrue.Billing.Subscription.force_status_changeset(%{dunning_campaign_started_at: anchor}) |> Accrue.Repo.update!()`, assert `ledger.data["campaign_anchor"] |> is_binary()` AND `{:ok, _dt, _} = DateTime.from_iso8601(ledger.data["campaign_anchor"])`.
2. Add nil-anchor case (Stripe-native immediate cancel) — don't pre-set anchor, assert `is_nil(ledger.data["campaign_anchor"])`. Validates the defensive `case row.dunning_campaign_started_at` branch.

(Full assertion shape in RESEARCH.md §Code Examples §7.)

---

### `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` (test boundary — MOD)

**Analog:** Same file's existing `describe "dunning.recovered observability (DUN-08)"` block at `:358-388`.

**Existing ledger-data assertion shape** (`accrue/test/accrue/webhook/dunning_campaign_keying_test.exs:358-376`):
```elixir
describe "dunning.recovered observability (DUN-08)" do
  test "the past_due→active recovery records a ledger event AND fires telemetry",
       %{sub: sub, sub_id: sub_id} do
    anchor = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
    sub = set_anchor(sub, anchor)

    attach_telemetry("test-dun-recovered", [:accrue, :ops, :dunning_recovered])

    assert {:ok, %Subscription{status: :active}} = fire_recovery(sub_id)

    # Ledger: data carries source (bounded enum), no PII.
    assert [ledger] = ledger_events("dunning.recovered", sub.id)
    assert ledger.data["source"] == "stripe_native"
```

**Test to add (DAN-02):** Extend that test — after `assert ledger.data["source"] == "stripe_native"`, add:
```elixir
assert is_binary(ledger.data["campaign_anchor"])
assert {:ok, %DateTime{}, _} = DateTime.from_iso8601(ledger.data["campaign_anchor"])
# Stronger: the snapshotted iso_anchor matches the anchor set above.
assert ledger.data["campaign_anchor"] == DateTime.to_iso8601(anchor)
```

The `set_anchor/2` helper is already defined in this file's test-helper area (used at `:362`).

---

### `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` (test integration — MOD)

**Analog:** Same file's existing `setup` block + `test "renders recovery dashboard with MRR totals"`.

**Existing setup + integration-test pattern** (`accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:1-65`):
```elixir
defmodule AccrueAdmin.Live.Analytics.RecoveryLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events
  # ... AuthAdapter module ...

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    Events.record(%{
      type: "dunning.recovered",
      subject_type: "Subscription",
      subject_id: "sub_123",
      data: %{
        mrr_value_cents: 5000,
        currency: "usd"
      }
    })
    # ...
    :ok
  end

  test "renders recovery dashboard with MRR totals", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

    assert html =~ "Revenue Recovery"
    assert html =~ "Recovered MRR"
    assert html =~ "$50.00"
    assert html =~ "Lost MRR"           # <-- DAN-13 rename: change to "Exhausted MRR"
    assert html =~ "$20.00"
  end
end
```

**`Application.put_env(:accrue, :default_currency, …)` precedent — quoted from `accrue/test/accrue/config_test.exs:132-138` (the ONLY existing occurrence in the repo)**:
```elixir
describe "get!/1 runtime overrides" do
  test "reads value from Application env when set" do
    Application.put_env(:accrue, :default_currency, :eur)
    assert :eur == Config.get!(:default_currency)
  after
    Application.delete_env(:accrue, :default_currency)
  end
end
```
Mirror this exact pattern in `recovery_live_test.exs` JPY setup — `setup` block (or `describe`-local setup) uses `Application.put_env(:accrue, :default_currency, :jpy)` + `on_exit` for cleanup. Note: the auth-adapter setup at `:26-29` already demonstrates the `prior = Application.get_env(...)`-then-restore pattern; reuse it.

**Tests to add (DAN-09 + DAN-13 + DAN-23 rename):**
1. **Rename assertion** — in the existing test, change `assert html =~ "Lost MRR"` to `assert html =~ "Exhausted MRR"` AND `refute html =~ "Lost MRR"`.
2. **Funnel render** — assert HTML contains funnel SVG / legend labels (e.g., `html =~ "Recovery Funnel"`, `html =~ "currently in dunning"`, `html =~ "Entered"`, etc.) after seeding cycled-dunning events with `campaign_anchor` payloads.
3. **JPY regression** (new `describe`):
   ```elixir
   describe "JPY rendering (DAN-13)" do
     setup do
       prior = Application.get_env(:accrue, :default_currency)
       Application.put_env(:accrue, :default_currency, :jpy)
       on_exit(fn ->
         if is_nil(prior),
           do: Application.delete_env(:accrue, :default_currency),
           else: Application.put_env(:accrue, :default_currency, prior)
       end)
       :ok
     end

     test "JPY events render with ¥ symbol, not $", %{conn: conn} do
       conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
       assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")
       refute html =~ "$50.00"
       assert html =~ "¥" or html =~ "￥" or html =~ "JPY"
     end
   end
   ```
   (Full pattern in RESEARCH.md §Code Examples §8.)

---

### `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` (test component unit — NEW)

**Analog:** No direct precedent — see §No Analog Found. Use `import Phoenix.LiveViewTest` + `render_component/2` + `=~` HTML assertions; case skeleton:
```elixir
defmodule AccrueAdmin.Components.FunnelChartTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.FunnelChart

  describe "funnel_chart/1" do
    test "renders all 4 counts in legend" do
      html = render_component(&FunnelChart.funnel_chart/1,
               entered: 10, recovered: 4, exhausted: 3, active: 3)
      assert html =~ "Recovery Funnel"
      assert html =~ "10"
      assert html =~ "currently in dunning"
    end

    test "guards against division-by-zero when entered: 0" do
      html = render_component(&FunnelChart.funnel_chart/1,
               entered: 0, recovered: 0, exhausted: 0, active: 0)
      assert html =~ "Entered"
      refute html =~ "NaN"
    end
  end
end
```

---

## Shared Patterns

### Runtime config accessor (DAN-13)

**Source:** `accrue/lib/accrue/config.ex:553` (`def get!(key) when is_atom(key)`) + precedent at `accrue/lib/accrue/billing/metered_renewal_invoice.ex:258` (existing `:default_currency` runtime read).

**Apply to:** `recovery_live.ex` `mount/3`. ALWAYS use `Accrue.Config.get!(:default_currency)`, NEVER `Application.compile_env(:accrue, :default_currency)`. CLAUDE.md "Config Boundaries" mandates runtime read for `:default_currency` (host-owned, may differ per-env).

### Atomic event-write inside `Ecto.Multi` / `Repo.transact`

**Source:** `accrue/lib/accrue/webhook/default_handler.ex:871-897` — the recovered-edge `Ecto.Multi` folds `clear_anchor` and `Events.record_multi/3` into one transaction.

**Apply to:** Both retrofit sites. The exhausted edge uses bare `Events.record/1` inside the enclosing reducer's `Repo.transact` (different mechanism, same atomicity guarantee — see `:777` doc comment "Runs inside the enclosing Repo.transact/2 so the write and the signal are atomic"). The retrofit ONLY adds a `data:` map key — the transaction shape is unchanged.

### `Application.put_env/3` + `on_exit` test config override

**Source:** `accrue/test/accrue/config_test.exs:134-137` (the only existing `:default_currency` precedent) + `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:26-29` (auth-adapter precedent in the file being modified).

**Apply to:** JPY regression test setup. Pattern: capture `prior`, `put_env`, `on_exit` restores (delete-if-nil, put-back-if-set).

### Direct `Accrue.Repo.insert!(%Accrue.Events.Event{...})` test seeding

**Source:** `accrue/test/accrue/analytics/dunning_test.exs:9-44`.

**Apply to:** All `dunning_test.exs` additions (funnel tests + malformed-JSONB regression + property test). Note: the property test (NEW file at `accrue/test/property/dunning_funnel_property_test.exs`) follows this same direct-insert pattern with `Repo.delete_all(Event)` between iterations (precedent in `accrue/test/property/dunning_campaign_property_test.exs`).

### `use Phoenix.Component` for functional UI components (no socket runtime)

**Source:** `accrue_admin/lib/accrue_admin/components/kpi_card.ex:9` (`use Phoenix.Component`) and `money_formatter.ex:6` (same).

**Apply to:** `FunnelChart` component. Critical: NEVER `use Phoenix.LiveView` for a static visual. Preserves CLAUDE.md C9 "core LiveView-runtime-free" posture (component lives in `accrue_admin`, not `accrue`, but the discipline of `use Phoenix.Component` is the same).

### `ax-card` wrapping shell for every dashboard component

**Source:** `accrue_admin/lib/accrue_admin/components/kpi_card.ex:33` (`<article class={["ax-card ax-kpi-card", @class]}>`).

**Apply to:** `FunnelChart`'s outer `<article>`. Use `class={["ax-card", "ax-funnel-chart", @class]}` — mirrors KpiCard's `[base, variant, @class]` shape.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` | test (component unit) | render-only | No existing `test/accrue_admin/components/` tests in the codebase — components are currently exercised only through LiveView integration tests. Use `Phoenix.LiveViewTest.render_component/2` shape (stdlib pattern, not project-specific). |

For the FunnelChart component test, use `Phoenix.LiveViewTest` (already a transitive dep via LiveView), `render_component(&FunnelChart.funnel_chart/1, attrs)`, and standard `=~` HTML assertions. The new test file is the first of its kind; planner should mention this in the plan so reviewers don't expect a parallel project-specific idiom.

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/{analytics,webhook,events,billing,invoices,config}.*`, `accrue_admin/lib/accrue_admin/{components,live/analytics}/**/*`, `accrue_admin/assets/css/app.css`, `accrue/test/accrue/{analytics,webhook,config}/**/*`, `accrue_admin/test/accrue_admin/live/analytics/*`, `.planning/phases/143/143-PATTERNS.md`.

**Files scanned:** ~14 (each Read with targeted offsets where files exceeded 200 lines; no re-reads).

**Pattern extraction date:** 2026-05-27

**Cross-reference:** Phase 143's `143-PATTERNS.md` confirmed `Dunning.recovered_vs_lost_mrr/1` is the analog for `funnel/1`, and `KpiCard` is the analog for `FunnelChart` — Phase 144 inherits and refines these mappings with precise line numbers.

---

## PATTERN MAPPING COMPLETE

**Phase:** 144 — Funnel query + viz + campaign-anchor retrofit + money formatter polish
**Files classified:** 10 (8 modified + 2 created)
**Analogs found:** 9 / 10 (only the new `funnel_chart_test.exs` has no project-specific precedent — uses stdlib `Phoenix.LiveViewTest.render_component/2`)

### Coverage
- Files with exact analog: 9
- Files with role-match analog: 0
- Files with no analog: 1 (`funnel_chart_test.exs` — stdlib pattern)

### Key Patterns Identified
- **Single-query Ecto JSONB aggregation:** `from(e in Event, where, group_by, select: sum(fragment(...)))` is the canonical template from `Dunning.recovered_vs_lost_mrr/1:41-56`; `funnel/1` extends it with two-level GROUP BY via `subquery/1` and `filter/2` predicates. The DAN-08 safe-cast retrofit wraps the existing cast at `:46` with `CASE WHEN jsonb_typeof((?->'k')) = 'number' THEN (?->>'k')::integer ELSE 0 END` (two `?` placeholders both bound to `e.data`).
- **Asymmetric anchor retrofit:** `iso_anchor` is ALREADY in scope at the recovered edge (`default_handler.ex:868`) — the retrofit is a one-line append `campaign_anchor: iso_anchor` to the `data:` map at `:889`. At the exhausted edge (`:777-820`), `row.dunning_campaign_started_at` may be nil (Stripe-native non-Accrue dunning), so the retrofit must compute `iso_anchor` defensively via `case row.dunning_campaign_started_at do %DateTime{} = dt -> DateTime.to_iso8601(dt); _ -> nil end` before the `Events.record/1` call at `:804-814`.
- **`KpiCard.value` is `:string, required: true`:** the MoneyFormatter swap CANNOT nest `<MoneyFormatter>` inside `<KpiCard.kpi_card>` — instead, `mount/3` computes `@recovered_str = Accrue.Invoices.Render.format_money(stats.recovered_cents, Accrue.Config.get!(:default_currency), Accrue.Config.default_locale())` and the LiveView passes the string through.
- **CSS tone palette + SVG idiom reuse:** `.ax-funnel-*` block appends after line 560 of `app.css`, mirroring `.ax-kpi-delta-{moss,amber,slate}` tokens (`:529-548`) and `.ax-kpi-sparkline svg`'s `currentColor` + `var(--ax-accent)` theming pattern (`:550-560`). Zero new design-system tokens.
- **`Application.put_env(:accrue, :default_currency, :jpy)`** is the canonical JPY-regression setup (sole precedent: `accrue/test/accrue/config_test.exs:134`). Pair with `on_exit` cleanup via the file-local auth-adapter pattern at `recovery_live_test.exs:26-29` for the restore-prior-state idiom.

### File Created
`/Users/jon/projects/accrue/.planning/phases/144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po/144-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. The planner can now produce per-task `<read_first>` blocks with precise file paths and line ranges: every load-bearing edit either copies from a same-module sibling function (analytics + retrofit + LiveView mount/render) or mirrors a tight functional-component shell (FunnelChart ↔ KpiCard). The only no-analog file is the new component unit test, which falls back to the stdlib `Phoenix.LiveViewTest.render_component/2` shape — flag explicitly so reviewers don't expect a project-specific precedent.
