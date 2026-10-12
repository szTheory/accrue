---
phase: 246-collection-controls-and-search
plan: 02
subsystem: ui
tags: [phoenix-liveview, collections, filters, search, playwright]
requires:
  - phase: 246-01
    provides: Shared collection filter region and chip bar controls
provides:
  - Truthful collection search guidance and exact relationship filters
  - Multi-status subscription selection and mutually exclusive coupon views
  - Labeled payment and Connect categorical controls
affects: [246-03, collection-filters, admin-search]
actuals:
  tokens: 8223.25
  tasks: 3
  commits: 3
plan_head_before: 4dd0b74558ed151b416ded5711a02c1ee4308794
plan_head_after: 97fecbbd6587401cc76da982cf8afa510a96691e
commits: 3
tech-stack:
  added: []
  patterns: [bounded canonical checkbox selection, labeled native categorical filters, secondary exact relationship fields]
key-files:
  created:
    - examples/accrue_host/e2e/phase246-collection-filters.spec.js
  modified:
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - examples/accrue_host/playwright.phase246.config.js
key-decisions:
  - "Keep subscription status OR predicates and normalize selections to a stable bounded URL order."
  - "Keep exact customer, coupon, and webhook relationships separate from broad q search."
  - "Preserve custom Connect account types as editable values instead of imposing a fixed enum."
patterns-established:
  - "Categorical filters use explicit labels and concise native controls."
  - "Exact relationship identifiers live in the secondary filter disclosure."
requirements-completed: [FILTER-01, FILTER-02, FILTER-03]
coverage:
  - id: D1
    description: Subscription status sets and coupon All/Valid views keep selected state, URL, and rows aligned.
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs and coupons_live_test.exs
        status: pass
      - kind: e2e
        ref: playwright:phase246-collection-filters.spec.js subscription and coupon journeys
        status: pass
    human_judgment: false
  - id: D2
    description: Payments and Connect use truthful search guidance and labeled categorical criteria while preserving custom account types.
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/charges_live_test.exs and connect_accounts_live_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Customer, promotion code, and event search claims match existing predicates, with exact relationships discoverable separately.
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/customers_live_test.exs, promotion_codes_live_test.exs, and events_live_test.exs
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-10-11
status: complete
---

# Phase 246 Plan 02: Collection Controls and Search Summary

**Collection filters now expose truthful search fields, stable subscription status sets, singular coupon views, and labeled categorical criteria.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-11T16:38:12Z
- **Completed:** 2026-10-11T16:55:46Z
- **Tasks:** 3
- **Files modified:** 16

## Accomplishments

- Added canonical multi-select subscription statuses with bounded values and retained existing OR query behavior.
- Made coupon All and Valid views mutually exclusive and retained the default Valid selection when a search query is present.
- Updated Payments, Connect, Customers, Promotion Codes, and Events filter labels to describe actual q predicates and distinguish exact relationship filters.
- Added mounted browser coverage for subscription controls, URL/history, matching rows, and coupon view/search transitions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Subscription status set and Coupons selected state** - `a6e39471` (feat)
2. **Task 2: Labeled native categorical criteria on payment and Connect lists** - `cee685ee` (feat)
3. **Task 3: Truthful general search and exact filters on customer, code and event lists** - `97fecbbd` (feat)

## Verification

- Task 1 focused LiveView tests: 22 tests, 0 failures.
- Task 2 focused LiveView tests: 22 tests, 0 failures.
- Task 3 focused LiveView tests: 31 tests, 0 failures.
- Full `mix test`: 705 tests, 0 failures.
- Phase 246 mounted Playwright collection tests: 2 passed, 0 failed.
- `git diff --check`: passed.

## TDD Gate Compliance

- Task 1 RED: new LiveView tests failed for missing checkbox selection and duplicate coupon selection. GREEN: focused tests passed after implementation.
- Task 2 RED: tests exposed inaccurate Payments search guidance and insufficiently explicit Connect control labeling. GREEN: both focused LiveView files passed.
- Task 3 RED: new Customer and Event tests failed on generic search guidance. GREEN: all three relevant test files passed.

## Files Created/Modified

- `examples/accrue_host/e2e/phase246-collection-filters.spec.js` - mounted subscription and coupon filter journeys.
- `examples/accrue_host/playwright.phase246.config.js` - includes the new Phase 246 collection spec.
- `accrue_admin/lib/accrue_admin/live/` - collection filter declarations, canonical status handling, and truthful q/secondary field labels.
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` - bounded canonical status selection normalization.
- `accrue_admin/test/accrue_admin/live/` - regression tests for state, predicates, and custom values.

## Decisions Made

- Kept existing query predicates and owner scoping while making control state and search claims match them.
- Kept custom Connect account type values as editable suggestions rather than constraining them to known defaults.
- Kept exact relationship identifiers outside broad q search and in the secondary filter disclosure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve the Valid coupon default when search is supplied directly**
- **Found during:** Task 1 browser verification.
- **Issue:** A direct `q` URL omitted the default `valid=true` selection, so the form did not reflect the page’s default Valid view.
- **Fix:** Canonicalize the default Valid filter while retaining q and owner scope; extended the mounted browser journey with a seeded valid coupon query.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/coupons_live.ex`, `examples/accrue_host/e2e/phase246-collection-filters.spec.js`.
- **Verification:** Coupon LiveView test and mounted coupon browser journey pass.
- **Committed in:** `a6e39471`.

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The correction closes a direct-URL state mismatch without changing coupon predicates or expanding scope.

## Issues Encountered

- The subscription status query intentionally treats `unpaid` records as part of the Past due predicate; browser assertions account for that established mapping.
- The segmented radio controls hide their native inputs, so browser tests click the visible labeled options.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 246-02 is complete and ready for Plan 246-03.
- The browser suite uses the ordinary Phase 245 Fake host and writes only Phase 246 result artifacts.

---
*Phase: 246-collection-controls-and-search*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Summary file exists at the planned phase path.
- All three task commit hashes are ancestors of HEAD.
- Stub scan found only intentional search/input placeholder labels; no TODO, FIXME, or unimplemented UI stubs.
