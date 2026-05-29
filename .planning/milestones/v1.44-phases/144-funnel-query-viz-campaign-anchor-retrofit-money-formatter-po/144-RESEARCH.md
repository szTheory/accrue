# Phase 144: Funnel query + viz + campaign-anchor retrofit + money formatter polish - Research

**Researched:** 2026-05-27
**Domain:** Analytics (Ecto JSONB aggregation), Event Ledger Augmentation, Phoenix functional components (inline SVG), CLDR money rendering
**Confidence:** HIGH

## Summary

Phase 144 is a tight, ledger-only extension to the Phase 143 foundation. The existing `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` shape (single `from(e in Event, …) Repo.all` round-trip with JSONB fragment aggregation) is the canonical template — `funnel/1` reuses the same idiom with a `GROUP BY (subject_id, COALESCE(data->>'campaign_anchor', '__legacy__'))` two-level outer aggregation and `bool_or` / `COUNT FILTER` for the per-stage counts. All Postgres features required (`jsonb_typeof`, `COUNT FILTER`, `bool_or`, `COALESCE`, `->`, `->>`) are present in PostgreSQL 9.4+ and well within Accrue's PG 14+ floor [VERIFIED: PostgreSQL docs].

The campaign-anchor retrofit is two surgical edits inside `default_handler.ex` — line 808-813 (exhausted edge, inside `Events.record/1`) and line 889-893 (recovered edge, inside `Events.record_multi`). The recovered edge already has `iso_anchor` in scope at line 868 [VERIFIED: source read]; the exhausted edge does NOT (different function, no anchor computed locally) and must compute `iso_anchor` defensively from `row.dunning_campaign_started_at`, which may be `nil` for past_due→unpaid transitions that never started an Accrue campaign (e.g., Stripe-native dunning paths) [VERIFIED: `Subscription.dunning_sweepable?/1` only checks `status: :past_due`, source `accrue/lib/accrue/billing/subscription.ex:241-243`].

