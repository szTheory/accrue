# Phase 147: Per-subscription drill-down route + CampaignLive - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators click any row in the at-risk table (built in Phase 146) and land on `/billing/analytics/recovery/subscriptions/:id` — a per-subscription drill-down showing the full dunning timeline (campaign_started → step_sent ×N → recovered | exhausted) with linked invoice status, amount, and payment-method context inline. The route lives inside the existing `live_session :accrue_admin` block so admin auth is inherited from Phase 143.

**Scope anchor — what ships:**
- `Accrue.Analytics.Dunning.campaign_timeline/2` — thin wrapper around `Accrue.Events.timeline_for/3` filtered to `dunning.*` event types, ordered chronologically. Returns `[Event.t()]`. Re-usable by adopter dashboards. (DAN-05)
- `Accrue.Analytics.Dunning.campaign_timeline_grouped/2` — new thin pure function (~15 LOC, no DB call) that takes the flat event list and groups it by campaign arc via `Enum.chunk_by` on `type == "dunning.campaign_started"`. Returns `[{anchor :: String.t() | nil, events :: [Event.t()]}]`. Encapsulates the `dunning.step_sent`-no-`campaign_anchor` edge case (per DAN-02 scope) in one library location rather than outsourcing to every adopter.
- `Accrue.Analytics.Dunning.invoices_for_campaign/2` — new public function taking `(subscription_id :: String.t(), opts :: keyword())`, returns `%{invoice_id_string => %{status:, amount_due_cents:, card_last4:, card_brand:}}`. A single join query through Invoice → Subscription → PaymentMethod, indexed by the `invoice_id` stored in event `data` maps. Provides the invoice context that CampaignLive renders inline per event row.
- New route `/billing/analytics/recovery/subscriptions/:id` inside the `scope "/analytics"` block alongside `RecoveryLive`, still within `live_session :accrue_admin`.
- `AccrueAdmin.Live.Analytics.CampaignLive` — new LiveView; `mount/3` loads `%{"id" => subscription_id}`, calls `campaign_timeline_grouped/2` + `invoices_for_campaign/2`, assigns `@arcs` and `@invoice_map`; renders a `for {anchor, events} <- @arcs` comprehension via `CampaignTimeline`.
- `AccrueAdmin.Components.CampaignTimeline` — new purpose-built `Phoenix.Component` (~80-120 LOC) with three visually distinct row variants: campaign_started (anchor row), step_sent×N (retry rows with attempt number), terminal (recovered=green / exhausted=amber). Embeds `StatusBadge` and `format_money/3` as first-class calls inline per row.

**Out of scope (handled in later v1.44 phases):**
- Cross-currency widening, recovery-rate API, public docs (DAN-06/07/14/15/16) → Phase 148.
- Window selector on the drill-down view — CampaignLive shows full subscription history, no window filter needed.

</domain>

<decisions>
## Implementation Decisions

### Invoice context sourcing (DAN-05 + DAN-12)

- **D-01:** `campaign_timeline/2` returns `[Event.t()]` as spec'd in DAN-05 — a thin wrapper around `Accrue.Events.timeline_for("Subscription", subscription_id, ...)` filtered in-memory (or in-Ecto via a `where: e.type in ^dunning_types` clause) to `dunning.*` event types, ordered chronologically (`asc: e.inserted_at, asc: e.id`). Return type is NOT enriched — adopters who pattern-match on `Event.t()` are unaffected.
- **D-02:** New `Accrue.Analytics.Dunning.invoices_for_campaign/2` is the second public function for invoice context. Signature: `invoices_for_campaign(subscription_id :: String.t(), opts :: keyword()) :: %{String.t() => map()}`. Returns a map keyed by `invoice_id` string (the value stored in `dunning.campaign_started` event `data["invoice_id"]` — an Accrue Invoice UUID). Joins `accrue_invoices → accrue_subscriptions → accrue_payment_methods` (or `Accrue.Billing.Invoice` + linked PaymentMethod) to produce `%{status:, amount_due_cents:, card_last4:, card_brand:}` per invoice. Pre-v1.44 events without `invoice_id` in data: gracefully handled (`Map.get(@invoice_map, nil)` returns nil, rendered as `"—"`).
- **D-03:** `CampaignLive.mount/3` calls both functions and assigns independently — `@arcs` (from `campaign_timeline_grouped/2`) and `@invoice_map` (from `invoices_for_campaign/2`). Two DB queries for a drill-down detail page is the idiomatic Phoenix pattern (Pay, Oban Web, LiveDashboard all do parallel data loads in mount). No need for a single combined query.
- **D-04:** Cross-package boundary enforced: `CampaignLive` calls ONLY `Accrue.Analytics.Dunning.*`. No `Ecto.Query`, no `Accrue.Repo`, no `Accrue.Billing.*` aliases in `accrue_admin`. This will be enforced by a boundary assertion test (same pattern as DAN-11 in Phase 146).

