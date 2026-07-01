---
phase: 198-propagate-detail-analytics
plan: "06"
subsystem: ui
tags: [phoenix-liveview, admin-detail, spec-detail, tdd, read-only]

requires:
  - phase: 198-propagate-detail-analytics
    provides: SPEC-DETAIL patterns and prior payment/detail propagation
  - phase: 195-exemplar-b-subscription-detail
    provides: exemplar DETAIL page structure
provides:
  - Coupon, promotion-code, and event read-only DETAIL propagation
  - Lazy activity and raw payload sections for read-only reference details
  - Scoped related-resource strips for coupon, promotion-code, and event pages
affects: [phase-198, phase-199, phase-200, admin-detail-pages]

tech-stack:
  added: []
  patterns:
    - Phoenix LiveView detail pages using Detail.summary_card, Detail.summary_list, page-specific drills, RelatedResources, Timeline, and JsonViewer
    - Raw payloads only render after lazy section interaction

key-files:
  created:
    - .planning/phases/198-propagate-detail-analytics/198-06-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/coupon.ex
    - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
    - accrue_admin/lib/accrue_admin/copy/billing_event.ex
    - accrue_admin/lib/accrue_admin/copy.ex

key-decisions:
  - "Coupon, promotion-code, and event pages remain read-only: no action bands, overflow menus, or mutation events were added."
  - "Raw payloads render only from bottom lazy sections through JsonViewer; EventLive omits the raw marker when event data is empty."
  - "Activity sections are lazy and intentionally empty where these pages have no activity source yet."

patterns-established:
  - "Read-only DETAIL sequence: summary card, summary list, page-specific drill, one related-resource wrapper, lazy activity, lazy raw data."
  - "Related links use existing ScopedPath helpers for owner-scope preservation."

requirements-completed: [PRP-02]

duration: 15m 37s
completed: 2026-06-29
status: complete
---

# Phase 198 Plan 06: Read-Only Detail Propagation Summary

**Coupon, promotion-code, and event details now use summary-first SPEC-DETAIL layouts with scoped related resources and lazy raw/activity sections.**

## Performance

- **Duration:** 15m 37s
- **Started:** 2026-06-29T01:09:28Z
- **Completed:** 2026-06-29T01:25:05Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Converted CouponLive, PromotionCodeLive, and EventLive away from KPI/eager-detail shapes into read-only DETAIL pages.
- Added D-17 summary rows, page-specific drill sections, exactly one related-resource wrapper, lazy activity markers, and lazy raw payload sections.
- Preserved read-only semantics by omitting empty action chrome and avoiding mutation/action flows.
- Added focused LiveView contract tests for summary rows, ordering, related-resource counts, lazy expansion, and raw payload deferral.

## Task Commits

1. **Task 1 RED: Coupon lazy/read-only assertions** - `5e3d64da` (test)
2. **Task 1 GREEN: Coupon DETAIL structure** - `887e4d90` (feat)
3. **Task 2 RED: Promotion-code lazy/read-only assertions** - `33cc4021` (test)
4. **Task 2 GREEN: Promotion-code DETAIL structure** - `aa8124b7` (feat)
5. **Task 3 RED: Event lazy/read-only assertions** - `94598ad2` (test)
6. **Task 3 GREEN: Event ledger DETAIL structure** - `e0a7bada` (feat)

**Plan metadata:** pending final docs commit.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/coupon_live.ex` - Coupon summary list, promotion-code/projection drills, scoped related strip, lazy activity/raw sections.
- `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` - Promotion-code summary rows, parent coupon/redemption drills, scoped related strip, lazy activity/raw sections.
- `accrue_admin/lib/accrue_admin/live/event_live.ex` - Event ledger summary rows, event drill, related wrapper with quiet empty state, lazy activity/raw sections.
- `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` - Coupon lazy and read-only DETAIL contract tests.
- `accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs` - Promotion-code lazy and read-only DETAIL contract tests.
- `accrue_admin/test/accrue_admin/live/event_live_test.exs` - Event lazy, empty-payload, related-resource, and read-only DETAIL contract tests.
- `accrue_admin/lib/accrue_admin/copy/coupon.ex` - Coupon lazy activity/raw copy.
- `accrue_admin/lib/accrue_admin/copy/promotion_code.ex` - Promotion-code drill and lazy section copy.
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex` - Event related-resource and lazy section copy.
- `accrue_admin/lib/accrue_admin/copy.ex` - Copy facade delegates for the new page-specific copy.

## Decisions Made

- Used page-specific helpers instead of introducing a generic DetailPage DSL/schema, matching the plan scope boundary.
- Kept raw projection data behind lazy JsonViewer sections to satisfy T-198-21 and reduce above-the-fold exposure.
- Rendered lazy activity markers with quiet empty-state copy because these read-only pages do not currently have an activity source.
- Kept related-resource links on existing ScopedPath/build helpers to preserve owner scope.

## Verification Results

- `cd accrue_admin && mix test test/accrue_admin/live/coupon_live_test.exs --max-failures 4` - passed, 8 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/promotion_code_live_test.exs --max-failures 4` - passed, 7 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/event_live_test.exs --max-failures 4` - passed, 11 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/event_live_test.exs --max-failures 8` - passed, 26 tests, 0 failures.
- `git diff --check` - passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Formatter caught one malformed alias comma while editing EventLive; corrected before verification and before the Task 3 implementation commit.

## Known Stubs

None. `activity_items/1` intentionally returns an empty list on these read-only pages because the plan requires a quiet lazy activity marker when no activity source exists.

## Threat Flags

None. No new endpoints, auth paths, file access patterns, schema changes, or mutation flows were introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The coupon, promotion-code, and event details now match the Phase 198 SPEC-DETAIL propagation pattern and are ready for later Phase 199/200 work without expanding this plan into mutation flows or new schemas.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/198-propagate-detail-analytics/198-06-SUMMARY.md`.
- All modified source, test, and copy files exist.
- All task commits are present in git history: `5e3d64da`, `887e4d90`, `33cc4021`, `aa8124b7`, `94598ad2`, `e0a7bada`.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-29*
