---
phase: 198-propagate-detail-analytics
plan: "03"
subsystem: testing
tags: [phoenix-liveview, exunit, admin-ui, detail-contracts, analytics-contracts]

requires:
  - phase: 195-exemplar-b-subscription-detail
    provides: Subscription DETAIL exemplar primitives and lazy Activity/Raw JSON contract
  - phase: 198-propagate-detail-analytics
    provides: Wave 0 Phase 198 Playwright and high-risk LiveView contract scaffolding
provides:
  - Coupon, promotion-code, and event read-only DETAIL contract tests
  - Recovery overview and AtRiskTable doc posture contract tests
  - Campaign analytics detail drill-down contract tests
affects: [phase-198-detail-propagation, phase-198-analytics-propagation, phase-200-verification]

tech-stack:
  added: []
  patterns:
    - "RED ExUnit contracts for Phase 198 page-level conformance before runtime rewrites"
    - "Local data_attr_count/2 and heading_count/2 helpers mirror prior Phase 198 tests"
    - "Order helpers assert marker order for DETAIL and Recovery overview bands"

key-files:
  created:
    - .planning/phases/198-propagate-detail-analytics/198-03-SUMMARY.md
  modified:
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
    - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
    - accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs

key-decisions:
  - "Kept 198-03 test-only: runtime DETAIL and analytics rewrites remain owned by later Phase 198 implementation plans."
  - "Documented focused RED verification failures as expected conformance gaps, not setup or fixture failures."

patterns-established:
  - "Reference-detail contracts assert one h1, one summary list, one related strip, lazy Activity, and lazy Raw data."
  - "Recovery contracts use Recovery-specific hero/work-queue/supporting-funnel markers instead of Dashboard zone grammar."
  - "Campaign contracts treat the route as a detail drill-down with summary rows and CampaignTimeline as the primary drill."

requirements-completed: [PRP-02]

duration: 7m 47s
completed: 2026-06-28
status: complete
---

# Phase 198 Plan 03: Reference Detail And Analytics Contracts Summary

**RED LiveView and component contracts for read-only DETAIL pages plus Recovery and Campaign analytics conformance**

## Performance

- **Duration:** 7m 47s
- **Started:** 2026-06-28T23:35:01Z
- **Completed:** 2026-06-28T23:42:48Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added read-only DETAIL contracts for Coupon, Promotion code, and Event covering summary rows, related resources, lazy Activity, lazy Raw data, no empty action overflow, and no KPI-first/raw-payload drift.
- Added Recovery overview contracts for orientation/window selector preservation plus Recovery-specific hero, at-risk work queue, and supporting funnel marker order.
- Added AtRiskTable doc posture coverage so stale docs that place the work queue below the funnel are caught.
- Added Campaign detail drill-down contracts requiring `Detail.summary_card`, one `[data-ax-summary-list]`, CampaignTimeline content or empty state, and no KPI-grid / `AnalyticsPage` drift.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock reference detail contracts** - `41ca7a20` (test)
2. **Task 2: Lock Recovery overview grammar and AtRiskTable doc contract** - `114858e9` (test)
3. **Task 3: Lock Campaign detail drill-down contract** - `71dff9cf` (test)

**Plan metadata:** committed in the closeout docs commit.

## Files Created/Modified

- `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` - Adds Coupon DETAIL contract assertions for summary rows, lazy bottom sections, related strip, no KPI grid, and no eager raw payload.
- `accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs` - Adds Promotion-code DETAIL contract assertions for summary rows, lazy bottom sections, related strip, no KPI grid, and no eager raw payload.
- `accrue_admin/test/accrue_admin/live/event_live_test.exs` - Adds Event DETAIL contract assertions for source/subject links, lazy activity/raw data, raw payload concealment, and quiet related empty state.
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` - Adds Recovery-specific overview marker/order assertions.
- `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` - Adds module-doc posture assertion for AtRiskTable as the Recovery work queue before the supporting funnel.
- `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` - Adds Campaign detail drill-down assertions for summary rows and CampaignTimeline primary drill behavior.

## Decisions Made

- Kept the plan strictly test-only. The focused failures are intended RED contracts for 198-04, 198-06, and 198-08 style runtime conformance work.
- Used local test helpers instead of extracting shared support because this plan only adds contract tests and the existing Phase 198 test files already use local helper style.

## Verification

Expected RED results:

- `cd accrue_admin && mix test test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/event_live_test.exs --max-failures 6` - **expected red**, 19 tests, 4 failures:
  - Promotion-code DETAIL contract missing summary-list/lazy contract
  - Coupon DETAIL contract missing summary-list/lazy contract
  - Event related-resources empty wrapper missing
  - Event DETAIL contract missing summary-list/lazy contract
- `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/components/at_risk_table_test.exs --max-failures 5` - **expected red**, 19 tests, 2 failures:
  - AtRiskTable docs still describe stale below-funnel posture
  - Recovery lacks Phase 198-specific overview markers
- `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs --max-failures 4` - **expected red**, 9 tests, 2 failures:
  - Campaign populated detail missing `[data-ax-summary-list]`
  - Campaign empty detail missing `[data-ax-summary-list]`

All failures are conformance failures intentionally left for later runtime rewrite plans. No syntax, fixture setup, or package/tooling failure was observed.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep. Production runtime rewrites were intentionally deferred.

## Issues Encountered

- The verification commands are red by design because this Wave 0 plan creates contracts before runtime conformance work. Failures were inspected and confirmed to be missing contract markers/docs rather than broken setup.
- The first verification wrapper used `status`, a reserved zsh variable, before rerunning successfully with `rc`. This did not affect repository files or task verification.

## Known Stubs

None.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for subsequent Phase 198 implementation plans to turn these contracts green by applying DETAIL propagation to reference pages and analytics conformance to Recovery/Campaign.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-28*

## Self-Check: PASSED

- Created/modified files verified on disk.
- Task commits verified in git history: `41ca7a20`, `114858e9`, `71dff9cf`.
- No tracked file deletions were introduced.
