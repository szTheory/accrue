---
status: complete
phase: 21-admin-and-host-ux-proof
source:
  - 21-01-SUMMARY.md
  - 21-02-SUMMARY.md
  - 21-03-SUMMARY.md
  - 21-04-SUMMARY.md
  - 21-05-SUMMARY.md
  - 21-06-SUMMARY.md
updated: "2026-04-17T00:00:00Z"
---

# Phase 21 — VERIFY-01 automation manifest

Human conversational UAT is retired for this phase. **Source of truth:** PR CI job
`host-integration` (`.github/workflows/ci.yml`) runs the same contract as
`cd examples/accrue_host && mix verify.full`, including E2E seed, fixture JSON
schema guard (`scripts/ci/verify_e2e_fixture_jq.sh`), full Playwright, and host
Mix proofs. README drift is blocked by `scripts/ci/verify_verify01_readme_contract.sh`
at the start of that job.

| # | Former UAT intent | Automation | Where it runs |
|---|-------------------|--------------|----------------|
| 1 | README VERIFY-01 (Fake-first, commands, no `sk_live` advice) | `verify_verify01_readme_contract.sh` greps `examples/accrue_host/README.md` | First step of `host-integration` |
| 2 | E2E seed writes fixture JSON | `accrue_host_seed_e2e.exs` + `verify_e2e_fixture_jq.sh` | `mix verify.full` → `verify_browser_command` in `examples/accrue_host/mix.exs` |
| 3 | Host integration / facade / org billing | `mix verify` + `mix verify.full` regression (`mix test --warnings-as-errors`) | `host-integration` via `scripts/ci/accrue_host_uat.sh` |
| 4 | Admin shell + money LiveViews | ExUnit under `accrue_admin/test/...` (same modules as historical VERIFY-01 list) | `release-gate` matrix / local `cd accrue_admin && mix test` |
| 5 | Org switching + tax invalid (browser) | Playwright | `examples/accrue_host/e2e/verify01-org-switching.spec.js`, `verify01-tax-invalid.spec.js` |
| 6 | Host org billing switcher + headings | Playwright org switching | Same as row 5 (`verify01-org-switching.spec.js`) |
| 7 | Mounted admin: Active organization + Billing signals | Playwright | `examples/accrue_host/e2e/verify01-admin-mounted.spec.js` |
| 8 | Tax & ownership card copy | ExUnit (canonical; mounted pixel parity optional) | `accrue_admin/test/accrue_admin/live/customer_live_test.exs` |
| 9 | Finance-boundary narrative (VERIFY-01 doc half) | ExUnit doc contract + published guide | `accrue/guides/finance-handoff.md`, `mix test test/accrue/finance_handoff_doc_test.exs` (Phase 22) |

The **VERIFY-01** requirement spans Phase 21 (executable) and Phase 22 (finance handoff docs + milestone traceability).

## Summary

| outcome | count |
|---------|------:|
| automated in CI / ExUnit | 9 |
| manual blocking | 0 |

## Advisory (non-blocking)

- Stripe test-mode parity: workflow job id `live-stripe` in `.github/workflows/ci.yml` (manual/cron only; display name **Stripe test-mode parity**); see `guides/testing-live-stripe.md`.
- Subjective / marketing screenshots: optional local headed Playwright only (`21-VALIDATION.md` Manual-Only table).
