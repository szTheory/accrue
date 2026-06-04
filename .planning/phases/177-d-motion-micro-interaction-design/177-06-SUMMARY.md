---
phase: 177-d-motion-micro-interaction-design
plan: "06"
subsystem: accrue_admin
tags:
  - motion
  - playwright
  - reduced-motion
  - e2e
  - kitchen
  - accessibility
dependency_graph:
  requires:
    - 177-04
  provides:
    - automated reduced-motion coverage for dropdown/palette/drawer (MOT-03)
    - live motion reference in /dev/components kitchen (MOT-01)
  affects:
    - accrue_admin/e2e/reduced-motion.spec.js
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
tech_stack:
  added: []
  patterns:
    - D-15 two-test Playwright describe block pattern for each new surface
    - Token-value check on documentElement for surfaces not in DOM when closed (drawer)
    - parseFloat-based ≤1ms threshold for --ax-dur-2 surfaces (opacity crossfades retained)
    - Static HEEx reference table (no assigns) in kitchen LiveView
key_files:
  created: []
  modified:
    - accrue_admin/e2e/reduced-motion.spec.js
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
decisions:
  - Used ≤1ms threshold (not "0s" equality) for dropdown/palette reduced-motion assertions because --ax-dur-2 intentionally stays at 1ms under reduced-motion (opacity crossfades retained per theme.css design; only --ax-dur-3 collapses fully to 0ms)
  - Used documentElement token check (--ax-dur-3 === "0ms") for drawer because the drawer element is not in DOM when closed (:if={@open}) — reading from getComputedStyle on documentElement is reliable regardless of element presence
  - Standalone structural test reads --ax-rise-sm and --ax-rise-md travel tokens on documentElement — covers all surfaces using these tokens (dropdown, drawer, flash) without requiring the elements to be open
  - Kitchen reference table has 11 rows (9 primary + 2 backdrop sub-entries) to match the full 177 motion catalog; section is static (no assigns) and behind :if={@available?} guard
metrics:
  duration: ~8 min
  completed: "2026-06-04T19:30:00Z"
  tasks: 2
  files: 2
---

# Phase 177 Plan 06: Playwright reduced-motion extension + /dev/components motion reference Summary

Playwright reduced-motion spec extended with D-15-pattern two-test blocks for three newly-animated surfaces (dropdown, palette, drawer) plus a structural token-collapse test for travel tokens; live motion reference table added to the /dev/components kitchen page.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend e2e/reduced-motion.spec.js with three new describe blocks and structural no-travel test | 36b4301b | e2e/reduced-motion.spec.js |
| 2 | Add Motion reference section to component_kitchen_live.ex | cbe41e24 | component_kitchen_live.ex |

## What Was Built

### Task 1 — Extended Playwright spec (e2e/reduced-motion.spec.js)

Added 4 new test blocks after the existing D-15 button describe:

**`.ax-dropdown-panel` describe block (2 tests):**
- With reduced-motion: reads `getComputedStyle(".ax-dropdown-panel").transitionDuration`, asserts every segment ≤ 1ms (parseFloat × 1000 since computed style is in seconds). `--ax-dur-2` collapses to `1ms` (0.001s) under reduced-motion — opacity crossfades retained by design.
- Without reduced-motion: asserts at least one segment > 1ms (proving 180ms default is present).

**`.ax-command-palette` describe block (2 tests):**
- Identical structure to dropdown — same `--ax-dur-2` token, same ≤1ms threshold.

**`.ax-drawer-entering` token describe block (2 tests):**
- With reduced-motion: reads `--ax-dur-3` from `getComputedStyle(document.documentElement)`, asserts `"0ms"`. Drawer is not in DOM when closed (`:if={@open}`), so token inspection is used instead of element inspection.
- Without reduced-motion: asserts `"240ms"` (drawer enter duration).