### Multi-campaign timeline grouping (DAN-05 + DAN-12)

- **D-05:** `campaign_timeline_grouped/2` is a thin pure function (no DB call, no Ecto dependency). It takes the flat `[Event.t()]` from `campaign_timeline/2` (or equivalent) and groups via `Enum.chunk_by(&(&1.type == "dunning.campaign_started"), events)`. Each chunk starting with a `dunning.campaign_started` event forms one campaign arc. The `campaign_anchor` string is extracted from the first event in each chunk (`data["campaign_anchor"]`). Returns `[{anchor :: String.t() | nil, events :: [Event.t()]}]`.
- **D-06:** The `dunning.step_sent`-no-`campaign_anchor` edge case (per DAN-02 scope: `campaign_anchor` was only added to `dunning.recovered` and `dunning.exhausted`, not to `step_sent`) is handled by the `chunk_by` boundary logic: step events fall naturally between the campaign_started and terminal events in chronological order. No anchor assignment needed for step events — the grouping is driven by the `campaign_started` boundary event, not by the `campaign_anchor` field on each event.
- **D-07:** Still-active campaign (no terminal event yet): the last arc in the list has events ending with the most recent `dunning.step_sent` — rendered as an open section in `CampaignTimeline` (no terminal event = campaign ongoing). This is the expected state for subscriptions from the at-risk table.
- **D-08:** Both `campaign_timeline/2` and `campaign_timeline_grouped/2` are public API functions that will be frozen in Phase 148's API doc pass. Both belong in `Accrue.Analytics.Dunning` (not in `Accrue.Billing.*`) because they are read-path analytics queries, not billing write operations.

### CampaignTimeline component (DAN-12)

- **D-09:** New `AccrueAdmin.Components.CampaignTimeline` at `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex`. Purpose-built for the dunning narrative — three structurally distinct row variants:
  - `dunning.campaign_started` → anchor row (campaign header with date, failure reason if available)
  - `dunning.step_sent` × N → retry rows (step number, timestamp, linked invoice amount + status badge)
  - `dunning.recovered` | `dunning.exhausted` → terminal row (outcome with prominent color treatment, moss=recovered / amber=exhausted)
- **D-10:** `CampaignTimeline` embeds `StatusBadge.status_badge/1` (for invoice status) and `Accrue.Invoices.Render.format_money/3` (for amount display) directly as first-class function component calls inside `~H`. These are already available in `accrue_admin` — no new dependencies.
- **D-11:** The existing `AccrueAdmin.Components.Timeline` component is NOT modified — it has no slot/inner_block machinery (plain string-map assigns), and adding slots would require dual-mode logic that risks `SubscriptionLive` regression. Project precedent is purpose-built components for domain-specific views (KpiCard, AtRiskTable, FunnelChart, WindowSelector).
- **D-12:** `CampaignTimeline` accepts `arcs` (grouped arc list from `campaign_timeline_grouped/2`) and `invoice_map` (from `invoices_for_campaign/2`) as attrs. Renders a `for {anchor, events} <- @arcs` outer loop + inner `for event <- events` per row.

### CampaignLive architecture (DAN-12)

