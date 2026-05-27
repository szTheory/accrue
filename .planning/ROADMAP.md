# Roadmap — v1.44 Recovered-Revenue Dashboard Completion

**Milestone:** v1.44 — Recovered-Revenue Dashboard Completion
**Builds on:** Phase 143 (standalone, verified 2026-05-27) — `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` + `/billing/analytics/recovery` LiveView + MRR snapshotting on `dunning.recovered` / `dunning.exhausted`.
**Granularity:** standard
**Coverage:** 16/16 v1.44 requirements (DAN-01..DAN-16) mapped — 100%
**Build-order principle (locked):** compute → state → UI → navigation. Every phase's must-have is testable at the `mix test` level before the LiveView wrapper goes in.
**Phase numbering:** 144–148 (continues from standalone Phase 143). v1.43 ended at Phase 142; Phase 143 was a standalone post-v1.43 phase and is NOT part of v1.44.

## Phases

- [x] **Phase 144: Funnel query + viz + campaign-anchor retrofit + money formatter polish** — DISTINCT-tuple funnel API, `FunnelChart` HEEx component, Phase 143 forward-fix snapshotting `campaign_anchor` onto recovered/exhausted events, JSONB cast safety, and CLDR-correct money rendering across the dashboard. (completed 2026-05-27)
- [x] **Phase 145: Time-window URL plumbing + window selector** — `?window=7d|30d|90d` URL parameter, three-button selector, threaded `:since`/`:until` through funnel + recovered-vs-lost callers, UTC-only labels. (completed 2026-05-27)
- [ ] **Phase 146: At-risk query + at-risk table + last-failure enrichment** — `at_risk_subscriptions/1` public API with ledger-as-tiebreaker against projection lag, `campaign_started` event payload enriched with last failure reason, at-risk table rendered inline below the funnel.
- [ ] **Phase 147: Per-subscription drill-down route + CampaignLive** — `campaign_timeline/2` public API, `/billing/analytics/recovery/subscriptions/:id` drill-down route inside the admin live_session, vertical timeline rendering with linked invoice/payment context.
- [ ] **Phase 148: Cross-currency widening + recovery-rate API + public docs + adopter-proof** — BREAKING `recovered_vs_lost_mrr/1` shape widening to per-currency lists (pre-publish lock-in), `recovery_rate/1` public API, `guides/analytics.md` + expanded `@moduledoc`, adopter-proof matrix row + deterministic-clock seed wiring in `examples/accrue_host`.

## Phase Details

### Phase 144: Funnel query + viz + campaign-anchor retrofit + money formatter polish

**Goal:** Operators see a credible 3-stage dunning funnel (Entered → Recovered → Exhausted) rendered as inline-SVG below the existing KPI cards on `/billing/analytics/recovery`, with no double-counting under cycled-dunning subscriptions, no dashboard crash from a single malformed JSONB row, and money labels that render correctly for any currency (JPY, EUR, GBP, USD).
**Depends on:** Phase 143 (foundation — shipped)
**Requirements:** DAN-01, DAN-02, DAN-08, DAN-09, DAN-13
**Success Criteria** (what must be TRUE):

  1. Operator visits `/billing/analytics/recovery` and sees a 3-stage funnel (Entered Dunning → Recovered → Exhausted) rendered with stage labels, absolute counts, and percentage-of-entered annotations below the existing KPI cards.
  2. A subscription that cycles dunning three times (entered → recovered → entered → exhausted → entered → active) appears as `entered: 3, recovered: 1, exhausted: 1, active: 1` in the funnel — DISTINCT `(subject_id, campaign_anchor)` tuples per stage, NOT raw event counts. Property test holds: `recovered + exhausted + active ≤ entered`.
  3. Inserting a single `dunning.recovered` event with a string-typed `"mrr_value_cents": "5000"` does NOT crash the dashboard mount — the malformed row contributes 0 and the page renders.
  4. The two existing KPI cards plus the new funnel render currency-correct labels: JPY shows `¥` (or CLDR locale-correct symbol), USD shows `$`, EUR shows `€` — no more USD-only `:erlang.float_to_binary` rendering.
  5. The funnel renames the previously-shipped "Lost MRR" copy to "Exhausted MRR" with a tooltip defining the term and a worked example for yearly-plan customers.

**Plans:** 4/4 plans complete
Plans:
**Wave 1**

