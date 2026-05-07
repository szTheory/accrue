---
gsd_state_version: 1.0
milestone: v1.37
milestone_name: Subscription Change Management
status: active
last_updated: "2026-05-07T21:07:30Z"
last_activity: 2026-05-07
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-07)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** `v1.37` is execution-complete; Phase 119 hardened the bounded Braintree plan-swap contract and the milestone is ready for closeout

## Current Position

Milestone: v1.37 — Subscription Change Management
Phase: 119 — Braintree Bounded Plan-Swap Closeout
Plan: Phase complete
Status: Phase 119 execution is complete and all three plans now have summary artifacts and passing verification
Resume file: None
Last activity: 2026-05-07 — executed Phase 119 across runtime, docs, and support-contract verifier lanes; `v1.37` is now ready for milestone completion

## Milestone Progress

**v1.37** (opened **2026-05-07**): Phases **117–119 complete**. **SCM-01..06** now cover the shipped active subscription change management contract across API, admin, portal, docs, and support-contract verifiers.

**v1.36** (opened **2026-05-06**, shipped **2026-05-07**, archived **2026-05-07**): Phases **112**, **113**, **114**, **115**, and **116** are complete. **PROC-21..24** are represented by verification artifacts and archived under **`milestones/v1.36-*`**.

**v1.35** (opened **2026-05-06**, shipped **2026-05-07**): Phases **109–111 complete** — **SUP-01..02**, **LIF-01..02**, **OPS-01..02**; archived in **`milestones/v1.35-ROADMAP.md`**, **`milestones/v1.35-REQUIREMENTS.md`**, and **`milestones/v1.35-phases/`**.

**v1.34** (opened **2026-05-06**, shipped **2026-05-06**): Phases **106–108 complete** — **PDF-01..PDF-09**; archived in **`milestones/v1.34-ROADMAP.md`**, **`milestones/v1.34-REQUIREMENTS.md`**, and **`milestones/v1.34-phases/`**.

**v1.33** (shipped **2026-05-06**): Phases **101–104 complete** — **BT-01..BT-09**; archived under **`milestones/v1.33-*`** and **`milestones/v1.33-phases/`**.

## Current Planning Artifacts

- **`.planning/STRATEGY.md`** — active PROC-08 strategic parent.
- **`.planning/ROADMAP.md`** — active `v1.37` roadmap for Phases 117–119.
- **`.planning/REQUIREMENTS.md`** — active `v1.37` requirements for `SCM-01..06`.
- **`.planning/milestones/v1.36-ROADMAP.md`** — archived roadmap and milestone narrative for Phases 112–116.
- **`.planning/milestones/v1.36-REQUIREMENTS.md`** — archived requirements and traceability for `PROC-21..24`.
- **`.planning/STRATEGY.md`** — active PROC-08 strategic parent for future milestone selection.
- **`.planning/research/STACK.md`** — most recent closure-milestone stack/integration research.
- **`.planning/research/FEATURES.md`** — most recent closure-milestone feature framing.
- **`.planning/research/ARCHITECTURE.md`** — most recent closure-milestone build-order guidance.
- **`.planning/research/PITFALLS.md`** — most recent contract-drift and proof-lane risk notes.
- **`.planning/research/SUMMARY.md`** — most recent synthesized research summary.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| processor_scope | Schedule management / pause-resume expansion beyond active subscription change | deferred beyond v1.37 |
| processor_scope | Braintree quantity and subscription-item parity | explicitly unsupported for this milestone |
| strategy_non_goal | FIN-03 finance exports | explicit non-goal |
| strategy_non_goal | Hyperwallet reopening | explicit non-goal |

## Recent Decisions

- **2026-05-07:** Open **v1.37** as an adopter-facing subscription-depth milestone, not a release-ops or broad lifecycle-expansion pass.
- **2026-05-07:** Promote the active subscription-change bundle (`swap_plan/3`, `preview_upcoming_invoice/2`, quantity/item changes where supported) as the next confidence and batteries-included gap to close.
- **2026-05-07:** Keep the contract provider-honest: full depth on Stripe/Fake, bounded Braintree plan-swap support through `:plan_resolver`, and explicit unsupported guidance for quantity/item semantics.
- **2026-05-07:** Require API, admin, and portal surfaces to ship the same subscription-change story within this milestone instead of treating UI as optional follow-on work.
- **2026-05-06:** Open **v1.36** as a closure milestone, not another broad supportability pass.
- **2026-05-06:** Treat `Accrue.Billing.update_customer/2` and the cancellation family as the remaining visible staged rows in the official dual-provider contract.
- **2026-05-06:** Keep advanced scheduling, preview/proration parity, Hyperwallet reopening, and new processor breadth out of scope.
- **2026-05-07:** Promote only immediate cancellation to `all first-party`; keep `cancel_at_period_end` explicitly split because Braintree still does not support it.
- **2026-05-07:** Reject Braintree scheduled-end cancel payloads with typed unsupported guidance instead of degrading them into immediate cancellation.
- **2026-05-07:** Use provider-aware portal branching and shared copy helpers rather than adding new public APIs to express the Braintree immediate-vs-scheduled split.
- **2026-05-07:** Keep Phase 113 closeout proof in the existing matrix verifier and add Braintree-specific UI/doc assertions instead of widening runtime scope.
- **2026-05-07:** Name and document the support-contract bundle in `scripts/ci/README.md` while keeping the existing targeted verifier split.
- **2026-05-07:** Backfill `113-VERIFICATION.md` from shipped Phase 113 summaries plus same-day reruns, and treat audit-closeout phases as narrow evidence repair rather than reopened feature scope.

**Next:** Run milestone closeout/archive flow for `v1.37`; execution is complete and the active subscription change milestone is ready to ship/retire.
