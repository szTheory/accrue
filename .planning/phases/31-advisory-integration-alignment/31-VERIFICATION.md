---
status: passed
phase: 31-advisory-integration-alignment
verified: 2026-04-21
---

# Phase 31 — Verification

## Goal

Advisory integration alignment: VERIFY-01 README/CI parity for mobile, host `e2e:mobile`, Copy-backed step-up modal chrome, reduced Playwright literal drift in `accrue_admin` fixture UAT with documentation of host-first VERIFY-01.

## Must-haves (from plans)

| Item | Evidence |
|------|----------|
| Mobile VERIFY-01 contract anchors | `scripts/ci/verify_verify01_readme_contract.sh` requires `e2e/verify01-admin-mobile.spec.js` and `### Mounted admin — mobile shell`; optional file-exists loop for `e2e/verify01-*.spec.js` |
| `npm run e2e:mobile` | `examples/accrue_host/package.json` script; README VERIFY-01 prose |
| Step-up Copy SSOT | `AccrueAdmin.Copy` step_up_* functions; `step_up_auth_modal.ex` uses them |
| Phase7 UAT structural asserts | `phase7-uat.spec.js` uses `replay-confirm`, regex toasts, regex bulk confirm body |
| Host-first documentation | `.github/workflows/accrue_admin_browser.yml` header comment; `accrue_admin/README.md` Browser UAT paragraph |

## Automated checks run

- `bash scripts/ci/verify_verify01_readme_contract.sh`
- `cd accrue_admin && mix compile --warnings-as-errors`
- `cd accrue_admin && mix test test/accrue_admin/live/step_up_test.exs --warnings-as-errors`
- `cd accrue_admin && npm run e2e`
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/accrue_admin_browser.yml'))"`
- `cd accrue && mix compile --warnings-as-errors`

## Human verification

None required for this phase (fixture + docs + contract script).

## Gaps

None.

## Verification Complete

Phase 31 implementation matches plan intent; no `gaps_found`.
