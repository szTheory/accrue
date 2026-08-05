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
- ◆ **v1.60 First-Adopter iOS Bridge & Proof** — Phases 223-226 (active)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

v1.60 clears that bar through an active first-adopter iOS delivery. It reuses the v1.59 Apple/offline contract, keeps StoreKit binding host-owned, and cannot promote Crosswake runtime capability without its separate physical-device proof. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

### v1.60 First-Adopter iOS Bridge & Proof

- [ ] **Phase 223: iOS-compatible Accrue offline client** — Extract the verified tracer into a reusable SwiftPM module, retain canonical vectors, and prove iOS compilation/cache semantics. Covers IOS-01..03.
- [ ] **Phase 224: Crosswake host-command bridge seam** — Add a manifest- and route-scoped host delegate behind the existing safe bridge validation boundary. Covers BRDG-01..02.
- [ ] **Phase 225: First-adopter host StoreKit adapter** — Implement the host-local StoreKit 2, Apple-evidence, proof, and reconnect integration plus StoreKit Test evidence. Covers HOST-01..03.
- [ ] **Phase 226: Readiness truth and external-gate handoff** — Remove retained warnings, refresh public/release truth, execute available advisory checks, and preserve device-gated status. Covers READY-01..02.

**Dependency shape:** 223 → 225; 224 → 225; 225 → 226. Phase 226 never claims runtime proof until the separately authorized physical-iPhone artifact exists.

### Phase 223: iOS-compatible Accrue offline client

**Goal**: Extract the verified Crosswake tracer foundation into an iOS-compatible, reusable SwiftPM offline client while retaining canonical ES256 verification, device binding, high-water and signed-deny ordering, verified atomic cache replacement, and an honest iOS compilation boundary.

**Depends on**: Nothing (first phase of v1.60; reuses the locked v1.59 offline-entitlements contract)

**Requirements**: IOS-01, IOS-02, IOS-03

**Success Criteria** (what must be TRUE):

1. A host can import the standalone iOS-compatible SwiftPM client and obtain canonical-vector-conformant proof verification, high-water ordering, and allow/deny cache replacement.
2. The public client exposes a narrow immutable `Sendable` four-state result boundary; only verified server ES256 proof bound to the registered device can replace cached state, and stale continuity never becomes a local grant.
3. A host-owned authenticated reconnect path feeds compact proof bytes through the same private verification and verified atomic replacement boundary; cache write or recovery failures preserve the previous complete authenticated cache.
4. Public-package tests exercise the canonical corpus, malformed input, rotation, high-water/deny ordering, and crash/recovery behavior; an iOS 16 SDK library-compilation lane is merge-blocking while Crosswake/device feasibility remains separately classified.
5. StoreKit, purchase/restore behavior, host authentication, host UI, Crosswake bridge APIs, simulator evidence, and physical-device runtime proof remain out of scope and cannot be promoted by package test or compile success.

**Plans**: 0/0 plans executed

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
