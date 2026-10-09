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
- 🚧 **v1.63 Admin and Portal UI refinement** — Phases 233-239 (planning)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work must be explicitly re-scoped by a future milestone before execution. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

### v1.63 — Admin and Portal UI refinement

- [x] **Phase 233: Shared Direction & Portal Contract** - Establish current-source baseline, shared visual roles, and the bounded host-owned billing context contract. (completed 2026-10-07)
- [x] **Phase 234: Admin Customers & Subscriptions** - Refine operator search, customer/subscription investigation, lifecycle truth, scope, and supported actions. (completed 2026-10-07)
- [x] **Phase 235: Customer Plan Selection & Checkout** - Make existing checkout, payment hooks, provider handoffs, and safe returns understandable and reliable. (completed 2026-10-08)
- [x] **Phase 236: Portal Billing Self-Service** - Refine existing customer billing pages and authorized payment/subscription tasks through one Portal. (completed 2026-10-08)
- [x] **Phase 237: Admin Invoices, Payments & Recovery** - Make money and recovery work precise, scoped, and honest about outcomes.
- [ ] **Phase 238: Admin Events, Webhooks & Remaining Billing Surfaces** - Improve event and delivery investigation plus existing coupon, promotion-code, and Connect surfaces.
- [ ] **Phase 239: Integrated Quality & Handoff** - Close route coverage, cross-surface evidence, current-render inspection, and a usable feedback preview.

## Phase Details

### Phase 233: Shared Direction & Portal Contract

**Goal**: Maintainers and adopters can see a current, coherent Admin and Portal baseline, while hosts can select a billed entity and authorize its actions through one bounded Portal contract.
**Depends on**: Nothing (first phase)
**Requirements**: BASE-01, SYS-01, SYS-02, POR-08, SAFE-02, SAFE-03, SHIP-04
**Success Criteria** (what must be TRUE):
  1. Maintainers can inspect the current served route, flow, component, and state inventory and distinguish it from historical captures.
  2. Operators and customers see shared semantic visual roles while Admin identity, host customer branding, and audience-specific layouts remain recognizable in real consumers.
  3. A personal-only host retains its existing Portal behavior without a company model or picker; a mixed host can resolve personal and custom billables while actor, billable, Customer, and processor remain distinct.
  4. On initial request, LiveView events/reconnect, and protected actions, the host's fresh authorization governs the selected context; invalid or unauthorized selection cannot fall back, provision, or retarget a form.
  5. The canonical example and adopter guidance show personal defaults plus organization/custom and mixed resolution without requiring a new auth or runtime dependency.

**Plans**: 7/7 plans complete

Plans:
**Wave 1**
- [x] 233-04-PLAN.md — Inventory current Admin/Portal source and served renders; define semantic direction.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 233-01-PLAN.md — Trace optional billable resolution through a real Portal page and blocked recovery.
- [x] 233-06-PLAN.md — Apply and verify semantic roles in bounded package-owned consumers.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 233-02-PLAN.md — Connect rendered payment forms to pinned POST actions and gate add-card client tokens.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 233-03-PLAN.md — Apply the contract to Home, subscription, and invoice routes and events.
- [x] 233-07-PLAN.md — Connect checkout form pins to both completion transports and gate client tokens.

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 233-05-PLAN.md — Demonstrate personal, custom, and mixed host adoption with aligned docs.

### Phase 234: Admin Customers & Subscriptions

**Goal**: Operators can find and investigate the correct customer and subscription, understand observed lifecycle truth, and complete only supported subscription actions.
**Depends on**: Phase 233
**Requirements**: ADM-01, ADM-03, ADM-04, SAFE-01
**Success Criteria** (what must be TRUE):
  1. Operators can search, enter a nondefault owner scope, follow customer/subscription/related-record links, and return without losing object or filter context.
  2. A known subscription lifecycle remains clear when ancillary observations are missing, and missing facts are identified as unknown.
  3. Only eligible subscription actions are offered; confirmation, step-up expiry, duplicate protection, and resulting evidence communicate the actual outcome.
  4. Mounted owner/customer denials and forged actions remain denied without exposing foreign records or payment-token data.
  5. The affected Admin flows remain usable by keyboard and at narrow/coarse-pointer sizes, with the relevant light/dark and empty/error states checked in this slice.