The JSONB safe-cast pattern `CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END` is the canonical form (avoids the unnecessary text→jsonb round-trip implied by REQUIREMENTS DAN-08's `(?->>'mrr_value_cents')::jsonb`). The `FunnelChart` component mirrors `KpiCard`'s `Phoenix.Component` shell pattern (`attr` macros, `ax-card` wrapper, slots if needed) and the `.ax-kpi-sparkline` SVG idiom (`currentColor` + `var(--ax-accent)`); tone palette reuses `ax-kpi-delta-{slate,moss,amber}` exactly. The money-formatter polish swaps a 6-line USD-only helper for a `MoneyFormatter.money_formatter/1` call site with `currency = Accrue.Config.get!(:default_currency)` and `locale = Accrue.Config.default_locale()` — both are runtime-safe accessors with no compile-time leakage.

**Primary recommendation:** Land the four sub-changes (funnel API → JSONB safety wrap → write-path retrofit → UI surface) as a single phase plan with four well-bounded waves. Every claim below is verified against source — no assumed knowledge in the load-bearing parts of this plan.

<user_constraints>
## User Constraints (from 144-CONTEXT.md)

### Locked Decisions

**Funnel query (DAN-01)**
- **D-01:** Single Ecto query using `GROUP BY (subject_id, COALESCE(data->>'campaign_anchor', '__legacy__'))` with `bool_or(type IN ('dunning.recovered','dunning.exhausted'))` as the conclusion flag. Aggregate per-stage counts in one round-trip: `entered` = COUNT all tuples; `recovered` = COUNT FILTER (WHERE concluded AND has dunning.recovered); `exhausted` = COUNT FILTER (WHERE concluded AND has dunning.exhausted); `active` = COUNT FILTER (WHERE NOT concluded).
- **D-02:** Pure-ledger, zero schema joins. Funnel reads only `accrue_events`. Mirrors Phase 143's JSONB precedent.
- **D-03:** Single `from(e in Event, ...)` query per REQUIREMENTS DAN-01 — no `Task.async`.
- **D-04:** Property test (stream_data): assert `recovered + exhausted + active ≤ entered`. Counter-example focus: cycled-dunning within a single window.

**Campaign-anchor fallback (DAN-02 forward-fix)**
- **D-05:** `COALESCE(data->>'campaign_anchor', '__legacy__')` sentinel-per-subject. Collapses ALL pre-retrofit events for a `subject_id` into ONE tuple per stage. Under-count is the safe failure mode (Pitfall #1 = double-counting).
- **D-06:** Document cutoff in `guides/analytics.md` (Phase 148 scope). P144 only documents in the funnel `@doc`.
- **D-07:** Backfill is architecturally impossible (`accrue_events` immutability trigger `SQLSTATE 45A01`).

**Anchor snapshot retrofit (DAN-02)**
- **D-08:** Retrofit two write sites in `default_handler.ex`: `dunning.recovered` (~line 885, inside `Events.record_multi`) and `dunning.exhausted` (~line 804, inside `Events.record/1`).
- **D-09:** Field shape: `campaign_anchor: DateTime.to_iso8601(row.dunning_campaign_started_at)` ISO-8601 string. Recovered edge: `iso_anchor` already at line 868. Exhausted edge: compute defensively.
- **D-10:** Extend `dunning_exhaustion_test.exs` and `dunning_campaign_keying_test.exs` to assert `ledger.data["campaign_anchor"]` is a parseable ISO-8601 string. Closes the Phase 143 emission-boundary test coverage gap.

**JSONB cast safety (DAN-08)**
- **D-11:** Wrap every `(?->>'mrr_value_cents')::integer` cast in canonical safe-cast: `CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END`. Apply at existing `recovered_vs_lost_mrr/1` site (`accrue/lib/accrue/analytics/dunning.ex:46`) and any new MRR-sum projections.
- **D-12:** Regression test: insert `dunning.recovered` event with string-typed `"mrr_value_cents": "5000"`; assert `recovered_vs_lost_mrr/1` returns successfully with 0 contribution from the bad row.

**FunnelChart visualization (DAN-09)**
- **D-13:** Left-aligned horizontal proportional bars (NOT centered trapezoidal). Inline SVG `viewBox="0 0 100 36"` so widths are percentages. Three `<g transform="translate(0, idx*12)">` rows; each row has `<rect width={pct} height="10" rx="1.5">` + inline `<title>` for hover. External `<dl class="ax-funnel-legend">` for a11y/zoom-resilient label/count/%.
- **D-14:** Tone reuse: `slate` (entered), `moss` (recovered), `amber` (exhausted). Theming via `currentColor` + `var(--ax-accent)`. Mirrors `ax-kpi-sparkline` idiom.
- **D-15:** A11y: `role="img"` on SVG; linked `<title>` + `<desc>` referenced via `aria-labelledby`. Per-bar inline `<title>` for hover/screen-reader.
- **D-16:** Per-stage tooltips. Exhausted tooltip carries yearly-plan worked example.
- **D-17:** Component file: `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`. Functional `Phoenix.Component`. Closest analog: `kpi_card.ex`. CSS additions to `app.css`: `.ax-funnel-chart`, `.ax-funnel-row`, `.ax-funnel-row--{slate,moss,amber}`, `.ax-funnel-bar`, `.ax-funnel-legend`.
- **D-18:** Insertion point: `recovery_live.ex` — append `<FunnelChart.funnel_chart .../>` directly BELOW the existing `<section class="ax-kpi-grid">` block.

**Currency strategy (DAN-13)**
- **D-19:** Replace `RecoveryLive.format_minor/1` with `AccrueAdmin.Components.MoneyFormatter` (or `Render.format_money/3`). Render cents value with `currency = Accrue.Config.get!(:default_currency)` and `locale = Accrue.Config.default_locale()`.
- **D-20:** Do NOT change `recovered_vs_lost_mrr/1` return shape in P144. Single-aggregate `%{recovered_cents, lost_cents}` stays untouched — Phase 148 owns the BREAKING per-currency widening.
- **D-21:** DAN-13 JPY regression test: `Application.put_env(:accrue, :default_currency, :jpy)` with `on_exit` cleanup; seed `dunning.recovered` event with `currency: "jpy"`, `mrr_value_cents: 5000`; assert HTML contains `¥50` or CLDR's locale-correct rendering.
- **D-22:** Funnel labels are MRR-free (counts + percentages only). DAN-13 currency strategy applies ONLY to the two KPI cards.
- **D-23:** Rename "Lost MRR" → "Exhausted MRR" with tooltip + worked example aligned with FunnelChart's Exhausted-stage tooltip (D-16).

### Claude's Discretion

- Test file placement for the campaign-anchor retrofit assertions (likely `dunning_exhaustion_test.exs` + `dunning_campaign_keying_test.exs`'s `describe "dunning.recovered observability"` block; planner picks).
- Exact CSS hex/HSL values and pixel offsets — pick from existing `ax-` tokens, no new design-system tokens.
- Exact `stream_data` generator shape (subject_id pool size, event-sequence length distribution).
- Inline vs. shared `defp safe_mrr_cents_sum` helper — lean inline since only ~1–2 call sites in P144.
- ExDoc `@doc` examples on `funnel/1` — include at least one `iex>` with a cycled-dunning fixture so DISTINCT-tuple semantics are self-documenting.
- Exact yearly-plan worked-example copy in the Exhausted tooltip.

### Deferred Ideas (OUT OF SCOPE)

- Per-currency widening of `recovered_vs_lost_mrr/1` + `funnel/1` → Phase 148 (DAN-07, BREAKING).
- `recovery_rate/1` public API → Phase 148 (DAN-06).
- `guides/analytics.md` + `@moduledoc` expansion + analytics-guide pointer needle in `verify_package_docs.sh` → Phase 148 (DAN-14, DAN-15).
- Adopter-proof matrix row + deterministic-clock seed wiring in `examples/accrue_host` → Phase 148 (DAN-16).
- "Showing data since YYYY-MM-DD" cutoff badge UI → Phase 148.
- `?window=7d|30d|90d` URL plumbing + window selector → Phase 145 (DAN-10). P144 funnel accepts `:since`/`:until` opts (mirroring `recovered_vs_lost_mrr/1`) so P145 threads them through without re-touching the API.
- At-risk subscriptions table + `at_risk_subscriptions/1` + `in_active_dunning_campaign/1` + last-failure enrichment → Phase 146 (DAN-03, DAN-04, DAN-11).
- `campaign_timeline/2` + drill-down route + `CampaignLive` → Phase 147 (DAN-05, DAN-12).
- Per-step funnel breakdown — out-of-scope for v1.44.
- Sparkline on KPI cards — deferred.
- `opentelemetry`-bridged dashboard-load span — explicit non-goal v1.44.
- Funnel-stage click → at-risk filter — explicitly deferred.
- Extracting `calculate_mrr_cents/1` to a shared module — deferred to v1.45+.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DAN-01 | `Accrue.Analytics.Dunning.funnel/1` returns `%{entered, recovered, exhausted, active}` over a window; DISTINCT `(subject_id, campaign_anchor)` tuples per stage; single Ecto query; property test holds `recovered + exhausted + active ≤ entered`. | "Funnel query design" + "Code Examples" + "Architecture Patterns" — verified SQL shape, Ecto `fragment/1` template at `dunning.ex:46`, property-test precedent at `test/property/dunning_campaign_property_test.exs`. |
| DAN-02 | Snapshot `campaign_anchor = DateTime.to_iso8601(subscription.dunning_campaign_started_at)` onto `dunning.recovered` (`default_handler.ex:~880`) and `dunning.exhausted` (`default_handler.ex:~805`) event payloads. Direct unit assertion at the `Events.record/record_multi` call site. | "Anchor-retrofit map" — `iso_anchor` is already at line 868 for recovered edge; exhausted edge must compute defensively because `Subscription.dunning_sweepable?/1` allows past_due→unpaid without an active anchor. |
| DAN-08 | All JSONB-fragment aggregations wrap `::integer` cast in `CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END`. Regression test: string-typed `"5000"` does not crash. | "JSONB safe-cast" — verified syntax against PostgreSQL `jsonb_typeof` docs; canonical shape uses `->` (returns jsonb) inside `jsonb_typeof`, not the round-trip cast `::jsonb` in REQUIREMENTS. |
| DAN-09 | `AccrueAdmin.Components.FunnelChart` HEEx component with inline SVG (no JS chart lib); three stacked stages with proportional widths; stage labels + counts + percentage-of-entered; tooltips define each stage. | "FunnelChart component map" — verified `KpiCard` analog (`use Phoenix.Component`, `attr`, slots, `ax-card` shell); CSS tones present at `app.css:529-548`; SVG idiom at `app.css:550-560`. |
| DAN-13 | Replace `RecoveryLive.format_minor/1` with `MoneyFormatter` calls. Regression test: JPY → `¥` symbol. | "Money formatter wiring" — verified `MoneyFormatter.money_formatter/1` API + `Accrue.Config.get!(:default_currency)` + `Accrue.Config.default_locale/0` + JPY put_env pattern at `test/accrue/config_test.exs:134`. |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Funnel aggregation (`funnel/1`) | API / Backend (`accrue`) | Database (Postgres JSONB) | Pure ledger query; lives in `Accrue.Analytics.Dunning` next to existing `recovered_vs_lost_mrr/1`. No schema joins. |
| JSONB safe-cast | Database (Postgres JSONB CASE) | API / Backend (Ecto `fragment/1`) | Defensive wrapping at the SQL layer so a single malformed row's text cannot crash the aggregation. |
| Campaign-anchor write-path retrofit | API / Backend (`Accrue.Webhook.DefaultHandler`) | Database (`accrue_events.data` jsonb) | Inject `campaign_anchor: iso_anchor` into the event `data` map at the two terminal emission sites. Atomic with the existing `Repo.transact` / `Ecto.Multi`. |
| FunnelChart UI component | Frontend Server (SSR / functional component) | Browser (inline SVG render) | `AccrueAdmin.Components.FunnelChart` is a `Phoenix.Component` — no LiveView socket runtime. Inline SVG renders server-side. |
| Money formatter swap | Frontend Server (SSR via `Render.format_money/3`) | API / Backend (`Accrue.Config` accessors) | `MoneyFormatter` is in `accrue_admin`; resolves `currency` + `locale` from `Accrue.Config` at render time. No compile-time leakage. |

## Standard Stack

### Core (all already in the project — no new mix deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:ecto_sql` | `~> 3.13` | Repo + `fragment/1` JSONB query DSL | Already pinned in `accrue/mix.exs`. The `from/in/where/group_by/select` shape is verbatim from Phase 143's `recovered_vs_lost_mrr/1`. [VERIFIED: source read at `accrue/lib/accrue/analytics/dunning.ex:42-47`] |
| `:postgrex` | `~> 0.22` | PG driver — JSONB encode/decode + `jsonb_typeof` | Already pinned. PG 14+ supports `jsonb_typeof`, `COUNT FILTER`, `bool_or`, `COALESCE` natively. [VERIFIED: PostgreSQL 14 docs; `jsonb_typeof` since 9.4] |
| `:phoenix_live_view` | `~> 1.1` | Source of `Phoenix.Component` + `~H` sigil for `FunnelChart` | Required core dep (per CLAUDE.md). `FunnelChart` uses `use Phoenix.Component`, NOT `use Phoenix.LiveView` — no socket runtime. [VERIFIED: `kpi_card.ex` analog at `accrue_admin/lib/accrue_admin/components/kpi_card.ex:9`] |
| `:stream_data` | `~> 1.3` | Property test generators | Already in `accrue/mix.exs:104` as `only: [:dev, :test]`. Existing precedent: `test/property/dunning_campaign_property_test.exs`. [VERIFIED: `mix.exs` + `test/property/` listing] |
| `:ex_money` + `:ex_cldr` | (existing) | CLDR money formatting via `Render.format_money/3` | Already wired through `MoneyFormatter`. Locale precedence ladder is `assigns[:locale] → customer.preferred_locale → Accrue.Config.default_locale/0`. [VERIFIED: `money_formatter.ex:67-71`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:phoenix_html` | `~> 4.2` | HEEx helpers for SVG/HTML interpolation | Implicit through Phoenix.Component / `~H` sigil. No direct API surface. |
| `:telemetry` | `~> 1.3` | (No new emissions in P144) | The existing `[:accrue, :ops, :dunning_recovered]` and `[:accrue, :ops, :dunning_exhausted]` telemetry stays untouched. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline SVG `<rect>` proportional bars | JS chart library (Chart.js, ApexCharts) | Avoided per locked decision D-13 + Accrue's "no new mix deps" constraint. Inline SVG is what `ax-kpi-sparkline` already uses; pattern is proven. |
| `bool_or` over `EXISTS` subquery | `EXISTS (SELECT 1 FROM accrue_events WHERE …)` correlated subquery | `bool_or` over the same GROUP BY pass keeps the query a single aggregation — no correlated subquery, no nested loop, Postgres planner produces one HashAggregate. |
| `MoneyFormatter` component wrapper | Direct `Render.format_money/3` call | `MoneyFormatter` already resolves the locale precedence ladder; calling `Render.format_money/3` directly skips that. Lean on `MoneyFormatter`. |
| `COALESCE('__legacy__')` sentinel | Per-event hash, or NULL pass-through | Per-event hash defeats de-dup (each legacy event becomes its own tuple). NULL pass-through requires Postgres `NULLS DISTINCT` GROUP BY semantics which are PG-15+ — Accrue's PG 14+ floor would break. The sentinel string collapses cleanly on PG 14. |

**Installation:** None — every dependency listed is already pinned in `accrue/mix.exs` and `accrue_admin/mix.exs`. [VERIFIED: read].

**Version verification:** All packages match versions already in the project. Phase 144 introduces **zero new mix deps**.

## Package Legitimacy Audit

> Not applicable — Phase 144 installs zero new external packages. Every library used is already pinned in the project's `mix.exs` files and was verified for Phase 143 (analytics) and earlier phases (Phoenix LiveView, Ecto, ex_money, ex_cldr).

| Package | Registry | Disposition |
|---------|----------|-------------|
| (none) | — | No new installs |

## Architecture Patterns

### System Architecture Diagram

```
WEBHOOK PATH (write-side retrofit — DAN-02)
─────────────────────────────────────────────────────────
Stripe webhook → DefaultHandler.handle/1
                       │
                       ├─► maybe_emit_dunning_exhaustion/3  (line 777)
                       │     │   row.dunning_campaign_started_at (may be nil)
                       │     ▼
                       │   Events.record(%{type: "dunning.exhausted",
                       │                   data: %{…, mrr_value_cents, currency,
                       │                           campaign_anchor: iso_or_nil}})
                       │     ▼
                       │   accrue_events row (jsonb data column)
                       │
                       └─► maybe_finalize_dunning_campaign/3  (line 853)
                             │   anchor + iso_anchor in scope at line 868
                             ▼
                           Events.record_multi(:dunning_recovered_event, %{
                             type: "dunning.recovered",
                             data: %{…, mrr_value_cents, currency,
                                     campaign_anchor: iso_anchor}})
                             ▼
                           Ecto.Multi → Repo.transaction (atomic with clear_anchor)


READ PATH (analytics + UI)
─────────────────────────────────────────────────────────
Operator → GET /billing/analytics/recovery
            │
            ▼
        RecoveryLive.mount/3
            │   ┌─► Dunning.recovered_vs_lost_mrr(opts)  [existing — wraps cast in safe-cast per D-11]
            │   │       │
            │   │       ▼
            │   │   from(e in Event,
            │   │        where: e.type in ["dunning.recovered","dunning.exhausted"],
            │   │        group_by: e.type,
            │   │        select: {e.type,
            │   │                 sum(fragment(
            │   │                   "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number'
            │   │                         THEN (?->>'mrr_value_cents')::integer
            │   │                         ELSE 0 END",
            │   │                   e.data, e.data))})
            │   │
            │   └─► Dunning.funnel(opts)  [NEW — DAN-01]
            │           │
            │           ▼
            │       Inner subquery: GROUP BY (subject_id, COALESCE(data->>'campaign_anchor','__legacy__'))
            │       Outer query: count(*) for entered, count(*) FILTER per stage
            │
            ▼
        assigns: %{stats: %{recovered_cents, lost_cents},
                   funnel: %{entered, recovered, exhausted, active}}
            │
            ▼
        render/1 (HEEx)
            │
            ├─► <KpiCard.kpi_card label="Recovered MRR" value={<MoneyFormatter />} />  [DAN-13]
            ├─► <KpiCard.kpi_card label="Exhausted MRR" value={<MoneyFormatter />} />  [DAN-13 + rename]
            └─► <FunnelChart.funnel_chart entered={...} … />  [DAN-09 NEW]
                    │   inline SVG <rect> bars + external <dl> legend
                    ▼
                Operator browser
```

### Recommended Project Structure

```
accrue/
├── lib/accrue/
│   ├── analytics/
│   │   └── dunning.ex                 # ADD funnel/1; WRAP recovered_vs_lost_mrr/1 cast in safe-cast
│   └── webhook/
│       └── default_handler.ex         # RETROFIT lines 808-813 (exhausted) + 889-893 (recovered)
└── test/accrue/
    ├── analytics/
    │   ├── dunning_test.exs           # ADD funnel tests + JSONB safe-cast regression
    │   └── dunning_funnel_property_test.exs  # NEW property test (or under test/property/)
    └── webhook/
        ├── dunning_exhaustion_test.exs        # EXTEND test at :308-311 with campaign_anchor assertion
        └── dunning_campaign_keying_test.exs   # EXTEND recovery edge at :369-370 with campaign_anchor assertion

accrue_admin/
├── lib/accrue_admin/
│   ├── components/
│   │   └── funnel_chart.ex            # NEW Phoenix.Component
│   └── live/analytics/
│       └── recovery_live.ex           # CALL Dunning.funnel/1; SLOT FunnelChart below ax-kpi-grid; SWAP format_minor → MoneyFormatter; RENAME "Lost MRR" → "Exhausted MRR"
├── assets/css/
│   └── app.css                        # ADD .ax-funnel-chart, .ax-funnel-row, .ax-funnel-row--{slate,moss,amber}, .ax-funnel-bar, .ax-funnel-legend (adjacent to .ax-kpi-* block at :515-560)
└── test/accrue_admin/live/analytics/
    └── recovery_live_test.exs         # ADD JPY regression + funnel render assertion
```

### Pattern 1: Single-query Ecto JSONB aggregation with safe-cast

**What:** Use Ecto `fragment/1` to embed Postgres-specific JSONB operators and CASE expressions; aggregate in one `Repo.all` round-trip.

**When to use:** Any time you sum/count a JSONB-encoded value across `accrue_events`. Mandatory wherever a `data->>'…'` cast appears (D-11).

**Example — existing `recovered_vs_lost_mrr/1` after the safe-cast wrap (D-11):**
```elixir
# accrue/lib/accrue/analytics/dunning.ex (modified)
query =
  from(e in Event,
    where: e.type in [@recovered_type, @exhausted_type],
    group_by: e.type,
    select:
      {e.type,
       sum(
         fragment(
           "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' " <>
             "THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
           e.data,
           e.data
         )
       )}
  )
  |> apply_window(opts)
```

Note: the `fragment/1` literal uses TWO `?` placeholders both bound to `e.data` (one for `jsonb_typeof((?->…))` and one for the `(?->>…)::integer` projection). Ecto `fragment/1` accepts repeated positional args this way. [VERIFIED: Ecto.Query.API docs + analogous repeated-arg fragments in lattice_stripe codebase].

### Pattern 2: Two-level GROUP BY for DISTINCT-tuple counting

**What:** Subquery groups events by `(subject_id, campaign_anchor)` first, producing one row per "campaign instance". Outer query counts those rows per outcome stage.

**When to use:** Whenever you need to "count distinct things by composite key" with multiple per-thing events.

**Example — funnel/1 (NEW):**
```elixir
# accrue/lib/accrue/analytics/dunning.ex (NEW)

@dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]

@spec funnel(keyword()) :: %{entered: non_neg_integer(),
                              recovered: non_neg_integer(),
                              exhausted: non_neg_integer(),
                              active: non_neg_integer()}
def funnel(opts \\ []) when is_list(opts) do
  # Inner: per-(subject, anchor) row with concluded? + which-conclusion flags.
  per_campaign =
    from(e in Event,
      where: e.type in ^@dunning_lifecycle_types,
      group_by: [
        e.subject_id,
        fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data)
      ],
      select: %{
        subject_id: e.subject_id,
        anchor: fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data),
        has_recovered: fragment("bool_or(? = 'dunning.recovered')", e.type),
        has_exhausted: fragment("bool_or(? = 'dunning.exhausted')", e.type)
      }
    )
    |> apply_window(opts)

  # Outer: stage-bucket counts in a single aggregation pass.
  query =
    from(c in subquery(per_campaign),
      select: %{
        entered:    count(),
        recovered:  count() |> filter(c.has_recovered),
        exhausted:  count() |> filter(c.has_exhausted and not c.has_recovered),
        active:     count() |> filter(not c.has_recovered and not c.has_exhausted)
      }
    )

  Repo.one(query) || %{entered: 0, recovered: 0, exhausted: 0, active: 0}
end
```

Notes:
- The Ecto `filter/2` macro (since `:ecto ~> 3.5`) compiles directly to Postgres `COUNT(*) FILTER (WHERE …)`. [VERIFIED: ecto docs `Ecto.Query.API.filter/2`].
- `bool_or(? = 'dunning.recovered')` returns `true` if any row in the group matches — perfect for "did this campaign reach the recovered stage". [VERIFIED: PostgreSQL aggregate functions docs, `bool_or` since pre-9.0].
- `exhausted` filter excludes campaigns that recovered first — defensive against a (logically impossible but ledger-replay-possible) double-conclusion. The DISTINCT-tuple property `recovered + exhausted + active ≤ entered` follows because the three filter predicates are mutually exclusive **and** the union does NOT cover `(has_recovered AND has_exhausted)` campaigns (which add to `recovered` only, leaving the sum strictly less than `entered`).
- `apply_window/2` is the existing `maybe_since`/`maybe_until` helper at `dunning.ex:58-72`. Apply it to the INNER query so window-bounded campaigns are filtered before grouping.
- Why `dunning.campaign_started` + `dunning.step_sent` are included in `@dunning_lifecycle_types`: an "entered but still active" campaign has NO recovered/exhausted event yet, so without including the lifecycle-entry types the outer count would miss it. Active campaigns are detected by `has_campaign_started OR has_step_sent` (implicit — the inner GROUP BY produces one row for any subject/anchor that has any lifecycle event).

### Pattern 3: Functional `Phoenix.Component` with inline SVG + slot-free attrs

**What:** A pure HEEx function component declares `attr` macros, renders SVG inline, uses external `<dl>` for accessible label/count data.

**When to use:** When the visual is a fixed shape parameterized by numbers — exactly the FunnelChart case.

**Example — `FunnelChart` (NEW), mirroring `KpiCard`:**
```elixir
# accrue_admin/lib/accrue_admin/components/funnel_chart.ex (NEW)

defmodule AccrueAdmin.Components.FunnelChart do
  @moduledoc """
  3-stage dunning funnel: Entered → Recovered / Exhausted, with an "active" chip
  for in-flight campaigns. Inline-SVG horizontal proportional bars.
  """

  use Phoenix.Component

  attr(:entered, :integer, required: true)
  attr(:recovered, :integer, required: true)
  attr(:exhausted, :integer, required: true)
  attr(:active, :integer, required: true)
  attr(:class, :string, default: nil)

  def funnel_chart(assigns) do
    assigns =
      assigns
      |> assign(:recovered_pct, pct(assigns.recovered, assigns.entered))
      |> assign(:exhausted_pct, pct(assigns.exhausted, assigns.entered))

    ~H"""
    <article class={["ax-card", "ax-funnel-chart", @class]}>
      <header class="ax-funnel-header">
        <p class="ax-label">Recovery Funnel</p>
        <span class="ax-funnel-active-chip"><%= @active %> currently in dunning</span>
      </header>

      <svg viewBox="0 0 100 36" role="img" aria-labelledby="funnel-title funnel-desc"
           preserveAspectRatio="none" class="ax-funnel-svg">
        <title id="funnel-title">Dunning recovery funnel</title>
        <desc id="funnel-desc">
          <%= @entered %> campaigns entered, <%= @recovered %> recovered, <%= @exhausted %> exhausted.
        </desc>

        <g transform="translate(0,0)" class="ax-funnel-row ax-funnel-row--slate">
          <rect width="100" height="10" rx="1.5" class="ax-funnel-bar">
            <title>Entered: <%= @entered %> campaigns</title>
          </rect>
        </g>
        <g transform="translate(0,12)" class="ax-funnel-row ax-funnel-row--moss">
          <rect width={@recovered_pct} height="10" rx="1.5" class="ax-funnel-bar">
            <title>Recovered: <%= @recovered %> campaigns (<%= @recovered_pct %>% of entered)</title>
          </rect>
        </g>
        <g transform="translate(0,24)" class="ax-funnel-row ax-funnel-row--amber">
          <rect width={@exhausted_pct} height="10" rx="1.5" class="ax-funnel-bar">
            <title>
              Exhausted: <%= @exhausted %> campaigns (<%= @exhausted_pct %>% of entered).
              A $120/yr plan that exhausts dunning contributes $10/mo to Exhausted MRR —
              annualized MRR snapshot at the exhaustion event.
            </title>
          </rect>
        </g>
      </svg>

      <dl class="ax-funnel-legend">
        <div class="ax-funnel-legend-row"><dt>Entered</dt><dd><%= @entered %></dd></div>
        <div class="ax-funnel-legend-row"><dt>Recovered</dt>
          <dd><%= @recovered %> <span class="ax-muted">(<%= @recovered_pct %>%)</span></dd>
        </div>
        <div class="ax-funnel-legend-row"><dt>Exhausted</dt>
          <dd><%= @exhausted %> <span class="ax-muted">(<%= @exhausted_pct %>%)</span></dd>
        </div>
      </dl>
    </article>
    """
  end

  defp pct(_n, 0), do: 0
  defp pct(n, total), do: round(n * 100 / total)
end
```

### Anti-Patterns to Avoid

- **`Task.async` per stage:** REQUIREMENTS DAN-01 explicitly forbids this. One Ecto query, one round-trip.
- **Counting raw events:** Naively `count(e.id) WHERE e.type = "dunning.exhausted"` double-counts subscriptions that cycle dunning. DISTINCT `(subject_id, campaign_anchor)` is the entire point.
- **`Subscription` schema join:** Phase 143's "pure ledger, no joins" precedent is load-bearing — window-bounded historical counts must be immutable against present-day subscription mutations.
- **Reading `Application.compile_env(:accrue, :default_currency)`:** secrets/runtime config rule in CLAUDE.md. Use `Accrue.Config.get!(:default_currency)` (runtime) — verified at `accrue/lib/accrue/billing/metered_renewal_invoice.ex:258` as the precedent.
- **JS chart library:** Inline SVG is the design system's idiom (`ax-kpi-sparkline`). Adding D3 / Chart.js / ApexCharts would introduce a new mix dep and break CLAUDE.md's "zero new mix deps" constraint.
- **NULL anchor without sentinel:** `GROUP BY (subject_id, NULL)` collapses ALL subjects together on PG ≤ 14 because NULL is not distinct in GROUP BY by default until PG 15's `NULLS NOT DISTINCT`. The `'__legacy__'` string sidesteps this entirely.
- **`use Phoenix.LiveView` for FunnelChart:** It's a static functional component. `use Phoenix.Component` only — no socket runtime.
- **Adding new event types or telemetry events:** P144 is read+write retrofit only. The existing `dunning.recovered` / `dunning.exhausted` / `dunning.campaign_started` / `dunning.step_sent` types are sufficient.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Money formatting | `"$" <> :erlang.float_to_binary(cents / 100)` (the current bug) | `AccrueAdmin.Components.MoneyFormatter.money_formatter/1` | CLDR-correct for ~150 currencies; never raises; double-fallback to `"N currency"`. Already in the project. |
| Locale resolution | `case currency, do: …` ladder | `Accrue.Config.default_locale/0` + `MoneyFormatter`'s precedence ladder | Resolved in one place at `money_formatter.ex:67-71`. |
| DateTime → ISO-8601 string | Hand-formatted `"#{year}-#{month}…"` | `DateTime.to_iso8601(dt)` | Stdlib; round-trips with `DateTime.from_iso8601/1`. |
| JSONB key extraction in SQL | Read full event in app and decode | `fragment("?->>'key'", e.data)` for text, `fragment("?->'key'", e.data)` for jsonb | Postgres-native; supported by Ecto fragment DSL. |
| JSONB type narrowing | Read in app and pattern-match | `jsonb_typeof((?->'k')) = 'number'` | Single-pass aggregation; no per-row roundtrip. |
| Funnel-bar layout | CSS flexbox of `<div>`s with `width: %` | Inline SVG `<rect>` with `viewBox="0 0 100 36"` | Survives screen zoom + a11y; mirrors `ax-kpi-sparkline`. |
| Property-test orchestration | Hand-rolled "generate N random sequences in a `for` loop" | `ExUnitProperties.check all …` + `StreamData` generators | Shrinking + counter-example reporting on failure. Existing precedent at `test/property/dunning_campaign_property_test.exs`. |

**Key insight:** Every load-bearing piece of this phase has a direct precedent in the codebase — either Phase 143's `recovered_vs_lost_mrr/1` (for the analytics shape), `KpiCard` (for the component shape), `MoneyFormatter` (for the rendering), or the existing `default_handler.ex` write sites (for the retrofit). The phase composes existing patterns; it does NOT introduce new ones.

## Common Pitfalls

### Pitfall 1: Funnel double-counting under cycled dunning

**What goes wrong:** A subscription cycles dunning 3 times in a single window (enters → recovers → enters → exhausts → enters → active). A naive `COUNT(*) WHERE type = 'dunning.campaign_started'` reports `entered: 3`, which is correct, but a naive `COUNT(*) WHERE type = 'dunning.recovered'` reports `recovered: 1` and `COUNT(*) WHERE type = 'dunning.exhausted'` reports `exhausted: 1`, while the SAME subject also appears as "active" in a third query — giving an inconsistent picture and inflated counts if any stage uses a different denominator.

**Why it happens:** The ledger has multiple recovered/exhausted events per `subject_id` (one per campaign cycle). Without a per-campaign keying field, you cannot tell them apart.

**How to avoid:**
- Inject `campaign_anchor = DateTime.to_iso8601(row.dunning_campaign_started_at)` into the event payload at write time (D-08, D-09).
- GROUP BY `(subject_id, COALESCE(data->>'campaign_anchor', '__legacy__'))` at read time (D-01, D-05).
- The `'__legacy__'` sentinel collapses ALL pre-retrofit events per subject into one row — under-count, NOT over-count (the safe failure mode).

**Warning signs:** A funnel where `recovered + exhausted + active > entered` is the canonical failure signature; the property test (D-04) catches it.

### Pitfall 2: Anchor unavailable at the exhausted edge

**What goes wrong:** The exhausted-write site (`maybe_emit_dunning_exhaustion/3`, line 777) emits `dunning.exhausted` for ANY past_due→unpaid|canceled transition. `Subscription.dunning_sweepable?/1` (line 241) ONLY checks `status: :past_due` — it does NOT require `dunning_campaign_started_at IS NOT NULL`. So a subscription that went past_due but never entered an Accrue dunning campaign (e.g., Stripe-native immediate-cancel) will hit this site with `row.dunning_campaign_started_at == nil`.

**Why it happens:** Stripe can transition past_due → canceled / unpaid without ever firing through Accrue's anchor-set path. The exhausted ledger event still fires (it's the canonical loss signal) but there's no anchor to snapshot.

**How to avoid:** Defensive ISO encoding at the exhausted edge:
```elixir
iso_anchor =
  case row.dunning_campaign_started_at do
    %DateTime{} = dt -> DateTime.to_iso8601(dt)
    nil -> nil
  end
```
The funnel's `COALESCE(data->>'campaign_anchor', '__legacy__')` then naturally folds nil-anchor exhaustions into the legacy bucket per subject — under-count, not crash.

**Warning signs:** A `nil.year` `KeyError` at the exhausted-write site under a Stripe-native-immediate-cancel test fixture.

### Pitfall 3: JSONB cast crashes the dashboard

**What goes wrong:** A single malformed event row — e.g., `data: %{"mrr_value_cents" => "5000"}` (string instead of integer) — causes `(?->>'mrr_value_cents')::integer` to raise `Postgrex.Error invalid input syntax for type integer: "5000"`, which propagates out of `Repo.all` and crashes the LiveView mount.

**Why it happens:** Pre-retrofit dev/staging events may carry the field as a string. Accrue's `Events.record` does NOT validate the shape of the `data` map — by design (jsonb is schemaless).

**How to avoid:** Wrap every `::integer` cast in a `CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN ((?->>'mrr_value_cents')::integer) ELSE 0 END` (D-11). The `jsonb_typeof` check runs on the raw jsonb (via `->`, not `->>`), returning `'number'`, `'string'`, `'null'`, `'boolean'`, etc.; only `'number'` is safe to cast to integer. [VERIFIED: PostgreSQL JSON Functions docs].

**Warning signs:** `Postgrex.Error invalid input syntax for type integer:` in the LiveView crash log. Regression test (D-12) seeds the malformed row and asserts the dashboard renders.

### Pitfall 4: `Application.compile_env` for currency leaks build secrets

**What goes wrong:** Using `Application.compile_env(:accrue, :default_currency)` at compile time bakes the currency into the release artifact. Hosts that deploy a multi-tenant release with per-deploy `:default_currency` then see the WRONG currency rendered.

**Why it happens:** Easy mistake — compile_env is `Application.fetch_env!` at compile time; runtime overrides are silently ignored.

**How to avoid:** Use `Accrue.Config.get!(:default_currency)` (runtime accessor). Existing precedent at `accrue/lib/accrue/billing/metered_renewal_invoice.ex:258`. [VERIFIED: CLAUDE.md "Config Boundaries: Compile-time vs Runtime" — `default_currency` is `runtime.exs`].

**Warning signs:** JPY regression test (D-21) passes locally but fails in CI when configs differ. If the test seeds `:jpy` via `Application.put_env/3` and the helper reads from `compile_env`, the put_env has no effect.

### Pitfall 5: Funnel inner GROUP BY on `data->>'campaign_anchor'` without COALESCE

**What goes wrong:** GROUP BY `(subject_id, data->>'campaign_anchor')` with NULL anchors on legacy events. On Postgres ≤ 14, NULL values in GROUP BY columns each form their own group only if `NULLS NOT DISTINCT` is set; by default NULLs are equal (collapsed into one group) — but cross-cutting-NULL-anchor events ALSO get collapsed across different subjects, creating phantom legacy "campaigns" that span multiple subscriptions.

Actually, the worse failure: Postgres standard behavior treats NULLs as equal in GROUP BY, so all NULL-anchor events of the same `subject_id` collapse into one row — which is what we want — but a SECOND row with non-NULL anchor for the same subject does NOT collapse. So the funnel reports `entered: 2` for a single subject with one legacy + one current campaign. That's actually correct! The pitfall is subtler: if the legacy events span multiple subscriptions, each subject gets its own "legacy" bucket — but you can't tell legacy-recovered from legacy-active because you don't know if the legacy event was the start or the end of the campaign.

**How to avoid:** Per D-05, the COALESCE-to-sentinel collapses ALL legacy events per subject into ONE tuple. Whether that tuple's outcome was "recovered", "exhausted", or "active" is then determined by `bool_or` over whatever lifecycle events happen to be in the ledger for that subject + the legacy anchor. The semantics: "earliest known single-row stage attribution" — the funnel under-counts entered if a subject cycled dunning legacy-style multiple times. Document this in the `funnel/1` `@doc`.

**Warning signs:** A property test that generates only legacy events per subject and asserts `funnel.entered == count(distinct subject_id)` for the legacy-only case. NOT `count(events)`.

## Code Examples

### Example 1: Safe-cast wrap on `recovered_vs_lost_mrr/1` (D-11)

```elixir
# accrue/lib/accrue/analytics/dunning.ex (modified — line 42-47 region)

query =
  from(e in Event,
    where: e.type in [@recovered_type, @exhausted_type],
    group_by: e.type,
    select:
      {e.type,
       sum(
         fragment(
           "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' " <>
             "THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
           e.data,
           e.data
         )
       )}
  )
  |> apply_window(opts)
```

### Example 2: `funnel/1` skeleton with cycled-dunning ExDoc example

```elixir
# accrue/lib/accrue/analytics/dunning.ex (NEW)

@dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent
                            dunning.recovered dunning.exhausted]

