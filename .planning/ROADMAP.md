# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154–158 (2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159–162 (2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163–166 (2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167–173 (2026-06-02) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass** — Phases 174–179 (2026-06-04) — [archive](milestones/v1.51-ROADMAP.md)
- ✅ **v1.52 Brand System** — Phases 180–186 (2026-06-14) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187–192 (2026-06-20) — [archive](milestones/v1.53-ROADMAP.md)
- ✅ **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193–200 (2026-07-01) — [archive](milestones/v1.54-ROADMAP.md)
- ✅ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201–204 (2026-07-03) — [archive](milestones/v1.55-ROADMAP.md)
- ⏸️ **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205–208 (parked 2026-07-19) — [archive](milestones/v1.56-ROADMAP.md)
- ✅ **v1.57 Admin Operator Control Plane (SEED-004 M1)** — Phases 209–211 (2026-07-30) — [archive](milestones/v1.57-ROADMAP.md)
- ✅ **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212–214.2 (2026-07-31) — [archive](milestones/v1.58-ROADMAP.md)
- ✅ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215–222 (2026-08-05) — [archive](milestones/v1.59-ROADMAP.md)
- ⏸️ **v1.60 First-Adopter iOS Bridge & Proof** — Phases 223–224 verified; remaining scope deferred (2026-08-08) — [archive](milestones/v1.60-ROADMAP.md)
- ✅ **v1.61 CI Evidence & Critical-Path Hardening** — Phases 225–228 (2026-09-12) — [archive](milestones/v1.61-ROADMAP.md)
- ✅ **v1.62 Release Integration & Repository Hygiene** — Phases 229–232 (2026-09-18) — [archive](milestones/v1.62-ROADMAP.md)
- ✅ **v1.63 Admin and Portal UI refinement** — Phases 233–239 (shipped 2026-10-09) — [archive](milestones/v1.63-ROADMAP.md)
- ✅ **v1.64 Admin Operator UI Cleanup** — Phases 240–243 (shipped 2026-10-10) — [archive](milestones/v1.64-ROADMAP.md)
- 🚧 **v1.65 Accrue Admin Language & Consistency** — Phase 244 (planned)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction anchors remain in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md). Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work require an explicit future scope decision; Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## v1.65 — Accrue Admin Language & Consistency

**Goal:** Support and billing operators can understand what happened and what to do next on targeted existing Admin screens, while exact technical evidence remains available for investigation.

**Scope:** Correct copy and repeated patterns only where current rendered Admin output confirms an issue. Home recent activity is an initial candidate, not a preapproved edit. Keep completed, failed, blocked, and unknown outcomes distinct. Use existing `AccrueAdmin.Copy`, LiveView, and browser test owners for recurring proof. No new billing capability, Portal work, diagnosis functions, new Admin rooms, redesign, rebrand, blanket banned-word rule, or new test/CI lane.

## Phases

- [ ] **Phase 244: Operator Language and Evidence** - Make confirmed Admin labels, outcomes, next steps, and repeated controls clear and consistent while preserving investigation details.

## Phase Details

### Phase 244: Operator Language and Evidence

**Goal**: Operators can understand the activity, state, outcome, and supported next action on targeted existing Admin screens without losing exact investigation evidence.
**Depends on**: Phase 243 (shipped v1.64 Admin baseline)
**Requirements**: LANG-01, STATE-01, EVID-01, CONS-01
**Success Criteria** (what must be TRUE):
  1. On each targeted existing Admin screen, an operator can read the primary activity or state label in operator-facing language that matches the underlying event or state, without decoding an implementation key. (LANG-01)
  2. For targeted completed, failed, blocked, and unknown outcomes, an operator can tell what the available evidence confirms, whether the requested action took effect, and which supported next step is available, without being shown an invented cause. (STATE-01)
  3. Where a human-readable event or state label appears, an operator can still find the exact event key and relevant record identifiers and timestamps at the point of investigation. (EVID-01)
  4. Across targeted existing Admin screens, an operator encounters consistent repeated headings and action names, and each link or control accurately describes its destination or effect. (CONS-01)

**Plans**: 3/3 plans executed
Plans:
**Wave 1**
- [x] 244-01-PLAN.md — Confirm mounted candidates and prove Home-to-event label and evidence path.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 244-02-PLAN.md — Carry shared meaning and exact evidence through event and related activity views.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 244-03-PLAN.md — Bind outcome and recovery language to durable facts and confirm rendered effects.

**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 244. Operator Language and Evidence | 3/3 | In Progress | - |

## Current Position

v1.65 is ready to plan at Phase 244. All 4/4 approved v1 requirements map to this phase. The complete v1.64 scope and closeout evidence remain in the [archived roadmap](milestones/v1.64-ROADMAP.md), [milestone audit](milestones/v1.64-MILESTONE-AUDIT.md), and [phase archive](milestones/v1.64-phases/).

**Next command:** `$gsd-plan-phase 244`.
