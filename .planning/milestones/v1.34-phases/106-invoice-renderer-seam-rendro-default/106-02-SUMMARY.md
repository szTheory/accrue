---
phase: 106-invoice-renderer-seam-rendro-default
plan: 02
subsystem: payments
tags: [invoice-pdf, rendro, parity, native-renderer]
requires:
  - phase: 106-invoice-renderer-seam-rendro-default
    provides: "Invoice-facing proof lanes and docs aligned to the invoice renderer seam"
provides:
  - "Rendro remains the default invoice renderer for the primary invoice path"
  - "Facade and downstream proof now verify semantic invoice content, not only PDF bytes"
affects: [phase-107, invoice-renderer, pdf-proof]
tech-stack:
  added: []
  patterns: [semantic-renderer-proof, chrome-free-default]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/invoice_renderer/rendro.ex
    - accrue/lib/accrue/invoices.ex
    - accrue/test/accrue/billing/pdf_test.exs
    - accrue/test/accrue/config_test.exs
key-decisions:
  - "Keep `Accrue.Invoices.render_invoice_pdf/2` unchanged while pushing deterministic structure into the Rendro renderer internals."
  - "Prove invoice semantics through render context and adapter-focused tests rather than byte-for-byte PDF comparisons."
patterns-established:
  - "Default invoice-renderer proof should assert totals, customer/header/footer semantics, and downstream lane stability together."
requirements-completed: [PDF-03, PDF-04, PDF-05]
duration: 1 run
completed: 2026-05-06
---

# Phase 106 Plan 02 Summary

**The Rendro-backed invoice path is now the proven default: Chrome-free by configuration and validated for invoice semantics across facade, mailer, and admin lanes.**

## Performance

- **Duration:** 1 run
- **Started:** 2026-05-06T15:00:00Z
- **Completed:** 2026-05-06T15:19:47Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Confirmed `Accrue.InvoiceRenderer.Rendro` is the configured default and returns a real PDF binary without Chrome in the normal invoice path.
- Preserved the lazy `render/store/fetch_invoice_pdf` facade contract while moving invoice rendering off the legacy `Accrue.PDF` path.
- Revalidated downstream admin and mailer lanes after the seam cleanup so the strengthened default path remains stable.

## Task Commits

No atomic task commits were created in this execution. The core Phase 106 renderer work was already present in the workspace; this run verified it, repaired contract drift around it, and documented the outcome without rebasing the existing dirty tree into task-by-task commits.

## Files Created/Modified

- `accrue/lib/accrue/invoice_renderer/rendro.ex` - deterministic native renderer for invoice header/body/footer sections.
- `accrue/lib/accrue/invoices.ex` - invoice facade now resolves through `Accrue.InvoiceRenderer` while preserving lazy semantics.
- `accrue/test/accrue/billing/pdf_test.exs` - facade proof covers the invoice renderer seam and the Rendro default lane.
- `accrue/test/accrue/config_test.exs` - config defaults remained green with the new invoice adapter key.

## Decisions Made

- Left the public billing facade unchanged and treated proof quality as the main completion gate for this plan.
- Used semantic assertions around render context and downstream lane success instead of trying to lock binary PDF output.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Phase 106 entered this run with pre-existing code changes already in the tree; execution here focused on validation and contract repair rather than rebuilding the implementation from scratch.
- The workflow runtime’s `gsd-sdk query` entry points were unavailable locally, so summaries and verification were written manually after successful test evidence.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 107 can focus on the explicit Chromic fallback path and published Rendro dependency handoff.
- Phase 108 can build docs/migration proof on top of a default invoice lane that is already green in billing, mailer, and admin tests.

## Self-Check

PASSED

- `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs test/accrue/invoice_renderer/rendro_test.exs test/accrue/config_test.exs test/mix/tasks/accrue_install_uat_test.exs --trace` passed during this execution.
- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs --trace` passed during this execution.
- The default invoice adapter in `accrue/config/config.exs` remains `Accrue.InvoiceRenderer.Rendro`.
