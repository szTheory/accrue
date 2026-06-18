---
phase: 190-navigation-data-display-meta-component-cohesion
plan: 190-03
subsystem: ui
tags: [phoenix-liveview, data-display, component-contracts, css, exunit]
dependency_graph:
  requires:
    - 190-02 registry-driven component group proof surfaces
    - 190-CONTEXT navigation and data-display cohesion goals
    - 190-UI-SPEC responsive data-display and detail rhythm requirements
    - 190-PATTERNS component group locator and tokenized CSS guidance
  provides:
    - DataTable group root and contextual selection accessibility labels
    - AtRiskTable mobile-card rendering with loading, error, empty, and pagination states
    - KPI/detail group locators with unframed detail sections and long-metadata wrapping
  affects:
    - phase-190
    - phase-191
    - phase-192
    - admin-ui
    - data-display-components
tech_stack:
  added: []
  patterns:
    - static data-component-group locators on component group roots
    - responsive desktop-table and mobile-card split using tokenized CSS breakpoints
    - detail page rhythm with framed summary cards, unframed sections, and repeated-item cards only
key_files:
  created:
    - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
    - .planning/phases/190-navigation-data-display-meta-component-cohesion/190-03-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
    - accrue_admin/lib/accrue_admin/components/kpi_card.ex
    - accrue_admin/lib/accrue_admin/components/detail.ex
    - accrue_admin/test/accrue_admin/components/display_components_test.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
key_decisions:
  - DataTable selection controls derive aria labels from row content so keyboard and screen reader users receive contextual row actions.
  - AtRiskTable accepts optional amount fields while preserving existing recovery-row call sites that do not yet expose invoice amounts.
  - Detail sections are intentionally unframed so detail pages avoid nested card framing while summary headers remain framed.
requirements_completed: [GRP-02, GRP-03, GRP-04]
metrics:
  started: 2026-06-18T15:47:00Z
  completed: 2026-06-18T15:57:32Z
  duration: 10m32s
  task_count: 3
  file_count: 10
status: complete
---

# Phase 190 Plan 03: Navigation/Data Display Component Cohesion Summary

Data display primitives now expose stable group locators, responsive table/card states, accessible selection labels, and detail-page rhythm that avoids nested card framing.

## What Changed

- Added `data-component-group="table-empty-loading-error-pagination"` to DataTable and covered the table group states with focused component tests.
- Added contextual `aria-label` values to DataTable desktop and mobile row-selection controls so selection is not announced as an anonymous checkbox.
- Added an AtRiskTable component contract covering desktop table rows, mobile cards, loading, error, empty, and cursor pagination states.
- Added tokenized AtRiskTable responsive CSS and rebuilt `priv/static/accrue_admin.css`.
- Added opt-in KPI group locators for KPI/chart/table compositions.
- Added the detail header group locator, kept detail sections unframed, preserved related-resource item rhythm, and hardened summary metadata wrapping.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 RED | Failing DataTable contract tests | dc02ee3f | `accrue_admin/test/accrue_admin/components/data_table_test.exs` |
| 1 GREEN | Tighten DataTable display contract | 99db7233 | `accrue_admin/lib/accrue_admin/components/data_table.ex` |
| 2 RED | Failing AtRiskTable contract tests | 0beaa326 | `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` |
| 2 GREEN | AtRiskTable mobile/state contract | a4c4700f | `accrue_admin/lib/accrue_admin/components/at_risk_table.ex`, `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`, `accrue_admin/test/accrue_admin/components/at_risk_table_test.exs` |
| 3 RED | Failing display rhythm tests | 59bd6b6f | `accrue_admin/test/accrue_admin/components/display_components_test.exs` |
| 3 GREEN | Display group rhythm | c4a029e5 | `accrue_admin/lib/accrue_admin/components/kpi_card.ex`, `accrue_admin/lib/accrue_admin/components/detail.ex`, `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css` |

## Verification

