---
phase: 189-primitive-form-components-component-lab
plan: "05"
subsystem: accrue_admin/css
tags: [css, design-system, status-badge, primitive-components, tokens]
dependency_graph:
  requires: ["189-04"]
  provides: ["189-06"]
  affects: ["accrue_admin/assets/css/app.css", "accrue_admin/lib/accrue_admin/components/status_badge.ex"]
tech_stack:
  added: []
  patterns:
    - "Phase-188 status semantic tokens (--ax-status-{role}-bg/text/border) consuming pattern"
    - "Composed font shorthand token (font: var(--ax-type-label-sm-font)) replaces raw font-size/weight/line-height"
    - "New primitive CSS: inline-id overflow contract, tooltip z-layer, toggle track/thumb, spinner with reduced-motion, empty-state tokens"
key_files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
decisions:
  - "StatusBadge color-mix() blocks replaced unconditionally with Phase-188 semantic status tokens at original location; Plan 04's semantic grouping block retained as secondary reinforcement (both point to same token values)"
  - ".ax-status-badge-ink maps to neutral (not danger); removed from Plan 04's danger grouping block to avoid semantic mismatch"
  - ".ax-empty replaced with flex (not grid) per plan spec to align all children centrally"
  - "status_badge.ex already had aria-hidden on dot; no component file changes required"
metrics:
  duration: "8 min"
  completed: "2026-06-17T22:01:07Z"
  tasks_completed: 3
  files_modified: 1
---

# Phase 189 Plan 05: StatusBadge Token Migration + New Primitive CSS Summary

StatusBadge color-mix formulas replaced with Phase-188 semantic status tokens; 5 new primitive CSS blocks (inline-id, tooltip, toggle, spinner, empty-state) added with full token consumption; status_badge.ex verified non-interactive.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1a | StatusBadge CSS migration to Phase-188 status tokens; type token fix | 5d1c5eb8 | assets/css/app.css |
| 1b | New primitive CSS additions (Fixes 4–8) | e6d8c086 | assets/css/app.css |
| 2 | Verify status_badge.ex — no interactive affordances (verification only) | e6d8c086 | none (component already correct) |

## Changes Made

### Task 1a — StatusBadge CSS Fixes 1–3

**FIX 1 — Type token:** `.ax-status-badge` base block replaced raw `font-size: 0.875rem; font-weight: 600; line-height: var(--ax-leading-normal)` with `font: var(--ax-type-label-sm-font)` + tracking supplement. Removed stale `ax-type-exception` comment (selector is now token-composed).

**FIX 2 — No-cursor contract (CMP-03):** Verified `.ax-status-badge` has no `cursor: pointer` and no `:hover` background shift. `transition: var(--ax-transition-colors)` retained (handles LiveView status-change patches, not user hover). No changes needed.

**FIX 3 — color-mix → status token migration:** All five tone blocks replaced unconditionally:
- `.ax-status-badge-moss` → `--ax-status-success-{bg/text/border}`
- `.ax-status-badge-cobalt` → `--ax-status-info-{bg/text/border}`
- `.ax-status-badge-amber` → `--ax-status-warning-{bg/text/border}`
- `.ax-status-badge-slate` → `--ax-status-neutral-{bg/text/border}`
- `.ax-status-badge-ink` → `--ax-status-neutral-{bg/text/border}` (ink is "unknown" status → neutral, not danger)

Also removed `.ax-status-badge-ink` from Plan 04's danger semantic grouping block (it had been incorrectly co-grouped with `.ax-badge-danger`).

### Task 1b — New Primitive CSS Additions (Fixes 4–8)

**FIX 4 — Inline ID:** Added `.ax-inline-id` with `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` overflow contract. Uses `--ax-type-code-font`, `--ax-type-code-tracking`, `--ax-sunken`, `--ax-radius-sm`, `--ax-space-xs`.

**FIX 5 — Tooltip:** Added `.ax-tooltip-wrapper` / `.ax-tooltip-content` with `z-index: var(--ax-z-popover)` (300). CSS-only opacity-based show/hide (no JS needed). Positional modifiers: `.ax-tooltip-above` / `.ax-tooltip-below`.

**FIX 6 — Toggle:** Added `.ax-toggle` / `.ax-toggle-thumb` with `--ax-border`, `--ax-accent-strong`, `--ax-disabled-{bg/cursor/opacity}`, `--ax-transition-colors`, `--ax-transition-base`. Thumb slides via `transform: translateX(1rem)` when `aria-checked="true"`. No raw ms or cubic-bezier.

