---
phase: 55-core-admin-verify-theme-copy-ci
plan: "02"
subsystem: docs
tags: [parity, verify01, ci, theme]

requires:
  - phase: 55-01
    provides: Named VERIFY flow ids in verify01-admin-a11y.spec.js
provides:
  - Parity matrix + VERIFY path map aligned to ADM-09 invoice anchors
  - CI drift guard for invoice flow ids
  - admin_ui link hygiene to package theme-exceptions SSOT
affects: [contributor-docs]

key-files:
  created:
    - scripts/ci/verify_core_admin_invoice_verify_ids.sh
  modified:
    - accrue_admin/guides/core-admin-parity.md
    - examples/accrue_host/docs/verify01-v112-admin-paths.md
    - accrue_admin/guides/admin_ui.md
    - accrue_admin/guides/theme-exceptions.md
    - .github/workflows/ci.yml

requirements-completed: [ADM-09, ADM-10, ADM-11]

duration: ""
completed: "2026-04-23"
---

# Phase 55 Plan 02 Summary

**Parity docs, contributor theme links, and a CI drift guard now track merge-blocking invoice VERIFY anchors without forking SSOT.**

## Accomplishments

- Updated `core-admin-parity.md` invoice rows to `core-admin-invoices-*` ids and `merge-blocking` VERIFY lane; clarified VERIFY column prose.
- Documented Phase 55 invoice paths and `test.describe` titles in `verify01-v112-admin-paths.md`.
- Replaced stale `.planning/...26-theme-exceptions` link in `admin_ui.md` with `theme-exceptions.md`; added Phase 55 reviewer note to the register.
- Added `verify_core_admin_invoice_verify_ids.sh` and a host-integration workflow step.

## Verification

- `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` — exit 0
- `rg "26-theme-exceptions" accrue_admin/guides/admin_ui.md` — no matches

## Self-Check: PASSED
