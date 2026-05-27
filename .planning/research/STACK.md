# Technology Stack — v1.44 Recovered-Revenue Dashboard Completion

**Researched:** 2026-05-27
**Scope:** Subsequent-milestone STACK delta only. Phase 143 already locked the foundation (Ecto JSONB aggregator + admin LiveView page + KPI cards). This file answers only "what *new* stack additions does v1.44 need?"
**Overall confidence:** HIGH

## TL;DR

**Zero new runtime dependencies are required for v1.44.** The existing stack already covers every capability the milestone needs:

- **Funnel viz** → pure HEEx + SVG (or CSS), no JS chart library.
- **Date-window math** → stdlib `DateTime` + `Calendar` modules, no `timex`.
- **Money formatting** → `Accrue.Invoices.Render.format_money/3` (already CLDR-aware via `:ex_money` 5.24.2 transitively pulling `:ex_cldr_numbers` 2.38.1) — reuse, don't roll inline.
- **At-risk drill-down table** → `AccrueAdmin.Components.DataTable` (LiveComponent, already shipped) — adopt LiveView 1.1 `Phoenix.LiveView.stream/4` for the row collection if the at-risk set is unbounded.
- **Time-window filters** → existing `handle_params` + `URI.encode_query` + `AccrueAdmin.Components.FilterChipBar` pattern (used in 9+ admin LiveViews already).
- **Tests** → existing `:stream_data` (property tests for window math) + `Phoenix.LiveViewTest` (HTML assertions, already in `accrue_admin/test/support`).

This is the lightest possible delta. It preserves the "lightweight OSS footprint" design constraint and the "no-new-tables, aggregate-existing-event-ledger-only" rule from Phase 143.

## Recommended Stack (Delta over the v1.43 baseline)

### NO new runtime dependencies

