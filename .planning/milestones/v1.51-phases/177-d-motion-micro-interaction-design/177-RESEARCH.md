# Phase 177: D — Motion & Micro-interaction Design - Research

**Researched:** 2026-06-04
**Domain:** CSS transition application, Phoenix.LiveView.JS, Playwright reduced-motion testing
**Confidence:** HIGH — all findings from direct codebase inspection

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Motion spec doc & antipattern list (MOT-01)**
- Spec location: `accrue_admin/guides/motion.md` + live reference section in `/dev/components`
- Per-element documentation: element · trigger · animated property + token · enter/exit · reduced-motion fallback · functional justification
- Antipattern list = Emil Kowalski principles; enforcement via grep guard extending the existing token-bypass guard (transition:all ban + raw ms/cubic-bezier literals + layout-thrash props)
- Guard needle must be added to BOTH the guard script AND its negative-test seed fixture

**Per-component motion application (MOT-02)**
- Surfaces: detail_drawer, dropdown_menu, More ▾, collapsible nav, global_search palette, tabs, flash/toasts, skeleton→content, badge/state changes
- ALL via Phase-174 `--ax-transition-*` bundles — never hardcoded ms/curves
- Mechanism: CSS transitions on data-state/hidden toggles preferred; `Phoenix.LiveView.JS` show/hide for genuine mount/remove (mirror step_up_auth_modal)
- Enter/exit asymmetry: `--ax-ease-out` enter, `--ax-dur-exit` + ease-in exit (snappy dismiss)

**Reduced-motion & verification (MOT-03)**
- Honor existing token-level override (theme.css:187 — bundles collapse to `--ax-dur-instant`)
- Extend Phase-174 D-15 test (`e2e/reduced-motion.spec.js`) to assert newly-animated surfaces collapse
- Add Playwright structural check emulating `prefers-reduced-motion: reduce` — no transform travel on drawer/dropdown

### Claude's Discretion
- Exact per-component durations within 150–300ms and enter/exit easing pairing (must compose from existing atoms, no literals)
- Whether tabs use indicator-slide vs crossfade (RESOLVED in UI-SPEC: crossfade — tabs are link-based, no continuous element for a slide)
- Exact shape of `motion.md` table and `/dev/components` motion reference section
- Whether to introduce `--ax-dur-exit` consumption pattern or reuse existing atom (RESOLVED: reuse existing atoms — no new tokens needed)

### Deferred Ideas (OUT OF SCOPE)
- Motion trace/video QA sign-off → Phase 179 (F)
- Seed/state coverage so every animated state is reachable → Phase 178 (E)
- Any net-new motion-only tokens beyond the 174 atoms — compose from existing; escalate only if genuine gap appears

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOT-01 | A documented motion/interaction spec defines what animates, why, which token, and reduced-motion behavior, including an antipattern list grounded in researched best practice | UI-SPEC.md is the approved spec (9 surfaces × 6 columns); motion.md guide needs creating at `accrue_admin/guides/motion.md`; enforcement guard extends existing breakpoint guard in `scripts/ci/verify_package_docs.sh` |
| MOT-02 | Drawers, dropdowns, command palette, tabs, flash/toasts, skeleton→content animate via design-token transition bundles — functional, not decorative | Each surface's current show/hide mechanism verified — see Per-Surface Mechanism Table; CSS changes go in `app.css`; JS.transition for detail_drawer and global_search |
| MOT-03 | All admin motion honors prefers-reduced-motion (no travel/overshoot; crossfades retained), verified by an automated check | `e2e/reduced-motion.spec.js` exists and has the two-test pattern to extend; all new surfaces must route through bundles whose tokens are already overridden at theme.css:187 |

</phase_requirements>

---

## Summary

Phase 177 applies the motion vocabulary from Phase 174 — already defined in `theme.css` — to the admin's interactive surfaces. The token system is complete and the reduced-motion override is wired. The work is 90% CSS rules and 10% JS.transition calls, plus guard script + test fixture updates, plus two Playwright test extensions. No new tokens, no new components.

The central insight for the planner: **three surfaces need JS-level help** (detail_drawer, global_search, and flash_group) because they mount/remove from the DOM rather than toggling a CSS attribute. For these, `Phoenix.LiveView.JS.show/hide` with transition tuples is the correct mechanism — mirroring `step_up_auth_modal.ex` which already uses this pattern. **Six surfaces** (dropdown_menu, tabs, collapsible nav, More ▾, data_table skeleton→content, badges) are pure CSS: they toggle `[open]`, `aria-expanded`, `.ax-tab-active`, or the `hidden` attr — CSS transitions just need adding.

The enforcement guard (extend `verify_package_docs.sh`) and the test fixture (`seed_tmp_dir!` in `package_docs_verifier_test.exs`) must change in the same commit — this is the known `verify_package_docs ↔ test coupling` from project memory. Missing either side causes the six negative tests to fail.

