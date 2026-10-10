---
phase: 241-billing-operator-journeys
plan: "01"
subsystem: billing-ui
tags: [phoenix-liveview, invoices, owner-scope, subscription-detail]

requires:
  - phase: 240
    provides: Shared detail hierarchy, scoped navigation, and truthful billing-state presentation
provides:
  - Separate customer-open-invoice and authorized-scope invoice destinations from subscription detail
  - Subscription-detail coverage for missing billing observations and empty invoice sets
affects: [241-02, 241-07]

actuals:
  tokens: 4814
  tasks: 2
  commits: 2
plan_head_before: 85b74dc8f601006de8eb23f529967e066adfa60c
plan_head_after: ad73b9f511e4a23dd5721ba29f079f5e45f4bf52

tech-stack:
  added: []
  patterns:
    - Use the existing Invoices route with only decoded customer_id/status filters for customer-specific open invoices.
    - Keep authorized-scope queues separately named and scoped through ScopedPath.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/queries/query_modules_test.exs

key-decisions:
  - "Customer invoice destinations use customer_id plus status=open; no subscription-only filter or count is implied."
  - "The broader invoice destination names the current global or selected-organization scope."

requirements-completed: [JRN-01]

coverage:
  - id: D1
    description: Subscription detail offers separate, accurately named customer-open-invoice and authorized-scope destinations.
    requirement: JRN-01
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#renders the six-band detail structure with one related resources strip
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/queries/query_modules_test.exs#open invoice destinations preserve customer membership and authorized scope
        status: pass
    human_judgment: false
  - id: D2
    description: Subscription detail keeps lifecycle and confirmed facts truthful with missing observations and an empty customer invoice set, while retaining exact identifiers and supported actions.
    requirement: JRN-01
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#active lifecycle remains active when price and period observations are unavailable
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#subscription identity and lifecycle precede actions and raw disclosure
        status: pass
    human_judgment: false

duration: 4 min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 01: Subscription Invoice Destinations Summary

**Subscription detail now links customer-wide open invoices and the separately scoped authorized queue without embedded owner-wide previews or inferred subscription counts.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-10-10T01:21:36Z
- **Completed:** 2026-10-10T01:25:41Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced repeated invoice queue panels and ignored `subscription_id` links with one secondary Related billing group containing distinct customer and current-scope destinations.
- Verified decoded customer and authorized-organization result membership, including equal-value invoices on separate subscriptions and an excluded organization.
- Kept subscription identity, lifecycle, exact confirmed facts, missing-value copy, and supported actions available without an invoice count or embedded invoice read.

## Task Commits

1. **Task 1: Trace subscription to customer open-invoice results** - `b36fe0d0` (feat)
2. **Task 2: Cover subscription facts and result states at the owning view** - `ad73b9f5` (test)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - Removed duplicate queue previews and added accurately scoped invoice links after subscription actions.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Asserts link filters, hierarchy, empty results, missing facts, and long identifiers/names.
- `accrue_admin/test/accrue_admin/queries/query_modules_test.exs` - Asserts exact customer and authorized-scope invoice membership and ignored-filter behavior.

## Decisions Made

- Customer invoice links use the existing `customer_id` and `status=open` filters; broader scope links do not imply customer or subscription filtering.
- The scope destination labels a verified selected organization by its current scope name, or says global scope for platform-wide access.

## Deviations from Plan

None - plan executed as written. Test fixtures were adjusted to honor the existing customer uniqueness and field-length constraints; no product behavior or scope changed.

## Issues Encountered

- The organization-scope fixture needed a distinct supported processor because the existing owner/processor uniqueness constraint permits one customer record per processor and owner.
- The long-name fixture was shortened below the schema's 255-character field limit while remaining long enough to exercise preserved text.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 241-01 is ready for the remaining phase work. Responsive geometry and served-asset browser evidence remain assigned to Plan 241-07.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*
