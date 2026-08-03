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
- ◆ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215-220 (active; Stripe + Apple account union, provider-honest lifecycle management, signed offline proof, and B2C Alpha proof)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

v1.59 clears that bar through B2C Alpha's sourced need for coherent Stripe/Apple access and extended offline use. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

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

### ◆ v1.59 Account-Scoped Multi-Rail & Offline Entitlements (Active)

**Goal:** Preserve one account's access across Stripe web billing, Apple in-app purchase, and extended offline study through a common entitlement projection and signed, device-bound proof, while keeping lifecycle operations rail-aware.

- [x] **Phase 215: Research, contracts, and Crosswake feasibility** — Freeze the evidence-to-entitlement contract and prove or block required Crosswake client capabilities before runtime assumptions (RSCH-01..03, RAIL-04..05). (completed 2026-08-01)
- [x] **Phase 216: Additive rail and persistence foundation** — Add concurrent Stripe/Apple rails, qualified products, and durable account/observation/grant/device records without breaking legacy hosts (RAIL-01..03). (completed 2026-08-02)
- [x] **Phase 217: Canonical projection and compatibility** — Project rail-qualified evidence into one revisioned account snapshot with provider-honest lifecycle and safe cross-rail purchase eligibility (ACCT-01..05). (completed 2026-08-02)
- [ ] **Phase 218: Apple observation and repair** — Verify, link, quarantine, reconcile, and present Apple lifecycle evidence without ownership heuristics or Stripe mutation leakage (AAPL-01..05).
- [ ] **Phase 219: Offline study contract** — Deliver device-bound ES256 proof, stale-study continuity, and atomic reconnect using the accepted no-72-hour-cutoff policy (OFF-01..06).
- [ ] **Phase 220: First-adopter proof and release gates** — Prove the complete Stripe/Apple/offline workflow, operations, documentation, and release contract for B2C Alpha (PROOF-01..05).

Dependencies: 215 → 216 → 217 → {218, 219} → 220. Phase 215 must prove Crosswake feasibility before later client assumptions; Phase 219 depends on Phase 217 and the accepted Phase-215 contract, not on Apple runtime implementation.

## Phase Details

### Phase 215: Research, contracts, and Crosswake feasibility

**Goal**: Maintainers have one current, evidence-backed multi-rail contract and know whether the required Crosswake client boundary is feasible before runtime coupling begins.
**Depends on**: Nothing (first phase)
**Requirements**: RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05
**Success Criteria** (what must be TRUE):

  1. A maintainer can find one versioned v1.59 bundle with source provenance, accepted and rejected choices, confidence, and a dated change watchlist.
  2. An implementer can use one decision table to determine projection, eligibility, repair, and offline-continuity outcomes for duplicate, out-of-order, revocation, survivor-grant, and stale cases.
  3. A host can inspect source-specific observation, control, restore, reconciliation, management, and offline capabilities without treating the processor matrix as a rail contract.
  4. The checked-in Crosswake tracer proves every required bridge or explicitly blocks mobile runtime coupling before later phases rely on it.

**Plans**: 15/15 plans executed

Plans:

- [x] 215-15-PLAN.md

**Wave 12** *(blocked on Wave 11 completion)*

- [x] 215-14-PLAN.md — Close the public data-only false-proof route and reserve proven feasibility for provenance-validating construction.

- [x] 215-13-PLAN.md

- [x] 215-12-PLAN.md

**Wave 1**

- [x] 215-01-PLAN.md — Build the Crosswake feasibility skeleton and explicit prove-or-block report.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 215-02-PLAN.md — Establish the v1.59 authority manifest, amendment ledger, watchlist, and drift gate.
- [x] 215-03-PLAN.md — Define one data-only decision-case corpus and deterministic Markdown/JSON/property consumers.
- [x] 215-04-PLAN.md — Publish the typed entitlement-source capability registry, mirrors, conformance, and leakage gates.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 215-05-PLAN.md — Bind signed offline vectors to DecisionCases and prove Elixir/Swift verification and atomic replacement.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 215-06-PLAN.md — Close the D-07 schema and replace vacuous properties with an executable conformance consumer.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 215-07-PLAN.md — Correct and self-validate the shared offline golden corpus across Elixir and Swift.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 215-08-PLAN.md — Serialize and durably prove concurrent Swift offline-cache replacement, then rerun all Phase 215 gates.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 215-09-PLAN.md — Correct Continuity rendering and make Elixir reject all canonical offline-corpus drift.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 215-10-PLAN.md — Enforce exact canonical offline-vector schema and binding parity in Swift.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 215-11-PLAN.md — Persist authenticated denial/high-water state and prove restart-safe interprocess ordering with automated feasibility closeout.

### Phase 216: Additive rail and persistence foundation

