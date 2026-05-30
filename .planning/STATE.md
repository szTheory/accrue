---
gsd_state_version: 1.0
milestone: v1.47
milestone_name: ENT-10 Polish + Adopter-Proof Completeness
status: planning
last_updated: "2026-05-30T18:00:00.000Z"
last_activity: 2026-05-30
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30 after v1.47 milestone start)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** v1.47 — ENT-10 Polish + Adopter-Proof Completeness

## Current Position

Phase: 154 (Advisory Cache Core Correctness)
Plan: —
Status: Planning
Last activity: 2026-05-30 — Roadmap created for v1.47

## Milestone Progress

### v1.47 Phase Summary

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 154 | Advisory Cache Core Correctness | ADV-01, ADV-02, ADV-03, ADV-04, POL-01, POL-02 | Not started |
| 155 | StripeFixtures Polish + Telemetry Counters | POL-03, POL-04 | Not started |
| 156 | Entitlements Gating Adopter Proof | PRF-01 | Not started |
| 157 | Metered Usage Adopter Proof | PRF-02 | Not started |
| 158 | Oban Cron Wiring Adopter Proof | PRF-03 | Not started |

### Recently shipped milestones

**v1.46** (shipped & archived **2026-05-30**): 3 phases (**151–153**), 1 requirement (MNT-01). Theme: Maintenance & Closure — routine issue triage, dependency updates, @since annotation fixes, Three Zeros gate, Hex 1.3.0 publish, and audit trail closure. Audit: `.planning/v1.46-v1.46-MILESTONE-AUDIT.md`.

**v1.45** (shipped & archived **2026-05-29**): 2 phases (**149–150**), 4 requirements (BAN-01..BAN-04). Theme: Multi-channel Dunning (In-App Banners). Audit: `.planning/v1.45-v1.45-MILESTONE-AUDIT.md`.

**v1.44** (shipped & archived **2026-05-28**): 5 phases (**144–148**), 16 requirements (DAN-01..DAN-16). Builds on standalone Phase 143 foundation. Audit: `.planning/v1.44-v1.44-MILESTONE-AUDIT.md`.

**v1.43** (shipped & archived **2026-05-27**): 3 phases (**140–142**). Theme: Close the linked release-truth gap by locking the three-package contract, shipping the public `1.2.0` trio with canonical proof, and finishing the post-publish planning-mirror plus inventory closeout.

**Phase 143** (standalone, verified **2026-05-27**): Recovered-Revenue Analytics Foundation — `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` + `/billing/analytics/recovery` LiveView + MRR snapshotting on dunning lifecycle events. NOT part of v1.43 milestone; informs v1.44.

**v1.42** (shipped & archived **2026-05-27**): 5 phases (**135–139**). Phase 139 shipped the UI for operator ad-hoc invoice management. Audit: `.planning/v1.42-v1.42-MILESTONE-AUDIT.md`.

**v1.41** (shipped & archived **2026-05-26**): 2 phases (**133–134**), 2 plans, SRCH-01..04. Admin global search via Postgres native `pg_trgm` indices and Ecto similarity queries, with a CMD+K keyboard-navizable LiveComponent in the admin UI. Audit: `.planning/v1.41-v1.41-MILESTONE-AUDIT.md`.

**v1.40** (shipped & archived **2026-05-25**): 5 phases (**128–132**), DUN-01..10 + PROOF-03 (11 requirements, 11/11 mapped). Multi-step dunning journey (campaign engine + idempotency must-fix → customer/operator surfaces + observability → provider honesty + Fake-lane proof + example-host wiring → optional Chimeway adapter, isolated → entitlements adopter-proof). Audit: `.planning/v1.40-v1.40-MILESTONE-AUDIT.md`.

