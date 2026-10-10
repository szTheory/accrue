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
- 🚧 **v1.64 Admin Operator UI Cleanup** — Phases 240–243 (3/4 complete; next: Phase 243 discussion)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction anchors remain in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md). Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work require an explicit future scope decision; Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

<details>
<summary>✅ v1.63 Admin and Portal UI refinement (Phases 233–239) — shipped 2026-10-09</summary>

**Completed phases:**
- [x] Phase 233: Shared Direction & Portal Contract (7 plans; 2026-10-07)
- [x] Phase 234: Admin Customers & Subscriptions (8 plans; 2026-10-07)
- [x] Phase 235: Customer Plan Selection & Checkout (6 plans; 2026-10-08)
- [x] Phase 236: Portal Billing Self-Service (6 plans; 2026-10-08)
- [x] Phase 237: Admin Invoices, Payments & Recovery (8 plans; 2026-10-09)
- [x] Phase 238: Admin Events, Webhooks & Remaining Billing Surfaces (5 plans; 2026-10-09)
- [x] Phase 239: Integrated Quality & Handoff (5 plans; 2026-10-09)

</details>

- [x] **Phase 240: Shared System and Real Billing Exemplar** - Deliver invoice list/detail/review and dense subscription examples through shared Admin patterns. (completed 2026-10-10)
- [x] **Phase 241: Billing Operator Journeys** - Make scoped billing destinations, returns, recovery and action reviews truthful. (completed 2026-10-10)
- [x] **Phase 242: Investigations and Remaining Admin Surfaces** - Clarify investigations, catalog, Connect, shell and domain language. (completed 2026-10-10)
- [ ] **Phase 243: Integrated Evidence and Feedback Preview** - Close selected visual proof and provide a stable Fake-backed preview.

## v1.64 — Admin Operator UI Cleanup

**Status:** Approved by maintainer on 2026-10-09. Scope/version, all 18 [requirements](REQUIREMENTS.md), and this four-phase structure are confirmed. [Bounded upstream decisions](research/v1.64/SUMMARY.md) are complete. Phases 240–242 are verified complete (20/20 planned plans; 16/18 requirements). Next: `$gsd-discuss-phase 243`; no repeat kickoff, research or approval interview is needed.

**Milestone goal:** Existing Admin journeys become clearer, consistent, responsive and easier to operate while preserving billing truth, authorization and scope, with recurring automated acceptance and a usable Fake-backed feedback preview.

**Delivery contract:** Each phase owns checks, current mounted inspection and package served-asset proof for its changed surfaces. Every affected route must preserve fresh actor/owner/target/material-state authorization, step-up, exact currency and minor-unit values, processor capability and accepted/pending/completed/unknown outcomes. Shared Cobalt, Geist/Geist Mono and `--ax-*` roles, theme, narrow/tablet/coarse-pointer access, keyboard/focus, state semantics, restrained motion and truthful domain language propagate through Phases 241–242; Phase 240's exemplars alone cannot close consumer-route acceptance. Existing ExUnit, package browser, mounted host, axe, registry/build and Linux pixel owners receive focused controls with the owning changes. Phase 243 reconciles completed evidence and preview access, rather than becoming the first acceptance owner. Confirm or close historical source candidates on current mounted output; keep one inspection batch, one corrective batch and at most one confirming inspection per agreed delivery batch.

**Boundaries:** Existing `accrue_admin` routes and necessary host proof/preview seams. No Portal work, new billing or provider capability, diagnosis/causality or new rooms, paid AI ratchet, CI redesign or unrelated historical debt. Preserve the closed v1.63 contracts and archives.

## Phase Details

### Phase 240: Shared System and Real Billing Exemplar

