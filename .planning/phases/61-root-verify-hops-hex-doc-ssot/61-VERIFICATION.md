---
status: passed
phase: 61-root-verify-hops-hex-doc-ssot
verified: 2026-04-23
---

# Phase 61 — Verification

**Requirements:** INT-08, INT-09 (see `.planning/REQUIREMENTS.md`)

**Plans:** `61-01-PLAN.md` (INT-08), `61-02-PLAN.md` (INT-09)

## Automated gates

| Check | Result | Evidence |
|-------|--------|----------|
| `bash scripts/ci/verify_package_docs.sh` | **PASS** | Exit **0** on **2026-04-23** after plan commits |
| `bash scripts/ci/verify_verify01_readme_contract.sh` | **PASS** | Exit **0** same session |
| `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | **PASS** | **7** tests, **0** failures (`PGUSER=$USER` where role `postgres` is absent) |

## Must-haves (plans)

| ID | Criterion | Evidence |
|----|-----------|----------|
| **61-01** | INT-08 row in `scripts/ci/README.md`; root merge-blocking line pinned in `verify_package_docs.sh`; ownership comment + D-07 audit | `rg '\| INT-08 \|' scripts/ci/README.md`; comment block before host README pins; `require_fixed` on merge-blocking README sentence |
| **61-02** | INT-09 row; PROJECT / MILESTONES dual-track Hex honesty; CONTRIBUTING pre-publish edge | `rg '\| INT-09 \|' scripts/ci/README.md`; **§ Current State** in `.planning/PROJECT.md`; **v1.16** header in `.planning/MILESTONES.md`; **Hex-only `mix deps.get`** paragraph in `CONTRIBUTING.md` |

## Human verification

None required (docs + CI scripts only).
