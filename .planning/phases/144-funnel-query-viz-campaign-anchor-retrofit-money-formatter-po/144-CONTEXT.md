# Phase 144: Funnel query + viz + campaign-anchor retrofit + money formatter polish - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators see a credible 3-stage dunning funnel (Entered → Recovered → Exhausted, with an "active" count) rendered as inline-SVG below the existing 2 KPI cards on `/billing/analytics/recovery`. No double-counting under cycled-dunning subscriptions, no dashboard crash from a single malformed JSONB row, and currency-correct money labels for any currency (JPY, EUR, GBP, USD). Phase 144 also lands the Phase-143 forward-fix to the write path: `campaign_anchor` is snapshotted onto `dunning.recovered` and `dunning.exhausted` event payloads (DAN-02 — required for funnel double-counting prevention).

**Scope anchor — what ships:**
- `Accrue.Analytics.Dunning.funnel/1` public API returning `%{entered: N, recovered: N, exhausted: N, active: N}` over a window (DAN-01).
- `campaign_anchor` ISO-8601 snapshot retrofit on the two terminal-edge `Events.record`/`Events.record_multi` call sites in `default_handler.ex` (DAN-02).
- JSONB CASE-WHEN safe-cast wrapper applied to every `(?->>'mrr_value_cents')::integer` aggregation site (DAN-08).
- `AccrueAdmin.Components.FunnelChart` HEEx component with inline-SVG left-aligned proportional bars + external `<dl>` legend, slotted below `ax-kpi-grid` on `RecoveryLive` (DAN-09).
- `RecoveryLive.format_minor/1` replaced with `AccrueAdmin.Components.MoneyFormatter` (or `Render.format_money/3` directly) driven off `Accrue.Config.default_currency()`; "Lost MRR" copy renamed to "Exhausted MRR" with tooltip + yearly-plan worked example (DAN-13).

**Out of scope (handled in later v1.44 phases):**
- Time-window URL plumbing / window selector → Phase 145 (DAN-10).
- At-risk subscriptions query + table + last-failure enrichment → Phase 146 (DAN-03/04/11).
- Per-subscription drill-down route + `CampaignLive` → Phase 147 (DAN-05/12).
- BREAKING per-currency widening of `recovered_vs_lost_mrr/1`, `recovery_rate/1`, `guides/analytics.md`, adopter-proof matrix row → Phase 148 (DAN-06/07/14/15/16).

</domain>

<decisions>
## Implementation Decisions

### Funnel query — Active-stage attribution (DAN-01)

- **D-01:** Single Ecto query using a `GROUP BY (subject_id, COALESCE(data->>'campaign_anchor', '__legacy__'))` pass with `bool_or(type IN ('dunning.recovered','dunning.exhausted'))` as the conclusion flag. Aggregate per-stage counts in a single round-trip:
  - `entered` = COUNT of all distinct tuples
  - `recovered` = COUNT FILTER (WHERE concluded AND has dunning.recovered)
  - `exhausted` = COUNT FILTER (WHERE concluded AND has dunning.exhausted)
  - `active` = COUNT FILTER (WHERE NOT concluded)
- **D-02:** Pure-ledger, zero schema joins. Funnel reads only `accrue_events`. Rationale: ledger is immutable historical truth; `accrue_subscriptions` mutations (deletion, status changes) would warp window-bounded historical counts. Preserves Phase 143's pure-ledger JSONB precedent.
- **D-03:** No `Task.async` per stage — explicit single `from(e in Event, ...)` query per REQUIREMENTS DAN-01.
- **D-04:** Property test (stream_data): generate sequences of dunning events per subject; assert `recovered + exhausted + active ≤ entered` invariant. Counter-example focus: subscriptions cycling dunning multiple times within a single window.

### Funnel query — Legacy `campaign_anchor` fallback (DAN-02)

