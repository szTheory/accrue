# Phase 75 — Post-publish contract alignment — Verification

**Milestone:** v1.23  
**Status:** Pending (run after linked **`accrue` / `accrue_admin`** Hex publish + version alignment merge)

## Evidence checklist

1. **PPX-01** — Capture log or CI link for **`verify_package_docs.sh`** + **`package_docs_verifier_test`** green on **`main`** at the shipped **`@version`**.
2. **PPX-02** — Capture log or CI link for **`verify_adoption_proof_matrix.sh`** green post-merge.
3. **PPX-03** — Confirm **`docs-contracts-shift-left`** (including **`verify_production_readiness_discoverability.sh`**) green on the same merge window.
4. **PPX-04** — Confirm **`.planning/PROJECT.md`**, **`MILESTONES.md`**, **`STATE.md`** Hex lines match **hex.pm** for the shipped pair; confirm **`v1.17-P1-002`** row **closed** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with pointer to this file.

## Sign-off

- [ ] Maintainer: requirements **PPX-01..PPX-04** satisfied for the shipped release.
