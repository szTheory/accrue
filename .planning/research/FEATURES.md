# Feature Landscape — v1.44 Recovered-Revenue Dashboard Completion

**Domain:** Dunning analytics dashboard (admin LiveView) — completing the Phase 143 foundation
**Researched:** 2026-05-27
**Researcher:** gsd-project-researcher
**Overall confidence:** HIGH (foundation code), MEDIUM (competitor parity)

---

## Scope contract (read this first)

**v1.44 is "complete the Phase 143 dashboard, then stop."** It is NOT:
- A SaaS metrics product (MRR/ARR/churn/LTV remain `FIN-03` non-goals per JTBD-FRONTIER.md)
- A BI tool (no cohorts, no plan breakdowns, no forecasts)
- A revenue-recognition surface (`FIN-03` explicit non-goal)
- A custom dashboard builder

It IS: a single LiveView page that **visually proves Accrue's dunning engine saves the operator money**, with one drill-down and one slice (time window). Per the maintainer takeaway in `.planning/threads/v1.44-NEXT-STEP-ASSESSMENT.md`: *"Build the Recovered Revenue dashboard, then stop. You've hit the diminishing returns boundary."*

**Posture constraint inherited from Phase 143:** all analytics must read from the existing `accrue_events` ledger via Ecto JSONB aggregations. No new tables. No new dependencies. No charting JS libraries beyond CSS/SVG where avoidable.

---

## What's already shipped (Phase 143 baseline — do NOT re-list as v1.44 scope)

