# Phase 193: Research, Re-baseline & Pattern Lock - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 13 new/modified files
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/guides/spec-overview.md` | config/doc | static | `accrue_admin/guides/motion.md` | exact |
| `accrue_admin/guides/spec-list.md` | config/doc | static | `accrue_admin/guides/motion.md` | exact |
| `accrue_admin/guides/spec-detail.md` | config/doc | static | `accrue_admin/guides/motion.md` | exact |
| `accrue_admin/mix.exs` (modify) | config | — | self (extend `extras`/`groups_for_extras`) | self |
| `accrue_admin/lib/accrue_admin/dev/storybook.ex` | config/module | — | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | role-match |
| `accrue_admin/lib/accrue_admin/router.ex` (modify) | middleware/router | request-response | self (`wrap_with_mailglass_dev_routes`) | self |
| `accrue_admin/lib/accrue_admin/assets.ex` (modify) | utility/plug | request-response | self (extend kind type + module attrs) | self |
| `storybook/_support/registry_story.ex` | utility | transform | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | role-match |
| `storybook/components/button.story.exs` | config/doc | static | (new pattern — no prior story files) | partial |
| `accrue_admin/priv/static/storybook.css` | config/asset | static | `accrue_admin/priv/static/accrue_admin.css` | role-match |
| `accrue_admin/priv/static/storybook.js` | config/asset | static | `accrue_admin/priv/static/accrue_admin.js` | role-match |
| `scripts/ci/verify_package_docs.sh` (modify) | middleware/CI | batch | self (append guards) | self |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` (modify) | test | — | self (extend `seed_tmp_dir!`) | self |
| `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` | config/data | batch | `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` | exact schema |
| `accrue_admin/e2e/spike-overlay-portal.spec.js` | test/E2E | event-driven | `accrue_admin/e2e/admin-page-flow-phase191.spec.js` | exact |

---

## Pattern Assignments

### `accrue_admin/guides/spec-overview.md`, `spec-list.md`, `spec-detail.md` (doc, static)

**Analog:** `accrue_admin/guides/motion.md`

**File structure pattern** (motion.md lines 1–30 — opening + anchor heading + enforcement section):
```markdown
# Motion & Micro-interaction Design

Accrue Admin applies restrained, purposeful, token-based motion...

## Motion Vocabulary

All new motion composes from these atoms only...

## Enforcement Guard
...
```

**Apply to each spec guide:**
- Each guide MUST have exactly one stable anchor heading matching the `require_fixed` needle pattern.
- Per D-11: `## SPEC-OVERVIEW — ` / `## SPEC-LIST — ` / `## SPEC-DETAIL — summary-then-drill`
- Structure: intro prose (persona + archetype intent) → machine-checkable invariant checklist (GOV.UK-style, with ✅/❌ rows) → prose judge-graded items (linked to 12-dim rubric dimensions).

**CI needle shape** (from `scripts/ci/verify_package_docs.sh` lines 518–519):
```bash
# Motion guide existence (Phase 177, MOT-01)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/motion.md"'
```

**Three spec guide needles follow this exact shape:**
```bash
# Archetype spec guide existence (Phase 193, RES-01)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-overview.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-list.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-detail.md"'
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-overview.md" "## SPEC-OVERVIEW — "
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-list.md" "## SPEC-LIST — "
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-detail.md" "## SPEC-DETAIL — summary-then-drill"
```

---

### `accrue_admin/mix.exs` — `docs/0` extension (config, self-modify)

**Analog:** self — current `extras`/`groups_for_extras` (lines 65–80)

**Current pattern** (lines 65–80):
```elixir
extras: [
  "README.md",
  "guides/admin_ui.md",
  "guides/local_demo.md",
  "guides/core-admin-parity.md",
  "guides/theme-exceptions.md",
  "guides/motion.md"
],
groups_for_extras: [
  Guides: [
    "guides/admin_ui.md",
    "guides/local_demo.md",
    "guides/core-admin-parity.md",
    "guides/theme-exceptions.md",
    "guides/motion.md"
  ]
],
```

**Change: append to BOTH `extras` and `Guides:`** (after `"guides/motion.md"` in both lists):
```elixir
"guides/spec-overview.md",
"guides/spec-list.md",
"guides/spec-detail.md",
```

**Dep addition** (in `deps/0`, alongside other `only: [:dev, :test]` deps):
```elixir
{:phoenix_storybook, "~> 1.2", only: [:dev, :test]},
```

