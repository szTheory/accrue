---
phase: 242-investigations-and-remaining-admin-surfaces
plan: 01
subsystem: admin-events
tags: [phoenix-liveview, scoped-paths, owner-scope, event-ledger]
requires:
  - phase: 241-billing-operator-journeys
    provides: Established Admin route, query, owner-scope, and test conventions
provides:
  - Validated return paths across events, webhooks, coupons, promotion codes, and Connect accounts
  - Event list to detail to filtered-list navigation with paired path and label
  - Owner-verified event source and typed-subject links
affects: [242-02, 242-03, 242-04, admin-navigation]
actuals:
  tokens: 4790
  tasks: 2
  commits: 2
plan_head_before: 6a621d17d97a985fb1542a23c24dbf7794ab625e
plan_head_after: 3daeeaa329b301f803db9f9cc50ead22c8d42af3
tech-stack:
  added: []
  patterns:
    - Destination-owned decoding and encoding validates preserved return filters
    - Related-resource hrefs are emitted only after current-owner identity proof
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/test/accrue_admin/scoped_path_test.exs
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/test/accrue_admin/queries/events_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
key-decisions:
  - "Each return family validates filters through its existing query decoder and encoder, then rebuilds with the active owner scope."
  - "Event detail relationships require an owner-scoped exact identity match before rendering a usable link."
patterns-established:
  - "Paired return destination: validate one local route, then expose its rebuilt path and family label together."
requirements-completed: [JRN-05, JRN-06]
coverage:
  - id: D1
    description: "Safe filtered returns for five admin list families, including event list/detail navigation."
    requirement: JRN-05
    verification:
      - kind: integration
        ref: "cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/events_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Event filter membership and owner-verified event detail relationships."
    requirement: JRN-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/queries/events_test.exs test/accrue_admin/live/event_live_test.exs"
        status: pass
    human_judgment: false
human_judgment: false
duration: 8min
completed: 2026-10-10
status: complete
---

# Phase 242 Plan 01: Event Returns and Evidence Summary

**Events now preserve validated list filters through detail navigation, and related records only link when their exact identity remains accessible under the active owner.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-10T12:35:00Z
- **Completed:** 2026-10-10T12:43:09Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Extended the finite return route contract to Events, Webhook Deliveries, Coupons, Promotion Codes, and Connect accounts. Each family retains only consumed, valid filters and regenerates owner scope from the current session.
- Wired event rows to carry their validated filtered-list origin; EventLive renders the paired safe return path and label.
- Verified source delivery and typed-subject records under the current owner before rendering links, while preserving event facts and lazy payload/activity evidence.
- Added tests for malformed/duplicate/oversized returns, decoder/encoder filter parity, and actual event-row membership for q, type, actor_type, subject_type, and source_webhook_event_id.

## Task Commits

1. **Task 1: Prove an event list to detail and back through ScopedPath** — `959e45ab` (`feat`)
2. **Task 2: Make event detail evidence and relationships truthful** — `3daeeaa3` (`fix`)

## Verification Results

- Task 1: `MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/events_live_test.exs` — **27 tests, 0 failures**.
- Task 2: `MIX_ENV=test mix test test/accrue_admin/queries/events_test.exs test/accrue_admin/live/event_live_test.exs` — **17 tests, 0 failures**.
- `git diff --check` passed before task commits; repository commit hooks passed for both task commits.
- No browser visual capture or physical-device check was performed. Phase 242 Plan 07 owns the bounded visual inspection; this summary makes no claim about those checks.

## Deviations from Plan

None. The owner-scoped relation checks implement the task's explicit authorization requirement.

## Deferred Evidence

Mounted browser visual inspection and measured viewport/theme/text-stress checks remain with Phase 242 Plan 07. Automated LiveView and query assertions above are the evidence for this plan.

## Self-Check: PASSED

- All seven modified product/test files exist.
- Both task commits are present in the measured plan range `6a621d17d97a985fb1542a23c24dbf7794ab625e..3daeeaa329b301f803db9f9cc50ead22c8d42af3`.
- The two task acceptance commands passed with nonzero selected test counts.
