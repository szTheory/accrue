---
phase: 85
slug: friction-inventory-post-closure
requirements: [INV-05]
status: complete
---

# Phase 85 — Friction inventory post-closure — Verification

## INV-05 path

**path (b)** — post–**CLS** doc landing maintainer review found no ranked **P1**/**P2** friction warranting new sourced table rows on the reviewed tree per **FRG-02** stop rules **S1** / **S5**.

**Reviewed commit SHA:** `a47a2ba9db27d6ce7a3c2e88a2577b195503be6a`

## Normative attestation

**INV-05** normative maintainer conclusion is recorded only in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** under **`### v1.27 INV-05 maintainer pass (2026-04-24)`**; **`v1.17-FRICTION-INVENTORY.md`** is the single normative voice for what was certified — this file is methodology + verifier evidence.

## Verifier bundle

- `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- `bash scripts/ci/verify_production_readiness_discoverability.sh`
- **`docs-contracts-shift-left`** / **`host-integration`** — merge-blocking on **`main`** (see **`.planning/milestones/v1.26-phases/083-friction-inventory-post-touch/083-VERIFICATION.md`** for job wiring reference).

## Path evidence

85-01: certification subsection **`### v1.27 INV-05 maintainer pass (2026-04-24)`** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`**.

## Command transcripts

Recorded **2026-04-24** from repository root; each command exited **0** on the tree at reviewed SHA **`a47a2ba9db27d6ce7a3c2e88a2577b195503be6a`**.

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

$ bash scripts/ci/verify_production_readiness_discoverability.sh
verify_production_readiness_discoverability: OK
```

## INV-05 closure checklist

- [x] **(b)** — **Dated maintainer certification** that no new sourced **P1**/**P2** rows were warranted: **`.planning/research/v1.17-FRICTION-INVENTORY.md`** → **`### v1.27 INV-05 maintainer pass (2026-04-24)`**.
- [x] **Named verifiers + SHA** — **`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, **VERIFY-01** / **`verify_verify01_readme_contract.sh`**, **`verify_v1_17_friction_research_contract.sh`**, **`verify_production_readiness_discoverability.sh`**, **`docs-contracts-shift-left`**, and **`host-integration`** — documented above with **Reviewed commit SHA** **`a47a2ba9db27d6ce7a3c2e88a2577b195503be6a`**.
- [x] **`verify_v1_17_friction_research_contract.sh`** green on final tree (path **(b)** — row counts unchanged).
