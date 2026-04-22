# Phase 39 — Pattern Map

**Phase directory:** `.planning/phases/39-org-billing-proof-alignment`

## Analog: shift-left bash verifier

| New / edited | Role | Closest existing analog | Excerpt / pattern |
|--------------|------|-------------------------|-------------------|
| `scripts/ci/verify_adoption_proof_matrix.sh` | ORG-09 matrix literals | `scripts/ci/verify_verify01_readme_contract.sh` | `require_substring`, `repo_root=`, `set -euo pipefail`, stderr-prefixed errors |
| `host-integration` step | Order with VERIFY-01 | `.github/workflows/ci.yml` ~L359 | `run: bash scripts/ci/verify_verify01_readme_contract.sh` — add adjacent matrix step |

## Analog: contributor table row

| New / edited | Role | Closest existing analog |
|--------------|------|-------------------------|
| `scripts/ci/README.md` `## ORG gates` | ORG-09 ownership | Existing `## ADOPT gates` table + triage bullets |

## Analog: ExUnit doc contract

| New / edited | Role | Closest existing analog |
|--------------|------|-------------------------|
| `organization_billing_guide_test.exs` needles | ORG-09 literals | Existing `for needle <- [` list |
| Optional: bash script smoke in ExUnit | Script deletion guard | `accrue/test/accrue/phase_31_nyquist_validation_test.exs` — `System.cmd("bash", [script], cd: root)` |

## Analog: adoption matrix prose

| New / edited | Role | Closest existing analog |
|--------------|------|-------------------------|
| `adoption-proof-matrix.md` | Blocking vs advisory sections | Current `## Blocking` / `## Advisory` tables and caveat paragraph |

---

## PATTERN MAPPING COMPLETE
