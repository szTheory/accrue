# Phase 198: Propagate DETAIL + analytics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-28
**Phase:** 198-propagate-detail-analytics
**Areas discussed:** Customer-360 tab policy, Action surfaces and drawers, Summary rows and drill grouping, Recovery and Campaign analytics grammar

---

## User Direction

User asked to discuss and consider all gray areas, research each with subagents,
weigh pros/cons/tradeoffs, consider Elixir/Plug/Ecto/Phoenix idiom, successful
libraries/apps in the same and adjacent spaces, DX, least surprise, UI/UX,
accessibility, performance, JTBD/persona/user psychology, brandbook/prompt
corpus, and produce one coherent set of recommendations so the user does not
need to make more decisions before planning.

---

## Customer-360 Tab Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current 3 primary tabs plus More | Preserves current CustomerLive shape but keeps non-peer content hidden in a broad More bucket. | |
| Strict peer-record tabs only | Keep only Subscriptions, Invoices, Payments as equal Customer-360 record sets; move other content into summary/drill/lazy sections. | x |
| No tabs on CustomerLive | Uniform detail pattern, but weakens customer-360 triage ergonomics. | |
| Full seven-tab workspace | Maximum separation, but contradicts SPEC-DETAIL unless every tab is a peer collection. | |

**User's choice:** User delegated the decision to advisor research and asked for
a cohesive recommendation.

**Notes:** Advisor research recommended strict peer-record tabs only. Payment
methods, entitlements, events, and metadata are not peer tabs because they are
operational/detail/audit/debug content. Keep URL compatibility and avoid ARIA
tab semantics unless the implementation provides the full keyboard contract.

---

## Action Surfaces and Drawers

| Option | Description | Selected |
|--------|-------------|----------|
| Universal action band with overflow and drawer | Use visible primary actions, overflow when needed, and drawer-hosted forms. | x |
| Single primary opens drawer | Best for one-action pages such as charge, webhook, and connect account. | x |
| Inline form in drill section | Lowest wiring, but violates no pre-expanded action forms for object actions. | |
| No action surface | Correct when no valid action exists; show state copy instead of disabled controls. | x |

**User's choice:** User delegated the decision to advisor research and asked for
a cohesive recommendation.

**Notes:** Advisor research recommended status-gated primary actions, overflow
only when needed, no disabled-looking-enabled controls, drawer-hosted forms and
confirmations, and step-up for sensitive/money-moving operations. Invoice,
charge, webhook, connect account, and customer payment-method flows are the
high-risk targets.

---

## Summary Rows and Drill Grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Per-page tuned SPEC-DETAIL propagation | Use existing DETAIL primitives, keep page-specific JTBD clear, avoid abstraction risk. | x |
| Declarative shared detail layout/schema | Centralizes ordering but risks a leaky DSL over actions, state, and exceptions. | |
| KPI-retention hybrid | Preserves current cards but competes with summary-then-drill if KPI grids stay top-level. | |
| Customer-360 tab exception | Keep only true peer record-set tabs while moving the rest into detail grammar. | x |

**User's choice:** User delegated the decision to advisor research and asked for
a cohesive recommendation.

**Notes:** Advisor research recommended per-page tuned propagation. Delete
top-level KPI grids; fold facts into summary rows or drill-local compact facts.
Place exactly one related strip after object drills and before lazy Activity/Raw
data. Do not introduce a generic detail-page DSL.

---

## Recovery and Campaign Analytics Grammar

| Option | Description | Selected |
|--------|-------------|----------|
| Literal dashboard four-zone grammar on both pages | One invariant set, but forces fake zones into Campaign and conflicts with Recovery's hero-pair-first clause. | |
| Recovery-specific overview plus Campaign detail drill-down | Matches current routes, Phase 194 intent, and the actual operator jobs. | x |
| Chart-led analytics report | Familiar reporting shape but violates no-chart-wall and de-emphasizes action. | |
| New generic AnalyticsPage DSL/component | Might help future pages but premature for two different jobs. | |

**User's choice:** User delegated the decision to advisor research and asked for
a cohesive recommendation.

**Notes:** Advisor research recommended treating `/analytics/recovery` as a
Recovery-specific overview and `/analytics/recovery/subscriptions/:id` as a
Campaign detail drill-down. Keep the funnel as supporting visualization; do not
build a new chart or generic analytics abstraction.

---

## Claude's Discretion

- Exact summary row labels/order and short copy, bounded by `brandbook/voice.md`.
- Exact helper names and locations.
- Whether to extract a small Customer peer-subview component.
- Exact `data-ax-*` marker placement under locked selectors.
- Which target pages receive deepest browser coverage, provided the representative
  set covers Customer, Invoice, Charge, Webhook, Connect Account, Recovery, and
  Campaign.

## Deferred Ideas

- Generic `DetailPage` DSL/schema.
- Generic `AnalyticsPage` abstraction.
- New Recovery chart or time-series replacement.
- Full cross-page overlay sweep and transformed-ancestor audit.
- Portal white-label billing design-system pass.
