# Phase 86 — Post-publish contract alignment — Verification

**Milestone:** v1.28  
**Status:** **Complete** (2026-04-24)

## Preconditions

- Workspace **`accrue/mix.exs`** **`@version`**: **0.3.1** (literal from file).
- Workspace **`accrue_admin/mix.exs`** **`@version`**: **0.3.1** (literal from file).
- **Reviewed merge SHA:** `a533474e6928f7ea3656c5182754d1ebafabd93d` (40-character lowercase hex for this contract pass on **`main`** / feature branch under review).
- **No new SemVer bump in this pass** — **v1.28** **PPX-05..08** are satisfied by **contract re-verification** at the published **0.3.1** **Hex** pair and the **SHA** above (same discipline family as **Phase 75** **PPX-01..04**). The **next** linked **Hex** **`@version`** bump remains the forcing function for **INV-06** / **Phase 87**.

## Evidence checklist

1. **PPX-05** — **`bash scripts/ci/verify_package_docs.sh`** → exit **0**, stdout includes **`package docs verified for accrue`** and **`accrue_admin`** with version **0.3.1**. **`accrue/test/accrue/docs/package_docs_verifier_test.exs`**: **`cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs`** → exit **0** (local: **`PGUSER`** must match a reachable Postgres role for **`Accrue.TestRepo`**; merge-blocking path is **CI** **`release-gate`** / **`docs-contracts-shift-left`**).
2. **PPX-06** — **`bash scripts/ci/verify_adoption_proof_matrix.sh`** → exit **0**; **`examples/accrue_host/docs/adoption-proof-matrix.md`** needle-aligned (same-PR discipline per **`scripts/ci/README.md`**).
3. **PPX-07** — Merge-blocking **`docs-contracts-shift-left`** bundle (see **`.github/workflows/ci.yml`** job **`docs-contracts-shift-left`**) — all exit **0** when run sequentially from repository root:
   - `bash scripts/ci/verify_package_docs.sh`
   - `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
   - `bash scripts/ci/verify_verify01_readme_contract.sh`
   - `bash scripts/ci/verify_production_readiness_discoverability.sh`
   - `bash scripts/ci/verify_adoption_proof_matrix.sh`
   - `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`

   **Local verification (2026-04-24):** All six commands above exited **0** on merge SHA **`a533474e6928f7ea3656c5182754d1ebafabd93d`**.

4. **PPX-08** — **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/STATE.md`** public **Hex** / last-published callouts match **0.3.1**; friction-inventory hygiene below.

## PPX-08 friction inventory

- **No friction rows reopened by this publish — inventory unchanged.**

## Sign-off

- [x] Maintainer: requirements **PPX-05** satisfied (**no** **PROC-08** / **FIN-03**).
- [x] Maintainer: requirements **PPX-06** satisfied (**no** **PROC-08** / **FIN-03**).
- [x] Maintainer: requirements **PPX-07** satisfied (**no** **PROC-08** / **FIN-03**).
- [x] Maintainer: requirements **PPX-08** satisfied (**no** **PROC-08** / **FIN-03**).
