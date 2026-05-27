# v1.44 Research Summary — Recovered-Revenue Dashboard Completion

**Project:** Accrue (Phoenix/Elixir payments + billing library)
**Milestone:** v1.44 — Recovered-Revenue Dashboard Completion
**Builds on:** Phase 143 (shipped, 4/4 verified) — `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` + `/billing/analytics/recovery` LiveView + MRR snapshotting on `dunning.recovered`/`dunning.exhausted`
**Researched:** 2026-05-27
**Confidence:** HIGH

> Detail lives in the sibling files. Read them when planning each phase:
> [`STACK.md`](./STACK.md) · [`FEATURES.md`](./FEATURES.md) · [`ARCHITECTURE.md`](./ARCHITECTURE.md) · [`PITFALLS.md`](./PITFALLS.md)

---

## Executive Summary

v1.44 is a *completion* milestone — not a green-field one. Phase 143 already shipped the foundation (MRR snapshotted into `dunning.recovered`/`dunning.exhausted`, `Accrue.Analytics.Dunning` Ecto aggregator, `/billing/analytics/recovery` admin LiveView with 2 KPI cards). v1.44 adds the **funnel viz**, **at-risk drill-down**, **time-window filters**, **per-campaign drill-down**, **public docs**, and **adopter-proof matrix row** that turn that foundation into a credible operator dashboard. The litmus test for in-scope vs out-of-scope (per the upstream assessment): *"Does this feature answer 'did the engine save me money?' or does it answer 'which segment performed how?'"* The first is v1.44; the second is BI-tool scope and out.

The recommended approach: **zero new runtime dependencies, zero new tables, four read-path public functions, two LiveView surfaces.** Everything aggregates the existing immutable `accrue_events` ledger via Ecto JSONB grouping (the pattern Phase 143 already proved). The funnel is HEEx + inline SVG — no JS chart library. The at-risk list is a plain `assign/3` table (10–500 rows, not a stream target). The per-campaign drill-down is a separate route, not a `push_patch`. The public API surface freezes in v1.44 — every new function is `@spec`'d, doc'd, and returns an **open-shape map** so v1.45 multi-channel additions extend keys non-breakingly.

The four critical risks: (1) **funnel double-counting** if naively counting events instead of distinct `(subject_id, campaign_anchor)` tuples — requires a Phase-143 forward-fix to snapshot the anchor onto recovered/exhausted events; (2) **stale at-risk** from projection lag — solved by using the ledger as tiebreaker over the schema anchor; (3) **legacy events have no `mrr_value_cents`** and the ledger is immutable (Postgres `BEFORE UPDATE/DELETE` trigger raises `SQLSTATE 45A01`) — the answer is a cutoff-date label, **not** a backfill rewrite; (4) **cross-currency summation** silently lies for EU/UK adopters — the return-shape widening must land **before 1.4.0 publish** or it's a semver lock-in. Stack-level wart: `RecoveryLive.format_minor/1` is currently USD-only `:erlang.float_to_binary` and bypasses CLDR — must be replaced by the existing `AccrueAdmin.Components.MoneyFormatter` (already wired to `:ex_money 5.24.2` / `Accrue.Cldr`).

---

## Key Findings

### Recommended Stack — Zero New Runtime Deps

The existing stack covers everything v1.44 needs. **No additions.** See [`STACK.md`](./STACK.md) for the full delta-table.

**Core (already present):**
- `:phoenix_live_view ~> 1.1` (1.1.30) — funnel HEEx, `handle_params/3`, optional `assign_async/3`
- Elixir stdlib `DateTime` — window math (no `:timex` needed)
- `:ex_money 5.24.2` + `Accrue.Cldr` (transitively via `:ex_cldr_numbers 2.38.1`) — money formatting via existing `AccrueAdmin.Components.MoneyFormatter`
- `:stream_data 1.3` + `Phoenix.LiveViewTest` + `:lazy_html` + `:mox 1.2` — all already in `mix.exs`

