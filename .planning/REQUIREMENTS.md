# Requirements: Accrue v1.59

**Defined:** 2026-07-31
**Core Value:** A Phoenix developer can install Accrue and launch production-grade subscription billing with clear domain state, strong observability, and additive v1.x compatibility.
**Milestone:** Account-Scoped Multi-Rail & Offline Entitlements

## v1.59 Requirements

### Durable Research Memory

- [x] **RSCH-01**: A future maintainer can find one versioned v1.59 research bundle that preserves stakeholder findings, primary-source provenance, accepted tradeoffs, rejected alternatives, and confidence levels without treating historical generic research as current authority.
- [x] **RSCH-02**: Implementers can drive reducers, fixtures, documentation, and support explanations from one evidence-to-entitlement decision table covering duplicate, out-of-order, survivor-grant, revocation, purchase-eligibility, and offline-continuity cases.
- [x] **RSCH-03**: Maintainers have a dated watchlist that names Apple, Stripe, Crosswake, dependency, policy, privacy, and security change triggers plus the owning phase or runbook response.

### Rail Contract and Foundation

- [x] **RAIL-01**: A host can register Stripe and Apple rails concurrently while the existing single `processor` configuration remains a supported default-rail alias.
- [x] **RAIL-02**: A host can map rail-qualified product identifiers to one logical Accrue plan without cross-rail or sandbox/production identifier collisions.
- [x] **RAIL-03**: Accrue can persist one stable entitlement account, rail/environment-qualified observations and grants, and registered devices with source-item cardinality, monotonic revision/order metadata, bounded provenance, quarantine state, and transactional uniqueness.
- [x] **RAIL-04**: A host can inspect each rail's observation, control, restore, reconciliation, management, and offline capabilities through a dedicated entitlement-source matrix rather than infer them from the gateway processor matrix.
- [x] **RAIL-05**: A checked-in Crosswake feasibility tracer proves or explicitly blocks the required StoreKit bridge, P-256 device key, secure storage, durable local state, high-water clock, atomic proof replacement, and lifecycle/reconnect callbacks before runtime coupling is accepted.

### Canonical Account Projection

- [x] **ACCT-01**: An account entitled through any live Stripe or Apple source receives the union of effective plans and features on web and mobile, with duplicate logical grants deduplicated and quantities resolved by maximum effective quantity.
- [x] **ACCT-02**: Revoking, refunding, or expiring one rail source retracts only that source and cannot remove access still supplied by another live source; duplicate or metadata-only evidence does not increment the account revision.
- [x] **ACCT-03**: Billing lifecycle operations dispatch by the persisted resource rail and capability; externally managed rails return explicit guidance and never enter Accrue-owned cancellation, retry, swap, proration, or dunning.
- [ ] **ACCT-04**: Existing single-processor hosts retain compatible configuration, deterministic `customer/1`, billable associations, price mapping, webhook handling, Stripe subscriptions, entitlement gates, and advisory-cache isolation; multi-rail activation uses an idempotent backfill, parity check, and opt-in cutover.
- [ ] **ACCT-05**: A host can check purchase eligibility before starting a Stripe or Apple purchase; an equivalent live grant on another rail blocks by default, may be explicitly rendered or overridden as a warning, and never triggers automatic cancellation, transfer, refund, migration, or proration.

### Apple Observation Rail

- [ ] **AAPL-01**: An authenticated account can start or restore an Apple purchase using its opaque entitlement-account UUID as `appAccountToken`; unbound verified lineage can bind once, while email, product, device, unverified claims, and automatic reassignment of existing lineage fail closed.
- [x] **AAPL-02**: Accrue verifies App Store Server Notifications V2 and nested signed transaction evidence against allowed algorithms, Apple trust roots, certificate purpose/time, bundle, environment, and production app identity before changing grants.
- [x] **AAPL-03**: Duplicate, delayed, and out-of-order Apple evidence converges idempotently within rail/environment/lineage, while invalid, unmatched, or ownership-conflicting evidence is quarantined and retried without granting access.
- [x] **AAPL-04**: Scheduled Apple status and transaction-history reconciliation repairs missed notifications and projects active, grace, billing-retry, expiry, refund, and revocation bounds without widening the Stripe subscription enum or relying on notification order.
- [ ] **AAPL-05**: A host can present Apple subscription management honestly as externally managed; v1.59 defers Family Sharing and offer-authoring policy while preserving bounded ownership and offer provenance.

### Offline Study Contract

- [ ] **OFF-01**: A registered device can independently verify an Accrue-issued compact ES256 entitlement proof using a published, versioned protocol and language-neutral golden fixtures without possessing a signing secret.
- [ ] **OFF-02**: Successful reconciliation sets a 30-day revalidation target, shortened by a known earlier provider access bound; crossing it yields `stale_offline` rather than an independent 72-hour cutoff or silent revocation.
- [ ] **OFF-03**: The reference host keeps already-downloaded lessons and local learner progress usable while proof is stale, but pauses new premium downloads, enrollment, export, purchase, account/rail mutation, and other value-expanding actions until reconnect.
- [ ] **OFF-04**: Verification distinguishes `fresh`, `stale_offline`, `denied`, and `invalid` with bounded reason metadata so host code can render policy without changing existing boolean entitlement-gate return types or deleting local data.
- [ ] **OFF-05**: Reconnect authenticates account and device, refreshes due rails under an explicit schedule, compares account revision and device state, and atomically replaces cached proof with a newer allow proof or signed deny tombstone; client proof is never accepted as provider truth.
- [ ] **OFF-06**: Issuance and verification resist algorithm/type/audience confusion, copied proof, wrong device/key, clock rollback, replay, superseded revisions, revoked devices, and key compromise/rotation while exposing no adopter identity, PII, raw receipt, notification body, or provider payload.

