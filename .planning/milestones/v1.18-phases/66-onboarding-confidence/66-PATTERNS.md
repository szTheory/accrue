# Phase 66 — Pattern map (analogs)

**Generated:** 2026-04-23 — for executor read-first routing.

## Target artifacts → closest analog

| Role | Create / touch | Analog (read_first) |
|------|----------------|---------------------|
| Verification ledger | `.planning/phases/66-onboarding-confidence/66-VERIFICATION.md` | `.planning/milestones/v1.17-phases/63-p0-integrator-verify-docs/63-VERIFICATION.md` (YAML + single matrix) |
| Doc-contract plan shape | `66-*-PLAN.md` | `.planning/milestones/v1.17-phases/63-p0-integrator-verify-docs/63-01-PLAN.md` (frontmatter, `<threat_model>`, `<task>` XML, grep acceptance) |
| Friction bash SSOT | `scripts/ci/verify_v1_17_friction_research_contract.sh` | Self + `scripts/ci/README.md` INT-10 row |
| ExUnit mirror | `accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs` | Invokes `../scripts/ci/verify_v1_17_friction_research_contract.sh` from `accrue/` |
| Adoption matrix contract | `scripts/ci/verify_adoption_proof_matrix.sh` | Paired with `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` |
| CI wiring | `.github/workflows/ci.yml` | Job id **`docs-contracts-shift-left`** (not legacy `verify_package_docs` job label in prose) |
| Historical UAT errata | `62-UAT.md` | Top banner blockquote pattern already applied 2026-04-23 — verify D-03c, avoid body rewrite |

## Data flow

`REQUIREMENTS.md` (law) → `66-VERIFICATION.md` (proof rows) → `STATE.md` / optional `verify_*.sh` → `REQUIREMENTS.md` traceability table checkboxes when truly closed.