**Plans**: 8/8 plans complete
Plans:
**Wave 1**
- [x] 234-01-PLAN.md — Scoped subscription list, detail and return trace; immutable pre-layout capture
- [x] 234-02-PLAN.md — Factual Home and bounded global search

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 234-07-PLAN.md — Scoped customer and related-record return journey

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 234-03-PLAN.md — Lifecycle truth and readable record hierarchy

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 234-04-PLAN.md — Eligible action review and fresh dispatch gate

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 234-05-PLAN.md — Stable action intent and truthful scoped results

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 234-06-PLAN.md — Served keyboard, responsive, denial and CI evidence

**Wave 8** *(verification gap closure)*
- [x] 234-08-PLAN.md — Shift-left real-search, step-up, and measurable UI verification

**UI hint**: yes

### Phase 235: Customer Plan Selection & Checkout

**Goal**: Customers can understand a selected offer, complete supported checkout through its actual browser integration, or leave safely with an honest outcome.
**Depends on**: Phase 233
**Requirements**: CKO-01, CKO-02, CKO-03, CKO-04
**Success Criteria** (what must be TRUE):
  1. The visible checkout form reaches the actual supported payment hook and represents valid, invalid, provider-failure, cancellation, and retry results accurately.
  2. Hosted-provider and mounted checkout handoffs remain distinct and capability-aware; safe returns do not treat a query parameter as payment evidence or imply live parity from Fake proof.
  3. Expired/completed sessions, stale promotions, and repeated submissions follow the existing contract without claiming an unproven charge or rendering missing price as zero.
  4. Plan choice survives sign-in and return; only trusted available metadata supplies charge terms, and unknown terms or outcomes lead to recovery without blind resubmission.
  5. Checkout keyboard, narrow-screen, theme, secure SDK, pending/error-state, and served-asset behavior is checked alongside each changed form and handoff.

**Plans**: 6/6 plans complete
Plans:
**Wave 1**
- [x] 235-01-PLAN.md — Visible Braintree secure-form tracer and safe retry

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 235-02-PLAN.md — Exact host-selected offer through sign-in and trusted terms

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 235-03-PLAN.md — Reentrant-safe POST and LiveView checkout outcomes

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 235-04-PLAN.md — Distinct hosted return and served-browser accessibility proof

**UI hint**: yes

### Phase 236: Portal Billing Self-Service

**Goal**: Customers can understand their billing identity and manage supported existing payment, subscription, and invoice tasks in the branded Portal.
**Depends on**: Phase 233; Phase 235 for shared checkout/return behavior
**Requirements**: POR-01, POR-02, POR-03, POR-04, POR-05, POR-06, POR-07
**Success Criteria** (what must be TRUE):
  1. Customers can use all seven existing Portal pages with legible, responsive content clearly scoped to the selected billed entity and consistent with host branding.
  2. Supported payment-method and subscription actions honor capability and ownership; list and detail entry points disclose matching consequences before confirmation.
  3. Customers reach only their existing invoice records and hosted invoice access; missing or unauthorized records fail safely.
  4. LiveView and POST/redirect actions announce visible success or failure, failed reads do not look empty, and checkout failure does not assert a charge.
  5. Direct add-card navigation initializes readable supported secure fields across effective themes; known subscription states and safe host returns are truthful, and Portal keyboard/mobile/focus/motion states are checked in this slice.

**Plans**: 6/6 plans complete
Plans:
**Wave 1**
- [x] 236-01-PLAN.md — Scoped hosted invoices and distinct read outcomes

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 236-02-PLAN.md — Supported payment-method actions and direct secure card entry
- [x] 236-04-PLAN.md — Checkout evidence and safe returns

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 236-03-PLAN.md — Subscription action parity and truthful lifecycle

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 236-05-PLAN.md — Host-branded seven-route browser contract in CI

**Wave 5** *(blocked on Waves 2 and 4 completion)*
- [x] 236-06-PLAN.md — POR-05 themed direct add-card Hosted Fields closure

**UI hint**: yes

### Phase 237: Admin Invoices, Payments & Recovery

**Goal**: Operators can complete invoice, payment, refund, and recovery work with exact amounts, correct scope, and truthful result evidence.
**Depends on**: Phase 234
**Requirements**: ADM-02, ADM-05, ADM-06
**Success Criteria** (what must be TRUE):
  1. Operators distinguish draft, open, and overdue invoices, see missing due dates honestly, and read amounts at the correct currency minor-unit precision.
  2. Invoice payment/finalization and refund views and confirmations show the exact amount, currency, and consequence.
  3. Accepted, requires-action, failed, and completed results are distinguishable and tied to the resulting billing evidence.
  4. Recovery views retain time window, owner, currency, and return context while keeping historical failures separate from current billing state.
  5. Changed money/recovery flows retain keyboard, responsive, theme, and relevant pending/denied/error evidence within this slice.

