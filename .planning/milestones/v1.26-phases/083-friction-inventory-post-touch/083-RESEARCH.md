# Phase 83 — Technical research (INV-04 maintainer pass)

**Question answered:** What must the planner know to plan **INV-04** after **INT-13** (Phase 82)?

## Delta vs Phase 79 (INV-03)

| Topic | INV-03 (79) | INV-04 (83) |
|-------|-------------|-------------|
| Normative subsection | `### v1.25 INV-03 maintainer pass (…)` | `### v1.26 INV-04 maintainer pass (…)` **immediately after** the INV-03 block |
| Verifier bundle | Named `verify_package_docs`, `verify_adoption_proof_matrix.sh`, VERIFY-01 / `verify_verify01_readme_contract.sh`, `host-integration` | **Same** plus **`docs-contracts-shift-left`** named **explicitly** in certification prose (REQUIREMENTS.md; 083-CONTEXT D-03) |
| Evidence file | `079-VERIFICATION.md` under `.planning/phases/` (79) | **`083-VERIFICATION.md`** under **`.planning/milestones/v1.26-phases/083-friction-inventory-post-touch/`** (083-CONTEXT D-06) |
| Precondition | Post–v1.24 | Post–**INT-13** / Phase **82** landed on **`main`** |
| Revisit triggers | Hex publish, host-integration/docs failures, matrix rename | Same family **plus** at least one trigger tied to **INT-13-class** surfaces (billing portal / First Hour / adoption matrix / host README drift without sourced row update) |

## Path (a) vs (b)

- **Default (b):** Dated certification that no new sourced **P1**/**P2** rows clear the FRG-01 bar; single reviewed **`main`** merge SHA; no row-count change → **no** edit to `verify_v1_17_friction_research_contract.sh` counts; document **`83-01-03 skipped (path b)`** in verifier bundle section.
- **(a):** Append one or more new table rows with stable **`v1.17-P1-NNN`** / **`v1.17-P2-NNN`** only; **never renumber**; same PR must update **`scripts/ci/verify_v1_17_friction_research_contract.sh`** `row_count`, `p1_count`, `p2_count` (and `p0_count` if ever touched) to match `grep -cE '^\| v1\.17-P[012]-[0-9]{3} \|'`.

## Script contracts (executor must not break)

- `verify_v1_17_friction_research_contract.sh` — exact counts (currently **5** rows, **2**/**2**/**1** P0/P1/P2); FRG-03 anchors; no `*(example)*`.
- `verify_package_docs.sh`, `verify_adoption_proof_matrix.sh`, `verify_verify01_readme_contract.sh` — standard INV bundle.
- **CI:** Job names **`docs-contracts-shift-left`** and **`host-integration`** in `.github/workflows/ci.yml` are acceptable evidence anchors (link or cite path @ SHA).

## Validation Architecture

Dimension 8 (Nyquist): This phase is **documentation + bash verifier evidence**. Automated feedback is **bash scripts from repo root** (no ExUnit required for attestation). After each material edit to inventory or `083-VERIFICATION.md`, run **`bash scripts/ci/verify_v1_17_friction_research_contract.sh`** at minimum. Before closure, run the full bundle listed in the plan verification section.

---

## RESEARCH COMPLETE

Evidence sources: `083-CONTEXT.md`, `REQUIREMENTS.md` INV-04, `v1.17-FRICTION-INVENTORY.md` structure, `079-01-PLAN.md` / `079-VERIFICATION.md`, `verify_v1_17_friction_research_contract.sh`.
