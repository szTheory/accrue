# Phase 174: A — Design-System Gap Closure & Token Completeness - Pattern Map

**Mapped:** 2026-06-03
**Files analyzed:** 8 (2 new, 6 modified)
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/assets/css/theme.css` | config/token | transform | itself (existing motion block) | exact |
| `accrue_admin/assets/css/app.css` | config/token | transform | itself (existing `--ax-theme-transition` usage) | exact |
| `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` | component | request-response | itself (lines 1–38) | exact |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | component/liveview | request-response | itself (lines 1–179) | exact |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | utility/data | transform | `AccrueAdmin.Components.KpiCard` `normalize_tone/1` + `StatusBadge` `status_tone/1` private-clauses-as-data pattern | role-match |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/components/display_components_test.exs` (render_component) + `component_kitchen_live_test.exs` (live/2) | exact |
| `scripts/ci/verify_package_docs.sh` | utility/script | transform | itself — `require_absent_regex` helper already defined (line 37–44) | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | request-response | itself — `seed_tmp_dir!` + `copy_fixture!` + negative-test pattern (lines 32–90) | exact |

---

## Pattern Assignments

### `accrue_admin/assets/css/theme.css` (config/token, transform)

**Analog:** itself — existing motion token block (lines 52–68) and reduced-motion override block (lines 157–171)

**Insertion target — existing motion block** (lines 52–68, copy the comment + value style verbatim):
```css
/* Motion — split duration + easing tokens (enter vs exit asymmetry; one emphasis curve) */
--ax-dur-instant: 0ms;
--ax-dur-1: 120ms;   /* press, hover, micro */
--ax-dur-2: 180ms;   /* default state change / enter */
--ax-dur-3: 240ms;   /* drawer / modal enter */
--ax-dur-exit: 140ms;
--ax-ease-out: cubic-bezier(0.2, 0, 0, 1);       /* enter / default */
--ax-ease-in: cubic-bezier(0.4, 0, 1, 1);        /* exit — accelerate away */
--ax-ease-inout: cubic-bezier(0.4, 0, 0.2, 1);
--ax-ease-emphasis: cubic-bezier(0.2, 0.9, 0.3, 1.2); /* the one earned overshoot */
```

**House comment style rule:** Every block opens with `/* Category — unit clarification */` and each value ends with a `/* purpose comment */`. New token blocks follow this exactly.

**New token blocks to append inside `html.accrue-admin {}` before the `--ax-z-*` block** (verbatim from D-07 and D-13):
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

**Reduced-motion override block** (lines 157–171 — insert new bundle overrides INSIDE the existing block, after the existing overrides; the block currently ends at line 170 before closing brace):
```css
/* Reduced motion — tiered: remove travel + overshoot, keep opacity crossfades perceptible.
   This is more correct than blanket 0ms (the vestibular issue is movement, not opacity). */
@media (prefers-reduced-motion: reduce) {
  html.accrue-admin {
    --ax-rise-sm: 0px;
    --ax-rise-md: 0px;
    --ax-press-scale: 1;
    --ax-ease-emphasis: var(--ax-ease-out);
    --ax-dur-1: 0ms;
    --ax-dur-3: 0ms;
    --ax-dur-exit: 0ms;
    --ax-dur-2: 1ms;
    --ax-motion-fast: 0ms linear;
    --ax-motion-standard: 0ms linear;
    --ax-theme-transition: 0ms linear;
    /* New: bundle overrides — consumers collapse for free */
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

---

### `accrue_admin/assets/css/app.css` (config/token, transform)

**Analog:** itself — lines 1–5 (import + font-face preamble) for placement of the breakpoint block; lines 264–275 (multi-line transition block) for the collapse pattern.

**Breakpoint registry block placement:** Insert immediately after `@font-face` declarations and before `html, body { ... }` (currently around line 21). Pattern: a CSS block-comment documentation section, no functional CSS — values are documentation only.

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
```

**Inline comment annotation pattern** (applied to all 10 `@media` breakpoint sites):
```css
@media (min-width: 640px) { /* --ax-bp-content ↑ */
@media (min-width: 768px) { /* --ax-bp-md ↑ */
@media (min-width: 1024px) { /* --ax-bp-lg ↑ */
@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */
@media (max-width: 1023.98px) { /* --ax-bp-lg ↓ */
```

