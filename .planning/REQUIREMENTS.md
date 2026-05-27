# Requirements: Accrue

## Milestone: v1.44 — Recovered-Revenue Dashboard Completion

Current focus: **Polish & Adopter ROI Proof**. Build on Phase 143's standalone foundation (`Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` + `/billing/analytics/recovery` LiveView with 2 KPI cards + MRR snapshotting in dunning lifecycle events) to ship the funnel, at-risk drill-down, time-window filters, per-campaign drill-down, public docs, and adopter-proof matrix row that prove the v1.40 dunning engine's ROI to adopters.

**Design constraint (carried from Phase 143):** Aggregate the existing `accrue_events` ledger only — no new analytical tables, no new dependencies (no TimescaleDB, no rollup workers). Zero new runtime mix deps.

**Build-order principle:** compute → state → UI → navigation. Every requirement's must-have is testable at the `mix test` level before the LiveView wrapper goes in.

### Public API & Core Math (DAN)

- [x] **DAN-01** — Funnel public API.
  - `Accrue.Analytics.Dunning.funnel/1` returns `%{entered: N, recovered: N, exhausted: N, active: N}` over a window.
  - Counts DISTINCT `(subject_id, campaign_anchor)` tuples per stage to prevent double-counting when a subscription cycles dunning multiple times.
  - Single `from(e in Event, where: e.type in ^types, group_by: e.type, select: ...)` Ecto query — not `Task.async` per stage.
  - `@spec` declared; `@moduledoc` notes "stable since 1.4.0" + "do not exact-match the return map (open shape)".
  - Property test: `recovered + exhausted + active ≤ entered` (stream_data).

- [ ] **DAN-02** — Campaign-anchor snapshot retrofit (Phase 143 forward-fix).
  - Snapshot `campaign_anchor = DateTime.to_iso8601(subscription.dunning_campaign_started_at)` onto `dunning.recovered` (`default_handler.ex:~880`) and `dunning.exhausted` (`default_handler.ex:~805`) event payloads, alongside existing `mrr_value_cents` + `currency`.
  - Backward compatible: legacy events without `campaign_anchor` fall through funnel de-dup as "earliest known" (single-row stage attribution).
  - Direct unit assertion at the `Events.record/record_multi` call site (closes the Phase 143 emission-boundary test coverage gap).

- [ ] **DAN-03** — At-risk subscriptions query.
  - `Accrue.Billing.Query.in_active_dunning_campaign/1` — new query composer in `accrue/lib/accrue/billing/query.ex`, sibling to `dunning_sweep_candidates/2`. Uses schema-side `dunning_campaign_started_at IS NOT NULL` as the source of truth.
  - `Accrue.Analytics.Dunning.at_risk_subscriptions/1` — public wrapper applying the **ledger-as-tiebreaker** filter (exclude subscriptions whose most recent dunning-lifecycle event is `recovered` or `exhausted`) to defeat projection lag.
  - Returns subscriptions with: `subject_id`, `customer_id`, `dunning_campaign_started_at`, `days_in_campaign`, current step (computed from `dunning.step_sent` event count), next-step ETA (derived from active Oban job timing). "Last failure reason" — see DAN-04.

- [ ] **DAN-04** — Last-failure-reason via event-payload enrichment.
  - One-line enrichment of `dunning.campaign_started` event payload in `default_handler.ex:~1237` to carry the triggering invoice's `failure_message` (or equivalent canonical field).
  - Surfaced by `at_risk_subscriptions/1` from the most recent `campaign_started` event per active campaign.
  - Pre-v1.44 campaigns show "—" (honest default; no public-query surface needed).

- [ ] **DAN-05** — Campaign timeline public API.
  - `Accrue.Analytics.Dunning.campaign_timeline(subject_id, opts \\ [])` — thin wrapper around the existing `Accrue.Events.timeline_for/3` filtered to `dunning.*` event types, ordered chronologically.
  - Powers Phase 147's per-subscription drill-down view.

- [ ] **DAN-06** — Recovery-rate public API.
  - `Accrue.Analytics.Dunning.recovery_rate/1` returns `%{rate: 0.0..1.0, recovered: N, total_concluded: N}` over a window.
  - Computed as `recovered / (recovered + exhausted)`; returns `%{rate: nil, ...}` when total is zero (no division-by-zero in templates).

- [ ] **DAN-07** — Cross-currency aggregation widening (SEMVER LOCK-IN — must ship before 1.4.0 publish).
  - Widen `recovered_vs_lost_mrr/1` return shape from `%{recovered_cents: int, lost_cents: int}` to `%{recovered: [%{currency: "usd", cents: N}, ...], lost: [...]}`.
  - No FX conversion — host apps convert in their BI tier if needed.
  - Updated `RecoveryLive` renders one card per currency (single currency = same UX as today).
  - CHANGELOG entry flagged "BREAKING for pre-1.4.0 callers".

