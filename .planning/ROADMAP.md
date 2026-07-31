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
- ⏭️ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215-219 (queued; Stripe + Apple account union, provider-honest lifecycle management, signed offline lease, and B2C Alpha proof)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

v1.59 clears that bar through B2C Alpha's sourced need for coherent Stripe/Apple access and extended offline use. Google Play remains dormant in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

<details>
<summary>✅ v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync (Phases 212-214.2) — SHIPPED 2026-07-31</summary>

- [x] Phase 212: lattice_stripe 2.x bump & green reconciliation (1/1 plan)
- [x] Phase 213: Stripe-native advisory entitlements sync (5/5 plans)
- [x] Phase 214: Docs & truth reconciliation (3/3 plans)
- [x] Phase 214.1: DOCS-03 writer-documentation gap closure (4/4 plans)
- [x] Phase 214.2: Diagnostic-display and pagination gap closure (4/4 plans)

Full history: [v1.58 roadmap archive](milestones/v1.58-ROADMAP.md).

</details>

### ⏭️ v1.59 Account-Scoped Multi-Rail & Offline Entitlements (Queued)

**Goal:** Preserve one account's access across Stripe web billing, Apple in-app purchase, and extended offline use through a common entitlement projection and signed, time-bounded offline lease, while keeping lifecycle operations rail-aware.

- [ ] **Phase 215: Multi-rail contract and additive data foundation** — Concurrent Stripe/Apple rail registration, logical product mapping, stable account/grant/device persistence, and a dedicated entitlement-source capability matrix (RAIL-01..04).
- [ ] **Phase 216: Canonical account projection and gateway compatibility** — Union/dedup effective access, source-local revocation, rail-aware lifecycle dispatch, and backward-compatible single-processor behavior (ACCT-01..04).
- [ ] **Phase 217: Apple observation rail and automatic linking** — `appAccountToken` linking, signed evidence verification, idempotent convergence, reconciliation, and honest management boundaries (AAPL-01..05).
- [ ] **Phase 218: Signed offline lease and reconnect protocol** — ES256 offline lease, 30-day freshness, signed 72-hour degraded window, hard expiry, atomic reconnect, and device/key security (OFF-01..06).
- [ ] **Phase 219: B2C Alpha proof, operations, docs, and release gates** — Cross-rail adopter proof, offline/revocation/key-rotation scenarios, operator diagnostics, repair runbooks, and public contract alignment (PROOF-01..05).

Dependencies: 215 → 216 → 217 → 218 → 219. The archived v1.58 requirements file also preserves the queued v1.59 requirement draft for `$gsd-new-milestone` review.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---:|---|---|
| 212. lattice_stripe 2.x bump | v1.58 | 1/1 | Complete | 2026-07-30 |
| 213. Advisory entitlements sync | v1.58 | 5/5 | Complete | 2026-07-31 |
| 214. Docs reconciliation | v1.58 | 3/3 | Complete | 2026-07-31 |
| 214.1. Writer-documentation closure | v1.58 | 4/4 | Complete | 2026-07-31 |
| 214.2. Diagnostic-display/pagination closure | v1.58 | 4/4 | Complete | 2026-07-31 |
| 215-219. Multi-rail/offline entitlements | v1.59 | 0/TBD | Queued | - |