**Transition collapse pattern** — source: lines 264–275, existing multi-line block:
```css
/* BEFORE (source analog at lines 264–275): */
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

/* AFTER (collapse to bundle token): */
.ax-sidebar-link,
.ax-card,
.ax-theme-button,
.ax-icon-button,
.ax-topbar-brand-chip {
  border: 1px solid var(--ax-border);
  transition: var(--ax-transition-base);
}
```

**Consuming utility class for `--ax-measure`** (add near the typography utility classes):
```css
.ax-measure {
  max-width: var(--ax-measure);
}
```

**Line-height migration map** (pure 1:1, no value changes):
- `line-height: 1.2` → `line-height: var(--ax-leading-tight)` (sites: lines 228, 234, 1190)
- `line-height: 1.4` → `line-height: var(--ax-leading-normal)` (sites: lines 373, 396... wait — 396 is `.ax-body` which is 1.5, see below)
- `line-height: 1.5` → `line-height: var(--ax-leading-relaxed)` (sites: lines 396, 847)
- Refer to RESEARCH.md §Line-Height Literal Sites for all 13 exact line numbers.

**Letter-spacing migration map** (pure 1:1, no value changes):
- `letter-spacing: 0.08em` → `letter-spacing: var(--ax-tracking-caps)` (lines 114, 260)
- `letter-spacing: 0.04em` → `letter-spacing: var(--ax-tracking-wide)` (lines 389, 2221)
- `letter-spacing: -0.02em` → `letter-spacing: var(--ax-tracking-tight)` (line 2159)

---

### `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` (component, request-response)

**Analog:** itself — lines 24–28 (the `<div>` with `class=` and `style=`)

**Current state** (lines 25–28):
```elixir
<div
  class="accrue-default-dunning-banner ax-banner ax-banner-danger"
  style="background-color: var(--ax-danger-surface, #fef2f2); color: var(--ax-danger-readable, #991b1b); padding: var(--ax-space-md, 1rem); text-align: center; border-bottom: 1px solid var(--ax-danger-border, #fecaca); font-weight: 500;"
>
```

**After fix** (remove `style=` entirely; `ax-banner ax-banner-danger` in `app.css` lines 1738–1749 already provides all styling):
```elixir
<div class="accrue-default-dunning-banner ax-banner ax-banner-danger">
```

**Test assertion to add** in `accrue_admin/test/accrue_admin/components/dunning_banner_test.exs`, inside the `"renders the default message when dunning is active and no inner_block is given"` test (after line 29):
```elixir
refute html =~ ~s(style=), "inline style= attribute must not appear in dunning banner (DSY-02)"
```

---

### `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (liveview, request-response)

**Analog:** itself — existing structure (lines 1–179)

**Key structural patterns to preserve and extend:**

Module guard (line 1):
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentKitchenLive do
```

Alias block pattern (lines 6–18) — add `ComponentRegistry` alias:
```elixir
alias AccrueAdmin.Components.{
  AppShell, Breadcrumbs, Button, Detail, FlashGroup,
  Icon, KpiCard, RelatedResources, StatusBadge, Tabs
}
alias AccrueAdmin.Dev.ComponentRegistry
```

`fake_processor?/0` guard in `mount/3` (lines 24–41) — keep unchanged; the registry section renders inside the `:if={@available?}` guard.

Existing section template (lines 83–103) — variant reference rows follow the same `<section :if={@available?} class="ax-card ax-dev-stack">` shell. New section structure adds a header `<p class="ax-label">` + a registry-driven `<div>` grid:
```heex
<section :if={@available?} class="ax-card ax-dev-stack">
  <p class="ax-label">Button variants (token reference)</p>
  <div class="ax-dev-grid">
    <%= for entry <- ComponentRegistry.variants_for("button") do %>
      <div class="ax-dev-variant-row">
        <!-- light swatch -->
        <div data-ax-theme="light">
          <Button.button variant={entry.variant} type="button">
            <%= String.capitalize(entry.variant) %>
          </Button.button>
        </div>
        <!-- dark swatch -->
        <div data-ax-theme="dark" style="background: var(--ax-base);">
          <Button.button variant={entry.variant} type="button">
            <%= String.capitalize(entry.variant) %>
          </Button.button>
        </div>
        <!-- token metadata -->
        <dl class="ax-dev-token-dl">
          <dt class="ax-label"><code><%= entry.ax_class %></code></dt>
          <%= for token <- entry.tokens do %>
            <dd class="ax-body ax-dev-token"><code><%= token %></code></dd>
          <% end %>
        </dl>
      </div>
    <% end %>
  </div>
