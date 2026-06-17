# Phase 189: Primitive & Form Components + Component Lab — Research

**Researched:** 2026-06-17
**Domain:** Phoenix LiveView admin UI — component systematization, registry-driven state-matrix lab, a11y verification harness
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 through D-03 — Component Inventory Split**
Phase 189 owns: button (primary/secondary/ghost/danger), input (text/number/email/password), textarea, checkbox/radio/toggle-switch, native select, form field wrapper (label/help/error/required), status_badge/tag/pill, icon, money_formatter, json_viewer, spinner/skeleton/loading, tooltip, inline code/ID display, non-interactive empty-state hero.
Phase 190 owns all composites, navigation, and overlay groups. If a 189-primitive defect originates in a 190-group, fix the primitive root here and record the group-level manifestation as a Phase-190 note — no group patching in 189.

**D-04 — Keep single `/dev/components` route.** No per-component routes; no Storybook.

**D-05 — Grow `ComponentRegistry` with `states` and `specimens` fields per entry; drive ONE matrix renderer off it.** Rows = applicable states; light and dark columns side-by-side. The exact state list a test asserts is the exact list the grid renders ("tested ⇔ shown").

**D-06 — Bake long/overflowing-content specimens into `specimens` data** (overflow is required by CMP-02, not optional).

**D-07 (CRITICAL GOTCHA) — Per-specimen theme wrappers were previously inert.** The new `.ax-dev-state-grid` theme columns MUST genuinely re-scope `--ax-*` tokens via `data-theme` on the column wrapper. Drift test MUST assert a resolved-color delta between light and dark cells — not merely class presence.

**D-08 — Adding `states`/`specimens`/`applicable_states` to registry requires lockstep updates to `component_registry_test.exs`.** The four existing tests must be extended or the coupling breaks CI.

**D-09 — `applicable_states` field per entry gates the frozen COMPONENT_STATES taxonomy.** Every n/a state must carry an explicit reason — never silently dropped.

**D-10 — Three deterministic verification layers** (no new runner): (1) axe-core sweep with `wcag2a`/`wcag2aa` on settled colors; (2) `getComputedStyle`/`elementFromPoint` probes for focus/disabled/contrast/overflow; (3) `score-visuals.mjs` PNG vision pass.

**D-11 — Two frozen viewports: 1440 desktop / 390 mobile** (from `baseline-manifest.js` PROJECTS). No new breakpoints.

**D-12 — All results keyed to existing `p187__{surface}__{mode}__{theme}__{state}__{dXX}` cell-id grammar** into the NDJSON ledger. Grammar is frozen — do not change it.

**D-13 — No visual-regression snapshot tooling** (`toHaveScreenshot`, Playwright CT). Rejected for this milestone.

**D-14 — All fixes at the component root** (HEEx + `theme.css`/`app.css`). No per-page CSS overrides.

**D-15 — Add a verifier + negative-fixture guard** flagging per-page overrides of primitive `ax-*` classes and raw inline `style` on primitives, following the established verifier ↔ negative-fixture coupling pattern.

### Claude's Discretion

- Exact registry schema shape for `states`/`specimens`/`applicable_states` (keyword list vs map vs struct).
- Exact `.ax-dev-state-grid` layout/markup, as long as theme columns genuinely re-scope `--ax-*` and side-by-side light/dark is achieved.
- Whether the per-page-override guard is an Elixir test, a shell verifier, or both.
- Plan/wave decomposition.

### Deferred Ideas (OUT OF SCOPE)

- Per-component routes, Storybook-style isolated canvases.
- Visual-regression snapshot baselines (`toHaveScreenshot` / Playwright CT).
- Meta-component / group cohesion (Phase 190).
- Page/flow interaction defects (Phase 191).
- PhoenixStorybook adoption (TOOL-01 deferred across v1.53).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CMP-01 | Every component exercised in `/dev/components` lab across full state matrix (default/hover/focus/active/pressed/disabled/loading/selected/empty/error/overflow) in both light and dark | Registry `states`/`applicable_states` fields drive the matrix renderer; frozen COMPONENT_STATES taxonomy from baseline-manifest.js is the state vocabulary |
| CMP-02 | Each component renders correctly with long/overflowing content without clipping, overlap, or layout break | `specimens` field bakes overflow content; `scrollWidth <= clientWidth` e2e probe in admin-interactions.spec.js pattern |
| CMP-03 | Each interactive component has correct role, full keyboard operation, visible focus, accessible name; non-interactive elements expose no misleading affordances | axe-core sweep + keyboard Playwright probe; StatusBadge/empty-state hero must have no `cursor:pointer` |
| CMP-04 | Disabled/read-only states visually unmistakable; button text never collides with background | `getComputedStyle` contrast probe; `--ax-disabled-*` token consumption at component root |
| CMP-05 | Component-level fixes at component root propagating to all consuming pages | Shell verifier + negative-fixture guard for per-page `ax-*` overrides and raw inline `style` |

</phase_requirements>

---

## Summary

Phase 189 is an application-and-proof phase. All its raw material already exists — the frozen Phase-187 harness, the Phase-188 foundation tokens, the four registry tests, and the component source files. The work is (a) growing the `ComponentRegistry` schema with `states`/`specimens`/`applicable_states` data, (b) converting the `ComponentKitchenLive` hand-authored sections to a registry-driven two-column state-matrix renderer, (c) fixing each primitive family's root defects to consume Phase-188 tokens correctly, and (d) extending the e2e and shell-verifier harness to prove it all deterministically.

The most important technical risk is the D-07 theme-column scope gotcha: the current `component_kitchen_live.ex` explicitly comments that per-specimen `data-theme` wrappers were previously inert — no CSS selector matched them for token re-scoping. The new `.ax-dev-state-grid-col[data-theme="dark"]` column must wire into the same selector the production `html.accrue-admin[data-theme="dark"]` uses, and the drift test must assert a `getComputedStyle` delta (e.g., `--ax-base` computed color differs between columns) not just class presence.

The second significant risk is the ax-type-exception and disabled-affordance gap: `app.css` currently has `ax-type-exception` comments on `.ax-button`, `.ax-status-badge`, `.ax-field-label`, `.ax-field-help`, `.ax-field-error`, `.ax-button-sm`, and `.ax-field-control` — all carry raw `font-size`, `font-weight`, and `line-height` literals. Phase 189 must migrate these to composed role tokens (D-05 Phase-188 was the ban; Phase 189 is the application). The `.ax-field-control-error` selector incorrectly uses `--ax-warning` instead of `--ax-status-danger-border` for error state — this is the clearest token-compliance defect at component scope.

**Primary recommendation:** Wave 1 — extend registry schema and convert renderer; Wave 2 — per-family root CSS fixes using Phase-188 tokens; Wave 3 — verification harness extension and CMP-05 guard.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Component state matrix gallery | Frontend Server (SSR) | — | `ComponentKitchenLive` is a LiveView route serving the registry-driven `/dev/components` page; no client-side runtime needed |
| Theme token re-scoping in lab columns | Browser / Client | Frontend Server (SSR) | CSS custom property inheritance cascades at browser paint time; the `data-theme` attribute is set by the LiveView template, resolved by the browser's cascade |
| Primitive component CSS fixes | Browser / Client | — | All fixes live in `app.css`/`theme.css` static bundle; no server logic |
| a11y and interaction verification | Browser / Client | — | Playwright probes run against the live browser; axe-core runs client-side |
| Registry SSOT and drift tests | Frontend Server (SSR) | — | `ComponentRegistry` is an Elixir module; drift tests use LiveView test helpers |
| CMP-05 verifier guard | CI / Build | — | Shell verifier in `scripts/ci/verify_package_docs.sh` runs at CI time; tests run in ExUnit |

---

