# Phase 174: A — Design-System Gap Closure & Token Completeness - Research

**Researched:** 2026-06-03
**Domain:** CSS design-token system, Phoenix LiveView component gallery, Elixir ExUnit test drift-prevention
**Confidence:** HIGH — all findings grounded directly from the codebase source files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Breakpoint mechanism = documented `--ax-bp-*` constants block + grep-guard. NO build-pipeline change.
- D-02: Implementation = commented registry block at top of `app.css` + inline `--ax-bp-*` comment on every `@media`.
- D-03: Token names: `--ax-bp-sm`=600, `--ax-bp-md`=768, `--ax-bp-lg`=1024, `--ax-bp-content`=640. Mobile-first min-width; max-width uses `-0.02px` guard form.
- D-04: Existing token-bypass grep guard + its negative-test seed fixture MUST both gain the new breakpoint needle.
- D-05: The 600/640 proximity reconciliation is deferred to Phase C.
- D-06: Type micro-token naming = semantic (leading/tracking vocabulary), NOT numeric t-shirt sizes.
- D-07: Exact token block (verbatim, with values) for `theme.css`:
  ```css
  /* Line-height — unitless (inherits as a ratio) */
  --ax-leading-tight: 1.2;
  --ax-leading-normal: 1.4;
  --ax-leading-relaxed: 1.5;
  /* Letter-spacing — em (scales with font-size) */
  --ax-tracking-tight: -0.02em;
  --ax-tracking-normal: 0;
  --ax-tracking-wide: 0.04em;
  --ax-tracking-caps: 0.08em;
  /* Reading measure */
  --ax-measure: 68ch;
  ```
- D-08: line-height unitless; letter-spacing in em; measure in ch.
- D-09: Keep body at 1.4. Do NOT force 1.5 globally.
- D-10: Keep BOTH `--ax-tracking-wide` (0.04em) and `--ax-tracking-caps` (0.08em).
- D-11: Migration is pure 1:1 literal→token rename, ZERO value changes.
- D-12: Transition shape = property-bundles (full multi-property `transition:` values), NOT timing-only.
- D-13: Ship exactly 4 bundles composed from existing `--ax-dur-*`/`--ax-ease-*` atoms; enter-neutral on `--ax-ease-out`. No `--ax-transition-all`. Use `background-color` not `background` shorthand.
- D-14: New `--ax-transition-*` family. Freeze legacy `--ax-motion-*`/`--ax-theme-transition` as back-compat.
- D-15: Reduced-motion override at token level inside existing `@media (prefers-reduced-motion: reduce)` block in `theme.css`.
- D-16: Exit-asymmetry deferred to Phase D. Ship only neutral bundle substrate.
- D-17: `/dev/components` = hand-rolled LiveView gallery extending `component_kitchen_live.ex`. Zero new deps.
- D-18: Scope to exactly four families: button / badge / status / card.
- D-19: Drive rows from new `AccrueAdmin.Dev.ComponentRegistry` module returning `%{family, variant, ax_class, tokens: [...]}`. Page and drift test share one list.
- D-20: Render both light and dark side-by-side per row via `data-ax-theme="light|dark"` wrappers.
- D-21: `ComponentRegistryTest` drift-prevention test: (a) renders page, asserts every registry variant appears; (b) asserts registry `ax_class` set == component class outputs.
- D-22: Wire `/dev/components` into Phase F Playwright sweep (`e2e/admin-visuals.spec.js`) — build screenshot-ready now, wiring lands in Phase F.

### Claude's Discretion
- Legitimate hardcoded hex OUT of scope (brand-config defaults in `*_live.ex`, `layouts.ex`, `brand_plug.ex`; favicon SVG hex). DSY-02 targets render-path CSS/HEEx bypasses only.
- Optional follow-on: add `attr :variant, :string, values: [...]` to Button/KpiCard/StatusBadge while in-file (ship registry-list first).
- Exact placement of new token blocks within `theme.css`, exact `.ax-measure` consumption sites, CSS section ordering.

### Deferred Ideas (OUT OF SCOPE)
- 600/640 breakpoint proximity reconciliation → Phase C.
- Exit-asymmetry motion bundles / deep motion semantics → Phase D.
- Normalize components to `attr :variant, values: [...]` → optional in Phase 174, otherwise later.
- Adding `/dev/components` to Playwright screenshot sweep → Phase F (wiring only; page must be built screenshot-ready).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DSY-01 | Admin CSS resolves every spacing, type, radius, shadow, line-height, letter-spacing, breakpoint, and transition value from a named `ax-*` token — no hardcoded px/em for these remain in `app.css` or components | Line-height: 13 literal sites confirmed; letter-spacing: 5 literal sites confirmed; breakpoints: 9 `@media` sites confirmed; multi-line transition blocks: 5 confirmed. All are 1:1 replace. |
| DSY-02 | Dunning banner and invoice screens render brand colors via tokens with zero inline-hex fallbacks; no surface bypasses the token system | Confirmed: sole remaining bypass is `dunning_banner.ex:27` inline `style=`. No other `style=` attributes found anywhere in `accrue_admin/lib/`. |
| DSY-03 | Maintainer can open `/dev/components` and see a component-variants reference enumerating every button/badge/status/card variant with its token mapping | Route exists at line 89 of `router.ex`; extends existing `component_kitchen_live.ex`; variant truth confirmed in component source files. |
</phase_requirements>

---

## Summary

Phase 174 is a pure design-system substrate phase: no new screens, no new billing primitives, no IA changes. It has three tightly-scoped deliverables that interlock via a shared `--ax-*` token taxonomy.

**Deliverable 1 (DSY-01 token gap-closure):** Add line-height, letter-spacing, reading-measure, and transition-bundle tokens to `theme.css`; add a breakpoint registry comment-block and inline `--ax-bp-*` comments to every `@media` in `app.css`; migrate all hardcoded literals to their new tokens. Grep confirms: 13 line-height literal sites, 5 letter-spacing literal sites, 9 `@media` breakpoint sites, and 5 multi-line `transition:` blocks. Every migration is a pure 1:1 literal→token rename with zero value changes — this is a mechanical rewrite with clear search targets.

**Deliverable 2 (DSY-02 bypass kill):** The only remaining token bypass in the entire `accrue_admin/lib/` tree is `dunning_banner.ex` line 27: a `style=` attribute with three inline hex fallbacks (`#fef2f2`, `#991b1b`, `#fecaca`). The CSS classes `.ax-banner.ax-banner-danger` already exist in `app.css` and already resolve from the correct semantic tokens (`--ax-danger-surface`, `--ax-danger-readable`, `--ax-danger-border`). The fix is to remove the `style=` attribute entirely.

