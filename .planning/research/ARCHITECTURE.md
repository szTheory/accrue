# Architecture Research — Recovered-Revenue Dashboard Completion (v1.44)

**Domain:** Operator-facing analytics dashboard layered on the `accrue_events` ledger
**Researched:** 2026-05-27
**Confidence:** HIGH (Phase 143 foundation is shipped + verified; all integration seams are codebase-grounded)

> **Scope note.** This is a **completion** design on top of an already-locked architecture (Phase 143). The integration points, JSONB aggregation pattern, public-API module name, and LiveView mount/auth posture are all set. v1.44 only adds new analytical surfaces (funnel, at-risk, time-window, drill-down) and one minimal write-path addition (a single new event type). The verified central insight is that **every new query in v1.44 can reuse `Accrue.Analytics.Dunning`'s pattern**: `from(e in Event, where: e.type in [...], group_by: ..., select: {..., sum(fragment("(?->>'mrr_value_cents')::integer", e.data))})` with optional `:since/:until` parameterized bounds. No new tables. No new dependencies.

---

## Decisions at a glance

| # | Question | Decision | Confidence |
|---|----------|----------|------------|
| 1 | Funnel query: one query or `Task.async` per stage? | **ONE query** — single `group_by :type` over a fixed set of event types, returning a `%{stage => count}` map. Same shape as `recovered_vs_lost_mrr/1` extended. | HIGH |
| 2 | Are step-level events emitted today? | **YES** — `dunning.campaign_started` (default_handler:1237), `dunning.step_sent` (workers/dunning_step.ex:196), `dunning.recovered` and `dunning.exhausted`. The funnel can be built today with **zero write-path changes**. | HIGH |
| 3 | What about `dunning.terminal_action_requested` (sweeper)? | **EXCLUDE** from funnel — already documented as "request-time intent, may double-count" in `billing/dunning.ex:108-110`. Funnel uses confirmed transitions only. | HIGH |
| 4 | At-risk subscriptions: derived from events or schema? | **From schema** — `Accrue.Billing.Subscription.dunning_campaign_active?/1` returns true iff `dunning_campaign_started_at` is non-nil. There is no `Accrue.Dunning.Campaign` row schema — "active" = anchor present on the subscription row. Anchor is cleared atomically with the terminal/recovery write. | HIGH |
| 5 | Where does the at-risk query live? | **Both** — push the *Ecto query composer* into `Accrue.Billing.Query.in_active_dunning_campaign/1` (next to the existing `dunning_sweep_candidates/2`), and expose the *enumeration helper* `Accrue.Analytics.Dunning.at_risk_subscriptions/1` that joins customer + invoice context for dashboard rendering. | HIGH |
| 6 | Time-window: URL param, assign, or both? | **Both, with URL as SSOT** — `?window=30d` URL param drives `handle_params/3` → assigns. This is consistent with `subscriptions_live.ex:43-45` and the existing `params`-driven `DataTable` shape. URL-shareable, deep-linkable, back-button safe. | HIGH |
| 7 | Per-campaign drill-down: separate route or live_component? | **Separate route** at `/billing/analytics/recovery/subscriptions/:subscription_id` — leverages the existing `Accrue.Events.timeline_for/3` helper. Drill-down is keyed on `subject_id`, not on a campaign-row PK (there is no campaign-row schema). | HIGH |
| 8 | LiveView 1.1 streams for at-risk table? | **No** — plain `assign(:at_risk, list)` is correct for the v1.44 scope (10–500 rows typical; never live-mutated mid-session). Streams are for live-mutating lists; this list refreshes only on `handle_params` + manual reload. Crossover ~5k rows or any push-based update — neither applies. | HIGH |
| 9 | Dashboard-load telemetry? | **Yes** — `[:accrue, :ops, :analytics_dashboard_loaded]` via `Accrue.Telemetry.Ops.emit/3` (the canonical helper). Dimensions: `view` (`:recovery` \| `:campaign_drilldown`), `window_days`, `result_count`. Useful for measuring adoption and tail-latency on the JSONB aggregations. | HIGH |
| 10 | Public API surface in v1.44 | Lock **`Accrue.Analytics.Dunning`** as the public boundary. Promote `recovered_vs_lost_mrr/1` (already shipped) + four new functions: `funnel/1`, `at_risk_subscriptions/1`, `campaign_timeline/2`, `bucket_recovered_mrr/2`. Everything in `accrue_admin` is internal (no @doc-public for LiveViews). | HIGH |
| 11 | Cross-package boundary risk? | **None new** — `RecoveryLive` calls only `Accrue.Analytics.Dunning` functions; no schema reach-around. Add a Credo check or doc convention to enforce. Third-party non-admin dashboards reuse the same context. | HIGH |
| 12 | Build order | **(1) funnel query + funnel UI** → **(2) time-window URL plumbing** → **(3) at-risk query + table** → **(4) per-subscription drill-down route** → **(5) docs + adopter-proof** → **(6) telemetry + bucket-by-day MRR for sparkline** (optional). De-risks compute path before navigation/state. | HIGH |

