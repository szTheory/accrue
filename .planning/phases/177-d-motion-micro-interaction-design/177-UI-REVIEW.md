---
phase: 177
slug: d-motion-micro-interaction-design
reviewed: 2026-06-04
baseline: 177-UI-SPEC.md (approved motion contract)
screenshots: not captured (code-only audit per scope_note — motion is non-visual in static screenshots; Phase 179 trace/video pass handles visual proof)
registry_audit: not applicable (no shadcn, no third-party registries)
---

# Phase 177 — UI Review

**Audited:** 2026-06-04
**Baseline:** 177-UI-SPEC.md (approved motion contract)
**Screenshots:** not captured — code-only audit (motion non-visual in static; Phase 179 trace pass)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | No new copy introduced; existing frozen strings conform to spec |
| 2. Visuals (Motion) | 2/4 | Two contract deviations: command palette exit lacks asymmetry; `.ax-status-badge` missing `--ax-transition-colors` |
| 3. Color | 4/4 | No new color usage; all motion surfaces use inherited token-defined colors only |
| 4. Typography | 4/4 | No new typography introduced; frozen from Phase 167/174 |
| 5. Spacing | 4/4 | No new spacing; all travel uses `--ax-rise-sm/md` tokens, no raw px |
| 6. Experience Design | 3/4 | More ▾ menu animation is a no-op due to `:if` conditional rendering; command palette has no focus-return on close |

**Overall: 21/24**

---

## Top 3 Priority Fixes

1. **`ax-status-badge` missing `--ax-transition-colors`** — motion contract surface #9 explicitly lists `.ax-status-badge` as a target; badge tone changes (e.g. invoice → paid) animate on `.ax-badge` but not on `.ax-status-badge`, which is the component used on customer/subscription detail pages. Fix: add `transition: var(--ax-transition-colors);` to the `.ax-status-badge` rule block at `app.css:1083`.

2. **Command palette exit has no asymmetry** — the motion spec requires `--ax-dur-exit` + `--ax-ease-in` on close, but the CSS uses a single base `transition` declaration (`--ax-dur-2 --ax-ease-out`) that fires in both directions. The backdrop likewise has no exit easing variation. Fix: add a `[data-open="false"]` or a `.ax-command-palette-closing` transition override that replaces the base transition with `opacity var(--ax-dur-exit) var(--ax-ease-in)` before the wrapper's data-open flips, OR use a `phx-remove` / JS.hide tuple approach (mirrors drawer/flash pattern already in codebase) instead of the data-open CSS toggle.

3. **More ▾ menu animation is a structural no-op** — the `.ax-tab-more-menu` CSS rule (`opacity 0`, `translateY(-rise-sm)`) requires the element to be in the DOM in its closed state so the CSS transition can fire. But `customer_live.ex:269` uses `:if={@more_tabs_open}`, meaning the element is mount/removed by LiveView. On open, it appears already under `.ax-tab-more-open` so jumps directly to opacity 1 with no enter animation. Exit has no `phx-remove` so also has no animation. Fix: add `phx-mounted` / `phx-remove` `JS.show/hide` tuples to the `<ul>` element using the same `ax-flash-*` class pattern (small translateY + opacity fade — already in CSS as the More ▾ motion block, but the JS side was explicitly deferred and never added).

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

Per the UI-SPEC: "Phase 177 ships NO new copy. Motion is non-textual." Confirmed — no new CTA labels, empty states, or error strings were added in Plans 01–06. Existing frozen copy (`"Look up a customer"`, `"Clear the invoice queue"`, `"Notice"`, `"Action required"`, `"Warning"`, `"Update"`, `"Nothing needs attention"`) is present and unchanged. The flash title fallback chain (`flash_title/1` in `flash_group.ex:27-31`) uses action-oriented, specific strings consistent with the design-system copy contract.

No findings.

---

### Pillar 2: Visuals — Motion (2/4)

This pillar is the load-bearing one for Phase 177. Audit checks each of the 9 contract surfaces against the implemented code.

**Surface #1 — Detail drawer (PASS)**
`detail_drawer.ex:30-31` — `phx-mounted` uses `ax-drawer-enter-from/entering/enter-to` (opacity 0 + translateX `--ax-rise-md`, `--ax-dur-3 --ax-ease-out`); `phx-remove` uses `ax-drawer-leave-from/leaving/leave-to` (fade-only, `--ax-dur-exit --ax-ease-in`). Enter/exit asymmetry correctly implemented. Token-clean; no raw literals.

