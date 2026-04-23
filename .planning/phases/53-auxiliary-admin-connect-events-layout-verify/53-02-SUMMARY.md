---
phase: 53-auxiliary-admin-connect-events-layout-verify
plan: "02"
subsystem: testing
tags: [playwright, axe, verify01, copy_strings]

requires:
  - provides: Plan 53-01 Copy function names for export and assertions
provides:
  - VERIFY-01 Playwright coverage for /connect, /connect/:id, /events, /coupons, /promotion-codes
  - Extended export_copy_strings allowlist and regenerated copy_strings.json
  - E2E fixture connect_account_id for deterministic Connect detail URL
  - ADM-06 path inventory extension (verify01-v112-admin-paths.md)
affects: [ci, accrue_host_seed_e2e]

tech-stack:
  added: []
  patterns:
    - "Minimal Connect account row in accrue_host_seed_e2e for VERIFY-01 detail path"

key-files:
  created: []
  modified:
    - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
    - examples/accrue_host/e2e/generated/copy_strings.json
    - examples/accrue_host/e2e/verify01-admin-a11y.spec.js
    - examples/accrue_host/docs/verify01-v112-admin-paths.md
    - scripts/ci/accrue_host_seed_e2e.exs

key-decisions:
  - "Playwright uses domcontentloaded + waitForLiveView (no networkidle), consistent with existing VERIFY-01 tests."

patterns-established: []

requirements-completed: [AUX-06]

duration: 40min
completed: 2026-04-23
---

# Phase 53 plan 02 summary

**VERIFY-01 now exercises auxiliary mounted paths (Connect list and detail, events, coupons, promotion codes) with axe and copyStrings SSOT assertions, backed by an expanded export allowlist and a seeded Connect account for stable detail URLs.**

## Accomplishments

- Extended **`mix accrue_admin.export_copy_strings`** allowlist and regenerated **`examples/accrue_host/e2e/generated/copy_strings.json`**.
- Added five **`test.describe`** blocks to **`verify01-admin-a11y.spec.js`** mirroring the existing customers/subscriptions login + org scope + light theme + **scanAxe** pattern.
- Seeded **`acct_host_browser_verify01`** **`Accrue.Connect.Account`** for **`connect_account_id`** in the host E2E fixture JSON.
- Documented mounted templates and **AUX** mapping in **`verify01-v112-admin-paths.md`**.

## Verification

- `bash scripts/ci/verify_verify01_readme_contract.sh` — **OK**.
- Allowlist drift loop (every **`copyStrings.*`** key appears in **`@allowlist`**) — **OK**.
- **`bash scripts/ci/accrue_host_verify_browser.sh`** — **not re-run to completion here** (script prompted for **Stripe** re-auth in this environment); run in CI or with a non-interactive **Stripe** session before merge.

## Self-Check: PASSED
