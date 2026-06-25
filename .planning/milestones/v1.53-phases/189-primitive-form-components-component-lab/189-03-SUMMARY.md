---
phase: 189-primitive-form-components-component-lab
plan: 03
subsystem: ui
tags: [phoenix-liveview, component-registry, state-matrix, design-system, ax-css, kitchen]

# Dependency graph
requires:
  - phase: 189-01
    provides: ComponentRegistry 7-field schema, structural tests (e) and (f)
  - phase: 189-02
    provides: 8 primitive Phoenix.Component modules (Textarea, Checkbox, Radio, Toggle, Spinner, Tooltip, EmptyState, InlineId)
provides:
  - ComponentRegistry with all 14 Phase-189 primitive family entries (7-field schema)
  - ComponentKitchenLive registry-driven two-column state-matrix renderer
  - data-theme="light"/data-theme="dark" column wrappers (D-07 HTML-attribute layer)
  - data-ax-state attributes for all applicable states per family
  - data-ax-na-reason attributes for all n/a states
  - Test (g): mounted-page HTML assertion for data-theme and data-ax-state
affects: [189-04, 189-05, 189-06, 189-07, phase-190, phase-191, phase-192]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Registry-driven state-matrix renderer: Enum.group_by(entries, family) → two-column light/dark grid"
    - "Theme-scoped element IDs: '#{theme}-#{component}-#{state}' ensures LiveView uniqueness across light/dark columns"
    - "render_specimen/3 private function dispatches component by family+state+theme with pattern matching"
    - "ax_class second token must be an actual CSS class rendered by the component (test (a) contract)"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
    - accrue_admin/test/accrue_admin/dev/component_registry_test.exs

key-decisions:
  - "ax_class second token must be an actual rendered CSS class (ax-field-control, ax-checkbox, etc.) so test (a) string-match passes without renderer workarounds"
  - "Theme-scoped element IDs (light-/dark- prefix + state) prevent LiveView duplicate-id RuntimeError when same component renders in both columns"
  - "Card entries (no applicable_states) retain a separate token-reference dl so test (d) can verify card registry tokens appear in the rendered HTML"
  - "D-07 HTML-attribute layer is proven by test (g); browser-level resolved-color delta deferred to Plan 06 themeColumnDeltaProbe"
  - "render_specimen/3 accepts theme parameter so ID-scoping is data-driven, not hardcoded per column"
  - "Fallback do_render_specimen/4 clause renders a text label for any unmatched family+state pair (graceful degradation)"

patterns-established:
  - "Registry-driven matrix: filter applicable_states entries → group_by family → render two-column grid per group"
  - "Theme column IDs: always prefix with theme name to guarantee uniqueness across the two-column layout"
  - "Token reference dl included in each family section so existing test (d) token-in-HTML contract is satisfied"

requirements-completed: [CMP-01, CMP-02, CMP-03]

# Metrics
duration: 25min
completed: 2026-06-17
---

# Phase 189 Plan 03: Registry-Driven State-Matrix Renderer Summary

**ComponentRegistry extended to all 14 Phase-189 primitive families with 7-field schema; ComponentKitchenLive converted to a registry-driven two-column state-matrix renderer emitting genuine data-theme scoped columns and data-ax-state cell attributes, verified by all 7 registry tests including new test (g)**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-17T21:20:00Z
- **Completed:** 2026-06-17T21:45:34Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Extended ComponentRegistry with 12 new Phase-189 primitive family entries (input, textarea, checkbox, radio, toggle, select, form-field, icon, money, json-viewer, spinner, tooltip, inline-id, empty-state) on top of the existing button (4) and status (5) entries — all with applicable_states, na_states (each with non-empty reason), and specimens (each with at least one overflow/long-content specimen for CMP-02/D-06)
- Converted ComponentKitchenLive from hand-authored button/status/card loops to a single registry-driven matrix that iterates over all Phase-189 primitive families and renders a two-column `.ax-dev-state-grid` with `data-theme="light"` and `data-theme="dark"` column wrappers — genuinely scoping `--ax-*` tokens via the theme.css sub-tree selector added in Plan 01
- Added test (g) as a mounted-page HTML assertion verifying `data-theme="light"`, `data-theme="dark"`, `data-ax-state="default"`, `data-ax-state="disabled"`, and `data-ax-na-reason` attributes in the rendered /billing/dev/components HTML
- Fixed `assign_shell/4` to include `:active_organization_name` (prevents potential KeyError if AppShell requires the assign)
- All 7 registry tests (a)-(g) pass; full test suite shows only pre-existing failures (dashboard_live and query module tests — confirmed pre-existing against the prior commit)

