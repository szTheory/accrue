# Requirements: Accrue

**Defined:** 2026-08-05
**Milestone:** v1.60 — First-Adopter iOS Bridge & Proof
**Core Value:** A Phoenix developer can install Accrue and launch a real SaaS with clear, production-grade billing state.

## v1.60 Requirements

### Offline client

- [x] **IOS-01**: A host can import an iOS-compatible Accrue SwiftPM client whose proof verification, high-water, and allow/deny replacement match the canonical vectors.
- [x] **IOS-02**: The client verifies only server-issued ES256 proof, binds it to the registered device, and preserves stale-study-only continuity.
- [ ] **IOS-03**: The client performs authenticated reconnect and replaces cached state only with a verified newer allow or signed deny.

### Crosswake bridge

- [ ] **BRDG-01**: A Crosswake host may declare a route-scoped command delegate without bypassing protocol, version, route, origin, pack, or manifest validation.
- [ ] **BRDG-02**: Unregistered, malformed, inactive-route, cross-origin, or failing host commands deny safely and cannot inject replies.

### First-adopter host

- [ ] **HOST-01**: The host-local StoreKit adapter initiates purchase with server-issued `appAccountToken`, observes updates/current entitlements, and submits evidence without granting access locally.
- [ ] **HOST-02**: Restore and reconnect converge through Accrue's verified Apple and offline paths; duplicate or mismatched evidence fails closed.
- [ ] **HOST-03**: StoreKit Test proves the full purchase, restore, refresh, stale-proof, reconnect, and disablement contract without a physical-device claim.

### Readiness truth

- [ ] **READY-01**: Public material and generated support truth describe the runtime lane as device-gated until approved physical evidence exists.
- [ ] **READY-02**: The retained compiler warnings are removed and the advisory Apple delivery smoke/public-material review procedures are current.

## Out of Scope

| Feature | Reason |
|---|---|
| Generic Crosswake commerce API | The adapter is host-local for one active adopter. |
| Android, Google Play, Family Sharing, migration, proration | No concrete delivery trigger and outside the v1.59 contract. |
| Device-runtime promotion | Physical iPhone authorization and redacted evidence are not yet available. |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| IOS-01, IOS-02, IOS-03 | Phase 223 | Pending |
| BRDG-01, BRDG-02 | Phase 224 | Pending |
| HOST-01, HOST-02, HOST-03 | Phase 225 | Pending |
| READY-01, READY-02 | Phase 226 | Pending |

**Coverage:** 10 v1.60 requirements, 10 mapped, 0 unmapped.

---
*Requirements defined: 2026-08-05 after starting v1.60.*
