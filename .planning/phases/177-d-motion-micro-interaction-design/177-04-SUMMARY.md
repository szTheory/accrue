---
phase: 177-d-motion-micro-interaction-design
plan: "04"
subsystem: accrue_admin
tags:
  - motion
  - command-palette
  - css-transitions
  - data-open
  - accessibility
dependency_graph:
  requires:
    - 177-03
  provides:
    - data-open visibility mechanism for command palette (MOT-02 surface #5 + #5b)
    - palette panel scale-in + backdrop fade via CSS tokens
  affects:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/global_search.ex
    - accrue_admin/assets/js/hooks/command_palette.js
tech_stack:
  added: []
  patterns:
    - data-open attribute toggle replacing class-swap-to-hidden mechanism
    - CSS [data-open="true"] selectors for pointer-events + opacity + transform enter/exit
    - Two-property transition (opacity --ax-ease-out + transform --ax-ease-emphasis) on palette panel
decisions:
  - data-open="true"/"false" attribute rather than class-swap to "hidden" so CSS transitions can fire (display:none kills transitions)
  - --ax-ease-emphasis used for palette panel transform — the one earned overshoot per motion contract (UI-SPEC row #5)
  - Symmetric backdrop transition (--ax-dur-2 both enter/exit) via single base transition declaration; acceptable for the backdrop surface per motion spec
  - pointer-events: none on wrapper and panel base states ensures closed palette is fully non-interactive without display:none
key_files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/global_search.ex
    - accrue_admin/assets/js/hooks/command_palette.js
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
metrics:
  duration: ~5 min
  completed: "2026-06-04T19:05:00Z"
  tasks: 2
  files: 5
---

# Phase 177 Plan 04: global_search data-open refactor + command_palette.js update Summary

Command palette visibility refactored from class-swap-to-"hidden" (display:none) to a data-open attribute with CSS opacity/transform/pointer-events transitions using motion tokens —MOT-02 surfaces #5 and #5b.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add data-open CSS transitions for palette wrapper, panel, and backdrop | bf357d61 | app.css, priv/static/accrue_admin.css |
| 2 | Refactor global_search.ex wrapper + update command_palette.js hook | b33bde73 | global_search.ex, command_palette.js, priv/static/accrue_admin.js |

## What Was Built

### Task 1 — CSS Transition Rules (app.css)

Added Phase 177 motion rules keyed on `[data-open]` attribute:

- `.ax-command-palette-wrapper`: added `pointer-events: none` to base rule — wrapper stays in DOM but is non-interactive when closed
- `.ax-command-palette-backdrop`: added `opacity: 0` base + `transition: opacity var(--ax-dur-2) var(--ax-ease-out)`
- `.ax-command-palette`: added `opacity: 0`, `transform: scale(0.98)`, `pointer-events: none` base + two-property transition (`opacity var(--ax-dur-2) var(--ax-ease-out), transform var(--ax-dur-2) var(--ax-ease-emphasis)`) — `--ax-ease-emphasis` is the one earned overshoot per motion contract
- `.ax-command-palette-wrapper[data-open="true"]`: `pointer-events: auto`
- `.ax-command-palette-wrapper[data-open="true"] .ax-command-palette-backdrop`: `opacity: 1`
- `.ax-command-palette-wrapper[data-open="true"] .ax-command-palette`: `opacity: 1`, `transform: scale(1)`, `pointer-events: auto`

No raw ms/cubic-bezier literals — all transitions use `--ax-dur-*` and `--ax-ease-*` token vars.

### Task 2 — global_search.ex + command_palette.js

**global_search.ex line 112:**
```
# Before:
<div id={@id} class={if @is_open, do: "ax-command-palette-wrapper", else: "hidden"}>

# After:
<div id={@id} class="ax-command-palette-wrapper" data-open={to_string(@is_open)}>
```

**command_palette.js — two checks updated:**
```js
// Before (both locations):
!this.el.parentElement.classList.contains("hidden")

// After:
this.el.parentElement.dataset.open === "true"
```

Both the `updated()` focus guard and the `handleGlobalKeydown` Escape handler now read `dataset.open`. All other hook logic (keyboard navigation, item selection, `⌘K` toggle dispatch) is unchanged.

## Verification Results

1. `grep "data-open" global_search.ex` — matches on line 112
2. `grep 'classList.contains("hidden")' command_palette.js` — 0 matches (fully replaced)
3. `grep "dataset.open" command_palette.js` — 2 matches
4. `grep -E "transition:.*[0-9]+(ms|s)\b" app.css | grep -v "ax-skeleton-shimmer"` — 0 matches
5. Asset build succeeded (134.1kb JS, 9ms)
6. `mix test --seed 0` — 252 tests, 0 failures

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The `data-open` attribute exposes only the boolean open/close state (`"true"` / `"false"`), consistent with T-177-04-01 analysis. Search query logic and auth scope are untouched (T-177-04-02).

## Known Stubs

None.

## Self-Check: PASSED

- `accrue_admin/assets/css/app.css` — exists and contains `data-open` rules (verified)
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — exists and has `data-open={to_string(@is_open)}` (verified)
- `accrue_admin/assets/js/hooks/command_palette.js` — exists and has `dataset.open === "true"` × 2 (verified)
- Commit `bf357d61` — confirmed in git log
- Commit `b33bde73` — confirmed in git log
- 252 tests passing — confirmed