- **D-13:** `CampaignLive` uses `mount/3`-based data loading (not `handle_params/3`), since this is a static detail view: `mount(%{"id" => subscription_id}, session, socket)` calls `Dunning.campaign_timeline_grouped/2` and `Dunning.invoices_for_campaign/2`, assigns results. `handle_params/3` is not needed — no URL params beyond `:id` need parsing.
- **D-14:** No window selector on the drill-down view. `CampaignLive` shows the full dunning history for the subscription regardless of the window selected on `RecoveryLive`. The URL is the subscription identity only.
- **D-15:** Not-found handling: if `campaign_timeline_grouped/2` returns an empty list for an unknown/wrong subscription_id, render a "No dunning history found" empty state rather than 404. (The subscription may exist but have no dunning events — this is valid.) If the subscription_id is malformed/nonexistent, the query returns `[]` gracefully.

### Route placement (DAN-12)

- **D-16:** New route added to the `scope "/analytics", AccrueAdmin.Live.Analytics` block in `AccrueAdmin.Router`: `live("/recovery/subscriptions/:id", CampaignLive, :show)`. This is a sibling to the existing `live("/recovery", RecoveryLive, :index)` — both are inside `live_session :accrue_admin`, so admin auth is inherited without modification.

### Claude's Discretion

- Exact Ecto query shape for `campaign_timeline/2`: in-memory filter (call `timeline_for/3` and `Enum.filter`) vs. Ecto `where: e.type in ^dunning_types` clause. Recommend in-Ecto for efficiency (dunning events are a small fraction of all subscription events — skip the DB fetch of irrelevant event types).
- `invoices_for_campaign/2` join shape: single compound query through Invoice + PaymentMethod, or a two-step load (Invoice query, then PaymentMethod query). Either is fine; planner picks the cleanest Ecto expression.
- Breadcrumb for `CampaignLive`: `[%{label: "Analytics"}, %{label: "Recovery", href: base_path <> "/analytics/recovery"}, %{label: "Subscription"}]`. Back-link to `RecoveryLive` preserves the breadcrumb trail without needing `?window=` param preservation (the drill-down is window-agnostic).
- CSS class names for `CampaignTimeline` row variants: `ax-campaign-timeline-anchor`, `ax-campaign-timeline-step`, `ax-campaign-timeline-terminal`. Planner picks exact names following `ax-` prefix convention.
- Step numbering: `dunning.step_sent` events numbered 1..N by position within the campaign arc (1-indexed). "Attempt 1", "Attempt 2", etc. Planner picks the display string.
- `invoices_for_campaign/2` opts: planner determines if `:since`/`:until` window bounds are threaded through (recommend NO — invoice context for a drill-down is window-agnostic; load all invoices for campaigns regardless of time window).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope + requirements
- `.planning/REQUIREMENTS.md` §"Public API & Core Math (DAN)" DAN-05 — `campaign_timeline/2` spec: thin wrapper around `timeline_for/3`, filtered to `dunning.*` types, chronological order, re-usable by adopter dashboards
- `.planning/REQUIREMENTS.md` §"Admin UI Recovery Dashboard (DAN)" DAN-12 — route spec, `CampaignLive` module name, timeline variant requirements, row-click affordance from DAN-11 table
- `.planning/ROADMAP.md` §"Phase 147" — goal + 4 success criteria (shareable URL, full timeline, linked invoice+payment-method, campaign_timeline/2 thin-wrapper)

### Prior phase foundations (DO NOT regress)
- `.planning/phases/146-at-risk-query-at-risk-table-last-failure-enrichment/146-CONTEXT.md` — D-01 through D-15: at-risk query shape, oban ETA, invoice_id enrichment on `dunning.campaign_started` events (D-04), `invoice_id` is an Accrue Invoice UUID; AtRiskTable component row-click link (`/analytics/recovery/subscriptions/<subscription_id>`) already ships in Phase 146 — Phase 147 must make that URL work.
- `.planning/phases/145-time-window-url-plumbing-window-selector/145-CONTEXT.md` — D-01 through D-09: `handle_params/3` pattern, `parse_window/1`, `window_bounds/1`, `apply_window/2`. CampaignLive does NOT need window opts, but must not regress the pattern in RecoveryLive.
- `.planning/phases/144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po/144-CONTEXT.md` — D-19/D-20: `format_money/3` via `Accrue.Invoices.Render.format_money/3` + `Accrue.Config.get!(:default_currency)` + `Accrue.Config.default_locale()`. Same call pattern in `CampaignTimeline` for amount display.