</section>
```

`assign_shell/4` private helper (lines 158–169) — unchanged, no new assigns needed for registry rows.

---

### `accrue_admin/lib/accrue_admin/dev/component_registry.ex` (utility/data, transform) — NET NEW

**Analog:** The private-function-as-data pattern from `accrue_admin/lib/accrue_admin/components/status_badge.ex` (lines 28–39) and `accrue_admin/lib/accrue_admin/components/kpi_card.ex` (lines 62–67). Both encode variant→class mappings in private clauses; the registry promotes this to a public, inspectable list of maps.

**StatusBadge source reference** (lines 28–39) — these 5 tone clauses define the 5 registry variants for the "status" family:
```elixir
defp status_tone(status) when status in [:paid, :active, :succeeded, :success, :ok], do: "moss"
defp status_tone(status) when status in [:draft, :processing, :info, :queued, :refunded, :trialing], do: "cobalt"
defp status_tone(status) when status in [:past_due, :warning, :grace_period, :retrying, :requires_action], do: "amber"
defp status_tone(status) when status in [:canceled, :neutral, :archived, :void], do: "slate"
defp status_tone(_status), do: "ink"
```

**KpiCard source reference** (lines 62–67) — defines the 5 delta tone values for the "card" family:
```elixir
defp normalize_tone(tone) when tone in ["moss", "cobalt", "amber", "slate", "ink"], do: tone
defp normalize_tone(tone) when tone in [:moss, :cobalt, :amber, :slate, :ink], do: Atom.to_string(tone)
defp normalize_tone(_tone), do: "slate"
```

**Button source reference** (lines 34–37) — defines the 4 variant clauses for the "button" family:
```elixir
defp button_variant_class("secondary"), do: "ax-button-secondary"
defp button_variant_class("ghost"), do: "ax-button-ghost"
defp button_variant_class("danger"), do: "ax-button-danger"
defp button_variant_class(_variant), do: "ax-button-primary"
```

**Module structure pattern** — pure data module, no Phoenix deps, no `use`:
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
      # Button family — 4 variants from button_variant_class/1 clauses
      %{family: "button", variant: "primary",
        ax_class: "ax-button ax-button-primary",
        tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"]},
      %{family: "button", variant: "secondary",
        ax_class: "ax-button ax-button-secondary",
        tokens: ["--ax-border", "--ax-elevated", "--ax-transition-colors"]},
      %{family: "button", variant: "ghost",
        ax_class: "ax-button ax-button-ghost",
        tokens: ["--ax-border", "--ax-elevated", "--ax-transition-colors"]},
      %{family: "button", variant: "danger",
        ax_class: "ax-button ax-button-danger",
        tokens: ["--ax-danger", "--ax-danger-readable", "--ax-transition-colors"]},
      # StatusBadge family — 5 tone variants from status_tone/1 clauses
      %{family: "status", variant: "moss",
        ax_class: "ax-status-badge ax-status-badge-moss",
        tokens: ["--ax-success", "--ax-success-readable", "--ax-elevated"]},
      # ... cobalt, amber, slate, ink (executor fills from status_tone/1 source)
      # KpiCard/card family — base + 5 delta tones from normalize_tone/1
      %{family: "card", variant: "base",
        ax_class: "ax-card ax-kpi-card",
        tokens: ["--ax-elevated", "--ax-shadow-sm", "--ax-border"]},
      # ... delta tones: moss, cobalt, amber, slate, ink (executor fills)
    ]
  end

  @doc "All entries for a given family string."
  def variants_for(family) do
    Enum.filter(entries(), &(&1.family == family))
  end
end
```

