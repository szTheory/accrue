---
phase: 177-d-motion-micro-interaction-design
plan: "03"
subsystem: accrue_admin
tags:
  - motion
  - liveview-js
  - transitions
  - detail-drawer
  - flash
  - data-table
  - customer-live

dependency_graph:
  requires:
    - 177-02
  provides:
    - detail_drawer phx-mounted/phx-remove JS.show/hide transition tuples
    - flash_group per-article phx-mounted/phx-remove JS.show/hide transition tuples
    - customer_live More ▾ ax-tab-more-open class toggle
    - data_table content container phx-mounted fade-in
  affects:
    - 177-04

tech_stack:
  added: []
  patterns:
    - "Phoenix.LiveView.JS.show/hide with transition: {active, from, to} three-tuple"
    - "phx-mounted + phx-remove on :if-gated elements (mirror step_up_auth_modal pattern)"
    - "CSS transition class tuples with --ax-dur-*/--ax-ease-* tokens, zero raw ms literals"

key_files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/lib/accrue_admin/components/detail_drawer.ex
    - accrue_admin/lib/accrue_admin/components/flash_group.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/components/data_table.ex

decisions:
  - "JS.show/hide time: integers (240/180/140) carry token-name comments (--ax-dur-3/2/exit) inline or via <%!-- --%> comment on the adjacent line"
  - "More ▾ uses pure CSS class toggle (ax-tab-more-open on wrapper), no JS.show/hide needed — Plan 02 CSS handles the translateY reveal via the .ax-tab-more-open selector"
  - "data_table phx-mounted placed on ax-card ax-data-table-shell (the :if-gated table wrapper) rather than tbody — the shell is the single mount point for the entire content block"
  - "Backdrop element gets its own phx-mounted/phx-remove transition (ax-drawer-backdrop-*) to fade in/out in sync with the drawer shell"

metrics:
  duration: "2 minutes"
  completed_date: "2026-06-04"
  tasks_completed: 2
  files_modified: 6
---

# Phase 177 Plan 03: JS.transition Wiring for Mount/Remove Surfaces Summary

One-liner: Wire JS.show/hide transition tuples on detail_drawer (slide+fade 240ms), flash_group articles (slide+fade 180ms), and data_table content (fade 180ms); activate More ▾ translateY via ax-tab-more-open class toggle; add ax-drawer-*/ax-flash-* CSS class tuple blocks using only --ax-dur-*/--ax-ease-* tokens.

## What Was Built

### Task 1: CSS transition class tuples in app.css (commit eaa6389b)

Added two CSS comment sections to `accrue_admin/assets/css/app.css`:

**Detail drawer transition classes** (after `.ax-detail-drawer-footer`, ~line 778):
- `.ax-drawer-enter-from` — `opacity: 0; transform: translateX(var(--ax-rise-md))`
- `.ax-drawer-entering` — `transition: opacity/transform var(--ax-dur-3) var(--ax-ease-out)`
- `.ax-drawer-enter-to` — `opacity: 1; transform: translateX(0px)`
- `.ax-drawer-leave-from/leaving/leave-to` — fade-only exit via `var(--ax-dur-exit)`
- `.ax-drawer-backdrop-*` — 6 matching backdrop classes (same timing)

**Flash transition classes** (after `.ax-flash-error`, ~line 982):
- `.ax-flash-enter-from` — `opacity: 0; transform: translateY(calc(-1 * var(--ax-rise-sm)))`
- `.ax-flash-entering` — `transition: opacity/transform var(--ax-dur-2) var(--ax-ease-out)`
- `.ax-flash-enter-to` — `opacity: 1; transform: translateY(0px)`
- `.ax-flash-leave-from/leaving/leave-to` — fade-only exit via `var(--ax-dur-exit)`

All durations reference `--ax-dur-*` tokens. Zero raw ms literals in app.css.
Asset rebuild succeeded in 135ms. `priv/static/accrue_admin.css` committed.

### Task 2: Elixir component wiring (commit 9fa6a78e)

**detail_drawer.ex:**
- `phx-mounted={JS.show(transition: {"ax-drawer-entering","ax-drawer-enter-from","ax-drawer-enter-to"}, time: 240)}` on `:if={@open}` section
- `phx-remove={JS.hide(transition: {"ax-drawer-leaving","ax-drawer-leave-from","ax-drawer-leave-to"}, time: 140)}`
- Backdrop div gets matching `ax-drawer-backdrop-*` transitions (time: 240/140)

**flash_group.ex:**
- `phx-mounted={JS.show(transition: {"ax-flash-entering","ax-flash-enter-from","ax-flash-enter-to"}, time: 180)}` on each `:for` article
- `phx-remove={JS.hide(transition: {"ax-flash-leaving","ax-flash-leave-from","ax-flash-leave-to"}, time: 140)}`

**customer_live.ex:**
- `class={["ax-tab-more-wrapper", @more_tabs_open && "ax-tab-more-open"]}` on the wrapper div
- Activates Plan 02's `.ax-tab-more-open .ax-tab-more-menu` CSS translateY reveal (no JS.show/hide needed)

**data_table.ex:**
- `phx-mounted={JS.show(transition: {"ax-content-entering","ax-content-enter-from","ax-content-enter-to"}, time: 180)}` on `ax-card ax-data-table-shell` div

## Verification Results

All plan verification checks pass:
- `grep "ax-drawer-entering" detail_drawer.ex` — 1 match
- `grep "ax-flash-entering" flash_group.ex` — 1 match
- `grep -E "transition:.*[0-9]+(ms|s)\b" app.css | grep -v ax-skeleton-shimmer` — 0 matches
- `grep "ax-tab-more-open" customer_live.ex` — 1 match
- `grep "ax-content-entering" data_table.ex` — 1 match
- `mix test --seed 0` — **252 tests, 0 failures**

## Deviations from Plan

None — plan executed exactly as written. The pre-existing `tabs/4` unused function warning in `customer_live.ex` (line 578) is pre-existing and unrelated to this plan.

## Threat Flags

None — this plan modifies component rendering only. No new routes, auth paths, or data surfaces were introduced. The More ▾ toggle logic (`handle_event("toggle_more_tabs"...)`) was not modified; only the CSS class list on the wrapper div was updated.

## Known Stubs

None — all transitions are fully wired CSS-class references; no placeholder text or mock data.

## Self-Check

- [x] `accrue_admin/assets/css/app.css` — modified (ax-drawer-* and ax-flash-* blocks added)
- [x] `accrue_admin/priv/static/accrue_admin.css` — rebuilt and committed (eaa6389b)
- [x] `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` — modified (9fa6a78e)
- [x] `accrue_admin/lib/accrue_admin/components/flash_group.ex` — modified (9fa6a78e)
- [x] `accrue_admin/lib/accrue_admin/live/customer_live.ex` — modified (9fa6a78e)
- [x] `accrue_admin/lib/accrue_admin/components/data_table.ex` — modified (9fa6a78e)
- [x] Commits eaa6389b and 9fa6a78e verified in git log

## Self-Check: PASSED
