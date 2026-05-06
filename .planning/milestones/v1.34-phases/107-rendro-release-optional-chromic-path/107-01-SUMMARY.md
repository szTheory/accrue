---
phase: 107-rendro-release-optional-chromic-path
plan: 01
subsystem: payments
tags: [invoice-pdf, chromicpdf, telemetry, boot-warnings]
requires:
  - phase: 106-invoice-renderer-seam-rendro-default
    provides: "The Rendro-first invoice renderer seam and invoice-facing adapter split"
provides:
  - "Typed invoice-renderer unavailability contract for the explicit Chromic compatibility path"
  - "Boot warning coverage for explicit Chromic opt-in and legacy HTML-seam migration drift"
  - "Invoice-path-wide unavailable telemetry emitted from the invoice facade"
affects: [phase-108, invoice-renderer, telemetry, docs]
tech-stack:
  added: []
  patterns: [typed-terminal-renderer-errors, invoice-path-ops-telemetry, migration-warning-guards]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/errors.ex
    - accrue/lib/accrue/invoices.ex
    - accrue/lib/accrue/application.ex
    - accrue/lib/accrue/workers/mailer.ex
    - accrue/test/accrue/billing/pdf_test.exs
    - accrue/test/accrue/application_boot_guards_test.exs
    - accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs
    - accrue/guides/pdf.md
    - accrue/guides/configuration.md
    - accrue/guides/telemetry.md
    - accrue/lib/accrue/telemetry/metrics.ex
key-decisions:
  - "Emit `[:accrue, :ops, :pdf_adapter_unavailable]` from `Accrue.Invoices` so the signal covers the whole invoice path instead of only the mailer fallback branch."
  - "Treat explicit Chromic misconfiguration as a typed terminal error and degrade to the hosted invoice URL without retries."
  - "Warn only for legacy `:pdf_adapter` drift when `:invoice_pdf_adapter` is unset and the HTML seam is explicitly non-default, avoiding noise for normal Rendro installs."
patterns-established:
  - "Invoice-facing compatibility errors should be host-matchable structs, not bare atoms."
  - "Low-cardinality invoice-path ops telemetry should carry adapter/surface metadata through `Accrue.Telemetry.Ops.emit/3`."
requirements-completed: [PDF-06]
duration: 1 run
completed: 2026-05-06
---

# Phase 107 Plan 01 Summary

**The optional Chromic invoice path is now explicit, typed, and observable: hosts get migration-safe warnings, a stable `%Accrue.Error.InvoiceRendererUnavailable{}` contract, and invoice-path-wide unavailable telemetry.**

## Performance

- **Duration:** 1 run
- **Started:** 2026-05-06T16:00:00Z
- **Completed:** 2026-05-06T16:19:47Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Replaced the invoice facade’s bare `:chromic_pdf_not_started` result with `%Accrue.Error.InvoiceRendererUnavailable{adapter: Accrue.InvoiceRenderer.ChromicPDF, reason: :chromic_pdf_not_started}`.
- Added boot-warning coverage for the explicit Chromic invoice adapter and the legacy `:pdf_adapter` migration-drift case without reintroducing implicit invoice-renderer inference.
- Moved the unavailable ops signal to the invoice facade and updated the mailer fallback path plus public docs to match the typed compatibility contract.

## Task Commits

No atomic task commits were created in this execution. The workspace already contained in-flight milestone changes, so this run finished the Phase 107 contract work and verified it without trying to re-slice the dirty tree into task-level commits.

## Files Created/Modified

- `accrue/lib/accrue/errors.ex` - added `Accrue.Error.InvoiceRendererUnavailable` and updated render-failure docs.
- `accrue/lib/accrue/invoices.ex` - emits typed explicit-Chromic failures and invoice-path unavailable telemetry.
- `accrue/lib/accrue/application.ex` - separates explicit Chromic boot warnings from legacy `:pdf_adapter` migration drift.
- `accrue/lib/accrue/workers/mailer.ex` - degrades on the typed renderer-unavailable error instead of the old atom branch.
- `accrue/test/accrue/billing/pdf_test.exs` - asserts the new typed contract.
- `accrue/test/accrue/application_boot_guards_test.exs` - aligns warning tests with `:invoice_pdf_adapter` and the explicit Chromic path.
- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` - keeps mailer-path proof on the new invoice renderer seam.
- `accrue/guides/pdf.md` - documents the explicit compatibility path and typed unavailable error.
- `accrue/guides/configuration.md` - clarifies that `:invoice_pdf_adapter` is the invoice switch and `:pdf_adapter` is the lower-level HTML seam.
- `accrue/guides/telemetry.md` - updates the unavailable event owner and metadata contract.
- `accrue/lib/accrue/telemetry/metrics.ex` - tags the unavailable counter by `:adapter` and `:surface`.

## Decisions Made

- Preserved the existing `[:accrue, :ops, :pdf_adapter_unavailable]` event name for compatibility and only changed its owner/metadata semantics.
- Kept the migration warning heuristic narrow so normal Rendro installs do not get noisy boot-time warnings from the package-default HTML seam.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `gsd-sdk query` entry points were unavailable in this runtime, so the phase execution flow and summaries were completed manually from local artifacts and verification evidence.
- The worktree already contained unrelated milestone changes, so execution had to preserve in-place edits rather than relying on clean task-by-task commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The explicit Chromic compatibility contract is stable enough for Phase 108’s broader migration/docs closeout.
- Release proof can now focus on the published Rendro dependency and final doc sweep without reopening invoice error semantics.

## Self-Check

PASSED

- `cd accrue && mix test test/accrue/billing/pdf_test.exs --trace` passed.
- `cd accrue && mix test test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs --trace` passed.
- `rg -n "explicit compatibility path|InvoiceRendererUnavailable|invoice_pdf_adapter|pdf_adapter|pdf_adapter_unavailable" accrue/guides/pdf.md accrue/guides/configuration.md accrue/guides/telemetry.md` matched the expected docs contract.