**Goal**: Operators can use a coherent, truthful invoice list → detail → action review flow and a dense subscription view through the incumbent Admin system, with shared interaction and evidence patterns ready for other existing routes.
**Depends on**: Phase 239 (shipped v1.63 baseline)
**Requirements**: DSN-01, DSN-02, DSN-03, DSN-04, DSN-05, UXC-02, EVR-01, EVR-02
**Success Criteria** (what must be TRUE):
  1. Operators can scan invoice list, detail and review, plus the dense subscription view, with consistent identity, current facts, next actions and existing Cobalt/Geist/`--ax-*` hierarchy; long/missing data, narrow and intermediate/coarse-pointer layouts, text enlargement and zoom keep essential facts and controls usable. (DSN-01, DSN-02)
  2. Operators can select and retain Light, Dark or System; effective styles and host-forced theme behavior remain correct across the exemplar and shared controls. (DSN-03)
  3. Keyboard operators can navigate and complete the exemplar review with visible focus, associated errors/status, contained overlays and logical focus return; controls remain correctly labeled, disabled and context-aware through real busy completion, repeated patches and reconnect without replaying a staged action. (DSN-04, DSN-05)
  4. Operators can distinguish empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown exemplar states, see uncertainty and choose only a supported next step. (UXC-02)
  5. Maintainers can inspect a current route/component/state coverage inventory with source, fixture, compiled/served-asset and exercised-behavior provenance; existing acceptance owners provide recurring exemplar checks, focused failure controls, current served package assets and lightweight comparable resource diagnostics without confirmation-only human UAT. (EVR-01, EVR-02)

**Propagation obligation**: Shared rules, interaction patterns, state distinctions and evidence owners established here must be exercised on every affected Phase 241–242 consumer. Do not declare broad route coverage from this exemplar. Preserve deliberate 2px dense and 1px structural exceptions; confirm suspected compression and action geometry in current mounted output before editing.
**Early regression guard**: Strengthen the existing expected-Linux-snapshot set guard before propagation and prove its missing-set failure at the existing owner. EVR-03's final reviewed baseline closure remains Phase 243 ownership; the guard is not postponed until then.
**Plans**: 6/6 plans complete
Plans:
**Wave 1**
- [x] 240-01-PLAN.md — Real invoice tracer, shared hierarchy and dense subscription cross-check
- [x] 240-02-PLAN.md — Blocking complete Linux snapshot-set guard

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 240-03-PLAN.md — Truthful invoice states and responsive/content acceptance
- [x] 240-04-PLAN.md — Effective theme and full keyboard review behavior

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 240-05-PLAN.md — Real busy completion and reconnect without action replay

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 240-06-PLAN.md — Current coverage, served assets and exercised provenance

**UI hint**: yes

### Phase 241: Billing Operator Journeys

**Goal**: Operators can move through existing customer, subscription, invoice, payment and recovery work with truthful scoped destinations, bounded returns and self-contained billing action reviews.
**Depends on**: Phase 240
**Requirements**: JRN-01, JRN-02, JRN-03, JRN-04
**Success Criteria** (what must be TRUE):
  1. From a subscription, operators reach the supported customer-scoped invoice result set named by the visible link, while any owner queue link is separately and accurately labeled. (JRN-01)
  2. Operators can enter supported filtered lists, open a record and return with validated owner, existing filter/lens and customer-tab context intact; foreign scope or arbitrary origin cannot redirect the return. (JRN-02)
  3. Direct campaign entry returns to scoped Recovery; entry from Recovery retains a valid selected recovery window and scope. (JRN-03)
  4. Before an existing billing action, operators can review exact target, material customer/scope, money/currency and consequence in one place; after action they see the evidence-specific accepted, pending, completed, failed or unknown result. Fresh authorization, step-up, duplicate protection and exact-money contracts remain visible through the flow. (JRN-04)

**Propagation obligation**: Exercise Phase 240 shared hierarchy, responsive/theme behavior, keyboard/focus, busy/reconnect and state distinctions on each changed billing consumer. Verify auth, owner/target/material-state, capability and exact-money invariants at their existing owners; rebuild and confirm package served assets and add focused negative controls with each owning change. Supported returns are bounded existing meanings, not pagination/scroll preservation or a new subscription invoice filter.
**Plans**: 7/7 plans complete
**Wave 1**
- [x] 241-01-PLAN.md
- [x] 241-02-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 241-03-PLAN.md
- [x] 241-04-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 241-05-PLAN.md
- [x] 241-06-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 241-07-PLAN.md

