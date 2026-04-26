---
phase: 89-proof-of-concept-templates-pipeline
plan: 01
subsystem: payments
tags: [mailglass, elixir, phoenix, oban, email]

# Dependency graph
requires:
  - phase: 88-mailglass-foundation
    provides: Mailglass repo path/deps, dev mount, and migration groundwork
provides:
  - Mailglass-backed worker seam for charge-driven email dispatch
  - explicit idempotency keys for receipt/payment-failed deliveries
  - receipt PDF attachment handling with hosted-URL fallback
affects: [phase-89-02, phase-90, webhook dispatch, email delivery]

# Tech tracking
tech-stack:
  added: [mailglass]
  patterns: [worker-as-orchestration-seam, explicit idempotency keys, fake-delivery test harness]

key-files:
  created: []
  modified:
    - accrue/lib/accrue/workers/mailer.ex
    - accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs
    - accrue/lib/accrue/emails/receipt.ex
    - accrue/lib/accrue/emails/payment_failed.ex
    - accrue/test/accrue/emails/receipt_test.exs
    - accrue/test/accrue/emails/payment_failed_test.exs
    - accrue/lib/accrue/invoices/styles.ex

key-decisions:
  - "Keep Accrue.Workers.Mailer as the orchestration seam and call Mailglass.deliver/1 from the worker."
  - "Use the explicit idempotency key shape accrue:v1:<type>:<charge_id>."
  - "Receipt can attach a PDF; payment_failed stays attachment-free."

patterns-established:
  - "Pattern 1: hydrate assigns in the worker, then hand a Mailglass message to the delivery layer."
  - "Pattern 2: verify mail behavior through Mailglass fake delivery assertions rather than Swoosh-only expectations."

requirements-completed: [MG-04, MG-05, MG-06]

# Metrics
duration: 1h
completed: 2026-04-26
---

# Phase 89: Proof of Concept Templates & Pipeline Summary

**Webhook-driven billing mail now routes through Mailglass with explicit idempotency and receipt PDF fallback behavior.**

## Performance

- **Duration:** ~1h
- **Started:** 2026-04-26T00:00:00Z
- **Completed:** 2026-04-26T01:05:03Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Moved the worker seam to Mailglass delivery.
- Added explicit charge-based idempotency keys.
- Preserved receipt PDF attachment behavior with hosted URL fallback.

## Task Commits

1. **Task 1: Prove the receipt path through Mailglass** - `66cce2f` (feat)
2. **Task 2: Finish the payment_failed branch and remove Oban uniqueness** - `66cce2f` (feat, combined commit)

**Plan metadata:** `66cce2f` (feat: complete Mailglass email pipeline changes)

## Files Created/Modified
- `accrue/lib/accrue/workers/mailer.ex` - Mailglass orchestration, idempotency, PDF attachment handling.
- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` - end-to-end delivery assertions.
- `accrue/lib/accrue/emails/receipt.ex` - Mailglass-backed receipt mailer.
- `accrue/lib/accrue/emails/payment_failed.ex` - Mailglass-backed payment-failed mailer.
- `accrue/test/accrue/emails/receipt_test.exs` - receipt parity coverage.
- `accrue/test/accrue/emails/payment_failed_test.exs` - payment_failed parity coverage.
- `accrue/lib/accrue/invoices/styles.ex` - map support for branded styling lookup.

## Decisions Made
- Keep the worker as the seam and delivery boundary.
- Use explicit idempotency keys keyed by event type and charge id.
- Preserve adopter-visible copy and CTA behavior while switching renderers.

## Deviations from Plan

### Auto-fixed Issues

None.

## Issues Encountered
- Task 1 and Task 2 landed in one combined commit because the worker seam and template ports were tightly coupled in the same uncommitted diff.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 89's first two slices are green and ready for the remaining Mailglass template ports.
- The next work should continue from the Mailglass template migration boundary.

## Self-Check: PASSED

---
*Phase: 89-proof-of-concept-templates-pipeline*
*Completed: 2026-04-26*