- [x] **DAN-08** — JSONB cast safety.
  - All JSONB-fragment aggregations wrap the `::integer` cast in `CASE WHEN jsonb_typeof((?->>'mrr_value_cents')::jsonb) = 'number' THEN ((?->>'mrr_value_cents')::integer) ELSE 0 END` (or equivalent safe-cast).
  - Single malformed row in `accrue_events` does NOT crash the dashboard mount.
  - Regression test: insert a `dunning.recovered` event with `"mrr_value_cents": "5000"` (string-typed) and assert `recovered_vs_lost_mrr/1` returns successfully (zero contribution from the bad row).

### Admin UI Recovery Dashboard (DAN)

- [ ] **DAN-09** — Funnel visualization on `/billing/analytics/recovery`.
  - `AccrueAdmin.Components.FunnelChart` HEEx component with inline SVG (no JS chart library).
  - Three stacked stages with proportional widths from `funnel/1` result.
  - Stage labels + counts + percentage-of-entered.
  - Tooltips define each stage; "Exhausted" replaces previously-shipped "Lost MRR" copy.

- [ ] **DAN-10** — Time-window URL plumbing + selector.
  - `?window=7d|30d|90d` URL parameter threaded via `handle_params/3`; default `30d`.
  - Window selector UI (3 preset buttons; no custom-range picker).
  - URL is single source of truth — sharing a URL preserves the window.
  - All `Accrue.Analytics.Dunning.*` calls thread `:since` / `:until` derived from the window.
  - UTC-only labels; document outcome-event-timestamp attribution in `analytics.md`.

- [ ] **DAN-11** — At-risk subscriptions table on dashboard.
  - Renders `at_risk_subscriptions/1` result inline below the funnel.
  - Plain `assign/3` (NOT `Phoenix.LiveView.stream/4` — static page data, refresh on `handle_params` only).
  - Columns: customer (with link), days-in-campaign, current step, next-step ETA, last failure reason.
  - Cross-package boundary: LiveView calls ONLY `Accrue.Analytics.Dunning.*` — no `Ecto.Query`, no `Accrue.Repo`, no `Accrue.Billing.Subscription` alias.

- [ ] **DAN-12** — Per-subscription drill-down route + view.
  - New route `/billing/analytics/recovery/subscriptions/:id` inside the existing `live_session :accrue_admin` block (admin-auth inherited).
  - `AccrueAdmin.Live.Analytics.CampaignLive` renders `campaign_timeline/1` as a vertical timeline: `dunning.campaign_started` → `dunning.step_sent` ×N → `dunning.recovered` | `dunning.exhausted`.
  - Linked invoice and payment-method context inline.
  - Row-click affordance from DAN-11 at-risk table.