| Already shipped | File |
|---|---|
| `mrr_value_cents` + `currency` snapshotted on `dunning.recovered` + `dunning.exhausted` event payloads | `accrue/lib/accrue/webhook/default_handler.ex:782, 880` |
| `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` aggregating ledger via JSONB `sum(fragment(...))` with `:since`/`:until` window | `accrue/lib/accrue/analytics/dunning.ex` |
| `/billing/analytics/recovery` LiveView under admin-auth `live_session :accrue_admin` | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` + `router.ex:75-77` |
| Two KPI cards: "Recovered MRR" and "Lost MRR" rendered via `KpiCard.kpi_card` | `recovery_live.ex:38-56` |

**Adjacent ledger events that v1.44 can lean on (already emitted by v1.40, MRR-snapshotted only at recovered/exhausted):**

| Event type | Emission site | Carries MRR? | Other data |
|---|---|---|---|
| `dunning.campaign_started` | `default_handler.ex:1237` | No | subscription_id (via subject_id) |
| `dunning.step_sent` | `workers/dunning_step.ex:195` | No | `step_key`, `step_index` |
| `dunning.recovered` | `default_handler.ex:885` | Yes (since 143) | `source`, `mrr_value_cents`, `currency` |
| `dunning.exhausted` | `default_handler.ex:804` | Yes (since 143) | `to_status`, `source`, `mrr_value_cents`, `currency` |

This is the v1.44 feature scoping's most important fact: **the entire campaign step ladder is already in the ledger.** Funnel work needs zero new event emissions on the happy path. The MRR-on-step-sent question is the only emission-time decision.

---

## Table stakes (MUST ship in v1.44 — required to be "done")

Features the dashboard cannot credibly ship without, given the v1.44 charter and the assessment's "done enough" definition.

| Feature | Why expected | Complexity | Notes |
|---|---|---|---|
| **F1. Funnel visualization: Entered → Recovered → Exhausted (3 stages)** | Assessment names it explicitly. Stripe's own "Revenue Recovery" view ships a Failed → In recovery → Recovered → Not recovered funnel as the canonical operator mental model. Without this the dashboard is just 2 KPI cards. | **Small** — 3 counts from existing ledger, render as 3 horizontal bars/blocks with absolute count + percentage. Counts come from `count("dunning.campaign_started")`, `count("dunning.recovered")`, `count("dunning.exhausted")`. | Baremetrics/Stripe agree the funnel mental model is `entered → in-progress → terminal`. v1.44 does NOT need per-step breakdown (see F1' below — explicitly deferred). |
| **F2. Time-window filter: 7d / 30d / 90d preset buttons** | Every competitor (Baremetrics, Stripe, ChartMogul) ships preset windows. Operators reason in "last month" / "last quarter," not in custom date ranges. The existing `recovered_vs_lost_mrr/1` already accepts `:since`/`:until`. | **Small** — three `<button phx-click="window" phx-value-days="30">` triggering a `handle_event` that recomputes stats. No JS, no datepicker. | Stripe Dashboard defaults to 30d. Recommend `7d / 30d (default) / 90d` — three buttons, no "All time" (unbounded queries on a hot ledger are a footgun; All-time runs without an index hint), no MTD/QTD (calendar-aligned windows are accounting-flavored and add complexity for no operator gain). |
| **F3. "At-Risk Subscriptions" drill-down table** | Assessment names it explicitly. Operators want to know *who* is currently in dunning right now — this drives manual outreach, the highest-leverage recovery action per Baremetrics' published data. Surfaces the live work, not just history. | **Medium** — query `accrue_subscriptions WHERE dunning_campaign_started_at IS NOT NULL`, join customer for display name, paginate with LiveView 1.1 streams + keyed comprehensions. | Columns recommended below in §"F3 column spec". Default sort: MRR-at-risk descending (highest-LTV accounts first — Baremetrics convention). |
| **F4. Public `Accrue.Analytics.Dunning` API expansion** | Assessment names it as required ("Public underlying Ecto query module so developers can build custom dashboards"). Library posture demands the LiveView is a *consumer* of public API, not bypassing it via private functions. | **Small** — add 2-3 functions (see §"F4 API surface"). Refactor `RecoveryLive.mount/3` to call only the public surface. | This is the *library*-deliverable half of v1.44. The LiveView is the UI proof; the public API is the developer-deliverable. |
| **F5. Public docs: `guides/analytics.md` + module @moduledoc** | Per Accrue's documentation convention every public capability has a guide page (see `guides/dunning.md`, `guides/entitlements.md`, `guides/lifecycle_semantics.md`). The current `Accrue.Analytics.Dunning` `@moduledoc` is 8 lines — not a public-API docstring. | **Small** — one guide (~150-300 lines, mirror `guides/dunning.md` shape), expanded `@moduledoc`, ExDoc anchor. | Guide must answer: "how do I build my own analytics dashboard against the dunning ledger?" Use `Accrue.Billing.Dunning` `recovered_vs_lost/1` and `Accrue.Analytics.Dunning` `recovered_vs_lost_mrr/1` as the dual public API (counts + MRR). |
| **F6. Adopter-proof matrix row in `examples/accrue_host`** | Every shipped capability has a row in `adoption-proof-matrix.md` proving an adopter can see it work (see Phase 143 already has entries for `dunning campaign wiring` and `entitlement gating`). Without it the feature is not "complete" by Accrue's own contract. | **Small** — wiring test that seeds events via the deterministic `Accrue.Clock`, mounts `/billing/analytics/recovery`, asserts the funnel + KPIs + at-risk table render. | New row: "Recovered-revenue analytics — `accrue_events` → `Accrue.Analytics.Dunning` → `/billing/analytics/recovery` funnel + KPIs + at-risk table". Test file: `examples/accrue_host/test/accrue_host/recovery_analytics_test.exs`. |

### F3 column spec — At-Risk Subscriptions table

Based on what operators actually do (Baremetrics + ChartMogul observed columns + the v1.40 ledger surface):

| Column | Source | Sortable? | Rationale |
|---|---|---|---|
| Customer name + email | `accrue_customers` join | Yes (name asc) | Identification. Click-through to existing customer detail page (already exists in admin). |
| MRR at risk | computed via the same `calculate_mrr_cents/1` already in `default_handler.ex:1896` (extract to public helper) | Yes — default sort, desc | The "is this account worth a phone call?" signal. Stripe orders by this. |
| Days in campaign | `now - dunning_campaign_started_at` | Yes | "How far through the journey?" Visual proximity to grace expiry. |
| Current step | `Enum.find_index` over configured steps where `after_days <= days_in_campaign` (matches `Campaign.next_step/3` logic) | No | Lets operator see whether reminder #1 or final notice has fired. Drives "should I intervene?". |
| Next retry / next step | derived from `Campaign.next_step/3` (pure, already exists) | No | Time to next contact attempt. |
| Last failure reason | latest `invoice.payment_failed` event for the subscription — JSONB extract on the most recent webhook_event row OR enrich the campaign-started event | No | Diagnoses category: card declined vs. expired vs. fraud check. Stripe/Baremetrics both surface this. **Caveat:** requires a query path; see §"Dependencies & gaps". |

**Pagination:** LiveView 1.1 streams + keyed comprehensions, 25 rows/page. Server-side sort, no infinite scroll (admin operators expect numbered pages). Estimated typical fleet size for v1.0 adopters: 5-50 at-risk subscriptions; pagination matters only for the long tail.

### F4 API surface — `Accrue.Analytics.Dunning` additions

Recommended public functions (all should accept the same `:since`/`:until` keyword options as the existing `recovered_vs_lost_mrr/1`):

```elixir
# Already shipped (Phase 143):
recovered_vs_lost_mrr(opts \\ [])

