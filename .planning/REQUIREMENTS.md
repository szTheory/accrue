# Requirements: Accrue v1.8

**Defined:** 2026-04-21  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through at least the first major version.

## v1.8 Requirements

Milestone theme: **ORG-04** — broader **non-Sigra** tenancy recipes (Pow, phx.gen.auth, custom org models) after **ORG-01..03** established the row-scoped contract.

### Organization billing — recipes (ORG-04)

- [x] **ORG-05**: Developer can follow a single documented spine (guide or clearly linked doc set) that explains how a **non-Sigra** Phoenix host resolves **session → billable** for org-shaped billing while preserving **ORG-03** boundaries. *(Validated in Phase 37: `guides/organization_billing.md` + cross-links.)*
- [x] **ORG-06**: Developer can follow a **phx.gen.auth**-oriented recipe (checklist + Accrue touchpoints: `Accrue.Auth`, `Accrue.Billable`, billing facade) without relying on Sigra-specific modules. *(Validated in Phase 37: phx.gen.auth checklist in the same guide.)*
- [x] **ORG-07**: Developer can follow a **Pow**-oriented recipe with the same contracts, including honest notes on community maintenance and version variance. *(Validated in Phase 38: Pow-oriented checklist in `guides/organization_billing.md` + `auth_adapters.md` link + guide tests.)*
- [x] **ORG-08**: Developer can follow a **custom org model** recipe that lists required host obligations (ownership columns, admin query scoping, webhook replay actor alignment) and explicit anti-patterns that would violate **ORG-03**. *(Validated in Phase 38: ORG-08 section + anti-pattern table in the same guide + tests.)*

### Verification & adoption proof

- [ ] **ORG-09**: Host adoption proof matrix and/or VERIFY-01 README contract documents **at least one** non-Sigra org billing archetype with the same merge-blocking vs advisory posture as existing lanes; owning verifier or script is named (per v1.7 `scripts/ci/README.md` patterns).

## Future Requirements

Unchanged from prior milestones unless explicitly reprioritized:

- **PROC-08** — Official second processor adapter (deferred).
- **FIN-03** — App-owned finance exports (deferred).

## Out of Scope

| Item | Reason |
|------|--------|
| **PROC-08** | Milestone non-goal; Stripe-first posture unchanged. |
| **FIN-03** | Export audiences and retention semantics not in this slice. |
| Accrue-owned org/membership schemas | Host owns tenancy; polymorphic billable only. |
| New third-party UI or auth libraries inside `accrue` / `accrue_admin` | Recipes only; no new hard deps for Pow/phx.gen.auth. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ORG-05 | Phase 37 | Complete |
| ORG-06 | Phase 37 | Complete |
| ORG-07 | Phase 38 | Complete |
| ORG-08 | Phase 38 | Complete |
| ORG-09 | Phase 39 | Pending |

**Coverage:**

- v1.8 requirements: **5** total  
- Mapped to phases: **5**  
- Unmapped: **0**

---
*Requirements defined: 2026-04-21*  
*Last updated: 2026-04-21 — ORG-07/ORG-08 marked complete after Phase 38*
