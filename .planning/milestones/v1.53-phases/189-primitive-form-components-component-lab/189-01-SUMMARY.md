---
phase: 189-primitive-form-components-component-lab
plan: 01
subsystem: ui
tags: [css, component-registry, component-lab, state-matrix, theme, dark-mode]

# Dependency graph
requires:
  - phase: 188-foundations-hardening
    provides: semantic tokens (--ax-status-*, --ax-disabled-*, --ax-focus-ring), focus-visible consolidated block, z-index layer stack
provides:
  - ".ax-dev-state-grid CSS layout (2-column light/dark grid, cell padding, n/a styling, mobile collapse)"
  - ".accrue-admin [data-theme='dark'] sub-tree CSS selector with FULL dark token set (D-07 CSS prerequisite)"
  - "ComponentRegistry schema extension: applicable_states/na_states/specimens on button×4 and status×5 entries"
  - "Structural data-contract tests (e) and (f) for registry schema enforcement"
affects: [189-02, 189-03, 189-04, 189-05, 189-06, 189-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sub-tree theme selector pattern: .accrue-admin [data-theme='dark'] re-scopes --ax-* tokens for column-level dark rendering (standard Radix/Primer pattern)"
    - "Registry state-matrix schema: applicable_states / na_states / specimens three-field contract on each component family entry"
    - "Structural data-contract test pattern: assert registry shape without mounting the page (mount assertions deferred to Plan 03 test (g))"

key-files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/assets/css/theme.css
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/test/accrue_admin/dev/component_registry_test.exs

key-decisions:
  - "D-07 CSS gate: sub-tree selector with FULL dark token set verbatim-copied from the existing html.accrue-admin[data-theme='dark'] block; browser-level color delta verified in Plan 06 (themeColumnDeltaProbe), NOT marked fully resolved here"
  - "Structural tests (e) and (f) are data-contract-only (no page mount); HTML mount assertions for data-ax-state and data-theme attributes are Plan 03 test (g)"
  - "Status badge na_states: all 9 non-applicable states carry the same reason 'non-interactive display element — no interactive state applies' per UI-SPEC"
  - "Button specimens include long-label overflow specimen ('Export all subscription events to CSV') satisfying D-06 overflow requirement"

patterns-established:
  - "State-matrix schema: every component family added to the lab must include applicable_states (list), na_states (list of %{state, reason}), and specimens (list of %{label, props, content})"
  - "Sub-tree theme scoping: add new theme selectors BETWEEN the existing html.accrue-admin[data-theme='dark'] block and the @media (prefers-color-scheme: dark) block"

requirements-completed: [CMP-01, CMP-02]

# Metrics
duration: 3min
completed: 2026-06-17
---

# Phase 189 Plan 01: CSS State-Grid Layout + ComponentRegistry Schema Extension Summary

**.ax-dev-state-grid two-column CSS grid with D-07 sub-tree dark selector, plus ComponentRegistry applicable_states/na_states/specimens schema for button and status families with 6 passing structural tests**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-17T21:06:24Z
- **Completed:** 2026-06-17T21:09:30Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added the complete `.ax-dev-state-grid` CSS block to `app.css`: 2-column grid layout, per-cell padding (`--ax-space-md`), n/a cell styling (`--ax-sunken` bg, 0.6 opacity), and `@media (max-width: 599.98px)` collapse to 1 column for mobile
- Added the `.accrue-admin [data-theme="dark"]` sub-tree selector to `theme.css` with the FULL verbatim dark token set (all `--ax-*` variables including `color-scheme: dark`), placed after the existing `html.accrue-admin[data-theme="dark"]` block and before the `@media (prefers-color-scheme: dark)` block — this is the D-07 CSS prerequisite for column-level dark token re-scoping
- Extended all 4 button entries and all 5 status/badge entries in `ComponentRegistry` with three new fields: `applicable_states`, `na_states`, and `specimens`, per the UI-SPEC specimen contracts
- Added structural tests (e) and (f) to `component_registry_test.exs` — data-contract-only assertions that verify registry shape without mounting the page; all 6 registry tests pass (4 existing + 2 new)

## Task Commits

1. **Task 1: Add .ax-dev-state-grid CSS to app.css and sub-tree dark selector to theme.css** - `384f918a` (feat)
2. **Task 2: Extend ComponentRegistry schema for button + status families; add structural tests (e) and (f)** - `4d05eeb1` (feat)

## Files Created/Modified

- `accrue_admin/assets/css/app.css` — added `.ax-dev-state-grid` block (grid, col, col-header, cell, cell-na rules + mobile media query)
- `accrue_admin/assets/css/theme.css` — added `html.accrue-admin [data-theme="dark"], .accrue-admin [data-theme="dark"]` sub-tree selector with FULL dark token set
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — extended @type entry, updated @doc, added applicable_states/na_states/specimens to button×4 and status×5 entries
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — added structural tests (e) and (f)

## Decisions Made

- **D-07 partial**: The sub-tree CSS selector is the necessary CSS prerequisite for the dark column to re-scope tokens. Browser-level resolved-color delta (getComputedStyle assertion) is Plan 06's `themeColumnDeltaProbe` — D-07 is NOT marked fully resolved here.
- **Tests (e) and (f) are data-contract-only**: They assert registry map shape (`Map.has_key?` checks) without mounting the LiveView page. This matches the plan directive and keeps the tests fast and focused on structural correctness. Mounted-page HTML assertions for `data-ax-state` and `data-theme` attributes belong in Plan 03 (test (g)), after the renderer exists.
- **Status badge na_states rationale**: All 9 non-applicable states for status/badge entries share the same reason string ("non-interactive display element — no interactive state applies") per the UI-SPEC contract.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- CSS grid foundation ready for Plan 03 lab renderer (`.ax-dev-state-grid` + `.ax-dev-state-grid-col` + `.ax-dev-state-cell`)
- Sub-tree dark selector ready for Plan 03 two-column rendering (column `data-theme="dark"` will now genuinely re-scope `--ax-*` tokens)
- Registry entries ready for Plan 03 renderer consumption (`applicable_states`, `na_states`, `specimens` fields all populated and test-verified)
- D-07 browser-level sign-off deferred to Plan 06 `themeColumnDeltaProbe`

## Self-Check

Files exist:
- `accrue_admin/assets/css/app.css` — FOUND (modified)
- `accrue_admin/assets/css/theme.css` — FOUND (modified)
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — FOUND (modified)
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — FOUND (modified)

Commits exist:
- `384f918a` — feat(189-01): add .ax-dev-state-grid CSS and sub-tree dark selector — FOUND
- `4d05eeb1` — feat(189-01): extend ComponentRegistry with state-matrix schema; add structural tests — FOUND

## Self-Check: PASSED

---
*Phase: 189-primitive-form-components-component-lab*
*Completed: 2026-06-17*
