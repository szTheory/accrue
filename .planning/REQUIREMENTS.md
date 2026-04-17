# Requirements: Accrue v1.4 Ecosystem stability + demo visuals

**Defined:** 2026-04-17  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through at least the first major version.

## v1.4 requirements

This milestone tightens the **Stripe SDK dependency surface** (`lattice_stripe`) and makes the **Fake-backed host + admin story** easy to **see** (screenshots and CI artifacts) without new product scope.

### Ecosystem stability

- [x] **STAB-01**: Monorepo lockfiles resolve the **latest published** `lattice_stripe` version compatible with `~> 1.1` in `accrue`, `accrue_admin`, and `examples/accrue_host`; `mix test` / host verify gates stay green. *(As of 2026-04-17, Hex latest is **1.1.0**; `mix deps.update lattice_stripe` was run in all three packages.)*

### Demo visuals (discoverability)

- [x] **UX-DEMO-01**: Documented, repeatable path for maintainers and evaluators to **view** full-page screenshots of the canonical Fake-backed walkthrough (`@phase15-trust`), including local output paths and the **`accrue-host-phase15-screenshots`** CI artifact; optional `npm run e2e:visuals` shortcut in `examples/accrue_host`.

## Future requirements

Deferred to later milestones (not v1.4 scope):

| ID | Theme |
|----|--------|
| **FIN-03** | Host-owned finance exports (audiences, retention, delivery). |
| **FIN-04** | Accounting-engine semantics only if deliberately scoped. |
| **PROC-08** | Official second processor adapter (explicitly **out of scope** for v1.4). |
| **ORG-04** | Broader non-Sigra tenancy recipes. |

## Out of scope (v1.4)

- Second processor adapter (**PROC-08**).
- Committed binary screenshot galleries in git (optional later; v1.4 uses generated + CI artifacts only unless a follow-up explicitly adds curated assets).

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STAB-01 | Phase 23 | Done |
| UX-DEMO-01 | Phase 23 | Done |

**Coverage:** v1.4 requirements: 2 total; mapped: 2; unmapped: 0.

---
*Last updated: 2026-04-17 — v1.4 milestone executed (ecosystem stability + demo visuals).*