- [ ] **DAN-13** — MoneyFormatter polish (fix USD-only bug).
  - Replace `RecoveryLive.format_minor/1` (currently `"$" <> :erlang.float_to_binary(...)`, USD-only) with `AccrueAdmin.Components.MoneyFormatter` calls using the event payload's `currency` field.
  - Existing 2 KPI cards + new funnel + new at-risk + new drill-down all render correctly for JPY, EUR, GBP, USD.
  - Regression test: seed a `dunning.recovered` event with `"currency": "jpy"` and assert rendered output uses `¥` (or CLDR's locale-correct rendering), not `$`.

### Public Docs (DAN)

- [ ] **DAN-14** — `accrue/guides/analytics.md`.
  - Public-API surface: `Accrue.Analytics.Dunning.{recovered_vs_lost_mrr, funnel, at_risk_subscriptions, campaign_timeline, recovery_rate}/1` — each with example, `@spec`, return-shape contract.
  - Cutoff-date semantics: explains why legacy events without `mrr_value_cents` are excluded; `:dunning_mrr_snapshot_floor` config; "Showing data since YYYY-MM-DD" UI badge.
  - Window semantics: outcome-timestamp attribution, UTC-only labels, no custom range.
  - Per-currency contract: each currency reported separately; no FX conversion in core.
  - Perf threshold guide: when to add an expression index on `(data->>'mrr_value_cents')`; recommended threshold ~100k events (rule-of-thumb, noted as such).
  - Admin-auth limitation + host-app escape-hatch sample for granular billing-readonly roles.
  - Open-shape map contract: "do not exact-match these maps; future versions add keys."
  - Added to `accrue/mix.exs` ExDoc nav.

- [ ] **DAN-15** — `@moduledoc` expansion on `Accrue.Analytics.Dunning`.
  - One-paragraph summary + `@since "1.4.0"` markers on each public function.
  - Cross-link to `guides/analytics.md`.
  - Picked up by `verify_package_docs.sh` (add the analytics guide pointer needle).

### Adopter Proof (DAN)

- [ ] **DAN-16** — Adopter-proof matrix row + example-host seed wiring.
  - Add row to `examples/accrue_host/docs/adoption-proof-matrix.md`: "Recovered Revenue Dashboard" → links to seed script + screenshot + LiveView path.
  - Seed `examples/accrue_host` with deterministic-clock dunning events spanning multiple windows (7d / 30d / 90d) so the demo dashboard renders non-empty out of the box.
  - Use `Accrue.Clock` (NOT wall-clock) for relative timestamps so the seed is reproducible across test runs.
  - `examples/accrue_host/test/.../recovery_analytics_test.exs` — wiring test asserting the dashboard mounts and renders non-empty funnel + at-risk + drill-down against the seed data.

### Out of Scope (explicit non-goals for v1.44)

- **Per-step funnel breakdown** — deferred to v1.45+ if demanded (would require per-step MRR snapshotting; the assessment's "Frame positively" lesson says start simple).
- **Cohort analysis / MRR-by-plan / segment-recovery-rate breakdown** — BI-tool scope, parked per the "build the dashboard, then stop" maintainer takeaway.
- **Churn forecast / predictive ML** — explicitly out-of-scope; risks accounting-territory drift.
- **A/B testing dunning emails** — out-of-scope; host-owned experimentation.
- **Custom-range date picker / all-time window** — anti-feature per the Spark/Stripe simplicity lesson.
- **CSV export / Slack/email alerts on rate drops** — anti-feature; hosts use telemetry → their BI stack.
- **Configurable dashboard layout / widget framework** — anti-feature; v1.44 is a fixed dashboard.
- **Real-time PubSub-driven dashboard refresh** — out-of-scope v1.44; manual refresh only.
- **MRR-at-risk column on at-risk table** — deferred to v1.45 (requires extracting `calculate_mrr_cents/1` out of `DefaultHandler` to a shared module; out-of-band scope for v1.44).
- **Funnel-stage click → at-risk filter (D3 from research)** — deferred; DAN-12 drill-down already covers the customer-investigation path.
- **Sparkline on KPI cards** — deferred unless trivially reusable via `Accrue.Events.bucket_by/2` (count-based only; sum-based is a v1.45 candidate).
- **`opentelemetry`-bridged dashboard-load span** — out-of-scope (deferred to optional polish if budget allows; not blocking v1.44 ship).
- **Backfill of pre-v1.44 events without `mrr_value_cents`** — architecturally impossible (`accrue_events` immutability trigger `SQLSTATE 45A01`); answered by the cutoff-date label in DAN-14.
- **Granular `billing-analytics-read` admin role** — out-of-scope; documented escape-hatch in DAN-14 for host apps that need it.

### Standing non-goals (carried across milestones, reaffirmed at v1.44)

- **FIN-03** (app-owned finance exports / revenue recognition / accounting) — explicit non-goal; Accrue is a billing/subscription library, not an accounting system.
- **MRR/ARR analytics product** — v1.44 surfaces recovered-revenue analytics specifically; broad MRR/ARR forecasting/cohort dashboards remain BI-tier work.
- **MoR processors** (Paddle / Lemon Squeezy) — explicit non-goal.
- **Hyperwallet marketplace parity** — explicit non-goal.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DAN-01 | Phase 144 | Complete |
| DAN-02 | Phase 144 | Pending |
| DAN-03 | Phase 146 | Pending |
| DAN-04 | Phase 146 | Pending |
| DAN-05 | Phase 147 | Pending |
| DAN-06 | Phase 148 | Pending |
| DAN-07 | Phase 148 | Pending |
| DAN-08 | Phase 144 | Complete |
| DAN-09 | Phase 144 | Pending |
| DAN-10 | Phase 145 | Pending |
| DAN-11 | Phase 146 | Pending |
| DAN-12 | Phase 147 | Pending |
| DAN-13 | Phase 144 | Pending |
| DAN-14 | Phase 148 | Pending |
| DAN-15 | Phase 148 | Pending |
| DAN-16 | Phase 148 | Pending |

**Phase mapping summary:**

- Phase 144 (5 reqs): DAN-01, DAN-02, DAN-08, DAN-09, DAN-13 — funnel API + viz + anchor retrofit + JSONB safety + money formatter
- Phase 145 (1 req): DAN-10 — time-window URL plumbing + selector
- Phase 146 (3 reqs): DAN-03, DAN-04, DAN-11 — at-risk query + failure-reason enrichment + at-risk table
- Phase 147 (2 reqs): DAN-05, DAN-12 — campaign_timeline API + drill-down route
- Phase 148 (5 reqs): DAN-06, DAN-07, DAN-14, DAN-15, DAN-16 — recovery_rate + currency widening + docs + adopter-proof

**Coverage:** 16/16 v1.44 requirements mapped (100%); 0 orphans; 0 duplicates.