### Live code touchpoints
- `accrue/lib/accrue/events.ex` line 261 — `timeline_for/3` signature: `(subject_type :: String.t(), subject_id :: String.t(), opts :: keyword()) :: [Event.t()]`; called as `Events.timeline_for("Subscription", subscription_id)` inside `campaign_timeline/2`
- `accrue/lib/accrue/analytics/dunning.ex` — add `campaign_timeline/2`, `campaign_timeline_grouped/2`, `invoices_for_campaign/2` alongside existing `funnel/1`, `at_risk_subscriptions/1`, `recovered_vs_lost_mrr/1`
- `accrue_admin/lib/accrue_admin/router.ex` lines 74–77 — `scope "/analytics", AccrueAdmin.Live.Analytics` block; add `live("/recovery/subscriptions/:id", CampaignLive, :show)` as sibling to `live("/recovery", RecoveryLive, :index)`
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — DO NOT modify data loading; AtRiskTable row-click link already ships in Phase 146 pointing to the Phase 147 route
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` — `<a href={@base_path <> "/analytics/recovery/subscriptions/" <> row.subscription_id}>` already rendered in Phase 146 — Phase 147 makes the destination exist
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — closest structural analog for `CampaignLive`; uses `mount/3` with `%{"id" => id}`, loads data, `assign_shell`, breadcrumbs pattern
- `accrue_admin/lib/accrue_admin/components/` — existing component directory; `StatusBadge`, `KpiCard`, `FunnelChart`, `AtRiskTable` all live here; add `campaign_timeline.ex`
- `accrue_admin/lib/accrue_admin/components/timeline.ex` — existing generic Timeline component (DO NOT modify); has no slot machinery (plain string-map assigns); `CampaignTimeline` is a separate file

### Tests
- `accrue/test/accrue/analytics/dunning_test.exs` — add: `campaign_timeline/2` returns only `dunning.*` events in chronological order; `campaign_timeline_grouped/2` groups correctly by arc (two campaigns, one recovered one active); `invoices_for_campaign/2` returns invoice map indexed by invoice_id; nil invoice_id gracefully returns nil entry
- `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` — new test file: renders full timeline for a subscription with 2 campaign arcs; renders empty state for unknown subscription_id; cross-package boundary assertion (no Ecto.Query / Repo / Billing.* aliases in CampaignLive)
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — verify at-risk table row links to the Phase 147 route (`/analytics/recovery/subscriptions/<id>`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Events.timeline_for/3` — core function for `campaign_timeline/2`: call as `timeline_for("Subscription", subscription_id)`, then filter to `dunning.*` types. Already handles ordering (`asc: inserted_at, asc: id`) and `upcast_to_current/1` migration.
- `AccrueAdmin.Components.StatusBadge` — use in `CampaignTimeline` for invoice status cells (`:draft`, `:open`, `:paid`, `:void` states → tone-coded badges). Already imported pattern across admin LiveViews.
- `Accrue.Invoices.Render.format_money/3` — use in `CampaignTimeline` for amount display. Same call as in `RecoveryLive` (Phase 144 D-20): `format_money(cents, currency, locale)`.
- `AccrueAdmin.Components.Breadcrumbs` — use in `CampaignLive` for back-nav to Recovery Dashboard. Pattern: `%{label: "Recovery", href: base_path <> "/analytics/recovery"}`.
- `AccrueAdmin.Live.SubscriptionLive` — structural template for `CampaignLive`: `mount/3` with `%{"id" => id}`, `assign_shell/2`, breadcrumbs assignment, not-found handling via redirect.
- `Accrue.Analytics.Dunning.apply_window/2` — NOT used in CampaignLive (drill-down is window-agnostic) but available in `dunning.ex` if `invoices_for_campaign/2` opts ever need window bounds.
- Phase 146 `AtRiskTable` component: already renders `<a href="/analytics/recovery/subscriptions/<subscription_id>">` — Phase 147 makes that URL resolve.