@doc """
3-stage dunning funnel from the `accrue_events` ledger.

Counts DISTINCT `(subject_id, campaign_anchor)` tuples per stage to prevent
double-counting when a subscription cycles dunning multiple times in the window.

Pre-Phase-144 events without `campaign_anchor` fall through under a sentinel
`"__legacy__"` per subject ("earliest known single-row stage attribution") —
this UNDER-counts `entered` if a subject cycled multiple legacy campaigns.
Backfill is architecturally impossible (`accrue_events` immutability trigger).

## Options
  * `:since` — `%DateTime{}` lower bound (inclusive on `inserted_at`).
  * `:until` — `%DateTime{}` upper bound (inclusive on `inserted_at`).

## Examples

    # 1 subject, 3 campaigns: recovered → exhausted → still-active
    iex> Accrue.Analytics.Dunning.funnel()
    %{entered: 3, recovered: 1, exhausted: 1, active: 1}

@since "1.4.0"
"""
@spec funnel(keyword()) :: %{entered: non_neg_integer(),
                              recovered: non_neg_integer(),
                              exhausted: non_neg_integer(),
                              active: non_neg_integer()}
def funnel(opts \\ []) when is_list(opts) do
  per_campaign =
    from(e in Event,
      where: e.type in ^@dunning_lifecycle_types,
      group_by: [
        e.subject_id,
        fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data)
      ],
      select: %{
        has_recovered: fragment("bool_or(? = 'dunning.recovered')", e.type),
        has_exhausted: fragment("bool_or(? = 'dunning.exhausted')", e.type)
      }
    )
    |> apply_window(opts)

  from(c in subquery(per_campaign),
    select: %{
      entered:   count(),
      recovered: filter(count(), c.has_recovered),
      exhausted: filter(count(), c.has_exhausted and not c.has_recovered),
      active:    filter(count(), not c.has_recovered and not c.has_exhausted)
    }
  )
  |> Repo.one()
  |> Kernel.||(%{entered: 0, recovered: 0, exhausted: 0, active: 0})