- **D-05:** `COALESCE(data->>'campaign_anchor', '__legacy__')` sentinel-per-subject. Collapses ALL pre-retrofit events for a subject_id into ONE tuple per stage ("earliest known single-row stage attribution" per REQUIREMENTS line 22). Under-count is the safe failure mode for a billing library (Pitfall #1 = double-counting, not under-counting; over-counting recovered-revenue destroys trust).
- **D-06:** Document the cutoff in `guides/analytics.md` (Phase 148's DAN-14 scope) — extend the existing "Showing data since YYYY-MM-DD" badge concept to cover the funnel anchor cutoff. Phase 144 does NOT add the badge UI; just documents the semantics in the funnel `@doc`.
- **D-07:** Backfill is explicitly architecturally impossible (`accrue_events` immutability trigger SQLSTATE 45A01). REQUIREMENTS out-of-scope confirms this. Adopter base is alpha + v1.4.0 unpublished → "legacy" events only exist in adopter dev envs between P143 and P144 shipping.

### Campaign-anchor snapshot retrofit (DAN-02)

- **D-08:** Retrofit two write sites in `accrue/lib/accrue/webhook/default_handler.ex`:
  - `dunning.recovered` emission (~line 885, inside `Events.record_multi` inside the multi alongside `clear_anchor`).
  - `dunning.exhausted` emission (~line 804, inside `Events.record/1`).
- **D-09:** Field shape: `campaign_anchor: DateTime.to_iso8601(row.dunning_campaign_started_at)` (ISO-8601 string). The row's `dunning_campaign_started_at` is captured BEFORE the `force_status_changeset` `clear_anchor` write — current code at `:867-868` already reads it into `anchor` + `iso_anchor`. Inject `iso_anchor` into the event `data` map.
- **D-10:** Direct unit assertion at the emission boundary: extend `dunning_exhaustion_test.exs` and `dunning_campaign_keying_test.exs` (or the recovery-edge equivalent) to assert `ledger.data["campaign_anchor"]` is a parseable ISO-8601 string. Closes the Phase 143 emission-boundary test coverage gap noted in `143-VERIFICATION.md` §"Notes / Minor Observations" #1.

### JSONB cast safety (DAN-08)

- **D-11:** Wrap every `(?->>'mrr_value_cents')::integer` cast in the canonical safe-cast pattern: `CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END`. Apply at:
  - Existing `recovered_vs_lost_mrr/1` aggregation site (`accrue/lib/accrue/analytics/dunning.ex:46`).
  - Any new funnel query MRR-sum projections (if added — funnel itself does not sum MRR, only counts tuples, so safe-cast is primarily for `recovered_vs_lost_mrr/1` and any future shared aggregator).
- **D-12:** Regression test: insert a `dunning.recovered` event with `"mrr_value_cents": "5000"` (string-typed) and assert `recovered_vs_lost_mrr/1` returns successfully with the malformed row contributing 0. Lives in `accrue/test/accrue/analytics/dunning_test.exs`.

### FunnelChart visualization (DAN-09)

- **D-13:** Layout: **left-aligned horizontal proportional bars** — each stage = one `<rect>` whose width is proportional to `stage_count / entered_count`. Inline SVG with `viewBox="0 0 100 36"` so widths are percentages; three `<g transform="translate(0, idx*12)">` rows; each row has `<rect width={pct} height="10" rx="1.5">` + an inline `<title>` for hover tooltip. External `<dl class="ax-funnel-legend">` renders label/count/% (so the info survives a11y/zoom — not SVG-only).
- **D-14:** Tones reuse the existing `ax-kpi-delta-*` palette: `slate` (entered), `moss` (recovered), `amber` (exhausted). Light/dark theming free via `currentColor` + `var(--ax-accent)` CSS custom properties — mirrors the `ax-kpi-sparkline` pattern.
- **D-15:** Accessibility: `role="img"` on the SVG; linked `<title id="funnel-title">` + `<desc id="funnel-desc">` referenced via `aria-labelledby="funnel-title funnel-desc"`. Per-bar inline `<title>` for hover/screen-reader tooltips.
- **D-16:** Tooltips on each stage define the term. "Exhausted" tooltip carries the worked yearly-plan example (e.g., "A $120/yr plan that exhausts dunning contributes $10/mo to Exhausted MRR — annualized MRR snapshot at the exhaustion event").
- **D-17:** Component file: `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`. Functional `Phoenix.Component`. Closest analog: `accrue_admin/lib/accrue_admin/components/kpi_card.ex` (same wrapping `ax-card` shell + slot pattern). CSS classes added to `accrue_admin/assets/css/app.css`: `.ax-funnel-chart`, `.ax-funnel-row`, `.ax-funnel-row--{slate,moss,amber}`, `.ax-funnel-bar`, `.ax-funnel-legend`.
- **D-18:** Insertion point: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — append `<FunnelChart.funnel_chart .../>` directly BELOW the existing `<section class="ax-kpi-grid">` block.

### Currency strategy on KPI cards (DAN-13)

- **D-19:** Replace `RecoveryLive.format_minor/1` (USD-only `:erlang.float_to_binary`) with a call into `AccrueAdmin.Components.MoneyFormatter` (or `Accrue.Invoices.Render.format_money/3` directly — `MoneyFormatter` already wraps it). Render the cents value with `currency = Accrue.Config.default_currency()` and `locale = Accrue.Config.default_locale()`.
- **D-20:** Do NOT change the `recovered_vs_lost_mrr/1` return shape in Phase 144. The single-aggregate `%{recovered_cents: int, lost_cents: int}` shape stays untouched — Phase 148's DAN-07 per-currency widening becomes a single clean BREAKING change instead of "undo P144 then widen". The `cents` value is already a cross-currency sum; tagging it with the tenant default currency is no MORE dishonest than tagging it with the latest event's currency.
- **D-21:** DAN-13 JPY regression test: in `recovery_live_test.exs` setup, `Application.put_env(:accrue, :default_currency, :jpy)` (with `on_exit` cleanup), seed a `dunning.recovered` event with `currency: "jpy"` and `mrr_value_cents: 5000`, assert the rendered HTML contains `¥50` (or CLDR's locale-correct rendering). Standard `Application.put_env` test pattern already used elsewhere in `accrue_admin/test`.
- **D-22:** Funnel labels themselves are MRR-free (counts + percentages only). DAN-13 currency strategy applies ONLY to the two KPI cards.
- **D-23:** "Lost MRR" KPI card label renamed to "Exhausted MRR" per ROADMAP success criterion #5; tooltip + worked example align with FunnelChart's Exhausted-stage tooltip (D-16) for consistency.

### Claude's Discretion

- Test file placement for the campaign-anchor retrofit assertions. Likely `dunning_exhaustion_test.exs` (exhausted edge) + `dunning_campaign_keying_test.exs` or a new `dunning_recovery_test.exs` (recovery edge) — planner picks based on closest existing test surface.
- Exact CSS values (color hex/HSL, exact pixel offsets) — pick from existing `ax-` tokens, no new design-system tokens.
- Exact `stream_data` generator shape for the funnel property test (subject_id pool size, event sequence length distribution).
- Whether to extract a shared `defp safe_mrr_cents_sum` macro/helper for the JSONB CASE-WHEN cast or inline at each call site. Lean inline since only ~1–2 call sites in P144.
- ExDoc `@doc` examples on `funnel/1` — include at least one `iex>` example with a cycled-dunning fixture so the DISTINCT-tuple semantics are self-documenting.
- Exact yearly-plan worked-example copy in the Exhausted tooltip — phrasing the planner can polish.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope + requirements
- `.planning/REQUIREMENTS.md` §"Public API & Core Math (DAN)" DAN-01, DAN-02, DAN-08 — funnel API shape, retrofit, JSONB safe-cast.
- `.planning/REQUIREMENTS.md` §"Admin UI Recovery Dashboard (DAN)" DAN-09, DAN-13 — funnel viz, money formatter.
- `.planning/ROADMAP.md` §"Phase 144" — goal + 5 success criteria.
- `.planning/REQUIREMENTS.md` §"Out of Scope (explicit non-goals for v1.44)" — anti-features.

### Phase 143 foundation (DO NOT regress)
- `.planning/phases/143/143-VERIFICATION.md` — what's already shipped (KPI cards, route under `live_session :accrue_admin`, `recovered_vs_lost_mrr/1`, MRR snapshotting). Verification log + the test-coverage gap to close.
- `.planning/phases/143/143-RESEARCH.md` §"Code Examples" — `calculate_mrr_cents/1` pattern; snapshotting site reference.
- `.planning/phases/143/143-PATTERNS.md` — analog map for `recovery_live.ex` ↔ `dashboard_live.ex` and `analytics/dunning.ex` ↔ `billing/dunning.ex`.

### Live code touchpoints
- `accrue/lib/accrue/analytics/dunning.ex` — existing `recovered_vs_lost_mrr/1`; Phase 144 adds `funnel/1` here. JSONB safe-cast applies to existing `fragment("(?->>'mrr_value_cents')::integer", e.data)` at line 46.
- `accrue/lib/accrue/webhook/default_handler.ex` `:782-820` (exhausted emission), `:867-897` (recovered emission inside multi) — campaign-anchor retrofit sites. `iso_anchor` is already captured at `:868`.
- `accrue/lib/accrue/events/event.ex` + `accrue/lib/accrue/events.ex` (`Events.record/1`, `Events.record_multi/3`) — event-write API used by retrofit.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — `format_minor/1` USD-bug fix site (`:76-81`); funnel insertion point below `ax-kpi-grid` (`:38-56`); `"Lost MRR"` → `"Exhausted MRR"` rename (`:49`).
- `accrue_admin/lib/accrue_admin/components/money_formatter.ex` — canonical money component; wraps `Accrue.Invoices.Render.format_money/3` with CLDR via `ex_money` + `ex_cldr`. Use this from `RecoveryLive`.
- `accrue_admin/lib/accrue_admin/components/kpi_card.ex` — closest functional-component analog for `FunnelChart` (same `ax-card` shell + slot pattern).
- `accrue/lib/accrue/invoices/render.ex` `:106-132` — `format_money/3` API contract (NEVER raises; falls back to `"N currency"` raw string on second failure).
- `accrue/lib/accrue/config.ex` `:1022-1023` — `Accrue.Config.default_currency/0` accessor; `:374-…` — `default_locale` accessor.

### Tests
- `accrue/test/accrue/analytics/dunning_test.exs` — existing aggregation + window tests; add funnel tests + JSONB safe-cast regression + property test here.
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` `:308-311` — extend to assert `campaign_anchor` is present in recorded event payload.
- `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` — recovery edge; assert `campaign_anchor` on `dunning.recovered` event.
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — add JPY regression test with `Application.put_env(:accrue, :default_currency, :jpy)`; assert funnel renders + KPI cards use `¥` symbol.

### Cross-phase coordination
- `.planning/threads/v1.44-NEXT-STEP-ASSESSMENT.md` — design constraint: ledger-only, no new tables, no new deps.
- `.planning/STATE.md` — milestone v1.44 progress; Phase 144 is first of 5 in v1.44.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Invoices.Render.format_money/3` — CLDR-correct money rendering with double-fallback (locale fallback → raw string fallback). Never raises. Use directly OR via `AccrueAdmin.Components.MoneyFormatter`.
- `AccrueAdmin.Components.MoneyFormatter` — already-wired Phoenix.Component that resolves locale (assigns → customer.preferred_locale → `Accrue.Config.default_locale()`) and dispatches to `Render.format_money/3`. Drop-in for `format_minor/1` callers.
- `AccrueAdmin.Components.KpiCard` — closest analog for `FunnelChart`: functional component, `ax-card` shell, slot-based composition. Mirror its `kpi_inner/1` pattern.
- `Accrue.Events.Event` schema + `Accrue.Repo` — used by `Accrue.Analytics.Dunning` already; no new schema/migration needed.
- `Accrue.Config.default_currency/0` and `default_locale/0` — accessors for tenant defaults; runtime-configurable; no compile-time leakage.
- `ax-kpi-sparkline` SVG pattern in `accrue_admin/assets/css/app.css` — inline-SVG + `currentColor` + `var(--ax-accent)` theming idiom that `.ax-funnel-chart` will mirror.
- `iso_anchor` already captured at `default_handler.ex:868` BEFORE the `clear_anchor` write — no new DateTime read needed for the retrofit.

### Established Patterns
- **Ledger-canonical aggregation:** Phase 143 shipped `recovered_vs_lost_mrr/1` as `from(e in Event, group_by: e.type, select: ...)` over `accrue_events` only — no schema joins. Phase 144 funnel MUST preserve this.
- **Single-query Ecto, not `Task.async`:** Per REQUIREMENTS DAN-01. Phase 143's existing query is the precedent.
- **JSONB fragments via Ecto `fragment/1`:** `fragment("(?->>'mrr_value_cents')::integer", e.data)`; safe-cast wrapping applies the same pattern with `CASE WHEN jsonb_typeof((?->'key')) = 'number' THEN ... ELSE 0 END`.
- **Event payloads:** Both `dunning.recovered` and `dunning.exhausted` already carry `data.mrr_value_cents` + `data.currency` from Phase 143; retrofit adds `data.campaign_anchor` alongside (no schema change — `data` is jsonb).
- **Functional components for admin UI:** `Phoenix.Component`, `attr`/`slot` macros, `~H` sigil. No LiveView socket runtime in components themselves.
- **Test seeding via `Events.record/1`:** Standard pattern used in `recovery_live_test.exs`; carries through directly to the JPY regression test + funnel property test.
- **`live_session :accrue_admin` admin-auth inheritance:** Phase 143 nested `/billing/analytics/recovery` inside the admin live_session; no router changes needed in Phase 144 (FunnelChart is a component, not a new route).
- **Atomic write inside `Repo.transact`/`Multi`:** Recovered-edge anchor-clear + ledger record are folded into the same `Ecto.Multi`. Retrofit injects `campaign_anchor` into the `data` map without changing the transaction shape.

### Integration Points
- `recovery_live.ex` mount/render: append `<FunnelChart.funnel_chart entered={...} recovered={...} exhausted={...} active={...} />` below `ax-kpi-grid`. Add `funnel = Dunning.funnel(opts)` call in `mount/3` alongside existing `stats = Dunning.recovered_vs_lost_mrr()`.
- `default_handler.ex`: extend the two `Events.record`/`Events.record_multi` `data:` map literals at `:805-814` (exhausted) and `:885-894` (recovered) with `campaign_anchor: iso_anchor` (or compute inline from `row.dunning_campaign_started_at`).
- `accrue_admin/assets/css/app.css`: add `.ax-funnel-*` classes adjacent to existing `.ax-kpi-*` block. No new design-system tokens — reuse `--ax-accent`, `--ax-success`, `--ax-warning` (or equivalent moss/amber custom properties already defined).

</code_context>

<specifics>
## Specific Ideas

- **Funnel SVG shape:** left-aligned horizontal proportional bars, NOT a centered trapezoidal classic funnel. Reads cleanly within the rectangular `ax-card` design system Accrue has converged on; trapezoid would read as a third-party widget bolted on. Mirror the `ax-kpi-sparkline` inline-SVG pattern.
- **`bool_or` over GROUP BY (subject_id, anchor):** the concrete SQL shape for the funnel — avoids correlated subqueries entirely; one pass; Postgres planner converts directly to a single aggregate.
- **Sentinel `'__legacy__'`:** literal string. NOT a UUID, NOT a per-event hash — the WHOLE POINT is to collapse legacy events per subject into one tuple ("earliest known single-row attribution"). Documented in the funnel `@doc` so adopters reading the source aren't surprised.
- **`Application.put_env(:accrue, :default_currency, :jpy)` in JPY-regression test setup:** the standard pattern. `on_exit` restores. Don't rebuild the test infrastructure around per-event currency tagging — that's P148's job.
- **Tone palette:** `slate` (entered, neutral), `moss` (recovered, positive), `amber` (exhausted, warning). Picked from existing `ax-kpi-delta-*` palette in `kpi_card.ex:62`.
- **Active count exposure:** the funnel's `active` count is included in the public API map (`%{entered, recovered, exhausted, active}`) AND rendered visually adjacent to the funnel (NOT as a 4th bar — it's "currently in flight" so it doesn't sit inside the funnel of concluded outcomes). Render as a small chip/badge next to the funnel header (e.g., `<span class="ax-funnel-active-chip">{active} currently in dunning</span>`). Planner: confirm placement.

</specifics>

<deferred>
## Deferred Ideas

- **Per-currency widening of `recovered_vs_lost_mrr/1` + `funnel/1`** → Phase 148 (DAN-07). BREAKING change. P144's job is the float_to_binary bug fix only.
- **`recovery_rate/1` public API** → Phase 148 (DAN-06).
- **`guides/analytics.md` public doc + `@moduledoc` expansion + analytics-guide pointer needle in `verify_package_docs.sh`** → Phase 148 (DAN-14, DAN-15).
- **Adopter-proof matrix row + deterministic-clock seed wiring in `examples/accrue_host`** → Phase 148 (DAN-16).
- **"Showing data since YYYY-MM-DD" cutoff badge UI** → Phase 148 (DAN-14). P144 only documents the funnel cutoff semantics in the function `@doc`; UI badge ships with the guide.
- **`?window=7d|30d|90d` URL plumbing + window selector** → Phase 145 (DAN-10). P144 funnel accepts `:since`/`:until` opts (mirroring `recovered_vs_lost_mrr/1`) so P145 can thread them through without re-touching the funnel API.
- **At-risk subscriptions table + `at_risk_subscriptions/1` + `in_active_dunning_campaign/1` query composer + last-failure enrichment** → Phase 146 (DAN-03, DAN-04, DAN-11).
- **`campaign_timeline/2` API + per-subscription drill-down route + `CampaignLive`** → Phase 147 (DAN-05, DAN-12).
- **Per-step funnel breakdown** — explicitly out-of-scope for v1.44 per REQUIREMENTS "Out of Scope".
- **Sparkline on KPI cards** — deferred unless trivially reusable via `Accrue.Events.bucket_by/2`; not P144 work.
- **`opentelemetry`-bridged dashboard-load span** — explicit non-goal v1.44.
- **Funnel-stage click → at-risk filter (D3 from research)** — explicitly deferred per REQUIREMENTS.
- **Extracting `calculate_mrr_cents/1` from `DefaultHandler` to a shared module** — would be required for an "MRR-at-risk" column in the at-risk table; explicitly deferred to v1.45+ per REQUIREMENTS.

</deferred>

---

*Phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-polish*
*Context gathered: 2026-05-27*