**FIX 7 — Spinner:** Replaced minimal `color: var(--ax-muted)` stub with full implementation: `border-top-color: var(--ax-accent-strong)`, `animation: ax-spin var(--ax-dur-3) linear infinite`, size modifiers (sm/md/lg), `@keyframes ax-spin`, reduced-motion media query.

**FIX 8 — Empty state:** Replaced `.ax-empty` / `.ax-empty-icon` / `.ax-empty-title` / `.ax-empty-copy` with corrected token-consuming rules. Changed from `display: grid; justify-items: center` to `display: flex; flex-direction: column; align-items: center`. `.ax-empty-icon` color corrected from `--ax-success` to `--ax-muted`. `.ax-empty-title` now uses `font: var(--ax-type-title-font)`. Added `.ax-empty-actions` utility. No `cursor: pointer` or `:hover` on `.ax-empty`.

### Task 2 — StatusBadge.ex Verification

Component verified as already non-interactive:
- No `phx-click`, `onclick`, `href`, or click handlers on outer `<span>`
- No `tabindex` attribute
- No `cursor: pointer` via inline style
- No `role="button"` or interactive role
- `.ax-status-dot` already has `aria-hidden="true"`
- Label text conveys status (color is supplementary signal only)

No component file changes required. CMP-03 no-misleading-affordance contract satisfied.

**MoneyFormatter scan:** No pages in `accrue_admin/lib/accrue_admin/live/` pass CSS overriding classes to `.ax-money` spans. Clean.

**JsonViewer note:** `.ax-card ax-json-viewer` double-class on outer section is a lab-specimen-level concern (Plan 03 registry). No component file change needed here.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ax-status-badge-ink incorrectly grouped with danger in Plan 04 semantic block**
- **Found during:** Task 1a
- **Issue:** Plan 04's semantic grouping at ~line 3052 co-grouped `.ax-status-badge-ink` with `.ax-badge-danger`, `.ax-flash-error`, etc. — mapping ink to danger tokens. Per the 189 plans and status_badge.ex `status_tone/1`, ink is the catch-all "unknown/other" status → should be neutral, not danger.
- **Fix:** Removed `.ax-status-badge-ink` from the danger grouping. The individual `.ax-status-badge-ink` block (now at its original location) correctly maps to `--ax-status-neutral-*`.
- **Files modified:** accrue_admin/assets/css/app.css
- **Commit:** 5d1c5eb8

**2. [Rule 2 - Missing] ax-type-exception comment on new .ax-inline-id letter-spacing**
- **Found during:** Task 1b verify_package_docs.sh run
- **Issue:** verify_package_docs.sh FND-01 check flagged the new `letter-spacing: var(--ax-type-code-tracking)` in `.ax-inline-id` as a raw type declaration without the required `ax-type-exception` marker.
- **Fix:** Added inline comment `/* ax-type-exception: letter-spacing supplements the composed code font shorthand. */` on the letter-spacing declaration.
- **Files modified:** accrue_admin/assets/css/app.css
- **Commit:** e6d8c086

## Verification Results

```
grep -c "ax-status-success-bg" accrue_admin/assets/css/app.css  → 3 (non-zero ✓)
grep "color-mix" ... | grep "status-badge"                      → 0 matches ✓
grep "ax-z-popover" accrue_admin/assets/css/app.css             → 5 (non-zero ✓)
grep -c "ax-inline-id" accrue_admin/assets/css/app.css          → 1 (non-zero ✓)
grep -c "ax-dur-3" accrue_admin/assets/css/app.css              → 4 (non-zero ✓)
grep "phx-click|role=\"button\"" status_badge.ex                → 0 matches ✓
bash scripts/ci/verify_package_docs.sh                          → exits 0 ✓
mix test                                                        → 269 tests, 3 pre-existing failures (no regressions) ✓
```

Pre-existing test failures (confirmed by stash+test before our changes):
- `DashboardLiveTest` "$42.50" seed assertion — seed data issue, pre-existing
- 2× `QueryModulesTest` connect/coupon query filter failures — pre-existing

## Known Stubs

None. All new CSS blocks consume live Phase-188 tokens. No placeholder text or hardcoded values in the component layer.

## Threat Flags

None. Changes are CSS-only affecting the dev-lab and production component classes. No new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

- [x] `accrue_admin/assets/css/app.css` exists and contains required tokens
- [x] Commit `5d1c5eb8` exists (Task 1a)
- [x] Commit `e6d8c086` exists (Task 1b)
- [x] `verify_package_docs.sh` exits 0
- [x] Test suite: 269 tests, same 3 pre-existing failures (no regression)
