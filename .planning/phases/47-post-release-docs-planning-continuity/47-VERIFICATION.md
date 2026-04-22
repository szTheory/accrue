---
phase: 47-post-release-docs-planning-continuity
status: passed
verified: 2026-04-22
---

# Phase 47 verification

## Must-haves (from plans)

| Requirement | Evidence |
|-------------|----------|
| **REL-03** | `RELEASING.md` opens with routine Release Please + Hex path; appendix titled **Appendix: Same-day `1.0.0` bootstrap (exceptional)**; first ~15 lines reference **Release Please**, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`. |
| **DOC-01** | `accrue/guides/first_hour.md` contains `{:accrue, "~> 0.3.0"}` and `{:accrue_admin, "~> 0.3.0"}` matching `accrue/mix.exs` `@version`; prose on pre-1.0 / lockstep / patches. |
| **DOC-02** | `bash scripts/ci/verify_package_docs.sh` exit 0; `mix test test/accrue/docs/package_docs_verifier_test.exs` exit 0. |
| **HYG-01** | `.planning/PROJECT.md`, `.planning/MILESTONES.md` (v1.11 block), `.planning/STATE.md` describe **0.3.0** public Hex; no stale **0.1.2** as *current* in those files. |

## Commands run

```bash
bash scripts/ci/verify_package_docs.sh
cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs
cd accrue && mix docs --warnings-as-errors
```

## Human verification

None required for this phase (documentation and planning continuity only).