**`elixirc_paths` extension** (open question O-3 from RESEARCH.md — required for `storybook/_support/`):
```elixir
defp elixirc_paths(:dev), do: ["lib", "storybook/_support"]
defp elixirc_paths(:test), do: ["lib", "storybook/_support", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

---

### `accrue_admin/lib/accrue_admin/dev/storybook.ex` (config module, dev/test-only)

**Analog:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex` (lines 1–2)

**Guard pattern** (component_registry.ex line 1):
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
    @moduledoc false
    ...
  end
end
```

**Apply the same `if Mix.env() != :prod do` outer wrapper.** Inside, `use PhoenixStorybook` with backend config:
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.Storybook do
    use PhoenixStorybook,
      otp_app: :accrue_admin,
      content_path: Path.expand("../../../../storybook", __DIR__),
      css_path: "/dev/storybook/assets/storybook-css-#{AccrueAdmin.Assets.storybook_css_hash()}",
      js_path: "/dev/storybook/assets/storybook-js-#{AccrueAdmin.Assets.storybook_js_hash()}",
      sandbox_class: "accrue-admin",
      color_mode_sandbox_dark_class: "ax-theme-dark-shim"
  end
end
```

Note: the `css_path` and `js_path` values must match the hashed routes registered in `AccrueAdmin.Assets`. The mount_path prefix (`/dev/storybook`) must match the `live_storybook` call in the router.

---

### `accrue_admin/lib/accrue_admin/router.ex` — Storybook wrap (middleware, self-modify)

**Analog:** self — `wrap_with_mailglass_dev_routes` (lines 107–138)

**Exact Mailglass pattern to replicate** (lines 107–138):
```elixir
    |> wrap_with_mailglass_dev_routes(dev_routes?, mount_path)
```

```elixir
  defp wrap_with_mailglass_dev_routes(base_ast, true, mount_path) do
    dev_ast =
      quote bind_quoted: [mount_path: mount_path] do
        scope mount_path do
          pipe_through(:accrue_admin_browser)
          import Phoenix.LiveView.Router
          import MailglassAdmin.Router
          mailglass_admin_routes("/dev/mail")
        end
      end

    quote do
      unquote(base_ast)
      unquote(dev_ast)
    end
  end

  defp wrap_with_mailglass_dev_routes(base_ast, _dev_routes?, _mount_path), do: base_ast
```

**Storybook wrap — chain after line 107, add `Code.ensure_loaded?` guard:**
```elixir
    |> wrap_with_mailglass_dev_routes(dev_routes?, mount_path)
    |> wrap_with_storybook_dev_routes(dev_routes?, mount_path)
```

```elixir
  # PhoenixStorybook component lab (Phase 193, D-13 / STY-01).
  #
  # Mounted as a SIBLING scope (same pattern as Mailglass above).
  #
  # MANDATORY: `Code.ensure_loaded?(PhoenixStorybook.Router)` guard is required here
  # (unlike Mailglass). phoenix_storybook is `only: [:dev, :test]` and is NOT available
  # to host apps' :dev compile. A bare `import PhoenixStorybook.Router` at compile time
  # on a host that has never run `mix deps.get` for accrue_admin's dev deps will fail.
  defp wrap_with_storybook_dev_routes(base_ast, true, mount_path) do
    if Code.ensure_loaded?(PhoenixStorybook.Router) do
      dev_ast =
        quote bind_quoted: [mount_path: mount_path] do
          scope mount_path do
            pipe_through(:accrue_admin_browser)
            import PhoenixStorybook.Router
            live_storybook("/dev/storybook",
              backend_module: AccrueAdmin.Dev.Storybook
            )
          end
        end

      quote do
        unquote(base_ast)
        unquote(dev_ast)
      end
    else
      base_ast
    end
  end

  defp wrap_with_storybook_dev_routes(base_ast, _dev_routes?, _mount_path), do: base_ast
```

---

### `accrue_admin/lib/accrue_admin/assets.ex` — Storybook kind extension (utility/plug, self-modify)

**Analog:** self — full file (lines 1–101)

**Current `@type kind` and guard** (lines 37, 40, 43, 66):
```elixir
@type kind :: :brand | :css | :js | :font_sans | :font_mono

def init(kind) when kind in [:brand, :css, :js, :font_sans, :font_mono], do: kind

def call(conn, kind) when kind in [:brand, :css, :js, :font_sans, :font_mono] do

def hashed_path(kind, mount_path) when kind in [:brand, :css, :js] and is_binary(mount_path) do
```

