---
phase: 39
status: passed
verified: "2026-04-21"
---

# Phase 39 verification

## Must-haves (plans)

| Plan | Evidence |
|------|-----------|
| 39-01 | `## Organization billing proof (ORG-09)` + primary/recipe tables + `scripts/ci/verify_adoption_proof_matrix.sh` literal in `examples/accrue_host/docs/adoption-proof-matrix.md`. |
| 39-02 | `scripts/ci/verify_adoption_proof_matrix.sh`; `host-integration` step **ORG-09 adoption proof matrix literals**; `## ORG gates (v1.8 org billing proof)` in `scripts/ci/README.md`. |
| 39-03 | `## Adoption proof matrix (ORG-09)` in `accrue/guides/organization_billing.md`; needles + `organization_billing_org09_matrix_test.exs` bash smoke. |

## Roadmap success criteria

1. **ORG-09 SSOT** — Adoption matrix documents merge-blocking non-Sigra mainline vs advisory ORG-07/ORG-08 lanes without widening VERIFY-01.
2. **Machine enforcement** — Bash verifier + `host-integration` + accrue ExUnit smoke cover accidental drift or script deletion.
3. **Contributor DX** — `scripts/ci/README.md` maps stderr prefix `verify_adoption_proof_matrix:` to ORG-09 triage.

## Automated checks run

```bash
bash scripts/ci/verify_adoption_proof_matrix.sh
cd accrue && mix format --check-formatted
cd accrue && mix compile --warnings-as-errors
cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs test/accrue/docs/organization_billing_org09_matrix_test.exs
cd accrue && MIX_ENV=test mix docs --warnings-as-errors
```

## human_verification

None required (documentation, bash gate, and contract tests only).

## Gaps

None.