## Standard Stack

No new dependencies. This phase extends existing infrastructure only.

### Core (existing — confirmed present in codebase)

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| `phoenix_live_view` | `~> 1.1` | `ComponentKitchenLive` LiveView, template rendering | Already in `accrue_admin/mix.exs` |
| `@axe-core/playwright` | existing | Axe a11y sweep in `admin-a11y.spec.js` | Already installed; pattern in use |
| Playwright | existing | e2e `getComputedStyle`/`elementFromPoint` probes | Already installed; pattern in use |
| `@anthropic-ai/sdk` | existing | `score-visuals.mjs` vision pass | Already installed |

**Installation:** none required.

---

## Package Legitimacy Audit

No new packages are installed in Phase 189. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
ComponentRegistry.entries()
        │
        ├─► (state_matrix_renderer in ComponentKitchenLive.render/1)
        │         │
        │         ├─► .ax-dev-family section (per family)
        │         │         ├─► .ax-dev-state-grid-col[data-theme="light"]
        │         │         │       └─► .ax-dev-state-cell per applicable_state
        │         │         └─► .ax-dev-state-grid-col[data-theme="dark"]
        │         │                 └─► .ax-dev-state-cell per applicable_state
        │         └─► n/a rows with stated reason
        │
        └─► component_registry_test.exs (4 tests + new state/specimen coverage tests)
                  └─► mount /billing/dev/components → assert cells rendered
                                    │
                  getComputedStyle probe: delta(light col bg) ≠ delta(dark col bg)

e2e verification (extends existing harness):
  admin-a11y.spec.js ──────────► axe sweep on /billing/dev/components (both themes, settled colors)
  admin-interactions.spec.js ──► getComputedStyle probes: focus-ring, disabled, overflow
                                   └─► write to p187__component-kitchen__*__*__*__dXX cells
  score-visuals.mjs ───────────► PNG capture + vision scoring of /billing/dev/components

CMP-05 guard:
  verify_package_docs.sh ──────► shell verifier: no `ax-*` overrides in page templates
                                   └─► negative fixture in PackageDocsVerifierTest
```

### Recommended Project Structure (Phase 189 edits only)

```
accrue_admin/
├── lib/accrue_admin/dev/
│   ├── component_registry.ex          # Extend with states/specimens/applicable_states
│   └── component_kitchen_live.ex      # Replace hand-authored sections with matrix renderer
├── test/accrue_admin/dev/
│   └── component_registry_test.exs    # Extend in lockstep with registry schema
├── assets/css/
│   ├── app.css                        # Add .ax-dev-state-grid CSS; fix primitive ax-type-exceptions
│   └── theme.css                      # No new tokens; consumed by component selectors
├── e2e/
│   ├── admin-a11y.spec.js             # Extend: add /dev/components a11y sweep
│   └── admin-interactions.spec.js     # Extend: add component state probes
└── scripts/ci/
    └── verify_package_docs.sh         # Add CMP-05 guard
```

---

## Current State of Edit-Surface Code

### ComponentRegistry shape (actual, as-is)

The current `ComponentRegistry.entries/0` returns a plain list of maps with four fields:

```elixir
%{
  family: String.t(),      # e.g. "button", "status", "card", "foundation-type"
  variant: String.t(),     # e.g. "primary", "moss", "base"
  ax_class: String.t(),    # full class string as rendered, e.g. "ax-button ax-button-primary"
  tokens: [String.t()]     # CSS custom property names consumed by this variant
}
```

Current families: `"button"` (4 variants), `"status"` (5 variants), `"card"` (6 variants), plus 8 `"foundation-*"` families added by Phase 188.

**Phase 189 must add new families for every primitive family** (14 families from D-01: button, input, textarea, checkbox, radio, toggle, select, form-field, status_badge, icon, money_formatter, json_viewer, spinner/skeleton, tooltip, inline-code/id, empty-state). The existing 3 non-foundation families can be updated or superseded.

### The four existing registry tests (actual assertions)

**(a) Variant presence test** — mounts `/billing/dev/components`, asserts every `entry.ax_class` has its variant-specific second class substring in the page HTML. Fragile to entries whose `ax_class` does not split into `"base variant_class"` at the first space — currently all entries do, but the Phase 188 foundation entries use a two-class pattern (`"ax-foundation ax-foundation-type"`). The test's `[_base, variant_class] = String.split(ax_class, " ", parts: 2)` binding means the second element is the full tail for multi-class strings — works correctly for foundation entries since the tail is unique.

**(b) Button ax_class exact-match test** — renders each of the 4 button variants via `render_component/2`, extracts the `ax-button` class string, compares as a MapSet against registry entries. The regex `~r/class="(ax-button[^"]+)"/` anchors on `ax-button`. Works only for buttons — not generalized for other families.

**(c) Token-validity test** — reads `theme.css` and `app.css` at test time; every token in every entry's `tokens` list must appear as `--token:` (definition form, not usage) in at least one CSS file. `known_in_layouts` allowlist: `--ax-accent` and `--ax-accent-contrast` (injected via runtime `<style>` tag in `layouts.ex`).

**(d) Token-render test** — mounts `/billing/dev/components`, asserts every registry token string appears in the rendered HTML. Also `refute`s three phantom token names (`--ax-neutral`, `--ax-ink`, `--ax-info`).

**D-08 implication:** Adding `states`/`specimens`/`applicable_states` fields to entries does not break these four tests — the tests only read `ax_class` and `tokens`. However, Phase 189 must ADD new tests that cover the state/specimen fields, and the "variant presence test" must be extended to assert state cells appear in the rendered grid.

### ComponentKitchenLive current structure

The kitchen live module (lines 1-498) has this overall render structure:
1. `AppShell.app_shell` wrapper with breadcrumbs + page header
2. `FlashGroup`
3. Unavailable guard section (`:if={!@available?}`)
4. KPI card grid (`:if={@available?}`)
5. A tabs + `ax-dev-grid` section (buttons, statuses, dropdown — hand-authored)
6. Icon gallery section (hand-authored, uses `Icon.names()`)
7. Detail skeleton section (hand-authored)
8. Related-resources + empty-state section (hand-authored)
9. **Component variants reference section** — buttons loop from registry
10. **Status badges section** — statuses loop from registry (zipped with status atoms)
11. **Cards section** — cards loop from registry
12. **Phase 188 foundation specimens section** (hand-authored with inline tokens)
13. Banners showcase section (hand-authored)
14. Motion reference table (hand-authored)

**Lines 166-168 (the D-07 gotcha):**
```elixir
<%!-- Buttons variant reference. Each component is shown ONCE; review light vs
     dark with the page theme toggle (the per-specimen light/dark wrappers used to
     be inert — no CSS re-themed them — so they only looked like duplicates). --%>
```
This comment documents that the per-specimen `data-theme` wrappers from an earlier iteration were inert. The current code shows each component once and tells users to toggle the page theme. Phase 189 must introduce genuine two-column scoping.

**Private helper functions:**
- `assign_shell/4` — assigns page title, brand, theme, mount path
- `fake_processor?/0` — checks `Application.get_env(:accrue, :processor, ...)`
- `default_brand/0` — fallback brand map
- `color_token?/1` and `non_color_token?/1` — classify tokens for swatch vs kind rendering
- `token_kind/1` — returns `"font"`, `"tracking"`, `"shadow"`, `"motion"`, `"z-index"`, `"measure"`, or `"color"`

These helpers are reusable in the matrix renderer for token display.

### Existing `.ax-dev-grid` and `.ax-dev-variant-row` in app.css

