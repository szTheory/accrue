---
phase: 90-full-template-port-cleanup
plan: 01
subsystem: email
tags: [mailglass, heex, templates, email]

# Dependency graph
requires:
  - phase: 89-proof-of-concept-templates-pipeline
    provides: Mailglass mailable pattern proven on Receipt and PaymentFailed
provides:
  - Six Mailglass-backed transactional email modules (trial, cancel, pause, resume, card-expiry)
  - Parity tests asserting adopter-visible content over byte-for-byte HTML
affects: [phase-90-02, phase-90-03, email templates, test fixtures]

# Tech tracking
tech-stack:
  added: []
  patterns: [mailglass-mailable-heex, parity-first template tests, deterministic fixtures]

key-files:
  created: []
  modified:
    - accrue/lib/accrue/emails/trial_ending.ex
    - accrue/lib/accrue/emails/trial_ended.ex
    - accrue/lib/accrue/emails/subscription_canceled.ex
    - accrue/lib/accrue/emails/subscription_paused.ex
    - accrue/lib/accrue/emails/subscription_resumed.ex
    - accrue/lib/accrue/emails/card_expiring_soon.ex
    - accrue/test/accrue/emails/trial_ending_test.exs
    - accrue/test/accrue/emails/trial_ended_test.exs
    - accrue/test/accrue/emails/subscription_canceled_test.exs

key-decisions:
  - "Use the same Mailglass HEEx pattern proven by Receipt and PaymentFailed in Phase 89."
  - "Assert adopter-visible content and structure rather than raw HTML equality (D-07/D-08)."
  - "Keep templates fixture-driven; do not introduce new helper modules or runtime deps."

patterns-established:
  - "Pattern 1: bulk-port mailers in cohesive batches (trial group, lifecycle group) so parity coverage moves together."

requirements-completed: [MG-07]

# Metrics
duration: ~1h
completed: 2026-04-26
---

# Phase 90 Plan 01: Port first six remaining MJML templates to Mailglass

**Six lifecycle and trial emails now render through Mailglass HEEx with parity tests preserving adopter-visible behavior.**

## Performance

- **Duration:** ~1h
- **Completed:** 2026-04-26
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Ported `trial_ending`, `trial_ended`, and `subscription_canceled` to Mailglass mailables.
- Ported `subscription_paused`, `subscription_resumed`, and `card_expiring_soon` to Mailglass mailables.
- Updated parity tests to assert subject, body content, and CTA semantics without locking byte-for-byte HTML.

## Task Commits

1. **Task 1: Port trial and cancellation templates** — `2cc6e0b` (combined commit)
2. **Task 2: Port pause, resume, and card-expiry templates** — `2cc6e0b` (combined commit)

**Plan metadata:** `2cc6e0b` (feat(90-01): port first mail templates to Mailglass)

## Files Created/Modified
- `accrue/lib/accrue/emails/trial_ending.ex` — Mailglass-backed trial-ending mailable.
- `accrue/lib/accrue/emails/trial_ended.ex` — Mailglass-backed trial-ended mailable.
- `accrue/lib/accrue/emails/subscription_canceled.ex` — Mailglass-backed cancellation mailable.
- `accrue/lib/accrue/emails/subscription_paused.ex` — Mailglass-backed pause mailable.
- `accrue/lib/accrue/emails/subscription_resumed.ex` — Mailglass-backed resume mailable.
- `accrue/lib/accrue/emails/card_expiring_soon.ex` — Mailglass-backed card-expiry mailable.
- `accrue/test/accrue/emails/trial_ending_test.exs` — parity coverage refresh.
- `accrue/test/accrue/emails/trial_ended_test.exs` — parity coverage refresh.
- `accrue/test/accrue/emails/subscription_canceled_test.exs` — parity coverage refresh.

## Decisions Made
- Reuse the Phase 89 Mailglass HEEx pattern unchanged.
- Assert structure and content over byte-equal HTML.
- Keep fixture-driven rendering — no new helpers introduced.

## Deviations from Plan
None.

## Issues Encountered
None.

## Next Plan Readiness
- Invoice, refund, and coupon mailers are the next batch (Plan 02).
- Cleanup of MJML assets and dependencies is gated on Plan 03 after every mailer is ported.

## Self-Check: PASSED

---
*Phase: 90-full-template-port-cleanup*
*Completed: 2026-04-26*