- Task 1 RED: `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` failed as expected before implementation with missing table group root and contextual row-selection labels.
- Task 1 GREEN: `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` passed with `10 tests, 0 failures`.
- Task 2 RED: `cd accrue_admin && MIX_ENV=test mix run --no-start -e 'ExUnit.start(); Code.require_file("test/accrue_admin/components/at_risk_table_test.exs")'` failed as expected with missing AtRiskTable group locator, mobile cards, state rendering, pagination, and CSS selectors.
- Task 2 GREEN: `cd accrue_admin && MIX_ENV=test mix run --no-start -e 'ExUnit.start(); Code.require_file("test/accrue_admin/components/at_risk_table_test.exs")'` passed with `3 tests, 0 failures`.
- Task 2 standard test: `cd accrue_admin && mix test test/accrue_admin/components/at_risk_table_test.exs` passed with `3 tests, 0 failures`.
- Task 2 assets: `cd accrue_admin && mix accrue_admin.assets.build` passed and rebuilt served admin assets.
- Task 3 RED: `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs` failed as expected before implementation with missing KPI and detail-header group locators.
- Task 3 no-start check: `cd accrue_admin && MIX_ENV=test mix run --no-start -e 'ExUnit.start(); Code.require_file("test/accrue_admin/components/display_components_test.exs")'` passed with `12 tests, 0 failures`.
- Task 3 standard test: `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs` passed with `12 tests, 0 failures`.
- Plan-level component tests: `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/at_risk_table_test.exs test/accrue_admin/components/display_components_test.exs` passed with `25 tests, 0 failures`.
- Package docs guard: `bash scripts/ci/verify_package_docs.sh` passed.
- Final assets: `cd accrue_admin && mix accrue_admin.assets.build` passed and left the worktree clean.

## Acceptance Criteria

- DataTable exposes a stable `table-empty-loading-error-pagination` group root without moving pagination/filter/sort behavior out of the existing LiveComponent contract.
- DataTable selection controls preserve bulk and row selection behavior while adding contextual accessible names.
- AtRiskTable renders desktop table and mobile card surfaces from the same row data, with distinct loading, error, empty, no-pagination, and has-pagination states.
- AtRiskTable CSS uses existing admin design tokens and breakpoint comments, and the served static CSS artifact includes the responsive card/table rules.
- KPI cards can participate in the `kpi-chart-table` group without forcing every KPI to emit that locator.
- Detail summary headers expose `detail-header-metadata-actions`, long metadata can wrap, and nested detail content avoids decorative card-in-card framing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized string currency codes before money formatting**
- **Found during:** Task 2 GREEN.
- **Issue:** AtRiskTable rows can provide currency as a binary string, while `Accrue.Invoices.Render.format_money/3` expects a normalized currency value.
- **Fix:** Added currency normalization in the AtRiskTable amount formatter so optional row amount fields render reliably.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex`
- **Verification:** AtRiskTable component tests passed in both no-start and standard test modes.
- **Commit:** a4c4700f

---

**Total deviations:** 1 auto-fixed Rule 1 issue.
**Impact on plan:** The fix stayed inside the planned AtRiskTable display contract and did not add new data sources or query behavior.

## Issues Encountered

- Local PostgreSQL remained saturated by unrelated long-lived processes. Focused test runs intermittently logged `FATAL 53300 (too_many_connections) sorry, too many clients already`; one standard Task 3 attempt failed during `test_helper` boot, then the no-start component check passed and the standard focused retry passed. No unrelated processes were stopped.

## Known Stubs

| File | Line | Reason |
| ---- | ---- | ------ |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | 186, 197 | Intentional `Amount unavailable` fallback for existing recovery-row call sites that do not provide optional amount fields yet. It preserves component rendering while still displaying amounts when rows include `amount_due_minor` and `currency`. |

## Threat Flags

None. This plan changed component rendering, component tests, tokenized CSS, and static assets only; it did not introduce network endpoints, auth paths, file access patterns, schema changes, or new trust-boundary behavior.

## Auth Gates

None.

## Deferred Issues

None.

## Self-Check: PASSED

- Confirmed `190-03-SUMMARY.md` exists at the expected phase path.
- Confirmed all plan-modified source, test, CSS, and static asset files exist.
- Confirmed task commits are reachable: `dc02ee3f`, `99db7233`, `0beaa326`, `a4c4700f`, `59bd6b6f`, `c4a029e5`.
- Confirmed `git diff --check` reports no whitespace errors for the summary.
- Confirmed the only untracked file before state updates was `190-03-SUMMARY.md`.
