---
phase: 55-core-admin-verify-theme-copy-ci
plan: "01"
subsystem: testing
tags: [playwright, axe, e2e, verify01, invoices]

requires: []
provides:
  - Deterministic E2E fixture field invoice_id for invoice detail URLs
  - Merge-blocking VERIFY-01 flows core-admin-invoices-index and core-admin-invoices-detail
  - DataTable org scoping via current_owner_scope on core admin list surfaces
affects: [verify01-host-ci]

key-files:
  created: []
  modified:
    - scripts/ci/accrue_host_seed_e2e.exs
    - scripts/ci/verify_e2e_fixture_jq.sh
    - examples/accrue_host/e2e/verify01-admin-a11y.spec.js
    - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
    - examples/accrue_host/e2e/generated/copy_strings.json
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - examples/accrue_host/e2e/verify01-admin-mounted.spec.js
    - examples/accrue_host/e2e/verify01-admin-mobile.spec.js
    - examples/accrue_host/e2e/phase13-canonical-demo.spec.js

requirements-completed: [ADM-09, ADM-11]

duration: ""
completed: "2026-04-23"
---

# Phase 55 Plan 01 Summary

**Host VERIFY-01 now merge-blocks invoice index + detail with a deterministic fixture `invoice_id`, and org-scoped DataTables stop leaking cross-tenant rows into list UIs.**

## Accomplishments

- Seeded a stable Fake invoice on the Admin E2E Alpha org customer, emitted `invoice_id` in the fixture JSON, and extended `verify_e2e_fixture_jq.sh`.
- Added Playwright + axe coverage for `core-admin-invoices-index` / `core-admin-invoices-detail`, extended `export_copy_strings` allowlist, regenerated `copy_strings.json`.
- Passed `current_owner_scope` into `DataTable` on admin list LiveViews (matching `events_live`) so queries honor organization scope.
- Stabilized mobile/host E2E selectors where card layout and nav labels differ from desktop.

## Verification

- `bash scripts/ci/verify_e2e_fixture_jq.sh` on fresh seed temp fixture — OK
- `bash scripts/ci/accrue_host_verify_browser.sh` — exit 0
- `cd accrue_admin && mix test` — exit 0

## Self-Check: PASSED