---

## System diagram (v1.44 — annotated against Phase 143 foundation)

```
                  +-------------------------------+
                  | accrue (LiveView-runtime-free)|
                  +-------------------------------+
                                  |
   write path (UNCHANGED + 0 new types)            read path (4 new functions)
                                  |                          |
+---------------------------------------------+   +-----------------------------------+
| Stripe webhook  ->  DefaultHandler          |   | Accrue.Analytics.Dunning          |
|                                             |   |   (PUBLIC v1.44 API)              |
|   `dunning.campaign_started`  :1237 (today) |   |                                   |
|   `dunning.step_sent`         (workers)     |   | recovered_vs_lost_mrr/1   (143)   |
|   `dunning.exhausted` + MRR   :804 (143)    |   | funnel/1                  NEW     |
|   `dunning.recovered` + MRR   :885 (143)    |   | at_risk_subscriptions/1   NEW     |
|                                             |   | campaign_timeline/2       NEW     |
|   accrue_events (JSONB data)                |   | bucket_recovered_mrr/2    NEW(opt)|
+---------------------------------------------+   +-----------------------------------+
                                  |                          |
                                  |                          |  (JSONB aggregations,
                                  |                          |   :since/:until window)
                                  v                          v
                  +---------------------------------------------------+
                  | Accrue.Billing.Query (existing query composer)    |
                  |   in_active_dunning_campaign/1   NEW              |
                  +---------------------------------------------------+
                                                             |
                                                             v
                  +-------------------------------+
                  | accrue_admin                  |
                  +-------------------------------+
                  |                                |
  Live.Analytics.RecoveryLive           Live.Analytics.CampaignLive   NEW
  (extends today's KPI page)            (per-subscription drill)
  /billing/analytics/recovery           /billing/analytics/recovery
                                          /subscriptions/:id
                  |
                  |  reuses: AppShell, Breadcrumbs, KpiCard
                  |  adds:   FunnelChart (HEEx/SVG),
                  |          AtRiskTable (LiveComponent or inline list)
                  +---> Operator browser
```

---

## Architectural responsibility map