end
```

### Example 3: Anchor retrofit at the exhausted edge (DAN-02)

```elixir
# accrue/lib/accrue/webhook/default_handler.ex — modify lines 781-814

source = dunning_source(row.dunning_sweep_attempted_at)
mrr_value_cents = calculate_mrr_cents(canonical)
currency = get(canonical, :currency) || "usd"

# DAN-02 forward-fix: snapshot the campaign anchor onto the event payload.
# `row.dunning_campaign_started_at` may be nil when a past_due subscription
# transitions to canceled/unpaid via a non-Accrue path (Stripe-native dunning
# never sets the anchor). The funnel's COALESCE-to-sentinel handles nil.
iso_anchor =
  case row.dunning_campaign_started_at do
    %DateTime{} = dt -> DateTime.to_iso8601(dt)
    _ -> nil
  end

# … existing :telemetry.execute call unchanged …

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

### Example 4: Anchor retrofit at the recovered edge (DAN-02)

```elixir
# accrue/lib/accrue/webhook/default_handler.ex — modify lines 878-897
# iso_anchor is already in scope at line 868.

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
        currency: currency,
        campaign_anchor: iso_anchor
      }
    })
  else
    multi
  end
```

### Example 5: MoneyFormatter swap on RecoveryLive (DAN-13)

