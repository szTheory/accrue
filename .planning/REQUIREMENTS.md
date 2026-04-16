# Requirements: Accrue v1.1 Stabilization + Adoption

**Defined:** 2026-04-16  
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one.

## v1.1 Requirements

Requirements for the v1.1 stabilization milestone. The milestone proves Accrue from the perspective of a real user integrating the libraries into a minimal Phoenix app, then turns that proof into CI coverage, docs, adoption assets, and quality hardening.

### Host App Dogfood

- [x] **HOST-01**: A minimal Phoenix host app exists in the repository as the canonical dogfood app for `accrue` and `accrue_admin`.
- [x] **HOST-02**: The host app uses the public installer and package APIs rather than private shortcuts or hand-wired internals.
- [x] **HOST-03**: The host app has at least one realistic billable schema and generated `MyApp.Billing` facade.
- [ ] **HOST-04**: The host app mounts the scoped webhook endpoint and verifies signed Fake/Stripe-shaped webhook payloads end to end.
- [ ] **HOST-05**: The host app mounts `accrue_admin` behind a realistic auth/session boundary.
- [ ] **HOST-06**: A user-facing checkout/subscription flow works through the host app against the Fake processor without network access.
- [ ] **HOST-07**: An admin-facing flow can inspect billing state, view webhook/event history, and perform at least one audited admin action.
- [x] **HOST-08**: The host app can be rebuilt from a clean checkout with documented commands and no hidden local state.

### CI Integration Gate

- [ ] **CI-01**: GitHub Actions runs the host app setup and integration suite on pull requests and pushes to `main`.
- [ ] **CI-02**: CI fails on host-app compile warnings, test failures, browser failures, docs-link drift, and generated artifact drift.
- [ ] **CI-03**: CI exercises both package-local tests and host-app user-facing flows in a clear release-gate order.
- [ ] **CI-04**: CI publishes useful artifacts for failed host-app browser runs, including screenshots or traces where practical.
- [ ] **CI-05**: CI keeps live Stripe checks opt-in/advisory while making Fake-backed user-facing flows mandatory.
- [ ] **CI-06**: CI annotation sweeps remain warning/error blockers for release-facing jobs.

### First-User DX

- [ ] **DX-01**: Installer output and generated files are validated against the host app and remain idempotent on rerun.
- [ ] **DX-02**: Setup failures for missing config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable errors.
- [ ] **DX-03**: Quickstart docs are updated from the host-app path and avoid hand-wavy or skipped setup steps.
- [ ] **DX-04**: Troubleshooting docs cover the most likely first-hour failures discovered by dogfooding.
- [ ] **DX-05**: Public APIs used by the host app are documented and avoid requiring private module knowledge.
- [ ] **DX-06**: Package version snippets, source links, and HexDocs guide links remain correct for both packages.
- [ ] **DX-07**: Host-app setup supports both path-dependency development and Hex-style dependency validation.

### Adoption Assets

- [ ] **ADOPT-01**: The repository includes a maintained example or demo path that new users can run locally.
- [ ] **ADOPT-02**: The docs include a tutorial that follows the host app from install through first subscription and admin inspection.
- [ ] **ADOPT-03**: The project has issue templates for bug reports, integration problems, docs gaps, and feature requests.
- [ ] **ADOPT-04**: The README clearly distinguishes package quickstart, example app, and production hardening guidance.
- [ ] **ADOPT-05**: Release notes and docs explain how users should choose between Fake, Stripe test mode, and live Stripe flows.
- [ ] **ADOPT-06**: Adoption docs preserve the established Accrue brand voice and avoid marketing claims not proven by the host app.

### Quality Hardening

- [ ] **QUAL-01**: A security pass reviews webhook/auth/admin boundaries introduced or exercised by the host app.
- [ ] **QUAL-02**: Performance checks cover webhook ingest latency and admin page responsiveness on realistic seeded data.
- [ ] **QUAL-03**: Compatibility checks cover supported Elixir/OTP/Phoenix/LiveView combinations at the package or host-app level.
- [ ] **QUAL-04**: Accessibility and responsive-browser checks cover the admin flows used in the host app.
- [ ] **QUAL-05**: Public error messages and logs avoid leaking Stripe secrets, webhook payload secrets, tokens, or PII.
- [ ] **QUAL-06**: The release gate documents known advisory checks separately from required blockers.