| Capability | Primary tier | Secondary | Rationale |
|------------|-------------|-----------|-----------|
| Event emission (already complete) | `accrue` backend | — | No new write paths. `dunning.campaign_started`, `dunning.step_sent`, `dunning.recovered`, `dunning.exhausted` all exist. v1.44 is read-only on the ledger. |
| Funnel aggregation | `Accrue.Analytics.Dunning.funnel/1` | `Accrue.Events` JSONB aggregation pattern | Single `group_by :type` query keeps the round-trip count low and yields a `%{entered: n, step_sent: n, recovered: n, exhausted: n}` map. |
| At-risk enumeration | `Accrue.Analytics.Dunning.at_risk_subscriptions/1` | `Accrue.Billing.Query.in_active_dunning_campaign/1` (NEW) | Schema-side: anchor (`dunning_campaign_started_at`) is the truth-bearing field. Cleaner to compose at the query layer next to `dunning_sweep_candidates/2`. |
| Per-campaign timeline | `Accrue.Analytics.Dunning.campaign_timeline/2` | `Accrue.Events.timeline_for/3` (already shipped) | Reuses the ledger's existing per-subject timeline helper. |
| Dashboard SSR | `AccrueAdmin.Live.Analytics.RecoveryLive` (extends today's page) + `AccrueAdmin.Live.Analytics.CampaignLive` (NEW) | `KpiCard`, `Breadcrumbs`, `AppShell`, NEW `FunnelChart` HEEx component | LiveView is `accrue_admin`-only. `accrue` stays runtime-free. |
| URL state sync | LiveView `handle_params/3` | — | Mirrors `subscriptions_live.ex` and `events_live.ex`. URL-shareable windows. |

---

## Files: new vs modified (the integration map)

### `accrue` package

| File | Change | What |
|------|--------|------|
| `accrue/lib/accrue/analytics/dunning.ex` | **MODIFY** (today 73 LOC → est. ~250 LOC) | Add `funnel/1`, `at_risk_subscriptions/1`, `campaign_timeline/2`, optional `bucket_recovered_mrr/2`. Promote `@doc` blocks to public-API quality. Add `@spec` for all new functions. Keep the same `apply_window/maybe_since/maybe_until` private helpers — extract if duplicated 3+ times. |
| `accrue/lib/accrue/billing/query.ex` | **MODIFY** (add ~15 LOC) | Add `@spec in_active_dunning_campaign/1 :: Ecto.Query.t()` mirroring `dunning_sweep_candidates/2` style. Filter: `where: not is_nil(s.dunning_campaign_started_at)`. |
| `accrue/test/accrue/analytics/dunning_test.exs` | **MODIFY** (today 83 LOC → est. ~250 LOC) | Add tests for each new public function: funnel with mixed event types, at-risk excludes nil-anchor and exhausted-recovered, timeline ordering, window filtering on each. Property tests for funnel monotonicity (recovered + exhausted ≤ campaign_started). |
| `accrue/test/accrue/billing/query_test.exs` | **MODIFY** | One test for `in_active_dunning_campaign/1`. |
| `accrue/CHANGELOG.md` | **MODIFY** | v1.2.x section: "Analytics: `Accrue.Analytics.Dunning.{funnel, at_risk_subscriptions, campaign_timeline, bucket_recovered_mrr}/1`". |
| `accrue/lib/accrue/webhook/default_handler.ex` | **NO CHANGE** | All needed events are already emitted. The "funnel needs new events" worry is unfounded. |
| `accrue/guides/analytics.md` | **NEW** (~150 LOC) | Public guide: "Querying recovered revenue", with full example for the dashboard's three queries + JSONB cookbook for users who want custom rollups. Linked from ExDoc nav. |

### `accrue_admin` package

| File | Change | What |
|------|--------|------|
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | **MODIFY** (today 86 LOC → est. ~250 LOC) | Add `handle_params/3` for `?window=`, swap hard-coded `recovered_vs_lost_mrr()` for window-aware call, add funnel section, add at-risk section. Keep AppShell + Breadcrumbs shape. |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | **NEW** (~150 LOC) | Per-subscription drill-down. Calls `Accrue.Analytics.Dunning.campaign_timeline/2`. Reuses existing `AccrueAdmin.Components.Timeline` if present. |
| `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` | **NEW** (~80 LOC) | Stateless `Phoenix.Component`. Pure HEEx + inline SVG (no JS dep). Takes a `%{stages: [{label, count}, ...]}` shape and renders horizontal bar funnel. |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | **NEW** (~100 LOC) — OR inline in `recovery_live.ex` | Static table (no `DataTable` LiveComponent — that's heavy for a one-off dashboard list). Plain `<table>` with rows from `assign(:at_risk, ...)`. Drill-down link per row. |
| `accrue_admin/lib/accrue_admin/router.ex` | **MODIFY** (add 1 line) | Inside the existing `scope "/analytics", ... do` block: `live "/recovery/subscriptions/:id", CampaignLive, :show`. |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | **MODIFY** (today 66 LOC → est. ~200 LOC) | Add window-filter test, funnel-rendering test, at-risk-row-render test, drill-down link test. |
| `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` | **NEW** (~80 LOC) | Mount per-subscription drill-down, assert timeline rendering. |
| `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` | **NEW** (~40 LOC) | Render-to-HTML assertions: stage counts, accessibility labels, SVG well-formed. |
| `accrue_admin/CHANGELOG.md` | **MODIFY** | v1.2.x: "Recovery Dashboard: funnel, time-window filter, at-risk subscriptions, per-subscription drill-down". |

### `examples/accrue_host`

| File | Change | What |
|------|--------|------|
| `examples/accrue_host/lib/.../seeds.exs` or fake-data helper | **MODIFY** | Seed mixed `dunning.campaign_started` / `dunning.step_sent` / `dunning.recovered` / `dunning.exhausted` events with varied `mrr_value_cents` and varied timestamps so the dashboard demos with realistic shape. |
| `examples/accrue_host/README.md` | **MODIFY** | One-paragraph adopter pointer: "Visit /billing/analytics/recovery against fake-seeded data". |
| **Adopter-proof matrix** (per CLAUDE.md milestone goal) | **MODIFY** | Add a row to the public adopter-proof matrix: "Recovered-revenue analytics dashboard → /billing/analytics/recovery (funnel + at-risk + windowed)". |

---

## Pattern 1: Funnel via single `group_by :type` query

**What.** Reuse Phase 143's JSONB aggregation pattern but `group_by e.type` over the full lifecycle event set rather than just two types.

**When to use.** Any "count events of each type within a window" question on `accrue_events`.

**Example.**

```elixir
# Accrue.Analytics.Dunning (NEW)
@campaign_started "dunning.campaign_started"
@step_sent        "dunning.step_sent"
@recovered        "dunning.recovered"
@exhausted        "dunning.exhausted"

@spec funnel(keyword()) :: %{
        entered: non_neg_integer(),
        step_sent: non_neg_integer(),
        recovered: non_neg_integer(),
        exhausted: non_neg_integer()
      }
def funnel(opts \\ []) when is_list(opts) do
  types = [@campaign_started, @step_sent, @recovered, @exhausted]

  counts =
    from(e in Event,
      where: e.type in ^types,
      group_by: e.type,
      select: {e.type, count(e.id)}
    )
    |> apply_window(opts)
    |> Repo.all()
    |> Map.new()

  %{
    entered: Map.get(counts, @campaign_started, 0),
    step_sent: Map.get(counts, @step_sent, 0),
    recovered: Map.get(counts, @recovered, 0),
    exhausted: Map.get(counts, @exhausted, 0)
  }
end
```

**Why not `Task.async` per stage.** Four queries against the same table is strictly slower (round-trip × 4) and adds zero parallelism benefit when Postgres is the bottleneck. The single `group_by` query is the canonical SQL idiom; the planner uses one index scan over `accrue_events.type` (already indexed — confirmed by `bucket_query/1` reliance on `where: type in ...`).

**Note on funnel semantics — important.** `step_sent` and `entered` count *events*, not *unique subscriptions*. A single subscription can fire multiple `dunning.step_sent` events (one per cadence step). For a v1.44 dashboard, "events" is the simpler-to-explain shape and matches the Stripe Dashboard's "actions sent" framing. If a future v1.45 wants "unique subscriptions per stage", we add `funnel_unique_subjects/1` — `select: {e.type, count(e.subject_id, :distinct)}` — without breaking v1.44 callers.

---

## Pattern 2: At-risk subscriptions via schema-side query (NOT event-derived)

**What.** "Active dunning campaign" is durably represented as a non-nil `dunning_campaign_started_at` on the subscription row. That anchor is set atomically with the past_due transition (default_handler:1208) and cleared atomically with the recovery/exhaustion transition (default_handler:875). Querying events to derive "active" is **wrong** — it would lag behind the schema by a transaction boundary and re-derive what's already authoritative.

**When to use.** Any "currently in state X" question where X has a dedicated schema column.

**Example.**

```elixir
# Accrue.Billing.Query (NEW function, next to dunning_sweep_candidates/2)
@doc "Subscriptions currently inside an active dunning campaign (anchor set)."
@spec in_active_dunning_campaign(Ecto.Queryable.t()) :: Ecto.Query.t()
def in_active_dunning_campaign(query \\ Subscription) do
  from(s in query, where: not is_nil(s.dunning_campaign_started_at))
end

# Accrue.Analytics.Dunning (NEW)
@doc "Lists subscriptions currently in an active dunning campaign, with snapshotted MRR."
@spec at_risk_subscriptions(keyword()) :: [%{...}]
def at_risk_subscriptions(opts \\ []) do
  limit = Keyword.get(opts, :limit, 100)

  from(s in Accrue.Billing.Query.in_active_dunning_campaign(),
    join: c in assoc(s, :customer),
    order_by: [asc: s.dunning_campaign_started_at],
    limit: ^limit,
    select: %{
      subscription_id: s.id,
      customer_id: c.id,
      customer_email: c.email,
      customer_name: c.name,
      processor_id: s.processor_id,
      status: s.status,
      past_due_since: s.past_due_since,
      campaign_started_at: s.dunning_campaign_started_at
    }
  )
  |> Repo.all()
end
```

**Why not enrich with per-subscription MRR.** The MRR-at-risk for each row is *not* in `accrue_events` (events only capture MRR at recovery/exhaustion). Computing MRR live from `subscription.data["items"]` per row would re-implement `calculate_mrr_cents/1` (currently private in `DefaultHandler`). **Recommendation for v1.44:** show past-due age and customer identity in the at-risk table, and reserve MRR-at-risk for a v1.45 column once `calculate_mrr_cents/1` is promoted out of `DefaultHandler` into a shared helper. This is the cleaner phase boundary.

---

## Pattern 3: Time-window URL parameter as single source of truth

**What.** A URL query param `?window=30d` drives `handle_params/3` → assigns. Default = 30d.

**When to use.** Any LiveView whose contents change based on a small set of discrete filters that operators want to share/bookmark.

**Example.**

```elixir
# RecoveryLive
@windows %{"7d" => 7, "30d" => 30, "90d" => 90}
@default_window "30d"

@impl true
def handle_params(params, _uri, socket) do
  window_key = Map.get(params, "window", @default_window)
  days = Map.get(@windows, window_key, 30)
  since = DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

  stats = Dunning.recovered_vs_lost_mrr(since: since)
  funnel = Dunning.funnel(since: since)
  at_risk = Dunning.at_risk_subscriptions(limit: 100)
  # at_risk is point-in-time, not window-filtered — semantically "right now"

  {:noreply,
   socket
   |> assign(:window_key, window_key)
   |> assign(:window_days, days)
   |> assign(:stats, stats)
   |> assign(:funnel, funnel)
   |> assign(:at_risk, at_risk)}
end
```

**Why URL not assigns-only.** Operators share links in Slack ("look at the 7-day funnel — recovery rate is up"). Assigns-only would make that impossible. Confirms the codebase convention: every existing list-style admin LiveView (`subscriptions_live.ex:43-45`, `customers_live.ex:66`, `invoices_live.ex:28`, `events_live.ex:27`) uses `handle_params(params, _uri, socket)` for exactly this.

**Why not Stripe-style "complex filter object in URL".** v1.44's window has 3 discrete values. JSON-encoding a filter object is over-engineering at this scale. Keep it simple: `?window=30d`.

---

## Pattern 4: Per-subscription drill-down as a separate route

**What.** Drill-down lives at `/billing/analytics/recovery/subscriptions/:id` and is a sibling LiveView in `live_session :accrue_admin` (inherits admin auth automatically).

**When to use.** Any drill-down that (a) has a stable URL worth sharing, (b) has fundamentally different page-content from its parent, (c) doesn't require synchronized state with the parent.

**Example.**

```elixir
# router.ex (modified — single line inside existing scope)
scope "/analytics", AccrueAdmin.Live.Analytics do
  live "/recovery", RecoveryLive, :index
  live "/recovery/subscriptions/:id", CampaignLive, :show  # NEW
end
```

**Why not `push_patch` + nested live_component.** Three reasons:
1. Back-button behavior. A push_patch'd drill-down requires custom history management; a separate route gets it free.
2. Code locality. `RecoveryLive`'s `render/1` is already at ~80 LOC. Adding a 2-state (`:list` / `:drilldown`) conditional render block doubles complexity for nothing.
3. Test isolation. Each LiveView gets its own focused test file (already the convention in `accrue_admin/test/accrue_admin/live/`).

**Subject ID is the right key, not "campaign ID".** There is no `Accrue.Dunning.Campaign` schema (campaign.ex is a *pure resolver*, not an Ecto schema). A campaign is uniquely identified by `(subscription_id, dunning_campaign_started_at)` — but since at most one campaign per subscription is active at a time, the subscription_id alone is a stable URL key. Historical campaigns for the same subscription appear as multiple `dunning.campaign_started` events in `timeline_for("Subscription", id)` and can be visually grouped client-side if needed (deferred to v1.45+).

---

## Pattern 5: Optional MRR-over-time sparkline (bucket_by reuse)

**What.** If sparkline shipping is in scope, reuse `Accrue.Events.bucket_by/2` directly — it already supports `:day` / `:week` / `:month` buckets and the `:type, :since, :until, :subject_type` filter shape.

**When to use.** Time-series visualizations on the ledger.

**Example.**

```elixir
def bucket_recovered_mrr(bucket, opts \\ []) when bucket in [:day, :week, :month] do
  # Note: bucket_by/2 returns counts. For MRR sums, we need a custom query
  # that mirrors bucket_by's shape but uses sum(fragment(...)) instead of count.
  # ALTERNATIVE: just return counts via bucket_by and accept "events recovered per day"
  # as the sparkline metric — simpler, no new query needed.
  Accrue.Events.bucket_by(
    [type: "dunning.recovered"] ++ Keyword.take(opts, [:since, :until]),
    bucket
  )
end
```

**Tradeoff.** A `sum(mrr)` sparkline is more meaningful than a `count(events)` sparkline for the recovered-revenue story. If we want sum we write a parallel `bucket_sum_by_jsonb/3` helper in `Accrue.Events` (~25 LOC). **Recommendation:** ship the count-based sparkline in v1.44 if time allows; defer sum-based to v1.45 alongside MRR-at-risk-per-row to keep the JSONB-sum helper introduced once with both consumers ready.

---

## Anti-patterns to avoid

### 1. Re-deriving "active campaign" from events
Computing `WHERE EXISTS (dunning.campaign_started without subsequent dunning.recovered or dunning.exhausted)` is **wrong**: it lags the durable schema column by a transaction boundary, and a recovery committed but not yet projected by a worker would show as "still active". The schema column is the SSOT — query it directly.

### 2. Joining events to subscriptions to compute live MRR
Don't pull live `Subscription.data["items"]` into the analytics context to enrich at-risk rows with MRR-at-risk. This is the **temporal data leakage anti-pattern** explicitly called out in Phase 143's RESEARCH.md (lines 86-88). Hold the line: MRR appears in analytics only at confirmed-transition events where it was snapshotted at emission time.

### 3. Streams for static page data
LiveView 1.1 streams are for *mutating* lists (chat windows, live feeds, in-place row updates). The at-risk table refreshes only on `handle_params` reload and full `mount`. Use plain `assign(:at_risk, list)`. The LiveView 1.1 docs are explicit about this: streams *replace* assign for large lists where you want to keep DOM under control and apply incremental ops. v1.44's 10–500-row at-risk list at 30s+ refresh cadence is not the target use case.

### 4. Reaching across `accrue` → `accrue_admin` for schema fields
The `AccrueAdmin.Live.Analytics.*` modules must only call `Accrue.Analytics.Dunning.*`. They must **not** import `Ecto.Query`, alias `Accrue.Billing.Subscription`, or call `Accrue.Repo` directly. (Verify with `grep` in the verification phase.) Reasons: (a) keeps the public-API surface tight, (b) lets third-party non-admin dashboards reuse the context, (c) the context can later add caching/memoization/telemetry transparently.

### 5. Funnel that counts the sweeper's request-time event
`dunning.terminal_action_requested` (sweeper) is request-time intent and may double-count loss. It must **NEVER** appear in funnel stages. Already documented in `billing/dunning.ex:108-110`; we re-state for emphasis: the funnel is built from `campaign_started` + `step_sent` + `recovered` + `exhausted` only.

### 6. Wrapping the analytics call in `mount/3`
`mount/3` runs twice on LiveView connect (HTTP dead-render then WebSocket live-render). Put the heavy aggregations in `handle_params/3` so they run once per filter change, not twice per page load. Today's `RecoveryLive.mount/3` calls `Dunning.recovered_vs_lost_mrr()` — that's fine because Phase 143 didn't introduce window filtering. As of v1.44, this call moves into `handle_params/3` driven by the window param.

---

## Public API surface freeze (v1.44 lock-in)

The functions below become **public-stable** in v1.44. Adding new analytical queries in v1.45+ is fine; *changing the signature or semantics* of any of these would be a breaking change.

| Function | Status in 143 | Status after v1.44 | Stability |
|----------|---------------|--------------------|-----------|
| `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` | Shipped (143) | Stable | **Public-stable** |
| `Accrue.Analytics.Dunning.funnel/1` | — | New in v1.44 | **Public-stable** |
| `Accrue.Analytics.Dunning.at_risk_subscriptions/1` | — | New in v1.44 | **Public-stable** |
| `Accrue.Analytics.Dunning.campaign_timeline/2` | — | New in v1.44 (thin wrapper over `Events.timeline_for/3` with type filter) | **Public-stable** |
| `Accrue.Analytics.Dunning.bucket_recovered_mrr/2` | — | New in v1.44 if scope permits, else v1.45 | **Public-stable** |
| `Accrue.Billing.Query.in_active_dunning_campaign/1` | — | New in v1.44 | **Public-stable** (mirrors existing query helpers) |
| `Accrue.Billing.Dunning.recovered_vs_lost/1` (the *count*-based older sibling) | Shipped | Keep, document the relationship in moduledoc | **Public-stable** |

**Forward-compat hedge.** The `funnel/1` return-map shape uses **string-named atoms** (`:entered`, `:step_sent`, `:recovered`, `:exhausted`). Future multi-channel dunning aggregations (v1.45 `:in_app_sent`, `:sms_sent` etc.) extend this map by adding keys — additive, non-breaking. Callers that pattern-match on `%{entered: _, step_sent: _, recovered: _, exhausted: _} = funnel` continue to work; callers that pattern-match on `^%{} = funnel` (exact shape) would break, so the moduledoc must say "the funnel map is an open shape; do not exact-match".

**What to NOT make public in v1.44.**
- The funnel's internal `@type` aliases (keep them private — too easy to leak module-internal names).
- The `apply_window/3` `maybe_since/2` `maybe_until/2` helpers — internal, can be refactored later.
- Anything in `AccrueAdmin.Live.Analytics.*` — internal admin surfaces, never @doc'd as public.
- The `AccrueAdmin.Components.FunnelChart` — internal admin component, no @doc'd public attrs beyond what `Phoenix.Component`'s `attr/2` requires for compile-time validation.

---

## Telemetry surface

| Event | When | Measurements | Metadata | Why |
|-------|------|--------------|----------|-----|
| `[:accrue, :ops, :analytics_dashboard_loaded]` | After `handle_params/3` finishes the aggregation calls | `%{duration_us: integer, result_count: integer}` (where `result_count` = at-risk row count, useful for tail-latency vs result-size correlation) | `%{view: :recovery \| :campaign, window_days: integer, operation_id: ...}` | Adoption + JSONB perf tail-tracking. Already canonical-namespaced via `Accrue.Telemetry.Ops.emit/3`. |
| `[:accrue, :ops, :analytics_query_slow]` (optional) | When a single aggregation exceeds a threshold (e.g., >500ms) | `%{duration_us: integer}` | `%{query: :funnel \| :at_risk \| :recovered_vs_lost, window_days: integer}` | Detect when seed data + JSONB pattern starts losing to a host's volume. Operator-actionable signal that they should consider pre-aggregation. |

**Note.** The dashboard does NOT need request-time tracing because `Accrue.Telemetry.span_billing` already wraps the underlying public functions in `accrue` (it's the firehose namespace). Ops events are additive on top — and stay on the canonical `[:accrue, :ops, :*]` prefix verified in `telemetry/ops.ex:32-34` ("the prefix is hardcoded; callers cannot inject events outside the namespace via this helper").

---

## Scalability considerations

| Concern | At 100 subscriptions | At 10K subscriptions | At 1M subscriptions |
|---------|----------------------|----------------------|---------------------|
| Funnel query | <5ms (<1k events) | ~20–80ms (cold cache: index scan) | ~200ms–1s; **start considering** pre-aggregation rollup table | Phase v1.44 is target: small/mid SaaS up to ~10k subs. |
| At-risk query | <5ms (1–20 active campaigns) | ~10ms (50–500 active) | ~50ms (1k–10k active); `limit: 100` already caps the response | Pagination via cursor needed only at the >10k-active tier. |
| Per-subscription timeline | <5ms (10–50 events per subject) | <10ms | <50ms (clamp by `limit:` in `timeline_for/3`, default 1_000) | Already bounded. |

**Conclusion.** The Phase 143 + v1.44 architecture is sized correctly for the realistic target of an OSS Phoenix billing library: tens-of-thousands of subscriptions per host. Beyond that, a "rollup table" plan should be a documented v2.0 plan, not a v1.44 concern.

---

## Build order (de-risks compute path before navigation)

| Phase # | Sub-area | Why this order | Deliverable |
|---------|----------|----------------|-------------|
| 144 | **Funnel query + funnel HEEx component + first render on RecoveryLive** | Pure read-path addition. Proves the JSONB single-`group_by` pattern at scale. Zero write-path changes. If the funnel pattern doesn't compose well, we discover it BEFORE building UI navigation around it. | `funnel/1` + `FunnelChart` component + RecoveryLive renders funnel below KPI cards. |
| 145 | **Time-window URL plumbing on RecoveryLive** | Smallest-possible navigation change. Validates `handle_params/3` shape + the `:since` option threading through both `recovered_vs_lost_mrr/1` AND `funnel/1`. Once this is shipped, any further analytics function "comes with" window support for free. | `?window=7d \| 30d \| 90d` URL param + assigns + window selector UI. |
| 146 | **At-risk query + at-risk table** | Schema-side query is the simplest of all new functions (one `where: not is_nil(...)` clause). Table renders are plain HEEx. Validates the cross-package boundary discipline (LiveView must only call `Accrue.Analytics.Dunning`). | `at_risk_subscriptions/1` + at-risk section on RecoveryLive. |
| 147 | **Per-subscription drill-down route + CampaignLive** | Depends on at-risk table existing (row click navigates to drill-down). Reuses existing `Events.timeline_for/3` so the *backend* is trivially done — this phase is mostly LiveView + routing. | `/billing/analytics/recovery/subscriptions/:id` route + CampaignLive + per-row click affordance. |
| 148 | **Public docs (`guides/analytics.md`) + adopter-proof matrix row + example_host wiring** | Everything is built; lock the API surface in docs. Adopter-proof row in the public matrix. Seed mixed event data in `examples/accrue_host` so the dashboard demos end-to-end. | `guides/analytics.md`, matrix updated, example_host seeds new event types. |
| 149 (optional) | **Telemetry emit + bucket_recovered_mrr sparkline** | Polish. Skippable from v1.44 scope if velocity is tight; defer to v1.45 without breaking anything. | `[:accrue, :ops, :analytics_dashboard_loaded]` emission + optional sparkline component. |

**Rationale for ordering**:
1. **Compute before UI before navigation** — every phase's must-have is testable at the `mix test` level *before* the LiveView wrapper goes in.
2. **Read-path completion before UI deepening** — at-risk + drill-down are intentionally pushed later because the UX is "interesting" (table interaction, route nav) and shouldn't block the most-visible win (funnel visualization).
3. **Docs last but never skipped** — locking the public API in `guides/analytics.md` AFTER all functions are stable means we don't churn docs alongside design pivots.

---

## Open architectural questions (FLAGGED for plan-phase clarification)

| # | Question | Why it's a flag |
|---|----------|-----------------|
| Q1 | Should `at_risk_subscriptions/1` include MRR-at-risk as a column? | If yes, requires promoting `calculate_mrr_cents/1` out of `DefaultHandler` (private) into a shared module — that's an additional cross-cutting refactor. Recommendation: **defer to v1.45** unless plan-phase explicitly decides this is in-scope. |
| Q2 | Funnel: count *events* or *unique subscriptions* per stage? | Decision in this doc: **events** for v1.44 (simpler, matches Stripe Dashboard framing). If product wants unique subjects, that's a `funnel_unique_subjects/1` addition. |
| Q3 | Sparkline in v1.44 or deferred? | Recommended: deferred unless very-easy-to-add. If added, ship as count-based (`Events.bucket_by/2` direct reuse), not sum-based, to avoid introducing a new JSONB-sum helper that has only one caller. |
| Q4 | Should there be a CSV export of at-risk subscriptions? | Out of scope for v1.44 per the milestone "design constraint" — no general BI scope creep. Defer. |
| Q5 | Real-time refresh of the dashboard? (LiveView subscriptions to `accrue_events` inserts via PubSub) | Out of scope. v1.44 is manual refresh / handle_params reload. PubSub-driven liveness is a separate v1.45+ phase if any. |

---

## Sources

### Primary (HIGH confidence — codebase verification)

- `.planning/phases/143/143-RESEARCH.md` — locked architectural decisions for Phase 143 foundation.
- `.planning/phases/143/143-VERIFICATION.md` — confirmation that 4/4 Phase 143 must-haves shipped.
- `accrue/lib/accrue/analytics/dunning.ex` (73 LOC) — current public-API module, shipped Phase 143.
- `accrue/lib/accrue/billing/dunning.ex` (167 LOC) — sibling pure-policy module + the `recovered_vs_lost/1` count function and its documented exclusion of `dunning.terminal_action_requested`.
- `accrue/lib/accrue/webhook/default_handler.ex` (1924 LOC) — verified emission sites for all four lifecycle event types (`:1237` campaign_started, `:805` exhausted, `:886` recovered).
- `accrue/lib/accrue/workers/dunning_step.ex:196` — verified `dunning.step_sent` is already emitted.
- `accrue/lib/accrue/jobs/dunning_sweeper.ex:110` — verified `dunning.terminal_action_requested` exists (and why we exclude it).
- `accrue/lib/accrue/billing/subscription.ex:240-272` — `dunning_sweepable?/1`, `dunning_exhausted_status/1`, `dunning_campaign_active?/1` predicates.
- `accrue/lib/accrue/billing/query.ex:117-145` — existing query-composer patterns (`past_due/1`, `dunning_sweep_candidates/2`).
- `accrue/lib/accrue/events.ex` — `record/1`, `record_multi/3`, `timeline_for/3`, `bucket_by/2`, `state_as_of/3` API surface.
- `accrue/lib/accrue/telemetry/ops.ex:32-75` — canonical `[:accrue, :ops, :*]` emit helper.
- `accrue_admin/lib/accrue_admin/router.ex:75-77` — Phase 143's analytics scope inside `live_session :accrue_admin`.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (86 LOC) — current LiveView shape to be extended.
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:43-45`, `customers_live.ex:66`, `events_live.ex:27` — `handle_params(params, _uri, socket)` URL-param convention.
- `accrue_admin/lib/accrue_admin/components/{app_shell,breadcrumbs,kpi_card,data_table}.ex` — existing reusable component surface.
- `.planning/PROJECT.md:15-29` — v1.44 milestone scope, target features, design constraint.

### Secondary (MEDIUM confidence — Phoenix/LiveView convention)

- LiveView 1.1 streams documentation: streams are designed for mutating lists with incremental ops, not for static page data. Conclusion: don't use streams for v1.44's at-risk table.
- Ecto JSONB query patterns: `fragment("(?->>'key')::type", column)` is the canonical Postgres jsonb extraction pattern; already validated in 143.

### Confidence breakdown

- Standard stack: HIGH (everything is already in `mix.exs`; nothing new).
- Architecture: HIGH (every integration seam is named-and-verified in the existing codebase).
- Public API stability: HIGH (additive, open-shape return maps, no breaking changes).
- Build order: HIGH (orderable by strict dependency: compute → state → UI → navigation).
- Scalability ceiling: MEDIUM (target is ~10k subscriptions; beyond that needs a rollup plan that's intentionally out of v1.44 scope).
