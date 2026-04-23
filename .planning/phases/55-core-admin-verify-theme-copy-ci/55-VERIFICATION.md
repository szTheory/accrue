---
status: passed
phase: 55-core-admin-verify-theme-copy-ci
verified: "2026-04-23"
---

# Phase 55 verification

## Automated

- `bash scripts/ci/verify_e2e_fixture_jq.sh` on fixture from `MIX_ENV=test mix run scripts/ci/accrue_host_seed_e2e.exs` — **PASS** (`invoice_id` string contract).
- `bash scripts/ci/accrue_host_verify_browser.sh` — **PASS** (full Playwright matrix including VERIFY-01 a11y + trust walkthrough).
- `cd accrue_admin && mix test` — **PASS**.
- `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` — **PASS**.

## Must-haves (from plans)

- **ADM-09:** `verify01-admin-a11y.spec.js` contains merge-blocking `core-admin-invoices-index` and `core-admin-invoices-detail` flows; parity matrix and path map reference the same ids and merge-blocking lane.
- **ADM-10:** `admin_ui.md` links to `guides/theme-exceptions.md`; `theme-exceptions.md` includes Phase 55 honesty note.
- **ADM-11:** `export_copy_strings` allowlist + `copy_strings.json` include only keys used by new VERIFY lines.

## Notes

- DataTable `current_owner_scope` wiring was missing on several list LiveViews (only `events_live` had it); fixing this was required for org-scoped list correctness and for subscriptions empty-state VERIFY stability.
