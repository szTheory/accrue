---
phase: 20-organization-billing-with-sigra
plan: 05
subsystem: ui
tags: [sigra, liveview, organization-billing, admin-scope, events]
requires:
  - phase: 20-organization-billing-with-sigra
    provides: Owner-aware admin query loaders and webhook ambiguity proof from plan 20-04
provides:
  - Exact cross-org denial redirects for customer and subscription detail routes
  - Owner-scoped event feed and summary counts for the active organization
  - Focused ORG-03 LiveView coverage for denied detail routes and hidden out-of-scope events
affects: [phase-20-plan-06, phase-21, accrue-admin, org-billing]
tech-stack:
  added: []
  patterns: [detail-route denial via owner-aware loaders, shared list query scoping via current_owner_scope]
key-files:
  created:
    - .planning/phases/20-organization-billing-with-sigra/20-05-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/queries/events.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
key-decisions:
  - "Customer and subscription detail routes now treat owner-aware loader misses as authorization denials and redirect to the scoped index with the locked UI-SPEC copy."
  - "Shared admin table queries now forward current_owner_scope so organization scoping applies consistently to list pages instead of only detail loaders."
patterns-established:
  - "Decode denial flash content from mount redirects in LiveView tests with Phoenix.LiveView.Utils.verify_flash/2 when the route exits before rendering."
  - "Compare accrue_events.subject_id to UUID-backed billing ids through ::text casts when scoping event rows by local owner proof."
requirements-completed: [ORG-03]
duration: 7 min
completed: 2026-04-17
---

# Phase 20 Plan 05: Scoped Admin Denial Presentation Summary

**Admin customer, subscription, and event LiveViews now fail closed for the active organization with exact denial copy and owner-scoped event feeds.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-17T20:19:00Z
- **Completed:** 2026-04-17T20:25:32Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Redirected out-of-scope customer and subscription detail routes before any row content is assigned, using the exact organization denial flash copy from the UI spec.
- Scoped admin event feed summaries and row queries to the active organization so linked webhook activity cannot bypass owner checks.
- Added focused LiveView coverage for denied detail redirects and hidden out-of-scope invoice-backed events.

## Task Commits

Each task was committed atomically:

1. **Task 1: Redirect ORG-03 out-of-scope customer and subscription detail routes with exact denial copy** - `fa13ca1` (feat)
2. **Task 2: Keep the ORG-03 event feed owner-scoped so it cannot bypass detail denial** - `0084d8e` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - swaps direct row loads for owner-aware detail queries and denial redirects.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - denies out-of-scope subscription detail routes before staged actions can render.
- `accrue_admin/lib/accrue_admin/live/customers_live.ex` - renders redirected flash messages on the customer index.
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` - renders redirected flash messages on the subscription index.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` - forwards `current_owner_scope` into shared list and polling queries.
- `accrue_admin/lib/accrue_admin/live/events_live.ex` - scopes event summaries and copy to the active organization.
- `accrue_admin/lib/accrue_admin/queries/events.ex` - fixes owner-proof joins for UUID-backed event subjects.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - covers denied customer redirects and exact denial flash decoding.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - covers denied subscription redirects and exact denial flash decoding.
- `accrue_admin/test/accrue_admin/live/events_live_test.exs` - proves in-scope invoice events render while out-of-scope rows stay hidden.

## Decisions Made

- Reused the owner-aware query modules from plan 20-04 as the single source of truth for detail-route authorization.
- Scoped event list plumbing at the shared `DataTable` boundary so owner-aware queries apply uniformly to list reloads, pagination, and polling.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Threaded owner scope through shared list queries**
- **Found during:** Task 2 (Keep the ORG-03 event feed owner-scoped so it cannot bypass detail denial)
- **Issue:** `AccrueAdmin.Components.DataTable` did not pass `current_owner_scope` into query modules, so the event feed and any other scoped list pages would still load global rows.
- **Fix:** Forwarded `owner_scope` through initial loads, pagination, and newer-count polling in the shared table component.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`
- **Verification:** `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs`
- **Committed in:** `0084d8e`

**2. [Rule 1 - Bug] Fixed UUID/text owner-proof comparisons for scoped event queries**
- **Found during:** Task 2 (Keep the ORG-03 event feed owner-scoped so it cannot bypass detail denial)
- **Issue:** Owner-proof fragments compared UUID billing ids directly to `accrue_events.subject_id` text values, which raised `operator does not exist: uuid = character varying` in org-scoped event paths.
- **Fix:** Cast customer, subscription, and invoice ids to `::text` in both the shared event query module and the events LiveView summary query.
- **Files modified:** `accrue_admin/lib/accrue_admin/queries/events.ex`, `accrue_admin/lib/accrue_admin/live/events_live.ex`
- **Verification:** `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs`
- **Committed in:** `0084d8e`

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 bug)
**Impact on plan:** Both fixes were required for ORG-03 correctness. No scope was added beyond the owner-scoped admin surfaces already in plan 20-05.

## Issues Encountered

- Mount-time denial redirects return a signed flash token instead of rendered HTML. The focused LiveView tests decode that token directly to prove the exact denial copy contract.
- The local `gsd-sdk query ...` state handlers referenced by the workflow were unavailable in this environment, so planning metadata was updated directly in the tracked markdown files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan `20-06` can build on the same scoped denial and event-feed plumbing for webhook detail ambiguity handling and replay controls.
- Phase 21 can use the active-organization event feed and denial copy as the UI proof baseline for browser verification.

## Self-Check: PASSED

- Verified `.planning/phases/20-organization-billing-with-sigra/20-05-SUMMARY.md` exists on disk.
- Verified task commits `fa13ca1` and `0084d8e` exist in git history.
