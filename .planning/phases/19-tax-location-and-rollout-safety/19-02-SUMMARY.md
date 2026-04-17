---
phase: 19-tax-location-and-rollout-safety
plan: 02
subsystem: payments
tags: [stripe-tax, billing, customer, exunit]
requires:
  - phase: 19-01
    provides: sanitized `customer_tax_location_invalid` processor behavior across Stripe and Fake
provides:
  - Public `Accrue.Billing.update_customer_tax_location/2` and `!/2` facade functions
  - Sanitized local customer persistence for processor-backed tax-location updates
  - Focused TAX-02 billing coverage for update success and invalid-location failures
affects: [19-04, TAX-02, billing, automatic-tax]
tech-stack:
  added: []
  patterns: [sanitized customer projection persistence, billing-level automatic-tax invalid-location guard]
key-files:
  created:
    - .planning/phases/19-tax-location-and-rollout-safety/19-02-SUMMARY.md
    - accrue/test/accrue/billing/tax_location_test.exs
  modified:
    - accrue/lib/accrue/billing.ex
    - accrue/lib/accrue/billing/subscription_actions.ex
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Kept `update_customer/2` local-only and introduced a new public tax-location facade so existing customer maintenance semantics do not change."
  - "Sanitized persisted customer projection data by stripping address, shipping, phone, and tax payloads before writing `customer.data` or recording the tax-location event."
patterns-established:
  - "Processor-backed customer tax-location writes must emit billing telemetry at the facade and persist only a sanitized local projection."
  - "Tax-enabled subscription creation must convert `requires_location_inputs` automatic-tax payloads into a stable `customer_tax_location_invalid` Accrue error instead of persisting a silently-disabled tax state."
requirements-completed: [TAX-02]
duration: 6 min
completed: 2026-04-17
---

# Phase 19 Plan 02: Tax Location and Rollout Safety Summary

**Public customer tax-location updates with immediate validation, sanitized local customer persistence, and focused TAX-02 billing proofs**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-17T18:14:00Z
- **Completed:** 2026-04-17T18:19:46Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added `Accrue.Billing.update_customer_tax_location/2` and `update_customer_tax_location!/2` as explicit processor-backed public APIs.
- Persisted only a sanitized local customer projection and emitted a dedicated `customer.tax_location_updated` event without raw address, shipping, phone, or tax payloads.
- Added focused billing coverage proving the successful update path, the stable invalid-location error, and the tax-enabled subscribe failure path.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the public customer tax-location billing API** - `f87de8c` (feat)
2. **Task 2: Prove TAX-02 through focused billing tests** - `0bf065c` (test)

## Files Created/Modified
- `accrue/lib/accrue/billing.ex` - Public tax-location update facade, sanitized projection helpers, and dedicated tax-location event recording.
- `accrue/lib/accrue/billing/subscription_actions.ex` - Guard that turns invalid automatic-tax subscription payloads into a stable public API error.
- `accrue/test/accrue/billing/tax_location_test.exs` - Focused TAX-02 coverage for sanitized updates and invalid-location failure paths.
- `.planning/phases/19-tax-location-and-rollout-safety/19-02-SUMMARY.md` - Plan execution summary and verification record.
- `.planning/STATE.md` - Advanced execution state to the next incomplete Phase 19 plan.
- `.planning/ROADMAP.md` - Marked `19-02` complete and updated Phase 19 progress.
- `.planning/REQUIREMENTS.md` - Marked `TAX-02` complete.

## Decisions Made
- Kept the old `update_customer/2` path local-only and introduced a dedicated public facade for processor-backed tax-location validation.
- Normalized the public subscribe failure at the billing boundary so invalid automatic-tax location state cannot quietly persist as a disabled-tax subscription.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Tax-enabled subscribe still succeeded with disabled automatic tax**
- **Found during:** Task 2 (Prove TAX-02 through focused billing tests)
- **Issue:** Fake-backed `Billing.subscribe/3` returned a successful subscription carrying `automatic_tax.status = "requires_location_inputs"` instead of surfacing the actionable invalid-location error required by TAX-02.
- **Fix:** Added a billing-level guard in `SubscriptionActions.subscribe/3` that maps invalid automatic-tax payloads to `%Accrue.APIError{code: "customer_tax_location_invalid"}` before local persistence.
- **Files modified:** `accrue/lib/accrue/billing/subscription_actions.ex`
- **Verification:** `cd accrue && mix test test/accrue/billing/tax_location_test.exs`
- **Committed in:** `f87de8c` (part of Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The auto-fix was required for TAX-02 correctness and kept the public error contract aligned with the plan.

## Issues Encountered

- The first verification pass showed that the Fake recurring invalid-location path reached billing as a disabled automatic-tax payload rather than an error. That behavior is now blocked at the billing boundary and covered by the focused test file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 19 now has the public TAX-02 billing surface and focused proof coverage in place.
- The next incomplete plan is `19-04`, which can build on the stable billing facade and test contract to surface local tax-risk state in admin and the host flow.

## Verification

- `cd accrue && mix test test/accrue/billing/tax_location_test.exs`

## Self-Check: PASSED

- Found `.planning/phases/19-tax-location-and-rollout-safety/19-02-SUMMARY.md`
- Found commit `f87de8c`
- Found commit `0bf065c`