**Primary recommendation:** Wave 1 = CSS transitions for the six pure-CSS surfaces + motion.md guide. Wave 2 = JS.transition for detail_drawer + global_search + flash_group. Wave 3 = guard script + test fixture coupling. Wave 4 = Playwright reduced-motion assertions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS transition rules (opacity, transform, colors) | Browser / Client CSS | — | Declarative, composited, cheapest path; all 9 surfaces use ax-* CSS classes |
| detail_drawer open/close animation | Frontend Server (LiveView) | Browser CSS | Drawer uses `:if={@open}` — DOM mount/remove requires JS.show/hide+transition or CSS approach via always-rendering with `hidden` |
| global_search palette open/close | Frontend Server (LiveView) | Browser CSS | Palette uses `class={if @is_open, do: "ax-command-palette-wrapper", else: "hidden"}` toggle — can be CSS-only by making the wrapper always present |
| flash_group mount animation | Frontend Server (LiveView) | Browser CSS | Flash articles appear via `:for` LiveView patch — genuine mount, needs JS.transition or CSS `@starting-style` |
| Enforcement guard | Build / CI | — | `verify_package_docs.sh` bash script + `package_docs_verifier_test.exs` ExUnit test |
| Reduced-motion verification | E2E (Playwright) | — | `e2e/reduced-motion.spec.js` — Playwright `emulateMedia` API |
| motion.md guide | Documentation | `/dev/components` reference | `accrue_admin/guides/motion.md` + `component_kitchen_live.ex` section |

---

## Standard Stack

No new packages. This phase is entirely within the existing stack.

### Core (already installed)
| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| Phoenix.LiveView.JS | ~> 1.1 | `JS.show/hide` with transition tuples for mount/remove surfaces | In use — step_up_auth_modal.ex already uses push_focus/pop_focus |
| Custom ax-* CSS tokens | Phase 174 | `--ax-transition-*` bundles, `--ax-dur-*`, `--ax-ease-*`, `--ax-rise-*` | Fully defined in theme.css; reduced-motion override at theme.css:187 |
| Playwright | accrue_admin/e2e/ | `emulateMedia({ reducedMotion: "reduce" })` for automated motion checks | In use — reduced-motion.spec.js already exists |

### Package Legitimacy Audit

Not applicable — this phase installs zero new packages.

---

## Per-Surface Current State & Mechanism

### Verified per-surface findings [VERIFIED: codebase inspection]

| # | Surface | File | Current show/hide mechanism | Existing transition | Mechanism recommendation |
|---|---------|------|-----------------------------|--------------------|-----------------------------|
| 1 | detail_drawer | `components/detail_drawer.ex` | `:if={@open}` — mounts/removes DOM entirely | None | **Option A (recommended):** Refactor to always-render with `hidden` attr + CSS transitions (simpler). **Option B:** `JS.show/hide` with transition tuples mirroring step_up_auth_modal. Option A avoids server round-trips for the close animation; Option B requires the LiveView host to pass JS actions. Per CONTEXT, either is valid — pick based on caller pattern. The existing callers set `open={@drawer_open}` as a LiveView assign; JS.transition approach works cleanly. |
| 1b | detail_drawer-backdrop | `app.css:743` `.ax-detail-drawer-backdrop` | Always inside the `:if={@open}` section — same as drawer | None | Same as #1 — tied to drawer DOM |
| 2 | dropdown_menu | `components/dropdown_menu.ex` | `<details open>` — native `[open]` attribute toggle by browser | None on `.ax-dropdown-panel` | **Pure CSS:** add opacity + transform transition on `.ax-dropdown-panel` keyed on `details[open] .ax-dropdown-panel` — no JS needed |
| 3 | More ▾ overflow | `customer_live.ex:269` `.ax-tab-more-menu` | `:if={@more_tabs_open}` LiveView boolean toggle — mounts/removes DOM | None | **JS.transition or CSS** — since `@more_tabs_open` is a LiveView assign, recommend making `.ax-tab-more-wrapper .ax-tab-more-menu` always-rendered but `hidden` toggled by LiveView, then CSS transitions on the `hidden` → visible change. Alternatively use `JS.show/hide` in the toggle button handler. |
| 4 | collapsible nav group | `components/sidebar.ex` + `hooks/sidebar_collapse.js` | `aria-expanded` on `<section>` + JS sets `list.hidden = !expanded` on the `<div id="sidebar-group-links-*">` | `--ax-transition-transform` on `.ax-sidebar-group-chevron` (app.css:1221) — chevron rotate already wired | **Pure CSS:** add `opacity` transition to the link list `<div>` keyed on `[hidden]` selector or wrapper class. Note: `hidden` attr disables the element; to animate it, CSS must override `hidden` at the transition layer using `[hidden] { visibility: hidden; opacity: 0; }` + `transition: opacity` pattern. The JS hook's `list.hidden = true/false` is the toggle. |
| 5 | global_search palette | `components/global_search.ex` | `class={if @is_open, do: "ax-command-palette-wrapper", else: "hidden"}` CSS class swap on wrapper | None on palette or backdrop | **Pure CSS (simplest):** the wrapper already swaps `hidden` class — add opacity + transform transition to `.ax-command-palette` inside the wrapper. The `hidden` class uses `display: none` which interrupts transitions; better to use `opacity: 0; pointer-events: none` for the closed state, controlled by a `data-state` attr or by removing the `hidden` class approach. **Alternative:** keep hidden-class approach + use `@starting-style` (CSS Level 5, partially supported). Recommendation: use a `data-open` attr toggled by the LiveComponent, CSS transitions on `[data-open]`. |
| 5b | palette backdrop | same file | same | None | Same as #5 |
| 6 | tabs active indicator | `components/tabs.ex` | Full page navigation (`href=`) — `ax-tab-active` class is set server-side at render | `.ax-tab` has no transition yet; color/border are static | **Pure CSS:** add `transition: var(--ax-transition-colors)` to `.ax-tab` and `.ax-tab-active`. The color crossfade happens during page load patch (LiveView navigation). Per CONTEXT and UI-SPEC: crossfade is correct choice (link-based nav, no continuous DOM element). |
| 7 | flash / toasts | `components/flash_group.ex` | `:for={flash <- @flashes}` LiveView list patch — articles mount via LiveView diff | None on `.ax-flash` | **JS.transition (required):** flash articles are mounted by LiveView server-push — the only way to animate their entrance is `phx-mounted` with `JS.transition` or CSS `@starting-style`. Recommend `phx-mounted={JS.transition("ax-flash-enter", ...)}` pattern. |
| 8 | skeleton → content | `components/data_table.ex` | Skeleton: inline in render as `class="ax-skeleton"` applied to placeholder elements during `:loading` state. Rows mount via LiveView patch when data arrives. Skeleton shimmer: `app.css:2401` already has `animation: ax-skeleton-shimmer 1.4s ...` + reduced-motion override at `app.css:2409`. | Shimmer exists; content has none | **CSS `@starting-style` (ideal) or `phx-mounted` JS.transition** on row elements / table container. Per UI-SPEC: content opacity 0→1 crossfade. Rows mount via LiveView patch; `phx-mounted` on the table body or the content container is the reliable path. |
| 9 | badge / state change | `.ax-status-badge`, `.ax-badge`, nav attention badges (Phase 175) | Server-rendered; class changes on LiveView re-render | `.ax-status-badge` has `transition: var(--ax-transition-base)` at `app.css:1000` (inherited via button/status-badge selector at `app.css:983-1000`) | **Partially wired.** `.ax-status-badge` already inherits `--ax-transition-base`. `.ax-badge` (at app.css:1182) has no transition. Add `transition: var(--ax-transition-colors)` to `.ax-badge`. For first-appear pop: `--ax-transition-transform` + `@starting-style scale(--ax-press-scale)`. |