### Adopter Proof and Operations

- [ ] **PROOF-01**: An anonymized Phoenix/Crosswake reference host proves Apple purchase to web login and Stripe purchase to iOS login produce coherent access for the same account without manual reconciliation.
- [ ] **PROOF-02**: The reference host deterministically proves duplicate-purchase prevention, extended stale-offline study, restricted value expansion, reconnect, refund/revocation, survivor grants, device replacement, deny tombstones, clock rollback, and key rotation without live-store credentials in merge CI.
- [ ] **PROOF-03**: A solo operator can diagnose account snapshot, source rail/environment/provenance, provider state, reconciliation freshness, account revision, purchase eligibility, device/proof horizon, and quarantine/retry state without raw transaction data or PII.
- [ ] **PROOF-04**: Automatic repair and runbooks cover missed Apple notifications, history cursor recovery, provider outages, ownership conflicts, duplicate charges, stale devices, signing-key rotation/compromise, and reconciliation backlog without routine manual account reconstruction.
- [ ] **PROOF-05**: Public guides, examples, capability matrices, compatibility notes, App Review guidance, release notes, threat model, watchlist, and conformance gates describe one additive multi-rail/offline contract and its explicit v1.59 limits.

## Future Requirements

### Deferred Rails and Policies

- **PLAY-01**: Add Google Play Billing only after Android delivery is scheduled or a second concrete adopter requires it, reusing the v1.59 rail and fixture contracts.
- **POL-01**: Define Family Sharing and shared-purchase ownership/transfer semantics from a sourced adopter need.
- **POL-02**: Add introductory, promotional, and offer-eligibility authoring from a sourced adopter need.
- **MIGR-01**: Support cross-rail migration, proration, automatic cancellation, or rail switching from an explicit product and finance policy.
- **RISK-01**: Add configurable TTL/device-risk matrices, hardware attestation, or advanced fraud scoring after the single v1.59 reference policy is proven.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Google Play Billing | Trigger remains unmet in SEED-007; v1.59 must prove Apple is an adapter before adding Android lifecycle burden. |
| Family Sharing | Apple family ownership differs from the host account model and needs a separate product policy. |
| Automatic purchase ownership transfer | Silent restore-based transfer enables account hopping; conflicting lineage is quarantined instead. |
| Automatic rail migration, cancellation, refund, or proration | Access aggregation is rail-neutral, but finance and lifecycle control remain provider-specific. |
| Arbitrary offline-risk configuration matrix | v1.59 proves one 30-day revalidation and stale-study-continuity contract before multiplying states. |
| Hardware attestation or DRM claims | Device binding reduces copying but cannot guarantee control of a compromised offline device. |
| Crosswake runtime dependency in Accrue core | Accrue owns protocol and fixtures; the host owns mobile runtime, storage, and UI policy. |
| Raw receipts/JWS/provider bodies in grants, tokens, telemetry, or diagnostics | Violates bounded provenance, privacy, and support-safety requirements. |
| Accounting or revenue-recognition engine | Accrue exports operational evidence; accounting policy remains host/adviser-owned. |

## Traceability

Filled during roadmap creation. Every v1.59 requirement must map to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RSCH-01 | Phase 215 | Complete |
| RSCH-02 | Phase 215 | Complete |
| RSCH-03 | Phase 215 | Complete |
| RAIL-04 | Phase 215 | Complete |
| RAIL-05 | Phase 215 | Complete |
| RAIL-01 | Phase 216 | Complete |
| RAIL-02 | Phase 216 | Complete |
| RAIL-03 | Phase 216 | Complete |
| ACCT-01 | Phase 217 | Complete |
| ACCT-02 | Phase 217 | Complete |
| ACCT-03 | Phase 217 | Complete |
| ACCT-04 | Phase 217 | Pending |
| ACCT-05 | Phase 217 | Pending |
| AAPL-01 | Phase 218 | Gaps Found |
| AAPL-02 | Phase 218 | Gaps Found |
| AAPL-03 | Phase 218 | Gaps Found |
| AAPL-04 | Phase 218 | Gaps Found |
| AAPL-05 | Phase 218 | Pending |
| OFF-01 | Phase 219 | Pending |
| OFF-02 | Phase 219 | Pending |
| OFF-03 | Phase 219 | Pending |
| OFF-04 | Phase 219 | Pending |
| OFF-05 | Phase 219 | Pending |
| OFF-06 | Phase 219 | Pending |
| PROOF-01 | Phase 220 | Pending |
| PROOF-02 | Phase 220 | Pending |
| PROOF-03 | Phase 220 | Pending |
| PROOF-04 | Phase 220 | Pending |
| PROOF-05 | Phase 220 | Pending |

**Coverage:**

- v1.59 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0

---
*Requirements defined: 2026-07-31*
*Last updated: 2026-07-31 after v1.59 research synthesis*
