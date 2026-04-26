---
phase: 90-full-template-port-cleanup
plan: 02
subsystem: email
tags: [mailglass, heex, templates, email, invoices]

# Dependency graph
requires:
  - phase: 89-proof-of-concept-templates-pipeline
    provides: Mailglass mailable pattern proven on Receipt and PaymentFailed
provides:
  - Five Mailglass-backed billing/invoice/coupon email modules
  - Parity tests preserving invoice-bearing subject/body semantics
affects: [phase-90-03, email templates, test fixtures]

# Tech tracking
tech-stack:
  added: []
  patterns: [mailglass-mailable-heex, parity-first template tests, deterministic fixtures]

key-files:
  created: []
  modified:
    - accrue/lib/accrue/emails/invoice_finalized.ex
    - accrue/lib/accrue/emails/invoice_paid.ex
    - accrue/lib/accrue/emails/invoice_payment_failed.ex
    - accrue/lib/accrue/emails/refund_issued.ex
    - accrue/lib/accrue/emails/coupon_applied.ex
    - accrue/test/accrue/emails/invoice_finalized_test.exs
    - accrue/test/accrue/emails/invoice_paid_test.exs
    - accrue/test/accrue/emails/invoice_payment_failed_test.exs
    - accrue/test/accrue/emails/refund_issued_test.exs
    - accrue/test/accrue/emails/coupon_applied_test.exs

key-decisions:
  - "Port invoice/refund/coupon mailers using the same Mailglass HEEx pattern as the lifecycle batch."
  - "Preserve invoice fee breakdown and ordering semantics; assert structure and content over raw HTML equality (D-07/D-08)."
  - "Keep fixture-driven test contracts intact for the broad coverage sweep."

patterns-established:
  - "Pattern 1: invoice-heavy mailers retain fixture-driven assertions on amounts, lines, and CTA structure across the renderer swap."

requirements-completed: [MG-07]

# Metrics
duration: ~1h
completed: 2026-04-26
---

# Phase 90 Plan 02: Port invoice and discount mailers to Mailglass

**The five remaining billing-surface emails (invoice/refund/coupon) now render through Mailglass HEEx with parity tests preserving invoice-bearing semantics.**

## Performance

- **Duration:** ~1h
- **Completed:** 2026-04-26
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Ported `invoice_finalized`, `invoice_paid`, and `invoice_payment_failed` to Mailglass mailables.
- Ported `refund_issued` and `coupon_applied` to Mailglass mailables.
- Refreshed parity tests to verify invoice fee/line content and refund/coupon copy without byte-equal HTML.

## Task Commits

1. **Task 1: Port invoice templates** — `38e130f` (combined commit)
2. **Task 2: Port refund and coupon templates** — `38e130f` (combined commit)

**Plan metadata:** `38e130f` (feat(90-02): port invoice and discount mailers to Mailglass)

## Files Created/Modified
- `accrue/lib/accrue/emails/invoice_finalized.ex` — Mailglass-backed invoice-finalized mailable.
- `accrue/lib/accrue/emails/invoice_paid.ex` — Mailglass-backed invoice-paid mailable.
- `accrue/lib/accrue/emails/invoice_payment_failed.ex` — Mailglass-backed invoice-payment-failed mailable.
- `accrue/lib/accrue/emails/refund_issued.ex` — Mailglass-backed refund-issued mailable.
- `accrue/lib/accrue/emails/coupon_applied.ex` — Mailglass-backed coupon-applied mailable.
- `accrue/test/accrue/emails/invoice_finalized_test.exs` — parity coverage refresh.
- `accrue/test/accrue/emails/invoice_paid_test.exs` — parity coverage refresh.
- `accrue/test/accrue/emails/invoice_payment_failed_test.exs` — parity coverage refresh.
- `accrue/test/accrue/emails/refund_issued_test.exs` — parity coverage refresh.
- `accrue/test/accrue/emails/coupon_applied_test.exs` — parity coverage refresh.

## Decisions Made
- Use the same Mailglass HEEx pattern as the lifecycle batch (Plan 01).
- Preserve invoice fee breakdown and adopter-visible ordering.
- Keep deterministic fixture data as the render baseline.

## Deviations from Plan
None.

## Issues Encountered
None.

## Next Plan Readiness
- All transactional templates other than `payment_succeeded` are now Mailglass-backed.
- Plan 03 can safely retire the MJML compiler dependency, the `mix accrue.mail.preview` task, and the legacy template assets.

## Self-Check: PASSED

---
*Phase: 90-full-template-port-cleanup*
*Completed: 2026-04-26*
