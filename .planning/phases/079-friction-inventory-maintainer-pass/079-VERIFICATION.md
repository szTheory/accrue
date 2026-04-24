---
phase: 79-friction-inventory-maintainer-pass
status: complete
---

# Phase 79 — Friction inventory maintainer pass — Verification

## INV-03 path

**path (b) — dated no-new-rows certification** — post–**v1.24** maintainer review found no ranked **P1**/**P2** friction warranting new sourced table rows on **`main`** per **079-CONTEXT.md** D-01 / **FRG-02** stop rules.

Reviewed merge SHA: `149736d0b1523f7ac8982da84cd14f49a5deebbd`

## Normative attestation

INV-03 normative maintainer conclusion is recorded only in `.planning/research/v1.17-FRICTION-INVENTORY.md` under **`### v1.25 INV-03 maintainer pass (2026-04-24)`**; this file is methodology + verifier evidence (no second certification voice).

## Verifier bundle

- `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- **79-01-03 skipped (path b)** — inventory row counts unchanged; no edits to **`scripts/ci/verify_v1_17_friction_research_contract.sh`** numeric asserts.
- **host-integration** — merge-blocking GitHub Actions job **`host-integration`** in **`.github/workflows/ci.yml`** (see **## VERIFY-01 / host-integration**).

## Path evidence

79-01-02: certification subsection ### v1.25 INV-03 maintainer pass (2026-04-24) in `.planning/research/v1.17-FRICTION-INVENTORY.md`.

## Command transcripts

Recorded **2026-04-24** from repository root; each command exited **0**. Final re-run in **79-01-06** re-confirms **`verify_v1_17_friction_research_contract.sh`** on the closing tree.

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

## VERIFY-01 / host-integration

**VERIFY-01** (README contract) runs in GitHub Actions job **`docs-contracts-shift-left`** — step **VERIFY-01 README contract** in **`.github/workflows/ci.yml`** on the reviewed tree ([`ci.yml` @ reviewed SHA](https://github.com/szTheory/accrue/blob/149736d0b1523f7ac8982da84cd14f49a5deebbd/.github/workflows/ci.yml)).

**host-integration** is the merge-blocking job **`host-integration`** in the same workflow file; it runs **`bash scripts/ci/accrue_host_uat.sh`** after **`docs-contracts-shift-left`** and **`admin-drift-docs`** succeed.

**How to confirm on GitHub Actions:** open **https://github.com/szTheory/accrue/actions** and find a **`CI`** workflow run for commit **`149736d0b1523f7ac8982da84cd14f49a5deebbd`** (or the merge commit that introduced it to **`main`**). Verify **`docs-contracts-shift-left`** and **`host-integration`** both **succeeded**.

**Local alignment:** The scripts in **## Command transcripts** were executed on that **`git`** tree with exit code **0**; they include the same **`verify_verify01_readme_contract.sh`** step used under **VERIFY-01** in **`docs-contracts-shift-left`**.

## INV-03 closure checklist

Per **`.planning/REQUIREMENTS.md`** **INV-03**:

- [x] **(b)** — **Dated maintainer certification** that no new sourced rows were warranted: **`.planning/research/v1.17-FRICTION-INVENTORY.md`** → **`### v1.25 INV-03 maintainer pass (2026-04-24)`** (normative voice; links here for verifier bundle only).
- [x] **Named verifiers + SHA** — **`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, **VERIFY-01** / **`verify_verify01_readme_contract.sh`**, **`verify_v1_17_friction_research_contract.sh`**, and **GitHub Actions** **`host-integration`** — documented above with **Reviewed merge SHA** **`149736d0b1523f7ac8982da84cd14f49a5deebbd`**.
- [x] **`verify_v1_17_friction_research_contract.sh`** remains green on final tree (no row-count drift for path **(b)**).