### Expansion Discovery

- [ ] **DISC-01**: Tax support options are evaluated and captured as a future milestone recommendation.
- [ ] **DISC-02**: Revenue recognition/export options are evaluated and captured as a future milestone recommendation.
- [ ] **DISC-03**: Additional processor adapter candidates are evaluated without weakening the existing Stripe-first abstraction.
- [ ] **DISC-04**: Organization/multi-tenant billing flows are evaluated against Sigra and host-owned schema constraints.
- [ ] **DISC-05**: Expansion ideas are captured as roadmap candidates, seeds, or backlog entries rather than partially implemented in v1.1.

## Future Requirements

Deferred until after v1.1 unless pulled into a later milestone:

### Product Expansion

- **TAX-01**: First-party tax calculation or Stripe Tax orchestration.
- **REV-01**: Revenue recognition exports or accounting-system handoff.
- **PROC-08**: First-party non-Stripe processor adapter.
- **ORG-01**: Organization-first billing flows once Sigra organization support is ready.
- **HOST-09**: Hosted public demo environment, if local example adoption proves useful.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Building tax/revenue recognition in v1.1 | Discovery is in scope; implementation would distract from stabilization. |
| Building a second payment processor in v1.1 | The milestone should validate existing abstraction boundaries first. |
| Making live Stripe mandatory in CI | Fake-backed E2E must be deterministic; live Stripe remains opt-in/advisory. |
| Rewriting the core billing architecture | v1.1 is a stabilization milestone, not a redesign. |
| Shipping a hosted SaaS around Accrue | Adoption assets can include examples; hosted service work is a separate product decision. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HOST-01 | Phase 10 | Complete |
| HOST-02 | Phase 10 | Complete |
| HOST-03 | Phase 10 | Complete |
| HOST-04 | Phase 10 | Pending |
| HOST-05 | Phase 10 | Pending |
| HOST-06 | Phase 10 | Pending |
| HOST-07 | Phase 10 | Pending |
| HOST-08 | Phase 10 | Complete |
| CI-01 | Phase 11 | Pending |
| CI-02 | Phase 11 | Pending |
| CI-03 | Phase 11 | Pending |
| CI-04 | Phase 11 | Pending |
| CI-05 | Phase 11 | Pending |
| CI-06 | Phase 11 | Pending |
| DX-01 | Phase 12 | Pending |
| DX-02 | Phase 12 | Pending |
| DX-03 | Phase 12 | Pending |
| DX-04 | Phase 12 | Pending |
| DX-05 | Phase 12 | Pending |
| DX-06 | Phase 12 | Pending |
| DX-07 | Phase 12 | Pending |
| ADOPT-01 | Phase 13 | Pending |
| ADOPT-02 | Phase 13 | Pending |
| ADOPT-03 | Phase 13 | Pending |
| ADOPT-04 | Phase 13 | Pending |
| ADOPT-05 | Phase 13 | Pending |
| ADOPT-06 | Phase 13 | Pending |
| QUAL-01 | Phase 14 | Pending |
| QUAL-02 | Phase 14 | Pending |
| QUAL-03 | Phase 14 | Pending |
| QUAL-04 | Phase 14 | Pending |
| QUAL-05 | Phase 14 | Pending |
| QUAL-06 | Phase 14 | Pending |
| DISC-01 | Phase 15 | Pending |
| DISC-02 | Phase 15 | Pending |
| DISC-03 | Phase 15 | Pending |
| DISC-04 | Phase 15 | Pending |
| DISC-05 | Phase 15 | Pending |

**Coverage:**
- v1.1 requirements: 38 total
- Mapped to phases: 38
- Unmapped: 0

---
*Requirements defined: 2026-04-16*
*Last updated: 2026-04-16 after milestone initialization*
