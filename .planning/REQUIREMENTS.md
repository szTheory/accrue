# Requirements: Accrue v1.61 CI Evidence & Critical-Path Hardening

**Defined:** 2026-08-08
**Core Value:** A Phoenix developer can install Accrue and ship subscription billing with trustworthy, production-grade evidence.

## v1 Requirements

### Required-Lane Reliability

- [x] **REL-01**: A maintainer can reproduce and classify each currently failing required CI signature as deterministic code/configuration, test-isolation, lifecycle, or external-infrastructure failure.
- [x] **REL-02**: Required release and admin checks pass with the repaired root cause, while their meaningful assertions and failure artifacts remain available.
- [x] **REL-03**: A matrix-wide symptom is reported and triaged as one root-cause incident when its failing signature is the same across matrix cells.

### Evidence Baseline

- [ ] **BASE-01**: A maintainer can review a durable, privacy-safe baseline of workflow wall time, queue delay, job/step duration, reruns, cache behavior, Docker/browser setup cost, provider state, and root failure signature across comparable runs.
- [ ] **BASE-02**: Required, skipped, and advisory provider evidence is visibly distinguished so a non-run provider lane cannot be mistaken for release proof.

### Critical Path and Ownership

- [ ] **PATH-01**: A maintainer can identify the measured critical path and the exact dependency or duplicated work selected for the first optimization, with before-state evidence and a documented rollback.
- [ ] **PATH-02**: One validated CI critical-path improvement reduces measured wait or duplicate work without removing required release, host, browser, or provider evidence.
- [ ] **OWN-01**: A host maintainer can determine whether Node, browser installation, and Playwright setup are owned by the host or CI, and can diagnose the documented setup failure modes.

### Safety and Operability

- [ ] **SAFE-01**: CI maintains stable required-check identity and artifacts while relevance gating, dependency ordering, or caching changes are evaluated.
- [ ] **SAFE-02**: Each CI change has an executable or recorded negative-control validation and rollback path; tests are not deleted or retried merely to hide failures.

## Future Requirements

- **FUT-01**: Re-shape the release matrix or branch-protection rules after the baseline proves which evidence is duplicate, required, or advisory.
- **FUT-02**: Resume host-local StoreKit Test, physical-device proof, or Crosswake runtime work only when its owner and external authorization are available.
- **FUT-03**: Resume the parked Admin UI ratchet only with an explicit admin-UI milestone and maintainer time.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New billing, entitlement, or adopter product features | This is stable-core CI/release-readiness work. |
| StoreKit adapter, iPhone testing, or Crosswake implementation | These are host/external-owner concerns with no current authorization or device access. |
| Admin UI redesign or ratchet convergence | The admin ratchet is deliberately parked and is not a CI-performance justification. |
| Deleting, broadly demoting, or masking tests | Signal must be repaired and measured before any test-value decision. |
| Matrix collapse, branch-protection edits, or cache rewrite before evidence | These changes can weaken release confidence and require baseline proof first. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 225 | Complete |
| REL-02 | Phase 225 | Complete |
| REL-03 | Phase 225 | Complete |
| BASE-01 | Phase 226 | Gaps Found |
| BASE-02 | Phase 226 | Gaps Found |
| PATH-01 | Phase 227 | Pending |
| PATH-02 | Phase 227 | Pending |
| OWN-01 | Phase 226 | Gaps Found |
| SAFE-01 | Phase 227 | Pending |
| SAFE-02 | Phase 227 | Pending |

**Coverage:**

- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-08-08*
*Last updated: 2026-08-08 after v1.61 roadmap creation*
