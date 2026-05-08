---
gsd_state_version: 1.0
milestone: v1.38
milestone_name: Linked Release Truth
status: shipped
last_updated: "2026-05-08T14:15:25Z"
last_activity: 2026-05-08
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

**Current focus:** `v1.38` shipped closeout. Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).

## Current Position

Milestone: v1.38 — Linked Release Truth
Phase: None
Plan: None
Status: v1.38 shipped; live planning mirrors and INV-08 closeout are complete
Resume file: None
Last activity: 2026-05-08 — finalized the shipped `1.1.1` trio planning mirrors, recorded INV-08, and closed the live `v1.38` state

## Milestone Progress

**v1.38** (opened **2026-05-07**, shipped **2026-05-08**): Phases **120**, **121**, and **122** are complete. The public `1.1.1` trio proof is recorded in **`121-VERIFICATION.md`**, and the final planning closeout plus dated `INV-08` certification are recorded in **`122-VERIFICATION.md`**.

**v1.37** (opened **2026-05-07**, shipped **2026-05-07**, archived **2026-05-07**): Phases **117**, **118**, and **119** are complete. **SCM-01..06** are archived under **`milestones/v1.37-*`** and **`milestones/v1.37-phases/`**.

**v1.36** (opened **2026-05-06**, shipped **2026-05-07**, archived **2026-05-07**): Phases **112**, **113**, **114**, **115**, and **116** are complete. **PROC-21..24** are represented by verification artifacts and archived under **`milestones/v1.36-*`**.

**v1.35** (opened **2026-05-06**, shipped **2026-05-07**): Phases **109–111 complete** — **SUP-01..02**, **LIF-01..02**, **OPS-01..02**; archived in **`milestones/v1.35-ROADMAP.md`**, **`milestones/v1.35-REQUIREMENTS.md`**, and **`milestones/v1.35-phases/`**.

**v1.34** (opened **2026-05-06**, shipped **2026-05-06**): Phases **106–108 complete** — **PDF-01..PDF-09**; archived in **`milestones/v1.34-ROADMAP.md`**, **`milestones/v1.34-REQUIREMENTS.md`**, and **`milestones/v1.34-phases/`**.

**v1.33** (shipped **2026-05-06**): Phases **101–104 complete** — **BT-01..BT-09**; archived under **`milestones/v1.33-*`** and **`milestones/v1.33-phases/`**.

## Current Planning Artifacts

- **`.planning/STRATEGY.md`** — active PROC-08 strategic parent.
- **`.planning/ROADMAP.md`** — no-active-milestone summary after the shipped `v1.38` closeout.
- **`.planning/REQUIREMENTS.md`** — `v1.38` requirements and traceability, with Phase 122 closeout rows complete.
- **`.planning/research/v1.17-FRICTION-INVENTORY.md`** — canonical friction inventory for intake-gated maintenance and dated maintainer passes.
- **`.planning/research/v1.17-north-star.md`** — stop-rule and maintenance-triage SSOT for the library-maintenance posture.
- **`.planning/phases/120-release-contract-audit/120-RESEARCH.md`** — Phase 120 research on release-scope drift, publish order truth, and recovery-path gaps.
- **`.planning/phases/120-release-contract-audit/120-PATTERNS.md`** — Phase 120 analog map for runbook, workflow, and shell-verifier edits.
- **`.planning/phases/120-release-contract-audit/120-VALIDATION.md`** — Phase 120 Nyquist validation contract for the three-plan sequence.
- **`.planning/phases/120-release-contract-audit/120-01-SUMMARY.md`** — release-scope decision token and evidence.
- **`.planning/phases/120-release-contract-audit/120-02-SUMMARY.md`** — runbook/workflow alignment summary.
- **`.planning/phases/120-release-contract-audit/120-03-SUMMARY.md`** — verifier and CI wiring summary.
- **`.planning/phases/120-release-contract-audit/120-VERIFICATION.md`** — Phase 120 verification report.
- **`.planning/phases/120-release-contract-audit/120-01-PLAN.md`** — blocking scope-decision plan.
- **`.planning/phases/120-release-contract-audit/120-02-PLAN.md`** — contract alignment plan across docs, config, manifest, and workflows.
- **`.planning/phases/120-release-contract-audit/120-03-PLAN.md`** — release-contract verifier and CI enforcement plan.
- **`.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`** — canonical public proof for PR **23**, version **1.1.1**, and run **25554198977**.
- **`.planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md`** — final maintainer closeout ledger for HYG-03 and INV-08.
- **`.planning/milestones/v1.37-ROADMAP.md`** — archived roadmap and milestone narrative for Phases 117–119.
- **`.planning/milestones/v1.37-REQUIREMENTS.md`** — archived requirements and traceability for `SCM-01..06`.
- **`.planning/milestones/v1.36-ROADMAP.md`** — archived roadmap and milestone narrative for Phases 112–116.
- **`.planning/milestones/v1.36-REQUIREMENTS.md`** — archived requirements and traceability for `PROC-21..24`.
- **`.planning/STRATEGY.md`** — active PROC-08 strategic parent for future milestone selection.
- **`.planning/research/STACK.md`** — most recent closure-milestone stack/integration research.
- **`.planning/research/FEATURES.md`** — most recent closure-milestone feature framing.
- **`.planning/research/ARCHITECTURE.md`** — most recent closure-milestone build-order guidance.
- **`.planning/research/PITFALLS.md`** — most recent contract-drift and proof-lane risk notes.
- **`.planning/research/SUMMARY.md`** — most recent synthesized research summary.

