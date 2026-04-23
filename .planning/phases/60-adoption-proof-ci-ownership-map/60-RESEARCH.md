# Phase 60 — Technical research

**Question:** What do we need to know to plan **INT-07** (adoption proof honesty + CI ownership map) well?

## Findings

### Merge-blocking vs advisory lanes (SSOT)

- **`adoption-proof-matrix.md`** already encodes **Layer B** (local Fake) vs **Layer C** (`host-integration`), **ORG-09** primary vs recipe rows, and **Stripe advisory**. INT-07 does not widen **PROC-08**; it refreshes prose so evaluators cannot infer stricter proof than CI provides.
- **`verify_adoption_proof_matrix.sh`** is a **substring contract** on the matrix file. Any new required literal in the matrix doc must be mirrored in the script **in the same PR** when the taxonomy intentionally changes (existing ORG-09 discipline).

### v1.15 trust signals in proof instruments

- **Hex SemVer** vs **internal milestone labels** (`v1.15`, …) and **Sigra as demo wiring** are explained in **First Hour**, **host README**, and **auth_adapters** — Phase **60** should add **short, stable** bullets or one-liners in matrix + walkthrough only where an evaluator would otherwise miss the boundary; deep narrative stays in explanation SSOTs (**D-07 / D-08** in CONTEXT).

### Contributor map (`scripts/ci/README.md`)

- Tables use **REQ-ID | script/artifact | ExUnit | phase VERIFICATION.md** — new **INT / v1.16** rows should **match that column schema** (**D-01**). Add to **ADOPT/ORG** only when semantically correct (**D-02**).
- **INT-07 literal scope:** rows for **new/changed** merge-blocking checks touched by **v1.16 (phases 59–61)** only, plus a **scope note** that normative CI graph remains **`.github/workflows/ci.yml`** + branch protection (**D-09–D-11**).

### Verification commands (repo reality)

- **Quick:** `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh`
- **Doc regression:** `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` (from monorepo root).

### Risks

- **Drift:** Walkthrough prose that implies extra merge-blocking steps not in `host-integration` → mitigated by explicit pointers to matrix § and CI job list.
- **Taxonomy rot:** Stuffing non-adoption checks into **ADOPT** → mitigated by dedicated **INT** section.

## Validation Architecture

**Nyquist / execution sampling**

| Dimension | Strategy |
|-----------|----------|
| **Automated doc contracts** | After every task that edits markdown under `examples/accrue_host/docs/` or `scripts/ci/README.md`, run **`verify_adoption_proof_matrix.sh`** when the matrix changes; always run the **bash trio** before marking a plan done. |
| **ExUnit doc corpus** | After wave completion, `mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` (adjust if repo standard is `mix test test/accrue/docs/` — executor follows repo `59-VERIFICATION.md` precedent). |
| **Manual** | Optional: spot-read matrix vs `.github/workflows/ci.yml` `host-integration` steps for **Layer C** wording — not blocking if scripts green. |

**Dimension 8 (plans):** Every plan task lists **grep-verifiable** acceptance strings and ties verification to the scripts above.

---

## RESEARCH COMPLETE
