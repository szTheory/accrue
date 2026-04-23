# Phase 63 — Pattern Map

Analogs for executors — read before editing.

| Intended change | Closest existing pattern | Excerpt / rule |
|-----------------|---------------------------|----------------|
| Doc pin enforcement | `scripts/ci/verify_package_docs.sh` | `fail()` → stderr `[verify_package_docs]`; `require_fixed` / `require_regex` on paths |
| ExUnit wraps bash verifier | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `System.cmd("bash", ...)` with repo root |
| Friction inventory needles | `scripts/ci/verify_v1_17_friction_research_contract.sh` | Row counts, `| INT-10 |`, `| →63 |`, `### Backlog — INT-10` anchor |
| Phase VERIFICATION lean table | `.planning/phases/62-friction-triage-north-star/62-VERIFICATION.md` | Scope + traceability rows + commands |
| PLAN task XML shape | `.planning/phases/62-friction-triage-north-star/62-01-PLAN.md` | Frontmatter + `<task>` + `<read_first>` + grep acceptance |
| Host CI entrypoint | `scripts/ci/accrue_host_uat.sh` | Delegates to `examples/accrue_host` + `mix verify.full` |
| Contributor triage tables | `scripts/ci/README.md` § INT gates | `### Triage: verify_*` bullets map stderr prefix → owner doc |

---

## PATTERN MAPPING COMPLETE