**New module attribute block** (add after line 32, following the existing pattern exactly):
```elixir
@storybook_css_file Application.app_dir(:accrue_admin, "priv/static/storybook.css")
@storybook_js_file  Application.app_dir(:accrue_admin, "priv/static/storybook.js")

@external_resource @storybook_css_file
@external_resource @storybook_js_file

@storybook_css_body File.read!(@storybook_css_file)
@storybook_js_body  File.read!(@storybook_js_file)

@storybook_css_hash :md5 |> :crypto.hash(@storybook_css_body) |> Base.encode16(case: :lower)
@storybook_js_hash  :md5 |> :crypto.hash(@storybook_js_body) |> Base.encode16(case: :lower)
```

**Type extension:** change `@type kind` to include `:storybook_css | :storybook_js`.

**New public functions** (same shape as `css_hash/0`, `js_hash/0`):
```elixir
@spec storybook_css_hash() :: String.t()
def storybook_css_hash, do: @storybook_css_hash

@spec storybook_js_hash() :: String.t()
def storybook_js_hash, do: @storybook_js_hash
```

**`hashed_path/2` extension** (add new clause after the `:brand/:css/:js` clause):
```elixir
def hashed_path(kind, mount_path)
    when kind in [:storybook_css, :storybook_js] and is_binary(mount_path) do
  normalized_mount = normalize_mount_path(mount_path)

  suffix =
    case kind do
      :storybook_css -> "storybook-css-#{@storybook_css_hash}"
      :storybook_js  -> "storybook-js-#{@storybook_js_hash}"
    end

  normalized_mount <> "/assets/" <> suffix
end
```

**`asset/1` extension** (add clauses after existing ones):
```elixir
def asset(:storybook_css), do: {@storybook_css_body, "text/css", @storybook_css_hash}
def asset(:storybook_js),  do: {@storybook_js_body, "application/javascript", @storybook_js_hash}
```

---

### `storybook/_support/registry_story.ex` (utility, transform)

**Analog:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex`

**Guard pattern:** use the same `if Mix.env() != :prod do` outer wrapper (registry.ex line 1). File is a compiled `.ex` (not `.exs`) located at `storybook/_support/` — included in `elixirc_paths(:dev)` and `elixirc_paths(:test)`, NOT under `lib/`, NOT in published Hex tarball.

**Module structure:**
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.RegistryStory do
    @moduledoc false

    alias PhoenixStorybook.Story.Variation

    @doc """
    Generates a list of `%Variation{}` structs from `ComponentRegistry.variants_for/1`.

    Each specimen in the registry entry becomes one Variation. Used by .story.exs
    shims to avoid duplicating variant data that the registry already encodes.
    """
    @spec variations_for(String.t()) :: [Variation.t()]
    def variations_for(family) do
      AccrueAdmin.Dev.ComponentRegistry.variants_for(family)
      |> Enum.flat_map(fn entry ->
        specimens = entry[:specimens] || [%{label: entry[:variant], props: %{}, content: nil}]
        Enum.map(specimens, fn specimen ->
          %Variation{
            id: String.to_atom("#{entry[:variant]}_#{specimen[:label]}"),
            attributes: specimen[:props],
            slots: if(specimen[:content], do: [specimen[:content]], else: []),
            description: specimen[:label]
          }
        end)
      end)
    end
  end
end
```

---

### `storybook/components/button.story.exs` (doc/config, static)

**No prior analog in codebase.** Use PhoenixStorybook's standard story shape.

**Pattern from RESEARCH.md:**
```elixir
defmodule AccrueAdmin.Storybook.Components.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &AccrueAdmin.Components.Core.button/1

  def variations do
    AccrueAdmin.Storybook.RegistryStory.variations_for("button")
  end
end
```

Key: the `.story.exs` is minimal — it delegates to the compiled `RegistryStory` module. Do NOT inline `ComponentRegistry` calls in the `.exs` file (Pitfall 5 from RESEARCH.md).

---

### `scripts/ci/verify_package_docs.sh` — new guards (CI, self-modify)

**Analog:** self — existing `require_fixed` / `require_absent_regex` / perl multiline guards

**Exact function shapes confirmed** (lines 23–57):
```bash
require_fixed() {
  local file=$1
  local needle=$2
  grep -Fq -- "$needle" "$file" || fail "$file is missing: $needle"
}

require_absent_regex() {
  local file=$1
  local pattern=$2
  if grep -Eq -- "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}
```

**Existing motion guard shape for reference** (lines 501–519 — append-after site for new guards):
```bash
# Motion antipattern guards (Phase 177, MOT-01)
grep -qE 'transition:\s*all\b' "$app_css" && \
  fail "$app_css must not use 'transition: all' (MOT-01/A1)..."
...
# Motion guide existence (Phase 177, MOT-01)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/motion.md"'
```

