# Requirements: Accrue — Milestone v1.23

**Defined:** 2026-04-24  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.23 — Post-publish contract alignment (Branch A)

**Goal:** After each **linked Hex publish** for **`accrue` / `accrue_admin`**, keep **merge-blocking doc and adoption contracts** green and planning callouts honest so production integrators see one coherent story (pins, First Hour, matrix needles, `.planning/` mirrors). Addresses **`.planning/research/v1.17-FRICTION-INVENTORY.md`** row **`v1.17-P1-002`**. **No** **PROC-08** / **FIN-03**.

### Proof and package contracts (PPX)

- [ ] **PPX-01**: **`bash scripts/ci/verify_package_docs.sh`** and **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** pass on **`main`** after the **`accrue` / `accrue_admin`** **`mix.exs` `@version`** bump that ships (or immediately accompanies) the linked registry release — install literals in enforced docs match workspace **`@version`**.
- [ ] **PPX-02**: **`bash scripts/ci/verify_adoption_proof_matrix.sh`** passes; **`examples/accrue_host/docs/adoption-proof-matrix.md`** stays needle-aligned with the script (same-PR co-update discipline per **`scripts/ci/README.md`**).
- [ ] **PPX-03**: Merge-blocking **`docs-contracts-shift-left`** set stays green, including **`scripts/ci/verify_production_readiness_discoverability.sh`**, after any doc or version touch in this milestone.

### Planning hygiene (PPX)

- [ ] **PPX-04**: **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** “public Hex” / last-published callouts match **actual** registry versions for the shipped release; **`v1.17-P1-002`** in the friction inventory is moved to **closed** with a verification pointer to Phase **75** evidence.

## Future requirements (deferred)

- New **FRG-01** rows from **sourced** integrator stalls — optional **Branch B** follow-up milestones only when evidence exists.
- **PROC-08** / **FIN-03** — explicit future milestone only (see **`.planning/PROJECT.md`** non-goals).

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** | Second processor; unchanged non-goal. |
| **FIN-03** | App-owned finance exports; unchanged non-goal. |
| New billing / admin product features | v1.23 is **publish-adjacent contract alignment** only. |
| Broad doc sweeps without a friction row | North star **S1** / **S5**. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PPX-01 | Phase 75 | Pending |
| PPX-02 | Phase 75 | Pending |
| PPX-03 | Phase 75 | Pending |
| PPX-04 | Phase 75 | Pending |

**Coverage:** v1.23 requirements **4** total · Mapped **4** · Unmapped **0** ✓
