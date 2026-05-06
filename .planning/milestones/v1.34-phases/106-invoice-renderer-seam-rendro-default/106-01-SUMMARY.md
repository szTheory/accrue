---
phase: 106-invoice-renderer-seam-rendro-default
plan: 01
subsystem: testing
tags: [invoice-pdf, rendro, docs, admin, mailer]
requires: []
provides:
  - "Invoice-facing proof lanes now configure the invoice renderer seam explicitly"
  - "Installer and guide wording distinguishes invoice rendering from the legacy HTML-to-PDF seam"
affects: [phase-106-plan-02, invoice-renderer, docs-contracts]
tech-stack:
  added: []
  patterns: [invoice-renderer-seam, facade-first-proof]
key-files:
  created: []
  modified:
    - accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue/test/accrue/billing/pdf_test.exs
    - accrue/guides/configuration.md
    - accrue/guides/testing.md
    - accrue/test/mix/tasks/accrue_install_uat_test.exs
key-decisions:
  - "Invoice proof lanes should configure `:invoice_pdf_adapter` and leave `:pdf_adapter` for explicit HTML-to-PDF tests only."
  - "Contract docs should describe `Accrue.InvoiceRenderer` as the invoice seam without widening into Phase 108 migration prose."
patterns-established:
  - "Admin, mailer, and billing proof stays routed through `Accrue.Billing.render_invoice_pdf/2` instead of bespoke render shortcuts."
requirements-completed: [PDF-01, PDF-02, PDF-03, PDF-05]
duration: 1 run
completed: 2026-05-06
---

# Phase 106 Plan 01 Summary

**Invoice proof lanes and contract docs now point at the invoice renderer seam instead of the legacy HTML `Accrue.PDF` mental model.**

## Performance

- **Duration:** 1 run
- **Started:** 2026-05-06T15:00:00Z
- **Completed:** 2026-05-06T15:19:47Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Switched admin and mailer proof setup from `:pdf_adapter` to `:invoice_pdf_adapter` with `Accrue.InvoiceRenderer.Test`.
- Aligned billing PDF tests and install-UAT expectations with the invoice renderer seam.
- Tightened `guides/configuration.md` and `guides/testing.md` so invoice rendering and the lower-level HTML seam are described separately.

## Task Commits

No atomic task commits were created in this execution. The workspace already contained in-progress Phase 106 changes, so this run completed in-place against the dirty tree and verified the result with targeted tests instead of the usual per-task commit protocol.

## Files Created/Modified

- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` - mailer attachment proof now configures the invoice renderer seam directly.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - admin open/download proof now uses `:invoice_pdf_adapter`.
- `accrue/test/accrue/billing/pdf_test.exs` - facade-level billing proof now documents and asserts invoice-renderer behavior.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - generated host expectations now mention `Accrue.InvoiceRenderer.Test`.
- `accrue/guides/configuration.md` - adapter docs now distinguish invoice rendering from the legacy HTML seam.
- `accrue/guides/testing.md` - test helper docs now describe `setup_pdf_test/1` correctly.

## Decisions Made

- Preserved the existing `assert_pdf_rendered/1` helper for explicit `Accrue.PDF.Test` use while moving invoice-renderer setup and proof to `Accrue.InvoiceRenderer.Test`.
- Kept all proof lanes on the existing billing/admin/mailer public seams rather than introducing any direct renderer shortcuts.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan’s recorded `mix test -x` commands are stale for this Mix version; verification was rerun successfully with the same file targets under `--trace`.
- The local `gsd-sdk query ...` runtime expected by the workflow is not available in this workspace, so execution artifacts were produced directly from phase files on disk.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 106 Plan 02 can now rely on proof lanes that actually exercise the invoice renderer seam.
- The remaining work is renderer-parity hardening and phase closeout evidence, not more contract-surface cleanup.

## Self-Check

PASSED

- Targeted contract/proof files now reference `:invoice_pdf_adapter` for invoice rendering.
- `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs test/accrue/config_test.exs test/mix/tasks/accrue_install_uat_test.exs --trace` passed during this execution.
- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs --trace` passed during this execution.