**Deliverable 3 (DSY-03 component-variants reference):** The `/dev/components` route already exists in `router.ex` (line 89), already renders `ComponentKitchenLive`, and already imports Button/StatusBadge/KpiCard. The work is: create `AccrueAdmin.Dev.ComponentRegistry`, extend `component_kitchen_live.ex` to render full variant reference rows with light/dark side-by-side, and write a `ComponentRegistryTest` drift-prevention test.

**Primary recommendation:** Sequence as Wave 0 (token blocks in `theme.css`) → Wave 1 (breakpoint comments + literal migrations in `app.css` + dunning bypass kill) → Wave 2 (ComponentRegistry + kitchen extension) → Wave 3 (drift test + asset rebuild + commit `priv/static`). Each wave is independently verifiable.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token definitions (line-height, letter-spacing, measure, transition bundles) | `theme.css` CSS layer | — | Token home is `theme.css`; all `--ax-*` custom properties live here |
| Breakpoint registry block | `app.css` CSS layer | — | CSS `@media` cannot read `var()`; breakpoints live as commented constants in `app.css`, not in `theme.css` |
| Reduced-motion bundle overrides | `theme.css` CSS layer (`@media (prefers-reduced-motion: reduce)` block, line 157) | — | Token-level override cascades to all consumers; existing block is the hook |
| Literal→token migration | `app.css` CSS layer | — | All 13 line-height + 5 letter-spacing + 5 transition block sites are in `app.css` |
| DSY-02 inline-style bypass kill | `dunning_banner.ex` HEEx layer | — | Only remaining `style=` in the entire lib tree |
| ComponentRegistry (data) | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | — | Single source of truth for variant→class→token mapping |
| ComponentKitchenLive (render) | `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | ComponentRegistry | LiveView rendering from registry data |
| Drift-prevention test | `accrue_admin/test/` ExUnit | ComponentRegistry + ComponentKitchenLive | Asserts registry matches component class outputs |
| Asset bundle | `priv/static/accrue_admin.css` | `mix accrue_admin.assets.build` | Committed bundle; host apps don't run Tailwind; must rebuild + commit after every CSS edit |

---

## Standard Stack

No external packages are installed in this phase. All work uses the existing project stack.

### Core (already installed)
| Component | Version | Purpose |
|-----------|---------|---------|
| Tailwind v3 CLI | `tailwindcss@3.4.17` | CSS build (invoked via `mix accrue_admin.assets.build`) |
| esbuild | `esbuild@0.25.3` | JS bundle (same task) |
| Phoenix LiveView | `~> 1.1` (already in `mix.exs`) | `ComponentKitchenLive` + test rendering |
| ExUnit | stdlib | `ComponentRegistryTest` drift test |
| `Phoenix.LiveViewTest` | transitive | `render_component/2` for component tests |

**Installation:** None required. Zero new build dependencies (D-01, UI-SPEC explicit constraint).

---

## Package Legitimacy Audit

Not applicable — this phase installs zero external packages.

---

## Architecture Patterns

### System Architecture Diagram

```
app.css (source)
  ├─ @import theme.css
  │     └─ :root html.accrue-admin { --ax-leading-*, --ax-tracking-*, --ax-measure,
  │                                   --ax-transition-*, @media prefers-reduced-motion }
  ├─ /* === AX BREAKPOINT REGISTRY === */ comment block (new, top of file)
  │     --ax-bp-content = 640px, --ax-bp-md = 768px, --ax-bp-lg = 1024px
  │     --ax-bp-sm-down = 599.98px, --ax-bp-lg-down = 1023.98px
  ├─ line-height: var(--ax-leading-*) [13 migration sites]
  ├─ letter-spacing: var(--ax-tracking-*) [5 migration sites]
  ├─ @media (min-width: 640px) { /* --ax-bp-content ↑ */ ... } [2 sites]
  ├─ @media (min-width: 768px) { /* --ax-bp-md ↑ */ ... } [2 sites]
  ├─ @media (min-width: 1024px) { /* --ax-bp-lg ↑ */ ... } [3 sites]
  ├─ @media (max-width: 599.98px) { /* --ax-bp-sm ↓ */ ... } [2 sites]
  ├─ @media (max-width: 1023.98px) { /* --ax-bp-lg ↓ */ ... } [1 site]
  └─ transition: var(--ax-transition-*) [multi-line collapse targets: 270, 992, 1446, 1967, 2077]
                                                ↓
                               mix accrue_admin.assets.build
                               (npx tailwindcss@3.4.17 --minify → npx esbuild)
                                                ↓
                                 priv/static/accrue_admin.css  (committed bundle)
                                 priv/static/accrue_admin.js

AccrueAdmin.Dev.ComponentRegistry   ←── single source of truth ──→  ComponentRegistryTest
  returns list of %{family, variant, ax_class, tokens: [...]}         (drift assertion)
         ↓
  ComponentKitchenLive.render/1
  (extends existing kitchen; adds reference rows with data-ax-theme light/dark wrappers)
         ↓
  /dev/components route (router.ex line 89; dev_routes? guard)
```

### Recommended Project Structure (new files only)

```
accrue_admin/
├── assets/css/
│   ├── theme.css               # MODIFY: add --ax-leading-*, --ax-tracking-*, --ax-measure,
│   │                           #          --ax-transition-* bundles, reduced-motion overrides
│   └── app.css                 # MODIFY: breakpoint registry block + inline comments,
│                               #          literal→token migrations (line-height, letter-spacing,
│                               #          transition blocks)
├── lib/accrue_admin/
│   ├── components/
│   │   └── dunning_banner.ex   # MODIFY: remove style= attribute on line 27
│   └── dev/
│       ├── component_kitchen_live.ex  # MODIFY: extend with variant reference rows
│       └── component_registry.ex      # NEW: AccrueAdmin.Dev.ComponentRegistry
├── priv/static/
│   └── accrue_admin.css        # REBUILD: commit after every CSS edit
└── test/accrue_admin/
    └── dev/
        └── component_registry_test.exs  # NEW: drift-prevention test