**UI hint**: yes

### Phase 242: Investigations and Remaining Admin Surfaces

**Goal**: Operators can investigate existing events and deliveries, understand catalog and Connect relationships, and find the correct scoped record through a consistent Admin shell and domain language.
**Depends on**: Phase 241
**Requirements**: JRN-05, JRN-06, JRN-07, UXC-01
**Success Criteria** (what must be TRUE):
  1. Operators can follow filtered event and webhook worklists into related evidence and supported replay review, then return with bounded supported context; material failure, uncertainty and exact diagnostic details remain discoverable. (JRN-05)
  2. Operators can inspect existing discounts, promotion-code relationships and Connect facts, preserve bounded list/relationship context, and use supported actions with a clear distinction between stored provider facts and local policy. (JRN-06)
  3. Operators can find the correct scoped record from Home, navigation and search, with visible selection that agrees across pointer and keyboard input. (JRN-07)
  4. Across changed lists, details, filters and reviews, operators encounter coherent resource, collection-method and action language while diagnostic terms and locked audit/legal meaning stay exact. (UXC-01)

**Propagation obligation**: Apply and verify Phase 240 system, accessibility, responsive/theme, state and evidence patterns on each changed investigation, catalog, Connect and shell consumer. Preserve fresh scope/authorization, capability and outcome truth; add focused checks at existing semantic owners, inspect mounted behavior, and confirm rebuilt served package assets. Reconcile earlier billing copy as needed for cross-route consistency.
**Plans**: 7/7 plans complete
**Wave 1**
- [x] 242-01-PLAN.md
- [x] 242-05-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 242-02-PLAN.md
- [x] 242-03-PLAN.md
- [x] 242-04-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 242-06-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 242-07-PLAN.md

**UI hint**: yes

### Phase 243: Integrated Evidence and Feedback Preview

**Goal**: Maintainers can review proven Admin cleanup across the existing route set and inspect a stable Fake-backed preview with evidence limits stated accurately.
**Depends on**: Phase 242
**Requirements**: EVR-03, EVR-04
**Success Criteria** (what must be TRUE):
  1. Maintainers receive blocking Linux pixel results for the complete expected selected golden set; removal of all or part of that set fails, reviewed intended updates are visible, and masks leave identity, money, state, action and error meaning exposed. (EVR-03)
  2. Maintainers can start and use the documented Fake-backed `/admin` feedback preview without disposable mutation/reset proof disturbing it; the handoff distinguishes transport, local versus remote, provider, rendered and exercised evidence limits. (EVR-04)
  3. Maintainers can compare final changed route and state coverage with the Phase 240 inventory and slice-owned recurring evidence, including desktop/narrow and effective-theme inspections, served asset identity and any named remaining limits; no broad claim rests only on the initial exemplar. (EVR-03, EVR-04; reconciles EVR-01 and EVR-02 without remapping them)

**Closure obligation**: Reconcile proofs from Phases 240–242 and repair named gaps in their owning surfaces. This phase does not defer first authorization, accessibility, responsive/theme, language or asset acceptance. Use selected stable snapshots, existing thresholds and bounded masks; no new CI matrix or required human sign-off.
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution order:** 240 → 241 → 242 → 243. Phases 240–242 are verified complete; next command is `$gsd-discuss-phase 243`.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 240. Shared System and Real Billing Exemplar | v1.64 | 6/6 | Complete    | 2026-10-10 |
| 241. Billing Operator Journeys | v1.64 | 7/7 | Complete    | 2026-10-10 |
| 242. Investigations and Remaining Admin Surfaces | v1.64 | 7/7 | Complete    | 2026-10-10 |
| 243. Integrated Evidence and Feedback Preview | v1.64 | 0/TBD | Not started | - |
