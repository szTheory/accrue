# Requirements: Accrue — Milestone v1.28

**Defined:** 2026-04-24  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.28 — Next linked publish continuity (spine B)

**Goal:** When **`accrue` / `accrue_admin`** ship the **next linked Hex** version bump, keep merge-blocking **package docs**, **adoption proof matrix**, and **docs-contracts-shift-left** (including **production-readiness discoverability**) honest, align **`.planning/`** registry mirrors, then run the **dated friction-inventory maintainer pass** required by inventory **revisit triggers** after publish (**INV-06**). **No** **PROC-08** / **FIN-03**. **Not** a **1.0.0** declaration milestone unless explicitly reprioritized (spine **A**).

### Proof and package contracts (PPX)

- [ ] **PPX-05**: **`bash scripts/ci/verify_package_docs.sh`** and **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** pass on **`main`** after the **`accrue` / `accrue_admin`** **`mix.exs` `@version`** bump that ships (or immediately accompanies) the linked registry release — install literals in enforced docs match workspace **`@version`**.

- [ ] **PPX-06**: **`bash scripts/ci/verify_adoption_proof_matrix.sh`** passes; **`examples/accrue_host/docs/adoption-proof-matrix.md`** stays needle-aligned with the script (same-PR co-update discipline per **`scripts/ci/README.md`**).

- [ ] **PPX-07**: Merge-blocking **`docs-contracts-shift-left`** set stays green, including **`scripts/ci/verify_production_readiness_discoverability.sh`**, after any doc or version touch in this milestone.

### Planning hygiene (PPX)

- [ ] **PPX-08**: **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** “public Hex” / last-published callouts match **actual** registry versions for the shipped release; any friction-inventory row reopened by the **next publish** trigger is **closed** or **updated** with a verification pointer to Phase **86** / **87** evidence (same discipline as **v1.23** **`v1.17-P1-002`**).

### Friction inventory (INV)

- [ ] **INV-06**: Post–**PPX** doc/version touch: maintainer pass **(b)** on **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with dated subsection + **`087-VERIFICATION.md`** verifier transcripts (same named verifier bundle family as **INV-03** / **INV-04** / **INV-05** per inventory **revisit triggers**).

## Future requirements (deferred)

- **1.0.0 closing narrative** — spine **A**; open a dedicated milestone when semver + stability promises are ready.
- New **FRG-01** rows from **sourced** integrator stalls — optional follow-up only when evidence clears the **FRG-01** bar.
- **PROC-08** / **FIN-03** — explicit future milestone only (see **`.planning/PROJECT.md`** non-goals).

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** | Second processor; unchanged non-goal. |
| **FIN-03** | App-owned finance exports; unchanged non-goal. |
| New billing / admin product features | v1.28 is **publish-adjacent contract + inventory** only. |
| Broad doc sweeps without a friction row or publish forcing function | North star **S1** / **S5**. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PPX-05 | Phase 86 | Pending |
| PPX-06 | Phase 86 | Pending |
| PPX-07 | Phase 86 | Pending |
| PPX-08 | Phase 86 | Pending |
| INV-06 | Phase 87 | Pending |

**Coverage:** v1.28 requirements **5** total · Mapped **5** · Unmapped **0** ✓

---
*Requirements defined: 2026-04-24 — **`/gsd-new-milestone`** v1.28 (spine **B**); domain research **skipped**.*