```

### Pattern 1: Token Definitions in theme.css

**What:** New `--ax-leading-*`, `--ax-tracking-*`, `--ax-measure`, and `--ax-transition-*` tokens added to the `html.accrue-admin {}` block in `theme.css`, following the exact house comment style already in use.

**When to use:** Any new ax-* token definition. Always goes in `theme.css`, consumed by `app.css` class definitions.

**Example (house style from existing file, line 52–68):**
```css
/* Source: accrue_admin/assets/css/theme.css — existing motion token block pattern */
/* Motion — split duration + easing tokens (enter vs exit asymmetry; one emphasis curve) */
--ax-dur-instant: 0ms;
--ax-dur-1: 120ms;   /* press, hover, micro */
--ax-dur-2: 180ms;   /* default state change / enter */
```

New tokens follow the same pattern, e.g.:
```css
/* Line-height — unitless (inherits as a ratio) */
--ax-leading-tight: 1.2;     /* display, headings */
--ax-leading-normal: 1.4;    /* body, labels — the default */
--ax-leading-relaxed: 1.5;   /* prose / long-form copy */
/* Letter-spacing — em (scales with font-size) */
--ax-tracking-tight: -0.02em; /* large display tightening */
--ax-tracking-normal: 0;
--ax-tracking-wide: 0.04em;   /* smaller uppercase labels */
--ax-tracking-caps: 0.08em;   /* uppercase eyebrows / section labels */
/* Reading measure — ch ≈ one "0" advance; 68ch ≈ 66 chars (60–75 sweet spot) */
--ax-measure: 68ch;
```

### Pattern 2: Transition Bundles (property-bundles composed from atoms)

**What:** Four `--ax-transition-*` custom properties in `theme.css`, each a full multi-property `transition:` value composed from existing `--ax-dur-*`/`--ax-ease-*` atoms.

**When to use:** Replace the ~5 multi-line `transition:` blocks in `app.css` with a single `transition: var(--ax-transition-base)` (or the appropriate sub-bundle).

**Exact bundle definitions to add to `theme.css` (D-13):**
```css
/* Transition bundles — property-bundles composed from dur/ease atoms.
   Use background-color (not background shorthand) to never conflict with
   skeleton shimmer's background-position animation. */
--ax-transition-colors:
  color var(--ax-dur-2) var(--ax-ease-out),
  background-color var(--ax-dur-2) var(--ax-ease-out),
  border-color var(--ax-dur-2) var(--ax-ease-out);
--ax-transition-transform:
  transform var(--ax-dur-2) var(--ax-ease-out);
--ax-transition-shadow:
  box-shadow var(--ax-dur-2) var(--ax-ease-out);
--ax-transition-base:
  color var(--ax-dur-2) var(--ax-ease-out),
  background-color var(--ax-dur-2) var(--ax-ease-out),
  border-color var(--ax-dur-2) var(--ax-ease-out),
  transform var(--ax-dur-2) var(--ax-ease-out),
  box-shadow var(--ax-dur-2) var(--ax-ease-out);
```

**Reduced-motion override (D-15)** inside the existing block at `theme.css` line 157:
```css
@media (prefers-reduced-motion: reduce) {
  html.accrue-admin {
    /* existing overrides unchanged ... */
    /* New: bundle overrides — use dur-instant so consumers collapse for free */
    --ax-transition-colors: color var(--ax-dur-instant) linear,
      background-color var(--ax-dur-instant) linear,
      border-color var(--ax-dur-instant) linear;
    --ax-transition-transform: transform var(--ax-dur-instant) linear;
    --ax-transition-shadow: box-shadow var(--ax-dur-instant) linear;
    --ax-transition-base: color var(--ax-dur-instant) linear,
      background-color var(--ax-dur-instant) linear,
      border-color var(--ax-dur-instant) linear,
      transform var(--ax-dur-instant) linear,
      box-shadow var(--ax-dur-instant) linear;
  }
}
```

### Pattern 3: Breakpoint Registry Block in app.css

**What:** A commented documentation block at the very top of the `app.css` class-definition section (after `@import "./theme.css"` and font-face declarations), followed by inline `/* --ax-bp-* ↑/↓ */` comments on every `@media (min-width:...)` or `@media (max-width:...)`.

**Example:**
```css
/* === AX BREAKPOINT REGISTRY ===
   CSS @media cannot read var(), so values live here as documented constants.
   Every @media below carries an inline token comment so it is grep-able.

   --ax-bp-content : 640px  (intrinsic content step, not a layout tier)
   --ax-bp-md      : 768px
   --ax-bp-lg      : 1024px
   --ax-bp-sm ↓    : 599.98px  (max-width guard = bp-sm - 0.02px)
   --ax-bp-lg ↓    : 1023.98px (max-width guard = bp-lg - 0.02px)
   =========================== */

/* ... later in file ... */
@media (min-width: 640px) { /* --ax-bp-content ↑ */
  ...
}
@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */
  ...
}
```

### Pattern 4: ComponentRegistry Module

**What:** A plain Elixir module returning a curated list of `%{family, variant, ax_class, tokens: [...]}` maps. No Phoenix dependencies needed — it's a pure data module callable from both the LiveView and the ExUnit drift test.

**Skeleton (executor fills in the actual ax_class and token lists from component source):**
```elixir
defmodule AccrueAdmin.Dev.ComponentRegistry do
  @moduledoc false

  @type entry :: %{
    family: String.t(),
    variant: String.t(),
    ax_class: String.t(),
    tokens: [String.t()]
  }

  @spec entries() :: [entry()]
  def entries do
    [
      # Button family
      %{
        family: "button",
        variant: "primary",
        ax_class: "ax-button ax-button-primary",
        tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"]
      },
      %{
        family: "button",
        variant: "secondary",
        ax_class: "ax-button ax-button-secondary",
        tokens: ["--ax-border", "--ax-elevated", "--ax-transition-colors"]
      },
      %{
        family: "button",
        variant: "ghost",
        ax_class: "ax-button ax-button-ghost",
        tokens: ["--ax-border", "--ax-elevated", "--ax-transition-colors"]
      },
      # StatusBadge family (tones, not statuses — tones are the CSS variant axis)
      %{
        family: "status",
        variant: "moss",
        ax_class: "ax-status-badge ax-status-badge-moss",
        tokens: ["--ax-success", "--ax-success-readable", "--ax-elevated"]
      },
      # ... cobalt, amber, slate, ink
      # KpiCard / card family (delta tones)
      %{
        family: "card",
        variant: "base",
        ax_class: "ax-card ax-kpi-card",
        tokens: ["--ax-elevated", "--ax-shadow-sm", "--ax-border"]
      },
      # ... delta tones: moss, cobalt, amber, slate, ink
    ]
  end

  @doc "All variants for a given family atom."
  def variants_for(family) do
    entries() |> Enum.filter(&(&1.family == family))
  end