## Task Commits

1. **Task 1: Extend ComponentRegistry with all 14 Phase-189 primitive family entries** - `abd34670` (feat)
2. **Task 2: Convert ComponentKitchenLive to registry-driven matrix renderer; add test (g)** - `21226bcb` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — Added 12 new family entries with 7-field schema; button and status entries retained; card and foundation entries remain 4-field (not Phase-189 primitives per plan spec)
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — Registry-driven state-matrix renderer replacing hand-authored button/status/card loops; render_specimen/3 private dispatch function; theme-scoped IDs; assign_shell/4 fix; new component aliases
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — Added test (g) mounted-page HTML assertion; tests (e) and (f) structural data-contract tests unchanged

## Decisions Made

- **ax_class second token is an actual rendered CSS class**: The existing test (a) pattern-matches `[_base, variant_class] = String.split(ax_class, " ", parts: 2)` and asserts `html =~ variant_class`. New entries use actual component-rendered classes (e.g., `ax-field-control` for input, `ax-checkbox` for checkbox, `ax-select-control` for select) so the assertion passes naturally when the renderer calls the component.
- **Theme-scoped element IDs**: IDs use the pattern `"#{theme}-#{family}-#{state}"` (e.g., `"light-inp-error"`, `"dark-cb-selected"`) to prevent LiveView's duplicate-id RuntimeError when the same component state is rendered in both light and dark columns.
- **Card section retained as separate dl**: Card entries have no `applicable_states` (not Phase-189 primitives) so they are excluded from the matrix renderer filter. A separate card section renders their tokens via `<dl class="ax-dev-token-dl">` so test (d)'s `html =~ token` assertion passes for `--ax-shadow-sm`, `--ax-success`, etc.
- **D-07 status**: HTML attribute presence (`data-theme="light"`, `data-theme="dark"`) is verified by test (g). Browser-level resolved-color delta (the definitive D-07 proof) is deferred to Plan 06's `themeColumnDeltaProbe` per the plan spec.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Theme-scoped element IDs to prevent LiveView duplicate-id RuntimeError**
- **Found during:** Task 2 (ComponentKitchenLive conversion)
- **Issue:** Rendering the same component (Input, Radio, Toggle, etc.) in both light and dark columns produced duplicate DOM IDs (e.g., two `<input id="inp-lab-error">` elements), causing LiveView to raise a RuntimeError during test mount
- **Fix:** All `do_render_specimen/4` clauses use `"#{theme}-#{family}-#{state}"` as the base for element IDs, scoping IDs to their column (light vs dark) AND state
- **Files modified:** `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex`
- **Verification:** All 7 registry tests pass with zero LiveView duplicate-id errors
- **Committed in:** `21226bcb` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** ID-scoping fix is required for correctness of the two-column renderer. No scope creep.

## Issues Encountered

- ax_class values for new entries initially used conceptual class names (`ax-field-input`, `ax-textarea-field`) that don't appear in rendered HTML. Resolved by using actual rendered CSS classes (`ax-field-control`, `ax-textarea`) that components emit, so test (a)'s `html =~ variant_class` assertion passes naturally via the renderer calling the components.

## Known Stubs

None - all 14 family entries have real component renderers dispatched by `render_specimen/3`. Overflow specimens use actual long content strings. The `fallback do_render_specimen/4` clause emits a text label for unmatched pairs but is only reachable for families/states not covered by the 60+ specific clauses (defensive only).

## Next Phase Readiness

- Plan 04 (CSS ax-dev-state-grid addition + primitive root fixes) can proceed: the registry-driven renderer is in place, emitting the `.ax-dev-state-grid` class and `data-ax-state` attributes that Plan 04's CSS tests will target
- Plan 05 (token drift and CMP-05 guard) can reference the registry entries for the CMP-05 primitive class scan
- D-07 HTML-attribute layer is proven; browser-level resolved-color delta awaits Plan 06's `themeColumnDeltaProbe` E2E probe

---
*Phase: 189-primitive-form-components-component-lab*
*Completed: 2026-06-17*

## Self-Check: PASSED

Files verified:
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — FOUND ✓
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — FOUND ✓
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — FOUND ✓

Commits verified:
- `abd34670` — FOUND ✓ (Task 1)
- `21226bcb` — FOUND ✓ (Task 2)

Test verification: `mix test test/accrue_admin/dev/component_registry_test.exs` — 7 tests, 0 failures ✓
