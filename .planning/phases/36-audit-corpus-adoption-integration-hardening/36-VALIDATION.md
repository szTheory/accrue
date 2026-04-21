---
phase: 36
slug: audit-corpus-adoption-integration-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 36 — Validation strategy

> Primarily **doc contracts**, **grep/structure checks**, and **audit re-run**. Functional ADOPT behavior is already verified in Phases 32–33.

---

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash `scripts/ci/*.sh` + targeted `accrue/test/**/docs/*_test.exs` as already wired |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh` (from repo root) |
| **Audit gate** | `/gsd-audit-milestone` after Phase 36 verification passes |

---

## Wave 0

Planning materialized; **no plans executed yet.**

---

## Per-phase checks (to fill after plans)

- [ ] Every completed `32-*-SUMMARY.md` / `33-*-SUMMARY.md` includes `requirements-completed` YAML consistent with VERIFICATION.
- [ ] Contributor doc maps ADOPT rows to verifier entrypoints.
- [ ] Forward-coupling artifact exists for OPS + Copy + route matrix.