```elixir
# accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex — modify render/1 + delete format_minor/1

alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FunnelChart, KpiCard, MoneyFormatter}

# In render/1 — replace the value attribute:
<KpiCard.kpi_card label="Recovered MRR" delta="…" delta_tone="moss">
  <:meta>Money Saved</:meta>
  <%!-- compute formatted string up-front for the value slot --%>
</KpiCard.kpi_card>
```

Note: `KpiCard` requires `value` as a String attr (`attr(:value, :string, required: true)`). The cleanest swap is to assign a formatted string in `mount/3` rather than nesting `<MoneyFormatter>` inside `<KpiCard>` (the attr type forbids that). Compute in `mount/3`:

```elixir
# In mount/3:
stats = Dunning.recovered_vs_lost_mrr()
currency = Accrue.Config.get!(:default_currency)
locale = Accrue.Config.default_locale()
recovered_str = Accrue.Invoices.Render.format_money(stats.recovered_cents, currency, locale)
exhausted_str = Accrue.Invoices.Render.format_money(stats.lost_cents, currency, locale)

{:ok,
 socket
 |> assign_shell(admin)
 |> assign(:stats, stats)
 |> assign(:recovered_str, recovered_str)
 |> assign(:exhausted_str, exhausted_str)
 |> assign(:funnel, Dunning.funnel())}
```

Then in render:
```heex
<KpiCard.kpi_card label="Recovered MRR" value={@recovered_str} delta="Amount saved by successful Dunning" delta_tone="moss">
  <:meta>Money Saved</:meta>
</KpiCard.kpi_card>

<KpiCard.kpi_card label="Exhausted MRR" value={@exhausted_str} delta="Amount lost to terminal Dunning failure" delta_tone="amber">
  <:meta>Churned Revenue</:meta>
</KpiCard.kpi_card>
```

### Example 6: Property test (DAN-01)

```elixir
# accrue/test/property/dunning_funnel_property_test.exs (NEW)

defmodule Accrue.Property.DunningFunnelPropertyTest do
  use Accrue.RepoCase, async: false
  use ExUnitProperties

  alias Accrue.Analytics.Dunning

  @types ~w[dunning.campaign_started dunning.step_sent
            dunning.recovered dunning.exhausted]

  # Generator: a sequence of dunning events for a single subject across N campaigns.
  defp campaign_sequence_gen do
    StreamData.list_of(
      StreamData.tuple({
        StreamData.member_of(["sub_a", "sub_b", "sub_c"]),
        StreamData.member_of(@types),
        StreamData.string(:alphanumeric, min_length: 1, max_length: 16)
      }),
      min_length: 0,
      max_length: 30
    )
  end

  property "recovered + exhausted + active ≤ entered (per-campaign DISTINCT)" do
    check all events <- campaign_sequence_gen() do
      Accrue.Repo.delete_all(Accrue.Events.Event)

      Enum.each(events, fn {subject_id, type, anchor} ->
        Accrue.Repo.insert!(%Accrue.Events.Event{
          type: type,
          subject_type: "Subscription",
          subject_id: subject_id,
          actor_type: "system",
          schema_version: 1,
          data: %{"campaign_anchor" => anchor}
        })
      end)

      result = Dunning.funnel()
      assert result.recovered + result.exhausted + result.active <= result.entered
    end
  end
end
```

### Example 7: Anchor-presence retrofit assertion (DAN-02, DAN-10)

```elixir
# accrue/test/accrue/webhook/dunning_exhaustion_test.exs — extend the test at :294-318

test "the confirmed terminal transition records a ledger event with campaign_anchor", %{sub: sub, sub_id: sub_id} do
  # Set an anchor first so we have something to snapshot.
  anchor = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
  sub
  |> Accrue.Billing.Subscription.force_status_changeset(%{dunning_campaign_started_at: anchor})
  |> Accrue.Repo.update!()

  stub_subscription_fetch(sub_id, :canceled)
  # … existing webhook event firing …

  assert [ledger] = ledger_events("dunning.exhausted", sub.id)
  assert ledger.data["campaign_anchor"] |> is_binary()
  assert {:ok, _dt, _} = DateTime.from_iso8601(ledger.data["campaign_anchor"])
end

test "exhaustion without a live anchor records campaign_anchor: nil (legacy bucket)", %{sub: sub, sub_id: sub_id} do
  # Don't set the anchor — Stripe-native non-Accrue dunning path.
  stub_subscription_fetch(sub_id, :canceled)
  # … existing webhook event firing …

  assert [ledger] = ledger_events("dunning.exhausted", sub.id)
  assert is_nil(ledger.data["campaign_anchor"])
end
```

### Example 8: JPY regression test (DAN-13)

```elixir
# accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs — add to top of file or new describe block

describe "JPY rendering (DAN-13)" do
  setup do
    prior = Application.get_env(:accrue, :default_currency)
    Application.put_env(:accrue, :default_currency, :jpy)
    on_exit(fn ->
      if is_nil(prior),
        do: Application.delete_env(:accrue, :default_currency),
        else: Application.put_env(:accrue, :default_currency, prior)
    end)

    Events.record(%{
      type: "dunning.recovered",
      subject_type: "Subscription",
      subject_id: "sub_jpy",
      data: %{mrr_value_cents: 5000, currency: "jpy"}
    })

    :ok
  end

  test "JPY events render with ¥ symbol, not $", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

    # CLDR may render "¥5,000" or "￥5,000" or locale-equivalent. Assert no "$".
    refute html =~ "$50.00"
    assert html =~ "¥" or html =~ "￥" or html =~ "JPY"
  end
end
```

### Example 9: CSS additions (D-17)

