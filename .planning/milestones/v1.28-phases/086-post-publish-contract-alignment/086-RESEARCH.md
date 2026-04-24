# Phase 86 — Post-publish contract alignment — Research

**Question:** What do we need to know to plan **PPX-05..PPX-08** well on the next linked Hex publish?

## Findings

### Normative CI contract

Job **`docs-contracts-shift-left`** in **`.github/workflows/ci.yml`** (merge-blocking on `pull_request`) runs these steps in order:

1. `bash scripts/ci/verify_package_docs.sh`
2. `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
3. `bash scripts/ci/verify_verify01_readme_contract.sh`
4. `bash scripts/ci/verify_production_readiness_discoverability.sh`
5. `bash scripts/ci/verify_adoption_proof_matrix.sh`
6. `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`

**PPX-07** requires evidence for this **full** set on the branch that ships (or immediately follows) the **`@version`** bump — not a cherry-picked subset (**086-CONTEXT** D-06, D-07).

### PPX-05 / PPX-06 split

- **PPX-05:** Bash **`verify_package_docs.sh`** plus ExUnit **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** (needs Postgres for full ExUnit; CI runs under **`release-gate`** with DB — **docs-contracts-shift-left** is bash-only for package docs; ExUnit path is still merge-blocking via release matrix). Executor should run bash from repo root; run ExUnit from **`accrue/`** per prior phases (**75**, **69**, **083**).
- **PPX-06:** **`verify_adoption_proof_matrix.sh`** must stay aligned with **`examples/accrue_host/docs/adoption-proof-matrix.md`** — same-PR co-update when matrix or script expectations change.

### PPX-08 boundary vs Phase 87

- Update **`.planning/PROJECT.md`**, **`MILESTONES.md`**, **`STATE.md`** to published **`accrue` / `accrue_admin`** versions.
- For friction-inventory rows **reopened by publish**, minimal status + pointer to **`086-VERIFICATION.md`**; **do not** write **INV-06** dated maintainer subsection body here (**086-CONTEXT** D-05).

### Evidence artifact

**`75-VERIFICATION.md`** is the lean template: Preconditions → Evidence checklist (PPX mapped to commands) → Sign-off. Add optional **Transcript annex** only when script membership or expected output changes (**086-CONTEXT** D-04).

### PR coupling

Default: **`086-VERIFICATION.md`**, all doc/verifier touches, and **`mix.exs` `@version`** in **one PR** before merge to **`main`** (**086-CONTEXT** D-01). Exception: same-day follow-up documented in Preconditions (**D-02**).

## Validation Architecture

| Dimension | Approach |
|-----------|----------|
| **Contract surface** | Bash exit codes + stdout needles documented in **`086-VERIFICATION.md`**; optional CI run URL or log paste when gates change. |
| **Sampling** | After each logical task group: re-run affected scripts; before close: full **`docs-contracts-shift-left`** list from **`ci.yml`**. |
| **Manual** | Hex registry “what shipped” cross-check (read-only) if automation misfit — record in Preconditions. |
| **Regression** | **`package_docs_verifier_test.exs`** mirrors **`verify_package_docs.sh`** invariants. |

Nyquist: every executor task with automated verify maps to a named command; no watch-mode.

## RESEARCH COMPLETE

Research sufficient to author **`086-VALIDATION.md`**, **`086-01-PLAN.md`**, and execution checklist.
