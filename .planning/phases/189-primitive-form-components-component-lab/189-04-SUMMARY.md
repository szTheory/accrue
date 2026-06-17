---
phase: 189-primitive-form-components-component-lab
plan: 04
subsystem: ui
tags: [css, a11y, phoenix-component, heex, design-tokens, focus-ring, aria]

# Dependency graph
requires:
  - phase: 188-foundations-hardening
    provides: Phase-188 semantic tokens (--ax-disabled-*, --ax-readonly-*, --ax-status-danger-*, --ax-focus-ring, --ax-type-label-font, --ax-type-body-sm-font) consumed here
  - phase: 189-primitive-form-components-component-lab (plans 01-02)
    provides: button.ex, input.ex, select.ex components that receive the root-fixes in this plan
provides:
  - CSS root-fixes: composed role tokens in .ax-button, .ax-button-sm, .ax-field-label, .ax-field-help/.ax-field-error
  - Error state token fix: --ax-status-danger-border on .ax-field-control-error; --ax-status-danger-text on .ax-field-error
  - Disabled/readonly field-control rules consuming Phase-188 semantic tokens
  - Stale outline:none focus rules on .ax-input/.ax-select/.ax-field-control removed (Phase-188 consolidated block owns the correct ring)
  - button.ex: loading attr + aria-busy emission; disabled={@disabled || @loading}
  - input.ex: single-wrapper error div with id=@id<>"-errors" (no duplicate IDs)
  - select.ex: same duplicate-error-ID fix
affects: [189-05, 190, 192]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Font shorthand (font: var(--ax-type-*-font)) + inline ax-type-exception comment for letter-spacing supplements — verifier passes"
    - "Single error wrapper div id=@id<>\"-errors\" with aria-describedby pointing to wrapper — no per-error IDs"
    - "aria-busy={if @loading, do: \"true\"} — emit attribute only when true (omit when false)"

key-files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/button.ex
    - accrue_admin/lib/accrue_admin/components/input.ex
    - accrue_admin/lib/accrue_admin/components/select.ex

key-decisions:
  - "letter-spacing supplements to font shorthand require inline ax-type-exception comment to satisfy FND-01 verifier guard"
  - "Stale local focus rules (outline:none) removed — Phase-188 consolidated :focus-visible block at line ~2941 already covers .ax-field-control and .ax-input with correct ring and takes cascade precedence"
  - ".ax-field-control:disabled added as explicit pseudo-class rule (separate from the consolidated .ax-disabled class rule which required class attribute)"

patterns-established:
  - "Error wrapper pattern: <div :if={@errors != []} id={@id <> \"-errors\"}> with <p :for> inside; described_by references -errors (plural)"
  - "Loading button: attr(:loading, :boolean, default: false); aria-busy={if @loading, do: \"true\"}; disabled={@disabled || @loading}"

requirements-completed: [CMP-03, CMP-04, CMP-05]

# Metrics
duration: 18min
completed: 2026-06-17
---

# Phase 189 Plan 04: CSS Root Fixes + HEEx Defects Summary

**Token root-fixes in app.css eliminate 8 Phase-187 defects: composed role fonts, danger error tokens, focus-ring restoration, disabled/readonly field states; button.ex adds loading/aria-busy; input.ex and select.ex eliminate axe-core duplicate-id violation via single error-wrapper div.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-17T21:47:07Z
- **Completed:** 2026-06-17T22:05:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Applied 8 surgical CSS root fixes: composed role tokens on .ax-button/.ax-button-sm/.ax-field-label; danger tokens on error states; removed stale outline:none focus rules; added explicit disabled/readonly field-control states; mobile min-height for WCAG 2.5.5
- Fixed button.ex: loading attr + aria-busy="true" emission; functionally disabled during loading state
- Fixed input.ex and select.ex: replaced multiple `id={@id <> "-error"}` per error with single `<div id={@id <> "-errors"}>` wrapper — eliminates axe-core duplicate-id violation; aria-describedby updated to reference the wrapper

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix button, field-control, and field CSS root defects in app.css** - `8c4d72ff` (fix)
2. **Task 2: Fix button.ex loading attr + aria-busy; fix input.ex and select.ex duplicate-error-ID defect** - `636be31c` (fix)

