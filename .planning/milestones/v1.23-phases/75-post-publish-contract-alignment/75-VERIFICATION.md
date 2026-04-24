# Phase 75 — Post-publish contract alignment — Verification

**Milestone:** v1.23  
**Status:** **Complete** (2026-04-24)

## Preconditions

- Workspace **`accrue/mix.exs`** and **`accrue_admin/mix.exs`** **`@version`**: **0.3.1** (matches **Hex** published pair as of verification).
- No new SemVer bump in this pass — **revisit trigger** satisfied by **contract re-verification** at current published line.

## Evidence checklist

1. **PPX-01** — **`bash scripts/ci/verify_package_docs.sh`** → exit **0**, stdout includes `package docs verified for accrue 0.3.1 and accrue_admin 0.3.1`. **`accrue/test/accrue/docs/package_docs_verifier_test.exs`**: same assertion path as script; requires **Postgres TestRepo** — **merge-blocking on CI** via **`release-gate`** / **`docs-contracts-shift-left`** (local dev without `postgres` role: rely on CI for ExUnit slice).
2. **PPX-02** — **`bash scripts/ci/verify_adoption_proof_matrix.sh`** → exit **0**.
3. **PPX-03** — **`docs-contracts-shift-left`** bash gates run locally, all exit **0**:
   - `verify_package_docs.sh`
   - `verify_v1_17_friction_research_contract.sh` (inventory **5** rows after **`v1.17-P1-002`**; verifier needle updated in same change set)
   - `verify_verify01_readme_contract.sh`
   - `verify_production_readiness_discoverability.sh`
   - `verify_adoption_proof_matrix.sh`
   - `verify_core_admin_invoice_verify_ids.sh`
4. **PPX-04** — **`.planning/PROJECT.md`**, **`MILESTONES.md`**, **`STATE.md`** already call out **`accrue` / `accrue_admin` 0.3.1`**; **`v1.17-P1-002`** → **closed** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with this file as pointer.

## Sign-off

- [x] Maintainer: requirements **PPX-01..PPX-04** satisfied for **0.3.1** registry alignment pass (**no** **PROC-08** / **FIN-03**).
