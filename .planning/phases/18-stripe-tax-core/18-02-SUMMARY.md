---
phase: 18-stripe-tax-core
plan: 02
subsystem: payments
tags: [stripe-tax, fake-processor, lattice-stripe, exunit]
requires:
  - phase: 17-milestone-closure-cleanup
    provides: planning baseline for v1.3 execution
provides:
  - Stripe adapter passthrough coverage for automatic tax request intent
  - Deterministic Fake automatic-tax payloads for subscriptions, invoices, and checkout sessions
  - Adapter-level parity tests for enabled and disabled automatic-tax states
affects: [18-01, 18-03, 18-04, TAX-01]
tech-stack:
  added: []
  patterns: [adapter passthrough assertions, fake payload parity]
key-files:
  created: [.planning/phases/18-stripe-tax-core/18-02-SUMMARY.md]
  modified:
    - accrue/lib/accrue/processor/fake.ex
    - accrue/test/accrue/processor/fake_test.exs
    - accrue/test/accrue/processor/stripe_test.exs
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - "Kept Stripe production code unchanged and locked automatic-tax passthrough with adapter-source assertions."
  - "Added deterministic Fake tax payload fields without changing existing invoice amount_due semantics."
patterns-established:
  - "Processor parity: Stripe forwards normalized automatic_tax intent unchanged while Fake returns the same observable keys."
  - "Fake tax state is derived only from automatic_tax.enabled, never from caller-supplied tax totals."
requirements-completed: [TAX-01]
duration: 17 min
completed: 2026-04-17
---

# Phase 18 Plan 02: Stripe and Fake Automatic Tax Parity Summary

**Stripe passthrough coverage plus deterministic Fake automatic-tax payloads for subscription, invoice, and checkout processor flows**

## Performance

- **Duration:** 17 min
- **Started:** 2026-04-17T16:46:00Z
- **Completed:** 2026-04-17T17:03:13Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added Stripe adapter tests that lock automatic-tax passthrough to `stringify_keys(params)` for subscription and checkout creation.
- Extended the Fake processor to emit deterministic `automatic_tax`, `tax`, and `total_details.amount_tax` fields for tax-enabled and tax-disabled flows.
- Verified adapter parity with focused ExUnit coverage and a combined Stripe/Fake processor test run.

## Task Commits

Each task was committed atomically:

1. **Task 1: Preserve automatic-tax intent inside the Stripe adapter** - `8bdc6f7` (test)
2. **Task 2: Add deterministic Fake tax payloads for subscription, invoice, and checkout flows** - `4fcb736` (feat)

## Files Created/Modified
- `.planning/phases/18-stripe-tax-core/18-02-SUMMARY.md` - Plan execution summary and verification record.
- `accrue/test/accrue/processor/stripe_test.exs` - Adapter passthrough coverage for `automatic_tax`.
- `accrue/lib/accrue/processor/fake.ex` - Deterministic Fake automatic-tax and tax-amount payload fields.
- `accrue/test/accrue/processor/fake_test.exs` - Enabled and disabled Fake tax parity assertions.
- `.planning/STATE.md` - Updated execution position for plan 18-02 completion.
- `.planning/ROADMAP.md` - Marked Phase 18 as in progress with 1 of 4 plans complete.

## Decisions Made
- Used the existing Stripe adapter inspection style in tests instead of adding a new HTTP mocking layer.
- Kept Fake invoice `amount_due` unchanged and layered tax observability fields beside it to avoid unrelated invoice regressions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18-02 is complete and verified. Phase 18 remains in progress pending plans 18-01, 18-03, and 18-04 to finish TAX-01 end to end.

## Verification

- `cd accrue && mix test test/accrue/processor/stripe_test.exs`
- `cd accrue && mix test test/accrue/processor/fake_test.exs`
- `cd accrue && mix test test/accrue/processor/stripe_test.exs test/accrue/processor/fake_test.exs`

## Self-Check: PASSED

- Found `.planning/phases/18-stripe-tax-core/18-02-SUMMARY.md`
- Found commit `8bdc6f7`
- Found commit `4fcb736`
