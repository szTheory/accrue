---
phase: 07-admin-ui-accrue-admin
plan: 07
subsystem: ui
tags: [phoenix, liveview, webhooks, events, oban, datatable, json]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Shared auth hook, step-up/audit causality seams, display primitives, and query-driven DataTable foundations
provides:
  - Webhook list and detail admin surfaces with payload inspection, retry history, and derived-event linkage
  - Single and bulk webhook replay flows wired to the existing DLQ primitives with admin audit rows
  - Global `accrue_events` activity feed page for cross-resource operator visibility
affects: [07-08, 07-12, admin-ops, verification]
tech-stack:
  added: []
  patterns: [query-module-backed ops pages, webhook-to-event causality display, replay verification against real Oban test wiring]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/queries/webhooks.ex
    - accrue_admin/lib/accrue_admin/queries/events.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
    - accrue_admin/test/test_helper.exs
key-decisions:
  - "Webhook detail derives attempt history from existing Oban job rows instead of inventing a second retry-tracking table."
  - "Replay actions stay thin UI wrappers over `Accrue.Webhooks.DLQ.requeue/1` and `requeue_where/2`, with admin audit rows added at the LiveView boundary."
  - "Global activity feed filters directly on `accrue_events`, keeping subject-scoped timelines and ops-wide visibility on the same append-only ledger."
patterns-established:
  - "Ops page pattern: mount shared shell state, summarize with KPI cards, and drive list pages through `AccrueAdmin.Queries.*` plus `DataTable`."
  - "Webhook causality pattern: show raw payload, job retry history, and `caused_by_webhook_event_id`-linked ledger rows together on one detail surface."
requirements-completed: [ADMIN-16, ADMIN-17, ADMIN-18]
duration: 13m
completed: 2026-04-15
---

# Phase 7 Plan 07: Webhook Inspector and Activity Feed Summary

**Webhook inspector pages with DLQ replay controls and a global `accrue_events` feed for operator traceability**

## Performance

- **Duration:** 13m
- **Started:** 2026-04-15T18:33:00Z
- **Completed:** 2026-04-15T18:46:11Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added `AccrueAdmin.Queries.Webhooks` plus webhook list/detail LiveViews that expose payload JSON, signature-verification status, retry history, and derived event linkage.
- Wired single-row and bulk replay flows to the existing `Accrue.Webhooks.DLQ` primitives while recording admin audit rows for replay intent.
- Added `AccrueAdmin.Queries.Events` and a global activity feed page so operators can inspect the append-only event ledger outside per-subject tabs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the webhook inspector list/detail surfaces with payload and attempt visibility** - `1503855` (feat)
2. **Task 2: Wire webhook replay flows and the global activity feed** - `e0ffebc` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/queries/{webhooks,events}.ex` - query modules for webhook operations and the global event ledger feed.
- `accrue_admin/lib/accrue_admin/live/{webhooks_live,webhook_live,events_live}.ex` - webhook list/detail screens, replay controls, and the all-events admin page.
- `accrue_admin/lib/accrue_admin/router.ex` and `components/app_shell.ex` - admin route wiring and navigation entry for the new ops pages.
- `accrue_admin/test/accrue_admin/live/{webhooks_live,webhook_live,webhook_replay,events_live}_test.exs` - focused LiveView coverage for filtering, payload inspection, replay actions, and global feed filters.
- `accrue_admin/test/test_helper.exs` - starts Oban in manual testing mode so replay tests exercise the real DLQ path.

## Decisions Made

- Used existing Oban job history as the webhook attempt timeline because the current schema does not persist per-attempt rows outside `oban_jobs`.
- Kept replay audit emission in the admin LiveViews instead of changing core DLQ semantics, which preserved the existing backend replay behavior while adding operator attribution.
- Exposed the global activity feed as a first-class page and nav entry instead of overloading the dashboard timeline, keeping scoped and global event views distinct.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Started Oban in the admin test harness so replay tests hit the real DLQ flow**
- **Found during:** Task 2 verification
- **Issue:** `Accrue.Webhooks.DLQ.requeue/1` and `requeue_where/2` failed in admin LiveView tests because no Oban instance was running in the package-owned test environment.
- **Fix:** Updated `accrue_admin/test/test_helper.exs` to start Oban in `:manual` testing mode against `AccrueAdmin.TestRepo`, matching the core package's test wiring.
- **Files modified:** `accrue_admin/test/test_helper.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/events_live_test.exs --warnings-as-errors`
- **Committed in:** `e0ffebc`

**2. [Rule 3 - Blocking] Seeded real webhook rows for event-feed causality tests**
- **Found during:** Task 2 verification
- **Issue:** `caused_by_webhook_event_id` is enforced by a foreign key, so the global feed test could not insert linked ledger rows against a fabricated UUID.
- **Fix:** Changed the events LiveView test to create a real `WebhookEvent` fixture before recording causally linked events.
- **Files modified:** `accrue_admin/test/accrue_admin/live/events_live_test.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/events_live_test.exs --warnings-as-errors`
- **Committed in:** `e0ffebc`

---

**Total deviations:** 2 auto-fixed (2 Rule 3)
**Impact on plan:** Both fixes were required to verify replay and causality against the actual persisted primitives. No product-scope creep beyond test/runtime support.

## Issues Encountered

- Replay verification surfaced a missing Oban runtime in the admin package tests even though the core DLQ implementation depends on it.
- Event-feed causality tests initially violated the new webhook foreign key because the fixture did not create a corresponding webhook row.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later admin plans can link directly from webhook or subject pages into the global `/events` feed using `source_webhook_event_id` filters.
- Replay, payload inspection, and causality display now exist as reusable ops patterns for any later admin incident-response surfaces.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-07-SUMMARY.md`
- Found task commit `1503855` in git history
- Found task commit `e0ffebc` in git history
