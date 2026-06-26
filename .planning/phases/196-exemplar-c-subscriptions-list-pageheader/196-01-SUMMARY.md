---
phase: 196-exemplar-c-subscriptions-list-pageheader
plan: "01"
subsystem: ui-testing
tags: [phoenix-liveview, exunit, playwright, pageheader, subscriptions, list-contract]

requires:
  - phase: 196-exemplar-c-subscriptions-list-pageheader
    provides: Phase context, research, UI spec, and validation strategy for Subscriptions LIST/PageHeader contracts
provides:
  - RED PageHeader component contract coverage
  - RED Subscriptions LIST LiveView contract coverage
  - Phase 196 Playwright LIST contract and npm script
affects: [phase-196, phase-197, subscriptions-list, pageheader, data-table, filter-chip-bar]

tech-stack:
  added: []
  patterns: [RED validation scaffolding, focused ExUnit contracts, Playwright browser contract]

key-files:
  created:
    - accrue_admin/test/accrue_admin/components/page_header_test.exs
    - accrue_admin/e2e/admin-spec-list-phase196.spec.js
  modified:
    - accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/package.json

key-decisions:
  - "Wave 0 stayed test-only: no PageHeader/DataTable/Subscriptions runtime behavior was implemented in this plan."
  - "Phase 196 propagation coverage is scoped to Subscriptions; broader LIST rollout remains Phase 197 work."
  - "Owner-scope clear-all is asserted in LiveView tests with an authorized organization session; Playwright uses existing e2e login/reset/seed helpers without adding new test-support routes."

patterns-established:
  - "PageHeader contracts assert slots and markers while explicitly rejecting query/filter/table/AppShell/flash ownership."
  - "LIST contracts use data-ax markers for chips, counts, clear-all, list state, empty reason, and loading skeleton accessibility."
  - "Phase e2e scripts target a single Playwright spec with existing single-worker timeout conventions."

requirements-completed: [EXE-03, PGH-01]

duration: 13min
completed: 2026-06-26
status: complete
---

# Phase 196 Plan 01: Wave 0 Validation Scaffolding Summary

**Executable RED contracts for the Subscriptions LIST exemplar and stateless PageHeader slot API.**

## Performance

- **Duration:** 13min
- **Started:** 2026-06-26T20:35:26Z
- **Completed:** 2026-06-26T20:48:09Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added PageHeader component tests for required attrs, optional attrs, caller-owned slots, semantic markers, one content `h1`, and no state/query/table ownership.
- Extended FilterChipBar and DataTable component contracts for Phase 196 chip/count/clear markers, LIST state markers, empty reasons, skeleton accessibility, no fake production delay, and an external filter toolbar seam.
- Added SubscriptionsLive RED coverage for PageHeader adoption, default At risk queue behavior, owner-scope clear-all, result/count/chip markers, list states, column priority, and raw ID de-emphasis.
- Added `admin-spec-list-phase196.spec.js` plus `npm run e2e:phase196` for desktop/mobile browser checks across PageHeader, chips, states, columns, mobile cards, and loading skeleton accessibility.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add RED PageHeader and component primitive contracts** - `5c262c15` (test)
2. **Task 2: Add RED SubscriptionsLive LIST contract coverage** - `cc51f83a` (test)
3. **Task 3: Add Phase 196 Playwright spec and npm script** - `d70e627f` (test)

## Files Created/Modified

- `accrue_admin/test/accrue_admin/components/page_header_test.exs` - New PageHeader contract tests for PGH-01 and D-01/D-02/D-03/D-18.
- `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs` - Added Phase 196 chip row, result count, and clear-all marker assertions.
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` - Added LIST state marker, empty reason, loading skeleton, reduced-motion, no fake delay, and filter toolbar API contracts.
- `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` - Added Subscriptions LIST and PageHeader RED coverage, including organization-scope clear-all.
- `accrue_admin/e2e/admin-spec-list-phase196.spec.js` - New Phase 196 Playwright browser contract.
- `accrue_admin/package.json` - Added `e2e:phase196` script pointing at the Phase 196 spec.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs --max-failures 1` - RED as expected: missing `lib/accrue_admin/components/page_header.ex` / `AccrueAdmin.Components.PageHeader.page_header/1`.
- `cd accrue_admin && mix test test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/data_table_test.exs --max-failures 3` - RED as expected: missing `data-ax-filter-chips`, `data-ax-list`, `data-ax-state`, and `DataTable.filter_toolbar/1`.
- `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs --max-failures 3` - RED as expected: Subscriptions runtime lacks PageHeader/LIST markers and owner-scope clear-all marker.
- `cd accrue_admin && node -e "const p=require('./package.json'); if(!p.scripts['e2e:phase196'] || !p.scripts['e2e:phase196'].includes('e2e/admin-spec-list-phase196.spec.js')) process.exit(1)"` - PASS.
- `cd accrue_admin && npm run e2e:phase196` - RED as expected: both Chromium projects start and fail on missing `data-ax-page-header`, `data-ax-filter-chips`, and `data-ax-list` markers.

## Decisions Made

- Kept the plan as Wave 0 validation scaffolding only; no runtime implementation was added.
- Used existing e2e reset/seed/login helpers and Phase 191 viewport/theme helpers rather than creating new browser fixture infrastructure.
- Kept owner-scope proof in LiveView where the existing test harness can establish an authorized organization session.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `accrue_admin/e2e/admin-spec-dashboard.spec.js` was listed as read-first context but does not exist in this tree. Active Phase 194/195 specs and the shared Phase 191 helper supplied the local Playwright pattern.
- Expected RED verification produces Playwright trace/screenshot artifacts under `accrue_admin/test-results/`; these are ignored runtime outputs and were not committed.

## Known Stubs

None. Stub scan found only test literals for HTML empty attributes and placeholder labels; no created or modified file contains a production stub that blocks the plan goal.

## Auth Gates

None.

## Next Phase Readiness

Plans 196-02 through 196-05 can now implement against executable RED coverage for PageHeader, Subscriptions LIST states, chip/count/clear behavior, loading skeleton accessibility, column priority, and the Phase 196 browser matrix.

## Self-Check: PASSED

- Found all six created/modified files.
- Found task commits `5c262c15`, `cc51f83a`, and `d70e627f`.
- No accidental tracked deletions were detected after task commits.

---
*Phase: 196-exemplar-c-subscriptions-list-pageheader*
*Completed: 2026-06-26*