## Files Created/Modified

- `accrue_admin/assets/css/app.css` — 8 root-fixes: composed type tokens, danger error tokens, disabled/readonly field state rules, stale focus rules removed, mobile touch target
- `accrue_admin/lib/accrue_admin/components/button.ex` — loading attr, aria-busy, disabled={@disabled || @loading}
- `accrue_admin/lib/accrue_admin/components/input.ex` — error wrapper div, -errors plural ID, described_by updated
- `accrue_admin/lib/accrue_admin/components/select.ex` — same duplicate-error-ID fix as input.ex

## Decisions Made

- **letter-spacing with ax-type-exception inline comment:** The FND-01 verifier awk script flags `letter-spacing` as a raw type declaration. The fix uses the existing inline pattern (`letter-spacing: ...; /* ax-type-exception: ... */`) — the awk rule fires on `ax-type-exception:` and calls `next`, bypassing the raw-type check for the same line. This avoids the old "preceding comment line" approach that would have left a hanging block.
- **Stale local focus rules:** Removed (replaced with comment) rather than deleted entirely — the consolidated Phase-188 block at line ~2941 already covers these selectors with the correct ring. Both approaches have same end state since later rules win in CSS cascade, but removal is cleaner.
- **.ax-field-control:disabled as explicit rule:** Added near the .ax-field-control block (not relying on the consolidated `.ax-disabled` class rule, which requires the host to add the class attribute). Explicit `:disabled` pseudo-class fires automatically on native disabled inputs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] letter-spacing inline ax-type-exception comment needed for FND-01 verifier**
- **Found during:** Task 1 (CSS root fixes)
- **Issue:** After replacing raw font blocks with `font: var(--ax-type-label-font); letter-spacing: var(--ax-type-label-tracking);`, the verify_package_docs.sh FND-01 check failed — the awk script flags `letter-spacing` as a raw type declaration when not guarded by `ax-type-exception:` comment
- **Fix:** Added inline `/* ax-type-exception: letter-spacing supplements the composed label font shorthand. */` comment to each `letter-spacing` line, using the same inline pattern already established in the existing role utility classes
- **Files modified:** accrue_admin/assets/css/app.css
- **Verification:** `bash scripts/ci/verify_package_docs.sh` exits 0
- **Committed in:** 8c4d72ff (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug: verifier failure on missing ax-type-exception guard)
**Impact on plan:** Essential for CI compliance. No scope change.

## Issues Encountered

- Pre-existing test failures (3 tests: `AccrueAdmin.DashboardLiveTest`, `AccrueAdmin.Queries.QueryModulesTest` ×2) confirmed pre-existing via git stash verification — unchanged count before/after all changes. Out of scope.

## Self-Check

- [x] `accrue_admin/assets/css/app.css` modified — verified via `grep -c`
- [x] `accrue_admin/lib/accrue_admin/components/button.ex` — `aria-busy` present, `loading` attr present
- [x] `accrue_admin/lib/accrue_admin/components/input.ex` — `id <> "-errors"` present, old `id <> "-error"` gone (count=0)
- [x] `accrue_admin/lib/accrue_admin/components/select.ex` — same
- [x] `bash scripts/ci/verify_package_docs.sh` exits 0
- [x] `mix test` — 269 tests, 3 pre-existing failures (unchanged)

## Next Phase Readiness

- Plan 05 may now proceed to write to app.css — the button/field/focus selector regions (lines 1268–2917 range) are finalized; Plan 05 targets the status-badge and new-primitive CSS blocks
- Component root fixes are complete; no per-page patches needed (CMP-05 satisfied)
- Phase 190 group composition work may rely on these root fixes being stable at the primitive level

---
*Phase: 189-primitive-form-components-component-lab*
*Completed: 2026-06-17*
