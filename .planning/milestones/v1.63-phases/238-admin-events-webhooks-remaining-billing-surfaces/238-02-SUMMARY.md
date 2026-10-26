---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
plan: 02
subsystem: admin
tags: [phoenix-liveview, ecto, events, webhooks, datatable]
requires:
  - phase: 238-01
    provides: Safe webhook replay with fresh step-up and queue outcome reporting.
provides:
  - Exact owner-scoped event detail links from the Events list.
  - Announced unavailable and retry states for local Events/Webhooks detail and summary reads.
  - Shared DataTable recovery for first-page and partial pagination failures.
affects: [phase-238-admin-surfaces, event-history, webhook-detail]
actuals:
  tokens: 8333
  tasks: 3
  commits: 4
plan_head_before: d9cb7e1af51c5e83bed1a804b972496fc6890ba8
plan_head_after: d8a721320da2b8e4694c0b589b6d59a6405a2a58
tech-stack:
  added: []
  patterns:
    - Expected DBConnection read failures render generic unavailable copy; programmer errors still surface.
    - First-page retry clears stale rows and selection; later-page retry retains rows and resumes at the failed cursor.
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
key-decisions:
  - "Only DBConnection.ConnectionError is converted to an unavailable state; backend exception details are never rendered."
  - "A later-page failure keeps already loaded rows and retries the exact failed cursor with the current filter and owner scope."
  - "A read failure remains distinct from an inaccessible or missing event/delivery record."
requirements-completed: [ADM-07]
coverage:
  - id: D1
    description: "Event rows link to the exact event record under the active organization scope, and summary failures are announced as unavailable."
    requirement: ADM-07
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/events_live_test.exs#event type links open the exact scoped event record
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/events_live_test.exs#summary read failure is announced as unavailable and can be retried
        status: pass
    human_judgment: false
  - id: D2
    description: "Event and webhook detail reads distinguish unavailable from not-found and recover through retry."
    requirement: ADM-07
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/event_live_test.exs#detail read failure is unavailable rather than not-found and retry restores the record
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhook_live_test.exs#detail read failure is unavailable rather than not-found and retry restores evidence
        status: pass
    human_judgment: false
  - id: D3
    description: "Shared list reads show unavailable or partial-load alerts, clear stale first-page data, preserve valid partial results, and retry with the same query."
    requirement: ADM-07
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/data_table_test.exs#initial list failure is unavailable and retry restores results
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/data_table_test.exs#load-more failure keeps loaded rows and retry loads the failed page
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/data_table_test.exs#first-page failure clears stale rows, pagination, and selection while preserving filters
        status: pass
    human_judgment: false
metrics:
  duration: 12min
  completed: 2026-10-09
  commits: 4
  plan_head_before: d9cb7e1af51c5e83bed1a804b972496fc6890ba8
  plan_head_after: d8a721320da2b8e4694c0b589b6d59a6405a2a58
status: complete
---

# Phase 238 Plan 02: Event and delivery evidence summary

**Event and webhook evidence now links to exact scoped records and reports local read failures with actionable retry states.**

## Performance

- **Duration:** 12 minutes
- **Started:** 2026-10-09T03:32:01Z
- **Completed:** 2026-10-09T03:44:16Z
- **Tasks:** 3/3
- **Files modified:** 8

## Accomplishments

- Event type cells link to the exact local event detail route while preserving active organization scope.
- Shared DataTable handles expected database connection failures at initial load and pagination. First-page failures clear stale rows and selection; later-page failures retain loaded rows, identify the incomplete history, and retry the failed cursor.
- Events summary, event detail, and webhook detail reads show announced unavailable states with retry, without presenting a failure as empty or not-found and without exposing backend details.
- Single webhook replay rechecks current scoped status after fresh step-up; rejected stale status makes no replay mutation. Queue errors show a recoverable message.

## Task Commits

1. **Task 1: Make event list and detail evidence exact and distinguish unavailable reads** - `6f864858` (`feat`)
2. **Task 2: Preserve delivery detail attempts and honest single replay** - `d6be0e64` (`fix`)
3. **Task 3: Render unavailable local history distinctly and recover with retry** - `d8a72132` (`fix`)

The plan was extended with T3 after review in `19b82cec` (`docs`).

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/data_table.ex` - Initial and partial read errors, safe copy, cleared stale first-page state, and retry at the failed cursor.
- `accrue_admin/lib/accrue_admin/live/events_live.ex` - Exact scoped event links and unavailable summary copy/retry.
- `accrue_admin/lib/accrue_admin/live/event_live.ex` - Unavailable detail state distinct from not-found, with retry.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` - Scoped delivery/attempt/derived-event read recovery and post-replay refresh handling.
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` - Initial, partial, stale-state, filter-preserving retry regressions.
- `accrue_admin/test/accrue_admin/live/events_live_test.exs` - Exact scoped event link and summary retry regressions.
- `accrue_admin/test/accrue_admin/live/event_live_test.exs` - Unavailable versus not-found and recovery regression.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - Unavailable delivery evidence recovery and stale-status replay regressions.

## Decisions Made

- Catch only `DBConnection.ConnectionError`; unrelated implementation errors continue to surface.
- A later-page retry repeats the failed cursor with the same filter and owner scope, while preserving prior rows and selection.
- Detail read failure is separate from owner denial, ambiguous ownership, and a missing record.

## Deviations from Plan

None - the authorized T3 extension was incorporated into the updated plan and executed as written.

## Issues Encountered

- The first retry implementation retained a derived `unavailable` list marker after rows recovered. The component now recomputes render state after retry, and the regression proves recovery to populated state.
- Tests inject deterministic `DBConnection.ConnectionError` failures through the existing fixture query and a test-only read-failure fixture; no live database outage or provider API was used.
- `roadmap.update-plan-progress` did not recognize the existing Phase 238 heading; the completed 238-02 checklist entry was updated directly.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs` — passed (68 tests, 0 failures).
- `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs` — passed (21 tests, 0 failures).
- `git diff --check` — clean.

## User Setup Required

None - no external service configuration or provider API calls are required.

## Next Phase Readiness

ADM-07 evidence and replay surfaces are ready for the remaining Phase 238 billing inspection work. No unresolved issue remains for this plan.

---
*Phase: 238-admin-events-webhooks-remaining-billing-surfaces*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary exists at the expected phase path.
- All three task commits and the plan extension commit are ancestors of the current HEAD.
