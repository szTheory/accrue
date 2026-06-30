---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: "06"
subsystem: ui
tags: [phoenix-liveview, overlay, focus-trap, scroll-lock, playwright]

requires:
  - phase: 199-04
    provides: canonical overlay component, root, and client sweep
  - phase: 199-05
    provides: overlay JS scroll, focus, and dismissal lifecycle
provides:
  - focused @overlay browser proof for portal root, inert shell, hit testing, dismissal, focus, and cleanup
  - scroll-lock reconciliation against live lockable overlay DOM during LiveView patches
  - topmost focus-trap stack for nested drawer-to-step-up modal flows
affects: [phase-199, phase-200, overlay-correctness]

tech-stack:
  added: []
  patterns:
    - DOM-reconciled overlay lock state
    - topmost-only focus trap enforcement

key-files:
  created: []
  modified:
    - accrue_admin/assets/js/app.js
    - accrue_admin/assets/js/hooks/focus_trap.js
    - accrue_admin/assets/js/hooks/overlay.js
    - accrue_admin/assets/js/hooks/scroll_lock.js
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/test/js/focus_trap_test.mjs
    - accrue_admin/test/js/scroll_lock_test.mjs

key-decisions:
  - "ScrollLock reconciles against live lockable overlay DOM, not only hook reference counts, so LiveView patches cannot drop shell inert while overlays remain mounted."
  - "FocusTrap uses a topmost-trap stack so nested step-up modals own focus and Escape handling above an open drawer."

patterns-established:
  - "Overlay lock reconciliation: observe body-level lockable overlay DOM and restore shell inert/body lock only when no modal or drawer remains."
  - "Nested overlay focus: active focus traps stay mounted, but only the stack top redirects focus and handles Escape."

requirements-completed: [IXN-01, IXN-04]

duration: 20m
completed: 2026-06-30
status: complete
---

# Phase 199 Plan 06: Overlay Browser Proof and Ancestor Escape Summary

**Focused overlay browser proof now passes with DOM-reconciled scroll locking and topmost focus ownership for nested drawer-to-step-up flows.**

## Performance

- **Duration:** 20m
- **Started:** 2026-06-29T23:49:34Z
- **Completed:** 2026-06-30T00:09:45Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments

- Proved the focused `@overlay` Playwright subset across representative drawer, command palette, and step-up modal flows.
- Fixed a LiveView patch race where an active overlay could keep the page scroll-locked while the replaced shell lost `inert`.
- Fixed nested focus-trap contention so the step-up modal, not the underlying drawer, owns focus and Escape handling.
- Preserved the existing source-level overlay root and transformed-ancestor audit coverage.

## Task Commits

1. **Task 1 RED: overlapping overlay scroll-lock regression** - `ba3e2f0c` (test)
2. **Task 1 GREEN: preserve overlay isolation across step-up patches** - `d44588c0` (fix)

**Plan metadata:** committed separately after state updates.

## Files Created/Modified

- `accrue_admin/assets/js/app.js` - Initializes the scroll-lock reconciler with other admin client controls.
- `accrue_admin/assets/js/hooks/focus_trap.js` - Adds a stack so only the topmost active trap enforces focus and Escape.
- `accrue_admin/assets/js/hooks/overlay.js` - Schedules scroll-lock reconciliation on overlay mount/update/destroy.
- `accrue_admin/assets/js/hooks/scroll_lock.js` - Reconciles active lockable overlay DOM, reapplies inert to replaced shells, and restores only after all lockable overlays are gone.
- `accrue_admin/priv/static/accrue_admin.js` - Rebuilt committed admin JS bundle.
- `accrue_admin/test/js/focus_trap_test.mjs` - Adds nested drawer/modal focus and Escape regression coverage.
- `accrue_admin/test/js/scroll_lock_test.mjs` - Adds shell replacement plus overlapping overlay lock regression coverage.

## Decisions Made

- Reconciled scroll lock from live `[data-scroll-lock]` overlay DOM because LiveView patches can replace the shell node independently of hook reference counts.
- Kept active focus traps mounted, but made enforcement topmost-only, which preserves drawer behavior after a step-up modal closes without allowing the drawer to steal modal focus.
- Did not loosen Playwright selectors or mask the failure with z-index changes; the failing contract exposed real runtime isolation bugs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reapplied shell inert after LiveView shell replacement**
- **Found during:** Task 1 (`npm run e2e:phase199 -- --grep @overlay`)
- **Issue:** The step-up flow kept `html`/`body` scroll-locked but the replaced `#accrue-admin-shell` lost `inert`, because saved lock state still referenced the old shell element.
- **Fix:** Added live DOM reconciliation for lockable modal/drawer overlays and updated saved inert restoration state when the current shell node changes during an active lock.
- **Files modified:** `accrue_admin/assets/js/hooks/scroll_lock.js`, `accrue_admin/assets/js/hooks/overlay.js`, `accrue_admin/assets/js/app.js`, `accrue_admin/test/js/scroll_lock_test.mjs`, `accrue_admin/priv/static/accrue_admin.js`
- **Verification:** `node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/command_palette_test.mjs`; `npm run e2e:phase199 -- --grep @overlay`
- **Committed in:** `d44588c0`

**2. [Rule 1 - Bug] Prevented underlying drawer trap from stealing modal focus**
- **Found during:** Task 1 (`npm run e2e:phase199 -- --grep @overlay`)
- **Issue:** Once shell inert was fixed, the step-up modal failed focus containment because the still-active drawer focus trap redirected focus back to a drawer button.
- **Fix:** Added a focus-trap stack and made initial focus, focus redirection, Tab wrapping, and Escape handling enforce only from the topmost active trap.
- **Files modified:** `accrue_admin/assets/js/hooks/focus_trap.js`, `accrue_admin/test/js/focus_trap_test.mjs`, `accrue_admin/priv/static/accrue_admin.js`
- **Verification:** `node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/command_palette_test.mjs`; `npm run e2e:phase199 -- --grep @overlay`
- **Committed in:** `d44588c0`

---

**Total deviations:** 2 auto-fixed (Rule 1 bug fixes)
**Impact on plan:** Both fixes were required for IXN-01 correctness. No selector loosening, package installs, endpoint changes, schema changes, or z-index masking were introduced.

## Issues Encountered

- The admin asset server embeds `priv/static/accrue_admin.js` at compile time. Rebuilding the committed bundle and rerunning the test server ensured Playwright used the updated hook code.
- `mix accrue_admin.assets.build` emitted existing Storybook optional-asset warnings; the build completed and did not block verification.

## Verification

- `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/command_palette_test.mjs` - 20 tests passed.
- `cd accrue_admin && npm run e2e:phase199 -- --grep @overlay` - 9 passed, 7 skipped.
- `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs --max-failures 5` - 18 tests passed.

## Known Stubs

None. Stub-pattern scan found only hook state initialization, test helper defaults, and the minified committed bundle; no user-facing placeholder or unwired data source was introduced.

## Threat Flags

None. The change touches client-side overlay/focus behavior and tests only; it adds no network endpoints, auth paths, file access, schema changes, or new trust boundaries beyond the plan's overlay hit-testing and transformed-ancestor mitigations.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 200 can rely on the focused overlay proof being green for portal root placement, inert background isolation, top-hit panel controls, close parity, no ghost overlays, stale body-lock cleanup, and nested step-up focus containment.

## Self-Check: PASSED

- `FOUND: .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-06-SUMMARY.md`
- `FOUND: ba3e2f0c`
- `FOUND: d44588c0`

---

*Phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress*
*Completed: 2026-06-30*
