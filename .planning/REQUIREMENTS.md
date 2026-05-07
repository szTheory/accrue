# Requirements: Accrue v1.36

**Defined:** 2026-05-06  
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1 Requirements

### Processor Contract Closure

- [x] **PROC-21**: Host code can call `Accrue.Billing.update_customer/2` on the official Stripe, Fake, and Braintree processors with one explicit first-party support contract and deterministic proof.
- [x] **PROC-22**: Host code can use the supported subscription cancellation path on Stripe, Fake, and Braintree through the generic billing facade without staged-label drift or ambiguous processor semantics.
- [x] **PROC-23**: Maintainers and adopters can inspect capability labels for customer update and cancellation semantics and see runtime truth that matches actual supported behavior, with unsupported lifecycle branches still failing clearly.
- [x] **PROC-24**: Public docs, planning mirrors, example-host proofs, and merge-blocking verifiers repeat the finalized dual-provider core contract so staged-vs-first-party drift is caught automatically.

## v2 Requirements

### Deferred Processor Expansion

- **PROC-25**: Host code can schedule subscriptions through a first-party dual-provider contract.
- **PROC-26**: Host code can preview upcoming invoices and proration semantics through the bounded multi-provider facade.
- **PROC-27**: Hosts can use broader lifecycle mutation parity such as pause, resume, and quantity changes beyond the current gateway-subscription-core boundary.

## Out of Scope

| Feature | Reason |
|---------|--------|
| `FIN-03` finance exports | Still outside Accrue's bounded billing-library scope. |
| Hyperwallet / marketplace reopening | Explicit strategic non-goal unless PROC-08 boundaries are reopened in a future milestone. |
| Advanced scheduling and invoice-preview parity | Still intentionally out of slice for the official dual-provider core. |
| Additional processor classes or breadth expansion | This milestone closes the current Stripe+Braintree contract before any new provider-facing expansion. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROC-21 | Phase 112 | Complete 2026-05-07 |
| PROC-22 | Phase 113 (backfilled by Phase 115) | Complete 2026-05-07 (`113-VERIFICATION.md`) |
| PROC-23 | Phase 113 (backfilled by Phase 115) | Complete 2026-05-07 (`113-VERIFICATION.md`) |
| PROC-24 | Phase 114 (verification backfilled by Phase 116) | Complete 2026-05-07 (`114-VERIFICATION.md`) |

**Coverage:**
- v1 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-07 after Phase 116 restored `114-VERIFICATION.md`; all v1.36 requirements now have verification artifacts*
