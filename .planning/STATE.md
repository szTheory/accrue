---
gsd_state_version: 1.0
milestone: v1.36
milestone_name: Dual-Provider Core Completion
status: planning
last_updated: "2026-05-06T12:00:00Z"
last_activity: 2026-05-06
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** v1.36 planning — close the remaining staged rows in the Stripe + Braintree dual-provider core contract

## Current Position

Milestone: v1.36 — Dual-Provider Core Completion
Phase: Not started
Plan: —
Status: Requirements and roadmap defined
Resume file: `.planning/ROADMAP.md`
Last activity: 2026-05-06 — opened v1.36, completed focused brownfield research, defined requirements PROC-21..24, and created a three-phase roadmap starting at Phase 112

## Milestone Progress

**v1.36** (opened **2026-05-06**): Phases **112–114 planned** — **PROC-21..24**. Focus: promote shipped customer-update and cancellation rows from staged contract leftovers to fully aligned first-party support, then lock the result across docs and verifier gates.

**v1.35** (opened **2026-05-06**, shipped **2026-05-07**): Phases **109–111 complete** — **SUP-01..02**, **LIF-01..02**, **OPS-01..02**; archived in **`milestones/v1.35-ROADMAP.md`**, **`milestones/v1.35-REQUIREMENTS.md`**, and **`milestones/v1.35-phases/`**.

**v1.34** (opened **2026-05-06**, shipped **2026-05-06**): Phases **106–108 complete** — **PDF-01..PDF-09**; archived in **`milestones/v1.34-ROADMAP.md`**, **`milestones/v1.34-REQUIREMENTS.md`**, and **`milestones/v1.34-phases/`**.

**v1.33** (shipped **2026-05-06**): Phases **101–104 complete** — **BT-01..BT-09**; archived under **`milestones/v1.33-*`** and **`milestones/v1.33-phases/`**.

## Current Planning Artifacts

- **`.planning/STRATEGY.md`** — active PROC-08 strategic parent.
- **`.planning/research/STACK.md`** — focused stack/integration research for v1.36.
- **`.planning/research/FEATURES.md`** — scoped feature and non-feature framing for v1.36.
- **`.planning/research/ARCHITECTURE.md`** — architecture and build-order guidance for the closure milestone.
- **`.planning/research/PITFALLS.md`** — contract-drift and proof-lane risks for v1.36.
- **`.planning/research/SUMMARY.md`** — synthesized research summary for the active milestone.
- **`.planning/REQUIREMENTS.md`** — active requirements PROC-21..24.
- **`.planning/ROADMAP.md`** — active roadmap for Phases 112–114.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| processor_scope | Scheduling / preview / broader lifecycle parity | deferred beyond v1.36 |
| strategy_non_goal | FIN-03 finance exports | explicit non-goal |
| strategy_non_goal | Hyperwallet reopening | explicit non-goal |

## Recent Decisions

- **2026-05-06:** Open **v1.36** as a closure milestone, not another broad supportability pass.
- **2026-05-06:** Treat `Accrue.Billing.update_customer/2` and the cancellation family as the remaining visible staged rows in the official dual-provider contract.
- **2026-05-06:** Keep advanced scheduling, preview/proration parity, Hyperwallet reopening, and new processor breadth out of scope.

**Next:** Start execution with `$gsd-plan-phase 112`.
