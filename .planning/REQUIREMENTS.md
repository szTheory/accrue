# Requirements: Accrue v1.3 Tax + Organization Billing

**Defined:** 2026-04-17
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version.

## v1.3 Requirements

Requirements for the v1.3 Tax + Organization Billing milestone. Each maps to exactly one roadmap phase.

### Stripe Tax

- [x] **TAX-01**: Developer can enable Stripe Tax for new subscription and checkout flows through Accrue's public billing API.
- [x] **TAX-02**: Developer can collect and validate customer tax location before creating tax-enabled recurring payments.
- [x] **TAX-03**: User or admin can identify and recover from missing or invalid tax location states without silent tax rollout failure.
- [x] **TAX-04**: Existing recurring subscriptions have explicit migration guidance before automatic tax rollout.

### Organization Billing

- [ ] **ORG-01**: Host app can make an organization billable using Accrue's existing `Accrue.Billable` ownership model.
- [ ] **ORG-02**: Sigra-backed host flow can bill the active organization while preserving membership and admin scope boundaries.
- [ ] **ORG-03**: Org admins cannot access or mutate another organization's billing state through public, admin, webhook replay, or export paths.

### Finance Handoff

- [ ] **FIN-01**: Developer has documented Stripe-native finance handoff paths for Revenue Recognition, Sigma, and Data Pipeline.
- [ ] **FIN-02**: Finance handoff docs identify supported data boundaries and explicitly exclude Accrue-owned accounting or revenue-recognition logic.

### Verification

- [ ] **VERIFY-01**: Fake-backed tests, host integration tests, and browser/admin checks prove tax, org billing, and finance-boundary behavior.

## Future Requirements

Deferred to later milestones. Tracked but not in the v1.3 roadmap.

### Processor Expansion

- **PROC-08**: Official second processor adapter, preserved behind the current Stripe-first custom-processor boundary until demand justifies a separate-package or host-owned adapter strategy.

### Finance Products

- **FIN-03**: App-owned downloadable finance exports for invoices, payments, subscriptions, and tax evidence after host-authorized audiences, delivery rules, retention, and storage boundaries are explicit.
- **FIN-04**: Revenue recognition or accounting-engine features only if Accrue deliberately expands beyond billing orchestration into accounting-domain semantics.

### Multi-Tenant Depth

- **ORG-04**: Broader non-Sigra tenancy recipes for Pow, phx.gen.auth, or custom org models after the Sigra-first proof establishes the row-scoped contract.

## Out of Scope

Explicitly excluded from v1.3 to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Custom tax calculation engine | Stripe Tax owns jurisdiction and rate logic; Accrue should orchestrate Stripe Tax instead of carrying compliance risk. |
| Schema-prefix tenancy | v1.3 uses row-scoped ownership through `owner_type` and `owner_id`; schema prefixes add migration and operational cost without matching Accrue's current model. |
| Accrue-owned revenue recognition engine | Billing is not accounting; Stripe Revenue Recognition and downstream accounting tools own accrual schedules and GAAP/ASC 606 interpretation. |
| Broad app-level finance CSV product | Export audiences, storage, retention, and delivery rules need clearer demand; v1.3 only documents Stripe-native handoff paths. |
| Official second processor adapter | Still a planted seed; adding another processor would weaken the Stripe-first focus of the tax and org-billing milestone. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TAX-01 | Phase 18 | Complete |
| TAX-02 | Phase 19 | Complete |
| TAX-03 | Phase 19 | Complete |
| TAX-04 | Phase 19 | Complete |
| ORG-01 | Phase 20 | Pending |
| ORG-02 | Phase 20 | Pending |
| ORG-03 | Phase 20 | Pending |
| FIN-01 | Phase 22 | Pending |
| FIN-02 | Phase 22 | Pending |
| VERIFY-01 | Phase 21, Phase 22 | Pending |

**Coverage:**
- v1.3 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-04-17*
*Last updated: 2026-04-17 after 19-05 execution update*
