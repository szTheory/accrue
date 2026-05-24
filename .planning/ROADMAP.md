# Roadmap: Accrue

## Active Milestone

**None.** 🎉 **v1.39 — Entitlements / Plan-Gating** shipped & archived **2026-05-24** (Phases 123–127, ENT-01..12, planning tag `v1.39`). The canonical six-step SaaS loop is now complete. Plan the next milestone with `/gsd:new-milestone` — **dunning depth / notification journeys** (JTBD #2) is the leading candidate.

## Milestones

- ✅ **v1.39 — Entitlements / Plan-Gating** — Phases 123–127 (shipped 2026-05-24)
- ✅ **v1.38 — Linked Release Truth** — Phases 120–122 (shipped 2026-05-08)
- ✅ **v1.37 — Subscription Change Management** — Phases 117–119 (shipped 2026-05-07)
- ✅ **v1.36 — Dual-Provider Core Completion** — Phases 112–116 (shipped 2026-05-07)
- ✅ **v1.35 — Dual-Provider Supportability Closure** — Phases 109–111 (shipped 2026-05-07)

## Phases

<details>
<summary>✅ v1.39 — Entitlements / Plan-Gating (Phases 123–127) — SHIPPED 2026-05-24</summary>

- [x] Phase 123: Config + Core Gate API Foundation (4/4 plans) — completed 2026-05-22
- [x] Phase 124: Enforcement Surfaces — Plug + LiveView Guards (6/6 plans) — completed 2026-05-23
- [x] Phase 125: Provider Honesty + Lifecycle Truth (3/3 plans) — completed 2026-05-23
- [x] Phase 126: Admin Surface + Docs / JTBD Spine (4/4 plans) — completed 2026-05-23
- [x] Phase 127: Optional Stripe-Native Sync (isolated, off by default) (4/4 plans) — completed 2026-05-24

Full detail: [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md) · requirements [milestones/v1.39-REQUIREMENTS.md](milestones/v1.39-REQUIREMENTS.md) · audit `.planning/v1.39-v1.39-MILESTONE-AUDIT.md`.

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 123. Config + Core Gate API Foundation | v1.39 | 4/4 | Complete | 2026-05-22 |
| 124. Enforcement Surfaces — Plug + LiveView Guards | v1.39 | 6/6 | Complete | 2026-05-23 |
| 125. Provider Honesty + Lifecycle Truth | v1.39 | 3/3 | Complete | 2026-05-23 |
| 126. Admin Surface + Docs / JTBD Spine | v1.39 | 4/4 | Complete | 2026-05-23 |
| 127. Optional Stripe-Native Sync (isolated) | v1.39 | 4/4 | Complete | 2026-05-24 |

## Notes

- **Canonical SaaS loop complete:** v1.39 (entitlements) closed the last open step of *bill → change/cancel → recover failed payments → self-serve → **gate access** → operate with an audit trail*. Five of six were shipped pre-v1.39; entitlements was the sixth.
- **Milestone audit:** `tech_debt` — DoD achieved, zero blockers, 12/12 requirements satisfied, 5/5 phases `passed`, integration 9.5/10, 3/3 E2E flows. Deferred (non-blocking): the ENT-10 advisory-cache follow-ups (`.planning/todos/pending/2026-05-24-ent10-advisory-cache-followups.md`) and partial Nyquist coverage on Phases 123–125 (`/gsd:validate-phase` to close).
- **Standing non-goals (unchanged):** rich metered/tiered entitlement math beyond seat counts; atomic seat enforcement / membership management; feature-catalog authoring UI; deep Sigra/Lockspire coupling; dunning notification journeys (next-milestone candidate); FIN-03 finance exports, MRR/ARR product, MoR processors, Hyperwallet.

## Recent Milestones

- ✅ **v1.39 Entitlements / Plan-Gating** — Phases **123–127** shipped **2026-05-24**. Closed the canonical SaaS loop's last step: first-party, local-first, fail-closed plan/feature gating with no new tables and no Stripe dependency on the gate path (`Accrue.has_active_plan?`/`entitled?`/`features_for`/`entitlement_quantity`), a Plug guard + cond-compiled LiveView `on_mount` guard (core stays runtime-LiveView-free), a provider-honest Resolver + capability matrix, a lifecycle→entitlement truth-table SSOT, a read-only admin entitlements tab, the `guides/entitlements.md` spine + JTBD ⛔→✅ flip, and an isolated off-by-default Stripe-native advisory-sync overlay. Archives: [milestones/v1.39-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.39-ROADMAP.md), [milestones/v1.39-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.39-REQUIREMENTS.md).
- ✅ **v1.38 Linked Release Truth** — Phases **120–122** shipped **2026-05-08**. Locked the three-package release contract, published the linked `1.1.1` trio with canonical proof in `121-VERIFICATION.md`, and finalized the maintainer-facing planning closeout plus `INV-08` certification in `122-VERIFICATION.md`.
- ✅ **v1.37 Subscription Change Management** — Phases **117–119** shipped **2026-05-07**. Promoted official swap/preview semantics, shipped admin and portal change flows, and finalized bounded Braintree `:plan_resolver` support plus drift gates. Archives: [milestones/v1.37-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-ROADMAP.md), [milestones/v1.37-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-REQUIREMENTS.md).
- ✅ **v1.36 Dual-Provider Core Completion** — Phases **112–116** shipped **2026-05-07**. Promoted bounded first-party customer update, normalized provider-honest cancellation semantics, locked the support-contract verifier bundle, and restored the audit-required verification chain. Archives: [milestones/v1.36-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-ROADMAP.md), [milestones/v1.36-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-REQUIREMENTS.md).
- ✅ **v1.35 Dual-Provider Supportability Closure** — Phases **109–111** shipped **2026-05-07**. Provider-honest support contract mirrors, lifecycle semantics SSOT, and Braintree webhook/operator recovery proof. Archives: [milestones/v1.35-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-REQUIREMENTS.md).

---
*Last updated: 2026-05-24 — v1.39 shipped & archived (Phases 123–127, ENT-01..12); ROADMAP collapsed to milestone grouping, full detail in [milestones/v1.39-ROADMAP.md](milestones/v1.39-ROADMAP.md).*