end
```

### Pattern 5: ComponentRegistryTest Drift-Prevention

**What:** ExUnit test using `render_component/2` from `Phoenix.LiveViewTest` to assert (a) the page renders all registry variants, and (b) the registry `ax_class` set matches the component's actual class outputs.

**Test file location:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs`

**Pattern (following `display_components_test.exs` style):**
```elixir
defmodule AccrueAdmin.Dev.ComponentRegistryTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest

  alias AccrueAdmin.Dev.ComponentRegistry
  alias AccrueAdmin.Components.{Button, StatusBadge, KpiCard}

  # (a) Every registry variant must appear in the page render
  test "every registry variant appears when kitchen page renders" do
    # render the full kitchen page via live/2 using AccrueAdmin.LiveCase endpoint,
    # or alternatively render each family section in isolation via render_component.
    for %{ax_class: ax_class} <- ComponentRegistry.entries() do
      # class fragment must appear in the rendered HTML
      assert html =~ ax_class, "registry variant #{ax_class} not found in page render"
    end
  end

  # (b) Registry ax_class set must match component's known class outputs
  test "button registry ax_class set matches Button component outputs" do
    registry_classes =
      ComponentRegistry.variants_for("button")
      |> MapSet.new(& &1.ax_class)

    component_classes =
      ["primary", "secondary", "ghost", "danger"]
      |> MapSet.new(fn variant ->
        html = render_component(&Button.button/1, %{variant: variant, type: "button"})
        extract_class(html)  # helper to pull class attr from rendered HTML
      end)

    assert registry_classes == component_classes
  end
end
```

**Key insight:** The `render_component/2` approach (already used in `display_components_test.exs`) is sufficient for this test — no DB, no sandbox needed. The test should be `use ExUnit.Case, async: true`.

### Anti-Patterns to Avoid

- **Extending `--ax-motion-*` / `--ax-theme-transition`:** These are frozen back-compat aliases (D-14). Never add new properties to these aliases. Single-property sites that currently use them may stay as-is.
- **`background` shorthand in transition bundles:** Use `background-color` only (D-13), or the skeleton shimmer's `background-position` animation will be captured by `transition: all` semantics.
- **`--ax-transition-all`:** Explicitly forbidden (D-13). It is a performance footgun.
- **Adding breakpoints to `theme.css`:** CSS `@media` cannot read `var()`. Breakpoint documentation block belongs in `app.css` only.
- **Changing any literal value during the migration:** D-11 mandates zero value changes. Only token references change.
- **Touching brand-config hex in `*_live.ex`, `layouts.ex`, `brand_plug.ex`:** Those are Elixir-layer branding config, explicitly out of scope for DSY-02.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Component variant enumeration for drift detection | Custom introspection / reflection of `attr` values | `ComponentRegistry` curated list (D-19) | `Button` declares `attr :variant` but without `values:` constraint; other components' variant truth lives in private `*_class/1` clauses only — auto-reflection would require refactoring components |
| Token documentation | Separate design-token doc files | Inline comments in `theme.css` and `app.css` registry block | Single source of truth; already the project's established pattern |
| Breakpoint CSS variables | CSS custom properties on `:root` | Documented constants block + inline `@media` comments | CSS `@media` cannot consume `var()` — the tokens are documentation + grep-guard anchors, not functional CSS variables |
| New LiveView for component gallery | Separate route/live module | Extend `component_kitchen_live.ex` (D-17) | Zero new deps; existing module already imports all four families; existing route at `/dev/components` (router.ex line 89) |

---

## Ground-Truth: Current State Inventory

### Line-Height Literal Sites (confirmed via grep)

| Line | Selector / Context | Value | Token to Use |
|------|-------------------|-------|-------------|
| 228 | `.ax-sidebar-name, .ax-heading` | `1.2` | `var(--ax-leading-tight)` |
| 234 | `.ax-display, .ax-kpi-value` | `1.2` | `var(--ax-leading-tight)` |
| 373 | `.ax-label, .ax-eyebrow, .ax-sidebar-link-label, ...` | `1.4` | `var(--ax-leading-normal)` |
| 396 | `.ax-body` | `1.5` | `var(--ax-leading-relaxed)` |
| 583 | `.ax-filter-chip` | `1.4` | `var(--ax-leading-normal)` |
| 847 | `.ax-timeline-details pre, .ax-json-raw` | `1.5` | `var(--ax-leading-relaxed)` |
| 933 | `.ax-breadcrumbs-link, .ax-breadcrumbs-current, .ax-breadcrumbs-separator` | `1.4` | `var(--ax-leading-normal)` |
| 986 | `.ax-button, .ax-status-badge` | `1.4` | `var(--ax-leading-normal)` |
| 1190 | `.ax-badge` | `1.2` | `var(--ax-leading-tight)` |
| 1266 | `.ax-field-label` (first occurrence) | `1.4` | `var(--ax-leading-normal)` |
| 1295 | `.ax-field-help, .ax-field-error, .ax-dropdown-item-description` | `1.4` | `var(--ax-leading-normal)` |
| 1363 | `.ax-dropdown-item-label` | `1.4` | `var(--ax-leading-normal)` |
| 1394 | `.ax-tab` | `1.4` | `var(--ax-leading-normal)` |

**Total: 13 sites.** Three values: 1.2 (tight, 2 sites), 1.4 (normal, 9 sites), 1.5 (relaxed, 2 sites).

Note: The UI-SPEC also lists a `.ax-field-label` at a second location. The grep found two `.ax-field-label` blocks in `app.css` (lines 1263 and 2214). Both must be checked by the executor.

### Letter-Spacing Literal Sites (confirmed via grep)

| Line | Selector / Context | Value | Token to Use |
|------|-------------------|-------|-------------|
| 114 | `.ax-dev-toolbar-label` | `0.08em` | `var(--ax-tracking-caps)` |
| 260 | `.ax-sidebar-group-label` | `0.08em` | `var(--ax-tracking-caps)` |
| 389 | `.ax-eyebrow` | `0.04em` | `var(--ax-tracking-wide)` |
| 2159 | `.ax-summary-title` | `-0.02em` | `var(--ax-tracking-tight)` |
| 2221 | `.ax-field-label` (in detail section) | `0.04em` | `var(--ax-tracking-wide)` |