**Existing bug to fix in v1.44 (stack-adjacent):**
- `RecoveryLive.format_minor/1` does `"$" <> :erlang.float_to_binary(dollars, decimals: 2)` — USD-only, bypasses CLDR. Will format `1500` JPY as `$15.00`. Fix: route through `MoneyFormatter` using the `data["currency"]` already snapshotted on events. Belongs in funnel-phase or polish-phase. (See STACK.md §3 + Pitfall #8 in PITFALLS.md.)

**Rejected:** Chart.js / ApexCharts / Plotly / D3 (70KB–1.2MB JS for a 3-bar funnel — breaks JS-light posture); `:timex` (stdlib covers); `:number` Hex package (duplicates `:ex_money`); LiveView 1.1 `stream/4` for at-risk table (static page data, wrong tool); new analytics tables / TimescaleDB / `:explorer` (violates "no new tables" constraint).

### Feature Scope — F1-F6 Must, D1-D3 Should, 13-Item Anti-Feature List

Full surface in [`FEATURES.md`](./FEATURES.md). The litmus test from the upstream assessment: **"did the engine save me money?" (in-scope) vs "which segment performed how?" (BI-tool scope, out).**

**Table stakes — MUST ship in v1.44:**
- **F1.** 3-stage funnel: Entered → Recovered → Exhausted (counts only; per-step is deferred)
- **F2.** Time-window preset: 7d / 30d / 90d (30d default) — no custom-range picker, no all-time
- **F3.** At-risk subscriptions drill-down table (columns: customer, MRR-at-risk, days-in-campaign, current step, next step, last failure reason)
- **F4.** Public API expansion: `Accrue.Analytics.Dunning.{funnel, at_risk_subscriptions, campaign_timeline, recovery_rate}/1`
- **F5.** Public docs: `accrue/guides/analytics.md` + expanded `@moduledoc`
- **F6.** Adopter-proof matrix row + wiring test in `examples/accrue_host`

**Differentiators — SHIP if budget allows:**
- **D1.** Per-campaign drill-down (separate route `/billing/analytics/recovery/subscriptions/:id`) — Stripe parity, the transparency win
- **D2.** Currency-aware MRR aggregation (per-currency rows) — **must ship before 1.4.0 publish** to avoid semver lock-in (see Pitfall #4)
- **D3.** Funnel-stage click → filter at-risk table — D1 already covers the customer-investigation path; skip if tight

**Anti-features (explicit OUT-OF-SCOPE list, 13 items):** cohort analysis, failure-reason breakdown chart, MRR-by-plan, churn forecast / predictive ML, A/B test on dunning emails, custom-range date picker, CSV export, email/Slack alerts on rate drops, configurable dashboard layout, all-time/lifetime window, per-step funnel breakdown, per-customer-segment recovery rate, dashboard widget framework. **Each has a "what to do instead"** documented in FEATURES.md §"Anti-features".

### Architecture — All Decisions Already Locked

Full rationale in [`ARCHITECTURE.md`](./ARCHITECTURE.md). The locked decisions (do not relitigate):

| Decision | Choice |
|---|---|
| Funnel query shape | **ONE query** — `from(e in Event, where: e.type in ^types, group_by: e.type, select: ...)`. NOT `Task.async` per stage. |
| At-risk source | **Schema-side** via `dunning_campaign_started_at IS NOT NULL` — NOT event-derived (would lag the projection and re-implement what the schema already guarantees) |
| URL ↔ assigns | `handle_params/3` with `?window=30d` as URL SSOT — matches `subscriptions_live.ex` / `customers_live.ex` / `events_live.ex` codebase convention |
| Drill-down | **Separate route** at `/billing/analytics/recovery/subscriptions/:id` — back-button free, test isolation free, NOT `push_patch` + nested `live_component` |
| At-risk table | Plain `assign/3` (static page data, 10–500 rows) — NOT `Phoenix.LiveView.stream/4` (streams are for *mutating* lists; this list refreshes only on `handle_params`) |
| Write-path | **Zero additions** on the happy path — `dunning.campaign_started` / `dunning.step_sent` / `dunning.recovered` / `dunning.exhausted` are all already emitted. (Pitfall #1 adds one snapshot field; see below.) |
| Public API shape | **Open-shape maps** so v1.45 multi-channel additions (`:in_app_sent`, `:sms_sent`) extend keys without breaking exact-match pattern callers. Documented as "do not exact-match." |
| Cross-package boundary | `AccrueAdmin.Live.Analytics.*` calls ONLY `Accrue.Analytics.Dunning.*` — no `Ecto.Query`, no `Accrue.Billing.Subscription` alias, no `Accrue.Repo` from admin |

### Critical Pitfalls (PITFALLS.md §"Critical")

Full table in [`PITFALLS.md`](./PITFALLS.md). The four must-address-before-publish:

1. **Funnel double-counting** — Naive `count(type == "dunning.campaign_started")` double-counts when a subscription cycles dunning multiple times. **Fix:** snapshot `campaign_anchor = DateTime.to_iso8601(row.dunning_campaign_started_at)` onto recovered/exhausted events in `default_handler.ex:867,890` (a Phase 143 forward-fix), then funnel counts DISTINCT `(subject_id, campaign_anchor)` tuples per stage. Invariant: `recovered + exhausted + active ≤ entered` (stream_data property test).
2. **Stale at-risk** — Schema anchor lags Stripe's "paid" by up to 10s (webhook → Oban → projection). Fix: use the **ledger as tiebreaker** — exclude subscriptions whose *most recent* dunning-lifecycle event is `recovered`/`exhausted`. Five-line change. Surface "Last reconciled: 30s ago" copy.
3. **Legacy events have no `mrr_value_cents` AND ledger is immutable** — `accrue_events` has a `BEFORE UPDATE/DELETE` trigger raising `SQLSTATE '45A01'`. Backfill rewriting is **architecturally impossible**. The answer is a **cutoff-date label** (option 1 — recommended): default `since: snapshot_floor()` returning the v1.44 release date; UI badge "Showing data since 2026-05-27." Reject hand-rolled SQL backfill (defeats tamper-evidence). Compensating-event backfill deferred to v1.45. **This constrains the docs phase — the guide must explain the cutoff.**
4. **Cross-currency summation** — Phase 143's return shape `%{recovered_cents, lost_cents}` collapses USD+EUR+GBP cents into one integer rendered with `$`. **Must widen** to `%{recovered: [%{currency, cents}], lost: [%{currency, cents}]}` **before 1.4.0 publish** — locks in as semver. No FX conversion (out of scope; document hosts convert in BI tier).

**Moderate (PITFALLS.md §"Moderate"):**
- **#5 JSONB cast errors** — one row with `data->>'mrr_value_cents' = "5000"` (string) crashes the whole dashboard mount. Wrap aggregation in `CASE WHEN jsonb_typeof(...) = 'number' THEN ... ELSE 0 END`.
- **#7 Time-window math** — UTC-only labels (no localization). Default = calendar-current-month. Document: outcome timestamp (not campaign-start) determines window membership.
- **#8 Rename "Lost MRR" → "Exhausted MRR"** — Baremetrics framing lesson. Tiny copy change. Add KPI tooltips defining "Recovered MRR" / "Exhausted MRR" with worked example for yearly-plan customers.
- **#9 Public API freeze** — once 1.4.0 ships, every new analytics function signature is a semver commitment. `@spec` everything, mark "stable since 1.4.0" in CHANGELOG.

**Minor (PITFALLS.md §"Minor"):** #10 deterministic seeds via `Accrue.Clock` (not wall-clock); #11 NO expression index in v1.44 (ship migration template + threshold guide); #12 binary admin auth is fine for v1.44 (document escape hatch); #13 `subject_id` is `:string`, `subscription.id` is `:binary_id` — provide `at_risk_with_subscriptions/1` helper that encapsulates the cast.

---

## Implications for Roadmap

**Build-order principle:** compute → state → UI → navigation. Every phase's must-have is testable at the `mix test` level *before* the LiveView wrapper goes in.

### Cross-cutting pre-work (MUST land before any phase)

- **Decide cross-currency API shape** (per-currency facets vs single-currency collapse). PITFALLS #4 says this MUST land in v1.44, not v1.45 — it's a semver lock-in once 1.4.0 publishes. Recommendation: per-currency lists; defaults render as single row for single-currency adopters (no UI regression).
- **Fix `RecoveryLive.format_minor/1`** to use `AccrueAdmin.Components.MoneyFormatter`. Fits into Phase 144 funnel work or a polish slot.

### Phase 144: Funnel query + viz + `mrr_value_cents` anchor retrofit
**Rationale:** De-risks the JSONB single-`group_by` pattern at scale + handles the funnel-double-counting forward-fix (Pitfall #1) before UI navigation depends on it.
**Delivers:** `Accrue.Analytics.Dunning.funnel/1` + `FunnelChart` HEEx component + funnel section on `RecoveryLive` + `campaign_anchor` snapshot retrofit in `default_handler.ex` + JSONB `CASE`-guard (Pitfall #5) + "Lost" → "Exhausted" rename (Pitfall #8).
**Pitfalls owned:** #1 (DISTINCT funnel), #5 (CASE-guard), #8 (rename + tooltips).

### Phase 145: Time-window URL plumbing + window selector
**Rationale:** Smallest navigation change; validates `handle_params/3` threading `:since`/`:until` through both `recovered_vs_lost_mrr/1` AND `funnel/1`. Once shipped, future analytics functions get window support free.
**Delivers:** `?window=7d|30d|90d` URL param + assigns + window selector UI + UTC labels + outcome-timestamp attribution doc.
**Pitfalls owned:** #7 (timezone / DST / rolling-vs-calendar).

### Phase 146: At-risk query + at-risk table
**Rationale:** Simplest of the new queries (one `where: not is_nil(...)` clause). Validates cross-package boundary discipline (LiveView calls only `Accrue.Analytics.Dunning`).
**Delivers:** `Accrue.Billing.Query.in_active_dunning_campaign/1` (new query composer) + `Accrue.Analytics.Dunning.at_risk_subscriptions/1` + at-risk section on `RecoveryLive` + ledger-as-tiebreaker (Pitfall #2) + `subject_id` cast helper (Pitfall #13).
**Pitfalls owned:** #2 (stale projection), #13 (id type mismatch). Note: streams (Pitfall #6 from PITFALLS.md) are intentionally NOT adopted here — see Architecture decision row 8. `DataTable` LiveComponent is bypassed in favor of plain `assign` (ARCHITECTURE.md §F3 boundary decision).

### Phase 147: Per-subscription drill-down route + `CampaignLive`
**Rationale:** Depends on at-risk table (row click → drill-down). Backend trivially done — reuses `Accrue.Events.timeline_for/3` already shipped. This phase is mostly LiveView + routing.
**Delivers:** `/billing/analytics/recovery/subscriptions/:id` route + `CampaignLive` + per-subscription timeline (campaign_started → step_sent ×N → recovered/exhausted) + linked invoice/payment context.

### Phase 148: Public docs + adopter-proof + cutoff-date label
**Rationale:** Lock the public API in `guides/analytics.md` AFTER all functions are stable. Seed mixed event data in `examples/accrue_host`. Add adopter-proof matrix row.
**Delivers:** `accrue/guides/analytics.md` (~150-300 LOC), expanded `@moduledoc`, `mix.exs` ExDoc nav entry, cutoff-date label + `:dunning_mrr_snapshot_floor` config + ADR-v144-001, perf-threshold guide section (Pitfall #11), admin-role limitation doc + host-app escape-hatch sample (Pitfall #12), `examples/accrue_host` seeds with `Accrue.Clock`-relative timestamps (Pitfall #10), adopter-proof matrix row, `examples/accrue_host/test/.../recovery_analytics_test.exs` deterministic-clock wiring test.
**Pitfalls owned:** #3 (cutoff label), #4 (per-currency in API), #9 (public-API freeze), #10 (clock-based seeds), #11 (perf threshold guide), #12 (auth-role doc).

### Phase 149 (optional): Telemetry + sparkline
**Rationale:** Polish. Skippable without breaking v1.44 scope.
**Delivers:** `[:accrue, :ops, :analytics_dashboard_loaded]` emission via `Accrue.Telemetry.Ops.emit/3` + optional count-based sparkline via direct `Accrue.Events.bucket_by/2` reuse.

### Research Flags

| Phase | Needs deeper research? | Why |
|---|---|---|
| 144 (funnel + anchor retrofit) | **MAYBE** — light research-phase to confirm anchor snapshot doesn't break Phase 143's existing emission-boundary test coverage gap | Touches `default_handler.ex` write path; existing test coverage gap at MRR-snapshot boundary noted in 143-VERIFICATION |
| 145 (time-window) | **NO** — standard `handle_params/3` codebase convention | 5+ existing admin LiveViews already use this exact pattern |
| 146 (at-risk) | **NO** — schema query is one `where:`; LiveView pattern is plain `assign/3` | Established codebase pattern |
| 147 (drill-down) | **NO** — reuses existing `Events.timeline_for/3` + sibling-route convention | Pure additive route + LiveView |
| 148 (docs + adopter-proof) | **MAYBE** — cutoff-date semantics need ADR-quality writing; cross-currency API shape is the semver risk surface | This is where 1.4.0 commits ship |
| 149 (telemetry, optional) | **NO** — `Accrue.Telemetry.Ops.emit/3` is canonical and used everywhere | Boilerplate |

### Decisions to Escalate to discuss-phase

Before phase planning begins, these need an explicit call (recommendations in parens):

1. **Funnel counts events or unique subscriptions per stage?** (Rec: **events** for v1.44 — matches Stripe Dashboard framing, simpler to explain. `funnel_unique_subjects/1` is a v1.45 additive addition if demanded.)
2. **"Last failure reason" column in at-risk table — source?** Three options: (a) public `last_failure_for_subscription/1` query (more code), (b) enrich `dunning.campaign_started` event payload with the triggering failure (one-line addition in `default_handler.ex:1237`; pre-v1.44 campaigns show "—"), (c) drop the column. (Rec: **(b)** — cheapest, no public-query surface, "—" for historical is honest.)
3. **Sparkline in v1.44?** (Rec: **only if reusable via `Accrue.Events.bucket_by/2` directly** — count-based, no new JSONB-sum helper. If sum-based is wanted, defer to v1.45 alongside MRR-at-risk-per-row so the new helper has two callers.)
4. **At-risk MRR-at-risk column** requires promoting `calculate_mrr_cents/1` out of `DefaultHandler` (currently `defp`) into a shared module. (Rec: **defer to v1.45** — keep v1.44 at-risk columns to past-due-age + customer identity. ARCHITECTURE.md §"Pattern 2" agrees.)

### Phase Ordering Rationale

- **Compute before UI before navigation.** Every phase has a `mix test` testable backend before the LiveView lands.
- **Funnel first (144)** because it surfaces the Pitfall #1 anchor-retrofit which propagates to every other count.
- **Window second (145)** because once `handle_params/3` threads `:since`/`:until` through, every subsequent query inherits window support free.
- **At-risk before drill-down (146 → 147)** because the drill-down's primary entry path is a row-click on the at-risk table.
- **Docs last (148)** because the public API surface should NOT churn alongside design pivots. Cutoff-date and per-currency API shape land here precisely because they're the semver-locked surfaces.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | Zero new runtime deps; every integration point verified in `mix.exs` / `mix.lock` |
| Features | **HIGH** | Foundation code grounded; competitor parity inferred but the litmus test (FEATURES.md scope contract) is decisive |
| Architecture | **HIGH** | Every integration seam is named-and-verified against the existing Phase 143 codebase; build order is dependency-orderable |
| Pitfalls | **HIGH** | All 4 critical pitfalls grounded in source files (migration trigger, emission sites, schema columns); LOW-confidence items (Stripe/Baremetrics UI screenshots, perf-index threshold) are flagged honestly in PITFALLS.md §"What I Could Not Verify" |

**Overall confidence:** HIGH.

### Gaps to Address During Planning

- **Funnel double-counting forward-fix to Phase 143** — the `campaign_anchor` snapshot on recovered/exhausted events is a Phase 143 write-path retrofit, not a v1.44 net-new feature. Phase 144 plan must explicitly include this as a sub-step or it cascades.
- **Cross-currency API shape decision** — must be made before 1.4.0 publish. Surfaced as a Phase 148 deliverable but the *decision* should land in phase planning, not phase execution.
- **`mix phx.routes`-based verify commands** — Phase 143 verification noted `accrue_admin/router.ex` is a macro-only router-builder; any v1.44 plan that tries `mix phx.routes | grep ...` will hit the same wall. Use static + integration verification (Phase 143's pattern).
- **Emission-boundary test coverage gap** — Phase 143 verified `mrr_value_cents` flows end-to-end via the analytics test but has no direct assertion at the `default_handler.ex` `Events.record` call site. Phase 144's anchor retrofit is a natural place to add this hardening test.
- **Perf-index threshold benchmark** (Pitfall #11) — "100k events" is a rule-of-thumb. Phase 148 docs phase should run an `EXPLAIN ANALYZE` on the demo host to anchor the guide's numbers with real data, not training-set generalizations.

---

## Sources

### Research files (all HIGH confidence — codebase-grounded)

- `.planning/research/STACK.md` — zero-new-deps justification, alternatives-rejected table, version compat matrix, JS chart library evaluation
- `.planning/research/FEATURES.md` — F1-F6 table stakes, D1-D3 differentiators, 13-item anti-feature list, scope litmus test, funnel-granularity decision, drill-down content spec, build-order graph
- `.planning/research/ARCHITECTURE.md` — 12 locked decisions, system diagram, file-change map (`accrue` + `accrue_admin` + `examples/accrue_host`), 5 reusable patterns, 6 anti-patterns, public-API freeze, telemetry surface, scalability ceiling, build order
- `.planning/research/PITFALLS.md` — 4 critical / 5 moderate / 4 minor pitfalls; phase-to-pitfall map; deferred-to-v1.45 list; honest-gaps section

### Upstream context (HIGH confidence)

- `.planning/threads/v1.44-NEXT-STEP-ASSESSMENT.md` — milestone scope, "done enough" definition, maintainer takeaway ("Build the dashboard, then stop"), design constraint (no new deps, no new tables)
- `.planning/phases/143/143-VERIFICATION.md` — Phase 143 4/4 verified, foundation shipped, known gaps flagged
- `.planning/phases/143/143-RESEARCH.md` — temporal-data-leakage decision, locked constraints inherited by v1.44

### Codebase source-of-truth (HIGH confidence — referenced throughout)

- `accrue/lib/accrue/analytics/dunning.ex` (Phase 143 foundation, 73 LOC — extends to ~250 LOC)
- `accrue/lib/accrue/webhook/default_handler.ex` (emission sites `:1237` / `:805` / `:886`; `calculate_mrr_cents/1` at `:1896`)
- `accrue/lib/accrue/billing/{dunning,query,subscription}.ex` (existing query composers + predicates)
- `accrue/lib/accrue/events.ex` (`record/1`, `record_multi/3`, `timeline_for/3`, `bucket_by/2`)
- `accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` (immutability trigger `SQLSTATE '45A01'`)
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (extension target)
- `accrue_admin/lib/accrue_admin/{router.ex, components/*}` (`AppShell`, `Breadcrumbs`, `KpiCard`, `MoneyFormatter`, `DataTable`)
- `examples/accrue_host/docs/adoption-proof-matrix.md` (matrix template)

---

*Research synthesis: 2026-05-27. Ready for roadmap.*