```css
/* accrue_admin/assets/css/app.css — append adjacent to .ax-kpi-* block (after line 560) */

.ax-funnel-chart {
  display: grid;
  gap: var(--ax-space-md);
}

.ax-funnel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--ax-space-md);
}

.ax-funnel-active-chip {
  display: inline-flex;
  align-items: center;
  padding: var(--ax-space-xs) var(--ax-space-sm);
  border-radius: 999px;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--ax-accent-readable);
  background: color-mix(in srgb, var(--ax-accent) 16%, transparent);
}

.ax-funnel-svg {
  width: 100%;
  height: 3.5rem;
}

.ax-funnel-row--slate .ax-funnel-bar { fill: color-mix(in srgb, var(--ax-muted) 28%, transparent); }
.ax-funnel-row--moss  .ax-funnel-bar { fill: var(--ax-success); }
.ax-funnel-row--amber .ax-funnel-bar { fill: var(--ax-warning); }

.ax-funnel-legend {
  display: grid;
  gap: var(--ax-space-xs);
  margin: 0;
}

.ax-funnel-legend-row {
  display: flex;
  justify-content: space-between;
  font-size: 0.875rem;
}

.ax-funnel-legend-row dt {
  font-weight: 600;
}

.ax-funnel-legend-row dd {
  margin: 0;
  color: var(--ax-primary);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `:erlang.float_to_binary` with `"$"` prefix (USD-only) | `Accrue.Invoices.Render.format_money/3` (CLDR via ex_money/ex_cldr) | Pre-existing in `MoneyFormatter`; P144 retrofits the last hard-coded USD site | DAN-13: JPY/EUR/GBP/USD all render correctly. |
| `(?->>'k')::integer` naked cast | `CASE WHEN jsonb_typeof((?->'k')) = 'number' THEN (?->>'k')::integer ELSE 0 END` | P144 (DAN-08) | Single bad row no longer crashes the dashboard. |
| Counting raw events for funnel stages | DISTINCT `(subject_id, campaign_anchor)` tuples via two-level GROUP BY | P144 (DAN-01) — anchor field newly snapshotted (DAN-02) | Cycled-dunning subscriptions counted once per campaign cycle. |
| Lost MRR (label only) | Exhausted MRR (label) + tooltip with yearly-plan worked example | P144 (DAN-13 + roadmap success criterion #5) | Aligns label with funnel stage; explains the annualized-snapshot semantics. |

**Deprecated/outdated:**
- `RecoveryLive.format_minor/1` private helper (lines 76-81) — DELETE after the MoneyFormatter swap.
- Phase 143 emission-boundary test coverage gap (verification log §"Notes / Minor Observations" #1) — CLOSED by the DAN-02 retrofit's new test assertions.

## Runtime State Inventory

Phase 144 is greenfield-additive code (new function, new component, new CSS) with surgical write-path edits. It is NOT a rename/refactor/migration. The Runtime State Inventory section does not apply — no stored data, live service config, OS state, secrets, or build artifacts are affected by this phase.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no data migration. `accrue_events` is append-only; the retrofit only changes the shape of FUTURE writes. Legacy events fall through the `'__legacy__'` sentinel by design (D-05). | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets / env vars | `:default_currency` and `:default_locale` already exist in `Accrue.Config` schema; P144 reads them at runtime via `Config.get!/0`. No new env vars. | None |
| Build artifacts | None | None |

## Environment Availability

Phase 144 introduces zero new external dependencies. All tooling required is already in the project.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | All Ecto queries (`jsonb_typeof`, `COUNT FILTER`, `bool_or`, `COALESCE`) | ✓ | 14+ (project floor) | — |
| `:ecto_sql` | Existing analytics + retrofit | ✓ | `~> 3.13` (pinned in `mix.exs`) | — |
| `:postgrex` | PG driver | ✓ | `~> 0.22` | — |
| `:phoenix_live_view` | `Phoenix.Component` for FunnelChart + LiveView for RecoveryLive | ✓ | `~> 1.1` | — |
| `:stream_data` | Property test (DAN-01) | ✓ | `~> 1.3` (`only: [:dev, :test]` in `accrue/mix.exs:104`) | — |
| `:ex_money` + `:ex_cldr` | `Render.format_money/3` for DAN-13 | ✓ | (transitive via existing `MoneyFormatter` wiring) | Double-fallback to raw `"N currency"` string is already in `Render.format_money/3` at `:106-132`. |
| ChromicPDF (Chrome) | NOT required by P144 | n/a | — | — |
| MJML / Rustler | NOT required by P144 | n/a | — | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Project Constraints (from CLAUDE.md)

Pulled directly from `./CLAUDE.md`; the planner must verify P144 complies with each.

| # | Constraint | P144 Compliance |
|---|-----------|-----------------|
| C1 | **Tech stack:** Elixir ~> 1.17, OTP 27+, Phoenix ~> 1.8, Ecto ~> 3.13, PostgreSQL 14+. No legacy OTP support. | ✓ Uses only Ecto 3.13 / PG 14 features. |
| C2 | **Dependencies (required):** No new mix deps in P144. | ✓ Zero new deps. |
| C3 | **Release model:** ship complete. No public v0.x iteration. Internal phases are build milestones. | ✓ P144 is a build milestone within v1.44. |
| C4 | **Security: Webhook signature verification mandatory and non-bypassable. Raw-body plug before `Plug.Parsers`. Sensitive Stripe fields never logged. Payment method details stored as Stripe references, never as PII.** | ✓ P144 touches `default_handler.ex` inside `Events.record` calls — no new logging; `campaign_anchor` is an ISO-8601 string, not PII. Existing T-129-01 "no PII in data/metadata" posture preserved. |
| C5 | **Performance: webhook request path <100ms p99.** | ✓ Retrofit adds two map-key writes (`campaign_anchor: iso_anchor`) — negligible overhead. Funnel query runs on the LiveView mount path, not the webhook path. |
| C6 | **Observability: all public entry points emit `:telemetry` start/stop/exception events.** | ✓ `Dunning.funnel/1` is a new public entry point — planner should add `[:accrue, :analytics, :funnel]` `:telemetry.span/3` wrapping. (NOT in CONTEXT.md decisions; planner discretion or follow-up to v1.45+ — flag in plan.) |
| C7 | **Monorepo: `accrue/` and `accrue_admin/`. Shared `.github/workflows/`. Per-package `CHANGELOG.md`.** | ✓ P144 spans both packages; CHANGELOG entries needed in both (DAN-02 + DAN-08 + DAN-01 → `accrue/CHANGELOG.md`; DAN-09 + DAN-13 → `accrue_admin/CHANGELOG.md`). |
| C8 | **License: MIT for both packages.** | ✓ No new files require headers; both packages already MIT. |
| C9 | **`phoenix_live_view` required core dep; core stays LiveView-runtime-free; `phoenix_live_view` never in `extra_applications`.** | ✓ `FunnelChart` uses `use Phoenix.Component` (no socket runtime). Code lives in `accrue_admin`, not core `accrue`. |
| C10 | **GSD Workflow Enforcement:** before Edit/Write, start work through a GSD command. | ✓ This research is executing under `/gsd:plan-phase 144`. |
| C11 | **Dunning campaign anchor design (C9 in CLAUDE.md):** `dunning_campaign_started_at` is a single nullable column on `accrue_subscriptions`. Stash `iso_anchor` (anchor at recovery, read from `row` BEFORE clear). | ✓ The retrofit READS `row.dunning_campaign_started_at` BEFORE the `force_status_changeset` clear. iso_anchor lifetime: captured at line 868, used at line 893 (recovered); captured fresh in maybe_emit_dunning_exhaustion (exhausted). |

**Note on C6 (telemetry):** CONTEXT.md does not explicitly list a telemetry-span requirement for `funnel/1`. The planner should decide whether to add `:telemetry.span([:accrue, :analytics, :funnel], …)` around the query body. Recommendation: yes — mirror the existing `recovered_vs_lost_mrr/1` patterns if any exist (currently none, by inspection). Treat as Claude's discretion bullet not yet in CONTEXT.md; surface to user before locking.

## Open Questions (RESOLVED)

1. **Does `recovered_vs_lost_mrr/1` currently emit `:telemetry`?**
   - What we know: Inspection of `accrue/lib/accrue/analytics/dunning.ex` shows NO `:telemetry.execute` or `:telemetry.span` call. CLAUDE.md Performance section says "all public entry points emit `:telemetry` start/stop/exception events" — `recovered_vs_lost_mrr/1` is a public entry point.
   - What's unclear: Whether Phase 143 was meant to add telemetry and missed it, or whether the analytics tier is exempted.
   - Recommendation: Planner adds `:telemetry.span([:accrue, :analytics, :funnel], %{}, fn -> {query_result, %{}} end)` around `funnel/1` and mirrors the same for `recovered_vs_lost_mrr/1` as a same-PR consistency edit. Flag for user confirmation if they want to defer the `recovered_vs_lost_mrr/1` part to Phase 148's docs-cleanup wave.
   - **RESOLVED:** Defer telemetry instrumentation. Plan 01 Task 2 explicitly does NOT add `:telemetry.span` around `funnel/1` (no telemetry call in the action). CONTEXT.md decisions (D-01..D-23) do not require telemetry; CLAUDE.md C6 ambiguity is acknowledged and a follow-up observability-tier cleanup (Phase 148+ or later) is the chosen path. Both `funnel/1` and `recovered_vs_lost_mrr/1` remain telemetry-free in P144 for consistency.

2. **Should `FunnelChart` accept ALL four counts including `active`, or should `active` be a separate chip?**
   - What we know: D-13 says three rows (entered, recovered, exhausted). Specifics §"Active count exposure" says active is rendered "adjacent to the funnel (NOT as a 4th bar)".
   - What's unclear: Whether the chip lives INSIDE FunnelChart (component owns it) or OUTSIDE (RecoveryLive owns it).
   - Recommendation: INSIDE the FunnelChart `<header>` (as shown in Example 3) — keeps the visual contract self-contained. Single attr surface for the LiveView.
   - **RESOLVED:** Active chip lives INSIDE the FunnelChart component. Plan 03 builds `AccrueAdmin.Components.FunnelChart` as a single Phoenix.Component owning all four attrs (`entered`, `recovered`, `exhausted`, `active`) and renders the active chip in the component's `<header>`. RecoveryLive (Plan 04) passes all four counts via one `<FunnelChart.funnel_chart>` slot — no separate chip wiring on the LiveView side.

3. **Does the funnel `since`/`until` window filter by event `inserted_at` or by `campaign_anchor`?**
   - What we know: D-01 doesn't specify. Phase 143's `recovered_vs_lost_mrr/1` filters on `inserted_at` (the event timestamp).
   - What's unclear: For the funnel, "this campaign happened in the window" could mean (a) the campaign started in the window, (b) the campaign concluded in the window, or (c) any lifecycle event of the campaign fell in the window.
   - Recommendation: Filter on `inserted_at` of any event (option c) for P144 to mirror `recovered_vs_lost_mrr/1`. This means a campaign that started outside the window but concluded inside it counts. Document explicitly in the `@doc`. Phase 145 owns more nuanced window semantics if needed.
   - **RESOLVED:** Filter on `inserted_at` (option c — any lifecycle event in the window). Plan 01 Task 2 applies `apply_window/2` to the inner subquery before grouping, which bounds the inner `where: e.type in ^@dunning_lifecycle_types` query by `inserted_at` — mirroring `recovered_vs_lost_mrr/1`'s precedent. The `@doc` for `funnel/1` (per the action) explicitly documents this window semantics. Phase 145 owns any future campaign-anchor-based window semantics.

4. **`active` count includes legacy `'__legacy__'` campaigns that may never have ended — is that desirable?**
   - What we know: Per D-05, legacy events collapse to one tuple per subject; if there's no recovered/exhausted event for that subject, the tuple lands in `active`.
   - What's unclear: For an adopter with a subscription that recovered LEGACY-style (pre-P144) but has no recovered event in the ledger because the recovered event predates Phase 143's snapshotting (`mrr_value_cents` wasn't added until P143), the funnel may report it as "active" forever.
   - Recommendation: Acknowledge in the `@doc` that the legacy bucket conflates active and pre-snapshot-recovered. This is the under-counting failure mode. Phase 148's `guides/analytics.md` cutoff-date badge handles this in the UI.
   - **RESOLVED:** Document the legacy-bucket ambiguity in the `@doc`, accept the under-counting failure mode for P144. Plan 01 Task 2's action explicitly requires the `@doc` to document the `'__legacy__'` sentinel as "earliest known single-row stage attribution" — making the conflation explicit. Plan 01 Task 3's property test confirms the invariant `recovered + exhausted + active ≤ entered` still holds because the filter predicates are mutually exclusive. Phase 148's `guides/analytics.md` cutoff-date badge handles the UI-side disclosure.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Ecto.Query.API.filter/2` (the `count() \|> filter(...)` syntax) compiles cleanly under `:ecto ~> 3.13`. | Code Examples §2 | LOW — `filter/2` is in Ecto since 3.5; verified in Ecto docs. If compilation fails, fall back to `fragment("COUNT(*) FILTER (WHERE ?)", c.has_recovered)`. |
