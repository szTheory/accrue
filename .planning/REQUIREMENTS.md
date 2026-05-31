# Requirements: Accrue v1.48 Release Readiness + Stable Core Posture

**Defined:** 2026-05-31
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version.
**Status:** Active

## v1.48 Requirements

### Release Readiness

- [ ] **REL-01**: Maintainer can verify the next linked release line after `1.3.0` has coherent package versions, changelog entries, Release Please state, git tags, and release-runbook instructions across `accrue`, `accrue_admin`, and `accrue_portal`.
- [ ] **REL-02**: Maintainer can run the deterministic release gate for all three packages and get one documented pass/fail artifact covering tests, docs, dialyzer, credo, package docs, support-matrix drift, adoption proof, and host integration checks.
- [ ] **REL-03**: Maintainer can publish the linked Hex release in the documented order with canonical proof recorded in planning, changelogs, and release notes.

### Stable-Core Positioning

- [ ] **POS-01**: Developer evaluating Accrue can read the public docs and package READMEs and understand that Accrue is stable-core / demand-driven expansion, not a broad feature-chasing billing product.
- [ ] **POS-02**: Developer adopting Accrue can see the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without reading planning internals.
- [ ] **POS-03**: Maintainer can verify that release notes, package docs, support matrix, adoption proof docs, and planning mirrors all describe the same stable-core posture.

### Backlog Anchor Closure

- [ ] **BAK-01**: Maintainer can distinguish stale historical backlog anchors from active scope because v1.17 friction anchors, resolved seeds, dormant seeds, and deferred ideas are archived, reclassified, or given explicit revisit triggers.
- [ ] **BAK-02**: Maintainer can run or inspect a planning hygiene proof that no stale roadmap pointer suggests broad feature work is currently active.

### Pause Rule

- [ ] **PAU-01**: Maintainer can close v1.48 with an explicit pause rule: after release readiness, broad feature milestones remain closed unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

## Future Requirements

- **ECO-01**: Ecosystem integration blueprints for Chimeway/Mailglass, Threadline, Sigra/Lockspire, Relyra, and Scrypath remain future-roadmap seeds only.
- **ENT-EXT-01**: Rich metered/tiered/range entitlement math beyond seat counts remains deferred until a concrete adopter contract requires it.
- **FIN-03**: App-owned finance exports remain a standing non-goal unless strategy explicitly changes.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New billing primitives | v1.48 is release readiness and posture closure, not new product surface. |
| New processor breadth | Processor changes require behavior, support matrix, docs, examples/verifiers, and release notes together; no current adopter failure justifies this. |
| New admin product dashboards | Existing dunning/recovery/admin capabilities are sufficient for stable-core positioning; polish-only dashboard work is backlog. |
| Ecosystem integration implementation | SEED-002 remains strategic future-roadmap material, not current release-readiness scope. |
| Breaking public API changes | The stable-core posture requires zero breaking-change pain through v1.x. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 159 | Pending |
| REL-02 | Phase 159 | Pending |
| REL-03 | Phase 159 | Pending |
| POS-01 | Phase 160 | Pending |
| POS-02 | Phase 160 | Pending |
| POS-03 | Phase 160 | Pending |
| BAK-01 | Phase 161 | Pending |
| BAK-02 | Phase 161 | Pending |
| PAU-01 | Phase 161 | Pending |

**Coverage:**
- v1.48 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-05-31 after v1.48 roadmap creation*