**Plans**: 8/8 plans complete
Plans:
- [x] 237-01-PLAN.md — Owner-scoped invoice tracer and Wave 0 boundary fixtures
- [x] 237-02-PLAN.md — Wave 0 invoice and refund action/result fixtures
- [x] 237-03-PLAN.md — Wave 0 recovery currency/window/navigation fixtures
- [x] 237-04-PLAN.md — Invoice collection and detail truth
- [x] 237-05-PLAN.md — Invoice action revalidation and evidenced outcomes
- [x] 237-06-PLAN.md — Charge/refund precision, revalidation, and outcomes
- [x] 237-07-PLAN.md — Recovery currency, history, scope, and return context
- [x] 237-08-PLAN.md — Representative served browser and CI proof

**UI hint**: yes

### Phase 238: Admin Events, Webhooks & Remaining Billing Surfaces

**Goal**: Operators can investigate local events and delivery history, retry or replay only eligible work, and inspect remaining existing billing surfaces without implied capabilities.
**Depends on**: Phase 234; Phase 237 for related money evidence
**Requirements**: ADM-07, ADM-08
**Success Criteria** (what must be TRUE):
  1. Operators can inspect local events and webhook deliveries with useful context, accessible identifiers, and linked evidence.
  2. Retry/replay is limited to eligible deliveries with required confirmation and step-up; accepted versus processed results and partial selections are stated honestly.
  3. Existing coupon, promotion-code, and Connect states and actions are understandable, provider-specific where needed, and never imply unsupported create/edit behavior.
  4. Each changed filter, payload, action, and empty/error state has relevant keyboard, responsive, theme, and interaction evidence in this slice.

**Plans**: 5/5 plans complete
Plans:
**Wave 1**
- [x] 238-01-PLAN.md — Safe selected webhook replay and Wave 0 regression seams
- [x] 238-02-PLAN.md — Event and delivery evidence detail
- [x] 238-03-PLAN.md — Coupon and promotion-code inspection
- [x] 238-04-PLAN.md — Connect provider observation and local override

**Wave 2**
- [x] 238-05-PLAN.md — Required mounted browser evidence and UI acceptance

**UI hint**: yes

### Phase 239: Integrated Quality & Handoff

**Goal**: Maintainers can rely on current cross-surface evidence for the complete refinement and inspect the delivered result in a stable preview.
**Depends on**: Phases 233–238
**Requirements**: INT-01, INT-02, INT-03, INT-04, SHIP-01, SHIP-02, SHIP-03
**Success Criteria** (what must be TRUE):
  1. Keyboard navigation, focus containment/restoration, narrow-screen reflow, zoom, theme handoff, forced themes, and reduced-motion behavior work across representative Admin, Portal, and host journeys; slice-level proof already exists for changed flows.
  2. Empty, no-match, unavailable, unsupported, denied, pending, error, and long-content states have deliberate coverage at the least costly credible layer across the owned inventory.
  3. Every owned route and unique interaction has a coverage disposition, and current required gates plus inspected representative renders support the completion claims.
  4. Generated assets, fonts, mounts, CSP/SRI, copy exports, and host integration documentation match the source actually served; component examples/docs match production and task-owned debris is removed.
  5. A useful feedback preview remains available separately from mutation/reset proof, with a concise change summary for optional owner feedback.

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 233. Shared Direction & Portal Contract | 7/7 | Complete    | 2026-10-07 |
| 234. Admin Customers & Subscriptions | 8/8 | Complete    | 2026-10-07 |
| 235. Customer Plan Selection & Checkout | 6/6 | Complete    | 2026-10-08 |
| 236. Portal Billing Self-Service | 6/6 | Complete    | 2026-10-08 |
| 237. Admin Invoices, Payments & Recovery | 8/8 | Complete    | 2026-10-08 |
| 238. Admin Events, Webhooks & Remaining Billing Surfaces | 4/5 | In Progress | - |
| 239. Integrated Quality & Handoff | 0/TBD | Not started | - |

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