---

## Architecture Patterns

### Pattern 1: CSS Transition on `[open]` (Dropdown — preferred for native disclosure)

```css
/* Source: codebase verified — dropdown uses <details> element */
details.ax-dropdown .ax-dropdown-panel {
  opacity: 0;
  transform: translateY(calc(-1 * var(--ax-rise-sm)));
  /* enter transition — always present so the browser can interpolate */
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-out);
  pointer-events: none;
}

details[open].ax-dropdown .ax-dropdown-panel {
  opacity: 1;
  transform: translateY(0px);
  pointer-events: auto;
}

/* Exit: when [open] is removed, the transition above still applies.
   To get a faster exit, the trick is a separate transition on the closed state
   — but CSS currently cannot natively encode asymmetric in/out on a single property
   via [open]. For exit asymmetry on <details>, the recommended path is a data-state
   attribute toggled by the SidebarCollapse-style JS hook, OR accept symmetric
   transition (both 180ms). The UI-SPEC says exit is opacity fade-only + --ax-dur-exit;
   this requires JS or a workaround. */
```

**Important limitation for `<details>` elements:** The native `[open]` toggle happens synchronously — CSS transition on the close does not fire because the browser removes `[open]` before the transition can run. The exit fade requires JavaScript to intercept the `toggle` event, set a temporary class/attr, and remove `[open]` after the transition completes. The SidebarCollapse hook pattern shows how to do this for `aria-expanded`; the dropdown needs the same approach if an exit transition is required.

**Practical recommendation for dropdown:** Accept symmetric 180ms for the initial implementation. If exit asymmetry is wanted, add a small JS hook that adds `data-closing` before removing `[open]`, and CSS transitions on `[data-closing]`. Flag this as discretionary complexity.

### Pattern 2: CSS Transition on `hidden` attr + JS hook (Collapsible Nav — already wired)

```javascript
// Source: accrue_admin/assets/js/hooks/sidebar_collapse.js
// SidebarCollapse hook already toggles list.hidden = !expanded.
// The chevron rotation via --ax-transition-transform is already live (app.css:1221).
// To add opacity transition to the link list:
setExpanded(expanded) {
  this.el.setAttribute("aria-expanded", String(expanded));
  const list = document.getElementById(this.el.dataset.controls);
  if (list) {
    list.hidden = !expanded;
    // The hidden attr sets display:none which kills CSS transitions.
    // Solution: don't use list.hidden for the transition; use a CSS class instead.
    // list.classList.toggle("ax-collapsed", !expanded);
  }
}
```

