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
- ✅ **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212-214.2 (shipped 2026-07-31) — [archive](milestones/v1.58-ROADMAP.md)
- ✅ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215-222 (shipped 2026-08-05) — [archive](milestones/v1.59-ROADMAP.md)
- ⏸️ **v1.60 First-Adopter iOS Bridge & Proof** — Phases 223-224 verified; remaining scope deferred by override closeout (2026-08-08) — [archive](milestones/v1.60-ROADMAP.md)
- ✅ **v1.61 CI Evidence & Critical-Path Hardening** — Phases 225-228 (shipped 2026-09-12) — [archive](milestones/v1.61-ROADMAP.md)
- ✅ **v1.62 Release Integration & Repository Hygiene** — Phases 229-232 (shipped 2026-09-18) — [archive](milestones/v1.62-ROADMAP.md)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work must be explicitly re-scoped by a future milestone before execution. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Open Release Handoff (carried out of v1.62)

v1.62 delivered a **reviewable, per-lane-proved** release candidate, not a green one. The candidate SHA is honestly recorded red on `docs-contracts-shift-left`, `release-gate`, and `phase18-tax-gate`; the fixes exist on the milestone line. The written path forward: push the phase-close commits, re-run CI at the new head, confirm the gates, merge PR #45, then run Release Please. See [v1.62 audit](milestones/v1.62-MILESTONE-AUDIT.md).

## Phases

<details>
<summary>✅ v1.62 Release Integration & Repository Hygiene (Phases 229-232) — SHIPPED 2026-09-18</summary>

- [x] Phase 229: Repository Truth & Recovery Safety (20/20 plans) — completed 2026-09-15
- [x] Phase 230: Reviewable History Integration (7/7 plans) — completed 2026-09-15
- [x] Phase 231: Exact-SHA Release Gate Proof (6/6 plans) — completed 2026-09-16
- [x] Phase 232: Bounded Hygiene & Release Handoff (11/11 plans) — completed 2026-09-17

Full history: [v1.62 roadmap archive](milestones/v1.62-ROADMAP.md).

</details>

<details>
<summary>✅ v1.61 CI Evidence & Critical-Path Hardening (Phases 225-228) — SHIPPED 2026-09-12</summary>

- [x] Phase 225: Required-Lane Signal Repair (3/3 plans)
- [x] Phase 226: CI Baseline & Proof Semantics (17/17 plans)
- [x] Phase 227: Measured Critical-Path Improvement (7/7 plans)
- [x] Phase 228: Stripe Webhook-Signing CI Boot Contract (3/3 plans)

Full history: [v1.61 roadmap archive](milestones/v1.61-ROADMAP.md).

</details>
