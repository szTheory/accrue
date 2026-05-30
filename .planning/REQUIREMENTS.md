# Requirements: Accrue v1.46

**Defined:** 2026-05-29
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one.

## v1.46 Requirements

### Maintenance & Closure

- [x] **MNT-01**: Perform routine issue triage and repository maintenance.

## Future Requirements

- **Multi-channel Dunning (SMS/Push via Chimeway)**: High compliance risk, better left to host app integration.
- **Rich metered/tiered entitlement math**: Out of scope unless adopter demand surfaces; risks accounting-territory drift.
- **Disputes / chargebacks visibility**: Intake-gated; read-only visibility only.
- **Audit bridge (Threadline integration)**: Intake-gated; defer execution.

## Out of Scope

| Feature | Reason |
|---------|--------|
| FIN-03 / Revenue recognition | Explicit non-goal. Accrue is a billing library, not an accounting platform. |
| MRR/ARR analytics product | Core ledger primitives exist; opinionated math left to host. |
| Merchant-of-record processors | PROC-08 bounded; MoR processors not in scope. |
| Marketplace payouts (Hyperwallet) | Durable no-go. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MNT-01 | Phase 151 | Complete |

**Coverage:**
- Active requirements: 1 total
- Mapped to phases: 1
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-29*
*Last updated: 2026-05-30 after Phase 153 closed MNT-01*