### Established Patterns
- `mount/3`-based data loading for detail views (SubscriptionLive, CustomerLive, InvoiceLive): all use `mount/3` with the `:id` param, not `handle_params/3`. `CampaignLive` follows this pattern.
- Cross-package boundary: `accrue_admin` LiveViews call ONLY `Accrue.Analytics.Dunning.*` for analytics data (no Ecto.Query, no Accrue.Repo in accrue_admin). Enforced by boundary assertion tests.
- Purpose-built components for domain-specific views: every domain-specific component (KpiCard, AtRiskTable, FunnelChart, WindowSelector) is a standalone file in `accrue_admin/lib/accrue_admin/components/`. `CampaignTimeline` follows this pattern.
- `Enum.chunk_by` for grouping by boundary events: pure Elixir, no DB call. `chunk_by(&(&1.type == "dunning.campaign_started"), events)` produces groups starting at each campaign_started event.
- `assign_shell/2` + `page_title` pattern from `SubscriptionLive` — CampaignLive assigns `page_title: "Dunning Timeline"` or `"Campaign History — <subscription_id>"`.

### Integration Points
- `accrue_admin/lib/accrue_admin/router.ex` — add `live("/recovery/subscriptions/:id", CampaignLive, :show)` to the `scope "/analytics"` block (line ~76 area)
- `accrue/lib/accrue/analytics/dunning.ex` — add 3 new functions: `campaign_timeline/2`, `campaign_timeline_grouped/2`, `invoices_for_campaign/2`
- `accrue_admin/lib/accrue_admin/live/analytics/` — add `campaign_live.ex`
- `accrue_admin/lib/accrue_admin/components/` — add `campaign_timeline.ex`

</code_context>

<specifics>
## Specific Ideas

- **`invoices_for_campaign/2` return shape**: `%{invoice_id_string => %{status: atom(), amount_due_cents: integer(), card_last4: String.t() | nil, card_brand: String.t() | nil}}`. The `card_last4`/`card_brand` come from the subscription's linked `PaymentMethod` (not from the invoice directly). If a subscription has no default payment method, both are nil → rendered as `"—"` in the timeline.
- **`campaign_timeline_grouped/2` edge case**: when `events` is empty (`[]`), return `[]`. When events start with a non-`campaign_started` event (pre-v1.44 legacy data), they land in a `{nil, [...]}` prefix bucket from `Enum.chunk_by` — render as "Legacy events" section in `CampaignTimeline` or omit silently.
- **`CampaignTimeline` row for `dunning.step_sent`**: display attempt number as 1-indexed position within the arc (e.g., "Attempt 1", "Attempt 2"). Invoice amount + status from `@invoice_map[event.data["invoice_id"]]`. Payment method context shown once at the arc header (campaign_started row) rather than repeated per step row.
- **`CampaignTimeline` terminal row**: `dunning.recovered` → `tone="moss"` + "Recovered" label. `dunning.exhausted` → `tone="amber"` + "Exhausted" label. MRR value from `event.data["mrr_value_cents"]` + `event.data["currency"]` formatted via `format_money/3`.
- **Route precedent**: `live("/recovery/subscriptions/:id", ...)` inside `scope "/analytics"` follows the existing `live("/customers/:id", CustomerLive, :show)` and `live("/subscriptions/:id", SubscriptionLive, :show)` pattern — detail routes use `:show` action.

</specifics>

<deferred>
## Deferred Ideas

- Window selector on CampaignLive (e.g., to limit visible campaigns to the currently-selected time window) → post-v1.44 if operators request it.
- MRR-at-risk per campaign arc (what MRR was at risk during this specific campaign) → v1.45+.
- Direct link from CampaignLive to the underlying Invoice detail (`/billing/invoices/:id`) or Subscription detail (`/billing/subscriptions/:id`) → could be added as a follow-on enhancement, but not in Phase 147 scope.
- `campaign_timeline/2` accepting `:types` opt to filter to a subset of dunning events → adopter need, deferred to when an adopter requests it.

</deferred>

---

*Phase: 147-per-subscription-drill-down-route-campaignlive*
*Context gathered: 2026-05-27*
