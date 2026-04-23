# Requirements: Accrue (milestone v1.18)

**Defined:** 2026-04-23  
**Milestone:** v1.18 — Onboarding confidence  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through the first **public** major line.

**Theme:** **Proof-first onboarding confidence** after **v1.17** — close deferred **Phase 62** human UAT scenarios (archived baseline) and align evaluator-facing adoption proof. **No** **PROC-08** / **FIN-03**.

**Scenario baseline:** [`.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-UAT.md`](milestones/v1.17-phases/62-friction-triage-north-star/62-UAT.md) (tests **1–5**).

## v1.18 Requirements

### Human UAT + confidence (UAT)

- [ ] **UAT-01** — **Friction inventory evidence + FRG-03 id hygiene** — **Exit:** Maintainer verifies the expectations in **`62-UAT`** test **1** against live **`.planning/research/v1.17-FRICTION-INVENTORY.md`** *or* a merge-blocking / CI contract documents the same invariants (cited path in **`66-VERIFICATION.md`**). **Pass** = evidence rows + citations + no placeholder / id-format traps per scenario text.
- [ ] **UAT-02** — **STATE.md friction inventory pointer** — **Exit:** **`.planning/STATE.md`** names or links **`.planning/research/v1.17-FRICTION-INVENTORY.md`** (pointer-only layout acceptable). **Pass** = pointer survives **v1.18** planning edits; **Automation** = ExUnit / script in **`test/`** or **`scripts/ci/`** if one is added and cited.
- [ ] **UAT-03** — **North star S1–S5 + cross-doc links** — **Exit:** **`.planning/research/v1.17-north-star.md`** still exposes **S1–S5** stop rules (table or equivalent); **`.planning/PROJECT.md`** and **`.planning/STATE.md`** still reference **`v1.17-north-star.md`** by name or path. **Pass** = manual confirmation row in **`66-VERIFICATION.md`**; **Automation** = optional doc contract test if added with citation.
- [ ] **UAT-04** — **v1.17 requirements archive traceability** — **Exit:** **`.planning/milestones/v1.17-REQUIREMENTS.md`** remains the historical **v1.17** record (no accidental deletion); **v1.18** narrative in **PROJECT** / **STATE** does not contradict shipped **FRG/INT/BIL/ADM** completion. **Pass** = **`66-VERIFICATION.md`** row + link to archive.
- [ ] **UAT-05** — **FRG-03 P0 disposition + ROADMAP / inventory consistency** — **Exit:** **`.planning/research/v1.17-FRICTION-INVENTORY.md`** **P0** rows + **`.planning/ROADMAP.md`** collapsed **v1.17** section remain internally consistent after path updates (**`milestones/v1.17-phases/`** verification links). **Pass** = maintainer sign-off row in **`66-VERIFICATION.md`** listing spot-check commands or links.

### Evaluator proof (PROOF)

- [ ] **PROOF-01** — **Adoption proof matrix ↔ walkthrough ↔ verifier alignment** — **Exit:** **`examples/accrue_host/docs/adoption-proof-matrix.md`**, **`examples/accrue_host/docs/evaluator-walkthrough-script.md`**, and merge-blocking **`scripts/ci/verify_adoption_proof_matrix.sh`** (plus host README pointers if touched) stay aligned — any intentional taxonomy rename ships **script + doc in one change set**; **`66-VERIFICATION.md`** records the proof (commands or CI job ids).

## Future requirements

- **PROC-08** / **FIN-03** — Reopen only in a later milestone with explicit scope boundaries (**`.planning/PROJECT.md`** non-goals until then).

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** / **FIN-03** | Non-goals for **v1.18**; expansion milestone not started. |
| New billing primitives / second processor / finance export product | Same as above. |
| Broad doc-only sweeps without a **UAT-** or **PROOF-** row | Diminishing returns; triage-style work belongs in a future friction milestone with new **FRG-01** evidence. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| UAT-01 | 66 | Pending |
| UAT-02 | 66 | Pending |
| UAT-03 | 66 | Pending |
| UAT-04 | 66 | Pending |
| UAT-05 | 66 | Pending |
| PROOF-01 | 66 | Pending |

**Coverage:** v1.18 requirements **6** total; mapped **6**; unmapped **0**.