**Standalone structural test:**
- Emulates reduced-motion, reads `--ax-rise-sm` and `--ax-rise-md` from documentElement computed style, asserts both are `"0px"`. Proves no translateX/translateY travel can occur on any surface using these tokens (dropdown, drawer, flash) — independent of whether those elements are in the DOM.

**Key design decision:** `--ax-dur-2` intentionally stays at `1ms` under reduced-motion (not `0ms`) because theme.css preserves opacity crossfades at 1ms for vestibular users. The `≤1ms` threshold matches this intent. The `--ax-transition-base` bundle used by `.ax-button` overrides to `--ax-dur-instant` (0ms) via the full bundle override, which is why the existing D-15 test uses exact `"0s"` equality.

### Task 2 — /dev/components Motion reference section (component_kitchen_live.ex)

Added a new `<section>` element near the end of the kitchen template (`ax-card ax-dev-stack`):
- Heading: `<p class="ax-label">Motion Reference</p>`
- Prose note: references `accrue_admin/guides/motion.md` and Phase 179 trace review
- HTML table (`ax-dev-motion-table`) with 11 rows covering all 9 primary surfaces plus 2 backdrop sub-entries
- Columns: Surface, CSS selector, Trigger, Token(s), Justification
- Static content (no assigns), gated with `:if={@available?}`, no module/mount/handle_event changes
- Annotated with `<%!-- Phase 177 — Motion reference (MOT-01) --%>` and guide reference comment

## Verification Results

1. `grep "MOT-03" reduced-motion.spec.js` — 5 matches (1 comment + 3 describe labels + 1 test label)
2. `grep "ax-dropdown-panel" reduced-motion.spec.js` — 9 matches
3. `grep "ax-rise-sm" reduced-motion.spec.js` — 4 matches (structural test + comments)
4. `grep "Motion" component_kitchen_live.ex` — 3 matches (comment + heading + prose)
5. `mix test --seed 0` — 252 tests, 0 failures (no regressions)

Note on Playwright e2e: The spec is structurally correct and well-formed. Full Playwright execution requires a running dev server (`mix phx.server`). Per plan scope, automated structural correctness + ExUnit green are the Phase 177-06 gates; motion trace/video confirmation is Phase 179.

## Deviations from Plan

### Auto-resolved Issues

**1. [Rule 1 - Accuracy] Used ≤1ms threshold instead of exact "0s" for dropdown/palette**
- **Found during:** Task 1 implementation
- **Issue:** The plan said "assert every segment is 0s" for dropdown/palette. But `--ax-dur-2` collapses to `1ms` under reduced-motion (intentional in theme.css to retain opacity crossfades), which computes to `0.001s` in `getComputedStyle`, not `"0s"`. An exact `"0s"` assertion would fail for these surfaces even when the override is working correctly.
- **Fix:** Used `parseFloat(seg) * 1000 ≤ 1` threshold instead of `=== "0s"`. The plan's alternative approach (read token from documentElement) was used for the drawer where element presence is unreliable. This faithfully tests the theme.css reduced-motion design without writing tests that fail on correct behavior.
- **Files modified:** accrue_admin/e2e/reduced-motion.spec.js
- **Commit:** 36b4301b

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. The motion reference section is static content in /dev/components (already behind admin auth — T-177-06-01 accepted). The Playwright spec tests the running dev server via the existing `/__e2e__/login` helper. No new capabilities exposed.

## Known Stubs

None.

## Self-Check: PASSED

- `accrue_admin/e2e/reduced-motion.spec.js` — exists, has 4 new test blocks, MOT-03 references, ax-dropdown-panel, ax-command-palette, ax-drawer-entering, ax-rise-sm, ax-rise-md (verified)
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — exists, has Motion reference section with motion.md link and 11-row table (verified)
- Commit `36b4301b` — confirmed in git log
- Commit `cbe41e24` — confirmed in git log
- 252 tests passing — confirmed via `mix test --seed 0`
