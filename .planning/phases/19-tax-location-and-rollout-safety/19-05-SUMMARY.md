---
phase: 19-tax-location-and-rollout-safety
plan: 05
subsystem: docs
tags: [stripe-tax, docs, troubleshooting, live-stripe, exunit]
requires:
  - phase: 19-02
    provides: public customer tax-location repair through `Accrue.Billing.update_customer_tax_location/2`
  - phase: 19-03
    provides: local recurring invalid-location and finalization-failure terminology
provides:
  - Troubleshooting guidance for stable invalid-location recovery using public Accrue contracts
  - Live Stripe parity guidance for safe tax-location checks and rollout warnings
  - Focused doc tests that lock recurring rollout and Checkout existing-customer caveats
affects: [20, TAX-04, guides, docs-tests]
tech-stack:
  added: []
  patterns: [grep-like doc assertions, stable rollout warning language, PII-safe provider-parity guidance]
key-files:
  created:
    - .planning/phases/19-tax-location-and-rollout-safety/19-05-SUMMARY.md
    - accrue/test/accrue/docs/tax_rollout_docs_test.exs
  modified:
    - accrue/guides/troubleshooting.md
    - guides/testing-live-stripe.md
    - accrue/test/accrue/docs/troubleshooting_guide_test.exs
key-decisions:
  - "Invalid tax-location recovery guidance stays anchored to stable Accrue errors and local recurring-state names, not copied Stripe payloads."
  - "Rollout warnings explicitly call out existing subscriptions, invoices, payment links, and Checkout existing-customer update flags so TAX-04 cannot drift into vague migration advice."
patterns-established:
  - "Operator-facing tax docs should reference public Accrue repair paths first and keep address or provider payload PII out of logs and support notes."
  - "Docs regressions for rollout warnings should use fast string assertions instead of live Stripe or browser dependencies."
requirements-completed: [TAX-04]
duration: 4 min
completed: 2026-04-17
---

# Phase 19 Plan 05: Rollout Safety Docs Summary

**Troubleshooting and live Stripe guides now spell out stable invalid-location recovery, non-retroactive Stripe Tax rollout rules, and the literal Checkout existing-customer update flags required for safe migration**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-17T18:33:02Z
- **Completed:** 2026-04-17T18:37:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added operator-facing troubleshooting guidance for `customer_tax_location_invalid`, recurring disabled-reason states, and the supported recovery order through Accrue.
- Added live Stripe provider-parity guidance that exercises valid and invalid placeholder locations without copying customer data or provider payloads into notes.
- Added focused doc tests that lock TAX-04 rollout wording and the literal Checkout flags `customer_update[address]=auto` and `customer_update[shipping]=auto`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write rollout and recovery guidance in the existing guides** - `d052472` (docs)
2. **Task 2: Lock the Phase 19 guide language with doc tests** - `1a79d64` (test)

## Files Created/Modified
- `accrue/guides/troubleshooting.md` - Adds stable invalid-location recovery guidance, recurring-state explanations, and the live parity guide reference.
- `guides/testing-live-stripe.md` - Adds safe Stripe test-mode tax-location parity checks and rollout warnings for existing recurring objects and Checkout customers.
- `accrue/test/accrue/docs/troubleshooting_guide_test.exs` - Extends the troubleshooting guide contract with rollout and recovery assertions.
- `accrue/test/accrue/docs/tax_rollout_docs_test.exs` - Adds focused string assertions for the live guide warnings and troubleshooting-path reference.

## Decisions Made
- Kept recovery copy on stable public Accrue terminology instead of instructing operators to inspect raw Stripe errors or dashboard payloads.
- Locked the TAX-04 warnings with literal string assertions so future doc edits cannot soften the migration caveats.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `gsd-sdk query` was not available in this shell, so planning state updates were applied directly in the checked-in `.planning` files instead of through the helper commands.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 19 is complete: customer tax-location validation, invalid-location recovery visibility, host/admin proof, and rollout guidance are now all shipped.
- Phase 20 can build on the completed tax contract and move into organization billing without reopening Stripe Tax migration semantics.

## Self-Check: PASSED

- Found `.planning/phases/19-tax-location-and-rollout-safety/19-05-SUMMARY.md`
- Found commit `d052472`
- Found commit `1a79d64`