# Add in v1.44:
funnel(opts \\ [])
# Returns: %{entered: n, recovered: n, exhausted: n, in_progress: n}
# Implementation: 4 grouped counts over the 4 event types, plus `in_progress = entered - recovered - exhausted` (or query the subscription table for live anchors).

at_risk_subscriptions(opts \\ [])
# Returns: [%{subscription_id: id, customer: %{...}, mrr_cents: n, started_at: dt, current_step_index: i, next_step_at: dt, last_failure_reason: str}]
# Opts: :limit (default 25), :offset, :sort_by (:mrr | :days | :name), :order (:asc | :desc)
# Note: this is the only function that joins; the LiveView passes it through.

recovery_rate(opts \\ [])
# Returns: %{rate: float, recovered: n, total_terminal: n}
# rate = recovered / (recovered + exhausted); nil if 0 total (avoid div-by-zero).
# Mirrors Stripe Dashboard's "Recovery rate" headline metric.
```

Explicitly NOT recommended for the v1.44 public API (scope creep — see §Anti-Features):

- `recovered_by_step/1` — operator would never act on it; the dashboard already shows per-step in the campaign-detail view (F1' is deferred anyway).
- `recovered_by_plan/1` — that's plan-segmented MRR analytics, i.e., **a metrics product**, not a dunning dashboard. Pure FIN-03 territory.
- `recovered_by_customer_segment/1` — same — cohort analysis is BI tool scope.
- `forecast_recovery/1` — predictive analytics; not even Stripe ships this.

---

## Differentiators (SHOULD ship if cheap; defer if not)

| Feature | Value | Complexity | Recommendation |
|---|---|---|---|
| **D1. Per-campaign drill-down (row → timeline)** | Stripe Dashboard ships this. Click a row in the At-Risk table → see the per-step Oban job trail with timestamps + email render previews + payment-attempt outcomes. This is the assessment's "see the exact Oban job/timeline that triggered it" — the *transparency* differentiator. | **Medium** — new route `/billing/analytics/recovery/:subscription_id`. Query `accrue_events WHERE subject_type = 'Subscription' AND subject_id = ^id AND type LIKE 'dunning.%'` ordered by `inserted_at`. Render as a vertical timeline. No new schema. Email preview can re-render the Swoosh template via existing `Mailer.preview/2` if it exists, else link to the generic admin event detail page. | **SHIP IT.** This is the one differentiator the assessment names by competitor (Stripe). It's the difference between "dashboard tells me numbers" and "dashboard lets me debug a customer." Marginal complexity — reuses event ledger. |
| **D2. Currency-aware MRR aggregation** | `data.currency` is already snapshotted alongside `mrr_value_cents`. Hosts with multi-currency subscriptions need totals split by currency, not summed across mismatched units. | **Small** — `GROUP BY type, (data->>'currency')` instead of just `GROUP BY type`. Render KPI cards in a per-currency table OR pin to the host's `default_currency` and badge mixed-currency events. | **SHIP IT with a default.** Single-currency hosts (the common case) see no UI change. Multi-currency hosts see a `USD / EUR / GBP` breakdown. ~30 LOC. |
| **D3. Funnel hover/click → step list of dropped subs** | Click "Exhausted" → see which subscriptions hit terminal action and why. Adjacent to D1 (the customer-level drill-down) but at the *cohort* level. | **Small-Medium** — wire `phx-click` on funnel stages to filter the At-Risk table OR open a side-panel listing. | **OPTIONAL.** D1 already covers the "investigate one" path. D3 is the "investigate the cohort" path. Skip if budget tight — D1 is the higher-leverage one. |

---

## Differentiators that competitors ship but Accrue should NOT (scope-creep red flags)

These are the BI-tool features the assessment explicitly warns against. Naming them concretely is the whole point of an anti-features list.

| Anti-feature | Why competitors ship it | Why we DON'T | What to do instead |
|---|---|---|---|
| **Cohort analysis** (e.g., "Q1-2026 cohort recovery rate") | Baremetrics, ChartMogul, ProfitWell all ship cohort tables. | This is `FIN-03` territory. Cohort math = analytics product. | Host imports event ledger into their own BI tool (Metabase, Hex, Mode). Document a "How to export accrue_events to your BI tool" recipe in `guides/analytics.md`. |
| **Failure-reason breakdown chart** | Stripe ships "decline-code distribution" pie/bar. | Requires either a new event type or joining `webhook_events` payloads. Adjacent to "category analytics," not "did dunning save me money." | Surface the per-subscription `last_failure_reason` in the At-Risk table (F3) — operator-actionable, no aggregate chart. |
| **MRR-by-plan breakdown** | Every metrics tool ships this. | Plan-segmented MRR is the textbook "we're not a metrics product" boundary. JTBD-FRONTIER.md explicitly puts MRR/ARR/churn at 🚫 non-goal. | None. This belongs in the host's BI tool. |
| **Churn forecast / predictive recovery rate** | ProfitWell/Paddle Retain markets this as their differentiator. | Predictive ML is **categorically** off-posture. Accrue is a billing library, not a data-science product. | None. |
| **A/B test on dunning email content** | Baremetrics Recover, ChartMogul, ProfitWell Retain all ship this. | Belongs in the host's email/marketing stack (Customer.io, Postmark, Resend). Accrue authors templates and emits ledger events — that's the seam. | Document how to swap dunning templates via host config; out-of-scope to track variant-vs-variant in our ledger. |
| **Custom-range date picker** | Every BI tool ships one. | Calendar widget = new JS, accessibility surface, timezone semantics. Preset buttons (7d/30d/90d) cover ≥95% of operator use cases. | 3 preset buttons (see F2). |
| **CSV export of at-risk subscriptions** | Stripe/Baremetrics both ship export. | Tempting because it's "small." But export → spreadsheet → email workflow is the toe in BI-tool waters. If an adopter needs this, they have the public `Accrue.Analytics.Dunning.at_risk_subscriptions/1` API. | Document the API call in `guides/analytics.md`; let hosts compose their own export. |
| **Email/Slack alerting on recovery rate drops** | ChartMogul ships this. | Notification routing is not Accrue's layer — it's the host's `[:accrue, :ops, :dunning_*]` telemetry consumer's job. We already emit the events. | Document the existing telemetry events (already in `guides/telemetry.md`) and that hosts wire alerts. |
| **Configurable dashboard layout / saved views** | Most BI tools ship this. | Layout customization is product surface, not library surface. | None. If a host wants a different layout, they consume the `Accrue.Analytics.Dunning` API and build their own. |
| **All-time / unbounded time window** | Baremetrics shows "Lifetime" recovery. | Unbounded ledger scan over `accrue_events` is a performance footgun at scale (the ledger is append-only forever). | Cap at 90d in v1.44. If a host needs lifetime, they call the public API directly with `:since` from epoch — explicit footgun-acceptance. |
| **Per-step recovery rate breakdown in the funnel (F1')** | Stripe ships this. | The current ledger doesn't snapshot MRR on `dunning.step_sent` — so per-step *MRR* would be inferred via subscription join (which violates the temporal-data-leakage rule already established in 143-RESEARCH.md). Per-step *counts* are possible but operator value is low ("step 2 has a 12% recovery boost over step 1" — not actionable for v1.x). | If we ship per-step at all (deferred to v1.45+), do per-step *counts only*, never per-step MRR. v1.44: simple 3-stage funnel. |

**The red-flag heuristic:** if a feature requires answering "what *segment* recovered?" rather than "*did the engine* recover the money?", it's BI-tool scope. The dashboard answers the second question.

---

## Funnel granularity decision — answer to Q1

**Recommendation: 3 stages in v1.44, named per the assessment.**

```
Entered Dunning  →  Recovered  +  Exhausted
   (count of                   (count of           (count of
    dunning.                    dunning.            dunning.
    campaign_started)           recovered)          exhausted)

    Plus an "In Progress" callout = entered - recovered - exhausted
    (or: count of subscriptions with dunning_campaign_started_at IS NOT NULL)
