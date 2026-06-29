---
phase: 198-propagate-detail-analytics
plan: "04"
subsystem: admin-ui
tags: [phoenix-liveview, customer-detail, spec-detail, payment-methods, tdd]

# Dependency graph
requires:
  - phase: 198-propagate-detail-analytics
    provides: Customer DETAIL contract tests from plans 198-01 through 198-03
provides:
  - Customer summary-first DETAIL page structure
  - Customer peer record-set navigation limited to Subscriptions, Invoices, and Payments
  - Intent-gated Customer payment-method action drawer with server-side id validation
affects: [customer-live, billing-admin, spec-detail, phase-198]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Page-owned LiveView state for Customer peer record sets and payment-method drawer actions
    - Detail.summary_card plus Detail.summary_list as Customer first-scan structure
    - Overlay-backed DetailDrawer with hidden test mirror for LiveView tests

key-files:
  created:
    - .planning/phases/198-propagate-detail-analytics/198-04-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex
    - accrue_admin/lib/accrue_admin/copy.ex

key-decisions:
  - "Kept Customer peer navigation as plain scoped links, not ARIA tabs, because no full tab keyboard component was introduced."
  - "Kept Customer payment-method action state page-owned in CustomerLive and revalidated payment-method ids before mutation."
  - "Used the existing DetailDrawer overlay pattern instead of adding a generic DetailPage or action DSL."

patterns-established:
  - "Customer peer record sets normalize ?tab=payments to the internal charges collection while rendering the visible Payments label."
  - "Payment-method actions render as intent buttons and open drawer state; direct legacy mutation event names were removed."
  - "Activity and Raw data are lazy bottom sections with page-owned load flags."

requirements-completed: [PRP-02]

# Metrics
duration: 16m 39s
completed: 2026-06-29
status: complete
---

# Phase 198 Plan 04: Customer Detail Propagation Summary

**CustomerLive now follows the SPEC-DETAIL Customer-360 shape with summary-first state, peer record-set navigation, lazy activity/raw sections, and intent-gated payment-method actions.**

## Performance

- **Duration:** 16m 39s
- **Started:** 2026-06-28T23:48:11Z
- **Completed:** 2026-06-29T00:04:50Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Reworked CustomerLive into a summary-first DETAIL page with Customer-specific summary rows, payment method/access/tax drills, one related-resources strip, and lazy Activity/Raw data sections.
- Replaced the old broad tab model with Customer peer record-set links for Subscriptions, Invoices, and Payments while preserving `?tab=payments` and `?tab=charges` compatibility.
- Moved Customer payment-method set-default/delete operations behind explicit drawer intent and re-check payment-method ids/action availability server-side before mutation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Render Customer summary-first DETAIL spine**
   - `bed4a142` (test): add Customer detail summary contract
   - `a70a349e` (feat): render Customer summary-first detail spine
2. **Task 2: Replace broad Customer tabs with peer record-set links**
   - `8e3b336c` (test): add Customer peer record-set source contract
   - `5c162cbc` (feat): restrict Customer peer record-set state
3. **Task 3: Gate Customer payment-method actions behind operator intent**
   - `088983cd` (test): add Customer payment-method intent gate contract
   - `89a64d79` (feat): gate Customer payment-method actions

**Plan metadata:** committed in final docs closeout

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - Customer DETAIL layout, peer navigation, lazy sections, and payment-method drawer event flow.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - TDD coverage for summary rows, peer navigation compatibility, lazy/detail markers, and payment-method intent validation.
- `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` - Drawer body/subtitle and validation copy for payment-method actions.
- `accrue_admin/lib/accrue_admin/copy.ex` - Facade delegates for new Customer payment-method copy.

## Decisions Made

- Kept Customer navigation as regular scoped links with `aria-current`, not ARIA `tab` roles, because this plan did not implement full tab keyboard semantics.
- Removed direct legacy payment-method mutation events from CustomerLive so browser events cannot skip the drawer intent state.
- Kept delete in the existing drawer confirmation path; Customer payment-method delete was not previously step-up gated, so no new step-up path was introduced.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Known Stubs

None. Stub scan found only legitimate empty-state checks for empty lists and no placeholder data sources.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs --max-failures 5` - PASS, 12 tests, 0 failures.
- `! rg -n "@more_tabs|More <|role=\"tab" accrue_admin/lib/accrue_admin/live/customer_live.ex` - PASS, no matches.
- `! rg -n "phx-click=\"set_default_payment_method\"|phx-click=\"prepare_delete_payment_method\"|phx-click=\"confirm_delete_payment_method\"|pending_payment_method_delete" accrue_admin/lib/accrue_admin/live/customer_live.ex` - PASS, no matches.
- `git diff --check` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

CustomerLive now satisfies the locked Customer-360 tab exception and payment-method action gate. Later Phase 198 plans can proceed to invoice/charge/connect/webhook/read-only/analytics propagation without expanding Customer scope.

## Self-Check: PASSED

- Verified SUMMARY exists at `.planning/phases/198-propagate-detail-analytics/198-04-SUMMARY.md`.
- Verified modified source/test/copy files exist.
- Verified task commits exist: `bed4a142`, `a70a349e`, `8e3b336c`, `5c162cbc`, `088983cd`, `89a64d79`.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-29*
