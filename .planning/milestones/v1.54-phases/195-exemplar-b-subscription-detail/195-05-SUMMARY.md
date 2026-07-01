---
phase: 195-exemplar-b-subscription-detail
plan: "05"
subsystem: accrue_admin-ui
tags: [overlay, css, layer-contract, drawer, generated-assets]

requires:
  - phase: 195-exemplar-b-subscription-detail/195-03
    provides: Canonical Overlay component markup and body-level overlay root
  - phase: 195-exemplar-b-subscription-detail/195-04
    provides: Overlay hook, ScrollLock behavior, and served JS bundle
provides:
  - Token-compliant overlay CSS geometry for modal, drawer, and popover presentations
  - CSS source assertions for canonical overlay layer and drawer geometry contract
  - Rebuilt served admin CSS bundle containing the overlay geometry
affects: [195-07, 195-08, 198, 199]

tech-stack:
  added: []
  patterns:
    - "Canonical .ax-overlay-* CSS selectors own shell/backdrop/panel layer semantics; wrapper aliases stay compatibility surfaces."
    - "Drawer geometry is mobile-first bottom sheet below md and right-docked at md+."
    - "Generated admin CSS must be rebuilt after source CSS changes."

key-files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/test/accrue_admin/components/overlay_components_test.exs
    - accrue_admin/priv/static/accrue_admin.css

key-decisions:
  - "Use existing --ax-z-drawer, --ax-z-modal, and --ax-z-popover tokens for overlay presentation layers."
  - "Keep .ax-detail-drawer-* and .ax-step-up-modal-* aliases while making .ax-overlay-* the canonical CSS contract."
  - "Leave IXN-01 requirement completion pending for Phase 199; this plan addresses the Phase 195 overlay CSS prerequisite."

patterns-established:
  - "Overlay CSS tests assert source-level geometry and token usage before the generated bundle is rebuilt."
  - "Mobile drawer rules are explicit below the md breakpoint even though the source remains mobile-first."

requirements-completed: []
requirements-addressed: [IXN-01]

duration: 6m 54s
completed: 2026-06-26
status: complete
---

# Phase 195 Plan 05: Overlay CSS Geometry Summary

**Token-compliant overlay layer CSS with drawer bottom-sheet/right-dock geometry, source assertions, and a rebuilt served admin CSS bundle.**

## Performance

- **Duration:** 6m 54s
- **Started:** 2026-06-26T09:00:13Z
- **Completed:** 2026-06-26T09:07:07Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added canonical `.ax-overlay-shell`, `.ax-overlay-backdrop`, and `.ax-overlay-panel` CSS rules with isolated local backdrop/panel ordering.
- Mapped drawer, modal, and popover presentations to the existing `--ax-z-*` layer tokens.
- Set drawer geometry to bottom-sheet below md and right-docked `min(34rem, 92vw)` at md+.
- Added component-source assertions for overlay selector, z-token, local layer, and drawer geometry contracts.
- Rebuilt `accrue_admin/priv/static/accrue_admin.css` so served admin CSS contains the new overlay geometry.

## Task Commits

1. **Task 1: Add token-compliant overlay CSS** - `2c2104ca` (feat)
2. **Task 2: Green CSS layer and geometry assertions** - `08c64a3c` (test)
3. **Task 3: Rebuild committed CSS bundle** - `0faedcb1` (chore)

## Files Created/Modified

- `accrue_admin/assets/css/app.css` - Adds canonical overlay shell/backdrop/panel CSS, presentation z-token mapping, drawer geometry, and internal overlay scroll containment.
- `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` - Adds focused CSS assertions for canonical overlay selectors, z-token usage, local ordering, and desktop/mobile drawer rules.
- `accrue_admin/priv/static/accrue_admin.css` - Rebuilt minified served CSS bundle containing the overlay geometry.

## Verification Results

- `bash scripts/ci/verify_package_docs.sh` - PASS. Foundation contrast passed; package docs verifier exited 0.
- `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs` - PASS: 11 tests, 0 failures. The run still prints the existing PhoenixStorybook `RegistryStory.variations_for/1` warning from `storybook/components/button.story.exs`.
- `cd accrue_admin && mix accrue_admin.assets.build && git diff --check priv/static/accrue_admin.css` - PASS. Asset build completed and generated CSS diff check passed. The build still prints existing Storybook dev-asset warnings and exits 0.
- Bundle probe - PASS: `accrue_admin/priv/static/accrue_admin.css` contains `ax-overlay-shell`, `ax-overlay-backdrop`, `ax-overlay-panel`, `width:min(34rem,92vw)`, `transform:translateY(100%)`, and the drawer/modal/popover z-token consumers.

## Decisions Made

- The `.ax-overlay-*` classes are the canonical CSS layer contract; drawer/modal wrapper classes remain compatibility aliases for existing components and specimens.
- Drawer CSS is mobile-first, with an explicit md-down media rule so tests can lock bottom-sheet behavior and an md-up rule for right-docked desktop geometry.
- IXN-01 remains pending for the Phase 199 cross-page overlay sweep; this plan completes the Phase 195 CSS prerequisite only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed behavior-equivalent raw z-index reset**
- **Found during:** Task 1 (Add token-compliant overlay CSS)
- **Issue:** The plan-required `verify_package_docs.sh` run rejected an existing `z-index: auto` declaration on `.ax-dev-command-palette-specimen` under the FND-02 z-index guard.
- **Fix:** Removed the declaration because `auto` is the CSS initial value for `z-index`, preserving behavior while satisfying the guard.
- **Files modified:** `accrue_admin/assets/css/app.css`
- **Verification:** `bash scripts/ci/verify_package_docs.sh` passed after the fix.
- **Committed in:** `2c2104ca`

---

**Total deviations:** 1 auto-fixed (Rule 3 - blocking verifier issue)
**Impact on plan:** No product scope change; the fix was required for the plan's source guard and is behavior-equivalent.

## Issues Encountered

- The focused mix test and asset build continue to print existing PhoenixStorybook asset/registry warnings. Both commands exited 0.

## Known Stubs

None. Stub scan found no TODO/FIXME or UI placeholder data in the modified source/test files. The minified generated CSS contains existing selector text such as `.ax-input-placeholder`, which is a real CSS class name, not a data stub.

## Threat Flags

None. The security-relevant layer, hit-testing, viewport geometry, and served-CSS bundle surfaces are the planned trust boundaries T-195-17 through T-195-19; no unplanned endpoint, auth path, file access path, schema, or network surface was introduced.

## User Setup Required

None - no external service configuration required.

## Self-Check

- [x] `accrue_admin/assets/css/app.css` exists.
- [x] `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` exists.
- [x] `accrue_admin/priv/static/accrue_admin.css` exists.
- [x] Task commit `2c2104ca` exists.
- [x] Task commit `08c64a3c` exists.
- [x] Task commit `0faedcb1` exists.
- [x] Plan verification commands pass.
- [x] No generated runtime artifacts were left untracked, except the pre-existing `.planning/research/.cache/` directory.

## Self-Check: PASSED

## Next Phase Readiness

Plan 195-06 can add the DETAIL and action-menu primitives against a stable overlay CSS contract. Plan 195-07 can host Subscription detail actions in the canonical drawer knowing the source and served CSS now agree.

---
*Phase: 195-exemplar-b-subscription-detail*
*Completed: 2026-06-26*
