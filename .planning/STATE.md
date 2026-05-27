---
gsd_state_version: 1.0
milestone: v1.44
milestone_name: milestone
status: planning
stopped_at: Phase 144 context gathered
last_updated: "2026-05-27T15:35:15.398Z"
last_activity: 2026-05-27 — Milestone v1.44 roadmap committed (5 phases, 144–148, 16/16 DAN-* requirements mapped)
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27 after v1.43 milestone)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Polish & Adopter ROI Proof. v1.44 completes the Phase 143 Recovered-Revenue dashboard foundation with funnel, at-risk drill-down, time-window filters, public docs, and adopter-proof.

## Current Position

Phase: Not started (roadmap committed; ready for `/gsd:plan-phase 144`)
Plan: —
Status: Roadmap committed, awaiting phase planning
Last activity: 2026-05-27 — Milestone v1.44 roadmap committed (5 phases, 144–148, 16/16 DAN-* requirements mapped)

## Milestone Progress

### v1.44 — Recovered-Revenue Dashboard Completion (ACTIVE, Planning)

5 phases (144–148), 16 requirements (DAN-01..DAN-16). Builds on standalone Phase 143 foundation.

- [ ] **Phase 144** — Funnel query + viz + campaign-anchor retrofit + money formatter polish (DAN-01, DAN-02, DAN-08, DAN-09, DAN-13)
- [ ] **Phase 145** — Time-window URL plumbing + window selector (DAN-10)
- [ ] **Phase 146** — At-risk query + at-risk table + last-failure enrichment (DAN-03, DAN-04, DAN-11)
- [ ] **Phase 147** — Per-subscription drill-down route + CampaignLive (DAN-05, DAN-12)
- [ ] **Phase 148** — Cross-currency widening + recovery-rate API + public docs + adopter-proof (DAN-06, DAN-07, DAN-14, DAN-15, DAN-16) — **BREAKING change DAN-07 blocks any post-v1.44 Hex publish**

### Recently shipped milestones

**v1.43** (shipped & archived **2026-05-27**): 3 phases (**140–142**). Theme: Close the linked release-truth gap by locking the three-package contract, shipping the public `1.2.0` trio with canonical proof, and finishing the post-publish planning-mirror plus inventory closeout.

**Phase 143** (standalone, verified **2026-05-27**): Recovered-Revenue Analytics Foundation — `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` + `/billing/analytics/recovery` LiveView + MRR snapshotting on dunning lifecycle events. NOT part of v1.43 milestone; informs v1.44.

**v1.42** (shipped & archived **2026-05-27**): 5 phases (**135–139**). Phase 139 shipped the UI for operator ad-hoc invoice management. Audit: `.planning/v1.42-v1.42-MILESTONE-AUDIT.md`.

**v1.41** (shipped & archived **2026-05-26**): 2 phases (**133–134**), 2 plans, SRCH-01..04. Admin global search via Postgres native `pg_trgm` indices and Ecto similarity queries, with a CMD+K keyboard-navizable LiveComponent in the admin UI. Audit: `.planning/v1.41-v1.41-MILESTONE-AUDIT.md`.

**v1.40** (shipped & archived **2026-05-25**): 5 phases (**128–132**), DUN-01..10 + PROOF-03 (11 requirements, 11/11 mapped). Multi-step dunning journey (campaign engine + idempotency must-fix → customer/operator surfaces + observability → provider honesty + Fake-lane proof + example-host wiring → optional Chimeway adapter, isolated → entitlements adopter-proof). Audit: `.planning/v1.40-v1.40-MILESTONE-AUDIT.md`.

**v1.39** (shipped & archived **2026-05-24**): 5 phases (**123–127**), 21 plans, ENT-01..12 (12/12). Headline JTBD — fail-closed local-first plan/feature gating with no new tables and no Stripe dependency — plus the isolated off-by-default Stripe-native advisory sync. Audit: `.planning/v1.39-v1.39-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 48 (v1.43) + 2 (Phase 143 standalone)
- Average duration: 1m
- Total execution time: 1m

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 140 | 01 | 1m | 2 | 0 |
| 143 | 02 | 2m | 2 | 3 |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-05-27 (v1.44 roadmap):** Phase 148 owns the **BREAKING** cross-currency widening (DAN-07). Must land before any post-v1.44 Hex publish — the public API surface freezes there and widening the `recovered_vs_lost_mrr/1` return shape later would be a semver violation.
- **2026-05-27 (v1.44 roadmap):** DAN-13 (MoneyFormatter polish) pulled into Phase 144 alongside the funnel viz so funnel money labels render correctly from day one (instead of inheriting the USD-only `:erlang.float_to_binary` bug).
- **2026-05-27 (v1.44 roadmap):** Phase 144 owns the Phase 143 forward-fix to the write path — `campaign_anchor` snapshot onto `dunning.recovered` / `dunning.exhausted` events in `default_handler.ex`. Required for DAN-01's DISTINCT-tuple funnel de-duplication (Pitfall #1 prevention).
- **2026-05-27:** Milestone Next-Step Assessment complete. Accrue is 6 of 6 on the canonical SaaS loop (feature-complete core). v1.44 selected to prove the v1.40 dunning engine's ROI to adopters via the recovered-revenue dashboard.
- **2026-05-26:** Open **v1.42 — Ad-hoc Invoices & Adopter Confidence** to address remaining JTBD frontier items and adopter-proof gaps identified during v1.39/v1.40 audits.

### Pending Todos

- Run `/gsd:plan-phase 144` to decompose Phase 144 into executable plans.

### Blockers/Concerns

- None open.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | deferred to `lattice_stripe ≥ 1.2` | 2026-05-22 |
| scope | Multi-channel (SMS/push/in-app) dunning | out of scope v1.40; Chimeway engine unlocks later | 2026-05-24 |
| scope | Per-step funnel breakdown in recovery dashboard | out of scope v1.44; deferred to v1.45+ if demanded | 2026-05-27 |
| scope | MRR-at-risk column on at-risk table | out of scope v1.44; requires extracting `calculate_mrr_cents/1` from `DefaultHandler` | 2026-05-27 |
| scope | Compensating-event backfill of pre-v1.44 events without `mrr_value_cents` | out of scope v1.44; cutoff-date label is the v1.44 honest answer | 2026-05-27 |
| scope | Real-time PubSub-driven dashboard refresh | out of scope v1.44; coupled to multi-channel dunning v1.45+ | 2026-05-27 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | carried |

## Session Continuity

Last session: 2026-05-27T15:35:15.396Z
Stopped at: Phase 144 context gathered
Resume file: .planning/phases/144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po/144-CONTEXT.md

## Operator Next Steps

- Run `/gsd:plan-phase 144` to begin v1.44 execution (funnel query + viz + campaign-anchor retrofit + money formatter polish).
