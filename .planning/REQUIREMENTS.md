# Requirements: Accrue

**Defined:** 2026-07-01
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.55 Requirements

### Software Quality Evaluation

- [ ] **QLT-01**: Maintainer can read one evidence-backed audit that ranks Accrue's weakest adoption, production, maintenance, support, architecture, data, UI, security, release, upgrade, and OSS trust dimensions without treating every category as equally important.
- [ ] **QLT-02**: The audit identifies the top five weakness deep dives with repo evidence, practical consequences, highest-leverage fixes, and what not to over-fix.
- [ ] **QLT-03**: The audit separately covers adopter journey, production/SRE journey, maintainer journey, GSD sanity, and missing project-specific dimensions.
- [ ] **QLT-04**: The audit marks strong or not-applicable dimensions honestly instead of manufacturing fake concerns.
- [ ] **QLT-05**: The audit separates direct repo facts from assumptions and cites evidence paths for low scores.

### CI/CD Evaluation

- [ ] **CI-01**: Maintainer can see the current CI workflow/job topology, trigger model, matrix shape, service usage, cache posture, and likely critical path in one document.
- [ ] **CI-02**: The CI audit identifies duplicated setup, slow/static bottlenecks, flaky/determinism risks, cache risks, release risks, and provider-parity risks with repo evidence.
- [ ] **CI-03**: The CI audit recommends a target pipeline that preserves high-value gates while measuring before demoting or deleting checks.
- [ ] **CI-04**: The CI audit classifies follow-up work by priority, expected impact, tradeoff, implementation approach, verification, and rollback.
- [ ] **CI-05**: The CI audit records required baseline metrics still needing live GitHub run data rather than pretending static inspection is enough.

### Database Schema Contract

- [ ] **DB-01**: Maintainer can read one ADR explaining the current Accrue-owned Postgres schema contract: default `billing`, explicit `public`, Ecto compile-time schema prefix, migration prefix helpers, and host-owned data-migration responsibility.
- [ ] **DB-02**: The ADR explains why v1.55 keeps `billing` instead of switching to `accrue`, including pros/cons and upgrade risk.
- [ ] **DB-03**: The ADR lists concrete future hardening checks for prefix agreement, raw SQL qualification, installer/docs/test coverage, and explicit old-default compatibility.
- [ ] **DB-04**: The ADR identifies which schema-related work belongs in a future implementation milestone and which work is not worth doing now.

### Hardening Roadmap

- [ ] **RD-01**: Maintainer gets a ranked top-10 hardening list with area, quality dimension improved, impact, effort, risk reduction, timing, and done criteria.
- [ ] **RD-02**: Follow-up work is grouped into milestone-sized slices rather than one giant cleanup grab bag.
- [ ] **RD-03**: The roadmap ties every recommended implementation slice back to concrete risk found in the audits.
- [ ] **RD-04**: The roadmap explicitly defers polish-only or overbuilt work that does not reduce adoption, production, support, or maintenance risk.

## Standing Verification Anchors

These anchors remain active outside a feature milestone because CI uses them to
keep the public docs and planning mirrors aligned:

- **POS-01**: Public docs and package READMEs describe Accrue as stable-core /
  demand-driven expansion.
- **POS-02**: Adopter-facing docs describe the supported SaaS billing loop,
  processor support boundaries, and package ownership boundaries.
- **POS-03**: Release notes, package docs, support matrix, adoption proof docs,
  and planning mirrors describe the same stable-core posture.

## Archived Milestone Requirements

Completed milestone requirements are archived under `.planning/milestones/`.
The most recent archive is `.planning/milestones/v1.54-REQUIREMENTS.md`.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| QLT-01 | Phase 201 | Pending |
| QLT-02 | Phase 201 | Pending |
| QLT-03 | Phase 201 | Pending |
| QLT-04 | Phase 201 | Pending |
| QLT-05 | Phase 201 | Pending |
| CI-01 | Phase 202 | Pending |
| CI-02 | Phase 202 | Pending |
| CI-03 | Phase 202 | Pending |
| CI-04 | Phase 202 | Pending |
| CI-05 | Phase 202 | Pending |
| DB-01 | Phase 203 | Pending |
| DB-02 | Phase 203 | Pending |
| DB-03 | Phase 203 | Pending |
| DB-04 | Phase 203 | Pending |
| RD-01 | Phase 204 | Pending |
| RD-02 | Phase 204 | Pending |
| RD-03 | Phase 204 | Pending |
| RD-04 | Phase 204 | Pending |

**Coverage:**
- v1.55 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-07-01*
*Last updated: 2026-07-01 after v1.55 milestone initialization*