```css
.ax-dev-toolbar,
.ax-dev-toolbar-links,
.ax-dev-grid,
.ax-dev-stack {
  display: flex;
}
.ax-dev-toolbar,
.ax-dev-stack {
  gap: var(--ax-space-md);
}
.ax-dev-grid {
  gap: var(--ax-space-sm);
  flex-wrap: wrap;
}
.ax-dev-variant-row {
  display: flex;
  flex-direction: column;
  gap: var(--ax-space-sm);
}
```

`.ax-dev-state-grid` does not yet exist in `app.css`. Phase 189 adds it. The existing `.ax-dev-grid` / `.ax-dev-variant-row` pattern remains for the non-primitive sections (icons, motion table, etc.).

### Theme CSS selector chain (the D-07 critical path)

The `theme.css` selector hierarchy is:
```css
html.accrue-admin { /* light defaults */ }
html.accrue-admin[data-theme="dark"] { /* dark overrides */ }
@media (prefers-color-scheme: dark) {
  html.accrue-admin[data-theme="system"] { /* system-dark overrides */ }
}
```

The `data-theme` attribute is set on `html.accrue-admin` by the `AppShell` component. A column wrapper with `data-theme="dark"` on a `div` inside the page does NOT match any of these selectors — hence the prior inert wrappers.

**Resolution options for genuine theme column scoping:**

Option A (recommended): Add new CSS rules scoping to the column element itself:
```css
.ax-dev-state-grid-col[data-theme="light"],
.ax-dev-state-grid-col[data-theme="dark"] {
  /* inline custom property overrides */
}
```
But CSS custom properties on a `div[data-theme="dark"]` only work if the column's own selector duplicates the full token set from the dark block — this would be a maintenance burden.

Option B (recommended, minimal risk): **Change the CSS selector** in `theme.css` to accept `data-theme` on any element, not just `html.accrue-admin`:
```css
[data-theme="dark"].accrue-admin,
.accrue-admin [data-theme="dark"] {
  /* dark overrides */
}
```
This means any descendant element with `data-theme="dark"` inside `.accrue-admin` picks up the dark token overrides. This is the standard approach used by Radix, Primer, and most design systems that support in-page theming.

Option C: Inline the full token set as `style=""` on each column wrapper — brittle, would add `style=` attributes the CMP-05 guard must then whitelist.

**Option B is the right path.** The selector change is in `theme.css` only. The production `html.accrue-admin[data-theme="dark"]` behavior is preserved by also keeping that rule. The new `.accrue-admin [data-theme="dark"]` rule activates for any sub-tree, including lab columns.

**Drift test for resolved-color delta:**
```js
// In component_registry_test.exs (Elixir LiveView test), after mounting:
// Read --ax-base from light and dark column wrappers, assert they differ
page.evaluate(() => {
  const light = document.querySelector('.ax-dev-state-grid-col[data-theme="light"]');
  const dark = document.querySelector('.ax-dev-state-grid-col[data-theme="dark"]');
  const lColor = getComputedStyle(light).getPropertyValue('--ax-base').trim();
  const dColor = getComputedStyle(dark).getPropertyValue('--ax-base').trim();
  return { lColor, dColor };
});
// Assert lColor !== dColor
```

For an Elixir-based test (LiveView test using LiveViewTest, not Playwright), the only assertion available is the rendered HTML. Therefore the delta assertion **must live in an e2e Playwright spec** (the natural home for `getComputedStyle`). The registry ExUnit test can assert structural markup (column wrappers present, `data-theme` attributes set) but not computed color values.

---

## Registry Schema Extension

### Recommended schema (Claude's discretion — keyword list of maps)

Extend each `ComponentRegistry` entry from 4 fields to 7:

```elixir
%{
  family: String.t(),
  variant: String.t(),
  ax_class: String.t(),
  tokens: [String.t()],
  # Phase 189 additions:
  applicable_states: [String.t()],  # subset of COMPONENT_STATES that apply
  na_states: [%{state: String.t(), reason: String.t()}],  # explicit n/a with reason
  specimens: [%{label: String.t(), props: map(), content: String.t() | nil}]  # what to render in each cell
}
```

`applicable_states` lists which of the 11 Phase-189 states (`default`, `hover`, `focus`, `active`, `pressed`, `disabled`, `loading`, `selected`, `empty`, `error`, `overflow`) apply to this component family. `na_states` captures every excluded state with a stated reason (satisfies D-09). `specimens` is a list of representative content descriptors consumed by the matrix renderer to instantiate each cell's component.

**Design trade-off: a single entry per family vs one entry per variant**

The current registry has one entry per variant (e.g., 4 button entries). For state-matrix rendering, the cleaner model is one entry per family (one button family entry with all 4 variants as specimens). This eliminates the current "zip with status atoms" hack for StatusBadge and makes the matrix renderer uniform.

**Recommended: migrate to one-entry-per-family for Phase 189 primitives.** The existing button/status/card per-variant entries can stay to avoid breaking the four tests — add a separate set of family-level entries for the new primitive families. Alternatively, add a `is_state_matrix_entry: true` flag to distinguish them.

**Simpler alternative: add the 3 new fields to existing entries, add new entries for new families.** The "tested ⇔ shown" invariant only requires that the state list a test asserts matches the list the grid renders — the structural form of entries can differ between the variant-token entries and the family-state entries.

### Lockstep test updates (D-08)

The four existing tests do not break if new fields are added (they ignore unknown fields). The required lockstep additions:

1. **New test (e): state-matrix markup presence** — mount `/billing/dev/components`; for each registry entry that has `applicable_states`, assert the rendered HTML contains cells for each applicable state (e.g., a `data-ax-state="focus"` attribute, or a `.ax-dev-state-cell` with the state label). Assert n/a rows exist for `na_states` entries.

2. **New test (f): column theme data-attributes** — mount `/billing/dev/components`; assert the rendered HTML contains at least one `.ax-dev-state-grid-col[data-theme="light"]` and one `.ax-dev-state-grid-col[data-theme="dark"]` element.

3. **Token-validity test (c) extension** — no change needed unless new tokens are added to entries. But the PhasePhase 189 primitive entries should include their token lists, so the gate covers them.

4. **Token-render test (d) extension** — any new tokens added in `specimens` entries must appear in the rendered HTML. The existing phantom-token refutes stay.

---

## The D-07 Theme Column Implementation

### CSS addition to `app.css`

```css
/* Phase 189 — state-matrix lab renderer */
.ax-dev-state-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1px;
  border: 1px solid var(--ax-border);
  border-radius: var(--ax-radius-md);
  overflow: hidden;
  background: var(--ax-border);
}

.ax-dev-state-grid-col {
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: var(--ax-border);
}

.ax-dev-state-cell {
  display: flex;
  flex-direction: column;
  gap: var(--ax-space-sm);
  padding: var(--ax-space-md);
  background: var(--ax-base);
  min-height: 4rem;
}

.ax-dev-state-cell-label {
  /* uses .ax-type-code-xs + ax-muted color applied in markup */
}

.ax-dev-state-cell-na {
  background: var(--ax-sunken);
  opacity: 0.6;
}

/* Mobile: stack columns vertically at 390px */
@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */
  .ax-dev-state-grid {
    grid-template-columns: 1fr;
  }
}
```

### CSS addition to `theme.css` (the D-07 fix)

Add this rule alongside the existing dark selector:

```css
/* Sub-tree theme scoping for the component lab columns.
   Keeps html.accrue-admin[data-theme="dark"] for the full-page production case;
   adds .accrue-admin [data-theme="dark"] so any descendant wrapper in the lab
   genuinely re-scopes --ax-* tokens. */
html.accrue-admin [data-theme="dark"],
.accrue-admin [data-theme="dark"] {
  /* mirror all vars from html.accrue-admin[data-theme="dark"] block */
  --ax-base: #0f1318;
  --ax-elevated: #171d24;
  /* ... full dark override block ... */
  color-scheme: dark;
}
```

