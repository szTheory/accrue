---
phase: 195-exemplar-b-subscription-detail
plan: "04"
subsystem: accrue_admin-ui
tags: [overlay, scroll-lock, focus-trap, liveview-hooks, generated-assets]

requires:
  - phase: 195-exemplar-b-subscription-detail/195-01
    provides: RED JS coverage for ref-counted scroll lock and inert shell behavior
  - phase: 195-exemplar-b-subscription-detail/195-03
    provides: Canonical Overlay component markup, phx-hook="Overlay", and #ax-overlay-root
provides:
  - Ref-counted ScrollLock module for modal/drawer overlays
  - Overlay LiveView hook composing FocusTrap with modal/drawer scroll lock
  - Served admin JS bundle containing the Overlay hook registration
affects: [195-05, 195-07, 195-08, 199]

tech-stack:
  added: []
  patterns:
    - "Overlay JS composes the existing FocusTrap lifecycle instead of forking focus/Escape behavior."
    - "ScrollLock owns all global document scroll, scrollbar compensation, and app-shell inert mutations."
    - "Popover presentation is explicitly excluded from scroll lock and inert background behavior."

key-files:
  created:
    - accrue_admin/assets/js/hooks/scroll_lock.js
    - accrue_admin/assets/js/hooks/overlay.js
  modified:
    - accrue_admin/assets/js/app.js
    - accrue_admin/priv/static/accrue_admin.js

key-decisions:
  - "Keep FocusTrap registered and compose it inside Overlay so existing non-migrated focus surfaces keep working."
  - "Gate ScrollLock to modal and drawer presentations; popovers remain lightweight non-modal surfaces."
  - "Keep IXN-01 requirement completion pending for Phase 199; this plan implements the Phase 195 overlay behavior prerequisite."

patterns-established:
  - "LiveView hook composition can spread an existing hook object, then wrap mounted/updated/destroyed for extra behavior."
  - "Generated admin JS must be rebuilt and committed whenever app.js hook registration changes."

requirements-completed: []
requirements-addressed: [IXN-01]

duration: 4m 10s
completed: 2026-06-26
status: complete
---

# Phase 195 Plan 04: Overlay JS Behavior Summary

**Ref-counted overlay scroll lock with inert shell isolation, FocusTrap composition, and a rebuilt served admin JS bundle.**

## Performance

- **Duration:** 4m 10s
- **Started:** 2026-06-26T08:51:16Z
- **Completed:** 2026-06-26T08:55:26Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `ScrollLock` with nested lock counting, exact scroll restoration, scrollbar compensation, app-shell inert toggling, and a deterministic test reset helper.
- Added `Overlay` as the single LiveView hook behind `<.overlay>`, delegating focus entry, trapping, Escape close, and focus restore to `FocusTrap`.
- Registered `Overlay` in `app.js` while preserving the existing `FocusTrap` hook registration.
- Rebuilt `accrue_admin/priv/static/accrue_admin.js` so served admin assets include the new hook behavior.

## Task Commits

1. **Task 1: Implement ScrollLock module** - `50b121cb` (feat)
2. **Task 2: Implement and register Overlay hook** - `8081a7dc` (feat)
3. **Task 3: Rebuild committed JS bundle** - `ecc9502a` (chore)

## Files Created/Modified

- `accrue_admin/assets/js/hooks/scroll_lock.js` - New ref-counted scroll-lock module with inert shell state management and exact restore.
- `accrue_admin/assets/js/hooks/overlay.js` - New Overlay hook composing FocusTrap with presentation-gated ScrollLock.
- `accrue_admin/assets/js/app.js` - Imports and registers `Overlay` while retaining `FocusTrap`.
- `accrue_admin/priv/static/accrue_admin.js` - Rebuilt generated admin bundle containing Overlay and ScrollLock runtime code.

## Verification Results

- `cd accrue_admin && node --test test/js/scroll_lock_test.mjs` - PASS: 4 tests, 0 failures.
- `cd accrue_admin && node --test test/js/focus_trap_test.mjs test/js/scroll_lock_test.mjs` - PASS: 7 tests, 0 failures.
- `cd accrue_admin && mix accrue_admin.assets.build` - PASS: bundle rebuilt; command also printed existing Storybook dev-asset warnings and exited 0.
- `cd accrue_admin && git diff --check priv/static/accrue_admin.js` - PASS.
- `rg` bundle/source probes confirmed the generated bundle contains `Overlay`, `overlayScrollLocked`, `#accrue-admin-shell`, and `--ax-scrollbar-comp`.

## Decisions Made

- The RED scroll-lock test from Plan 195-01 was reused as the TDD contract; the initial run failed on missing `scroll_lock.js`, then passed after implementation.
- `Overlay` spreads the existing `FocusTrap` hook object and wraps lifecycle methods rather than duplicating focus containment or Escape dispatch.
- `ScrollLock` is scoped to modal/drawer presentations by `data-presentation` and `data-scroll-lock`; popovers do not lock scroll or mark the shell inert.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix accrue_admin.assets.build` emitted non-blocking PhoenixStorybook dev-asset warnings during compile, then completed and rebuilt `priv/static/accrue_admin.js`.
- Node printed the existing typeless-package warning for ES module test imports; tests passed and no package metadata was changed.

## Known Stubs

None. The `null`/empty-string values in the JS modules are internal lifecycle state and attribute defaults, not UI data stubs.

## Threat Flags

None. The only security-relevant surfaces changed are the planned overlay-to-document scroll boundary, nested lock counter, inert shell mutation, and FocusTrap composition covered by T-195-13 through T-195-15.

## User Setup Required

None - no external service configuration required.

## Self-Check

- [x] `accrue_admin/assets/js/hooks/scroll_lock.js` exists.
- [x] `accrue_admin/assets/js/hooks/overlay.js` exists.
- [x] `accrue_admin/assets/js/app.js` imports and registers `Overlay`.
- [x] `accrue_admin/priv/static/accrue_admin.js` contains the generated Overlay hook registration.
- [x] Task commit `50b121cb` exists.
- [x] Task commit `8081a7dc` exists.
- [x] Task commit `ecc9502a` exists.
- [x] Plan verification commands pass.
- [x] No generated runtime artifacts were left untracked, except the pre-existing `.planning/research/.cache/` directory.

## Self-Check: PASSED

## Next Phase Readiness

Plan 195-05 can add the overlay CSS geometry knowing the browser hook contract is wired, and Plan 195-07 can open Subscription detail actions through the canonical drawer path. Phase 199 still owns the full IXN-01 cross-page overlay sweep.

---
*Phase: 195-exemplar-b-subscription-detail*
*Completed: 2026-06-26*