**Triage doctrine (read-only context, v1.17–v1.18):** [North star + stop rules](research/v1.17-north-star.md) · [Friction inventory](research/v1.17-FRICTION-INVENTORY.md)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| process_gap | Dedicated `v1.37` milestone audit artifact | accepted prior-milestone gap; not reopened unless needed for release truth |
| strategy_non_goal | FIN-03 finance exports | explicit non-goal |
| strategy_non_goal | Hyperwallet reopening | explicit non-goal |

## Recent Decisions

- **2026-05-07:** Open **v1.38** as a release-continuity milestone, not another feature-depth or strategy-expansion pass.
- **2026-05-07:** Prioritize public release truth over new feature work because developer trust depends on published package reality matching the code and docs story.
- **2026-05-07:** Treat the linked package-set ambiguity around `accrue_portal` as a release-contract problem to resolve explicitly before or during the next publish.
- **2026-05-07:** Plan Phase 120 as a three-step execution chain: explicit release-scope decision first, contract-surface alignment second, and merge-blocking verifier enforcement third.
- **2026-05-07:** Resolve the release-scope decision as `promote-three-package`; `accrue_portal` is part of the public linked release contract and must be reflected in maintainer docs, recovery workflows, and CI verifiers.
- **2026-05-07:** Clear stale active phase directories before roadmapping the next milestone so the new planning state starts cleanly.
- **2026-05-08:** Ship the linked `1.1.1` trio with canonical proof bound to PR **23** and run **25554198977**, then keep Phase 122 narrowly focused on live planning closeout rather than replaying release evidence.
- **2026-05-08:** Record `INV-08` on path `(b)` because the `1.1.0` failure and `1.1.1` recovery remain release-proof history, not a new sourced downstream friction row.
- **2026-05-06:** Open **v1.36** as a closure milestone, not another broad supportability pass.
- **2026-05-06:** Treat `Accrue.Billing.update_customer/2` and the cancellation family as the remaining visible staged rows in the official dual-provider contract.
- **2026-05-06:** Keep advanced scheduling, preview/proration parity, Hyperwallet reopening, and new processor breadth out of scope.
- **2026-05-07:** Promote only immediate cancellation to `all first-party`; keep `cancel_at_period_end` explicitly split because Braintree still does not support it.
- **2026-05-07:** Reject Braintree scheduled-end cancel payloads with typed unsupported guidance instead of degrading them into immediate cancellation.
- **2026-05-07:** Use provider-aware portal branching and shared copy helpers rather than adding new public APIs to express the Braintree immediate-vs-scheduled split.
- **2026-05-07:** Keep Phase 113 closeout proof in the existing matrix verifier and add Braintree-specific UI/doc assertions instead of widening runtime scope.
- **2026-05-07:** Name and document the support-contract bundle in `scripts/ci/README.md` while keeping the existing targeted verifier split.
- **2026-05-07:** Backfill `113-VERIFICATION.md` from shipped Phase 113 summaries plus same-day reruns, and treat audit-closeout phases as narrow evidence repair rather than reopened feature scope.

**Next:** Start the next milestone with `$gsd-new-milestone`.