```

**Why not the 5-stage version (Entered → Step1 → Step2 → Step3 → Recovered/Exhausted-at-each-step)?**

1. **Operator value is low.** The default journey is `[0, 5, 12]`. By the time step 3 fires, Stripe Smart Retries has had 12 days to recover the payment — the per-step "drop-off" attribution is statistically muddy.
2. **Configurability complicates rendering.** Hosts can configure 2, 3, 4, or N steps. A funnel with N stems would need dynamic SVG/CSS, not a static 3-block layout.
3. **The drill-down (D1) already shows per-step delivery per customer.** Cohort-level per-step is BI-tool scope.
4. **Stripe itself doesn't ship per-step in the headline funnel.** Their "Revenue recovery" overview is 4 stages (Failed → In recovery → Recovered → Not recovered), not per-retry-attempt. Per-attempt detail is one drill-down level deeper.

**Counter-argument considered:** "Per-step would prove which campaign step is doing the work." Response: that's a *campaign tuning* analytic (which step has best ROI?), not a "did dunning save me money?" analytic. Tuning belongs in a v1.45+ campaign A/B feature (which we already named as Anti-Feature above as a scope-creep red flag). For v1.44, the 3-stage funnel is exactly the assessment's spec.

---

## Time-window semantics decision — answer to Q3

**Three preset buttons: `7d / 30d / 90d`, with `30d` as default.**

| Question | Answer | Rationale |
|---|---|---|
| Which windows? | 7d, 30d, 90d | Stripe Dashboard's defaults. Aligns with "weekly check-in / monthly review / quarterly board metric" operator cadences. |
| Default? | 30d | Same as Stripe's "Revenue Recovery" view default. Monthly cadence dominates SaaS operator reviews. |
| Custom-range picker? | NO | Calendar widgets add JS, a11y surface, and timezone semantics. Operators who need a custom range can call the public API. Per the maintainer takeaway: "Build the dashboard, then stop." |
| All-time / lifetime? | NO | Unbounded `accrue_events` scan is a performance footgun. Document that the public API accepts arbitrary `:since` if hosts opt in. |
| MTD / QTD? | NO | Calendar-aligned windows are accounting-flavored. Adds timezone complexity (whose month?). |
| Window applies to event timestamp or campaign-start timestamp? | **Event `inserted_at`** | Three reasons: (1) Already what the existing `recovered_vs_lost_mrr/1` filters on (`e.inserted_at >= ^since` in `analytics/dunning.ex:65`). (2) Matches operator mental model "what did dunning save me *this month*" — they're asking about *terminal outcomes* in the window, not campaigns that *started* in the window (some of which won't have outcomes yet). (3) Avoids the "campaign started day 28 of last month, recovered day 3 of this month, shows up in *neither* window" footgun that campaign-start-timestamp filtering would create. |

**Caveat for funnel coherence:** if the funnel uses `inserted_at` as the window, the "Entered Dunning" count and the "Recovered + Exhausted" counts may not sum to the entered count (some campaigns that started in-window are still in-progress; some that started before the window recovered in-window). Document this in the funnel UI as a small annotation ("In progress: X" displayed below the funnel — campaigns started but not yet terminal). Don't try to force a one-to-one balance — the funnel is a directional indicator, not a closed accounting identity.

---

## Per-campaign drill-down content — answer to Q4

If D1 ships (recommended), the drill-down view should show **exactly these surfaces** and nothing more:

| Section | Source | Purpose |
|---|---|---|
| **Customer + subscription header** | Existing customer/subscription rows (already exists in admin's subscription detail view) | Identifies the case. Reuse the existing component, don't rebuild. |
| **Vertical timeline of dunning events** | `accrue_events WHERE subject_type = 'Subscription' AND subject_id = ^id AND type LIKE 'dunning.%' ORDER BY inserted_at ASC` | The full event story: campaign_started → step_sent (×N) → recovered/exhausted. Each row: timestamp, event type badge, payload summary. |
| **Linked invoice/payment context** | Existing `accrue_invoices` + `accrue_payments` for the subscription (admin already renders these) | Without payment context, the timeline is theatrical. Operator wants to see "step 2 sent → payment retry succeeded $59" as a single story. |
| **Link to subscription detail page** | Existing admin route | Escape hatch to all other ops (cancel, comp, re-send, etc.). Don't duplicate those actions here. |

**Explicitly NOT in the drill-down:**

- Full Oban job inspection (Oban Web is a separate package; don't reinvent it). Link to it if installed.
- Email render preview as a separate iframe (Swoosh `Mailer.deliver_later` / preview is a separate surface; link out if it exists, don't embed).
- Manual retry button. Recovery is automated; manual retry is a host-app responsibility against `Accrue.Billing.pay_invoice/2`.

---

## At-risk drill-down details — answer to Q2

**Columns, sorts, and pagination** are spec'd in §"F3 column spec" above. Restating the operator-research summary here:

What competitors expose (synthesis of Baremetrics, ChartMogul, Stripe):
- Customer identifier (name + email) — universal
- MRR/LTV at risk — universal, almost always the default sort
- Days in dunning / time-in-status — universal
- Current step / retry attempt — Baremetrics + Stripe; ChartMogul shows it less prominently
- Last failure reason / decline code — Stripe + Baremetrics
- Next scheduled action — Stripe + Baremetrics

What operators **actually use** (from the recovered-revenue blog post research):
- MRR at risk + customer name = the "do I personally email this person?" signal
- Days in campaign + current step = the "is the automated journey enough or do I intervene?" signal
- Failure reason = the "is this fixable by them (expired card) or a hard decline (fraud)?" triage

**Pagination:** LiveView 1.1 streams + keyed comprehensions (LiveView 1.1's `:key` attribute on `<.list>` / streams pattern). 25 rows per page, server-side sort, page-based pagination (not infinite scroll — admin operators expect "page 2 of 3"). For typical v1.0 adopters (5-50 at-risk subs) pagination is mostly an aesthetic choice; matters for the long tail.

---

## Public API surface — answer to Q5

Spec'd in §"F4 API surface" above. Summary:

```elixir
# Public (ship in v1.44):
Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1   # already shipped (Phase 143)
Accrue.Analytics.Dunning.funnel/1                  # NEW
Accrue.Analytics.Dunning.at_risk_subscriptions/1   # NEW
Accrue.Analytics.Dunning.recovery_rate/1           # NEW

