# Phase 60 — Pattern map

Analogs for executor **read_first** alignment.

| Intended change | Analog | Pattern |
|-----------------|--------|---------|
| Adoption matrix structure | `examples/accrue_host/docs/adoption-proof-matrix.md` | Headings `## Blocking`, `## Organization billing proof (ORG-09)`, `### Primary archetype (merge-blocking)` / recipe lanes; tables with concern / proof / where. |
| Walkthrough checklist | `examples/accrue_host/docs/evaluator-walkthrough-script.md` | Short numbered steps; VERIFY-01 / Fake vs Stripe separation. |
| CI contributor registry | `scripts/ci/README.md` | `## ADOPT gates` / `## ORG gates` tables: REQ-ID, script, ExUnit, `.planning/phases/.../VERIFICATION.md`. |
| Matrix literal gate | `scripts/ci/verify_adoption_proof_matrix.sh` | `require_substring` for each enforced needle — extend only when matrix taxonomy changes intentionally. |
| Prior INT narrative | `.planning/phases/59-golden-path-quickstart-coherence/59-CONTEXT.md` | Bash trio order; Hex vs planning labels; no markdown skip of `host-integration`. |

## PATTERN MAPPING COMPLETE