**Important:** This must be the same token set as `html.accrue-admin[data-theme="dark"]`. The planner should create a Wave 0 task that adds the sub-tree selector with the full token block copied verbatim from the existing dark block. It must NOT be a partial set.

### Drift test delta assertion (e2e Playwright)

In `admin-interactions.spec.js` (or a dedicated `admin-components.spec.js`), add:

```js
test("lab grid light/dark columns resolve different --ax-base values", async ({ page }) => {
  await login(page, "/billing/dev/components");
  const { lightBase, darkBase } = await page.evaluate(() => {
    const light = document.querySelector('.ax-dev-state-grid-col[data-theme="light"]');
    const dark = document.querySelector('.ax-dev-state-grid-col[data-theme="dark"]');
    if (!light || !dark) return { lightBase: null, darkBase: null };
    return {
      lightBase: getComputedStyle(light).getPropertyValue("--ax-base").trim(),
      darkBase: getComputedStyle(dark).getPropertyValue("--ax-base").trim(),
    };
  });
  expect(lightBase).not.toBeNull();
  expect(darkBase).not.toBeNull();
  expect(lightBase).not.toBe(darkBase); // the critical assertion
});
```

This observation can also be recorded as an NDJSON cell keyed to:
`p187__component-kitchen__chromium-desktop__light__default-populated__d01`

---

## Per-Family Root-Fix Landmines

### Button family (120 Phase-189 defects in ledger)

**Current state** (`app.css` lines 1268-1338):
- `.ax-button` has `ax-type-exception` comment + raw `font-size: 0.875rem; font-weight: 600; line-height: var(--ax-leading-normal)` — must migrate to `font: var(--ax-type-label-font)`.
- `.ax-button[aria-disabled="true"], .ax-button:disabled` uses `opacity: 0.5; pointer-events: none` — should use `--ax-disabled-opacity: 0.62` token and `cursor: var(--ax-disabled-cursor)` (the `pointer-events: none` removes cursor-change feedback; Phase-188 D-21 says disabled should keep `not-allowed` cursor, so `pointer-events: none` should be replaced or the cursor must be forced before that rule).
- Primary button hover/active: uses `color-mix(in srgb, var(--ax-accent-strong) 90%, black)` — the interactive-hover/active tokens `--ax-interactive-hover`, `--ax-interactive-active` are accent-tinted in light mode but the primary button should still get the fill-darkening, not the surface-hover. This is correct as-is for a filled button; keep.
- Ghost and secondary hover states: the registry tokens list `--ax-interactive-hover` but app.css has no explicit `.ax-button-ghost:hover` rule yet — this is a gap (ghost button should get `background: var(--ax-interactive-hover)` on hover).
- `.ax-button-sm` has a second `ax-type-exception` comment with raw `font-size`.
- Focus ring: `.ax-button` is NOT in the current `:focus-visible` block (lines 438-444). The focus-visible block covers `.ax-sidebar-link`, `.ax-theme-button`, `.ax-icon-button`, `.ax-link` — but NOT `.ax-button`. This is a significant gap: buttons must receive the standard `outline: 2px solid var(--ax-focus-ring); outline-offset: 2px; box-shadow: var(--ax-focus-shadow)` on `:focus-visible`.
- `aria-busy` loading state: the component HEEx does not set `aria-busy="true"` on loading buttons — this must be added to `button.ex` when loading state is shown.
- Min touch target at 390px: `min-height: 2.25rem` is 36px — below the 44px CMP-03 WCAG 2.5.5 requirement. Phase 189 must add a mobile media query raising it to `min-height: 2.75rem` (44px).

**Token remediation:**
- `font-size/weight/line-height` → `font: var(--ax-type-label-font); letter-spacing: var(--ax-type-label-tracking);`
- `opacity: 0.5` → `opacity: var(--ax-disabled-opacity);`
- Add `cursor: var(--ax-disabled-cursor);` on disabled
- Add `.ax-button:focus-visible` rule with focus ring contract

### Input / Textarea / Checkbox / Select / Form-field families

**Current state:**
- `.ax-field-control` (lines 1747-1756): uses raw padding literal `0.75rem 0.875rem`; background `var(--ax-base)`; color `var(--ax-primary)` — tokens correct for non-error state.
- `.ax-field-control:focus-visible` (line 1758): sets `border-color: var(--ax-focus-ring); outline: none` — this is WRONG. Setting `outline: none` without providing the full focus ring (outline + shadow) violates WCAG 2.4.11. Must change to `outline: 2px solid var(--ax-focus-ring); outline-offset: 2px; box-shadow: var(--ax-focus-shadow);` (do not also set `border-color`).
- `.ax-field-control-error` (line 1764): `border-color: var(--ax-warning)` — wrong token. Error state must use `--ax-status-danger-border` (not `--ax-warning` which is the amber/warning tone). `aria-invalid="true"` is already set in `input.ex` — the CSS must match the semantic.
- `.ax-field-label` (line 1740): `ax-type-exception` + raw font-size/weight/line-height — must migrate to `font: var(--ax-type-label-font); letter-spacing: var(--ax-type-label-tracking);`.
- `.ax-field-help`, `.ax-field-error` (line 1768): same `ax-type-exception` pattern — migrate to `font: var(--ax-type-body-sm-font)`.
- `.ax-field-error` color: currently `var(--ax-warning)` (line 1783) — must change to `var(--ax-status-danger-text)`.
- Disabled state on inputs: no explicit `ax-field-control:disabled` rule in app.css — the browser default grey apply. Must add: `background: var(--ax-disabled-bg); border-color: var(--ax-disabled-border); color: var(--ax-disabled-text); cursor: var(--ax-disabled-cursor);`.
- Readonly state: no explicit `.ax-field-control[readonly]` rule — must add: `background: var(--ax-readonly-bg); border-color: var(--ax-readonly-border); color: var(--ax-readonly-text);`.
- `.ax-checkbox` (line 1706): uses `accent-color: var(--ax-accent)` — this is correct for the native checkbox accent. The `:focus-visible` rule at line 1689 does `border-color: var(--ax-focus-ring); outline: none` — same wrong pattern as above.
- `.ax-select` (line 1694): custom caret via `background-image` linear-gradients — the arrow uses `var(--ax-muted)` color which is correct. `appearance: none` removes native focus ring; the `:focus-visible` rule at line 1688 has the same `outline: none` gap.
- Textarea: no dedicated `.ax-textarea` class found in app.css — likely falling through to `.ax-field-control`. Phase 189 must verify or add an explicit `.ax-textarea` selector.
- `described_by/3` in `input.ex` produces a space-joined string; multiple errors accumulate as `id <> "-error"` all pointing to the same ID for multiple errors. The `input.ex` uses `:for={error <- @errors} id={@id <> "-error"}` — this creates multiple elements with the same ID, which is invalid HTML. Phase 189 should fix this: either index the error IDs (`id <> "-error-0"`, etc.) or use a wrapper `div` with one ID. The `described_by/3` logic must be updated accordingly.

### StatusBadge / tag / pill family

