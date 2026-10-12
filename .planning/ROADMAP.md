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
- ✅ **v1.65 Accrue Admin Language & Consistency** — Phase 244 (completed 2026-10-11) — [archive](milestones/v1.65-ROADMAP.md)
- 🚧 **v1.66 Admin Usability and Visual Consistency** — Phases 245–248

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction anchors remain in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md). Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work require an explicit future scope decision; Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Current Position

v1.66 has completed Phases 245–247 and is continuing into Phase 248. The owner-approved scope covers existing Admin routes and necessary evaluation-host tooling. Phase 244 remains archived with v1.65.

## v1.66 — Admin Usability and Visual Consistency

**Goal:** Existing Admin journeys are intentional, understandable and consistent, with realistic evaluation data and revision-bound rendered proof.

**Boundary:** Existing Admin and minimal host-only evaluation tooling. Preserve exact billing evidence, owner scope, authorization and action-outcome distinctions. No new billing capability, Portal work, production scenario picker or new Admin room.

## Phases

- [x] **Phase 245: Rendered Baseline and Realistic Preview** - Review every existing Admin route/state against a traceable visual inventory and plausible ordinary data. (completed 2026-10-11)
- [x] **Phase 246: Collection Controls and Search** - Make collection filtering, table scanning and global search coherent across existing journeys. (completed 2026-10-11)
- [x] **Phase 247: Evidence-True Details and Analytics** - Make timestamps, detail investigation, navigation, statuses and recovery metrics readable without overstating evidence. (completed 2026-10-11)
- [x] **Phase 248: Reproducible Scenarios and Integrated Proof** - Reproduce the agreed evaluation states and trace every accepted finding through executed, revision-bound checks. (completed 2026-10-12)

## Phase Details

### Phase 245: Rendered Baseline and Realistic Preview

**Goal**: Reviewers can see the actual breadth of existing Admin journeys with plausible ordinary billing data and explicit coverage limits.
**Depends on**: Nothing (first phase)
**Requirements**: BASE-01, BASE-02, DEMO-01
**Success Criteria** (what must be TRUE):
  1. A reviewer can find every existing Admin route and materially distinct list, detail and overlay state in a ledger, marked inspected, unavailable or not applicable with a reason.
  2. A reviewer can inspect representative wide/narrow and light/dark captures labeled with route, state, scenario, source revision and served assets; previously unseen pages receive a bounded rendered assessment.
  3. A reviewer can use a plausible ordinary feedback preview whose money, dates, relationships and processing histories agree, while adversarial fixture cases remain available in their test owners.

**Plans**: 3/3 plans complete

**Wave 1**
- [x] 245-01-PLAN.md — Isolated ordinary preview and first mounted capture

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 245-02-PLAN.md — Ordinary story integrity and seed protection

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 245-03-PLAN.md — Complete route/state inventory and bounded rendered review

**UI hint**: yes

### Phase 246: Collection Controls and Search

**Goal**: Operators can find and scan existing billing records through coherent controls whose visible state matches the results.
**Depends on**: Phase 245
**Requirements**: FILTER-01, FILTER-02, FILTER-03, SEARCH-01, TABLE-01
**Success Criteria** (what must be TRUE):
  1. An operator can distinguish a collection view from applied constraints, read visible filter labels, remove one compact chip or reset all filters, and see URL, controls, count and rows agree.
  2. An operator can combine useful statuses on existing multi-status collections, including default invoice and subscription queues, without losing scope or search intent.
  3. An operator can use general search according to its stated predicates and discover exact relationship constraints under explicitly named controls.
  4. An operator can open global billing search and see one active result across pointer and keyboard use, with truthful loading feedback on narrow and wide screens.
  5. An operator can scan primary identity, significant state, money and dates in responsive tables, then access the exact underlying identifiers when needed.

**Plans**: 5/5 complete (the supplemental identity-gap summary is not an additional plan).
- [x] 246-05-PLAN.md
- [x] 246-01-PLAN.md
- [x] 246-02-PLAN.md
- [x] 246-03-PLAN.md
- [x] 246-04-PLAN.md

**UI hint**: yes

### Phase 247: Evidence-True Details and Analytics

**Goal**: Operators can read, investigate and act on existing details and recovery data with consistent language and exact, appropriately qualified evidence.
**Depends on**: Phase 246
**Requirements**: TIME-01, LANG-02, STATE-02, DETAIL-01, DETAIL-02, METRIC-01
**Success Criteria** (what must be TRUE):
  1. An operator can identify the displayed local timezone and copy the exact UTC timestamp by keyboard or touch, with feedback that reflects clipboard success or failure.
  2. An operator can follow concrete destination headings, breadcrumbs and contextual links, and understand significant statuses without missing data implying unsupported outcomes or actions.
  3. An operator can inspect a webhook's identity, observed processing state, replay availability, history and raw payload through clear disclosures and readable controls that preserve exact evidence.
  4. An operator can review existing detail actions and copy metadata while owner scope, confirmation, step-up and accepted-versus-completed outcomes remain accurate.
  5. An operator can compare recovery values by currency, distinguish available/zero/absent data, and tell selected UTC windows from historical coverage and explicitly named help.

**Plans**: 8/8 plans complete
Plans:
**Wave 1**
- [x] 247-01-PLAN.md — Mounted exact timestamp tracer

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 247-02-PLAN.md — Shared Local/UTC choice and truthful clipboard feedback

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 247-03-PLAN.md — Timestamp coverage in existing Admin consumers

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 247-08-PLAN.md — Remaining list and analytics timeline timestamps

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 247-04-PLAN.md — Webhook investigation, replay and payload hierarchy

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 247-05-PLAN.md — Existing detail actions, metadata and concrete destinations

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 247-06-PLAN.md — Currency-true payment recovery presentation

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 247-07-PLAN.md — Current-revision mounted proof and final checks

**UI hint**: yes

### Phase 248: Reproducible Scenarios and Integrated Proof

**Goal**: Reviewers can independently reproduce ordinary and exceptional Admin states and verify how each accepted finding was resolved at the tested revision.
**Depends on**: Phase 247
**Requirements**: DEMO-02, PROOF-01
**Success Criteria** (what must be TRUE):
  1. A reviewer can select or launch documented ordinary, empty, failure and boundary evaluation states through existing or minimal host-only tooling without an implicit destructive reset of the current preview.
  2. A reviewer can trace every accepted owner finding to its shared or page-specific fix, or a justified disposition, and to executed owning checks.
  3. A reviewer can inspect rendered confirmation of changed surfaces labeled by route/state, theme, viewport, scenario, tested revision and served assets; uncovered states remain explicit.

**Plans**: 2/2 plans complete
**UI hint**: yes

Plans:
**Wave 1**
- [x] 248-01-PLAN.md — Guarded host-only ordinary, empty, failed-record and boundary scenarios with current rendered proof

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 248-02-PLAN.md — Complete owner finding/check ledger and inspected revision-bound acceptance evidence

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 245. Rendered Baseline and Realistic Preview | 3/3 | Complete    | 2026-10-11 |
| 246. Collection Controls and Search | 5/5 | Complete    | 2026-10-11 |
| 247. Evidence-True Details and Analytics | 8/8 | Complete    | 2026-10-11 |
| 248. Reproducible Scenarios and Integrated Proof | 2/2 | Complete    | 2026-10-12 |
