# Requirements: Accrue v1.11

**Defined:** 2026-04-22  
**Milestone:** v1.11 — Public Hex release + post-release continuity  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through at least the first major version.

Milestone theme: **publish** `accrue` + `accrue_admin` to Hex for metering and accumulated work since **0.1.2**, using **Release Please** + **linked versions**, then **align docs and planning** with the published SemVer. **PROC-08** (second processor) and **FIN-03** (app-owned finance exports) remain **out of scope**.

---

## Release automation & publish

- [ ] **REL-01**: Maintainer can follow **`RELEASING.md`** and the **combined** Release Please path in **`.github/workflows/release-please.yml`** so **`accrue` publishes before `accrue_admin`**, consistent with **`release-please-config.json`** linked-versions behavior.
- [ ] **REL-02**: Shipped **`accrue/mix.exs`** and **`accrue_admin/mix.exs`** **`@version`** match the **Hex-published** SemVer for that release, and both **`accrue/CHANGELOG.md`** and **`accrue_admin/CHANGELOG.md`** include a **released** section for that version (including metering and post-**0.1.2** user-visible changes — no “Unreleased forever” at ship boundary).
- [ ] **REL-03**: **`RELEASING.md`** accurately describes **routine pre-1.0** linked releases (e.g. **0.3.x**) alongside any historic **1.0.0 bootstrap** narrative, without implying only **1.0.0** is valid for normal shipping.
- [ ] **REL-04**: **Git tags** **`accrue-v{version}`** / **`accrue_admin-v{version}`** exist for the shipped release (per Release Please / maintainer verification), and Hex package pages show the new versions.

## Documentation & evaluators

- [ ] **DOC-01**: **`accrue/guides/first_hour.md`** (and any other **primary install** doc called out in **`verify_package_docs`**) uses **`~>`** install lines consistent with the **newly published** package versions.
- [ ] **DOC-02**: **`scripts/ci/verify_package_docs.sh`** and **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** pass on **`main`** after the release merge (versions, **source_ref** tag shapes, and link invariants).

## Planning continuity

- [ ] **HYG-01**: **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** “last published / Hex” lines reflect the **actual** post-release **`accrue`** / **`accrue_admin`** versions.

---

## Later milestones (not v1.11)

- Next **implementation** theme after Hex is live — open with **`/gsd-discuss-phase 48`** or **`/gsd-new-milestone`** when ready (not a v1.11 REQ-ID; avoids pre-choosing feature scope here).
- **PROC-08**, **FIN-03**, Stripe Dashboard meter builder UX — unchanged non-goals unless a future milestone reprioritizes them in writing.

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** | Second processor; not part of release hygiene. |
| **FIN-03** | App-owned finance exports; not part of release hygiene. |
| New billing primitives | v1.11 is release + continuity only. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 46 | Pending |
| REL-02 | Phase 46 | Pending |
| REL-04 | Phase 46 | Pending |
| REL-03 | Phase 47 | Pending |
| DOC-01 | Phase 47 | Pending |
| DOC-02 | Phase 47 | Pending |
| HYG-01 | Phase 47 | Pending |

**Coverage:** v1.11 requirements: **7** total · Mapped: **7** · Unmapped: **0**

---
*Requirements defined: 2026-04-22 — `/gsd-new-milestone` after v1.10 archival.*