| Capability | Existing Tool | Version | Why It Suffices |
|------------|---------------|---------|-----------------|
| Funnel SVG/CSS rendering | `Phoenix.Component` (via `phoenix_live_view ~> 1.1`) | 1.1.30 | A 3-stage funnel (Entered → Recovered → Exhausted) is ~30 lines of HEEx-generated `<svg>` or `<div class="ax-funnel-stage" style={"width:#{pct}%"}>`. JS libs add weight + audit surface for visual chrome we can render server-side. |
| Time-window math (7/30/90 days) | Elixir stdlib `DateTime`, `Date`, `Calendar` | OTP 27 stdlib | `DateTime.utc_now() \|> DateTime.add(-30, :day)` is one line. The existing `Accrue.Analytics.Dunning` already takes `%DateTime{}` `:since`/`:until`. No timezone arithmetic across DST boundaries is in scope (windows are UTC instant-relative). |
| Money formatting ($X,XXX.XX) | `Accrue.Invoices.Render.format_money/3` + `AccrueAdmin.Components.MoneyFormatter` | n/a (already shipped) | Already used by every other admin currency display. CLDR-aware via `:ex_money 5.24.2`. The current `RecoveryLive.format_minor/1` inline helper is the anomaly — fold it into `MoneyFormatter` for consistency. |
| At-risk subscriptions drill-down | `AccrueAdmin.Components.DataTable` (LiveComponent) | n/a (already shipped) | 484 LOC, supports filters, cursor pagination, polling, selection, mobile card layout. Already used by `customers_live`, `invoices_live`, `subscriptions_live`. |
| Time-window filter UI (chips + selector) | `AccrueAdmin.Components.FilterChipBar` + plain `<select>` or button group | n/a (already shipped) | Exact pattern lives in `customers_live` / `invoices_live` filter forms. `handle_params` + `URI.encode_query` for URL-state SSOT. |
| At-risk row collection on the socket | `Phoenix.LiveView.stream/4` | 1.1.x | LiveView 1.1 streams (the recommended idiom since 0.20 / hardened in 1.0) keep large row collections off the socket's `assigns`, only updating the DOM by patch. Important for at-risk lists that can grow into the hundreds during incidents. |
| Async background loading (optional) | `Phoenix.LiveView.assign_async/3` or `start_async/3` | 1.1.x | If the aggregate query is slow under load (it shouldn't be — JSONB aggregations on `accrue_events` are cheap), wrap the `Dunning.recovered_vs_lost_mrr/1` call in `assign_async` so the page renders the shell first. Optional polish. |

### Public Docs Stack (no new deps, just structure)

| Need | Tool | Why |
|------|------|-----|
| `guides/analytics.md` (new) | ExDoc 0.40 (already pinned) | Mounts as an extra in `accrue/mix.exs` `:docs.extras` via the existing `Path.wildcard("guides/*.md")` glob — auto-discovered, zero config change. |
| `@moduledoc` + `@doc` on `Accrue.Analytics.Dunning` (already partially present) | ExDoc | The module already has a `@moduledoc` and a documented `recovered_vs_lost_mrr/1` (lines 1-39 of `accrue/lib/accrue/analytics/dunning.ex`). v1.44 needs to expand it with funnel-counter and at-risk-list functions. |
| Adopter-proof matrix row | `accrue/scripts/verify_adoption_proof_matrix.*` (already exists) | Add one row pointing at `/billing/analytics/recovery` in the example host. No new tooling. |

### Tests Stack (no new deps)

| Test Concern | Tool | Version | Already Available |
|--------------|------|---------|-------------------|
| Time-window aggregation correctness (property tests over MRR cents + window edges) | `stream_data` | 1.3 (already in `accrue/mix.exs:104`) | YES |
| LiveView assertions (filter URL state, funnel render, at-risk table) | `Phoenix.LiveViewTest` | bundled with `phoenix_live_view 1.1` | YES (the existing `recovery_live_test.exs` is the template) |
| HTML parsing for assertions | `:lazy_html` | already in `accrue_admin/mix.exs:45` (test-only) | YES |
| Mocking Stripe/Fake processor for the at-risk query | `mox` | 1.2 (already in `accrue/mix.exs:103`) | YES |
| Time-travel for "last 30 days" tests | Pure stdlib — pass `DateTime` explicitly into `:since`/`:until` opts (the `Dunning` API already accepts them) | n/a | YES (Phase 143 already verified `:since`/`:until` windowing in `dunning_test.exs:2 tests, 0 failures`) |

## Detailed Decisions

### 1. Funnel Visualization — Pure HEEx/SVG, NOT a JS chart library

**Decision:** Render the funnel as HEEx-generated SVG (or pure CSS bars). **Reject** Chart.js / ApexCharts / Plotly / D3.

**Why:**

| Factor | HEEx/SVG | Chart.js | ApexCharts | Plotly |
|--------|----------|----------|------------|--------|
| Bundle size added | 0 KB | ~70 KB min+gz (4.5) | ~135 KB min+gz | ~1.2 MB min+gz |
| LiveView hook required | No | Yes (mount + update lifecycle) | Yes | Yes |
| Theme integration | Native Tailwind preset + `ax-*` tokens | CSS variable wiring + JS theme switcher | Same | Same |
| Funnel chart type built-in | trivial 3 `<rect>` | No native funnel — workaround with bar | YES (`funnel` type) | YES |
| Server-rendered (no JS race on mount) | YES | No | No | No |
| `assets/js/app.js` complexity | Unchanged | +1 hook, +1 import | +1 hook, +1 import | +1 hook, +1 import |
| Aligns with the JS-light posture (`app.js` is 30 lines, 4 hooks) | YES | Breaks pattern | Breaks pattern | Breaks pattern |

**Implementation sketch** (no new code, just the shape):
```heex
<section class="ax-funnel" aria-label="Dunning recovery funnel">
  <div class="ax-funnel-stage" style={"width: #{percent(entered, entered)}%"}>
    <span class="ax-funnel-stage-label">Entered</span>
    <span class="ax-funnel-stage-value"><%= entered %></span>
  </div>
  <div class="ax-funnel-stage ax-funnel-stage--moss" style={"width: #{percent(recovered, entered)}%"}>
    <span class="ax-funnel-stage-label">Recovered</span>
    <span class="ax-funnel-stage-value"><%= recovered %></span>
  </div>
  <div class="ax-funnel-stage ax-funnel-stage--amber" style={"width: #{percent(exhausted, entered)}%"}>
    <span class="ax-funnel-stage-label">Exhausted</span>
    <span class="ax-funnel-stage-value"><%= exhausted %></span>
  </div>
</section>
```
The visual treatment lives in `accrue_admin/assets/css/components/_funnel.css` (new ~20 LOC) extending the existing Tailwind preset palette (`moss`, `amber`, `cobalt` already defined per `kpi_card.ex:62`).

**If/when a JS chart lib becomes warranted** (out of scope for v1.44): the minimal-footprint pick is **ApexCharts** (~135 KB gz, native funnel type, MIT-licensed, mature LiveView integration via the community `LiveviewChartsHook`). But this is a *future* milestone consideration, NOT v1.44.

**Confidence:** HIGH. Driven by inspecting `accrue_admin/assets/js/app.js` (4 hand-rolled hooks, no chart libs), the existing 3-stage funnel data shape (which is trivially representable as 3 stacked divs), and the project's stated "lightweight OSS footprint" constraint.

### 2. Date-window helpers — Stdlib `DateTime`, NOT `:timex`

**Decision:** Use Elixir's standard `DateTime`/`Date`/`Calendar`. **Reject** `:timex`.

**Why:**
- The required math is **`DateTime.utc_now() |> DateTime.add(-N, :day)`** — one stdlib call per window.
- `:timex` is a 100+ KB dep tree (tzdata, gettext, combine) for arithmetic that landed in OTP 21+ stdlib.
- The existing `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` already accepts `:since` / `:until` `%DateTime{}`. We pass them in — no library code needed.
- No timezone-aware "last business day in customer's locale" math is in scope. Windows are UTC-instant-relative ("now minus 30 days"), which stdlib trivially handles.

**Implementation sketch:**
```elixir
defp window_bounds(:last_7), do: {DateTime.add(DateTime.utc_now(), -7, :day), nil}
defp window_bounds(:last_30), do: {DateTime.add(DateTime.utc_now(), -30, :day), nil}
defp window_bounds(:last_90), do: {DateTime.add(DateTime.utc_now(), -90, :day), nil}
defp window_bounds(:all_time), do: {nil, nil}
```
Then `Dunning.recovered_vs_lost_mrr(since: since, until: until)` — already supported by Phase 143's API.

**Confidence:** HIGH. Verified against `accrue/lib/accrue/analytics/dunning.ex:31-72` — `:since`/`:until` already work.

### 3. Money formatting — Reuse `Accrue.Invoices.Render.format_money/3`, NOT add `:number`

**Decision:** Replace the inline `format_minor/1` in `RecoveryLive` with the existing `AccrueAdmin.Components.MoneyFormatter` component (or call `Render.format_money/3` directly). **Reject** adding the `:number` Hex package.

**Why:**
- `:ex_money 5.24.2` is already a core dep (`accrue/mix.exs:56`), pulling in `:ex_cldr_numbers 2.38.1` and `:ex_cldr_currencies 2.17.1` transitively — full CLDR locale-aware formatting is **already available**.
- `Accrue.Invoices.Render.format_money/3` is the canonical formatter (handles locale fallback + telemetry on failure, per `accrue/lib/accrue/invoices/render.ex:6-30`).
- `AccrueAdmin.Components.MoneyFormatter` is the shared HEEx component (already shipped). Other admin pages already use it.
- Adding `:number` would be a duplicate capability + a CLDR-incompatible non-locale-aware formatter — strictly worse.

**Current state** (to be fixed in v1.44 polish): `RecoveryLive.format_minor/1:76-81` does `"$" <> :erlang.float_to_binary(dollars, decimals: 2)` — that is **wrong** for non-USD currencies, will format `1500` JPY as `$15.00` instead of `¥1,500`, and bypasses `MoneyFormatter`. Phase 143's verification didn't catch this because tests asserted USD-only.

**Fix:** Replace with `<MoneyFormatter.money_formatter amount_minor={@stats.recovered_cents} currency="usd" />` (resolving currency from the event payload's `data["currency"]`, which Phase 143 already snapshots per `default_handler.ex:804-814`).

**Confidence:** HIGH. Cross-verified `Accrue.Money`, `Accrue.Invoices.Render.format_money/3`, and `AccrueAdmin.Components.MoneyFormatter` all wire through CLDR.

### 4. LiveView 1.1 features to leverage for at-risk drill-down

**Decision:** Use **`Phoenix.LiveView.stream/4`** for the at-risk subscription row collection. Optionally use **`assign_async/3`** for the aggregate query.

**Why streams** for the at-risk list:
- An "at-risk" list = subscriptions with an active `dunning.campaign_started` not yet matched by `dunning.recovered` / `dunning.exhausted`. During incidents this can grow into the hundreds.
- `Phoenix.LiveView.stream/4` keeps the row collection **off the socket** — only DOM patches are sent over the wire. Avoids socket memory bloat.
- Streams require `phx-update="stream"` on the `<tbody>` and a stable DOM id per row — both are trivial to add to the existing `DataTable` component (or render inline if `DataTable`'s LiveComponent boundary is awkward for streams).
- **Caveat:** `DataTable` currently keeps `:rows` in `assigns` (see `data_table.ex:65-89` `load-more` handler). To adopt streams, either (a) refactor `DataTable` to support a stream-mode flag, or (b) bypass `DataTable` for this page and render a slimmer streamed table inline. **Recommend (b)** for v1.44 to scope-limit risk — `DataTable` stream-support is a separate concern.

**Why `assign_async`** (optional):
- If `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` becomes slow under high-event-volume hosts, wrap it in `assign_async` so the shell renders first and the KPI numbers stream in.
- Phase 143 currently calls it synchronously in `mount/3:12`. Fine for now; reconsider if a host with millions of events surfaces a latency complaint.

**LiveView 1.1 features we are NOT using** (clarity flag):
- `Phoenix.LiveView.send_update_after/3` already in use by `DataTable` for polling — no change.
- LiveView form `<.input>` core components — not needed; filter is a simple `<select>` + button group.
- `Phoenix.LiveView.JS` commands — overkill for a 3-stage funnel.

**Confidence:** HIGH for streams (well-documented LiveView 1.0+ feature). MEDIUM for `assign_async` (a v1.44 polish concern; we may skip it).

### 5. Tests stack — no new additions

**Decision:** Keep `:stream_data 1.3` + `Phoenix.LiveViewTest` + `:lazy_html` + `:mox 1.2`. No new test deps.

**Specific patterns to use:**

1. **Property tests for window math** (in `accrue/test/accrue/analytics/dunning_property_test.exs`, new):
   - Generate `DateTime` pairs with `StreamData.integer/1` (offset from a base epoch).
   - Generate MRR cents lists with `StreamData.list_of(integer/1)`.
   - Property: `sum_in_window(events, since, until) == filter_then_sum(events, since, until)`.
   - Catches: off-by-one on `>=` vs `>` boundary, empty-window edge cases, single-event-at-boundary cases.

2. **LiveView filter URL-state tests** (in `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`):
   - Pattern from `customers_live_test.exs`: `{:ok, view, _html} = live(conn, "/billing/analytics/recovery?window=7")`.
   - Assert `view |> element("[data-window='7']") |> render() =~ "selected"`.
   - On window-chip click: `view |> element("[data-window='30']") |> render_click()` then assert URL via `assert_patch(view, ~p"/billing/analytics/recovery?window=30")`.

3. **Funnel render assertions:**
   - Seed events: `5 entered, 3 recovered, 2 exhausted`.
   - Assert `view |> element(".ax-funnel-stage--moss .ax-funnel-stage-value") |> render() =~ "3"`.
   - Use `Floki.find/2` via `:lazy_html` for structural assertions.

4. **At-risk drill-down tests:**
   - Seed an `:active` `Subscription` with a `dunning.campaign_started` event and no matching `recovered`/`exhausted`.
   - Mount the page, assert the at-risk row appears with the campaign details.
   - Click into the row, assert it patches to the subscription detail page (or opens the drawer via existing `DetailDrawer`).

**Confidence:** HIGH. All patterns are 1:1 reuse of existing `accrue_admin/test/` precedent.

## Alternatives Considered (Reject Table)

| Considered | Status | Reason |
|------------|--------|--------|
| `:chart_js` / `chartjs_phoenix` | REJECTED | 70 KB+ JS, breaks JS-light posture, requires a LiveView hook + DOM ref management. Pure HEEx/SVG suffices for a 3-bar funnel. |
| `:apex_charts` (via custom hook) | REJECTED for v1.44 | Best-in-class funnel chart type, but ~135 KB JS for a single visualization. Revisit only if a future milestone adds 5+ chart types. |
| `:plotly` / `:d3` | REJECTED | Vastly overpowered for a 3-stage funnel. D3 alone is ~250 KB. |
| `:timex` | REJECTED | Stdlib `DateTime.add/3` + `Calendar` covers everything needed. `:timex` adds tzdata + combine deps for capabilities we don't use. |
| `:number` (the Hex package "Number.Currency") | REJECTED | `:ex_money` already in deps with CLDR-aware formatting via `:ex_cldr_numbers`. Adding `:number` duplicates capability and bypasses the existing `Accrue.Invoices.Render.format_money/3` central choke point. |
| `:phoenix_live_view_native` | REJECTED | Not a real concern for admin UI; mobile is served via responsive HEEx already. |
| Custom Tailwind plugin for funnel | REJECTED | The existing `tailwind_preset.js` already exposes the brand tokens. Inline `class={...}` strings are sufficient — no plugin needed. |
| Storing time-window state in `assigns` only (no URL) | REJECTED | Breaks deep-linking + sharing. Every other admin filter (`customers_live`, `invoices_live`, etc.) uses `handle_params` + URL state — be consistent. |
| Async aggregate roll-up workers (Oban) | REJECTED for v1.44 | Phase 143 design constraint: "aggregate the existing event ledger only — no new tables, no rollup workers." Adding Oban analytics workers introduces a new state machine. Defer until/unless a host hits real perf issues. |
| New analytics-storage deps (TimescaleDB, ClickHouse) | REJECTED — VIOLATES CONSTRAINT | Phase 143 design constraint explicitly forbids new tables/storage. v1.44 inherits this. |
| `:explorer` (Polars-backed dataframes) | REJECTED | Beautiful for in-process analytics, but adding a Rust NIF + 30 MB binary for "sum of cents grouped by event type" is wildly over-engineered. Postgres `GROUP BY` is the right tool. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Inline `:erlang.float_to_binary/2` for money | Locale-blind, breaks for non-USD currencies, bypasses CLDR | `Accrue.Invoices.Render.format_money/3` via `AccrueAdmin.Components.MoneyFormatter` |
| `Timex.shift/2` for windows | Adds 4-package dep for stdlib-equivalent math | `DateTime.add(now, -N, :day)` |
| JavaScript chart libraries (any) | 70-1200 KB bundle, runtime DOM races, theme integration cost, breaks JS-light posture | HEEx-rendered SVG/CSS, server-rendered |
| New ETL tables for analytics rollup | Violates Phase 143 design constraint ("no new tables") | JSONB aggregation on `accrue_events` ledger (already proven) |
| Heavyweight async/streaming chart libs (Plotly, Bokeh, etc.) | Massive surface area for a 3-stage visualization | 3 `<div>`s with width % |
| `:absinthe` for an "analytics API" | Out of scope — we're not exposing a GraphQL surface; the admin LiveView is the consumer | Plain `Accrue.Analytics.Dunning` context functions |
| Caching aggregate results in ETS | Premature — JSONB aggregation on `accrue_events` is cheap (events table is bounded by retention; even at millions of rows a single `GROUP BY type` is sub-100ms with a btree index on `(type, inserted_at)`) | Direct query each `mount/3`; revisit if a host complains. Add an index *before* a cache. |
| Adding `LiveView.stream/4` to the `DataTable` component itself | Scope creep — `DataTable` is used by 5+ pages; refactoring for streams is its own phase | Bypass `DataTable` for the at-risk page and render an inline streamed `<tbody phx-update="stream">` |

## Constraint Compliance Check

| Constraint | Status |
|------------|--------|
| No new tables | OK — all aggregations on existing `accrue_events` |
| No new storage deps | OK — zero new runtime deps |
| Lightweight OSS footprint | OK — zero deps added, only HEEx + stdlib |
| `accrue_admin` JS-light posture preserved | OK — no new JS hooks, no new chart libs, `app.js` unchanged |
| LiveView 1.1 idioms | OK — leverage `stream/4` (optionally `assign_async/3`); no socket-bloat patterns |
| Theme/Tailwind preset consistency | OK — `ax-funnel-*` classes follow the existing `ax-kpi-*` / `ax-filter-chip-*` naming convention |
| Core stays LiveView-runtime-free | OK — all LiveView work lives in `accrue_admin`, not `accrue` |
| Adopter-proof matrix expandable without new tooling | OK — `verify_adoption_proof_matrix.sh` already exists |

## Version Compatibility Matrix (Confirmation, NOT a Change)

All locked versions remain unchanged from v1.43:

| Library | Pinned | Current (2026-05) | Status |
|---------|--------|-------------------|--------|
| `elixir` | `~> 1.17` | 1.18.x ecosystem | OK |
| `phoenix` | `~> 1.8` | 1.8.x | OK |
| `phoenix_live_view` | `~> 1.1` | 1.1.30 | OK — stream + assign_async available |
| `ecto` / `ecto_sql` | `~> 3.13` | 3.13.5 | OK — JSONB fragments supported |
| `postgrex` | `~> 0.22` | 0.22.0 | OK |
| `ex_money` (transitive) | from `accrue/mix.exs:56` `~> 5.24` | 5.24.2 | OK — `ex_cldr_numbers 2.38.1` pulled in |
| `stream_data` | `~> 1.3` | 1.3.0 | OK — property tests for window math |
| `mox` | `~> 1.2` | 1.2.0 | OK |
| `phoenix_html` | `~> 4.2` | 4.2.x | OK |

## Sources

### Project source-of-truth (HIGH confidence)

- `/Users/jon/projects/accrue/CLAUDE.md` — locked tech-stack constraints (Phoenix 1.8 / LiveView 1.1 / Ecto 3.13 / Postgres 14+ / ship-complete posture).
- `/Users/jon/projects/accrue/accrue/mix.exs` — confirmed `:ex_money 5.24`, `:stream_data 1.3`, `:mox 1.2` already in deps.
- `/Users/jon/projects/accrue/accrue_admin/mix.exs` — confirmed `:phoenix_live_view 1.1`, `:lazy_html` test-only.
- `/Users/jon/projects/accrue/accrue/mix.lock` — confirmed transitive resolution: `ex_money 5.24.2`, `ex_cldr_numbers 2.38.1`, `ex_cldr_currencies 2.17.1`, `ex_cldr 2.47.2`.
- `/Users/jon/projects/accrue/accrue/lib/accrue/analytics/dunning.ex` (72 LOC) — confirmed `:since`/`:until` `%DateTime{}` window already supported (Phase 143 foundation).
- `/Users/jon/projects/accrue/accrue/lib/accrue/invoices/render.ex` — confirmed `format_money/3` is the canonical CLDR formatter with telemetry fallback.
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/components/{kpi_card,money_formatter,data_table,filter_chip_bar}.ex` — confirmed shared admin primitives already shipped.
- `/Users/jon/projects/accrue/accrue_admin/assets/js/app.js` (30 LOC) — confirmed JS-light posture (only 4 hand-rolled hooks: clipboard, theme, shell_nav, command_palette).
- `/Users/jon/projects/accrue/.planning/phases/143/143-VERIFICATION.md` — Phase 143 4/4 verified, foundation shipped.

### External (MEDIUM confidence, verified)

- [hex.pm — phoenix_live_view](https://hex.pm/packages/phoenix_live_view) — confirmed **1.1.30** as the latest in the 1.1 line (fetched 2026-05-27).
- LiveView 1.1 streams + `assign_async/start_async`: documented in HexDocs for `Phoenix.LiveView` 1.0+; 1.1 hardens API ergonomics. Already in use indirectly via `Phoenix.LiveView.send_update_after/3` in the codebase.

### v1.44 strategy thread (HIGH confidence)

- `/Users/jon/projects/accrue/.planning/threads/v1.44-NEXT-STEP-ASSESSMENT.md` — confirmed scope: funnel + at-risk drill-down + time-window filters + docs + adopter-proof. Confirmed "no new dependencies" design constraint (carried from Phase 143).
- `/Users/jon/projects/accrue/.planning/phases/143/143-RESEARCH.md` — confirmed JSONB aggregation pattern; confirmed "no new tables, no new deps" foundation.

## Flags for Roadmap Consumer

1. **Polish item to bundle into v1.44 — fix `RecoveryLive.format_minor/1`:** The current inline `:erlang.float_to_binary` is USD-only and bypasses CLDR. Replace with `AccrueAdmin.Components.MoneyFormatter` (resolving currency from the event payload). Low-risk, ~5 LOC, but breaks for non-USD adopters. Flag for a v1.44 phase.

2. **Adopter-proof seed-data choice:** The example host's `seed.exs` must include enough fake `dunning.recovered`/`dunning.exhausted` events at varying `inserted_at` offsets to make the 7/30/90 windows visibly different. Otherwise the filter UI looks broken on a fresh demo install. Suggest the v1.44 adopter-proof phase explicitly verify this.

3. **Streams-vs-DataTable boundary decision:** Phase plan should declare whether the at-risk drill-down uses (a) the shared `DataTable` LiveComponent or (b) an inline streamed table. Recommendation: **(b)** — bypass `DataTable` for this page to avoid refactoring its `:rows` assign into stream form (which would be a separate concern). Re-evaluate if a future milestone unifies the two.

4. **No new index migration needed yet, BUT flag for monitoring:** `accrue_events` likely already has a btree on `(type, inserted_at)` from Phase 143's foundation work (verify in the next plan). If not, add it preemptively in the v1.44 funnel-aggregation phase — `EXPLAIN ANALYZE` of the new funnel `GROUP BY type` query will tell us.

5. **`guides/analytics.md` location:** Place under `accrue/guides/` (not `accrue_admin/guides/`) because the public API contract is `Accrue.Analytics.Dunning` (lives in `accrue`). The admin LiveView is a *consumer* of that contract, not the contract itself. The guide should document the Ecto context so developers can build custom dashboards (per the v1.44 scope).

6. **No timezone / DST scope:** Time-window filters use UTC-instant arithmetic. If a host requests "last 30 calendar days in customer's timezone," that's a separate concern (and would warrant `:timex` only at that point). Out of scope for v1.44 unless the requirements explicitly add it.

7. **Defer chart-library introduction discussion:** If a future milestone (v1.45+) adds 5+ chart types (heatmaps, time-series, cohort tables), revisit whether to introduce **ApexCharts** as a single chart-library standard. Do NOT introduce it for v1.44's one funnel.