**v1.39** (shipped & archived **2026-05-24**): 5 phases (**123–127**), 21 plans, ENT-01..12 (12/12). Headline JTBD — fail-closed local-first plan/feature gating with no new tables and no Stripe dependency — plus the isolated off-by-default Stripe-native advisory sync. Audit: `.planning/v1.39-v1.39-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 63 (v1.43) + 2 (Phase 143 standalone)
- Average duration: 1m
- Total execution time: 1m

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 140 | 01 | 1m | 2 | 0 |
| 143 | 02 | 2m | 2 | 3 |
| Phase 144 P01 | 4m | 3 tasks | 3 files |
| Phase Phase 144 P02 P02 | 6m | 2 tasks | 3 files |
| Phase 144 P03 | 6m | 2 tasks | 3 files |
| Phase 144 P04 | 5m | 2 tasks | 3 files |
| Phase 145 P01 | 3m | 3 tasks | 4 files |
| Phase 146 P01 | 2m | 2 tasks | 4 files |
| Phase 146 P03 | 3m | 2 tasks | 4 files |
| Phase 150 P01 | 4m | 1 tasks | 1 files |
| Phase 150 P02 | 7m | 3 tasks | 5 files |
| Phase 152 P01 | 2m | 3 tasks | 2 files |
| Phase 152 P02 | 8m | 2 tasks | 9 files |
| Phase 153 P02 | 5m | 2 tasks | 5 files |

## Accumulated Context

### Key Planning Decisions for v1.47

- **2026-05-30:** ADV-01 (optimistic_lock removal) and ADV-02 (NULL watermark fix) must ship together in Phase 154 — fixing one without the other leaves the concurrent-suppress bug alive. Documented in PITFALLS.md.
- **2026-05-30:** ADV-04 (concurrent test) is mandatory for WR-05 closure — serial tests cannot catch the OCC+upsert interaction. Included in Phase 154 scope.
- **2026-05-30:** Phase 154 plan must include: verify `optimistic_lock` + `on_conflict_where` interaction at Ecto 3.13 before final implementation (minimal repro in scratch test).
- **2026-05-30:** No migration required for any v1.47 phase — `lock_version` column stays in DB; only the changeset call is removed.
- **2026-05-30:** Phases 156, 157, 158 are mutually independent — all depend on Phase 153 (prior milestone close) but not on each other. Can run in any order.
- **2026-05-30:** `write_entitlement_summary/8` becomes `/9` by adding `processor` as final argument (IN-01); the processor atom is already threaded through every level except this final hop.

### Historical Research Assets

- **v1.17 Friction Inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md` — `v1.17-P1-002` closed 2026-04-24; P0/P1/P2 backlog rows (INT-10, BIL-03, ADM-12) tracked as phase 63/64/65 anchors.
- **v1.17 North Star:** `.planning/research/v1.17-north-star.md` — stop rules S1–S5.
- **v1.47 Research:** `.planning/research/SUMMARY.md` + sibling STACK.md / FEATURES.md / ARCHITECTURE.md / PITFALLS.md — HIGH confidence, sourced 2026-05-30.

### Roadmap Evolution

- v1.47 roadmap created 2026-05-30: Phases 154–158

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-05-30:** v1.47 started. Scope: ENT-10 advisory cache correctness (WR-05 + IN-01..04) and three adopter-proof tracks (entitlements/metering/Oban crons in examples/accrue_host).
- **2026-05-28:** Milestone Next-Step Assessment complete for v1.45. Selected Multi-channel Dunning (In-App Banners) to complete the dunning story without adding compliance risks.
- **2026-05-27:** Milestone Next-Step Assessment complete. Accrue is 6 of 6 on the canonical SaaS loop (feature-complete core). v1.44 selected to prove the v1.40 dunning engine's ROI to adopters via the recovered-revenue dashboard.

### Pending Todos

- None open.

### Blockers/Concerns

- None open.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | deferred to `lattice_stripe ≥ 1.2` | 2026-05-22 |
| scope | Multi-channel (SMS/push) dunning via Chimeway | out of scope v1.45; deferred | 2026-05-28 |
| scope | Per-step funnel breakdown in recovery dashboard | out of scope v1.44; deferred to v1.45+ if demanded | 2026-05-27 |
| scope | MRR-at-risk column on at-risk table | out of scope v1.44; requires extracting `calculate_mrr_cents/1` from `DefaultHandler` | 2026-05-27 |
| scope | Compensating-event backfill of pre-v1.44 events without `mrr_value_cents` | out of scope v1.44; cutoff-date label is the v1.44 honest answer | 2026-05-27 |
| scope | Real-time PubSub-driven dashboard refresh | out of scope v1.44; coupled to multi-channel dunning v1.45+ | 2026-05-27 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | carried |
| seed | SEED-002-ecosystem-integrations — Chimeway/Mailglass ecosystem integrations | dormant; carry to v1.47+ | 2026-05-30 |

## Session Continuity

Last session: 2026-05-30
Stopped at: Roadmap created for v1.47 — ready for Phase 154 planning
Resume file: None

## Operator Next Steps

- Run `/gsd:plan-phase 154` to plan Phase 154 (Advisory Cache Core Correctness)