**Surface #1b — Drawer backdrop (PASS)**
`detail_drawer.ex:37-38` — matching `ax-drawer-backdrop-entering/leave` class tuples with `--ax-dur-3 --ax-ease-out` enter, `--ax-dur-exit --ax-ease-in` exit. Correct.

**Surface #2 — Dropdown menu (PARTIAL PASS — WARNING)**
`app.css:1629-1643` — `details.ax-dropdown .ax-dropdown-panel` has opacity 0 + translateY `--ax-rise-sm` base state with `--ax-dur-2 --ax-ease-out` enter. Correct enter. However, exit is instant (native `<details>` removes `[open]` synchronously; no CSS exit transition fires). The UI-SPEC acknowledges this in the motion contract comment ("accepted per Phase 177 scope") and the SUMMARY also notes this. The spec table says exit should use `--ax-dur-exit --ax-ease-in`, but the implementation notes this is structurally impossible via `<details>` CSS alone. This is a known documented limitation, not a new finding — recorded as a minor note, not a blocker.

**Surface #3 — More ▾ overflow menu (FAIL — WARNING)**
`customer_live.ex:269` uses `:if={@more_tabs_open}` — the `<ul class="ax-tab-more-menu">` is conditionally mounted/removed by LiveView. The CSS rule at `app.css:1427-1442` requires the element to be in the DOM in its base state (opacity 0, translateY) for the CSS transition to fire. Since the element does not exist when `more_tabs_open` is false, there is no element on which the base state applies. On open: the element mounts already inside `.ax-tab-more-open`, so it renders at opacity 1 with no enter animation. On close: LiveView removes the element immediately (no `phx-remove`), so there is no exit animation either. The Plan 03 summary acknowledges this but frames it as "pure CSS class toggle" working — it does not. The Plan 02 SUMMARY comment "Exit is instant when :if={@more_tabs_open} removes the element" confirms the exit is unintentionally instant, but does not note the enter is also broken.

**Surface #4 — Collapsible nav group (PASS)**
`sidebar_collapse.js:41-81` — transitionend two-step correctly implemented. The reduced-motion stuck-state bug (CR-01 from the code review) was fixed before this UI audit: `getComputedStyle(list).transition-duration` is read and if `<= 0.001`, `hidden` is set synchronously. Expand: `list.removeAttribute("hidden")` + `list.classList.remove("ax-collapsed")` (CSS opacity 0→1 fires via `ax-sidebar-group-links`). Collapse: `.ax-collapsed` added, `--ax-dur-exit --ax-ease-in` fires, then `hidden` set on `transitionend`. Correct.

Chevron rotate: `app.css:1334` — `transition: var(--ax-transition-transform)` on `.ax-sidebar-group-chevron`. The rotate is driven by `[aria-expanded="true"]` parent, which the JS sets. Correct.