**Total: 5 sites.** Three values: `0.08em` (caps, 2 sites), `0.04em` (wide, 2 sites), `-0.02em` (tight, 1 site).

### Breakpoint @media Sites (confirmed via grep)

| Line | Query | Token Comment to Add |
|------|-------|---------------------|
| 896 | `@media (min-width: 768px)` | `/* --ax-bp-md ↑ */` |
| 1246 | `@media (min-width: 1024px)` | `/* --ax-bp-lg ↑ */` |
| 1620 | `@media (min-width: 768px)` | `/* --ax-bp-md ↑ */` |
| 1637 | `@media (min-width: 1024px)` | `/* --ax-bp-lg ↑ */` |
| 1655 | `@media (max-width: 1023.98px)` | `/* --ax-bp-lg ↓ */` |
| 1785 | `@media (max-width: 599.98px)` | `/* --ax-bp-sm ↓ */` |
| 1921 | `@media (max-width: 599.98px)` | `/* --ax-bp-sm ↓ */` |
| 2026 | `@media (min-width: 640px)` | `/* --ax-bp-content ↑ */` |
| 2036 | `@media (min-width: 1024px)` | `/* --ax-bp-lg ↑ */` |
| 2231 | `@media (min-width: 640px)` | `/* --ax-bp-content ↑ */` |

**Total: 10 sites** (not 9 — the UI-SPEC had a partial count; grep found 10 breakpoint `@media` rules). Note: `prefers-color-scheme: dark` and `prefers-reduced-motion` queries are NOT breakpoints and do NOT receive `--ax-bp-*` comments.

The `600px` named `--ax-bp-sm` in D-03 refers to the **concept** (sm breakpoint), but the actual live up-query value does not exist as a min-width — the 600px only appears as a `599.98px` max-width guard. There is no `@media (min-width: 600px)` in the file. The `--ax-bp-sm` token is documented in the registry block for completeness but only the `↓` form appears in the current `@media` rules.

### Multi-Line Transition Block Sites (confirmed via grep)

| Line | Selector / Context | Collapse To |
|------|-------------------|------------|
| 270 | `.ax-sidebar-link, .ax-card, .ax-theme-button, .ax-icon-button, .ax-topbar-brand-chip` | `var(--ax-transition-base)` |
| 992 | `.ax-button` | `var(--ax-transition-base)` |
| 1446 | `.ax-search-trigger` | Mixed: 3 properties use `--ax-theme-transition`, 1 uses `--ax-motion-fast`. Collapse to `var(--ax-transition-colors)` + `var(--ax-transition-transform)` or `var(--ax-transition-base)` — executor judgment needed |
| 1967 | `.ax-launcher` | `var(--ax-transition-base)` (transform + box-shadow + border-color) |
| 2077 | `.ax-related-item` | `var(--ax-transition-colors)` (background + border-color only) |

**Note on line 1446 (`.ax-search-trigger`):** This block mixes `--ax-theme-transition` and `--ax-motion-fast`, which use different durations for different properties. D-14 says single-property sites using `--ax-motion-*` MAY stay as-is. The executor should check whether collapsing `.ax-search-trigger` to `var(--ax-transition-base)` is correct or whether this is one of the "flag for Phase D" cases. If the intentional asymmetry matters (different speed for transform vs color), flag it for Phase D rather than encoding a 5th bundle.

**Single-property transition sites (should NOT collapse, confirmed):**
- Line 59: `body { transition: background var(--ax-theme-transition), color var(--ax-theme-transition); }` — two properties but already using legacy alias; D-14 says leave as-is.
- Line 291: `.ax-sidebar-link-icon { transition: color var(--ax-theme-transition); }` — single-property, leave as-is.
- Line 1846: `.ax-attention-row { transition: background var(--ax-dur-1) var(--ax-ease-out); }` — already uses atoms directly, not a legacy alias; leave as-is per D-14.

### DSY-02 Token Bypasses (confirmed complete)

Sole remaining bypass:
- **`accrue_admin/lib/accrue_admin/components/dunning_banner.ex`, line 27:** `style="background-color: var(--ax-danger-surface, #fef2f2); color: var(--ax-danger-readable, #991b1b); padding: var(--ax-space-md, 1rem); text-align: center; border-bottom: 1px solid var(--ax-danger-border, #fecaca); font-weight: 500;"`

The existing classes `ax-banner ax-banner-danger` on the same element (line 26) already supply all necessary styling via `app.css` lines 1738–1749. The `style=` attribute is pure redundancy with hex fallbacks. Remove it; the classes provide identical styling.

**Confirmed no other `style=` attributes** in `accrue_admin/lib/` outside of `dunning_banner.ex`. No invoice live view inline styles found.

### Component Variant Truth (confirmed from source files)

**Button** (`accrue_admin/lib/accrue_admin/components/button.ex`):
```
button_variant_class("secondary") → "ax-button-secondary"
button_variant_class("ghost")     → "ax-button-ghost"
button_variant_class("danger")    → "ax-button-danger"
button_variant_class(_)           → "ax-button-primary"  (default)
```
Variants for registry: `primary`, `secondary`, `ghost`, `danger` (4 variants; `danger` is implemented but not shown in the kitchen today — registry must include it).

**StatusBadge** (`accrue_admin/lib/accrue_admin/components/status_badge.ex`):
The CSS variant axis is **tone**, not status atom. The `status_tone/1` function maps many statuses to 5 tones:
```
moss   ← :paid, :active, :succeeded, :success, :ok
cobalt ← :draft, :processing, :info, :queued, :refunded, :trialing
amber  ← :past_due, :warning, :grace_period, :retrying, :requires_action
slate  ← :canceled, :neutral, :archived, :void
ink    ← all others (default)
```
CSS variants: `ax-status-badge-moss`, `ax-status-badge-cobalt`, `ax-status-badge-amber`, `ax-status-badge-slate`, `ax-status-badge-ink` (5 variants).
Registry enumerates by **tone** (the CSS variant axis), one representative status per tone.

**KpiCard** (`accrue_admin/lib/accrue_admin/components/kpi_card.ex`):
The card itself has no variant parameter — it's always `ax-card ax-kpi-card`. The **delta tone** is the variant axis: `normalize_tone/1` accepts `moss | cobalt | amber | slate | ink` (as string or atom). This produces `ax-kpi-delta-{tone}`. The `card` family in the registry should enumerate: (1) the base `ax-card` class, (2) the 5 delta tones.

