---
phase: 19-tax-location-and-rollout-safety
plan: 01
subsystem: payments
tags: [stripe-tax, fake-processor, error-mapping, exunit]
requires:
  - phase: 18-03
    provides: narrow automatic-tax projection fields for subscription and invoice rows
provides:
  - Stable Stripe `customer_tax_location_invalid` mapping with sanitized metadata
  - Processor test coverage for nested customer tax-location update params
  - Deterministic Fake invalid-location behavior for immediate validation and recurring automatic-tax rollback
affects: [19-02, 19-03, TAX-02, TAX-03]
tech-stack:
  added: []
  patterns: [sanitized processor error mapping, deterministic fake tax-location failure helpers]
key-files:
  created:
    - .planning/phases/19-tax-location-and-rollout-safety/19-01-SUMMARY.md
  modified:
    - accrue/lib/accrue/processor/stripe/error_mapper.ex
    - accrue/test/accrue/processor/stripe_test.exs
    - accrue/lib/accrue/processor/fake.ex
    - accrue/test/accrue/processor/fake_test.exs
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - "Mapped Stripe `customer_tax_location_invalid` to a stable `%Accrue.APIError{}` with a narrow `processor_error` map containing only request id, status, type, and code."
  - "Kept Fake tax-location rules intentionally small: immediate validation requires line1, postal_code, and country, and recurring automatic-tax rollback derives from the stored customer location instead of fake jurisdiction logic."
patterns-established:
  - "Processor error mapping may keep raw provider errors for general failures, but tax-location validation must sanitize `processor_error` before it crosses the public API boundary."
  - "Fake tax rollout failures should be produced from stored customer state and explicit helper payloads, not scripted one-off Stripe-like blobs."
requirements-completed: [TAX-02]
duration: 10 min
completed: 2026-04-17
---

# Phase 19 Plan 01: Tax Location and Rollout Safety Summary

**Stable tax-location validation errors for Stripe customer updates plus deterministic Fake rollback payloads for invalid recurring tax state**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-17T17:58:00Z
- **Completed:** 2026-04-17T18:08:19Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added a dedicated Stripe error-mapper branch for `customer_tax_location_invalid` that returns stable repair guidance and strips raw provider payloads down to safe metadata.
- Locked the Stripe adapter contract with tests covering nested `address`, `shipping`, and `tax.validate_location` customer update params.
- Extended the Fake processor to fail immediate invalid tax-location updates deterministically and emit recurring `disabled_reason` plus `last_finalization_error.code` payloads for later projection and webhook work.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Stripe-side tax-location validation and safe error mapping** - `50ad8d2` (feat)
2. **Task 2: Make Fake deterministic for invalid tax-location cases** - `2cd27d8` (feat)

## Files Created/Modified
- `.planning/phases/19-tax-location-and-rollout-safety/19-01-SUMMARY.md` - Plan execution summary and verification record.
- `accrue/lib/accrue/processor/stripe/error_mapper.ex` - Stable sanitized mapping for `customer_tax_location_invalid`.
- `accrue/test/accrue/processor/stripe_test.exs` - Coverage for nested tax-location request params and sanitized Stripe error mapping.
- `accrue/lib/accrue/processor/fake.ex` - Deterministic invalid tax-location validation and recurring automatic-tax rollback helpers.
- `accrue/test/accrue/processor/fake_test.exs` - Coverage for request-time invalid location errors and recurring disabled-reason payloads.
- `.planning/STATE.md` - Advanced the phase state to the next executable plan.
- `.planning/ROADMAP.md` - Marked plan `19-01` complete and Phase 19 as in progress.

## Decisions Made
- Used an actionable fixed Accrue error message for invalid tax locations instead of surfacing Stripe’s raw text, because TAX-02 requires a stable public repair contract.
- Returned Fake recurring rollback state through `automatic_tax.status`, `automatic_tax.disabled_reason`, and `last_finalization_error.code` so later Phase 19 plans can project and reconcile those fields without ad hoc test scripting.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The processor contract for tax-location validation is now locked on both Stripe and Fake. Phase `19-02` can add the public billing facade path on top of a stable sanitized adapter surface.

## Verification

- `cd accrue && mix test test/accrue/processor/stripe_test.exs`
- `cd accrue && mix test test/accrue/processor/fake_test.exs`
- `cd accrue && mix test test/accrue/processor/stripe_test.exs test/accrue/processor/fake_test.exs`

## Self-Check: PASSED

- Found `.planning/phases/19-tax-location-and-rollout-safety/19-01-SUMMARY.md`
- Found commit `50ad8d2`
- Found commit `2cd27d8`
