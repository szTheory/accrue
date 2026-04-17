# Requirements: Accrue v1.2 Adoption + Trust

**Defined:** 2026-04-17  
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one.

## v1.2 Requirements

Requirements for v1.2 focus on adoption, trust, and decision-quality expansion planning. The milestone should make Accrue easier to evaluate and integrate without starting large product-expansion implementation.

### Canonical Demo

- [x] **DEMO-01**: User can clone the repository and run `examples/accrue_host` as the canonical local demo with documented prerequisites and commands.
- [x] **DEMO-02**: User can seed or create a Fake-backed subscription in the demo without live Stripe credentials.
- [x] **DEMO-03**: User can inspect billing state and replay a webhook/admin action through the mounted admin UI in the demo.
- [x] **DEMO-04**: User can run a single CI-equivalent local command that verifies the demo setup and focused host proofs.
- [x] **DEMO-05**: User can understand which demo commands are for local evaluation, CI validation, Hex-style smoke validation, and production setup.
- [x] **DEMO-06**: Maintainer can detect drift between the demo path and documented tutorial commands before release.

### Adoption Front Door

- [x] **ADOPT-01**: User lands on a root repository README that explains Accrue, the two packages, the local demo, docs, and production-hardening path.
- [x] **ADOPT-02**: User can follow a tutorial from install through first subscription, signed webhook ingest, admin inspection/replay, and focused host tests.
- [ ] **ADOPT-03**: User can choose between Fake, Stripe test mode, and live Stripe flows using clear release and docs guidance.
- [x] **ADOPT-04**: User can find issue templates for bug reports, integration problems, documentation gaps, and feature requests.
- [x] **ADOPT-05**: User can identify supported public APIs and generated host-owned boundaries without relying on private modules.
- [x] **ADOPT-06**: User-facing docs preserve Accrue's established brand voice and avoid claims not proven by the host app.

### Trust Hardening

- [ ] **TRUST-01**: Maintainer has a security review artifact for webhook, auth, admin, replay, and generated-host boundaries.
- [ ] **TRUST-02**: Maintainer can run seeded performance smoke checks for webhook ingest latency and admin page responsiveness.
- [ ] **TRUST-03**: Maintainer can verify supported Elixir, OTP, Phoenix, and LiveView compatibility at the package or host-app level.
- [ ] **TRUST-04**: User-facing admin flows used by the demo have accessibility and responsive-browser checks.
- [ ] **TRUST-05**: Public errors, logs, docs, and retained artifacts are reviewed for Stripe secrets, webhook secrets, tokens, and PII leakage.
- [ ] **TRUST-06**: Release-gate docs clearly distinguish required blockers from advisory checks such as live Stripe validation.

### Expansion Discovery

- [ ] **DISC-01**: Tax support options are evaluated and captured as a future milestone recommendation.
- [ ] **DISC-02**: Revenue recognition and export options are evaluated and captured as a future milestone recommendation.
- [ ] **DISC-03**: Additional processor adapter candidates are evaluated without weakening the existing Stripe-first abstraction.
- [ ] **DISC-04**: Organization and multi-tenant billing flows are evaluated against Sigra and host-owned schema constraints.
- [ ] **DISC-05**: Expansion candidates are ranked into a recommended next implementation milestone, backlog, or planted seed.

## Future Requirements

Deferred until after v1.2 unless a blocker emerges during planning:

### Product Expansion

- **TAX-01**: First-party tax calculation or Stripe Tax orchestration.
- **REV-01**: Revenue recognition exports or accounting-system handoff.
- **PROC-08**: First-party non-Stripe processor adapter.
- **ORG-01**: Organization-first billing flows once Sigra organization support is ready.
- **HOST-09**: Hosted public demo environment, if local example adoption proves useful.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Implementing tax support in v1.2 | Discovery is in scope; implementation would be a separate product milestone. |
| Implementing revenue recognition or accounting exports in v1.2 | The project needs a decision-quality recommendation before adding accounting surface area. |
| Building a second payment processor in v1.2 | Accrue should preserve Stripe-first clarity until processor demand and abstraction boundaries are validated. |
| Implementing organization/multi-tenant billing in v1.2 | This depends on Sigra/org decisions and should not be partially bolted onto the current host-owned model. |
| Hosted public demo | v1.2 focuses on a canonical local demo; hosting introduces ops/security scope that can follow if local adoption proves valuable. |
| Rewriting core billing architecture | Current architecture is validated; v1.2 is about adoption and trust, not redesign. |

## Traceability

Which phases cover which requirements. Updated during phase execution.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEMO-01 | Phase 13 | Complete |
| DEMO-02 | Phase 13 | Complete |
| DEMO-03 | Phase 13 | Complete |
| DEMO-04 | Phase 13 | Complete |
| DEMO-05 | Phase 13 | Complete |
| DEMO-06 | Phase 13 | Complete |
| ADOPT-01 | Phase 14 | Complete |
| ADOPT-02 | Phase 13 + Phase 14 | Complete |
| ADOPT-03 | Phase 14 | Pending |
| ADOPT-04 | Phase 14 | Complete |
| ADOPT-05 | Phase 14 | Complete |
| ADOPT-06 | Phase 14 | Complete |
| TRUST-01 | Phase 15 | Pending |
| TRUST-02 | Phase 15 | Pending |
| TRUST-03 | Phase 15 | Pending |
| TRUST-04 | Phase 15 | Pending |
| TRUST-05 | Phase 15 | Pending |
| TRUST-06 | Phase 15 | Pending |
| DISC-01 | Phase 16 | Pending |
| DISC-02 | Phase 16 | Pending |
| DISC-03 | Phase 16 | Pending |
| DISC-04 | Phase 16 | Pending |
| DISC-05 | Phase 16 | Pending |

**Coverage:**
- v1.2 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0

---
*Requirements defined: 2026-04-17*
*Last updated: 2026-04-17 after v1.2 milestone start*
