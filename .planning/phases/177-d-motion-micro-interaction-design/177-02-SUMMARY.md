---
phase: 177-d-motion-micro-interaction-design
plan: "02"
subsystem: accrue_admin
tags: [motion, css-transitions, sidebar, animation, micro-interaction]
dependency_graph:
  requires: [177-01]
  provides: [dropdown-motion, tabs-motion, badge-motion, more-overflow-motion, skeleton-content-classes, sidebar-opacity-reveal]
  affects: [accrue_admin/assets/css/app.css, accrue_admin/assets/js/hooks/sidebar_collapse.js, accrue_admin/priv/static]
tech_stack:
  added: []
  patterns: [css-transition-token-bundles, transitionend-two-step, details-open-selector, ax-collapsed-class]
key_files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/assets/js/hooks/sidebar_collapse.js
    - accrue_admin/lib/accrue_admin/components/sidebar.ex
    - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
decisions:
  - "Exit on dropdown/More ▾ is instant (native details[open] removes synchronously); symmetric 180ms enter accepted per Phase 177 scope"
  - "ax-collapsed CSS class approach (not height-based) for sidebar link list opacity reveal; JS sets hidden only after transitionend"
  - "@supports(@starting-style {}) guard for .ax-badge-appear first-appear pop (nice-to-have; primary deliverable is --ax-transition-colors)"
  - "ax-sidebar-group-links class added to sidebar.ex div so CSS selector targets it cleanly"
metrics:
  duration: "7m"
  completed: "2026-06-04"
  tasks: 2
  files: 6
---

# Phase 177 Plan 02: CSS Transition Rules for 6 Pure-CSS Surfaces + Sidebar Reveal Summary

CSS transitions for dropdown, More ▾ menu, tabs, badge, skeleton-content phase-in classes, and opacity-based collapsible nav reveal via transitionend two-step — all routed through Phase-174 --ax-transition-* token bundles.

## What Was Built

### Task 1: CSS transition rules for dropdown, More ▾, tabs, badge (commit fe3ec94a)

**app.css changes:**

1. **Stale comment update** (line 1215): Replaced "instant — no transition in this phase; motion is Phase D" with "via --ax-transition-transform bundle (Phase D — wired)".

2. **Badge color transition**: Added `transition: var(--ax-transition-colors)` to `.ax-badge` so badge tone changes (default/warning/danger) animate. Added `.ax-badge-appear` with `@supports (@starting-style {})` guard for a first-appear scale pop from `--ax-press-scale` → 1.

3. **More ▾ motion block**: Added `.ax-tab-more-menu` base state (opacity 0, translateY(-`--ax-rise-sm`), pointer-events none, transition on opacity+transform via `--ax-dur-2`/`--ax-ease-out`) and `.ax-tab-more-open .ax-tab-more-menu` open state (opacity 1, translateY(0px), pointer-events auto). Plan 03 will toggle `.ax-tab-more-open` on the wrapper via JS.

4. **Dropdown motion block**: Added `details.ax-dropdown .ax-dropdown-panel` base state (opacity 0, translateY(-`--ax-rise-sm`), transition) and `details[open].ax-dropdown .ax-dropdown-panel` open state with a comment noting exit is instant due to native `<details>` behavior.

5. **Tabs color transition**: Appended `transition: var(--ax-transition-colors)` to `.ax-tab` for color + border-color crossfade on active-tab changes.

### Task 2: Skeleton content CSS classes + sidebar transitionend two-step (commit 7f3dcf3f)

**app.css additions:**

6. **Collapsible nav link list**: Added `.ax-sidebar-group-links` rule with `transition: opacity var(--ax-dur-2) var(--ax-ease-out)` (the always-present transition anchor). Added `.ax-collapsed` rule with `opacity: 0; pointer-events: none; transition: opacity var(--ax-dur-exit) var(--ax-ease-in)`.

7. **Skeleton → content classes**: Added `.ax-content-enter-from` (opacity 0), `.ax-content-entering` (transition via `--ax-dur-2`/`--ax-ease-out`), `.ax-content-enter-to` (opacity 1) for use by data_table.ex Plan 03 phx-mounted `JS.show` transition tuple.

**sidebar_collapse.js**: Replaced `list.hidden = !expanded` one-liner with transitionend two-step:
- Expand: `list.removeAttribute("hidden")` + `list.classList.remove("ax-collapsed")` (CSS opacity 0→1 fires).
- Collapse: `list.classList.add("ax-collapsed")` (triggers exit), `{ once: true }` transitionend listener sets `list.hidden = true` + removes class after animation completes.

**sidebar.ex**: Added `class="ax-sidebar-group-links"` to the collapsible link-list div so the CSS selector targets it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed navigation_components_test assertion for new class attribute**
- **Found during:** Task 2 test run
- **Issue:** Test asserted `~s(id="sidebar-group-links-catalog" hidden)` as a substring match. After adding `class="ax-sidebar-group-links"` to the div, the rendered HTML became `id="sidebar-group-links-catalog" class="ax-sidebar-group-links" hidden` — the class attr sits between id and hidden, breaking the exact string match.
- **Fix:** Updated assertion to use a regex `~r/id="sidebar-group-links-catalog"[^>]*hidden/` that tolerates intervening attributes.
- **Files modified:** `accrue_admin/test/accrue_admin/components/navigation_components_test.exs`
- **Commit:** 7f3dcf3f

## Known Stubs

None. All 6 surfaces have real transition rules wired. The More ▾ open-state CSS
(`.ax-tab-more-open .ax-tab-more-menu`) requires Plan 03 JS to toggle the wrapper class — the
CSS is present but the toggle mechanism will be wired in Plan 03. This is intentional sequencing,
not a stub.

## Threat Flags

None. Plan is CSS/JS presentation only — no data access, auth, or network changes.

## Self-Check

### Created/modified files exist

- [x] `/Users/jon/projects/accrue/accrue_admin/assets/css/app.css` — exists
- [x] `/Users/jon/projects/accrue/accrue_admin/assets/js/hooks/sidebar_collapse.js` — exists
- [x] `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/components/sidebar.ex` — exists
- [x] `/Users/jon/projects/accrue/accrue_admin/priv/static/accrue_admin.css` — exists
- [x] `/Users/jon/projects/accrue/accrue_admin/priv/static/accrue_admin.js` — exists

### Commits exist

- [x] fe3ec94a — Task 1 (CSS transitions for dropdown, More ▾, tabs, badge)
- [x] 7f3dcf3f — Task 2 (skeleton content classes + sidebar two-step)

### Test suite

- [x] 252 tests, 0 failures (`mix test --seed 0`)

## Self-Check: PASSED
