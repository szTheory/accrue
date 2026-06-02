# Requirements: Accrue

**Defined:** 2026-06-01
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1 Requirements

### Adoption Evidence & Realistic Demo (EVD)

- [ ] **EVD-01**: Define a realistic SaaS cohort persona and JTBD domain for `examples/accrue_host`.
- [ ] **EVD-02**: Implement rich, realistic database seeds (users, plans, subscriptions, usage) that populate the demo app to immediately demonstrate the Admin UI value.
- [x] **EVD-03**: Create a seamless Docker-based local development environment for the demo app.
- [x] **EVD-04**: Optimize Docker caching layers (e.g., Tailwind, Hex deps) to ensure rapid local iteration without redownloading dependencies.

### E2E Automation & Shift-Left (E2E)

- [x] **E2E-01**: Implement robust Playwright E2E tests for the primary onboarding and checkout happy paths.
- [x] **E2E-02**: Implement robust Playwright E2E tests for billing management (upgrade, downgrade, cancel, payment methods).
- [x] **E2E-03**: Integrate these tests into CI to run automatically, demonstrating a shift-left devops mindset.
- [x] **E2E-04**: Ensure tests are deterministic and flake-free when run against the rich seed data.

### DX Documentation (DOC)

- [ ] **DOC-01**: Write/update a clear "Start Here" DX summary at the top of the demo app's README.
- [ ] **DOC-02**: Document the Docker setup and commands needed to spin up the demo and explore the Admin UI.
- [ ] **DOC-03**: Ensure documentation is framed around the user persona and their goals, rather than just technical implementation details.

## v2 Requirements

(None for this milestone)

## Out of Scope

| Feature | Reason |
|---------|--------|
| New core billing primitives | This milestone focuses purely on adoption evidence, demoing existing features, and DX. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVD-01 | Phase 163 | Pending |
| EVD-02 | Phase 163 | Pending |
| EVD-03 | Phase 164 | Complete |
| EVD-04 | Phase 164 | Complete |
| E2E-01 | Phase 165 | Complete |
| E2E-02 | Phase 165 | Complete |
| E2E-03 | Phase 165 | Complete |
| E2E-04 | Phase 165 | Complete |
| DOC-01 | Phase 166 | Pending |
| DOC-02 | Phase 166 | Pending |
| DOC-03 | Phase 166 | Pending |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-01*
*Last updated: 2026-06-01 after v1.49 milestone definition*