**Key constraint:** the `ax_class` field must contain the **full class string** as it appears in the rendered HTML (e.g. `"ax-button ax-button-primary"` not just `"ax-button-primary"`), because the drift test extracts the class attribute from the rendered HTML and compares the full string.

---

### `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` (test, request-response) — NET NEW

**Primary analog:** `accrue_admin/test/accrue_admin/components/display_components_test.exs` (lines 1–196) for the `render_component/2` pattern and `use ExUnit.Case, async: true` with no DB.

**Secondary analog:** `accrue_admin/test/accrue_admin/dev/component_kitchen_live_test.exs` (lines 1–15) for the `live/2` + session init + `assert html =~` pattern using `AccrueAdmin.LiveCase`.

**`render_component/2` pattern** (from `display_components_test.exs` lines 11–42):
```elixir
use ExUnit.Case, async: true
use Phoenix.Component
import Phoenix.LiveViewTest

# Simple render_component call — no DB, no sandbox, no LiveCase
html = render_component(&Button.button/1, %{variant: "primary", type: "button"})
assert html =~ "ax-button-primary"
```

**`live/2` pattern with session init** (from `component_kitchen_live_test.exs` lines 4–14):
```elixir
use AccrueAdmin.LiveCase, async: false

test "renders the shared component kitchen", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/dev/components")
  assert html =~ "Primary action"
end
```

**Target module structure:**
```elixir
defmodule AccrueAdmin.Dev.ComponentRegistryTest do
  # Part (a) — live/2 page render — needs LiveCase (DB sandbox for mount)
  # Part (b) — render_component drift test — does NOT need DB
  # Simplest approach: split into two modules or use LiveCase for both and mark async: false
  use AccrueAdmin.LiveCase, async: false

  alias AccrueAdmin.Dev.ComponentRegistry
  alias AccrueAdmin.Components.{Button, StatusBadge, KpiCard}

  # (a) Every registry variant appears in the page render
  test "every registry variant appears in the /dev/components page render", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    for %{ax_class: ax_class} <- ComponentRegistry.entries() do
      # ax_class is "ax-button ax-button-primary" — assert a distinctive substring
      [_base, variant_class] = String.split(ax_class, " ", parts: 2)
      assert html =~ variant_class,
             "registry variant #{ax_class} (#{variant_class}) not found in page render"
    end
  end

  # (b) Registry ax_class set matches Button component's known class outputs
  test "button registry ax_class set matches Button component render outputs" do
    registry_classes =
      ComponentRegistry.variants_for("button")
      |> MapSet.new(& &1.ax_class)

    # Render each variant and extract the class attribute
    component_classes =
      ["primary", "secondary", "ghost", "danger"]
      |> MapSet.new(fn variant ->
        html = render_component(&Button.button/1, %{variant: variant, type: "button",
                                                    inner_block: fn -> "x" end})
        extract_button_classes(html)
      end)

    assert registry_classes == component_classes
  end

  # Class extraction helper: pull class=" ... " from rendered HTML, normalize whitespace
  defp extract_button_classes(html) do
    case Regex.run(~r/class="([^"]+)"/, html) do
      [_, classes] -> classes |> String.split() |> Enum.join(" ")
      _ -> flunk("no class attribute found in rendered html: #{html}")
    end
  end
end
```

**Note on `render_component` with slots:** `Button.button` has a required `slot(:inner_block)`. The correct pattern for rendering with slots in `Phoenix.LiveViewTest` is the wrapping function form (used in `display_components_test.exs` lines 46–69):
```elixir
html = render_component(fn assigns ->
  ~H"""
  <Button.button variant="primary" type="button">Label</Button.button>
  """
end)
```

---

### `scripts/ci/verify_package_docs.sh` (utility/script, transform)

**Analog:** itself — `require_absent_regex` function already defined (lines 37–44), already used at lines 76 and 170.

**Existing `require_absent_regex` call pattern** (line 76):
```bash
require_absent_regex "$ROOT_DIR/accrue/guides/quickstart.md" 'defp deps'
```