# Existing public (don't touch):
Accrue.Billing.Dunning.recovered_vs_lost/1         # counts not MRR (pre-143)
```

Note the dual public API: `Accrue.Billing.Dunning.recovered_vs_lost/1` (counts) is the older `accrue/lib/accrue/billing/dunning.ex:134` function. `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` is the newer MRR-aware one. Both should coexist — counts are useful for low-cardinality plans (one big-ticket subscription's MRR distorts averages); MRR is useful for revenue framing. The guide should explain the distinction.

---

## Adopter-proof — answer to Q6

**The adopter-proof story for analytics is harder than for product features** because analytics is about *time*: a static seed is not a story; a story is "watch the dashboard *change* as the campaign progresses."

**Recommended approach:** time-warp fixture via the existing `Accrue.Clock` deterministic clock (already used in `dunning_full_journey_test.exs` per the adoption-proof matrix). The wiring test:

```elixir
# examples/accrue_host/test/accrue_host/recovery_analytics_test.exs

test "operator can see recovery dashboard reflect dunning campaign outcomes" do
  # Phase 1: seed a subscription that fails payment
  {:ok, sub} = create_failing_subscription(mrr_cents: 5000)

  # Phase 2: advance the clock to fire all campaign steps
  Accrue.Clock.advance(:days, 5)   # step 2 fires
  Accrue.Clock.advance(:days, 7)   # step 3 fires
  Accrue.Clock.advance(:days, 2)   # past grace → exhausted

  # Phase 3: mount dashboard, assert the funnel + KPIs reflect the journey
  {:ok, view, html} = live(conn, "/billing/analytics/recovery")
  assert html =~ "$50.00"  # Lost MRR
  assert html =~ "Exhausted: 1"
  # ... and so on
