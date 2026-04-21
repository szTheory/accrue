---
status: passed
phase: 36
verified: 2026-04-21
---

# Phase 36 — Verification

## Automated

| Check | Result |
|-------|--------|
| `bash scripts/ci/verify_package_docs.sh` | PASS |
| `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` | PASS |
| `cd accrue_admin && mix test test/accrue_admin/nav_test.exs test/accrue_admin/components/navigation_components_test.exs --warnings-as-errors` | PASS |

## ROADMAP success criteria

1. **Three-source traceability (32–33):** `36-TRACEABILITY-MATRIX.md` records each `32-*` / `33-*` plan summary `requirements-completed:` line against `32-VERIFICATION.md` / `33-VERIFICATION.md` Requirements rows; no YAML corrections were required (all six already aligned). **Met.**
2. **Contributor map + triage labels:** `scripts/ci/README.md` maps ADOPT-01..06 to scripts/ExUnit/verification owners; `CONTRIBUTING.md` links to it; `verify_package_docs.sh` stderr is prefixed with `[verify_package_docs]`. **Met.**
3. **Dual-contract documentation:** `accrue/guides/testing.md` section **Adoption documentation contracts (dual README gates)** documents both verifier scripts and root vs host README roles. **Met.**
4. **Forward coupling OPS-03..05:** `36-FORWARD-COUPLING-OPS-34-35.md` exists and references existing `AccrueAdmin.Nav`, tests, README route inventory, Phase 35 UX-04 context, `AccrueAdmin.Copy`, and `examples/accrue_host/e2e/`; `testing.md` points maintainers at that file. **Met.**

## Requirements

| ID | Evidence |
|----|----------|
| ADOPT-01..06 | Plans 36-01–36-02 + matrix + `scripts/ci/README.md` rows |
| OPS-03..05 | Plan 36-03 + forward-coupling doc + `testing.md` appendix |

## human_verification

None required (docs, bash stderr prefix, and ExUnit updates only).
