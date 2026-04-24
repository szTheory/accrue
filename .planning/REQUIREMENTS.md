# Requirements: Accrue (milestone v1.19)

**Defined:** 2026-04-23  
**Milestone:** v1.19 — Release continuity + proof resilience  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through the first public major line.

**Theme:** Harden merge-blocking **adoption proof matrix** ↔ **`verify_adoption_proof_matrix.sh`** contracts (**addresses `v1.17-P1-001`**), then ship **`accrue` / `accrue_admin` 0.3.1** to Hex via the existing linked-release path, then align **First Hour**, **`verify_package_docs`**, and **`.planning/`** mirrors with published reality. **No** **PROC-08** / **FIN-03**.

---

## Proof contracts (PRF)

- [x] **PRF-01**: Merge-blocking checks cover **taxonomy / archetype / row-id** alignment between **`examples/accrue_host/docs/adoption-proof-matrix.md`** and **`scripts/ci/verify_adoption_proof_matrix.sh`** (and any related **ExUnit** contract tests) so an intentional matrix edit **must** update verifier needles in the **same change set** (CI fails otherwise).
- [x] **PRF-02**: **`scripts/ci/README.md`** documents contributor triage for **`verify_adoption_proof_matrix.sh`** — including the **matrix + script + tests co-update** rule and pointers to the matrix SSOT.

## Release train (REL)

- [ ] **REL-01**: Maintainer can follow **`RELEASING.md`** and **`.github/workflows/release-please.yml`** + **`release-please-config.json`** so **`accrue` publishes before `accrue_admin`** for the **0.3.1** (or current ship) bump.
- [ ] **REL-02**: Shipped **`accrue/mix.exs`** and **`accrue_admin/mix.exs`** **`@version`**, both **`CHANGELOG.md`** files, and **Hex-published** SemVer match for the release (no “Unreleased” gap at ship boundary for that version).
- [ ] **REL-03**: Git tags **`accrue-v{version}`** / **`accrue_admin-v{version}`** exist for the shipped release; Hex package pages show **0.3.1** (or shipped version).

## Documentation and integrator pins (DOC)

- [ ] **DOC-01**: **`accrue/guides/first_hour.md`** and package README **primary install** lines enforced by **`verify_package_docs`** use **`~>`** pins consistent with **newly published** **0.3.1** (or shipped version).
- [ ] **DOC-02**: **`scripts/ci/verify_package_docs.sh`** and **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** pass on **`main`** after the release merge (**source_ref**, extras lists, link invariants).

## Planning hygiene (HYG)

- [ ] **HYG-01**: **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** “public Hex” / last-published callouts reflect **actual** post-release **`accrue`** / **`accrue_admin`** versions (**0.3.1** or shipped).

---

## Future requirements

- **v1.17-P2-001** (First Hour capsule cross-link discipline) — optional timebox only if **PRF** + **REL** slip risk is low; otherwise a later friction milestone.
- **PROC-08** / **FIN-03** — Explicit future milestone only (see **`.planning/PROJECT.md`** non-goals).

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** | Second processor; not part of this release slice. |
| **FIN-03** | App-owned finance exports; not part of this slice. |
| New billing primitives | **v1.19** is proof + release + continuity only. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRF-01 | 67 | Complete |
| PRF-02 | 67 | Complete |
| REL-01 | 68 | Pending |
| REL-02 | 68 | Pending |
| REL-03 | 68 | Pending |
| DOC-01 | 69 | Pending |
| DOC-02 | 69 | Pending |
| HYG-01 | 69 | Pending |

**Coverage:** v1.19 requirements **8** total · Mapped **8** · Unmapped **0**