**Current state:**
- `.ax-status-badge` (line 1251): `ax-type-exception` + raw `font-size: 0.875rem; font-weight: 600; line-height` — must migrate to `font: var(--ax-type-label-sm-font)`.
- Color: tone variants use `color-mix(in srgb, var(--ax-success) 14%, var(--ax-elevated))` — not using the `--ax-status-*-bg` semantic tokens from Phase 188. This is the biggest token-compliance defect: the Phase-188 tokens exist (`--ax-status-success-bg`, etc.) and the component must consume them instead of local `color-mix()`.
- `--ax-status-badge-moss` should become: `background: var(--ax-status-success-bg); color: var(--ax-status-success-text); border-color: var(--ax-status-success-border);`
- `--ax-status-badge-cobalt` → `background: var(--ax-status-info-bg); color: var(--ax-status-info-text); border-color: var(--ax-status-info-border);`
- `--ax-status-badge-amber` → `background: var(--ax-status-warning-bg); color: var(--ax-status-warning-text); border-color: var(--ax-status-warning-border);`
- `--ax-status-badge-slate` → `background: var(--ax-status-neutral-bg); color: var(--ax-status-neutral-text); border-color: var(--ax-status-neutral-border);`
- `--ax-status-badge-ink` → keep current or map to a neutral dark tone; the current `ax-primary 10% + elevated` is reasonable but could use `--ax-status-neutral-bg/text`.
- CMP-03 contract: StatusBadge must NOT have `cursor: pointer` or `:hover` background shift. Current CSS does not add hover styles, but the `--ax-transition-colors` transition at line 1342 (`.ax-status-badge { transition: var(--ax-transition-colors); }`) means a state-change transition is present — this is acceptable (the transition fires on status changes in LiveView patches, not on hover). Verify in e2e that `getComputedStyle(badge).cursor` is NOT `pointer`.
- The `data-ax-state` attribute approach: to show hover/focus/etc. in the lab matrix, interactive states should use CSS classes or the `:is(.ax-dev-state-force-hover)` pattern. For non-interactive components like StatusBadge, the spec correctly marks these states n/a.

### Icon family

**Current state** (`app.css` lines 51-60):
- `.ax-icon { width: var(--ax-icon-md); height: var(--ax-icon-md); flex: none; display: inline-block; vertical-align: middle; }`
- `.ax-icon-sm`, `.ax-icon-md`, `.ax-icon-lg` size modifiers present.
- `icon.ex`: correct `aria-hidden="true"` by default; `role="img"` + `aria-label` + `<title>` when `@label` is set.
- Defects: none expected at CSS level — icon is a display primitive with correct sizing and color inheritance. The lab state matrix for icon should show `default` only (all interactive states are n/a — correctly specified in 189-UI-SPEC.md).
- Phase 189 must add the icon family to the registry with its `applicable_states: ["default"]` and `na_states` for all others.

### MoneyFormatter

**Current state** (`app.css` lines 1114-~):
- `.ax-money { ... }` — need to check the actual block.
- `money_formatter.ex` outputs `<span class={["ax-money", @class]}` — the `@class` pass-through means page-level classes CAN be injected. Phase 189 must verify no consuming pages currently add overriding classes to `ax-money` spans.
- The component is display-only — all interactive states are n/a.
- The negative (red) display uses `ax-money-negative` but no CSS rule for that was found in the excerpt read — need to verify the actual rule exists.

### JsonViewer

**Current state:**
- `json_viewer.ex` uses `class="ax-card ax-json-viewer"` as the outer wrapper — it inherits `ax-card` padding and elevation. In a state-matrix cell, the card padding/border may be redundant (cells have their own padding). The matrix renderer should potentially strip the card class for lab specimens.
- The viewer has built-in tab buttons (`tree`/`raw`/`copy`) using `ax-tab` / `ax-tab-active` classes — these are interactive but are Phase 190 (tab component). For Phase 189, the viewer should be shown in its default `tree` tab state.
- `.ax-json-value`, `.ax-json-key` (lines 758-760): need to verify they use type tokens, not raw `font-size`.
- Readonly background: `json_viewer` is read-only by nature; it should get `background: var(--ax-readonly-bg)` on the outer card wrapper — this is a semantic role application the phase must apply.

### Spinner / Skeleton / Loading

- No dedicated `spinner.ex` or `skeleton.ex` component file found in `accrue_admin/lib/accrue_admin/components/`. These are likely either:
  - CSS-only primitives (`.ax-skeleton` referenced in motion table and `reduced-motion.spec.js`)
  - Inline HEEx patterns in specific pages
- **Phase 189 must first inventory whether a Phoenix.Component exists for spinner/skeleton or if it needs to be created.** If CSS-only, the registry entry points to a CSS class rather than a component function.
- The motion spec confirms `.ax-skeleton` selector exists in app.css. The shimmer animation is the documented exception to the motion ban.

### Tooltip

- No `tooltip.ex` found in the components directory listing. Like spinner/skeleton, Phase 189 must either find where tooltip is implemented or create the primitive.
- The tooltip `--ax-z-popover` (300) layer contract from the UI spec must be verified or established.

### Inline code / ID display

- No dedicated component — likely inline `<code>` elements styled by `.ax-type-code` or `.ax-type-code-xs` classes.
- Phase 189 must decide: create a `InlineCode` component with `ax-inline-id` class, or use the CSS class directly. D-01 lists it as a Phase-189 primitive.
- Overflow contract: `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` constrained by `max-width`.

### Empty-state hero

- Exists in kitchen as an inline pattern (lines 157-162 in `component_kitchen_live.ex`):
  ```elixir
  <div class="ax-card ax-empty">
    <Icon.icon name={:inbox} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
    <p class="ax-empty-title">No rows in this list yet</p>
    <p class="ax-body ax-empty-copy">...</p>
  </div>
  ```
- No dedicated `EmptyState` component module. Phase 189 must either create one or standardize the inline pattern and add it to the registry as a CSS-class-based family.
- CMP-03: the outer container must have no `cursor: pointer` and no hover background shift. `.ax-empty` must not have a hover rule.

---

## Verification Harness Mechanics

### Layer 1: admin-a11y.spec.js extension

The existing spec (93 lines) already has the `scan()` helper that:
1. Sets `data-theme` on `document.documentElement`
2. Waits 50ms for transition to settle (or relies on `reducedMotion: "reduce"` to make it instant)
3. Runs `@axe-core/playwright` with `wcag2a` + `wcag2aa` tags
4. Filters for `critical` or `serious` violations

**Phase 189 extension:** Add `/billing/dev/components` to the surfaces list. The scan will sweep all rendered component states in both themes (since the grid contains both in the same DOM). A single scan of the kitchen route covers all family/state/theme cells simultaneously.

Cell-id grammar for kitchen axe results:
- `p187__component-kitchen__chromium-desktop__light__default-populated__d06` (contrast dimension)
- `p187__component-kitchen__chromium-desktop__dark__default-populated__d06`

### Layer 2: admin-interactions.spec.js extension

The existing spec has these probe utilities (confirmed from reading lines 1-240):
- `makeRecorder(projectName)` — creates an NDJSON observation recorder per project
- `observe(row)` — records a typed observation row with all `OBSERVATION_FIELDS`
- `topElementAt(locator)` — `elementFromPoint` probe for z-index/click interception
- `scrollProbe(page, selector, ...)` — scroll metrics check
- `focusCycleProbe(page, surfaceSelector, ...)` — Tab/Shift+Tab inside surface
- `clickOrObserve(locator, recorder, baseRow)` — click + observe with interception detection
- `visible(locator)` and `text(locator)` — helper utilities

**Phase 189 must add a new probe block** for the `/billing/dev/components` route:

