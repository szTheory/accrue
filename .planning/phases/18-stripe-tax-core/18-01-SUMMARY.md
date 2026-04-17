---
phase: 18-stripe-tax-core
plan: 01
subsystem: payments
tags: [stripe-tax, subscriptions, fake-processor, exunit]
requires:
  - phase: 18-02
    provides: Stripe and Fake automatic-tax payload parity for downstream subscription assertions
provides:
  - Public boolean `automatic_tax` support on `Accrue.Billing.subscribe/3`
  - Subscription request normalization that forwards only `automatic_tax.enabled` intent
  - Regression coverage for enabled, disabled, and omitted subscription tax options
affects: [18-03, 18-04, TAX-01]
tech-stack:
  added: []
  patterns: [boolean-only tax boundary normalization, persisted raw payload assertions]
key-files:
  created: [.planning/phases/18-stripe-tax-core/18-01-SUMMARY.md]
  modified:
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/test/accrue/billing/subscription_test.exs
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - "Kept the public subscription tax contract boolean-only and normalized it to `automatic_tax.enabled` inside `SubscriptionActions`."
  - "Used persisted `sub.data` assertions in tests so the coverage locks the observable public contract rather than processor internals."
patterns-established:
  - "Public billing callers pass `automatic_tax: true | false`; nested Stripe tax maps stay internal to processor params."
  - "Subscription tax regressions assert on persisted raw payload keys so Fake-backed coverage survives projection changes."
requirements-completed: []
duration: 2 min
completed: 2026-04-17
---

# Phase 18 Plan 01: Subscription Automatic Tax Boundary Summary

**Boolean-only subscription automatic-tax normalization with Fake-backed persistence tests for enabled, disabled, and legacy calls**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T17:04:00Z
- **Completed:** 2026-04-17T17:06:18Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `automatic_tax: true | false` to the `Accrue.Billing.subscribe/3` boundary without exposing nested Stripe request maps.
- Normalized `automatic_tax` into subscription processor params and stripped the public option from downstream request opts.
- Added focused subscription tests that prove enabled, disabled, and omitted tax options all persist the expected Fake-backed payload.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add `:automatic_tax` to the subscription entry point** - `0eb7c00` (feat)
2. **Task 2: Add subscription tax regression coverage** - `4ab9484` (test)

## Files Created/Modified
- `.planning/phases/18-stripe-tax-core/18-01-SUMMARY.md` - Plan execution summary and verification record.
- `accrue/lib/accrue/billing/subscription_actions.ex` - Subscription tax intent normalization and request opt sanitization.
- `accrue/test/accrue/billing/subscription_test.exs` - Enabled, disabled, and legacy no-tax regression coverage.
- `.planning/STATE.md` - Advanced Phase 18 execution state to the next plan.
- `.planning/ROADMAP.md` - Marked Plan 18-01 complete and updated Phase 18 progress.

## Decisions Made
- Defaulted omitted `:automatic_tax` to `false` so existing subscription callers remain backward-compatible.
- Kept tests at the billing boundary and asserted on persisted raw payload data instead of adding adapter-specific expectations here.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans `18-01` and `18-02` are complete. Phase 18 now moves to `18-03` for automatic-tax observability on subscription and invoice projections.

## Verification

- `cd accrue && mix test test/accrue/billing/subscription_test.exs`

## Self-Check: PASSED

- Found `.planning/phases/18-stripe-tax-core/18-01-SUMMARY.md`
- Found commit `0eb7c00`
- Found commit `4ab9484`
