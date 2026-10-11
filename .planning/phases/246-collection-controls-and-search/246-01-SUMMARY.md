---
phase: 246-collection-controls-and-search
plan: "01"
subsystem: ui
tags: [phoenix-liveview, filters, invoices, accessibility, playwright]
requires:
  - phase: 245-rendered-baseline-and-realistic-preview
    provides: Ordinary mounted preview host and protected baseline separation
provides:
  - Canonical multi-status invoice controls wired through owner-scoped query results
  - Shared visible filter labels, secondary categorical disclosure, constraint chips, and scoped reset
  - Mounted browser proof of invoice status, URL, Unicode search, reload, and history alignment
affects: [246-02, 246-03, 246-04, shared-data-table, invoice-filters]
actuals:
  tokens: 9286
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 5afc63b12753cdfe8c93f0503eaa0b3f6cfee735
plan_head_after: f3e6ea01892d7e44fa5b79341e948456032767a8
tech-stack:
  added: []
  patterns:
    - Checkbox groups serialize a canonical status set while preserving owner scope and unrelated criteria.
    - Constraint removal merges the remaining query parameters with the canonical owner-scoped route.
key-files:
  created:
    - examples/accrue_host/e2e/phase246-invoice-filters.spec.js
    - examples/accrue_host/playwright.phase246.config.js
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/queries/invoices.ex
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
key-decisions:
  - "Treat the invoice queue/all choice as view navigation and render only actual filter constraints as chips."
  - "Clearing the final status checkbox selects the All view so the default queue does not immediately reapply itself."
  - "Reset preserves the selected view and owner scope while removing query constraints."
patterns-established:
  - "Checkbox-group filter fields use a visible legend and serialize repeated values under the array field name."
  - "Secondary categorical filters are marked on their field definitions and rendered in a native Filters disclosure."
requirements-completed: []
coverage:
  - id: FILTER-02-invoices
    description: Invoice status controls, canonical URL, owner-scoped query and visible rows agree on mounted interactions.
    requirement: FILTER-02
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/invoices_live_test.exs
        status: pass
      - kind: e2e
        ref: examples/accrue_host/e2e/phase246-invoice-filters.spec.js
        status: pass
    human_judgment: false
  - id: FILTER-01-invoices
    description: Invoice views are separate from labeled constraints with accessible removal and one scoped reset.
    requirement: FILTER-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/data_table_test.exs and accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/invoices_live_test.exs
        status: pass
    human_judgment: true
    rationale: Automated checks verify markup and target sizing rules, while visual hierarchy and responsive touch affordance still need human inspection.
metrics:
  duration: 19m
  completed: 2026-10-11
  status: complete
---

# Phase 246 Plan 01: Invoice Status and Shared Filter Controls Summary

**Invoices now connect canonical multi-status controls to owner-scoped rows, with shared labeled filters and removable constraints that preserve view and query state.**

## Performance

- **Duration:** 19 minutes
- **Started:** 2026-10-11T16:20:00Z
- **Completed:** 2026-10-11T16:39:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added invoice status checkbox controls with default Open + Uncollectible selection, stable status ordering, and URL/query/result agreement.
- Separated queue/all view navigation from actual constraint chips and added visible labels, a secondary Filters disclosure, accessible 44px removal targets, and one scope-preserving reset.
- Added mounted browser coverage for status changes, Unicode search, URL state, reload, and back/forward history against the ordinary Phase 245 preview host.

## Verification

- RED evidence for Task 246-01-01: the new default-status test failed because the invoice filter toolbar initially rendered no checkbox controls.
- GREEN: `mix test test/accrue_admin/live/invoices_live_test.exs` — 17 tests, 0 failures.
- RED evidence for Task 246-01-02: the new chip test failed because the remove action rendered “Clear” instead of an X; the LiveView test also found no visible status-field label.
- GREEN: `mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/live/invoices_live_test.exs` — 59 tests, 0 failures.
- Mounted browser verification against `http://accrue-host-phase245-ordinary.localhost/` — 1 test passed, covering selection, query rows, Unicode text, reload, and browser history.
- `gsd_run check evaluation-scope --plan 246-01 --commits-only --raw` resolved the plan and found four reachable task commits.
- No full-project suite or held-out Phase 246 visual probe was run; the latter remains assigned to Plan 04.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Clearing all invoice statuses now selects the All view**
- **Found during:** Task 246-01-01
- **Issue:** An empty status selection would fall through to the default queue and immediately reselect Open + Uncollectible.
- **Fix:** Preserve the existing query path and set `view=all` when no status remains selected.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex`
- **Commit:** `e20d12f8`

**2. [Rule 2 - Missing accessibility behavior] Added visible and touch-sized filter controls**
- **Found during:** Task 246-01-02
- **Issue:** Shared text/select labels were visually hidden and the chip action did not meet the 44px target contract.
- **Fix:** Render visible labels and a 44px X link with a clear accessible name and visible keyboard focus.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`, `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex`, `accrue_admin/assets/css/app.css`
- **Commit:** `f3e6ea01`

## Known Stubs

None found in files created or modified by this plan.

## Self-Check: PASSED

- All created browser-spec files and the summary exist on disk.
- All four task commits are reachable from the plan baseline on the current branch.
- Task acceptance criteria and plan verification were rerun successfully.