end
```

**Adoption-proof matrix row to add:**

| Concern | Proof | Where |
|---|---|---|
| Recovered-revenue analytics — `accrue_events` → `Accrue.Analytics.Dunning` → `/billing/analytics/recovery` funnel + KPIs + at-risk table | `recovery_analytics_test.exs` (host wiring smoke) — Fake-lane deterministic-clock journey through campaign_started → step_sent ×N → exhausted, asserts dashboard funnel + KPI cards + at-risk row | `examples/accrue_host/test/accrue_host/recovery_analytics_test.exs` |

This goes into the "Blocking: Fake-backed host + browser" table in `adoption-proof-matrix.md`, paired alongside the existing "Dunning campaign wiring" row (line 27 of that file).

**Seed-data alternative considered + rejected:** seeding 30 days of synthetic events at host boot. Rejected because (a) it pollutes the dev DB with non-deterministic timestamps, (b) re-seeding muddies the clean adopter-proof story, and (c) the `Accrue.Clock` time-warp pattern is already established and proven in v1.40's dunning tests — extending it for analytics is the on-posture choice.

---

## Anti-features (the explicit OUT-OF-SCOPE list)

Restated and consolidated from §"Differentiators competitors ship but Accrue should NOT":

| Anti-feature | What to do instead |
|---|---|
| Cohort analysis (Q1-cohort retention, etc.) | Recommend BI tool export in `guides/analytics.md` |
| Failure-reason breakdown chart | Show per-row in the At-Risk table only |
| MRR-by-plan breakdown | None (FIN-03 non-goal) |
| Churn forecast / predictive ML | None (off-posture entirely) |
| A/B test on dunning email content | Host's marketing stack |
| Custom-range date picker | Public API accepts arbitrary `:since`/`:until` |
| CSV export | Public API + host composes export |
| Email/Slack alerts on recovery-rate drops | Existing telemetry events + host's alerting stack |
| Configurable dashboard layout / saved views | Host builds their own LiveView atop the public API |
| All-time / lifetime window | Public API accepts `:since` from epoch (explicit opt-in) |
| Per-step funnel breakdown (F1') | Defer to v1.45+ if ever; D1 drill-down covers the per-customer story |
| Per-customer-segment recovery rate | BI tool scope |
| Dashboard widget framework / pluggable charts | Host builds their own LiveView |

**The litmus test the maintainer can use during planning:**

> "Does this feature answer 'did the engine save me money?' or does it answer 'which segment / cohort / plan / customer-attribute is performing how?'"
>
> First answer → v1.44 scope.
> Second answer → BI-tool scope. Park it.

---

## Feature dependencies (build-order graph)

```
F4 (public API expansion)
   ↓
   ├── F5 (analytics.md guide consumes the public API)
   ├── F1 (funnel uses Analytics.Dunning.funnel/1)
   ├── F2 (window filter passes :since/:until through to all API calls)
   ├── F3 (at-risk table uses Analytics.Dunning.at_risk_subscriptions/1)
   │     └── F3 needs: extract calculate_mrr_cents/1 from default_handler.ex to a shared helper module
   │
   └── D1 (drill-down) — independent route, queries events directly (no analytics module needed)
         └── D1 needs: existing customer/subscription detail components (already shipped)

