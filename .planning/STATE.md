---
gsd_state_version: 1.0
milestone: v1.36
milestone_name: Dual-Provider Core Completion
status: active
last_updated: "2026-05-07T15:31:27Z"
last_activity: 2026-05-07
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 5
  completed_plans: 5
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** v1.36 audit closeout complete — Phase 116 restored the final missing verification artifact and the milestone is ready for archival

## Current Position

Milestone: v1.36 — Dual-Provider Core Completion
Phase: 116 — Phase 114 Verification Backfill
Plan: 116-01 complete
Status: Phase 116 complete; v1.36 shipped
Resume file: None
Last activity: 2026-05-07 — restored `114-VERIFICATION.md`, refreshed the v1.36 milestone audit, and closed the remaining `PROC-24` audit gap

## Milestone Progress

**v1.36** (opened **2026-05-06**, shipped **2026-05-07**, audit closeout restored **2026-05-07**): Phases **112**, **113**, **114**, **115**, and **116** are complete. **PROC-21..24** are now represented by verification artifacts, and the milestone is ready for archival.

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
- **2026-05-07:** Promote only immediate cancellation to `all first-party`; keep `cancel_at_period_end` explicitly split because Braintree still does not support it.
- **2026-05-07:** Reject Braintree scheduled-end cancel payloads with typed unsupported guidance instead of degrading them into immediate cancellation.
- **2026-05-07:** Use provider-aware portal branching and shared copy helpers rather than adding new public APIs to express the Braintree immediate-vs-scheduled split.
- **2026-05-07:** Keep Phase 113 closeout proof in the existing matrix verifier and add Braintree-specific UI/doc assertions instead of widening runtime scope.
- **2026-05-07:** Name and document the support-contract bundle in `scripts/ci/README.md` while keeping the existing targeted verifier split.
- **2026-05-07:** Backfill `113-VERIFICATION.md` from shipped Phase 113 summaries plus same-day reruns, and treat audit-closeout phases as narrow evidence repair rather than reopened feature scope.

**Next:** Archive or roll over from `v1.36`; no further verification backfill remains in this milestone.
