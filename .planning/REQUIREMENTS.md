# Requirements: Accrue (milestone v1.16)

**Defined:** 2026-04-23  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through the first **public** major line.

## v1.16 Requirements

**Theme:** **Integrator + proof continuity** — refresh the **v1.13** golden path / **VERIFY-01** / adoption-proof / package-doc story after **v1.15** trust SemVer work, without new billing surface.

### Integrator continuity (INT)

- [x] **INT-06**: **Golden path coherence** — **`accrue/guides/first_hour.md`**, **`examples/accrue_host/README.md`**, and **`accrue/guides/quickstart.md`** (plus explicitly linked tutorial sections) contain **no contradictory** version pins, command order, or capsule (**H/M/R**) instructions relative to **v1.15** trust SemVer messaging and current **CI** merge-blocking contracts; **`verify_verify01_readme_contract.sh`** and **`verify_adoption_proof_matrix.sh`** (or successors) stay **green** on `main`.
- [x] **INT-07**: **Adoption proof + evaluator honesty** — **`examples/accrue_host/docs/adoption-proof-matrix.md`** and **`evaluator-walkthrough-script.md`** reflect current **golden path**, **VERIFY-01** lanes, and **v1.15** doc signals where those docs are the SSOT; **`scripts/ci/README.md`** (or successor contributor map) names **owning verifiers** for any new/changed merge-blocking checks touched by this milestone.
- [x] **INT-08**: **Root VERIFY discoverability** — repository **`README.md`** preserves **v1.7** intent: **VERIFY-01** / **`host-integration`** discoverable within the **documented hop budget** from repo root after **v1.15** additions; if the contract tightens or moves, **verifiers** and **README** are updated **together** (no silent drift).
- [x] **INT-09**: **Hex / `main` doc SSOT** — **`verify_package_docs`**, **`first_hour`**, **`accrue/README.md`**, and **`accrue_admin/README.md`** **Hex vs `main`** install guidance stays aligned with **`accrue/mix.exs`** / **`accrue_admin/mix.exs`** **`@version`** on the branch under test; **`.planning/PROJECT.md`** / **`.planning/MILESTONES.md`** “current Hex” callouts match **v1.11 HYG**-style mirror rules when **`@version`** advances during the milestone.

## Future requirements

*(Deferred by theme — reopen in a later milestone if needed.)*

- **Release train** as primary theme (next Hex publish, Release Please narrative only) — not **v1.16** unless scope expands.

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** / **FIN-03** | Explicit non-goals until a milestone reopens them. |
| New **`Accrue.Billing`** APIs, schema migrations, admin feature parity | **v1.16** is **docs + verifiers + proof artifacts** only. |
| New third-party UI kits | Unchanged UI contract. |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| INT-06 | Phase 59 | Complete |
| INT-07 | Phase 60 | Complete |
| INT-08 | Phase 61 | Complete |
| INT-09 | Phase 61 | Complete |

**Coverage:** v1.16 requirements **4** total; mapped **4**; unmapped **0**.

---
*Requirements defined: 2026-04-23 — milestone v1.16 (integrator + proof continuity).*