```js
// Focus probe for each interactive primitive family
async function focusProbe(page, selector, recorder, surface, state) {
  const el = page.locator(selector).first();
  await el.focus();
  const styles = await el.evaluate((element) => {
    const cs = getComputedStyle(element);
    return {
      outlineWidth: cs.outlineWidth,
      outlineOffset: cs.outlineOffset,
      cursor: cs.cursor,
    };
  });
  recorder.observe({
    interaction_class: "focus-ring",
    cell_id: `p187__component-kitchen__chromium-desktop__light__${state}__d07`,
    surface: surface,
    surface_type: "component",
    state: state,
    rubric_dimension: "focus-semantics",
    target_selector: selector,
    expected: "outlineWidth >= 2px; outlineOffset >= 2px",
    actual: JSON.stringify(styles),
    assertions: ["outline-width-2px", "outline-offset-2px"],
    coverage_status: (parseFloat(styles.outlineWidth) >= 2 && parseFloat(styles.outlineOffset) >= 2) ? "covered" : "gap",
    failure_kind: parseFloat(styles.outlineWidth) < 2 ? "focus-ring-missing" : null,
    overlay_tags: ["focus-restore"],
  });
}

// Overflow probe
async function overflowProbe(page, selector, recorder, surface) {
  const el = page.locator(selector).first();
  const metrics = await el.evaluate((element) => ({
    scrollWidth: element.scrollWidth,
    clientWidth: element.clientWidth,
    overflow: getComputedStyle(element).overflow,
  }));
  recorder.observe({
    interaction_class: "overflow-clip",
    cell_id: `p187__component-kitchen__chromium-desktop__light__overflow__d05`,
    surface,
    surface_type: "component",
    state: "overflow",
    rubric_dimension: "responsive-mobile-first",
    target_selector: selector,
    expected: "scrollWidth <= clientWidth (no overflow escape)",
    actual: JSON.stringify(metrics),
    assertions: ["scrollWidth-lte-clientWidth"],
    coverage_status: metrics.scrollWidth <= metrics.clientWidth ? "covered" : "gap",
    failure_kind: metrics.scrollWidth > metrics.clientWidth ? "content-overflow-escape" : null,
    overlay_tags: ["scroll-reachability"],
  });
}
```

The `cell_id` for component-kitchen observations should use a stable surface slug. Given the kitchen is at `/billing/dev/components` and maps to the `component` surface type, the surface slug should be `component-kitchen` or per-family (e.g., `button-primary`). Either approach is valid as long as it's consistent across all Phase 189 observations and consistent with how Phase 192 re-runs them.

### Layer 3: score-visuals.mjs extension

The existing `score-visuals.mjs` reads PNG screenshots from `test-results/admin-visuals/{chromium-desktop,chromium-mobile}/` by filename. Phase 189 must ensure the kitchen route is captured as a screenshot. The `e2e:visuals:png-only` npm script (referenced in the remediation loop comment) must include the kitchen route.

### Writing results into the frozen cell-id grammar

The `p187__{surface}__{mode}__{theme}__{state}__{dXX}` grammar components for Phase 189 component-kitchen observations:
- `surface`: `component-kitchen` (or family-specific like `button`, `input`)
- `mode`: `chromium-desktop` or `chromium-mobile` (matches PROJECTS)
- `theme`: `light` or `dark`
- `state`: from COMPONENT_STATES taxonomy — `default-populated`, `disabled-readonly`, `overflow`, `long-content`, `error`, `loading`, `interactive-open` (the Phase-187 baseline taxonomy, not the Phase-189 state-matrix vocabulary which uses slightly different names — note this mapping)
- `dXX`: `d01` through `d12` for the 12 rubric dimensions

**Critical mapping:** The Phase-189 state matrix uses `default`, `hover`, `focus`, `active`, `disabled`, `loading`, `selected`, `empty`, `error`, `overflow` while the Phase-187 COMPONENT_STATES taxonomy uses `default-populated`, `disabled-readonly`, `overflow`, `long-content`, `error`, `loading`, `interactive-open`. The planner must establish a mapping table so Phase 189 e2e observations are written using the Phase-187 NDJSON taxonomy, not the Phase-189 matrix vocabulary. Example: `disabled` → `disabled-readonly`; `hover`/`focus`/`active` → `interactive-open`.

---

## CMP-05 Guard (D-15)

### What to detect

Per the UI-SPEC (lines 563-574), the guard must flag:
1. Per-page CSS overrides of primitive `ax-*` classes (e.g., `.ax-button { font-size: 1rem; }` in a page-specific CSS block)
2. Raw inline `style=` attributes on primitive component HTML elements
3. Raw `font-size`, `font-weight`, `line-height`, `letter-spacing`, `font-family` in component selectors outside the `ax-type-exception` allowlist (already guarded by the existing Phase-188 FND-01 guard)
4. Literal `z-index` values outside micro-stacking exceptions (already guarded by FND-02)

**Net new for CMP-05:** Items 1 and 2 are new. Items 3 and 4 are already covered by Phase-188 guards — CMP-05 complements them.

### Shell verifier approach (recommended)

Add to `verify_package_docs.sh`:

```bash
# Phase 189 CMP-05: no per-page overrides of primitive ax-* classes
# Per-page CSS files (not app.css / theme.css) must not re-define primitive selectors
primitive_override_hit=$(
  find "$ROOT_DIR/accrue_admin/assets/css" -name "*.css" \
    ! -name "app.css" ! -name "theme.css" -print0 |
    xargs -0 grep -E '\.ax-(button|field|input|select|status-badge|icon|money|json|empty)[^{]*\{' |
    head -n 1
)
[[ -z "$primitive_override_hit" ]] || fail "per-page CSS overrides of primitive ax-* classes are not allowed (CMP-05): $primitive_override_hit"

# Phase 189 CMP-05: no raw inline style on primitive component wrappers
# Scan HEEx templates for style= on elements that already carry ax-* primitive classes
inline_style_hit=$(
  find "$ROOT_DIR/accrue_admin/lib" -type f \( -name '*.ex' -o -name '*.heex' \) -print0 |
    xargs -0 perl -0ne '
      while (/~H"""(.*?)"""/sg) {
        my $template = $1;
        # Flag elements that have both an ax-* primitive class and a style attribute
        while ($template =~ /<[a-z][^>]*class="[^"]*\b(ax-button|ax-field|ax-input|ax-select|ax-status-badge|ax-money|ax-json)\b[^"]*"[^>]*style=/g) {
          print "$ARGV: $1\n";
          last;
        }
      }
    ' |
    head -n 1
)
[[ -z "$inline_style_hit" ]] || fail "raw inline style on primitive ax-* elements is not allowed (CMP-05): $inline_style_hit"
```

### Negative fixture (D-08 coupling pattern)

Following the established verifier ↔ negative-fixture coupling pattern, add a test in `PackageDocsVerifierTest` (or a dedicated `ComponentRootEnforcementTest`) that:

1. Creates a temporary CSS file with a per-page primitive override
2. Runs the verifier against a test directory containing that file
3. Asserts the verifier exits non-zero with the expected error message

The Pattern from existing `component_registry_test.exs` / `verify_package_docs.sh` coupling: the test seeds a `tmp_dir` with the files the verifier checks, injects a violation, runs the shell verifier via `System.cmd/3`, and asserts the exit code and stderr message.

---

## Component Missing-Primitive Inventory

The following primitives listed in D-01 do NOT have a dedicated `*.ex` component module in `accrue_admin/lib/accrue_admin/components/`:

| Primitive | Status | Phase 189 action |
|-----------|--------|-----------------|
| `textarea` | Missing — `input.ex` handles text input but no `textarea.ex` | Create `textarea.ex` component or extend `input.ex` with a `type="textarea"` branch |
| `checkbox` | Missing — only `.ax-checkbox` CSS class exists | Create `checkbox.ex` or accept inline HTML pattern; add to registry |
| `radio` | Missing | Create `radio.ex` or accept inline HTML; add to registry |
| `toggle switch` | Missing | Create `toggle.ex` component; add to registry |
| `spinner` | Missing — `.ax-skeleton` CSS exists, no component | Create `spinner.ex` or accept CSS-only pattern |
| `skeleton` | Missing — `.ax-skeleton` CSS exists | Accept CSS-only pattern or create component |
| `tooltip` | Missing | Create `tooltip.ex` or accept inline pattern |
| `inline code / ID` | Missing — CSS utilities exist | Accept `.ax-type-code` CSS class or create `InlineId` component |
| `empty-state hero` | Missing — inline pattern exists | Decide: extract to `EmptyState` component or standardize inline pattern |