**Surface #5 — Command palette (PARTIAL FAIL — WARNING)**
`app.css:1786-1808` — Panel enter uses `opacity var(--ax-dur-2) var(--ax-ease-out), transform var(--ax-dur-2) var(--ax-ease-emphasis)`. Enter asymmetry with `--ax-ease-emphasis` for the one earned scale overshoot is correct per contract. However, the base `transition` declaration on `.ax-command-palette` is used for BOTH enter and exit (CSS transitions are symmetric by default unless overridden with a separate state). When `data-open` flips to `false`, the same `--ax-dur-2 --ax-ease-out` fires as the exit — this violates the motion contract which specifies `--ax-dur-exit + --ax-ease-in` for exit (row #5, exit column: "opacity --ax-dur-exit --ax-ease-in"). The palette stays on screen for 180ms rather than 140ms, and eases out instead of in. The "snappy dismissal" affordance of the asymmetric exit is not delivered.

**Surface #5b — Palette backdrop (PARTIAL FAIL — WARNING)**
`app.css:1762-1769` — Backdrop uses `transition: opacity var(--ax-dur-2) var(--ax-ease-out)`. A single declaration means close also uses `--ax-dur-2 --ax-ease-out`. The contract specifies `--ax-dur-exit --ax-ease-in` for exit (row #5b). Minor deviation — the backdrop feel is close to correct but the exit asymmetry is missing.

**Surface #6 — Tabs active indicator (PASS)**
`app.css:1671` — `.ax-tab` has `transition: var(--ax-transition-colors)`. Active state `.ax-tab-active` changes `border-bottom-color` and `color`. Color crossfade on active-tab navigation is correct. No slide (correct — link-based tabs with no continuous element). Contract satisfied.

**Surface #7 — Flash / toasts (PASS)**
`flash_group.ex:17-18` — `phx-mounted` uses `ax-flash-entering/from/to` (opacity 0 + translateY `-rise-sm`, `--ax-dur-2 --ax-ease-out`); `phx-remove` uses `ax-flash-leaving/from/to` (fade-only, `--ax-dur-exit --ax-ease-in`). Enter/exit asymmetry correct. Token-clean.

**Surface #8 — Skeleton to content (PASS)**
`data_table.ex:185` — `phx-mounted` on the `:if={!Enum.empty?(@rows)}` wrapper uses `ax-content-entering/from/to` (opacity 0→1, `--ax-dur-2 --ax-ease-out`). Content fades in where the skeleton was. No exit transition needed (skeleton is removed by LiveView patch). Correct.

**Surface #9 — Badge / state change (PARTIAL FAIL — WARNING)**
`app.css:1295` — `.ax-badge` has `transition: var(--ax-transition-colors)`. Correct for `.ax-badge`.
However, `.ax-status-badge` at lines 1083 and 1146 has no `transition` property. The motion contract row #9 explicitly lists `.ax-status-badge` alongside `.ax-badge`. The `.ax-status-badge` is the component used throughout customer, invoice, and subscription detail pages for live status indicators (e.g., subscription `active`/`past_due`, invoice `open`/`paid`). Status changes on these badges produce an instant color snap instead of a `--ax-transition-colors` crossfade.

**Antipattern guard (PASS)**
`scripts/ci/verify_package_docs.sh:328-344` — all four banned patterns are guarded: `transition: all` (A1), raw `cubic-bezier(` (A3), raw `ms/s` in transition rules except `ax-skeleton-shimmer` (A3), layout properties in transition lists (A2). Guard is correctly paired with negative tests in `package_docs_verifier_test.exs`. 14 verifier tests green.

Confirmed zero raw literal violations: `grep -E "(transition|animation):[^;]*[0-9]+(ms|s)\b" app.css | grep -v "ax-skeleton-shimmer"` returns only the comment `/* 180ms enter */` — no CSS rule violations.

**Summary for this pillar:** 7 of 9 surfaces are fully implemented per contract. Surface #3 (More ▾) has no animation at runtime. Surface #5/#5b (palette) exits with the wrong easing and duration. Surface #9 (`.ax-status-badge`) missing `--ax-transition-colors`. Score: 2/4.

---

### Pillar 3: Color (4/4)

Phase 177 introduces no new color values. All motion surfaces use existing `--ax-accent`, `--ax-elevated`, `--ax-border`, `--ax-primary`, `--ax-muted`, `--ax-accent-subtle`, and `--ax-accent-readable` tokens from the locked Phase 167/174 design system. The backdrop uses `color-mix(in srgb, var(--accrue-ink) 34%, transparent)` (existing token pattern from Phase 174). No hardcoded hex or `rgb()` values were introduced in the new motion rules. The 60/30/10 distribution is unchanged.

No findings.

---

### Pillar 4: Typography (4/4)

Phase 177 introduces no new typography. The `/dev/components` motion reference section added in Plan 06 uses existing `.ax-label`, `.ax-eyebrow` classes. No new `font-size`, `font-weight`, or `line-height` values were added.

No findings.

---

### Pillar 5: Spacing (4/4)

All motion travel uses `--ax-rise-sm` (4px) and `--ax-rise-md` (8px) tokens. No raw `px` or `rem` values in motion rules. The `.ax-command-palette` width `min(42rem, calc(100vw - 2rem))` and `padding: 10vh var(--ax-space-md) var(--ax-space-md)` on the wrapper are existing values. No new spacing was introduced by motion work.

No findings.

---

### Pillar 6: Experience Design (3/4)

**More ▾ — no animation affordance (WARNING)**
As described in Pillar 2 #3: the More ▾ menu enters and exits without animation because it uses `:if`-based DOM mount/remove but has no `phx-mounted`/`phx-remove` transitions wired. The menu still functionally opens and closes; it just has no motion affordance. The UX gap is that the menu appears/disappears abruptly rather than with the small translateY enter that communicates spatial origin. The CSS is correct and ready; only the JS tuples are missing.

**Command palette — no focus return on close (WARNING)**
`command_palette.js` focuses the search input on open (`updated()` line 21: `input.focus()` via `setTimeout`). However, on Escape or backdrop close, the component dispatches a `"close"` event to the LiveView (`pushEventTo(target, "close", {})`), which sets `is_open: false`. There is no corresponding `focus` restoration to the element that triggered the palette (e.g., the Cmd-K search button in the shell). The `step_up_auth_modal` pattern (which the motion spec cites as the mirror template) uses `JS.push_focus`/`JS.pop_focus`. The command palette does not. After closing the palette with Escape, keyboard focus is lost (dropped to `document.body`) — a WCAG 2.1 §2.4.3 Focus Order failure.

`detail_drawer.ex` similarly has `aria-modal="true"` but no focus trap or `JS.push_focus`/`JS.pop_focus`. The close button (fixed in CR-02) now has `{@rest}` which allows `phx-click` handlers, but focus return is the caller's responsibility with no documented pattern.

**Flash — no dismiss mechanism (INFO — pre-existing)**
`flash_group.ex` has no dismiss button — the spec's copywriting contract lists "flash dismiss" as a motion surface (exit: `phx-remove`), but dismissal is server-driven (the flash disappears when the server removes it from the assigns). This is a pre-existing design limitation; the `phx-remove` exit animation wired in Plan 03 correctly handles the server-driven removal. Not a new gap introduced in Phase 177.

**Dropdown — no keyboard Escape handling (INFO — pre-existing)**
`dropdown_menu.ex` wraps a native `<details>` element. Native `<details>` does not close on Escape in most browsers. No JS hook handles Escape for the dropdown. This is a pre-existing accessibility gap not introduced or worsened by Phase 177 motion work.

**Loading states, error states, empty states: unchanged (PASS)**
All existing state coverage from prior phases is intact. `data_table.ex` skeleton/spinner patterns unchanged. `global_search.ex` empty state, loading state, and no-results state unchanged.

---

## Registry Safety

Not applicable — no `components.json` found; project uses in-repo Phoenix.Component / Phoenix.LiveComponent exclusively. No third-party registries.

---

## Files Audited

- `accrue_admin/guides/motion.md` — authoritative motion catalog (Plan 01)
- `.planning/phases/177-d-motion-micro-interaction-design/177-UI-SPEC.md` — motion contract baseline
- `accrue_admin/assets/css/app.css` — transition rules, motion class tuples, badge transitions, sidebar, skeleton content classes (Plans 02–04)
- `accrue_admin/assets/css/theme.css` — token definitions, reduced-motion override at line 187
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` — phx-mounted/phx-remove wiring (Plan 03)
- `accrue_admin/lib/accrue_admin/components/flash_group.ex` — phx-mounted/phx-remove wiring (Plan 03)
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — data-open refactor (Plan 04)
- `accrue_admin/lib/accrue_admin/components/sidebar.ex` — ax-sidebar-group-links class (Plan 02)
- `accrue_admin/lib/accrue_admin/components/tabs.ex` — tabs structure (confirms CSS-only approach)
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` — details-based disclosure (confirms CSS-only approach)
- `accrue_admin/lib/accrue_admin/components/data_table.ex` — phx-mounted content fade (Plan 03)
- `accrue_admin/assets/js/hooks/sidebar_collapse.js` — transitionend two-step, reduced-motion guard (Plan 02 + fix)
- `accrue_admin/assets/js/hooks/command_palette.js` — data-open, focus management (Plan 04)
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — More ▾ ax-tab-more-open class toggle (Plan 03)
- `accrue_admin/e2e/reduced-motion.spec.js` — Playwright reduced-motion checks (Plan 06)
- `scripts/ci/verify_package_docs.sh` — motion antipattern guards (Plan 05)
- `.planning/phases/177-d-motion-micro-interaction-design/177-REVIEW.iter2.md` — prior code review findings
- `.planning/phases/177-d-motion-micro-interaction-design/177-REVIEW-FIX.iter2.md` — confirmed fixes applied
