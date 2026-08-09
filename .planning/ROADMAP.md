# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass** — Phases 174-179 (shipped 2026-06-04) — [archive](milestones/v1.51-ROADMAP.md)
- ✅ **v1.52 Brand System** — Phases 180-186 (shipped 2026-06-14) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187-192 (shipped 2026-06-20) — [archive](milestones/v1.53-ROADMAP.md)
- ✅ **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193-200 (shipped 2026-07-01) — [archive](milestones/v1.54-ROADMAP.md)
- ✅ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201-204 (shipped 2026-07-03) — [archive](milestones/v1.55-ROADMAP.md)
- ⏸️ **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205-208 (parked 2026-07-19) — [archive](milestones/v1.56-ROADMAP.md)
- ✅ **v1.57 Admin Operator Control Plane (SEED-004 M1)** — Phases 209-211 (shipped 2026-07-30) — [archive](milestones/v1.57-ROADMAP.md)
- ✅ **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212-214.2 (shipped 2026-07-31; 11/11 requirements and 5/5 flows passed with documented non-blocking tech debt) — [archive](milestones/v1.58-ROADMAP.md)
- ✅ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215-222 (shipped 2026-08-05; 29/29 requirements, 11/11 integration links, and 5/5 E2E flows passed) — [archive](milestones/v1.59-ROADMAP.md)
- ⏸️ **v1.60 First-Adopter iOS Bridge & Proof** — override closeout 2026-08-08; Phases 223-224 verified, Phases 225-226 deferred — [archive](milestones/v1.60-ROADMAP.md)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

v1.60 clears that bar through an active first-adopter iOS delivery. It reuses the v1.59 Apple/offline contract, keeps StoreKit binding host-owned, and cannot promote Crosswake runtime capability without its separate physical-device proof. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

Completed and deferred v1.60 details are retained in [the milestone archive](milestones/v1.60-ROADMAP.md). A future milestone must explicitly re-scope the deferred StoreKit and readiness work.

<details>
<summary>✅ v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync (Phases 212-214.2) — SHIPPED 2026-07-31</summary>

- [x] Phase 212: lattice_stripe 2.x bump & green reconciliation (1/1 plan)
- [x] Phase 213: Stripe-native advisory entitlements sync (5/5 plans)
- [x] Phase 214: Docs & truth reconciliation (3/3 plans)
- [x] Phase 214.1: DOCS-03 writer-documentation gap closure (4/4 plans)
- [x] Phase 214.2: Diagnostic-display and pagination gap closure (4/4 plans)

Full history: [v1.58 roadmap archive](milestones/v1.58-ROADMAP.md).

</details>

Completed milestone detail is archived in [v1.59-ROADMAP.md](milestones/v1.59-ROADMAP.md).