**Goal**: Hosts can represent concurrent Stripe and Apple entitlement evidence on durable, rail-qualified records while existing single-processor integrations remain valid.
**Depends on**: Phase 215
**Requirements**: RAIL-01, RAIL-02, RAIL-03
**Success Criteria** (what must be TRUE):

  1. A host can register Stripe and Apple together while legacy `processor` configuration continues as the supported default-rail alias.
  2. A host can map each rail/environment product identifier to one logical plan without identifier collisions across rails or Apple sandbox and production.
  3. An account’s observations, grants, devices, provenance, quarantine state, and ordering data persist with stable identity and transactional uniqueness.

**Plans**: 6/6 plans executed

Plans:

**Wave 1**

- [x] 216-01-PLAN.md — Prove concurrent rail configuration through one durable entitlement-account tracer.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 216-02-PLAN.md — Complete legacy aliasing and rail/environment-qualified catalog normalization.
- [x] 216-03-PLAN.md — Add qualified grants, idempotent observations, and account-scoped device persistence.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 216-04-PLAN.md — Ship deterministic fixtures and propagate config/migrations through installer guidance.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 216-05-PLAN.md — Harden opaque evidence, scoped provenance, observation idempotency, and PostgreSQL domain constraints.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 216-06-PLAN.md — Close remaining RAIL-03 gaps with account-safe global observation identity, provider-provenance byte limits, and executable PostgreSQL bypass proofs.

### Phase 217: Canonical projection and compatibility

**Goal**: A host can make entitlement and purchase decisions from one revisioned account snapshot without changing legacy billing behavior or destroying survivor grants.
**Depends on**: Phase 216
**Requirements**: ACCT-01, ACCT-02, ACCT-03, ACCT-04, ACCT-05
**Success Criteria** (what must be TRUE):

  1. A user with any live Stripe or Apple grant receives the union of effective plans/features, with duplicate logical grants deduplicated and maximum effective quantity used.
  2. Revoking one source leaves access granted by another source intact, and duplicate or metadata-only evidence does not advance the account revision.
  3. Lifecycle actions dispatch by the persisted rail; externally managed Apple resources give explicit guidance and never enter Accrue-owned billing mutations.
  4. Existing single-processor hosts retain deterministic customers, mappings, webhooks, Stripe subscriptions, gates, and advisory-cache isolation through an opt-in, parity-checked multi-rail cutover.
  5. An equivalent second-rail purchase is blocked by default, with an explicit host warning/override path and no automatic cancellation, transfer, refund, migration, or proration.

**Plans**: 5/5 plans executed

Plans:

**Wave 1**

- [x] 217-01-PLAN.md — Trace qualified evidence through serialized projection to a deterministic survivor-safe account snapshot.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 217-02-PLAN.md — Prove projection boundary, precision, idempotency, concurrency, and decision-case invariants.
- [x] 217-03-PLAN.md — Ship typed cross-rail purchase preflight, revision-bound override, and idempotent Stripe continuation.
- [x] 217-04-PLAN.md — Deliver legacy backfill, shadow parity, cohort cutover, and non-destructive rollback.

**Wave 3** *(blocked on 217-03 completion)*

- [x] 217-05-PLAN.md — Route persisted subscription lifecycle by resource provenance and prove honest Apple isolation.

### Phase 218: Apple observation and repair

**Goal**: Verified Apple evidence safely contributes to the account snapshot and repairs itself without ownership reassignment or provider-lifecycle confusion.
**Depends on**: Phase 217
**Requirements**: AAPL-01, AAPL-02, AAPL-03, AAPL-04, AAPL-05
**Success Criteria** (what must be TRUE):

  1. An authenticated account can purchase or restore through its opaque entitlement UUID; only eligible verified lineage binds once, while ownership conflicts quarantine without heuristic or automatic reassignment.
  2. Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants.
  3. Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable.
  4. Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries.
  5. Hosts receive honest externally-managed Apple subscription guidance, with Family Sharing and offer authoring explicitly deferred.

**Plans**: 13/14 plans executed

Plans:

**Wave 11** *(blocked on 218-12 and 218-13 completion)*

- [ ] 218-14-PLAN.md — Repair Production Notifications V2 envelope validation and prove durable duplicate/concurrent wakeup coalescing.

**Wave 10** *(blocked on Wave 9 completion)*

- [x] 218-13-PLAN.md — Quarantine verified unmapped products without blocking later terminal history from retracting stale Apple access.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 218-12-PLAN.md — Wire bounded evidence-time certificate validation and all configured Apple trust roots through production admission and reconciliation.

- [x] 218-11-PLAN.md

- [x] 218-09-PLAN.md
- [x] 218-10-PLAN.md

**Wave 1**