**New needle to add** — detect any breakpoint `@media` in `app.css` that lacks an `--ax-bp-` comment:
```bash
# DSY-01: every breakpoint @media in app.css must carry an --ax-bp-* annotation comment.
# After the Phase 174 migration, bare min/max-width values without the comment are drift.
# Pattern: grep for breakpoint @media lines, pipe to grep -v to exclude annotated ones.
# A non-zero result means a bare breakpoint was added without a token comment.
app_css="$ROOT_DIR/accrue_admin/assets/css/app.css"
if grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" | grep -qv '\-\-ax-bp-'; then
  fail "$app_css must not have bare breakpoint @media without an --ax-bp-* annotation comment"
fi
```

**Placement:** Add after the existing require_absent_regex calls that target `accrue/guides/` files, before the `for guide in` loop. Add a section comment: `# Token bypass guards (Phase 174, DSY-01)`.

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` (test, request-response)

**Analog:** itself — existing negative-test pattern (lines 32–90) + `seed_tmp_dir!` / `copy_fixture!` private helpers (lines 241–280).

**`copy_fixture!` pattern** (line 241–244):
```elixir
defp copy_fixture!(relative_path, tmp_dir) do
  destination = Path.join(tmp_dir, relative_path)
  File.mkdir_p!(Path.dirname(destination))
  File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
end
```

**`seed_tmp_dir!` modification required** (D-04 coupling): Add `app.css` to the copy list inside `seed_tmp_dir!` (after line 272, alongside `accrue_admin/mix.exs`):
```elixir
copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)
```
Also add the directory creation: `File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/assets/css"))` in the mkdir_p! block (after line 250).

**New negative test** (follows the same shape as lines 32–60):
```elixir
test "package docs verifier rejects unguarded breakpoint @media in app.css" do
  tmp_dir =
    Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

  File.rm_rf!(tmp_dir)
  on_exit(fn -> File.rm_rf(tmp_dir) end)
  seed_tmp_dir!(tmp_dir)

  # Introduce a bare breakpoint without --ax-bp-* annotation
  drifted_css =
    tmp_dir
    |> Path.join("accrue_admin/assets/css/app.css")
    |> File.read!()
    |> Kernel.<>("\n@media (min-width: 900px) { .ax-drift { display: block; } }\n")

  File.write!(Path.join(tmp_dir, "accrue_admin/assets/css/app.css"), drifted_css)

  {output, status} =
    System.cmd("bash", [@script_path],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}]
    )

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "app.css"
  assert output =~ "--ax-bp-"
end
```

---

## Shared Patterns

### Phoenix.Component `use` declaration
**Source:** every component in `accrue_admin/lib/accrue_admin/components/`
**Apply to:** `component_registry.ex` does NOT need this (pure data, no templates). `component_kitchen_live.ex` already has `use Phoenix.LiveView`.

### Module guard for dev-only modules
**Source:** `component_kitchen_live.ex` lines 1–2
**Apply to:** `component_registry.ex` — wrap in the same `if Mix.env() != :prod do` guard, consistent with the kitchen module it serves.
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
    ...
  end
end
```

### `render_component/2` with required slots
**Source:** `display_components_test.exs` lines 46–69 (wrapping function form)
**Apply to:** `component_registry_test.exs` for Button (has required `slot(:inner_block)`)
```elixir
html = render_component(fn assigns ->
  ~H"""
  <Button.button variant="primary" type="button">Label</Button.button>
  """
end)
```

### Token house-comment style
**Source:** `theme.css` lines 16–68 — every block: `/* Category — unit/annotation */` header, inline `/* purpose */` on each value line.
**Apply to:** New token blocks in `theme.css` (D-07, D-13).

### Back-compat freeze pattern
**Source:** `theme.css` lines 65–68 — the `--ax-motion-fast`, `--ax-motion-standard`, `--ax-theme-transition` aliases are retained but frozen.
**Apply to:** Do NOT add new properties to these aliases when adding `--ax-transition-*` bundles. The pattern is: define new family; old family stays as-is (no extension, no deletion).

---

## No Analog Found

All files have strong analogs. No files require falling back to external references.

---

## Metadata

**Analog search scope:** `accrue_admin/assets/css/`, `accrue_admin/lib/accrue_admin/`, `accrue_admin/test/`, `accrue/test/accrue/docs/`, `scripts/ci/`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-06-03