**Key pitfall:** `element.hidden = true` sets `display: none` which immediately removes the element from layout — CSS transitions cannot animate to/from `display: none`. Two options:
1. Replace `list.hidden` with a CSS class (`ax-collapsed`) that uses `opacity: 0; pointer-events: none; visibility: hidden` and add `transition: opacity var(--ax-dur-exit) var(--ax-ease-in)` for exit.
2. Use `list.style.transition = "..."` + `list.style.opacity = "0"` in JS before setting `hidden`.

Option 1 is cleaner and keeps the JS hook simple. The `hidden` attr stays for accessibility semantics (AT will still skip hidden content); add it after the transition completes via `transitionend` listener.

### Pattern 3: Phoenix.LiveView.JS show/hide with transition (Flash / Modal pattern)

```elixir
# Source: accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
# The step_up_auth_modal uses phx-mounted / phx-remove for focus management.
# For motion: use the JS.show transition API.

# In flash_group.ex, add phx-mounted to each :for article:
<article
  :for={flash <- @flashes}
  phx-mounted={
    JS.show(transition: {"ax-flash-entering", "ax-flash-enter-from", "ax-flash-enter-to"}, time: 180)
  }
  phx-remove={
    JS.hide(transition: {"ax-flash-leaving", "ax-flash-leave-from", "ax-flash-leave-to"}, time: 140)
  }
  class={["ax-flash", flash_class(flash[:kind])]}
  role="status"
>
```

```css
/* Corresponding CSS transition classes (in app.css) */
.ax-flash-enter-from {
  opacity: 0;
  transform: translateY(calc(-1 * var(--ax-rise-sm)));
}
.ax-flash-entering {
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-out);
}
.ax-flash-enter-to {
  opacity: 1;
  transform: translateY(0px);
}
.ax-flash-leave-from {
  opacity: 1;
}
.ax-flash-leaving {
  transition: opacity var(--ax-dur-exit) var(--ax-ease-in);
}
.ax-flash-leave-to {
  opacity: 0;
}
```

Note: `JS.show/hide` with transition tuples is the Phoenix.LiveView 1.1 API. The `time:` option must match the CSS transition duration in milliseconds. Use `var(--ax-dur-2)` = 180ms for enter and `var(--ax-dur-exit)` = 140ms for exit — pass the integer values, not CSS variables.

### Pattern 4: detail_drawer — Always-Render Approach

```elixir
# Recommended: Convert from :if={@open} (DOM remove) to always-render + hidden attr
# This lets CSS transitions run on both enter and exit.

def detail_drawer(assigns) do
  ~H"""
  <section
    id="ax-detail-drawer-region"
    class={["ax-detail-drawer-shell", @class]}
    hidden={not @open}  <%!-- hidden managed by phx-transition, not raw hidden attr --%>
    ...
  >
  """
end
```

However, the `:if` approach is also workable with `phx-mounted` / `phx-remove` (JS.transition). The choice depends on whether the component is used in contexts where the drawer content should not exist in the DOM when closed (e.g., for performance or to avoid partial state). Given detail_drawer renders significant content, keeping `:if={@open}` and using `phx-mounted` / `phx-remove` is the recommended approach — mirrors step_up_auth_modal.

### Pattern 5: Global Search — data-open Approach

```elixir
# Recommended: Change the wrapper from class-swapping to data-open attr
# global_search.ex render:
<div id={@id} class="ax-command-palette-wrapper" data-open={to_string(@is_open)}>
  ...
</div>
```

```css
/* CSS handles visibility + transition keyed on data-open */
.ax-command-palette-wrapper {
  pointer-events: none;
}
.ax-command-palette-wrapper[data-open="true"] {
  pointer-events: auto;
}

/* Backdrop */
.ax-command-palette-wrapper .ax-command-palette-backdrop {
  opacity: 0;
  transition: opacity var(--ax-dur-2) var(--ax-ease-out);
}
.ax-command-palette-wrapper[data-open="true"] .ax-command-palette-backdrop {
  opacity: 1;
}

/* Palette panel */
.ax-command-palette-wrapper .ax-command-palette {
  opacity: 0;
  transform: scale(0.98);
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-emphasis);
}
.ax-command-palette-wrapper[data-open="true"] .ax-command-palette {
  opacity: 1;
  transform: scale(1);
}
```

**Note:** The CommandPalette JS hook currently checks `!this.el.parentElement.classList.contains("hidden")`. If the show/hide mechanism changes from class to data-open, the hook's visibility check must update to `this.el.parentElement.dataset.open !== "true"`.

### Anti-Patterns to Avoid