**Registry completeness requirement:** D-21 says "adding a 5th variant without a registry entry must fail CI." The executor must enumerate ALL known variants from each component.

### Token Gap Completeness: theme.css

Confirmed by reading `theme.css`: there are NO existing `line-height`, `letter-spacing`, `--ax-measure`, or `--ax-transition-*` tokens. The new token blocks are entirely additive — no collision or override risk.

Existing motion token atoms that the new bundles compose from (confirmed in `theme.css`):
- Durations: `--ax-dur-instant` (0ms), `--ax-dur-1` (120ms), `--ax-dur-2` (180ms), `--ax-dur-3` (240ms), `--ax-dur-exit` (140ms)
- Easings: `--ax-ease-out`, `--ax-ease-in`, `--ax-ease-inout`, `--ax-ease-emphasis`
- Back-compat aliases (freeze, do not extend): `--ax-motion-fast`, `--ax-motion-standard`, `--ax-theme-transition`

---

## The Token-Bypass Grep Guard and Its Negative-Test Coupling (D-04)

### The Guard Script

**File:** `scripts/ci/verify_package_docs.sh` [VERIFIED: read directly]

This is the project's "package docs verifier" — a bash script that uses `require_fixed`, `require_regex`, and `require_absent_regex` functions to pin invariants across documentation files.

**Important:** The current `verify_package_docs.sh` contains **no** CSS-token or breakpoint needles. It enforces documentation invariants only. The "token-bypass grep guard" referenced in D-04 and CONTEXT.md canonical refs is a **new needle to add to this script**, not an existing one.

The planner must design:
1. A `require_absent_regex` call on `accrue_admin/assets/css/app.css` that fails if any `@media` contains a bare `min-width:` or `max-width:` breakpoint value that is NOT one of the registered values AND is NOT accompanied by an `--ax-bp-*` comment.
2. The corresponding negative test in `PackageDocsVerifierTest` (`accrue/test/accrue/docs/package_docs_verifier_test.exs`) that:
   - Calls `seed_tmp_dir!` to create a temp repo snapshot
   - Introduces a drifted `app.css` with an unregistered breakpoint (e.g., `@media (min-width: 900px)`)
   - Asserts the verifier script fails with the expected needle message

**The `seed_tmp_dir!` coupling rule (from project memory / CONTEXT.md D-04):**
The `seed_tmp_dir!` private function in `PackageDocsVerifierTest` copies a set of files into a temp dir for negative tests. If the new guard needle checks `accrue_admin/assets/css/app.css`, then `app.css` must be added to the `copy_fixture!` list in `seed_tmp_dir!` — otherwise the negative tests that verify failure will fail for the wrong reason (file missing vs. pattern match).

**Files to modify for D-04:**
1. `scripts/ci/verify_package_docs.sh` — add `require_absent_regex` for unguarded breakpoints
2. `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add `copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)` to `seed_tmp_dir!` + add a new negative test case

**Grep pattern for the guard (suggested):**
The guard should find bare `@media (min-width: Npx)` or `@media (max-width: Npx)` in `app.css` where the pixel value is not in the registered set AND the line has no `--ax-bp-` comment. A multi-step approach:
- After the migration, all breakpoint `@media` in `app.css` carry an `--ax-bp-*` comment.
- The guard can be: `grep -E '@media \((min|max)-width: [0-9.]+px\)' app.css | grep -v '\-\-ax-bp-'` must return empty.

This is simpler than checking exact values — it checks that every breakpoint `@media` has the annotation, which is exactly what D-02 requires.

---

## Build / Commit Flow (Confirmed)

**Command:** `cd accrue_admin && mix accrue_admin.assets.build`

**What it does** (from `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`):
1. Runs `npx tailwindcss@3.4.17 --config assets/tailwind.config.js --input assets/css/app.css --output priv/static/accrue_admin.css --minify`
2. Runs `npx esbuild@0.25.3 assets/js/app.js --bundle --format=esm --minify --outfile=priv/static/accrue_admin.js`
3. No PostCSS pipeline. No `postcss.config.js`. Zero new build deps needed.

**Committed bundle:** `priv/static/accrue_admin.css` (+ `.js`) must be committed after every CSS/JS edit. Host apps consume this bundle — they do not run Tailwind themselves.

**What confirms it worked:** After rebuild, `priv/static/accrue_admin.css` will contain the minified output with `var(--ax-leading-tight)` etc. in place of the former literals. A grep on the minified bundle for bare `line-height:1.2` should return zero results.

---

## Common Pitfalls

### Pitfall 1: Migrating `.ax-body` line-height from 1.5 to `--ax-leading-relaxed` globally
**What goes wrong:** D-09 says keep body at 1.4, not 1.5 globally. The `.ax-body` class currently uses `line-height: 1.5` (line 396). Per D-07, `--ax-leading-relaxed` is 1.5 and is CORRECT for `.ax-body` (genuine reading region). But do not introduce `--ax-leading-relaxed` to dense admin classes like form labels, filter chips, or tabs that currently have 1.4 — those correctly use `--ax-leading-normal`.
**How to avoid:** Map by current literal value: `1.2 → tight`, `1.4 → normal`, `1.5 → relaxed`. No semantic re-evaluation needed.

### Pitfall 2: Forgetting that `--ax-transition-*` bundles must NOT include `background` shorthand
**What goes wrong:** The skeleton shimmer uses `background-position` animation (line 2250). If a transition bundle uses `background` (the shorthand), the shorthand captures `background-position` and the shimmer animation will be suppressed when prefers-reduced-motion is NOT active.
**How to avoid:** Always use `background-color` in bundle definitions (D-13). The shorthand `background` captures `background-position`, `background-size`, etc.

### Pitfall 3: Rebuilding bundle but not committing `priv/static`
**What goes wrong:** Host apps consume the committed `priv/static/accrue_admin.css`. If it is not committed, no one sees the changes. CI may not fail if tests run against the source CSS, not the committed bundle.
**How to avoid:** Each wave that modifies CSS ends with `mix accrue_admin.assets.build` and `git add priv/static/accrue_admin.css`. Make this an explicit step in every CSS-touching task.

### Pitfall 4: The `seed_tmp_dir!` coupling for the new breakpoint guard needle
**What goes wrong:** If `app.css` is not added to `seed_tmp_dir!` in `package_docs_verifier_test.exs`, the negative test that verifies the guard detects a drifted breakpoint will fail because the file is missing from the temp directory (the script will error on the missing file, not on the pattern match). This makes the negative test pass for the wrong reason — or it may fail with a confusing error.
**How to avoid:** Add `copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)` to `seed_tmp_dir!` at the same time as adding the guard needle to the script.
**Warning signs:** If the negative test's `output =~ "[verify_package_docs]"` assertion passes but `status != 0` is also true because the file is missing (not because the pattern failed), the test gives false confidence.

### Pitfall 5: ComponentRegistry variant set mismatch with CSS
**What goes wrong:** The `ComponentRegistryTest` asserts `ax_class` strings match component outputs. If a registry entry lists `ax-button-primary` but the component wraps it in `["ax-button", "ax-button-primary", nil]` (Elixir list form), the HTML output will have `class="ax-button ax-button-primary"` — the assertion must compare the full class string including the `ax-button` base class.
**How to avoid:** The test helper that extracts classes from rendered HTML must normalize the class attribute (join list, strip nils, collapse whitespace) before comparing to the registry's `ax_class` string.

### Pitfall 6: `Button` variant `danger` not in the current kitchen render
**What goes wrong:** The current `component_kitchen_live.ex` renders `primary`, `secondary`, `ghost` but NOT `danger`. The `button_variant_class/1` clause for `"danger"` exists in the component. The registry must include `danger` or D-21 drift detection is incomplete.
**How to avoid:** The executor must enumerate ALL clauses in `button_variant_class/1` (primary, secondary, ghost, danger) when populating the registry.

---

## Code Examples

### Consuming utility class for `--ax-measure` (D-07, `app.css`)
```css
/* Source: decided in CONTEXT.md D-07; placement in app.css TBD by planner */
.ax-measure {
  max-width: var(--ax-measure);
}
```

### Dunning banner after DSY-02 fix
Before (dunning_banner.ex line 26–27):
```elixir
<div
  class="accrue-default-dunning-banner ax-banner ax-banner-danger"
  style="background-color: var(--ax-danger-surface, #fef2f2); color: var(--ax-danger-readable, #991b1b); padding: var(--ax-space-md, 1rem); text-align: center; border-bottom: 1px solid var(--ax-danger-border, #fecaca); font-weight: 500;"