| A2 | `bool_or` is available in PostgreSQL 14 without extensions. | Architecture Patterns §2 | LOW — `bool_or` is a standard SQL aggregate, in PG since pre-9.0. |
| A3 | `jsonb_typeof` on a NULL jsonb returns `'null'`, not NULL. So `jsonb_typeof((?->'mrr_value_cents'))` for an absent key returns `'null'`, which does not match `'number'`, falling through to `ELSE 0`. | Pitfall #3 + Safe-cast example | LOW — verified in PG docs: `jsonb_typeof(NULL)` returns NULL, but `data->'missing_key'` returns SQL NULL → `jsonb_typeof` on SQL NULL returns NULL → CASE WHEN NULL = 'number' is NOT TRUE → ELSE 0. Safe either way. |
| A4 | `MoneyFormatter` accepts `currency` as `:jpy` atom (not just `"jpy"` string). | DAN-13 Examples | LOW — verified at `money_formatter.ex:53-65`: atom currency passes through `normalize_currency/1`; string is downcased + `String.to_existing_atom`. |
| A5 | `Accrue.Config.get!(:default_currency)` returns the atom `:jpy` (not the string `"jpy"`) when set via `Application.put_env(:accrue, :default_currency, :jpy)`. | DAN-13 setup | LOW — verified at `config.ex:165-169`, `default_currency` schema is `type: :atom, default: :usd`. NimbleOptions validates the atom shape. |
| A6 | `KpiCard.kpi_card`'s `value` attr is `:string, required: true` and does NOT accept a function component as child. | Example 5 | LOW — verified at `kpi_card.ex:12`: `attr(:value, :string, required: true)`. The MoneyFormatter swap must compute the string in `mount/3` and pass it through. |
| A7 | PG `GROUP BY (subject_id, COALESCE(data->>'campaign_anchor', '__legacy__'))` semantics on PG 14: NULLs in GROUP BY columns are collapsed into one group per (other columns); the COALESCE produces a non-NULL sentinel so the issue is moot. | Pitfall #5 | LOW — verified in PG 14 GROUP BY semantics docs. COALESCE makes the question irrelevant. |
| A8 | The funnel's inner query result fits in memory for adopter-typical event volumes (< 100k rows). | Performance / planner discretion | MEDIUM — for very large ledgers, the inner subquery materializes one row per `(subject, anchor)` tuple. Phase 148's `guides/analytics.md` discusses the ~100k events expression-index threshold. Not blocking for P144. |
| A9 | The "Exhausted MRR" rename is purely a UI label change — no `recovered_vs_lost_mrr/1` return shape change (`lost_cents` key stays). | DAN-13 (D-23) | LOW — D-20 explicitly locks the shape until P148. |
| A10 | `verify_package_docs.sh` does NOT yet have an "analytics guide" needle, so adding `Accrue.Analytics.Dunning.funnel/1` to the public API does NOT require a same-phase script update. | CLAUDE.md verify_package_docs coupling | LOW — P148 owns the `guides/analytics.md` + `verify_package_docs.sh` needle update (DAN-14, DAN-15). |

## Validation Architecture

> Required because `workflow.nyquist_validation = true` in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + ExUnitProperties (StreamData) — already in project |
| Config file | `accrue/config/test.exs` (existing); `accrue_admin/config/test.exs` (existing) |
| Quick run command | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` (analytics) |
| | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` (UI) |
| Full suite command | `cd accrue && mix test` && `cd accrue_admin && mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DAN-01 (funnel API) | `funnel()` returns `%{entered, recovered, exhausted, active}` over a window | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs -t funnel` | ✅ extend existing file |
| DAN-01 (DISTINCT-tuple) | Cycled-dunning subject counted once per anchor | unit + property | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` and `cd accrue && mix test test/property/dunning_funnel_property_test.exs` | ❌ Wave 0 — create `test/property/dunning_funnel_property_test.exs` |
| DAN-01 (invariant) | `recovered + exhausted + active ≤ entered` | property | `cd accrue && mix test test/property/dunning_funnel_property_test.exs` | ❌ Wave 0 |
| DAN-02 (exhausted retrofit) | `dunning.exhausted` event carries `campaign_anchor: <iso8601 or nil>` | unit (emission boundary) | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs` | ✅ extend existing file at :308-311 |
| DAN-02 (recovered retrofit) | `dunning.recovered` event carries `campaign_anchor: <iso8601>` | unit (emission boundary) | `cd accrue && mix test test/accrue/webhook/dunning_campaign_keying_test.exs` | ✅ extend existing file at :369-370 |
| DAN-08 (JSONB safe-cast) | Malformed `"mrr_value_cents": "5000"` row does not crash `recovered_vs_lost_mrr/1` | unit (regression) | `cd accrue && mix test test/accrue/analytics/dunning_test.exs -t malformed_jsonb` | ✅ extend existing file |
| DAN-09 (FunnelChart render) | Mounted dashboard renders SVG funnel with entered count, recovered count, exhausted count, active chip | integration (LiveView) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ extend existing file |
| DAN-09 (cycled-dunning render) | Subscription cycled 3 times shows `entered: 3, recovered: 1, exhausted: 1, active: 1` | integration (LiveView with seeded events) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ extend existing file |
| DAN-13 (MoneyFormatter) | KPI cards render `¥`/`€`/`£`/`$` based on `Accrue.Config.default_currency()` | integration (LiveView JPY regression) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs -t jpy_regression` | ✅ extend existing file |
| roadmap SC#5 ("Exhausted MRR" rename) | KPI card label reads "Exhausted MRR", not "Lost MRR"; tooltip + worked example present | integration (HTML assertion) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ extend existing file |
| Phase 143 verification gap (info-only) | `dunning.exhausted` event carries `mrr_value_cents` at the emission boundary | unit (emission boundary — already incidentally covered by DAN-02 test extension) | (covered by DAN-02 retrofit test) | ✅ |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/analytics/dunning_test.exs` (sub-second).
- **Per wave merge:**
  - Wave A (funnel API + safe-cast): `cd accrue && mix test test/accrue/analytics/ test/property/dunning_funnel_property_test.exs`
  - Wave B (retrofit): `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs test/accrue/webhook/dunning_campaign_keying_test.exs test/accrue/webhook/default_handler_test.exs`
  - Wave C (UI): `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs`
- **Phase gate:** Full `mix test` in both `accrue/` and `accrue_admin/` green before `/gsd:verify-work`.

### Wave 0 Gaps

- [ ] `accrue/test/property/dunning_funnel_property_test.exs` — NEW file. Covers DAN-01 property invariant.
- [ ] No framework install needed — `stream_data ~> 1.3` is already in `accrue/mix.exs:104`.
- [ ] No new conftest / shared fixtures needed — existing `Accrue.RepoCase` (async: false) suffices for analytics tests; existing `AccrueAdmin.LiveCase` (async: false) suffices for LiveView tests.

### Dimensions covered (per the orchestrator's required §"Validation Architecture")