- [x] 218-01-PLAN.md — Trace verified Apple purchase evidence through bind-once lineage, canonical projection, and a rollback-safe durable reconciliation wakeup.
- [x] 218-02-PLAN.md — Verify the candidate Apple server package identity before any installation.

**Wave 2** *(blocked on 218-01 and 218-02 completion)*

- [x] 218-03-PLAN.md — Admit strict Apple verification through candidate gates or the complete Jason/OTP fallback.

**Wave 3** *(blocked on 218-03 completion)*

- [x] 218-04-PLAN.md — Serialize explicit unbound repair and close convergent intake dispositions.
- [x] 218-07-PLAN.md — Durably acknowledge bounded Notifications V2 input through the strict verifier.

**Wave 4** *(blocked on 218-04 completion)*

- [x] 218-05-PLAN.md — Drain durable wakeups into host-owned repair and reconcile authoritative status plus crash-safe ascending history.

**Wave 5** *(blocked on 218-05 completion)*

- [x] 218-06-PLAN.md — Persist and normalize complete Apple lifecycle ordering through the sole-writer Projector.

**Wave 6** *(blocked on 218-06 and 218-07 completion)*

- [x] 218-08-PLAN.md — Finalize typed Apple outcomes, exact external management, and Stripe isolation.

### Phase 219: Offline study contract

**Goal**: A registered device can safely retain downloaded-study continuity while offline, then converge atomically when it reconnects.
**Depends on**: Phase 215, Phase 217
**Requirements**: OFF-01, OFF-02, OFF-03, OFF-04, OFF-05, OFF-06
**Success Criteria** (what must be TRUE):

  1. A registered device independently verifies a versioned, compact ES256 entitlement proof with language-neutral fixtures and no signing secret.
  2. Successful reconciliation establishes a 30-day revalidation target (shortened by known provider bounds); passing it produces `stale_offline`, never an independent 72-hour cutoff.
  3. While stale, already-downloaded lessons and local progress remain usable, while new premium downloads and all other value-expanding actions wait for reconnection.
  4. Host code can distinguish fresh, stale-offline, denied, and invalid proof states with bounded reasons while existing boolean gate return types remain compatible.
  5. Reconnect authenticates account and device, refreshes due rails, and atomically replaces cached proof with a newer allow proof or signed deny tombstone; copied, replayed, wrong-device, rollback, revoked-device, and rotated-key proofs fail safely.

**Plans**: TBD

### Phase 220: First-adopter proof and release gates

**Goal**: The anonymized B2C Alpha reference host and public release contract prove that multi-rail access and offline study are safe, diagnosable, and operable.
**Depends on**: Phase 218, Phase 219
**Requirements**: PROOF-01, PROOF-02, PROOF-03, PROOF-04, PROOF-05
**Success Criteria** (what must be TRUE):

  1. The reference host proves Apple-to-web and Stripe-to-iOS access converge for the same account without manual reconciliation.
  2. Deterministic, credential-free checks prove duplicate-purchase prevention, stale study continuity, restricted expansion, reconnect, revocation, survivor grants, device replacement, deny tombstones, clock rollback, and key rotation.
  3. An operator can inspect redacted account, rail, provider, revision, eligibility, device/proof, and quarantine/retry state without raw transaction data or PII.
  4. Automated repair and runbooks address missed Apple notifications, history cursor recovery, outages, conflicts, duplicate charges, stale devices, signing-key compromise, and reconciliation backlog without routine account reconstruction.
  5. Public guides, examples, capability/compatibility material, App Review guidance, release notes, threat model, watchlist, and conformance gates state one additive contract and its explicit v1.59 limits.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---:|---|---|
| 212. lattice_stripe 2.x bump | v1.58 | 1/1 | Complete | 2026-07-30 |
| 213. Advisory entitlements sync | v1.58 | 5/5 | Complete | 2026-07-31 |
| 214. Docs reconciliation | v1.58 | 3/3 | Complete | 2026-07-31 |
| 214.1. Writer-documentation closure | v1.58 | 4/4 | Complete | 2026-07-31 |
| 214.2. Diagnostic-display/pagination closure | v1.58 | 4/4 | Complete | 2026-07-31 |
| 215. Research, contracts, and Crosswake feasibility | v1.59 | 15/15 | Complete    | 2026-08-01 |
| 216. Additive rail and persistence foundation | v1.59 | 6/6 | Complete    | 2026-08-02 |
| 217. Canonical projection and compatibility | v1.59 | 5/5 | Complete | 2026-08-02 |
| 218. Apple observation and repair | v1.59 | 13/13 | In Progress|  |
| 219. Offline study contract | v1.59 | 0/TBD | Not started | - |
| 220. First-adopter proof and release gates | v1.59 | 0/TBD | Not started | - |