**Three new guards to append (RES-04):**
```bash
# Phase 193 CSS source guards (RES-04)

# Guard A — Spacing-literal ban
spacing_literal_hit=$(
  perl -0ne '
    while (/([^\n]+)\n/g) {
      my $line = $1;
      next if $line =~ /\/\*/;
      next if $line =~ /ax-spacing-exception:/;
      if ($line =~ /\b(padding|margin|gap)\s*:[^;]*\b\d+px\b/ && $line !~ /var\(--ax-/) {
        print "$line\n";
        last;
      }
    }
  ' "$app_css" || true
)
[[ -z "$spacing_literal_hit" ]] || fail "$app_css must not use raw px spacing outside --ax-space-* tokens (RES-04 spacing-literal guard)"

# Guard B — :focus-visible enforcement
focus_ring_hit=$(grep -En ':focus[^-]' "$app_css" | grep -v ':focus-visible' | head -n 1 || true)
[[ -z "$focus_ring_hit" ]] || fail "$app_css contains :focus selector without :focus-visible (RES-04 focus-visible guard)"

# Guard C — Truncation without min-width:0
truncation_hit=$(
  perl -0ne '
    while (/\{([^}]*text-overflow\s*:\s*ellipsis[^}]*)\}/gs) {
      my $block = $1;
      unless ($block =~ /min-width\s*:\s*0/) {
        print "found truncation without min-width:0\n";
        last;
      }
    }
  ' "$app_css" || true
)
[[ -z "$truncation_hit" ]] || fail "$app_css has truncation without min-width:0 in same block (RES-04 truncation guard)"

# Archetype spec guide existence (Phase 193, RES-01)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-overview.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-list.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-detail.md"'
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-overview.md" "## SPEC-OVERVIEW — "
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-list.md" "## SPEC-LIST — "
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-detail.md" "## SPEC-DETAIL — summary-then-drill"
```

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` — `seed_tmp_dir!` extension (test, self-modify)

**Analog:** self — `seed_tmp_dir!` (lines 665–712)

**Existing motion.md pattern** (line 703):
```elixir
copy_fixture!("accrue_admin/guides/motion.md", tmp_dir)
```

**New `copy_fixture!` calls to add** (after line 703, same block):
```elixir
copy_fixture!("accrue_admin/guides/spec-overview.md", tmp_dir)
copy_fixture!("accrue_admin/guides/spec-list.md", tmp_dir)
copy_fixture!("accrue_admin/guides/spec-detail.md", tmp_dir)
```

Note: `accrue_admin/mix.exs` is already copied at line 695 — once the real mix.exs gains the spec extras, `seed_tmp_dir!` picks them up automatically. Only the three new guide files need explicit `copy_fixture!` entries.

**New negative test cases** for the three CSS guards (add after existing MOT-01 negative tests, same structure as existing guard tests):
```elixir
test "package docs verifier rejects raw px spacing (RES-04 spacing-literal guard)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)
  File.write!(Path.join(tmp_dir, "accrue_admin/assets/css/app.css"),
    ".foo { padding: 16px; }")
  assert_script_fails(tmp_dir, ~r/spacing-literal guard/)
end

test "package docs verifier rejects :focus without :focus-visible (RES-04)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)
  File.write!(Path.join(tmp_dir, "accrue_admin/assets/css/app.css"),
    ".foo:focus { outline: 2px solid red; }")
  assert_script_fails(tmp_dir, ~r/focus-visible guard/)
end

test "package docs verifier rejects truncation without min-width:0 (RES-04)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)
  File.write!(Path.join(tmp_dir, "accrue_admin/assets/css/app.css"),
    ".foo { overflow: hidden; text-overflow: ellipsis; }")
  assert_script_fails(tmp_dir, ~r/truncation without min-width/)
end
```

---

### `accrue_admin/e2e/spike-overlay-portal.spec.js` (test/E2E, event-driven)

**Analog:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js` + `accrue_admin/e2e/phase191-page-flow-helpers.js`

**Confirmed helper imports** (from RESEARCH.md — phase191-page-flow-helpers.js):
```javascript
import {
  assertTopPointerTarget,
  assertScrollReachable,
  assertNoHorizontalClip,
  assertFocusWithin,
  assertNoBodyFocus,
  setPhase191Theme
} from './phase191-page-flow-helpers.js';
```

**`setPhase191Theme(page, theme)` confirmed** — sets `document.documentElement.setAttribute("data-theme", value)` and localStorage.