F6 (adopter-proof) — built last, exercises F1+F2+F3+D1 end-to-end
```

**Critical dependency to flag for the roadmapper:** `at_risk_subscriptions/1` (F3) requires extracting `calculate_mrr_cents/1` from `default_handler.ex:1896` to a publicly-accessible module (probably `Accrue.Billing.Money` or `Accrue.Subscription.Mrr`). Currently it's a private defp inside the webhook handler. This is a ~30 LOC extraction with no behavior change, but it has to happen before F3 is implementable. Phase plan should include it as an early step.

**Secondary dependency:** the "last failure reason" column in F3 (§F3 column spec) requires a query path that doesn't currently exist as a public function. Either (a) add a `last_failure_for_subscription/1` to `Accrue.Billing.Dunning`, or (b) enrich the `dunning.campaign_started` event payload with the triggering failure reason, or (c) drop the column from v1.44 scope. Recommend (b) — it's a one-line addition to `record_dunning_campaign_started/2` in `default_handler.ex:1237`, requires backfill only on existing data (or accept that pre-v1.44 campaigns just show "—" for the column).

---

## MVP recommendation — the minimum-viable v1.44

If the roadmapper has to cut, ship in this order:

1. **F4 — Public API expansion** (`funnel/1`, `at_risk_subscriptions/1`, `recovery_rate/1`). [BLOCKING — the library deliverable]
2. **F1 — 3-stage funnel** (Entered → Recovered → Exhausted) [BLOCKING — the assessment names it]
3. **F2 — 7d/30d/90d preset buttons** [BLOCKING — useless without window control]
4. **F3 — At-risk drill-down table** [BLOCKING — the assessment names it]
5. **F5 — `guides/analytics.md`** [BLOCKING — Accrue's documentation convention]
6. **F6 — Adopter-proof matrix row + wiring test** [BLOCKING — Accrue's "done" contract]
7. **D1 — Per-campaign drill-down** [HIGH-VALUE — the differentiator, ship if budget]
8. **D2 — Currency-aware aggregation** [POLISH — ship if cheap]
9. **D3 — Funnel-click cohort filter** [SKIP — D1 covers the same need]

**If budget gets tight, cut in this order: D3 → D2 → D1.** Never cut from F1-F6.

---

## Sources

- **`/Users/jon/projects/accrue/.planning/threads/v1.44-NEXT-STEP-ASSESSMENT.md`** — "done enough" definition, maintainer takeaway, scope-creep warning
- **`/Users/jon/projects/accrue/.planning/phases/143/143-VERIFICATION.md`** — Phase 143 verified deliverables baseline
- **`/Users/jon/projects/accrue/.planning/phases/143/143-RESEARCH.md`** — temporal-data-leakage decision, locked constraints
- **`/Users/jon/projects/accrue/.planning/research/JTBD-FRONTIER.md`** — FIN-03 non-goal scope; 6-of-6 SaaS loop posture
- **`/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex`** — dunning event emission sites (lines 782, 804, 880, 1237, 1896)
- **`/Users/jon/projects/accrue/accrue/lib/accrue/workers/dunning_step.ex:195`** — `dunning.step_sent` emission site
- **`/Users/jon/projects/accrue/accrue/lib/accrue/analytics/dunning.ex`** — Phase 143 public API foundation
- **`/Users/jon/projects/accrue/accrue/lib/accrue/billing/dunning.ex`** — pre-existing `recovered_vs_lost/1` counts API
- **`/Users/jon/projects/accrue/accrue/lib/accrue/dunning/campaign.ex`** — pure step resolver (used in §F3 "current step" computation)
- **`/Users/jon/projects/accrue/accrue/guides/dunning.md`** — shape template for `guides/analytics.md`
- **`/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`** — current LiveView (extension target)
- **`/Users/jon/projects/accrue/examples/accrue_host/docs/adoption-proof-matrix.md`** — adopter-proof contract template
- **Stripe — Revenue Recovery Analytics docs** (HIGH confidence — 4-stage funnel + recovery rate + recovery-method breakdown reference) — <https://docs.stripe.com/billing/revenue-recovery/recovery-analytics>
- **Baremetrics Recover features** (MEDIUM confidence — competitor parity reference for dashboard surfaces) — <https://baremetrics.com/features/recover>
- **Baremetrics dunning strategy guide** (MEDIUM confidence — operator-action research) — <https://baremetrics.com/blog/ultimate-dunning-management-guide>
- **ChartMogul vs Baremetrics vs ProfitWell breakdown** (LOW-MEDIUM confidence — synthesis of dunning analytics positioning) — <https://www.cobloom.com/blog/chartmogul-vs-baremetrics>
- **Phoenix LiveView 1.1 streams + keyed comprehensions** (HIGH confidence — F3 pagination approach) — <https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html>
- **LiveView streams with pagination tutorial** (MEDIUM confidence — page-based vs infinite-scroll reference) — <https://www.elixirstreams.com/tips/liveview-streams-with-pagination>
