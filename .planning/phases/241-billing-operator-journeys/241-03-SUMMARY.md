---
phase: 241-billing-operator-journeys
plan: "03"
subsystem: billing-ui
tags: [phoenix-liveview, scoped-navigation, payments, customers, subscriptions]

requires:
  - phase: 240
    provides: Shared Admin detail hierarchy, owner scope, and route-owner action guards
  - phase: 241-02
    provides: ScopedPath validated return destination paths and labels
provides:
  - Payment, customer, and subscription details render return links from one validated path/label pair
  - Same-customer peer-tab and filtered list journeys rebuild under the current owner
affects: [241-04, 241-05, 241-06, 241-07]

actuals:
  tokens: 3199.5
  tasks: 2
  commits: 2
commits: 2
plan_head_before: cba746b47e688da91146f12b719dbfce70de0bde
plan_head_after: 8ac16f2ddd92b4a30055b93627e0489414a791e7

tech-stack:
  added: []
  patterns:
    - Return destinations supply both the href and label from the validated route meaning.
    - Customer detail destinations require the loaded customer ID and rebuild with fresh owner scope.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs

key-decisions:
  - "Payment, customer, and subscription returns display the ScopedPath label paired with the validated path."
  - "Customer detail return origins must match the loaded customer; unsupported or foreign origins fall back to the scoped customer list."
  - "Existing billing mutation, fresh-scope, and stale-review checks stay in their current route owners."

requirements-completed: [JRN-02]

coverage:
  - id: D1
    description: Payment and customer returns use truthful validated labels, preserve same-customer tabs and fresh owner scope, and reject foreign customer origins.
    requirement: JRN-02
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/charge_live_test.exs#payment contextual return accepts only its loaded customer's local detail origin
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/customer_live_test.exs#customer return labels identify a matching peer tab and reject another customer's tab
        status: pass
    human_judgment: false
  - id: D2
    description: Subscription returns restore supported list filters or the matching customer's Subscriptions tab, with exact rows and repeated navigation retaining the same meaning.
    requirement: JRN-02
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#subscription detail returns to the validated originating list in the current organization scope
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#subscription detail returns to the matching customer's query-free subscriptions tab
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 03: Payment, Customer, and Subscription Return Journeys Summary

**Payment, customer, and subscription details now use validated return destinations whose labels match their restored list or same-customer tab.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-10T01:32:06Z
- **Completed:** 2026-10-10T01:37:06Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Replaced generic “Back to results” links with labels produced alongside the validated `ScopedPath` destination for payments, customers, and subscriptions.
- Bound customer detail returns to the loaded customer ID, while preserving fresh owner scope and supported decoded list filters.
- Added route-owner coverage that opens returned URLs and checks customer tab identity, returned rows, filtered subscription results, safe fallback, and repeated subscription navigation.

## Task Commits

1. **Task 1: Bind payment and customer returns to validated context** - `042a4790` (feat)
2. **Task 2: Bind subscription return and customer peer tabs** - `8ac16f2d` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - Uses a validated destination path and matching payment return label.
- `accrue_admin/test/accrue_admin/live/charge_live_test.exs` - Checks matching customer payment tab returns, visible labels, and foreign-customer fallback.
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - Uses a destination pair constrained to the loaded customer, with a scoped customer-list fallback.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - Checks matching and foreign peer-tab origins and safe customer-list fallback.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - Renders the validated subscription return path and label.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Checks supported list restoration and the same-customer Subscriptions-tab round trip.

## Decisions Made

- The validated destination label and URL are assigned as a pair, so visible copy cannot contradict the route that will open.
- Customer detail origins are accepted only for the loaded customer; the current owner is rebuilt by `ScopedPath`.
- Existing action staging and fresh mutation checks remain owned by the billing route handlers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected stale local variable references after adopting destination pairs**
- **Found during:** Task 1 verification
- **Issue:** The first compile after the return destination refactor found two related-resource calls still referencing the removed `return_path` local.
- **Fix:** Passed `return_destination.path` to the existing related-resource builders.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/charge_live.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- **Verification:** Both focused LiveView test commands passed after the correction.
- **Committed in:** `042a4790`, `8ac16f2d`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Compile correction only; no scope or behavior expansion.

## Issues Encountered

- The first focused test compile caught the stale local references noted above; correcting both restored compilation and the suites passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 241-03 is complete. JRN-02 remains shared with Plan 241-07, so global requirement bookkeeping remains pending for that owner. Combined mounted browser and served-asset proof remains with Plan 241-07.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*

## Self-Check: PASSED

- All six planned source and test files exist.
- Task commits `042a4790` and `8ac16f2d` are ancestors of HEAD; evaluation scope resolved both commits for this plan.
- Task 1 focused suite: 33 tests, 0 failures. Task 2 focused suite: 32 tests, 0 failures.
- Coverage metadata records the passing route-owner integration tests with `human_judgment: false`.