>
```

After (remove the `style=` attribute entirely):
```elixir
<div class="accrue-default-dunning-banner ax-banner ax-banner-danger">
```

The `.ax-banner` and `.ax-banner-danger` classes in `app.css` (lines 1738–1749) already supply all styling via `--ax-danger-surface`, `--ax-danger-readable`, `--ax-danger-border`, and `--ax-space-md` tokens.

### Transition block collapse example (line 270)
Before:
```css
.ax-sidebar-link,
.ax-card,
.ax-theme-button,
.ax-icon-button,
.ax-topbar-brand-chip {
  border: 1px solid var(--ax-border);
  transition:
    border-color var(--ax-theme-transition),
    background var(--ax-theme-transition),
    color var(--ax-theme-transition),
    transform var(--ax-theme-transition);
}
```

After:
```css
.ax-sidebar-link,
.ax-card,
.ax-theme-button,
.ax-icon-button,
.ax-topbar-brand-chip {
  border: 1px solid var(--ax-border);
  transition: var(--ax-transition-base);
}
```

Note: The `background` shorthand in the original must become `background-color` in the new bundle definition. The visual result is identical (no background-position or background-image animation in these elements).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js / npx | `mix accrue_admin.assets.build` | ✓ (project already builds) | — | — |
| tailwindcss@3.4.17 | CSS build | ✓ (pinned in task) | 3.4.17 | — |
| esbuild@0.25.3 | JS build | ✓ (pinned in task) | 0.25.3 | — |
| ExUnit | ComponentRegistryTest | ✓ (Elixir stdlib) | — | — |
| Phoenix.LiveViewTest | ComponentRegistryTest | ✓ (already in test helpers) | — | — |

No missing dependencies. Zero new installs required.

---

## Validation Architecture

Nyquist validation is ENABLED (`workflow.nyquist_validation: true` in `.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `accrue_admin/test/test_helper.exs` |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs` |
| Full suite command | `cd accrue_admin && mix test --seed 0` |
| Token guard script | `bash scripts/ci/verify_package_docs.sh` (with new needle after D-04) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DSY-01 (line-height) | No bare `line-height: 1.2/1.4/1.5` literal remains in `app.css` | grep-guard (shell) | `grep -E 'line-height: [0-9]\.[0-9]' accrue_admin/assets/css/app.css` must return 0 hits | ❌ Wave 0 |
| DSY-01 (letter-spacing) | No bare `letter-spacing: [value]em` literal remains in `app.css` | grep-guard (shell) | `grep -E 'letter-spacing: -?[0-9.]+em' accrue_admin/assets/css/app.css` must return 0 hits | ❌ Wave 0 |
| DSY-01 (breakpoints) | Every breakpoint `@media` in `app.css` carries an `--ax-bp-*` comment | grep-guard (shell) + verify_package_docs.sh | `grep -E '@media \((min\|max)-width: [0-9.]+px\)' app.css | grep -v '\-\-ax-bp-'` must return 0 hits | ❌ Wave 1 (needle + test added to verify_package_docs.sh + PackageDocsVerifierTest) |
| DSY-01 (transitions) | Multi-line `transition:` blocks collapse to `var(--ax-transition-*)` | visual + grep (shell) | `grep -c 'transition:' accrue_admin/assets/css/app.css` drops from 8 to expected count (single-property sites remain) | ❌ Wave 1 |
| DSY-02 | `dunning_banner.ex` renders with no inline `style=` attribute | unit test | `cd accrue_admin && mix test test/accrue_admin/components/dunning_banner_test.exs` (add refute for `style=`) | ✅ exists; ❌ needs `refute html =~ "style="` assertion added |
| DSY-02 | No `style=` attributes remain in `accrue_admin/lib/` render paths | grep-guard (shell) | `grep -rn 'style=' accrue_admin/lib/ | grep -v '/deps/'` must return 0 hits | ❌ Wave 1 (post-fix verification) |
| DSY-03 (render) | Every registry variant appears in the `/dev/components` page render | unit test | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs` | ❌ Wave 2 |
| DSY-03 (drift) | Registry `ax_class` set exactly matches component class outputs | unit test | Same command (part b of ComponentRegistryTest) | ❌ Wave 2 |

### Sampling Rate