- [x] 144-01-PLAN.md — Analytics safe-cast + funnel/1 API + property test (DAN-01, DAN-08)
- [x] 144-02-PLAN.md — Campaign-anchor retrofit on dunning.recovered + dunning.exhausted emission (DAN-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 144-03-PLAN.md — FunnelChart Phoenix.Component + .ax-funnel-* CSS + component unit tests (DAN-09)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 144-04-PLAN.md — RecoveryLive wiring: funnel call + MoneyFormatter swap + Exhausted-MRR rename + JPY regression (DAN-09, DAN-13)

**UI hint:** yes
**Note:** This phase owns the Phase 143 forward-fix to the write path — `campaign_anchor` is snapshotted onto `dunning.recovered` (`default_handler.ex:~880`) and `dunning.exhausted` (`default_handler.ex:~805`) event payloads. Required for Pitfall #1 (funnel double-counting) prevention.

### Phase 145: Time-window URL plumbing + window selector

**Goal:** Operators can filter every analytics metric on `/billing/analytics/recovery` by 7d / 30d / 90d window — via either the URL (`?window=30d`, shareable in Slack) or the three-button preset selector — with the URL as single source of truth and all UTC-labeled.
**Depends on:** Phase 144
**Requirements:** DAN-10
**Success Criteria** (what must be TRUE):

  1. Operator clicks the "7d" / "30d" / "90d" preset button and the funnel + KPI cards reload to reflect that window, with the URL updating to `?window=7d` / `30d` / `90d` (browser back-button restores the prior window).
  2. Operator pastes `https://.../billing/analytics/recovery?window=7d` into a fresh tab and lands directly on the 7-day view — URL is the SSOT, default (no param) is 30d.
  3. Every `Accrue.Analytics.Dunning.*` call from the LiveView threads `:since` / `:until` derived from the active window — funnel counts, KPI sums, and any future analytics function automatically inherit window support.
  4. Time-range UI labels show "UTC" and the docs (`analytics.md`) call out that funnel attribution uses the outcome event timestamp (not the campaign-start timestamp).

**Plans:** 1/1 plans complete
Plans:
**Wave 1**

- [x] 145-01-PLAN.md — WindowSelector component + RecoveryLive handle_params refactor + tests (DAN-10)

**UI hint:** yes

### Phase 146: At-risk query + at-risk table + last-failure enrichment

**Goal:** Operators see the live "who is currently in dunning right now" list inline on `/billing/analytics/recovery` — each row showing customer, days in campaign, current step, next-step ETA, and last-failure reason — without false positives from subscriptions that just recovered but haven't propagated to the projection yet.
**Depends on:** Phase 145
**Requirements:** DAN-03, DAN-04, DAN-11
**Success Criteria** (what must be TRUE):

  1. Operator visits `/billing/analytics/recovery` and sees an "At Risk Subscriptions" table inline below the funnel — columns: customer (linked to customer detail), days-in-campaign, current step, next-step ETA, last failure reason.
  2. A subscription whose `dunning.recovered` event was just written but whose `dunning_campaign_started_at` column hasn't been nilled yet (projection lag race) does NOT appear in the at-risk list — the ledger is the tiebreaker against the schema anchor.
  3. Post-v1.44 active campaigns surface the triggering invoice's `failure_message` in the "Last failure reason" column; pre-v1.44 campaigns show "—" (honest default — no public-query surface).
  4. The LiveView code touching the at-risk table calls ONLY `Accrue.Analytics.Dunning.*` functions — no `Ecto.Query` import, no `Accrue.Repo` call, no `Accrue.Billing.Subscription` alias from `accrue_admin`.

**Plans:** 2/3 plans executed
Plans:
**Wave 1**

- [x] 146-01-PLAN.md — emit_campaign_started/2 invoice_id enrichment + in_active_dunning_campaign/1 query composer (DAN-03, DAN-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 146-02-PLAN.md — at_risk_subscriptions/1 compound query + apply_campaign_window/2 + test suite (DAN-03, DAN-04)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 146-03-PLAN.md — AtRiskTable component + CSS + RecoveryLive wiring + cross-package boundary test (DAN-11)

**UI hint:** yes

### Phase 147: Per-subscription drill-down route + CampaignLive

**Goal:** Operators click any row in the at-risk table and land on a per-subscription drill-down view showing the full dunning timeline (campaign_started → step_sent ×N → recovered | exhausted) with linked invoice and payment-method context — the "investigate this one customer" path.
**Depends on:** Phase 146
**Requirements:** DAN-05, DAN-12
**Success Criteria** (what must be TRUE):

  1. Operator clicks a row in the at-risk table and the browser navigates to `/billing/analytics/recovery/subscriptions/:id` — a shareable URL inside the existing `live_session :accrue_admin` block (admin auth inherited from Phase 143).
  2. The drill-down view renders a vertical timeline of every `dunning.*` event for that subscription in chronological order: `dunning.campaign_started` first, then `dunning.step_sent` (one per cadence step), terminating at `dunning.recovered` or `dunning.exhausted`.
  3. Each timeline row shows the linked invoice (status + amount) and payment-method context inline — operators can diagnose "step 2 sent → retry succeeded for $59" as a single narrative.
  4. `Accrue.Analytics.Dunning.campaign_timeline/2` is a public-API thin wrapper around `Accrue.Events.timeline_for/3` filtered to `dunning.*` types and ordered chronologically — re-usable by adopter dashboards.

**Plans:** TBD
**UI hint:** yes

### Phase 148: Cross-currency widening + recovery-rate API + public docs + adopter-proof

**Goal:** The v1.44 public API surface (`Accrue.Analytics.Dunning.{recovered_vs_lost_mrr, funnel, at_risk_subscriptions, campaign_timeline, recovery_rate}/1`) freezes for the next Hex publish — currency-correct, documented, adopter-provable end-to-end against deterministic-clock seed data in `examples/accrue_host`.
**Depends on:** Phase 147
**Requirements:** DAN-06, DAN-07, DAN-14, DAN-15, DAN-16
**Success Criteria** (what must be TRUE):

  1. `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` returns `%{recovered: [%{currency: "usd", cents: N}, ...], lost: [...]}` (per-currency lists, no FX conversion) — a multi-currency adopter sees one KPI card per currency on the dashboard; single-currency adopters see no UX change. CHANGELOG entry flags "BREAKING for pre-1.4.0 callers".
  2. `Accrue.Analytics.Dunning.recovery_rate/1` returns `%{rate: 0.0..1.0 | nil, recovered: N, total_concluded: N}` — adopters can compute "recovered / (recovered + exhausted)" without re-deriving the SQL, and templates do not divide by zero.
  3. An adopter visits `accrue/guides/analytics.md` and finds: every public-API function with `@spec`, example, and return-shape contract; cutoff-date semantics with the "Showing data since YYYY-MM-DD" UI badge explanation; per-currency contract ("no FX conversion in core"); perf-threshold guide (when to add the `(data->>'mrr_value_cents')` expression index, ~100k events rule-of-thumb); admin-auth limitation + host-app escape-hatch sample; open-shape map contract ("do not exact-match these maps").
  4. The `Accrue.Analytics.Dunning` module's `@moduledoc` carries a one-paragraph summary, `@since "1.4.0"` markers on each public function, and a link to `guides/analytics.md` — picked up by `verify_package_docs.sh` via a new analytics-guide pointer needle.
  5. A fresh `mix test` on `examples/accrue_host` (no DB pre-seed) mounts `/billing/analytics/recovery` and sees a non-empty funnel + at-risk table + drill-down rendering against deterministic-clock-seeded dunning events spanning 7d / 30d / 90d windows — the adopter-proof matrix row links to the seed script + screenshot + LiveView path.

**Plans:** TBD
**UI hint:** yes
**Note:** **BREAKING CHANGE — DAN-07 (cross-currency widening) MUST land in this phase before any post-v1.44 Hex publish.** The public-API freeze for 1.4.0 happens here; widening the return shape later would be a semver violation. DAN-07 + DAN-14 + DAN-15 + DAN-13(landed P144) + DAN-16 are bundled to ship the public surface in one consistent slice.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 144. Funnel query + viz + campaign-anchor retrofit + money formatter polish | 4/4 | Complete    | 2026-05-27 |
| 145. Time-window URL plumbing + window selector | 1/1 | Complete    | 2026-05-27 |
| 146. At-risk query + at-risk table + last-failure enrichment | 2/3 | In Progress|  |
| 147. Per-subscription drill-down route + CampaignLive | 0/0 | Not started | - |
| 148. Cross-currency widening + recovery-rate API + public docs + adopter-proof | 0/0 | Not started | - |
