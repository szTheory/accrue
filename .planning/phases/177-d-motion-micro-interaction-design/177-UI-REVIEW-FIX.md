---
phase: 177
fixed_at: 2026-06-04T16:26:40Z
review_path: .planning/phases/177-d-motion-micro-interaction-design/177-UI-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 177 — UI Review Fix Report

**Fixed at:** 2026-06-04T16:26:40Z
**Source review:** .planning/phases/177-d-motion-micro-interaction-design/177-UI-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

---

## Fixed Issues

### Fix #1: `.ax-status-badge` missing `--ax-transition-colors` (Surface #9)

**Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
**Commit:** e718b5f8
**Applied fix:** Added `transition: var(--ax-transition-colors);` to the `.ax-status-badge` rule at `app.css:1146`. The rule previously had only `padding` — the colors bundle was present on `.ax-badge` (line 1295) but not on `.ax-status-badge`, the component used on customer/subscription/invoice detail pages for live status indicators (e.g. `active`/`past_due`, `open`/`paid`). Badge tone changes now animate instead of snapping. The bundle routes through the Phase-174 reduced-motion override automatically.

---

### Fix #2: More ▾ menu animation was a structural no-op (Surface #3)

**Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/priv/static/accrue_admin.css`, `accrue_admin/priv/static/accrue_admin.js`
**Commit:** e49fb68e
**Applied fix:** The `<ul class="ax-tab-more-menu">` used `:if={@more_tabs_open}`, meaning LiveView DOM-mounted and removed it — the base CSS state (opacity 0, translateY) never existed in the closed state, so the CSS transition could never fire. Added `phx-mounted` (`JS.show`, `time: 180`, class tuple `ax-tab-more-entering / ax-tab-more-enter-from / ax-tab-more-enter-to`) and `phx-remove` (`JS.hide`, `time: 140`, class tuple `ax-tab-more-leaving / ax-tab-more-leave-from / ax-tab-more-leave-to`) to the `<ul>` element, mirroring the `flash_group.ex` pattern. Added the six supporting CSS classes: enter from-state (opacity 0, translateY(-rise-sm)), entering transition (opacity + transform, --ax-dur-2 --ax-ease-out), enter to-state; leave from-state (opacity 1), leaving transition (opacity, --ax-dur-exit --ax-ease-in), leave to-state (opacity 0). The existing `.ax-tab-more-open .ax-tab-more-menu` CSS toggle is kept harmless. The stale Plan-03 "exit is instant" comment was updated.

---

### Fix #3: Command palette exit has no asymmetry (Surface #5/#5b)

**Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
**Commit:** b6a2c68f
**Applied fix:** The CSS approach for the palette uses `data-open="true"` as the open-state selector. Previously both base and open states used the same symmetric transition declaration (`--ax-dur-2 --ax-ease-out`). Fixed by moving the exit transition to the base/closed state rules and the enter transition to the `[data-open="true"]` override selectors — this is the correct CSS pattern because the base-state transition fires on close (exit) and the open-state transition fires on open (enter). `.ax-command-palette` base now carries `transition: opacity var(--ax-dur-exit) var(--ax-ease-in)` (snappy fade-only, no scale-out). `.ax-command-palette-backdrop` base likewise has the exit transition. The `[data-open="true"]` selectors add `transition: opacity var(--ax-dur-2) var(--ax-ease-out)` for backdrop and `transition: opacity var(--ax-dur-2) var(--ax-ease-out), transform var(--ax-dur-2) var(--ax-ease-emphasis)` for the palette (the earned overshoot is enter-only, correct per contract).

---

### Fix #4: Command palette focus-return on close (WCAG 2.4.3)

**Files modified:** `accrue_admin/assets/js/hooks/command_palette.js`, `accrue_admin/priv/static/accrue_admin.js`
**Commit:** 4dd9919e
**Applied fix:** Added focus save/restore to the `CommandPalette` hook. `mounted()` initializes `this.previousFocus = null` and `this.wasOpen` from the current `data-open` state. `updated()` detects the open/close transition by comparing `isOpen` to `this.wasOpen`: on open, it saves `document.activeElement` to `this.previousFocus` before moving focus to the input (the existing `setTimeout(() => input.focus(), 0)` is preserved); on close, it restores focus to `this.previousFocus` via a deferred `setTimeout` so the focus ring appears after the exit transition completes. `this.wasOpen` is updated at the end of `updated()` to track state for the next call.

---

## Skipped Issues

None — all 4 in-scope findings were fixed.

---

## Deferred (out of scope per prompt)

- **Dropdown instant exit** (Surface #2, WARNING): native `<details>` removes `[open]` synchronously; CSS exit transition cannot fire. Acknowledged limitation per the Phase 177 spec. Requires a non-`<details>` disclosure component to fix properly. Deferred to a future phase.
- **Flash dismiss button** (INFO, pre-existing): flash dismissal is server-driven; no dismiss button implemented. Pre-existing design limitation not introduced in Phase 177.
- **Dropdown Escape handling** (INFO, pre-existing): native `<details>` does not close on Escape. Pre-existing accessibility gap not introduced or worsened by Phase 177.

---

## Verification

All four fixes were verified with:
1. Tier 1: re-read modified files, confirmed fix text present and surrounding code intact.
2. Tier 2 (assets build): `cd accrue_admin && mix accrue_admin.assets.build` — passed, priv/static rebuilt.
3. Test suite: `cd accrue_admin && mix test --seed 0` — **254 tests, 0 failures** (no regression from the baseline 254 green).
4. Antipattern guard: `bash scripts/ci/verify_package_docs.sh` from repo root — **EXIT 0** (no raw ms literals, no cubic-bezier, no transition:all, no layout props in transitions).

---

_Fixed: 2026-06-04T16:26:40Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