**The planner must allocate a Wave 0 task** to decide the component existence question for each missing primitive: create a module or accept CSS-only / inline. The decision affects how the registry `specimens` field references each family.

---

## Common Pitfalls

### Pitfall 1: `outline: none` on focus-visible without a replacement

**What goes wrong:** Current `app.css` has `.ax-field-control:focus-visible { border-color: var(--ax-focus-ring); outline: none; }`. This kills the default browser focus ring and replaces it only with a border-color change — which is a weak, color-only indicator that fails WCAG 2.4.11.

**Why it happens:** Historical practice before the Phase-188 focus contract was established.

**How to avoid:** Change to `outline: 2px solid var(--ax-focus-ring); outline-offset: 2px; box-shadow: var(--ax-focus-shadow);` — remove the `border-color` change or keep it as secondary reinforcement.

**Warning signs:** axe-core `color-contrast` violations on focused inputs; `getComputedStyle` probe showing `outlineWidth: "0px"`.

### Pitfall 2: `pointer-events: none` on disabled removes cursor feedback

**What goes wrong:** `.ax-button:disabled { pointer-events: none; }` means the `cursor: not-allowed` signal never reaches the user — the cursor shows as the default arrow instead.

**How to avoid:** Change disabled rule to `opacity: var(--ax-disabled-opacity); cursor: var(--ax-disabled-cursor);` without `pointer-events: none`. Use the `disabled` HTML attribute (or `aria-disabled`) for actual disabling of activation, not CSS pointer-events.

### Pitfall 3: D-07 partial token set in sub-tree dark selector

**What goes wrong:** If `theme.css` adds `.accrue-admin [data-theme="dark"]` with only a subset of the dark tokens (e.g., just `--ax-base` and `--ax-elevated`), child elements that rely on other dark tokens (e.g., `--ax-border`) fall back to the light values inside the dark column — producing incorrect mixed-theme specimens.

**How to avoid:** Copy the FULL dark token block from `html.accrue-admin[data-theme="dark"]` verbatim into the new sub-tree selector. Do not subset it.

### Pitfall 4: Registry entry `ax_class` split assumption

**What goes wrong:** The variant-presence test (a) does `[_base, variant_class] = String.split(ax_class, " ", parts: 2)`. For entries where `ax_class` has only one class (hypothetically `"ax-icon-sm"`), this crashes the pattern match.

**How to avoid:** Ensure every Phase 189 registry entry has at least two space-separated classes in `ax_class`, OR update the variant-presence test to handle single-class entries gracefully.

### Pitfall 5: Multiple errors with same HTML `id` attribute

**What goes wrong:** `input.ex` line 41 renders `<p :for={error <- @errors} id={@id <> "-error"} ...>` — if there are 2+ errors, the DOM has multiple elements with the same ID, which is invalid HTML and causes axe-core `duplicate-id` violations.

**How to avoid:** Phase 189 must fix the error ID generation — either enumerate (`id <> "-error-#{index}"`) or wrap all errors in a single `<div id={@id <> "-errors"}>`.

### Pitfall 6: StatusBadge `color-mix` vs status semantic tokens

**What goes wrong:** The current `.ax-status-badge-moss` uses `color-mix(in srgb, var(--ax-success) 14%, var(--ax-elevated))` — this is NOT the same value as `--ax-status-success-bg` which is a carefully-tuned contrast-safe color. In dark mode, `var(--ax-elevated)` is `#171d24`, so the mix produces a different shade than `--ax-status-success-bg: #14261c`. The Phase-188 status tokens were tuned for AA contrast; the color-mix formulas were not.

**How to avoid:** Migrate ALL badge tone CSS to use `var(--ax-status-{role}-bg)`, `var(--ax-status-{role}-text)`, `var(--ax-status-{role}-border)`. Delete the `color-mix()` formulas.

### Pitfall 7: `active_organization_name` missing from `assign_shell/4`

**What goes wrong:** `component_kitchen_live.ex` line 57 passes `active_organization_name={@active_organization_name}` to `AppShell` but `assign_shell/4` (lines 451-462) does NOT assign `:active_organization_name`. This would raise a `KeyError` for `@active_organization_name` at render time unless the session provides it or `AppShell` has a default.

**Note:** This may be an existing non-issue if the session always provides it via `admin["active_organization_name"]`. Phase 189 should verify by checking if `assign_shell/4` needs to add `|> assign(:active_organization_name, admin["active_organization_name"])`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme token cascade in sub-tree | Custom JS to swap CSS vars | CSS `data-theme` attribute + `theme.css` sub-tree selector | CSS cascade handles this natively; no JS needed |
| State simulation for matrix cells | JavaScript to force DOM state | CSS `:is(.ax-dev-state-force-hover)` applied to specimen wrapper + `CSS.escape()` lookup | Pure CSS; no JS event emulation; works in captured PNGs |
| WCAG contrast checking | Custom color-math code | `@axe-core/playwright` `color-contrast` rule + `getComputedStyle` probe | axe handles WCAG math correctly including `currentColor` resolution |
| Duplicate error ID fix | A new error-rendering macro | Simple `:for={error <- Enum.with_index(@errors)}` with indexed IDs | Elixir built-in is sufficient |
| Focus ring application | Browser-default ring (remove with outline:none) | `outline: 2px solid var(--ax-focus-ring); box-shadow: var(--ax-focus-shadow)` | The Phase-188 token contract is already established — consume it |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| ExUnit framework | `mix test` (standard Elixir) |
| LiveView test | `AccrueAdmin.LiveCase` (`async: false` due to DB sandbox) |
| e2e runner | Playwright (`npm run e2e` in `accrue_admin/`) |
| a11y runner | `npm run e2e:a11y` |
| Vision scorer | `npm run score-visuals` |
| Quick run (unit) | `mix test test/accrue_admin/dev/component_registry_test.exs` |
| Full suite | `mix test && npm run e2e && npm run e2e:a11y && npm run score-visuals` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Signal |
|--------|----------|-----------|-------------------|--------|
| CMP-01 | Every primitive exercised in lab across full state matrix in both themes | ExUnit (registry drift) + Playwright (axe sweep on kitchen route) | `mix test test/accrue_admin/dev/component_registry_test.exs` + `npm run e2e:a11y` | Registry test (e): all applicable_states render; axe sweep: zero violations |
| CMP-01 | Light and dark columns resolve different computed colors | Playwright probe (new) | `npm run e2e -- e2e/admin-interactions.spec.js` | `lightBase !== darkBase` assertion passes |
| CMP-02 | Long/overflowing content renders without clipping or layout break | Playwright probe (extend admin-interactions) | `npm run e2e -- e2e/admin-interactions.spec.js` | `scrollWidth <= clientWidth` for all overflow specimens |
| CMP-03 | Interactive primitives: correct role, keyboard, focus, name | Playwright axe + keyboard probe | `npm run e2e:a11y` + new keyboard probe in admin-interactions | Axe: no button-name/label violations; focus probe: outlineWidth >= 2px |
| CMP-03 | Non-interactive elements: no misleading affordances | Playwright probe (cursor check) | `npm run e2e -- e2e/admin-interactions.spec.js` | `getComputedStyle(badge).cursor !== "pointer"` |
| CMP-04 | Disabled/readonly visually unmistakable; button text contrast | Playwright probe + axe color-contrast | `npm run e2e:a11y` + disabled probe | Axe: no color-contrast violations; disabled bg = `--ax-disabled-bg` computed value |
| CMP-05 | No per-page overrides of primitive ax-* classes; no raw inline style | Shell verifier + ExUnit negative fixture | `bash scripts/ci/verify_package_docs.sh` | Verifier exits 0 with compliant codebase; exits 1 with injected violation |

