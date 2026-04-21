# Phase 36 — Three-source traceability matrix (Phases 32–33)

Cross-check of each shipped plan summary’s `requirements-completed:` line against the **Requirements** tables in `32-VERIFICATION.md` and `33-VERIFICATION.md`, plus plan scope (titles / must-haves). Verbatim YAML lines are taken from disk at audit time (2026-04-21).

| Summary file | Plan | requirements-completed (verbatim) | Verification reference (section/row) | Notes |
|--------------|------|-----------------------------------|----------------------------------------|-------|
| `.planning/phases/32-adoption-discoverability-doc-graph/32-01-SUMMARY.md` | 01 | `requirements-completed: [ADOPT-02]` | `32-VERIFICATION.md` — **## Requirements**, row **ADOPT-02** (host README structure + `verify_verify01_readme_contract.sh`) | Plan 32-01 delivered host Proof section + VERIFY-01 awk / package README alignment; matches ADOPT-02 evidence column. |
| `.planning/phases/32-adoption-discoverability-doc-graph/32-02-SUMMARY.md` | 02 | `requirements-completed: [ADOPT-01]` | `32-VERIFICATION.md` — **## Requirements**, row **ADOPT-01** (root `## Proof path (VERIFY-01)` + `verify_package_docs.sh`) | Plan 32-02 delivered root proof path block; matches ADOPT-01. |
| `.planning/phases/32-adoption-discoverability-doc-graph/32-03-SUMMARY.md` | 03 | `requirements-completed: [ADOPT-03]` | `32-VERIFICATION.md` — **## Requirements**, row **ADOPT-03** (`testing.md`, `first_hour.md`, `testing-live-stripe.md` + `require_fixed` one-liner) | Plan 32-03 aligned package guides + script pins; matches ADOPT-03. |
| `.planning/phases/33-installer-host-contracts-ci-clarity/33-01-SUMMARY.md` | 01 | `requirements-completed: [ADOPT-04]` | `33-VERIFICATION.md` — **## Requirements**, row **ADOPT-04** (`first_hour.md` §4 + `first_hour_guide_test.exs`) | Plan 33-01 First Hour + ExUnit anchor; matches ADOPT-04. |
| `.planning/phases/33-installer-host-contracts-ci-clarity/33-02-SUMMARY.md` | 02 | `requirements-completed: [ADOPT-05]` | `33-VERIFICATION.md` — **## Requirements**, row **ADOPT-05** (`verify_package_docs.sh` `require_fixed` lines) | Plan 33-02 extended doc gate pins; matches ADOPT-05. |
| `.planning/phases/33-installer-host-contracts-ci-clarity/33-03-SUMMARY.md` | 03 | `requirements-completed: [ADOPT-06]` | `33-VERIFICATION.md` — **## Requirements**, row **ADOPT-06** (`.github/workflows/ci.yml` comments; `README.md`; `guides/testing-live-stripe.md`) | Plan 33-03 CI header comments + README / live-Stripe prose; matches ADOPT-06. |

## Three-source alignment result

- **No YAML edits required — all six summaries aligned.**

Each summary’s `requirements-completed:` ID matches the same ADOPT row that `*-VERIFICATION.md` uses as evidence for that plan’s scope; no contradictions were found between summary YAML, verification tables, and plan deliverables.
