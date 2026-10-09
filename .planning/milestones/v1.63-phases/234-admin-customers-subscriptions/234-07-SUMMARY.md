---
phase: 234-admin-customers-subscriptions
plan: "07"
subsystem: payments
tags: [phoenix-liveview, scoped-navigation, owner-scope]

# Dependency graph
requires:
  - phase: 234-01
    provides: Owner-scoped reads and bounded ScopedPath return validation
provides:
  - Customer and subscription journeys preserve validated related-record return context
  - Invoice and payment detail returns bind customer detail context to the loaded related customer
affects: [phase-234, admin-customer-navigation, invoice-navigation, payment-navigation]

# Measured plan commit range
plan_head_before: 6f6edb60e5202a844a8cab077be37ff7655c11d9
plan_head_after: 59b03668123b44086d6ca8f2b60dcfee49f585ab
commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Record-aware local return validation with current mount and OwnerScope reconstruction

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - accrue_admin/test/accrue_admin/scoped_path_test.exs

key-decisions:
  - "Customer-detail returns from a related record are accepted only when the customer ID matches that record's loaded, owner-scoped customer."
  - "Invalid related customer origins fall back to the current detail type's list; valid paths are rebuilt under current mount and owner scope."

patterns-established:
  - "Return URL input preserves navigation context but never chooses owner scope."

requirements-completed: [ADM-03, SAFE-01]

coverage:
  - id: D1
    description: Customer and subscription journeys retain authorized context through invoice and payment detail returns.
    requirement: ADM-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/customer_live_test.exs"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscription_live_test.exs"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/charge_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Forged, foreign, stale, and alternate-mount customer returns are rejected without changing owner scope.
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/scoped_path_test.exs"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/charge_live_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-10-08
status: complete
---

# Phase 234 Plan 07: Scoped Customer and Related-Record Returns Summary

**Customer and subscription navigation now retains validated customer-tab context through owner-scoped invoice and payment details.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-08T00:59:24Z
- **Completed:** 2026-10-08T01:06:01Z
- **Tasks:** 2 completed
- **Files modified:** 13, including the plan contract

## Accomplishments

- Preserved customer result state and the active customer tab through subscription and related-record navigation.
- Added record-aware return validation: a customer detail ID must exactly match the customer loaded through the current invoice, payment, or subscription under the current owner scope.
- Rebuilt accepted local paths under the current mount and `OwnerScope`; invalid customer origins return to the appropriate invoice or payment list.
- Added focused checks for matching origins, foreign/forged IDs, alternate mounts, owner-scope preservation, and Task 1 customer navigation.

## Task Commits

1. **Task 1: Carry customer result and tab context into the named subscription** — `0f15763c` (feat)
2. **Task 2: Carry validated origin through related invoice and payment returns** — `59b03668` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/{customers_live,customer_live,subscription_live,invoice_live,charge_live}.ex` — carry contextual navigation through customer, subscription, invoice, and payment details.
- `accrue_admin/lib/accrue_admin/scoped_path.ex` — validate customer detail returns against the related loaded record and rebuild with current mount and owner scope.
- `accrue_admin/test/accrue_admin/live/{customers_live,customer_live,invoice_live,charge_live}_test.exs` and `accrue_admin/test/accrue_admin/scoped_path_test.exs` — cover preserved state and safe fallback behavior.
- `.planning/phases/234-admin-customers-subscriptions/234-07-PLAN.md` — document the approved helper-contract exception.

## Decisions Made

- Customer detail returns are record-aware: only the current detail's loaded customer may be restored. This prevents a crafted related-record URL from naming another customer.
- List destinations remain allowlisted; a return parameter cannot select owner scope or mount.

## Deviations from Plan

### Approved architectural deviation

**1. Extend the shared return helper with record-aware customer validation**
- **Found during:** Task 2
- **Issue:** The original list-only return helper could not safely restore a customer tab from a related invoice/payment detail, while simple path-prefix checks did not prove the customer belonged to that loaded record.
- **Approved change:** Add a bounded helper overload that validates exact customer ID equality against the currently loaded owner-scoped related record and accepts a route-specific list fallback. The stable three-argument helper remains available for existing callers.
- **Files modified:** `accrue_admin/lib/accrue_admin/scoped_path.ex`, `accrue_admin/lib/accrue_admin/live/{subscription_live,invoice_live,charge_live}.ex`, focused tests, and this plan's Task 2 constraint.
- **Verification:** Task 2 focused suites passed; Task 1 customer suites passed.

**Total deviations:** 1 approved architectural deviation.
**Impact on plan:** Enables the approved navigation intent while preserving mount and owner scope and rejecting unrelated customer IDs.

## Issues Encountered

- The invoice test fixture's `customer` association was unloaded; the test now loads the customer by the invoice's `customer_id` before changing owner scope.
- `roadmap.update-plan-progress 234` returned `missing_phase_details` because the roadmap updater's active-region scan stops before the Phase 234 section. After confirming the existing summaries on disk, the Phase 234 plan checkboxes and progress row were aligned directly to the three completed summaries (01, 02, and 07).

## User Setup Required

None.

## Next Phase Readiness

The customer/subscription/related-record navigation journey is complete. Invoice and payment edits remain navigation-only as planned.

## Self-Check: PASSED

- SUMMARY exists at the expected phase path.
- Task commits `0f15763c` and `59b03668` are ancestors of HEAD.
- Measured task commit count from `plan_head_before` to `plan_head_after` is 2.

---
*Phase: 234-admin-customers-subscriptions*
*Completed: 2026-10-08*
