---
phase: 247-evidence-true-details-and-analytics
plan: "05"
subsystem: payments
tags: [phoenix, liveview, billing-evidence, navigation, copy]
requires:
  - phase: 247-04
    provides: shared evidence timestamp and clipboard behavior
provides:
  - Detail routes use concrete real-parent breadcrumbs and unavailable language for absent evidence.
  - Billing list tables use a shared ownership and tax label and avoid inferring pending fee or setup-gap states.
affects: [247-06, 247-07, billing-details, billing-list-copy]
actuals:
  tokens: 8346
  tasks: 3
  commits: 3
plan_head_before: 2e4ff3d8d37be309f3c746e58174f2508870a890
plan_head_after: 215ac9d425ec63a14ed862611ce8704464b52a65
commits: 3
tech-stack:
  added: []
  patterns: [concrete parent breadcrumbs, unavailable evidence copy, shared owner-and-tax label]
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/components/breadcrumbs.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/test/accrue_admin/copy_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
key-decisions:
  - "Missing fee, plan, and snapshot details describe unavailable evidence without inferring pending or misconfigured states."
  - "Keep action flows and authorization unchanged; use real scoped parent destinations for breadcrumbs."
patterns-established:
  - "Billing evidence: missing values remain unavailable; actual zero remains a value."
  - "Ownership and tax: one concise label for the shared owner and tax fields."
requirements-completed: []
duration: 16min
completed: 2026-10-11
status: complete
---

# Phase 247 Plan 05: Evidence-True Details and Analytics Summary

**Billing detail routes now use real parent breadcrumbs and describe missing plan, fee, and snapshot data as unavailable evidence.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-10-11T22:03:10Z
- **Completed:** 2026-10-11T22:18:52Z
- **Tasks:** 3
- **Files modified:** 22

## Accomplishments

- Updated payment, customer, invoice, subscription, event, Connect account, coupon, and promotion code details to use concrete parent labels and evidence-backed unavailable copy.
- Kept breadcrumbs scoped to real parent destinations and omitted unusable parent rows while preserving the current page.
- Replaced “Signals” headings with a shared “Ownership and tax” label, and made absent subscription plan amounts and payment fee settlement evidence explicitly unavailable.

## Task Commits

Each task was committed atomically:

1. **Task 1: Unify payment, customer, invoice and subscription investigation** - `989c75e9` (fix)
2. **Task 2: Unify remaining detail routes and navigation names** - `9f45d9a4` (fix)
3. **Task 3: Centralize supported labels and attention language** - `215ac9d4` (fix)

## Files Created/Modified

- Detail LiveViews: concrete parents and unavailable copy for missing evidence.
- `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex` - omit parent rows without valid destinations.
- `accrue_admin/lib/accrue_admin/copy.ex` and `copy/invoice.ex` - shared ownership and tax heading.
- Subscription and payment list LiveViews - neutral unavailable plan and fee evidence.
- Owning detail, navigation, list, and copy tests - verify real destinations and evidence wording.

## Decisions Made

- Kept existing authorization, step-up requirements, action handlers, and accepted outcomes intact.
- Did not add optional Copy details because the existing visible fields already support the plan’s required investigation; no new export surface was needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test contract] Updated nearby route and navigation tests for concrete breadcrumb behavior**
- **Found during:** Task 2
- **Issue:** The changed parent labels and removal of artificial Dashboard rows made existing route assertions stale.
- **Fix:** Updated the nearest route-owned expectations and added a component test for omission of a parent without a destination.
- **Files modified:** navigation_components_test.exs and the event, Connect account, coupon, and promotion code LiveView tests.
- **Verification:** Task 2 focused suite passed, 99 tests, 0 failures.
- **Committed in:** `9f45d9a4`

**2. [Rule 1 - Test contract] Aligned copy source-contract assertions with current Connect and webhook helpers**
- **Found during:** Task 3
- **Issue:** The focused copy suite expected Connect and webhook helper call sites that those detail routes no longer use.
- **Fix:** Asserted the existing provider snapshot and replay safety copy call sites instead, preserving source-level coverage of shared operator copy.
- **Files modified:** `accrue_admin/test/accrue_admin/copy_test.exs`.
- **Verification:** Task 3 focused suite passed, 43 tests, 0 failures.
- **Committed in:** `215ac9d4`

**Total deviations:** 2 auto-fixed (Rule 1: 2)
**Impact on plan:** Tests now reflect the concrete route and shared-copy behavior introduced by this plan; no application behavior or dependencies were broadened.

## Issues Encountered

The first Task 3 runs surfaced stale headings, missing-evidence wording, and copy call-site assertions. Those expectations were updated to the shipped behavior. An initial formatter invocation from the repository root used package-relative paths and failed to locate them; the correctly scoped formatter check passed.

## Validation

- Task 1: 110 focused detail tests passed.
- Task 2: 99 focused detail and navigation tests passed.
- Task 3: 43 focused copy and list tests passed.
- Task 3 format check and `git diff --check` passed.
- Impeccable detector reported no findings for the changed UI owners.
- Plan evaluation scope resolved to the three plan commits with no outside files or unreachable commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 is ready for the remaining Phase 247 execution and final integrated verification. Requirement IDs remain pending until that final verifier runs.

---
*Phase: 247-evidence-true-details-and-analytics*
*Completed: 2026-10-11*

## Self-Check: PASSED

The summary exists, and all three task commits are ancestors of the current HEAD.