### Sampling Rate

- Per task commit: `mix test test/accrue_admin/dev/component_registry_test.exs`
- Per wave merge: `mix test && npm run e2e:a11y`
- Phase gate: full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/accrue_admin/dev/component_registry_test.exs` — extend with tests (e) and (f) for state-matrix structure and theme column data-attributes
- [ ] `e2e/admin-interactions.spec.js` — extend with component-kitchen probe block (focus, overflow, theme delta, disabled-affordance checks)
- [ ] `accrue_admin/assets/css/app.css` — add `.ax-dev-state-grid` rules (no existing definition)
- [ ] `accrue_admin/assets/css/theme.css` — add sub-tree `[data-theme="dark"]` selector (D-07 critical path)
- [ ] Component creation: audit for missing primitives (textarea, checkbox, radio, toggle, spinner, skeleton, tooltip, inline-id, empty-state) before writing registry entries

---

## Security Domain

This phase contains no authentication, secrets handling, webhook processing, or user-data persistence. It is a dev-only UI surface (`Mix.env() != :prod` guard on both `ComponentRegistry` and `ComponentKitchenLive`). Security domain is not applicable.

---

## Environment Availability

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Elixir / OTP | ExUnit registry tests | Yes | Production environment |
| Playwright | e2e probes | Yes | Existing e2e suite runs in CI |
| `@axe-core/playwright` | a11y sweep | Yes | Already imported in admin-a11y.spec.js |
| `ANTHROPIC_API_KEY` | score-visuals.mjs | Optional (env-gated) | Script skips cleanly if absent |
| Chrome/Chromium | Playwright e2e | Yes | Required by existing e2e suite |

---

## State of the Art

| Old Approach | Current Approach | Impact on Phase 189 |
|--------------|------------------|---------------------|
| Per-specimen `data-theme` wrappers (inert) | Sub-tree CSS selector for `data-theme` | Must implement option B (theme.css sub-tree selector) — the old approach was documented as a known gap |
| `color-mix()` formulas for badge tones | Phase-188 `--ax-status-*` semantic tokens | Badge CSS must migrate off `color-mix()` to status token consumption |
| Raw `font-size/weight/line-height` with `ax-type-exception` comments | Composed role tokens (`--ax-type-{role}-font` + `--ax-type-{role}-tracking`) | All `ax-type-exception` comments in primitive selectors must be resolved in Phase 189 |
| `outline: none` on `:focus-visible` | Full focus ring: `outline + outline-offset + box-shadow` | All `outline: none` occurrences on interactive primitives must be fixed |
| `pointer-events: none` for disabled | `opacity + cursor` only; `disabled` attribute handles behavior | Fix disabled CSS on `.ax-button:disabled` |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `active_organization_name` is always provided via session; the missing `assign` in `assign_shell/4` is not an existing runtime error | Per-family landmines (Pitfall 7) | If wrong: kitchen page crashes at render; Wave 0 must add the assign |
| A2 | The `reduced-motion.spec.js` spec covers `.ax-button` transition durations at line 12 (matches `app.css:~1000`) | Verification harness | If wrong: reduced-motion guard for buttons may need a separate selector |
| A3 | No tooltip, checkbox/radio/toggle, spinner/skeleton component `.ex` files exist (not found in directory listing) | Missing-primitive inventory | If wrong (they exist elsewhere or under different names): planning effort for creation tasks is wasted; actual state needs re-verification |
| A4 | The `npm run e2e:visuals:png-only` script (referenced in score-visuals.mjs comment) does NOT currently include `/billing/dev/components` as a target | Verification harness | If wrong: vision layer already covers the kitchen; no extension needed |

---

## Open Questions

1. **Spinner/skeleton/tooltip/checkbox/radio/toggle component existence**
   - What we know: no `.ex` files found in `accrue_admin/lib/accrue_admin/components/` for these families.
   - What's unclear: Are they defined elsewhere? Inline patterns only? Or genuinely missing?
   - Recommendation: Wave 0 task — run `grep -rn "ax-skeleton\|ax-spinner\|ax-toggle\|ax-checkbox" accrue_admin/lib/` to confirm and make the component-existence decision.

2. **NDJSON cell-id surface slug for kitchen observations**
   - What we know: the grammar is `p187__{surface}__{mode}__{theme}__{state}__{dXX}`; existing component rows use surface names like `button`, `app-shell`.
   - What's unclear: should Phase 189 kitchen observations use `component-kitchen` (the route slug) or per-family (`button`, `input`, etc.)?
   - Recommendation: Use per-family surface slugs matching the existing Phase-187 component surface names. This allows Phase 192 to diff individual family rows rather than a monolithic kitchen row.

3. **Mobile state-grid layout at 390px**
   - What we know: the UI-SPEC says "stack columns vertically OR show light only with a Dark tab toggle."
   - What's unclear: which is preferred?
   - Recommendation: Stack vertically (simpler, no JS, dark column still rendered and accessible). Add `@media (max-width: 599.98px)` breakpoint with `grid-template-columns: 1fr`.

---

## Sources

### Primary (HIGH confidence — verified from codebase)

- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — actual registry schema, 4 current tests
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — D-07 gotcha inline comments (lines 166-168), render structure, helper functions
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — exact assertions in all 4 tests
- `accrue_admin/assets/css/app.css` — actual `.ax-button`, `.ax-field-control`, `.ax-status-badge` CSS with `ax-type-exception` comments; `.ax-dev-grid`, `.ax-dev-variant-row` definitions
- `accrue_admin/assets/css/theme.css` — dark-theme selector chain (`html.accrue-admin[data-theme="dark"]`); all semantic tokens confirmed present
- `accrue_admin/e2e/admin-a11y.spec.js` — `scan()` helper pattern; surface list
- `accrue_admin/e2e/admin-interactions.spec.js` — `makeRecorder`, `observe`, `topElementAt`, `scrollProbe`, `focusCycleProbe` utilities
- `accrue_admin/e2e/baseline-manifest.js` — `COMPONENT_STATES`, `PROJECTS` (1440/390), cell-id grammar, `OVERLAY_TAGS`
- `accrue_admin/e2e/score-visuals.mjs` — vision pass model, PNG directory, remediation loop
- `scripts/ci/verify_package_docs.sh` — existing Phase-188 guards (z-index, font-literal, Tailwind, motion antipatterns); the coupling pattern
- `.planning/phases/187-audit-baseline/defects.ndjson` — 342 Phase-189 defects; top surfaces: app-shell (192), button (120); pattern: all are gap/state-not-forced defects

### Secondary (HIGH confidence — approved design contracts)

- `189-CONTEXT.md` — D-01..D-15 locked decisions
- `189-UI-SPEC.md` — per-family specimen contracts, CSS rules for `.ax-dev-state-grid`
- `188-CONTEXT.md` — D-17..D-22 semantic role tokens, focus contract

### Tertiary (ASSUMED — training knowledge, not verified from fresh docs)

- None for this phase — all technical claims are verified against live codebase or approved spec documents.

---

## Metadata

**Confidence breakdown:**
- Current code state: HIGH — all key files read directly
- Registry schema extension: HIGH — based on actual schema observed
- D-07 theme-column fix: HIGH — CSS selector chain verified from theme.css
- Per-family defects: MEDIUM — most are "state not forced" gaps from the Phase-187 capture, not observed behavioral regressions; specific CSS defects (wrong error token, outline:none, type exceptions) are HIGH from direct inspection
- Missing primitives: MEDIUM — directory listing confirms absence; not 100% certain they don't exist under a different path

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable CSS/Elixir surface; no expected upstream churn)