- **Per task commit:** Run the specific test file(s) touched in that task + the relevant grep-guard command.
- **Per wave merge:** `cd accrue_admin && mix test --seed 0` (full suite, dodges flaky PdfTest).
- **Phase gate:** Full suite green + `bash scripts/ci/verify_package_docs.sh` passes before `/gsd:verify-work`.

### Wave 0 Gaps

- [ ] `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — covers DSY-03 (render + drift)
- [ ] `accrue_admin/test/accrue_admin/dev/` — directory must be created
- [ ] `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — data module (not a test but prerequisite)
- [ ] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add new negative test case for breakpoint drift + add `app.css` to `seed_tmp_dir!`
- [ ] `scripts/ci/verify_package_docs.sh` — add `require_absent_regex` for unguarded breakpoints

**Assertion to add to existing `dunning_banner_test.exs`:**
In the `"renders the default message when dunning is active and no inner_block is given"` test, add:
```elixir
refute html =~ ~s(style=), "inline style= attribute must not appear in dunning banner (DSY-02)"
```

**Observable signal for "every literal resolved from a token":**
- `grep -E 'line-height: [0-9]\.[0-9]' accrue_admin/assets/css/app.css` returns 0 lines
- `grep -E 'letter-spacing: -?[0-9.]+em' accrue_admin/assets/css/app.css` returns 0 lines
- `grep -E '@media \((min|max)-width: [0-9.]+px\)' accrue_admin/assets/css/app.css | grep -v '\-\-ax-bp-'` returns 0 lines

---

## Runtime State Inventory

Step 2.5 SKIPPED — Phase 174 is not a rename/refactor/migration phase. No runtime state (databases, OS-registered tasks, SOPS keys, build artifacts) carries strings that this phase renames. The only artifacts touched are CSS source files and Elixir modules; the committed `priv/static/accrue_admin.css` is regenerated and recommitted.

---

## Open Questions

1. **`.ax-search-trigger` transition block (line 1446)**
   - What we know: Currently uses a 4-property block mixing `--ax-theme-transition` (3 props) and `--ax-motion-fast` (transform). D-14 says single-property sites using `--ax-motion-*` may stay as-is; the question is whether this 4-property mixed block qualifies as a "multi-line collapse target" or a "stay as-is" case.
   - What's unclear: Whether the intentional speed asymmetry (standard speed for colors, fast for transform) must be preserved or can be normalized to `var(--ax-transition-base)`.
   - Recommendation: Executor should inspect visually. If collapsing to `var(--ax-transition-base)` preserves acceptable behavior, do it. If the transform asymmetry is visually load-bearing (e.g., the search trigger has a deliberate "snappy lift"), flag it for Phase D per D-16.

2. **Guard needle scope: `app.css` only or include component `.ex` files?**
   - What we know: DSY-01 says "no hardcoded px/em for these remain in `app.css` or components."
   - What's unclear: Whether the guard script needle should also scan `*.ex` component files for inline CSS literals, or whether DSY-02's `grep -rn 'style='` covers the component surface.
   - Recommendation: The `style=` grep in DSY-02 verification covers the component render-path bypass. The `app.css` grep covers the stylesheet. These two together satisfy DSY-01 + DSY-02 without over-engineering the guard.

---

## Security Domain

`security_enforcement` is not explicitly set to `false` in config. Phase 174 makes no changes to authentication, authorization, session management, input validation, cryptography, or HTTP handlers. The changes are CSS token definitions and a dev-only LiveView page (guarded by `Mix.env() != :prod` + `fake_processor?/0`). No ASVS categories apply.

---

## Sources

### Primary (HIGH confidence — read directly from codebase)
- `accrue_admin/assets/css/theme.css` — complete file read; confirmed existing token set, motion atoms, reduced-motion block location (line 157)
- `accrue_admin/assets/css/app.css` — complete file read; confirmed all 13 line-height sites, 5 letter-spacing sites, 10 `@media` breakpoint sites, 5 transition blocks
- `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` — confirmed sole `style=` bypass at line 27 with hex fallbacks `#fef2f2`/`#991b1b`/`#fecaca`
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — confirmed existing route, imports, render structure, `fake_processor?/0` guard
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — confirmed build is Tailwind v3 CLI → esbuild, no PostCSS
- `accrue_admin/lib/accrue_admin/router.ex` — confirmed `/dev/components` route at line 89
- `accrue_admin/lib/accrue_admin/components/button.ex` — confirmed 4 variant clauses (primary/secondary/ghost/danger)
- `accrue_admin/lib/accrue_admin/components/status_badge.ex` — confirmed 5 tone mappings
- `accrue_admin/lib/accrue_admin/components/kpi_card.ex` — confirmed delta tone axis (5 tones)
- `scripts/ci/verify_package_docs.sh` — confirmed structure: `require_fixed`, `require_absent_regex`, `require_regex` helpers; no existing CSS token needles
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — confirmed `seed_tmp_dir!` pattern and `copy_fixture!` list
- `accrue_admin/test/accrue_admin/components/dunning_banner_test.exs` — confirmed test structure
- `accrue_admin/test/support/live_case.ex` — confirmed `AccrueAdmin.LiveCase` for LiveView tests
- `.planning/config.json` — confirmed `nyquist_validation: true`

### Secondary (HIGH confidence — CONTEXT.md / UI-SPEC are user-locked decisions)
- `.planning/phases/174-a-design-system-gap-closure-token-completeness/174-CONTEXT.md` — 22 locked decisions D-01..D-22
- `.planning/phases/174-a-design-system-gap-closure-token-completeness/174-UI-SPEC.md` — UI design contract with exact line-number tables
- `.planning/research/v1.51-admin-ui-depth-design.md` — authoritative milestone design source

---

## Metadata

**Confidence breakdown:**
- Ground-truth literal sites (line-height, letter-spacing, breakpoints, transitions): HIGH — confirmed by grep on actual files
- Token definitions to add: HIGH — verbatim from locked D-07/D-13 decisions
- Component variant inventory: HIGH — confirmed from component source files
- Grep guard design: MEDIUM — the exact regex for the guard script is suggested but executor may refine
- ComponentRegistryTest drift assertion: MEDIUM — pattern established from `display_components_test.exs` style; executor fills in class-extraction helper

**Research date:** 2026-06-03
**Valid until:** Stable (no external dependencies; all grounded in locked decisions and codebase reads). Re-verify only if `app.css` or component files are modified before planning is complete.
