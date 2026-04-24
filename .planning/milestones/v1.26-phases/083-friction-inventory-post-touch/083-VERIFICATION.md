---
phase: 83-friction-inventory-post-touch
status: complete
---

# Phase 83 — Friction inventory post-touch — Verification

## INV-04 path

**path (b)** — post–**INT-13** maintainer review found no ranked **P1**/**P2** friction warranting new sourced table rows on the reviewed tree per **083-CONTEXT.md** D-01 / **FRG-02** stop rules.

Reviewed merge SHA: `d1f121c75bb21fb2dd53c9ac9315bd83c26a438e`

## Normative attestation

**INV-04** normative maintainer conclusion is recorded only in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** under **`### v1.26 INV-04 maintainer pass (2026-04-24)`**; **`v1.17-FRICTION-INVENTORY.md`** is the single normative voice for what was certified — this file is methodology + verifier evidence (no second certification paragraph).

## Verifier bundle

- `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- **`docs-contracts-shift-left`** — merge-blocking GitHub Actions job in **`.github/workflows/ci.yml`** that runs the bash contracts above (including **VERIFY-01**).
- **`host-integration`** — merge-blocking job in the same workflow; see **## CI evidence: docs-contracts-shift-left, VERIFY-01, host-integration** for `needs:` wiring vs **`docs-contracts-shift-left`**.
- **83-01-03 skipped (path b)** — row counts unchanged

## Path evidence

83-01-02: certification subsection ### v1.26 INV-04 maintainer pass (2026-04-24) in `.planning/research/v1.17-FRICTION-INVENTORY.md`.

## Command transcripts

Recorded **2026-04-24** from repository root; each command exited **0** on the tree at reviewed SHA **`d1f121c75bb21fb2dd53c9ac9315bd83c26a438e`**.

```text
$ bash scripts/ci/verify_v1_17_friction_research_contract.sh
verify_v1_17_friction_research_contract: OK

$ bash scripts/ci/verify_package_docs.sh
package docs verified for accrue 0.3.1 and accrue_admin 0.3.1
fixed invariants checked: README.md, RELEASING.md, CONTRIBUTING.md, quickstart.md, 15-TRUST-REVIEW.md, STRIPE_TEST_SECRET_KEY, release-gate, host-integration, retain-on-failure, only-on-failure, First run, Seeded history, mix verify, mix verify.full

$ bash scripts/ci/verify_adoption_proof_matrix.sh
verify_adoption_proof_matrix: OK

$ bash scripts/ci/verify_verify01_readme_contract.sh
verify_verify01_readme_contract: OK
```

## CI evidence: docs-contracts-shift-left, VERIFY-01, host-integration

**VERIFY-01** maps to step **`VERIFY-01 README contract`** in GitHub Actions job **`docs-contracts-shift-left`**, which runs **`bash scripts/ci/verify_verify01_readme_contract.sh`** (see [`.github/workflows/ci.yml` @ reviewed SHA](https://github.com/szTheory/accrue/blob/d1f121c75bb21fb2dd53c9ac9315bd83c26a438e/.github/workflows/ci.yml) — job key **`docs-contracts-shift-left`**, lines ~30–55).

**`host-integration`** is merge-blocking on **`pull_request`** to **`main`** per the workflow header comments and the **`host-integration`** job definition in the same file; that job declares **`needs: [admin-drift-docs, docs-contracts-shift-left]`**, so **`docs-contracts-shift-left`** (including **VERIFY-01**) must go green before **`host-integration`** runs. **`docs-contracts-shift-left`** is listed among merge-blocking jobs alongside **`host-integration`** in **`.github/workflows/ci.yml`**.

## INV-04 closure checklist

Per **`.planning/REQUIREMENTS.md`** **INV-04**:

- [x] **(b)** — **Dated maintainer certification** that no new sourced **P1**/**P2** rows were warranted: **`.planning/research/v1.17-FRICTION-INVENTORY.md`** → **`### v1.26 INV-04 maintainer pass (2026-04-24)`** (normative voice; this file holds methodology + transcripts only).
- [x] **Named verifiers + SHA** — **`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, **VERIFY-01** / **`verify_verify01_readme_contract.sh`**, **`verify_v1_17_friction_research_contract.sh`**, **`docs-contracts-shift-left`**, and **`host-integration`** — documented above with **Reviewed merge SHA** **`d1f121c75bb21fb2dd53c9ac9315bd83c26a438e`**.
- [x] **`docs-contracts-shift-left`** explicitly named in the certification bundle (inventory subsection + this file).
- [x] **`verify_v1_17_friction_research_contract.sh`** green on final tree (path **(b)** — row counts unchanged; **83-01-03** skip line recorded).