- **`transition: all` anywhere in app.css:** Banned — A1. Animates layout properties accidentally, destroys performance, bypasses the token vocabulary.
- **Animating `height: auto`:** Banned — A2. Layout-triggering. Use opacity + `hidden` attribute toggle (structural) for reveal/collapse. The collapsible nav already does this correctly with `list.hidden`.
- **Raw `200ms` / `0.3s` / `cubic-bezier(...)` in app.css rules:** Banned — A3. Every duration and curve must trace back to a `--ax-dur-*` or `--ax-ease-*` atom. Exception allowlist: `ax-skeleton-shimmer 1.4s` (loading, A4 exception).
- **`display: none` → CSS transition:** Transitions cannot start from or end at `display: none`. Use `opacity: 0; visibility: hidden; pointer-events: none` for CSS-only closes, or `JS.hide` for LiveView-managed removes.
- **Forgetting the `time:` integer in JS.show/hide:** The `time:` must match the CSS transition duration in ms. If they don't match, the element is shown/hidden before the animation completes.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-component animation duration constants | Hard-coded `180` integers scattered across JS | `--ax-dur-2` CSS variable; pass `180` to `JS.show/hide time:` with a comment citing the token | Single override point for reduced-motion |
| Reduced-motion detection in JS | `window.matchMedia('(prefers-reduced-motion: reduce)')` checks | The CSS token override at theme.css:187 handles it for all CSS transitions; JS hooks never need to check | Token override collapses durations to 0ms/1ms automatically |
| Exit animation via `setTimeout` + class removal | Manual timeout to remove an element after fade | `JS.hide` with `time:` + transition classes | LiveView manages the DOM lifecycle correctly |
| Custom `cubic-bezier()` in component CSS | Ad-hoc easing curves per component | `--ax-ease-out`, `--ax-ease-in`, `--ax-ease-emphasis` atoms | Consistent, overridable, grep-guarded |

**Key insight:** The enforcement guard is as important as the motion itself. Any literal that slips in now will silently bypass the reduced-motion override and violate MOT-03. The guard prevents entropy.

---

## Enforcement Guard — Current State and Extension

### Current guard location
`scripts/ci/verify_package_docs.sh`, lines 322–328 [VERIFIED: codebase inspection]

```bash
# Token bypass guards (Phase 174, DSY-01)
app_css="$ROOT_DIR/accrue_admin/assets/css/app.css"
if grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" | grep -qv '\-\-ax-bp-'; then
  fail "$app_css must not have bare breakpoint @media without an --ax-bp-* annotation comment ..."
fi
```

### Extension needed (Phase 177, MOT-01)
Add four new checks after the existing Phase 174 breakpoint guard in `verify_package_docs.sh`:

1. **Ban `transition: all`** — grep for `transition:\s*(all|all\b)` in app.css
2. **Ban raw `cubic-bezier(` outside theme.css** — grep in app.css only (theme.css atom definitions are exempt)
3. **Ban raw duration literals in transition/animation** — grep for `transition:.*[0-9]+(ms|s)\b` and `animation:.*[0-9]+(ms|s)\b` in app.css, with allowlist for `ax-skeleton-shimmer 1.4s`
4. **Ban layout-thrash properties in transition lists** — grep for `transition:.*\b(height|width|margin|padding|top|left|right|bottom)\b` in app.css

### Coupling: negative-test seed fixture
`accrue/test/accrue/docs/package_docs_verifier_test.exs`, `seed_tmp_dir!/1` at line 302 [VERIFIED: codebase inspection]

The seed function copies `copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)` (line 331). The negative tests inject violations into this copy. Each new guard needle needs a corresponding negative test that injects that violation into the seeded `app.css` and asserts the guard fails. Without this, the six existing negative tests will still pass (they test different needles), but there will be no coverage proof for the motion guards.

The coupling is: **guard script and negative test must change in the same commit** (per project MEMORY).

---

## Common Pitfalls

### Pitfall 1: `display: none` kills CSS transitions
**What goes wrong:** Setting `hidden` attr (or `display: none` class) immediately removes the element from layout. Any CSS `transition` on that element never fires for the close/exit.
**Why it happens:** `display` is not an interpolatable property. The browser terminates transitions when `display: none` is applied.
**How to avoid:** For CSS-only closes, use `opacity: 0; visibility: hidden; pointer-events: none` instead of `display: none`. For LiveView-managed removes (`:if`), use `JS.hide` with transition tuple.
**Warning signs:** Animation works on open but close is instant even with `transition` defined.

### Pitfall 2: `<details>` `[open]` close transition does not fire
**What goes wrong:** Native `<details>` element closes synchronously — `[open]` is removed by the browser before any transition can run.
**Why it happens:** Browser's built-in close behavior for `<summary>` click skips CSS transitions.
**How to avoid:** Intercept the `toggle` event in JS (or use a `click` handler on `<summary>`), add a `data-closing` attribute, run the exit transition, then remove `[open]` on `transitionend`. For Phase 177 scope, accept symmetric transitions on the dropdown (both enter and exit use `--ax-dur-2`) unless a hook is warranted.
**Warning signs:** Dropdown closes instantly despite `transition` on `.ax-dropdown-panel`.

