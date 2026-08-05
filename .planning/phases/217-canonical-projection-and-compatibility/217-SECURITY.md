---
phase: 217
slug: canonical-projection-and-compatibility
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-05
---

# Phase 217 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host reference → account lookup | Host identity selects the canonical account. | Authenticated billable reference |
| Provider observations → projector | Qualified provider facts may alter authorization. | Normalized provider evidence |
| Snapshot → billing action | Canonical eligibility controls financial side effects. | Revisioned entitlement decision |
| Compatibility configuration → resolver | Cohort and authority settings select the resolver. | Host configuration and account state |
| Persisted resource → gateway adapter | Stored processor provenance selects an allowed adapter. | Scoped billing resource |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-217-01 | Tampering | `Projector.project/2` | high | mitigate | Account lock, qualified lineage scope, database constraints | closed |
| T-217-02 | Elevation of Privilege | Snapshot account lookup | high | mitigate | Host-authenticated reference and separate provisioning | closed |
| T-217-03 | Information Disclosure | Projector/audit telemetry | high | mitigate | Explicit metadata allowlists and opaque identifiers | closed |
| T-217-04 | Repudiation | Material revision | medium | mitigate | Transactional bounded audit event | closed |
| T-217-04A | Tampering | Follow-up handoff | high | mitigate | Unique transactional Oban job and rollback proof | closed |
| T-217-05 | Tampering | Snapshot fold | high | mitigate | Property-tested deterministic authorization signature | closed |
| T-217-06 | Denial of Service | Projector contention | medium | mitigate | Account row lock and bounded concurrent tests | closed |
| T-217-07 | Repudiation | Fixture/reason drift | medium | mitigate | Checked-in corpus and stable reason vocabulary | closed |
| T-217-08 | Tampering | Equivalence/override | high | mitigate | Qualified catalog identity, bounded override, revision recheck | closed |
| T-217-08A | Elevation of Privilege | First-purchase provisioning | high | mitigate | Authorize billable reference before provisioning | closed |
| T-217-09 | Repudiation | Override/Stripe continuation | high | mitigate | Bounded audit facts and durable operation ID | closed |
| T-217-10 | Denial of Service | Preflight | medium | mitigate | Closed actionable failure reasons | closed |
| T-217-11 | Tampering | Ambiguous Stripe retry | high | mitigate | Reconcile same idempotency identity before a second create | closed |
| T-217-11A | Information Disclosure | Purchase telemetry/audit | high | mitigate | Facade allowlists and forbidden-key regression tests | closed |
| T-217-12 | Tampering | Compatibility authority | high | mitigate | Closed modes/cohorts and fail-closed resolver selection | closed |
| T-217-13 | Elevation of Privilege | Cutover blockers | high | mitigate | Clean-window evidence and zero-blocker requirement | closed |
| T-217-14 | Information Disclosure | Compatibility telemetry | high | mitigate | Shared allowlist and seeded-secret regression tests | closed |
| T-217-15 | Tampering | Backfill/rollback | high | mitigate | Idempotent identities, no provider mutations, preservation tests | closed |
| T-217-16 | Tampering | Gateway dispatch | high | mitigate | Persisted provenance-only adapter resolution | closed |
| T-217-17 | Elevation of Privilege | Resource authorization/order | high | mitigate | Scope resource before adapter resolution | closed |
| T-217-18 | Tampering | Apple lifecycle isolation | high | mitigate | Externally managed guidance with forbidden-call tests | closed |
| T-217-19 | Information Disclosure | Lifecycle telemetry/guidance | high | mitigate | Action-specific allowlists and forbidden-key tests | closed |
| T-217-SC | Tampering | Package-manager installs | low | accept | Locked project dependencies; no installation in the phase | closed |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-217-01 | T-217-SC | The phase uses only locked project dependencies and performs no package installation. | Phase 217 threat model | 2026-08-05 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-05 | 23 | 23 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-05