**Spike spec structure** (four D-05 proofs as distinct test blocks):
```javascript
import { test, expect } from '@playwright/test';
import { assertTopPointerTarget, assertFocusWithin } from './phase191-page-flow-helpers.js';

/* D-05 recorded decision: portal primary (A) — spike-overlay-portal.spec.js
   Four proofs required per CONTEXT.md D-05; all must be green before Phase 193 merge. */

test.describe('D-05 overlay portal spike', () => {
  test('proof 1 — primary action is hit-testable above scrim', async ({ page }) => { ... });
  test('proof 2 — portal survives LiveView navigation without orphan', async ({ page }) => { ... });
  test('proof 3 — body scroll locked without scrollbar-gutter jump', async ({ page }) => { ... });
  test('proof 4 — portal escapes transformed ancestor', async ({ page }) => { ... });
});
```

---

### `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` (data, batch)

**Analog:** `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json`

**Confirmed cell schema:**
```json
{
  "cell_id": "p193__dashboard__chromium-desktop__light__default-populated__d01",
  "surface": "dashboard",
  "surface_type": "page-flow",
  "mode": "chromium-desktop",
  "viewport_width": 1280,
  "theme": "light",
  "state": "default-populated",
  "dimension": "d01",
  "dimension_name": "Information hierarchy",
  "score": null,
  "coverage_status": "pending",
  "evidence_refs": [],
  "notes": "",
  "targeted_label": "dashboard page-flow d01",
  "breakpoint": "desktop"
}
```

Key differences from component cells:
- `surface_type` is `"page-flow"` (not `"component"` or `"group"`)
- `surface` is a route slug (e.g. `"dashboard"`, `"subscriptions-list"`, `"subscription-detail"`)
- `cell_id` prefix is `p193` for Phase 193 cells

---

## Shared Patterns

### `if Mix.env() != :prod do` guard
**Source:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex` line 1
**Apply to:** `accrue_admin/lib/accrue_admin/dev/storybook.ex`, `storybook/_support/registry_story.ex`
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.Storybook do
    ...
  end
end
```

### Sibling-scope router wrap (quote AST chaining)
**Source:** `accrue_admin/lib/accrue_admin/router.ex` lines 121–138
**Apply to:** `wrap_with_storybook_dev_routes/3` (new function)

The canonical shape is:
1. `defp wrap_with_X(base_ast, true, mount_path)` builds a `dev_ast` in `quote bind_quoted:`
2. Returns `quote do: unquote(base_ast); unquote(dev_ast)` — siblings, not nested
3. `defp wrap_with_X(base_ast, _dev_routes?, _mount_path), do: base_ast` is the no-op fallback
4. `import X.Router` is INSIDE the `quote bind_quoted:` block, NEVER at module top-level

### Committed-bundle asset serving
**Source:** `accrue_admin/lib/accrue_admin/assets.ex` lines 10–32
**Apply to:** Storybook CSS/JS kind additions in `assets.ex`

The canonical shape per asset:
1. `@file_attr Application.app_dir(:accrue_admin, "priv/static/filename")`
2. `@external_resource @file_attr`
3. `@body_attr File.read!(@file_attr)`
4. `@hash_attr :md5 |> :crypto.hash(@body_attr) |> Base.encode16(case: :lower)`
5. Public `def X_hash, do: @X_hash`
6. `asset(:X)` clause returning `{@body, content_type, @hash}`

### `require_fixed` + `seed_tmp_dir!` needle coupling
**Source:** `scripts/ci/verify_package_docs.sh` line 519 + `package_docs_verifier_test.exs` line 703
**Apply to:** All three spec guide needles + three CSS guard needles

Every `require_fixed "$ROOT_DIR/accrue_admin/guides/X.md"` needle MUST have a corresponding `copy_fixture!("accrue_admin/guides/X.md", tmp_dir)` in `seed_tmp_dir!`. These must be committed atomically (same commit).

### ExDoc extras + groups_for_extras sync
**Source:** `accrue_admin/mix.exs` lines 65–80
**Apply to:** Three spec guide additions

Every path added to `extras` MUST also be added to the same group in `groups_for_extras`. Adding to only one list causes guides to appear under "Pages" instead of "Guides" in ExDoc.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `storybook/components/button.story.exs` | doc | static | First `.story.exs` in the codebase; PhoenixStorybook story format has no prior in-repo precedent — use PhoenixStorybook docs + RESEARCH.md Spike D pattern |

---

## Metadata

**Analog search scope:** `accrue_admin/lib/`, `accrue_admin/guides/`, `accrue_admin/e2e/`, `scripts/ci/`, `accrue/test/accrue/docs/`, `.planning/milestones/v1.53-phases/187-audit-baseline/`
**Files scanned:** 13 canonical analog files
**Pattern extraction date:** 2026-06-25