- **Unit / property:** funnel math invariant (`recovered + exhausted + active ≤ entered`) + DISTINCT-tuple property test in `test/property/dunning_funnel_property_test.exs`.
- **Integration:** Full mount of `/billing/analytics/recovery` with seeded events covering (a) the cycled-dunning case (success criterion #2) and (b) the malformed-row case (success criterion #3).
- **Regression:** JPY render (success criterion #4) + Lost MRR→Exhausted MRR copy rename (success criterion #5).
- **Boundary:** Retrofit emission boundary tests for both exhausted and recovered edges (DAN-02 + closing Phase 143's verification gap §"Notes" #1).
- **Performance:** NOT in scope for P144. The funnel inner-subquery cost on adopter-typical ledgers (< 100k events) is acceptable; expression-index guidance lives in Phase 148's `guides/analytics.md`. The `/gsd:verify-work` checker should NOT ask for a perf benchmark.

## Security Domain

> `security_enforcement` is not explicitly set to `false` in `.planning/config.json` — treat as enabled. P144 is a low-risk additive phase; most ASVS categories are inherited from Phase 143's threat model (T-143-01, T-143-02). New surface analysis:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherited) | `live_session :accrue_admin` admin-auth on `/billing/analytics/recovery` — unchanged from P143. |
| V3 Session Management | yes (inherited) | Inherited from `live_session :accrue_admin` block in `router.ex:52-86`. |
| V4 Access Control | yes (inherited) | `on_mount {AccrueAdmin.AuthHook, :ensure_admin}` (default for the block). |
| V5 Input Validation | yes | `:since`/`:until` opts bound via Ecto `^` parameter binding — never string-interpolated into fragments. Re-affirmed in `apply_window/2` at `dunning.ex:58-72`. |
| V6 Cryptography | no | P144 introduces no crypto primitives. |
| V8 Data Protection | yes | `campaign_anchor` is an ISO-8601 datetime string — not PII. `mrr_value_cents` is an integer. No new PII surface. |
| V9 Communications | no | All HTTP is server-side admin LiveView; no new outbound. |
| V14 Configuration | yes | `Accrue.Config.get!(:default_currency)` is the runtime read — verified at `metered_renewal_invoice.ex:258` precedent. NOT `Application.compile_env`. |

### Known Threat Patterns for `accrue` analytics surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Information Disclosure (analytics path leaks customer data) | Information Disclosure | Route nested in `live_session :accrue_admin` — admin auth required. Data carries only IDs + enums + integers + ISO datetime; no PII (T-129-01 reaffirmed). |
| Elevation of Privilege (non-admin access to recovery dashboard) | Elevation of Privilege | `on_mount {AccrueAdmin.AuthHook, :ensure_admin}` — inherited from P143. |
| SQL Injection via opts | Tampering | Ecto `^` parameter binding for `:since`/`:until`. Verified safe in P143 (T-143-01). |
| JSONB cast crash (DoS via malformed event row) | Denial of Service | `CASE WHEN jsonb_typeof(...) = 'number' ... ELSE 0` safe-cast (D-11). New mitigation in P144. |
| Funnel double-counting (reporting integrity) | Tampering (logic) | DISTINCT-tuple GROUP BY with anchor (D-01, D-05). Property test enforces invariant. New mitigation in P144. |

### New threats introduced by P144

- **T-144-01 (DoS via malformed JSONB):** A single event row with `"mrr_value_cents": "string"` could crash the dashboard mount. Mitigation: D-11 safe-cast.
- **T-144-02 (Funnel reporting integrity):** Cycled-dunning subjects could be double-counted, misleading operators about real recovery rate. Mitigation: D-01 DISTINCT-tuple + D-02 anchor snapshot + property test (D-04).

Both threats are surfaced + mitigated within the same phase — no follow-up needed.

## Sources

### Primary (HIGH confidence)

- **Source files read** (all in `/Users/jon/projects/accrue/`):
  - `accrue/lib/accrue/analytics/dunning.ex` (full, 73 lines)
  - `accrue/lib/accrue/webhook/default_handler.ex` (lines 740-905, 1885-1924)
  - `accrue/lib/accrue/events.ex` (lines 100-160)
  - `accrue/lib/accrue/events/event.ex` (lines 1-50)
  - `accrue/lib/accrue/config.ex` (lines 160-170, 370-390, 1010-1030)
  - `accrue/lib/accrue/invoices/render.ex` (lines 100-150)
  - `accrue/lib/accrue/billing/subscription.ex` (lines 60-95, 240-275 — anchor field + `dunning_sweepable?`/`dunning_campaign_active?`)
  - `accrue/lib/accrue/billing/metered_renewal_invoice.ex` (lines 250-260 — `default_currency` runtime read precedent)
  - `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (full, 86 lines)
  - `accrue_admin/lib/accrue_admin/components/kpi_card.ex` (full, 68 lines)
  - `accrue_admin/lib/accrue_admin/components/money_formatter.ex` (full, 77 lines)
  - `accrue_admin/assets/css/app.css` (lines 100-560 — ax-kpi-* + ax-funnel-* adjacency)
  - `accrue/test/accrue/analytics/dunning_test.exs` (full, 83 lines)
  - `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` (lines 290-340)
  - `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` (lines 1-60, 355-389)
  - `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` (full, 66 lines)
  - `accrue/test/property/dunning_campaign_property_test.exs` (lines 1-80 — property-test precedent)
  - `accrue/test/accrue/config_test.exs` (lines 125-140 — `Application.put_env(:accrue, :default_currency, …)` precedent)
- **Planning docs read:**
  - `.planning/phases/144-…/144-CONTEXT.md` (full)
  - `.planning/REQUIREMENTS.md` (DAN-01..16)
  - `.planning/ROADMAP.md` (phase 144 detail)
  - `.planning/STATE.md` (milestone progress)
  - `.planning/phases/143/143-VERIFICATION.md` (full)
  - `.planning/phases/143/143-PATTERNS.md` (full)
  - `.planning/phases/143/143-RESEARCH.md` (lines 1-120)
- **CLAUDE.md** (full — read at session start)
- **`.planning/config.json`** (workflow flags)

### Secondary (MEDIUM confidence)

- **PostgreSQL documentation** (via training knowledge — verified consistent with PG 14 docs):
  - `jsonb_typeof(jsonb) → text` — returns `'object'`, `'array'`, `'string'`, `'number'`, `'boolean'`, `'null'`; in PG since 9.4.
  - `bool_or(boolean)` aggregate — standard SQL, in PG since pre-9.0.
  - `COUNT(*) FILTER (WHERE predicate)` syntax — SQL:2003, in PG since 9.4.
  - `COALESCE(expr, expr, ...)` — standard SQL.
- **Ecto.Query documentation:**
  - `Ecto.Query.API.filter/2` — since Ecto 3.5.
  - `Ecto.Query.API.fragment/1` with repeated `?` positional args — verified by reading analogous calls in `recovered_vs_lost_mrr/1`.

### Tertiary (LOW confidence)

None — every load-bearing claim is verified against source code or planning docs.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — every dependency already pinned in `mix.exs`; zero new packages.
- Architecture (funnel SQL shape, retrofit edits, FunnelChart component shape, money formatter swap): **HIGH** — direct source reads of every touchpoint; Phase 143 precedents documented in 143-PATTERNS.md.
- Pitfalls: **HIGH** — Pitfall #2 (anchor unavailable at exhausted edge) was confirmed by reading `Subscription.dunning_sweepable?/1` source; other pitfalls are straightforward Postgres / Ecto correctness.
- Security: **HIGH** — inherits Phase 143's verified threat model; two new threats fully mitigated within phase.
- Validation: **HIGH** — all test files exist except one new property test file; commands runnable.

**Research date:** 2026-05-27
**Valid until:** 2026-06-27 (30 days — stable mature stack; no fast-moving deps).

## RESEARCH COMPLETE

**Phase:** 144 — Funnel query + viz + campaign-anchor retrofit + money formatter polish
**Confidence:** HIGH

### Key Findings

- **Funnel SQL shape validated:** two-level GROUP BY with `bool_or` + `filter(count(), …)` compiles cleanly in Ecto ~> 3.13 against PG 14+. All required Postgres features (`jsonb_typeof`, `COUNT FILTER`, `bool_or`, `COALESCE`) verified present at PG 9.4+ (well within the project's PG 14+ floor).
- **Anchor retrofit asymmetry surfaced:** `iso_anchor` is already in scope at the recovered edge (line 868) but NOT at the exhausted edge — the retrofit must compute it defensively because `Subscription.dunning_sweepable?/1` allows past_due→unpaid transitions without an active anchor.
- **JSONB safe-cast canonicalized:** `CASE WHEN jsonb_typeof((?->'k')) = 'number' THEN (?->>'k')::integer ELSE 0 END` is cleaner than REQUIREMENTS DAN-08's `(?->>'k')::jsonb` round-trip; uses `->` (returns jsonb directly) inside `jsonb_typeof`.
- **MoneyFormatter wiring confirmed:** `MoneyFormatter` already resolves the locale precedence ladder; `Accrue.Config.get!(:default_currency)` is the runtime accessor (precedent at `metered_renewal_invoice.ex:258`). `KpiCard`'s `value` attr is `:string` typed — the LiveView must compute the formatted string in `mount/3` rather than nest `<MoneyFormatter>` inside `<KpiCard>`.
- **Zero new mix deps; zero schema changes:** every library and accessor required is already in the project. `accrue_events.data` is jsonb so `campaign_anchor` injection requires no migration.
- **Phase 143 emission-boundary gap closes naturally:** the new DAN-02 retrofit tests assert `campaign_anchor` presence, which incidentally also covers the `mrr_value_cents`-at-emission-boundary gap noted in 143-VERIFICATION.md §Notes #1.

### File Created

`/Users/jon/projects/accrue/.planning/phases/144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po/144-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Zero new deps; all versions verified in `mix.exs` |
| Architecture (funnel SQL, retrofit, FunnelChart, MoneyFormatter swap) | HIGH | Every touchpoint read at source; Phase 143 precedents apply |
| Pitfalls | HIGH | Source-verified (esp. anchor-unavailable-at-exhausted edge case) |
| Security | HIGH | Inherits P143 threat model; two new threats mitigated in-phase |
| Validation Architecture | HIGH | All test files exist except one new property test |

### Open Questions (surface to planner)

1. Whether to add `:telemetry.span([:accrue, :analytics, :funnel], …)` around `funnel/1` (CLAUDE.md C6 implies yes; CONTEXT.md doesn't mention).
2. Funnel `:since`/`:until` window filters `inserted_at` of any lifecycle event (mirror `recovered_vs_lost_mrr/1`) — confirm with `@doc`.
3. `'__legacy__'` bucket conflates active and pre-snapshot-recovered legacy subjects — acknowledge in `@doc`.

### Ready for Planning

Research complete. Planner can now decompose Phase 144 into ~4 plans (analytics core + safe-cast, write-path retrofit, FunnelChart component + CSS, LiveView wiring + MoneyFormatter swap + label rename + JPY regression test) and create PLAN.md files. Every decision needed by the plans is documented above with source citations; no further investigation required before planning begins.
