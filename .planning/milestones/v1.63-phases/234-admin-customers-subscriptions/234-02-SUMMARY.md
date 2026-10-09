---
phase: 234-admin-customers-subscriptions
plan: "02"
subsystem: ui
tags: [phoenix-liveview, admin, owner-scope, search]

requires:
  - phase: 233-shared-direction-portal-contract
    provides: Shared Admin visual roles, mount behavior, and owner-scope contracts
provides:
  - Bounded Home activity sourced from the current owner scope
  - Global search with explicit partial-failure and no-match states
  - Generation-checked asynchronous search replies tied to current query and owner scope
affects: [234-03, admin-home, global-search]

actuals:
  tokens: 16077
  tasks: 2
  commits: 2
  plan_head_before: 65f9e9a3144eab50d01a98156c471a40cd645910
  plan_head_after: 39ca340191667a8b61fd167f0ca04f9cb35a45be
commits: 2
plan_head_before: 65f9e9a3144eab50d01a98156c471a40cd645910
plan_head_after: 39ca340191667a8b61fd167f0ca04f9cb35a45be

tech-stack:
  added: []
  patterns:
    - Async LiveComponent searches accept replies only when query, scope, and generation still match
    - Home previews use bounded owner-scoped event queries and same-scope destinations

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/lib/accrue_admin/components/global_search.ex
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
    - accrue_admin/test/accrue_admin/components/global_search_test.exs

key-decisions:
  - "Home shows bounded scoped audit activity and navigation; unsupported global health, count, and amount claims were removed."
  - "Global search remains a three-group, five-result preview and states actual match fields, exact IDs, and partial lookup failure."

patterns-established:
  - "Invalidate search state on query or scope changes; discard async replies with an obsolete generation."
  - "Keep successful search groups available and provide a safe retry when another lookup fails."

requirements-completed: [ADM-03, SAFE-01, ADM-01]
coverage:
  - id: D1
    description: Home presents bounded audit activity and destinations under the same active owner scope, without unsupported aggregate claims.
    requirement: ADM-03
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Search communicates supported fields, exact IDs, partial failure, no matches, and rejects stale query or owner-scope replies.
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/global_search_test.exs
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-10-07
status: complete
---

# Phase 234 Plan 02: Factual Home and Bounded Global Search Summary

**Home now presents bounded owner-scoped audit activity, while global search reports supported match fields and keeps partial failures distinct from no matches.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-08T00:43:58Z
- **Completed:** 2026-10-08T00:50:37Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Replaced global Home aggregates and health language with a six-row owner-scoped event preview and same-scope customer, subscription, and event-ledger destinations.
- Kept the three existing search query modules and five-row group limits; results now load asynchronously and stale query/scope generations are ignored.
- Search now names each query’s supported fields, displays readable identity and exact IDs, retains successful groups on partial failure, and offers a safe retry.

## Task Commits

1. **Task 1: Give Home factual, scope-matched observations** — `12d5dac5` (fix)
2. **Task 2: Distinguish bounded search results from failure and stale state** — `39ca3401` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — bounded scoped audit preview; removed unscoped or unsupported summary claims.
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — explicit async result states, accurate field copy, identity disambiguation, and generation checks.
- `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` — default Home and two-owner scope controls.
- `accrue_admin/test/accrue_admin/components/global_search_test.exs` — field copy, partial failure, exact identity, and stale reply/scope controls.

## Decisions Made

- Home uses the established bounded `Events.list/1` query. Billing counts, mixed-currency exposure, webhook status, and health claims were removed because their existing aggregate paths could not meet the scoped and bounded contract.
- Search stays a bounded preview; it does not claim broader list handoff semantics that the list filters cannot preserve.

## Deviations from Plan

### Process deviation

**1. Task 1 scope-control tests were added after the first implementation instead of preceding it in a RED-first cycle.**
- **Found during:** Task 1
- **Issue:** The mounted Home positive/foreign-scope tests did not exist before the first implementation edit.
- **Fix:** Added the tests, corrected an interim LiveView integration error, and reran the focused mounted suite successfully.
- **Files modified:** `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` — 2 tests, 0 failures.
- **Recorded in:** `.planning/WINDOWS.md` entry 15.

**Total deviations:** 1 process deviation.  
**Impact on plan:** Product scope and planned deliverables are complete; the final Home and search verification suites pass.

## Issues Encountered

- Existing Home tests asserted the unsupported global health verdict and unscoped aggregates. They were replaced with assertions for factual scoped activity and a positive/foreign organization control.
- An interim test run found an invalid LiveComponent call in the new Home markup; removing the duplicate component mount resolved it before Task 1 was committed.
- `gsd_run query roadmap.update-plan-progress 234` declined with `missing_phase_details` and left ROADMAP.md unchanged, despite the visible Phase 234 checklist and progress row. The SDK reported no writable phase entry.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` — **2 tests, 0 failures**.
- `cd accrue_admin && mix test test/accrue_admin/components/global_search_test.exs` — **14 tests, 0 failures**.
- `git diff --check` — passed.

## User Setup Required

None.

## Next Phase Readiness

The Home and global search entry points now provide scoped, bounded investigation paths for the remaining customer and subscription work in Phase 234.

The ROADMAP progress row remains at its prior 1/7 value because the registered updater declined to write; the summary count on disk is 2/7.

---
*Phase: 234-admin-customers-subscriptions*
*Completed: 2026-10-07*

## Self-Check: PASSED

- All four key files exist.
- Task commits `12d5dac5` and `39ca3401` are ancestors of HEAD.
- `gsd check evaluation-scope --plan 234-02 --commits-only` resolved both task commits on this branch.
