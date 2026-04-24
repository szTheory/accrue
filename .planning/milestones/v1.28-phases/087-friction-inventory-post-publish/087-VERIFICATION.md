---
phase: 87
slug: friction-inventory-post-publish
requirements: [INV-06]
status: complete
---

# Phase 87 — Friction inventory post-publish — Verification

## INV-06 path

**path (b)** — default per **087-CONTEXT** **D-13**: post–**PPX-05..08** (**Phase 86**) maintainer certification that no new sourced **P1**/**P2** rows were warranted on the reviewed baseline per **FRG-02** **S1** / **S5**; normative prose lives under **`### v1.28 INV-06 maintainer pass (2026-04-24)`** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`**.

## Reviewed merge SHA

Reviewed merge SHA: `aa3df3cad0262b3760a9f9a65a56d177eb6bc047`

**Pin note:** **40-character** lowercase hex for the **`main`**-lineage commit used to **`git show <SHA>:.github/workflows/ci.yml`** and freeze **`docs-contracts-shift-left`** **`run:`** membership. **Phase 87** documentation commits are descendants on the same contract graph; **`ci.yml`** merge-blocking steps for this bundle were **unchanged** between **Phase 86** evidence (**`086-VERIFICATION.md`**, merge SHA **`a533474e6928f7ea3656c5182754d1ebafabd93d`**) and this pin.

## Normative attestation

**INV-06** maintainer conclusion is recorded only under **`### v1.28 INV-06 maintainer pass (2026-04-24)`** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`**; this file is methodology + falsifiable verifier evidence (**085** / **086** family).

## Verifier bundle snapshot @ SHA

Numbered list — **exact** `run:` lines under job **`docs-contracts-shift-left`** in **`.github/workflows/ci.yml`** at **`aa3df3cad0262b3760a9f9a65a56d177eb6bc047`**:

1. `bash scripts/ci/verify_package_docs.sh`
2. `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
3. `bash scripts/ci/verify_verify01_readme_contract.sh`
4. `bash scripts/ci/verify_production_readiness_discoverability.sh`
5. `bash scripts/ci/verify_adoption_proof_matrix.sh`
6. `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`

## host-integration

Merge-blocking job **`host-integration`** (**`.github/workflows/ci.yml`**) **`needs`** **`docs-contracts-shift-left`** (and **`admin-drift-docs`**) and runs **`bash scripts/ci/accrue_host_uat.sh`** plus conditional **`bash scripts/ci/accrue_host_hex_smoke.sh`** — full **CI** job intent per **087-CONTEXT** **D-06**. **087-CONTEXT** **D-04** / **D-05**: this phase does **not** duplicate **Playwright** / host stdout here when **Phase 86** already established **PPX** + shift-left green at **`086-VERIFICATION.md`**; **PR** replay of **`docs-contracts-shift-left`** + **`host-integration`** matches that **merge-blocking** graph at the same **`ci.yml`** revision family.

## release-manifest-ssot

**087-CONTEXT** **D-09**: **Phase 86** already cited merge-blocking **`release-manifest-ssot`** / **`verify_release_manifest_alignment.sh`** in the **PPX** pass — **pointer-only** for **87** (no duplicate **`release-manifest-ssot`** transcript).

## Path evidence

**INV-06** subsection **`### v1.28 INV-06 maintainer pass (2026-04-24)`** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`**.

## Command transcripts

Per **087-CONTEXT** **D-05**, duplicate **stdout** replay of all six **`docs-contracts-shift-left`** scripts is **omitted** here: **`.github/workflows/ci.yml`** **`docs-contracts-shift-left`** membership is **unchanged** vs **`.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md`**, which already records **local** sequential green for the six commands on merge SHA **`a533474e6928f7ea3656c5182754d1ebafabd93d`**. **087** adds **post–INV-06** inventory contract proof below.

```text
$ bash scripts/ci/verify_v1_17_friction_research_contract.sh
verify_v1_17_friction_research_contract: OK
```

*(Recorded **2026-04-24** from repository root on workspace after **INV-06** subsection append; exit **0**.)*

## INV-06 closure checklist

- [x] **(b)** — **Dated maintainer certification** that no new sourced **P1**/**P2** rows were warranted: **`.planning/research/v1.17-FRICTION-INVENTORY.md`** → **`### v1.28 INV-06 maintainer pass (2026-04-24)`**.
- [x] **Named verifiers + SHA** — **`docs-contracts-shift-left`** six-script bundle (**SHA-pinned** above) + **`host-integration`** job naming + **`086-VERIFICATION.md`** cross-reference — with **Reviewed merge SHA** **`aa3df3cad0262b3760a9f9a65a56d177eb6bc047`**.
- [x] **`verify_v1_17_friction_research_contract.sh`** green on final tree after inventory edit (**path (b)**).
