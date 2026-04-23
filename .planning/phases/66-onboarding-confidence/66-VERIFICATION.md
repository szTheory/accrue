---
status: passed
phase: 66-onboarding-confidence
verified: "2026-04-23"
---

# Phase 66 — Deferred UAT + evaluator proof (verification ledger)

Normative exit criteria for **UAT-01..UAT-05** and **PROOF-01** are defined in **`.planning/REQUIREMENTS.md`** (milestone **v1.18 — Onboarding confidence**). This file records merge-blocking commands, CI job mapping, evidence pointers, and closure.

| Row ID | Acceptance one-liner | Merge-blocking proof | Automation | Evidence pointer | Closure |
|--------|------------------------|----------------------|------------|------------------|---------|
| UAT-01 | Friction inventory evidence and FRG-03 id hygiene: four evidence-backed rows, real citations, no `*(example)*`, no ambiguous bare `v1.17-P0-` substrings — as in **REQUIREMENTS** § Human UAT. | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | CI (`.github/workflows/ci.yml`; workflow name: **CI**; job: **docs-contracts-shift-left**; steps include **verify_package_docs.sh**; **v1.17 friction + north-star SSOT contract**; VERIFY-01 README contract; Adoption proof matrix contract) | `.planning/research/v1.17-FRICTION-INVENTORY.md`; historical scenario text `.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-UAT.md` (superseded banner) | closed |
| UAT-02 | **STATE.md** names or links **`.planning/research/v1.17-FRICTION-INVENTORY.md`** (pointer-only layout acceptable). | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | CI (workflow: **CI**; job: **docs-contracts-shift-left**; step: **v1.17 friction + north-star SSOT contract**) | `.planning/STATE.md` — `Friction inventory (FRG-01):` line | closed |
| UAT-03 | **v1.17-north-star.md** exposes **S1–S5** stop rules; **PROJECT.md** and **STATE.md** reference **`v1.17-north-star.md`**. | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | CI (workflow: **CI**; job: **docs-contracts-shift-left**; step: **v1.17 friction + north-star SSOT contract**) | `.planning/research/v1.17-north-star.md`; `.planning/PROJECT.md`; `.planning/STATE.md` — north star pointer | closed |
| UAT-04 | **`.planning/milestones/v1.17-REQUIREMENTS.md`** remains the historical v1.17 record; **PROJECT** / **STATE** narrative does not contradict shipped **FRG/INT/BIL/ADM** completion. | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` (includes on-disk archive gate); `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | CI (workflow: **CI**; job: **docs-contracts-shift-left**; step: **v1.17 friction + north-star SSOT contract**) | `.planning/milestones/v1.17-REQUIREMENTS.md`; `.planning/PROJECT.md`; `.planning/STATE.md`; `62-UAT.md` supersession banner verified **2026-04-23** | closed |
| UAT-05 | **P0** rows in friction inventory and **ROADMAP** collapsed v1.17 section stay consistent (**`milestones/v1.17-phases/`** verification links). | `bash scripts/ci/verify_v1_17_friction_research_contract.sh`; `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs`; `rg -n 'v1\.17-FRICTION-INVENTORY\.md#backlog' .planning/ROADMAP.md` | CI (workflow: **CI**; job: **docs-contracts-shift-left**; step: **v1.17 friction + north-star SSOT contract**) | `.planning/research/v1.17-FRICTION-INVENTORY.md`; `.planning/ROADMAP.md` FRG-03 anchors | closed |
| PROOF-01 | Adoption proof matrix, evaluator walkthrough script, **verify_adoption_proof_matrix.sh**, and host README pointers stay aligned; taxonomy edits ship matrix + script + ExUnit in one change set. | `bash scripts/ci/verify_adoption_proof_matrix.sh`; `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` | CI (workflow: **CI**; job: **docs-contracts-shift-left**; step: **Adoption proof matrix contract**) | `examples/accrue_host/docs/adoption-proof-matrix.md`; `examples/accrue_host/docs/evaluator-walkthrough-script.md`; `examples/accrue_host/README.md`; `scripts/ci/verify_adoption_proof_matrix.sh` | closed |

## Spot-checks (PROOF-01 semantic)

**Date:** 2026-04-23. **Scope:** `adoption-proof-matrix.md`, `evaluator-walkthrough-script.md`, and **Proof and verification** / **Adoption realism & proof matrix** sections of `examples/accrue_host/README.md` read together for relative links and VERIFY hops.

**No contradictions found.**