### Pitfall 3: `JS.show/hide time:` integer must match CSS transition duration
**What goes wrong:** LiveView removes the element from DOM before the CSS transition finishes (or keeps it in DOM after it's already invisible if `time:` is too long).
**Why it happens:** `time:` in `JS.show/hide` is the hook duration; LiveView uses it to know when the transition is done. CSS and JS must agree.
**How to avoid:** When using `--ax-dur-2` (180ms) for enter, pass `time: 180`; for exit with `--ax-dur-exit` (140ms), pass `time: 140`. Add a comment citing the token.
**Warning signs:** Element disappears before animation completes, or stays in DOM as a ghost after `hidden`.

### Pitfall 4: Transitioning `transform: scale()` can cause jank on non-composited layers
**What goes wrong:** Elements with `overflow: hidden` or certain stacking contexts can cause repaints when scaled.
**Why it happens:** Compositing is not guaranteed for all elements.
**How to avoid:** Add `will-change: transform` cautiously (only on elements that animate) or use `transform: translateZ(0)` to promote to compositor. For the command palette scale-in, the panel is already in a fixed-position stacking context — compositing should be fine.
**Warning signs:** Jank or dropped frames on the palette open.

### Pitfall 5: Extending the guard script without updating the negative-test seed fixture
**What goes wrong:** New guard needles added to `verify_package_docs.sh` but not reflected in `package_docs_verifier_test.exs` `seed_tmp_dir!/1`. The six existing negative tests still pass (they test different needles). The new guards have no negative-test coverage.
**Why it happens:** Two files must be kept in sync; easy to forget the test side.
**How to avoid:** In the same commit that adds the guard needle, add the corresponding negative test. See the existing breakpoint guard negative test at line 241 of `package_docs_verifier_test.exs` as the template.

---

## Runtime State Inventory

Not applicable — this is a CSS/JS/component depth pass. No stored data, live service config, OS-registered state, secrets, or build artifacts are renamed or migrated.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js / npm | Playwright e2e tests | ✓ | confirmed (e2e/ exists and runs) | — |
| Chrome / Playwright | `e2e/reduced-motion.spec.js` | ✓ | confirmed (existing tests run) | — |
| mix accrue_admin.assets.build | CSS/JS compilation | ✓ | confirmed (existing phases use it) | — |

**Skip condition:** No missing dependencies — all required tools are confirmed present from previous phases.

---

## Code Examples

### Existing reference: step_up_auth_modal.ex (the JS.transition template)

```elixir
# Source: accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
phx-mounted={Phoenix.LiveView.JS.push_focus() |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")}
phx-remove={Phoenix.LiveView.JS.pop_focus()}
```
This shows the pattern for `phx-mounted`/`phx-remove` hooks. Phase 177 extends this with `JS.show/JS.hide` transition tuples for motion.

### Existing reference: sidebar chevron rotate (already wired)

```css
/* Source: accrue_admin/assets/css/app.css:1218-1227 */
.ax-sidebar-group-chevron {
  color: var(--ax-muted);
  flex: none;
  transition: var(--ax-transition-transform);  /* Phase 174 bundle wired */
}

[aria-expanded="true"] > .ax-sidebar-group-toggle .ax-sidebar-group-chevron,
.ax-sidebar-group-toggle[aria-expanded="true"] .ax-sidebar-group-chevron {
  transform: rotate(90deg);
}
```
The chevron rotation is already live. Phase 177 adds the link list reveal.

### Existing reference: reduced-motion test (two-test pattern to extend)

```javascript
// Source: accrue_admin/e2e/reduced-motion.spec.js
// Pattern:
// Test 1: emulateMedia({ reducedMotion: "reduce" }) → assert all transition segments = "0s"
// Test 2: no emulateMedia → assert at least one segment != "0s" (proves the override is the cause)
// Phase 177 extension: add the same two-test structure for .ax-detail-drawer, .ax-command-palette, .ax-dropdown-panel
```

### Existing reference: reduced-motion token override (already wired)

```css
/* Source: accrue_admin/assets/css/theme.css:187-211 */
@media (prefers-reduced-motion: reduce) {
  html.accrue-admin {
    --ax-rise-sm: 0px;
    --ax-rise-md: 0px;
    --ax-press-scale: 1;
    --ax-ease-emphasis: var(--ax-ease-out);
    --ax-dur-1: 0ms;
    --ax-dur-3: 0ms;
    --ax-dur-exit: 0ms;
    --ax-dur-2: 1ms;        /* NOTE: 1ms not 0ms — preserves opacity crossfades */
    --ax-transition-colors: color var(--ax-dur-instant) linear, ...;
    --ax-transition-transform: transform var(--ax-dur-instant) linear;
    --ax-transition-shadow: box-shadow var(--ax-dur-instant) linear;
    --ax-transition-base: color var(--ax-dur-instant) linear, ...;
  }
}
```
All new CSS transitions that use `--ax-transition-*` bundles honor this override automatically. Opacity crossfades that use `--ax-dur-2` collapse to 1ms (perceptible enough for vestibular safety, effectively instant).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 175 sidebar chevron: "instant — no transition in this phase; motion is Phase D" | Phase 177 adds the full reveal transition for the link list | Phase 177 | Completes the collapsible nav motion story |
| Phase 174 bundles defined but not applied to interactive surfaces | Phase 177 applies bundles to all 9 surfaces | Phase 177 | Activates the token vocabulary |
| D-16 deferred (enter/exit asymmetry) | Now implemented in Phase 177 via `--ax-dur-exit` + `--ax-ease-in` | Phase 177 | Encodes the full motion grammar |

**Deprecated/outdated:**
- The comment `/* Rotates 90deg (instant — no transition in this phase; motion is Phase D) */` at app.css:1216 becomes incorrect after Phase 177 — update the comment.
- The `--ax-motion-fast` and `--ax-motion-standard` back-compat aliases in theme.css (lines 66-68): still valid for the one registered exception at app.css:1562-1569, but no new rules should use them. The registered exception at app.css:1562 is explicitly documented as an allowlist item.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework (ExUnit) | Mix test, `accrue_admin/test/` |
| Framework (E2E) | Playwright, `accrue_admin/e2e/` |
| Quick run command | `cd /Users/jon/projects/accrue/accrue_admin && mix test --seed 0` |
| Full suite command | `cd /Users/jon/projects/accrue/accrue_admin && mix test --seed 0 && npm run e2e:visuals:png-only` |
| E2E reduced-motion command | `cd /Users/jon/projects/accrue/accrue_admin && npx playwright test e2e/reduced-motion.spec.js` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOT-01 | motion.md guide exists and is referenced in accrue_admin/mix.exs extras | unit | `cd /Users/jon/projects/accrue && bash scripts/ci/verify_package_docs.sh` | ❌ Wave 0 — add `"guides/motion.md"` needle to verify_package_docs.sh + seed fixture |
| MOT-01 | motion guard rejects `transition: all` in app.css | unit (negative test) | `cd /Users/jon/projects/accrue/accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0` | ❌ Wave 0 — add negative test |
| MOT-01 | motion guard rejects raw `cubic-bezier(` in app.css | unit (negative test) | same | ❌ Wave 0 — add negative test |
| MOT-01 | motion guard rejects raw ms/s literals in transition rules | unit (negative test) | same | ❌ Wave 0 — add negative test |
| MOT-01 | motion guard rejects layout-thrash properties in transition lists | unit (negative test) | same | ❌ Wave 0 — add negative test |
| MOT-02 | `.ax-dropdown-panel` has opacity/transform transition (not instant) without reduced-motion | E2E | Playwright CSS assertion | ❌ Wave 0 — new structural assertion |
| MOT-02 | `.ax-command-palette` has opacity/transform transition (not instant) without reduced-motion | E2E (extend D-15 pattern) | `npx playwright test e2e/reduced-motion.spec.js` | ❌ Wave 0 — extend existing file |
| MOT-03 | `.ax-dropdown-panel` transitions collapse to 0s under prefers-reduced-motion | E2E | `npx playwright test e2e/reduced-motion.spec.js` | ❌ Wave 0 — extend existing file |
| MOT-03 | `.ax-command-palette` transitions collapse to 0s under prefers-reduced-motion | E2E | `npx playwright test e2e/reduced-motion.spec.js` | ❌ Wave 0 — extend existing file |
| MOT-03 | Playwright structural check: open drawer/dropdown under reduced-motion, assert no transform travel | E2E | `npx playwright test e2e/reduced-motion.spec.js` | ❌ Wave 0 — extend existing file |
| Regression | 252 tests remain green after all changes | unit | `cd /Users/jon/projects/accrue/accrue_admin && mix test --seed 0` | ✅ existing suite |

### Sampling Rate
- **Per task commit:** `cd /Users/jon/projects/accrue/accrue_admin && mix test --seed 0 2>&1 | tail -5`
- **Per wave merge:** Full test suite + `npx playwright test e2e/reduced-motion.spec.js`
- **Phase gate:** Full suite green + all new Playwright assertions pass before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Extend `scripts/ci/verify_package_docs.sh` — add 4 motion guard needles (transition:all, cubic-bezier, ms/s literals, layout-thrash props)
- [ ] Extend `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add 4 negative tests mirroring the existing breakpoint guard test at line 241; update `seed_tmp_dir!` if any new files are referenced
- [ ] Add needle for `"guides/motion.md"` to `accrue_admin/mix.exs` extras list and to verify_package_docs.sh (and seed fixture)
- [ ] Extend `accrue_admin/e2e/reduced-motion.spec.js` — add D-15-style two-test blocks for: `.ax-dropdown-panel`, `.ax-command-palette`, `.ax-detail-drawer`
- [ ] Add structural Playwright check: emulate reduced-motion, open drawer/dropdown, assert `getComputedStyle(el).transitionDuration` is `"0s"` on all segments

*(Existing test infrastructure covers all regression — no new framework install needed)*

---

## Security Domain

Not applicable — this phase is purely CSS/JS motion and documentation. No authentication, session, input validation, cryptography, or access control changes.

---

## Open Questions (RESOLVED)

1. **detail_drawer enter/exit mechanism choice: `:if` + JS.transition vs always-render + CSS**
   - What we know: step_up_auth_modal uses `:if` + `phx-mounted`/`phx-remove` for focus management; detail_drawer uses `:if={@open}` today
   - What's unclear: whether detail_drawer is ever used in contexts where always-rendering would cause issues (hidden form fields, inaccessible tab stops)
   - Recommendation: keep `:if={@open}` and add `phx-mounted={JS.show(...)} phx-remove={JS.hide(...)}` — matches the existing step_up_auth_modal pattern, no architectural change required
   - **RESOLVED:** Keep `:if={@open}`; add `phx-mounted` / `phx-remove` JS.show/hide transition attrs on the `:if`-gated section (Plan 03 Task 2, EDIT 1).

2. **`<details>` exit transition for dropdown**
   - What we know: native `[open]` removal is synchronous; CSS transitions don't fire on exit
   - What's unclear: whether the planner should add a minimal JS hook to support exit asymmetry, or accept symmetric duration for dropdown close
   - Recommendation: accept symmetric 180ms for dropdown (enter and exit same speed) in Phase 177. Exit asymmetry is a nice-to-have; the functional justification (affordance) is met by the enter alone. Flag as discretionary.
   - **RESOLVED:** Accept symmetric 180ms for Phase 177 (Plan 02 Task 1, CHANGE 2). JS-hook upgrade for exit asymmetry is flagged discretionary and deferred.

3. **SidebarCollapse hook: `list.hidden` vs CSS class for transition**
   - What we know: `list.hidden = true` kills CSS transitions immediately
   - What's unclear: the planner needs to decide whether to modify `sidebar_collapse.js` to use a CSS class toggle instead of `hidden`, or use the `transitionend` callback approach
   - Recommendation: replace `list.hidden = !expanded` with a two-step approach: (a) add `ax-collapsing` class, (b) on `transitionend`, set `list.hidden = !expanded`. This keeps `hidden` for structural semantics while allowing CSS transitions to run.
   - **RESOLVED:** CSS class (`ax-collapsed`) two-step with transitionend listener: add `ax-collapsed` class to trigger exit opacity transition, then set `list.hidden = true` + remove class on `transitionend` (Plan 02 Task 2, SUB-CHANGE B).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.ax-status-badge` inherits `--ax-transition-base` from the `app.css:983-1000` selector | Per-Surface table row #9 | If the selector inheritance doesn't apply, badge color transitions won't work without explicit rule |
| A2 | `@starting-style` CSS Level 5 is not reliably available in the Playwright/Chrome version used by the e2e suite | Per-Surface table row #8 | If `@starting-style` is available, skeleton→content crossfade could be purely CSS without `phx-mounted` |

---

## Sources

### Primary (HIGH confidence — codebase inspection)
- `accrue_admin/assets/css/theme.css` — all motion token definitions (lines 52-98), reduced-motion override (lines 185-211)
- `accrue_admin/assets/css/app.css` — per-surface CSS class definitions, existing transition rules, chevron rotate (line 1218), registered exception (line 1562), skeleton shimmer (line 2401), reduced-motion override (line 2409)
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` — `:if={@open}` DOM mount pattern
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` — `<details>` native disclosure
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — `is_open` class-swap on wrapper
- `accrue_admin/lib/accrue_admin/components/sidebar.ex` — `aria-expanded` + hidden div toggle
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` — `phx-mounted`/`phx-remove` JS pattern (template to mirror)
- `accrue_admin/lib/accrue_admin/components/flash_group.ex` — `:for` list render
- `accrue_admin/lib/accrue_admin/components/tabs.ex` — link-based nav, `ax-tab-active` class
- `accrue_admin/lib/accrue_admin/components/data_table.ex` — skeleton state, `.ax-skeleton` class
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — More ▾ `@more_tabs_open` toggle
- `accrue_admin/assets/js/hooks/sidebar_collapse.js` — `list.hidden = !expanded` JS hook
- `accrue_admin/assets/js/hooks/command_palette.js` — `classList.contains("hidden")` visibility check
- `accrue_admin/e2e/reduced-motion.spec.js` — existing D-15 two-test pattern (template to extend)
- `scripts/ci/verify_package_docs.sh` — Phase 174 breakpoint guard (lines 322-328) — template for motion guard
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — `seed_tmp_dir!/1` (line 302), negative test pattern (line 241)
- `.planning/phases/177-d-motion-micro-interaction-design/177-CONTEXT.md` — locked decisions
- `.planning/phases/177-d-motion-micro-interaction-design/177-UI-SPEC.md` — approved motion contract (9 surfaces)
- `.planning/REQUIREMENTS.md` — MOT-01, MOT-02, MOT-03

---

## Metadata

**Confidence breakdown:**
- Per-surface mechanism: HIGH — every surface's DOM pattern verified by reading the actual component file
- Token vocabulary: HIGH — theme.css and app.css read directly; all atoms confirmed present
- Enforcement guard pattern: HIGH — existing guard script + test file both read; coupling pattern confirmed
- Reduced-motion test extension: HIGH — existing spec read; two-test pattern is clear
- JS.transition API shape: MEDIUM — based on LiveView 1.1 training knowledge; verify against LiveView docs before writing final code

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable tech; tokens are frozen)
