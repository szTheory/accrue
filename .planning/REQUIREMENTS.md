# Requirements: Accrue (milestone v1.15)

**Defined:** 2026-04-23  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through the first **public** major line.

## v1.15 Requirements

Release semantics and evaluator trust: align **Hex SemVer**, **upgrade contract**, and **internal planning milestone labels** so teams know what “rely on it” means before more feature milestones.

### Trust and versioning (TRT)

- [x] **TRT-01**: `accrue/guides/upgrade.md` states the **current** consumer baseline using **`accrue/mix.exs` / `accrue_admin/mix.exs` `@version`** and [Hex](https://hex.pm/packages/accrue), not a stale fixed version; links maintainer **`RELEASING.md`** for the **`1.0.0` bootstrap** appendix where relevant.
- [x] **TRT-02**: Root **`RELEASING.md`** includes a short, explicit note that **`.planning/` milestone labels (`v1.14`, etc.)** are **internal cadence**, while **ship + install truth** is **`mix.exs` `@version`** and **Hex** SemVer.
- [x] **TRT-03**: Repository root **`README.md`** clarifies **Hex vs `main` vs planning milestones** in one place so skimmers do not confuse **internal `v1.x` planning** with **public package majors**.
- [x] **TRT-04**: **`examples/accrue_host/README.md`** states **above the fold** that **Sigra** is a **checked-in demo dependency** for clone/CI convenience; **`Accrue.Auth`** remains the supported integration surface for **non-Sigra** hosts, with pointers to **First Hour** / **organization billing** guides. **`accrue/README.md`** **Stability** ties **`0.x`** public SemVer to the same **deprecation** contract and points maintainers at **`RELEASING.md`** for the **`1.0.0`** bootstrap appendix.

## Future requirements

*(None added in v1.15 — external integrator bake-offs and product expansion stay out of this milestone.)*

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** (second processor) | Strategic expansion; not a trust-doc gap. |
| **FIN-03** (finance exports) | Strategic expansion; explicit non-goal until reprioritized. |
| New billing APIs or admin parity passes | Diminishing returns per adoption sanity; defer to a later milestone with a new forcing function. |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| TRT-01 | Phase 57 | Complete |
| TRT-02 | Phase 57 | Complete |
| TRT-03 | Phase 57 | Complete |
| TRT-04 | Phase 58 | Complete |

**Coverage:** v1.15 requirements **4** total; mapped **4**; unmapped **0**.

---
*Requirements defined: 2026-04-23 — milestone v1.15 (forcing function **B**: release / trust semantics).*
