# Phase 188: Foundations hardening - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/assets/css/theme.css` | config | transform | `accrue_admin/assets/css/theme.css` | exact |
| `accrue_admin/assets/css/app.css` | component | transform | `accrue_admin/assets/css/app.css` | exact |
| `accrue_admin/assets/tailwind.config.js` | config | transform | `accrue_admin/assets/tailwind.config.js` | exact-delete |
| `accrue_admin/assets/tailwind_preset.js` | config | transform | `accrue_admin/assets/tailwind_preset.js` | exact-delete |
| `accrue_admin/lib/accrue_admin/components/button.ex` | component | render | `accrue_admin/lib/accrue_admin/components/button.ex` | exact |
| `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` | test | render | `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` | exact |
| `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` | config | file-I/O | `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` | exact |
| `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` | test | file-I/O | `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` | exact |
| `scripts/ci/verify_package_docs.sh` | utility | batch | `scripts/ci/verify_package_docs.sh` | exact |
| `scripts/ci/verify_foundation_contrast.mjs` | utility | batch | `scripts/ci/verify_package_docs.sh` verifier helpers and `package_docs_verifier_test.exs` negative fixtures | role-match |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | batch | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | exact |
| `accrue_admin/guides/admin_ui.md` | docs | transform | `accrue_admin/guides/admin_ui.md` | exact |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | config | transform | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | exact |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | exact |
| `accrue_admin/e2e/admin-a11y.spec.js` / `reduced-motion.spec.js` / new kitchen checks | test | request-response | `accrue_admin/e2e/kitchen-banner.spec.js` and `reduced-motion.spec.js` | role-match |

## Pattern Assignments

### `accrue_admin/assets/css/theme.css` (config, transform)

**Analog:** `accrue_admin/assets/css/theme.css`

**Token source-of-truth pattern** (lines 9-14):
```css
/* Bind semantic tokens to the same element that carries `data-theme` (see Layouts.root).
   Defining these only on `:root` can lose against host `:root` ordering; `html.accrue-admin`
   scopes Accrue admin surfaces deterministically. */
html.accrue-admin {
  --ax-font-sans: "Geist", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --ax-font-mono: "Geist Mono", "SFMono-Regular", "SF Mono", Consolas, "Liberation Mono", monospace;
```

**Atomic typography + measure pattern to preserve** (lines 70-80):
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

**Motion bundle pattern to reuse for all remaining motion** (lines 82-98):
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

**Current layer scale to replace** (lines 100-103):
```css
  --ax-z-topbar: 10;
  --ax-z-popover: 20;
  --ax-z-drawer: 30;
  --ax-z-modal: 40;
```

**Dark/system-dark duplication pattern** (lines 145-181):
```css
html.accrue-admin[data-theme="dark"] {
  --ax-base: #0f1318;
  --ax-elevated: #171d24;
  --ax-sunken: #0b1015;
  --ax-primary: #f4f7fa;
  --ax-focus-ring: color-mix(in oklch, var(--ax-accent) 70%, black);
  color-scheme: dark;
}

@media (prefers-color-scheme: dark) {
  html.accrue-admin[data-theme="system"] {
    --ax-base: #0f1318;
    --ax-elevated: #171d24;
    --ax-sunken: #0b1015;
    --ax-primary: #f4f7fa;
    --ax-focus-ring: color-mix(in oklch, var(--ax-accent) 70%, black);
    color-scheme: dark;
  }
}
```

**Reduced-motion override pattern** (lines 187-210):
```css
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

### `accrue_admin/assets/css/app.css` (component, transform)

**Analog:** `accrue_admin/assets/css/app.css`

**Imports and font-face allowlist pattern** (lines 1-18):
```css
@import "./theme.css";

/* Self-hosted Geist variable faces (OFL). Relative url() resolves against the
   served stylesheet at `<mount>/assets/css-<hash>`, i.e. `<mount>/assets/geist-*.woff2`,
   which AccrueAdmin.Assets serves — mount-path independent, no host wiring. */
@font-face {
  font-family: "Geist";
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;
  src: url("geist-sans-vf.woff2") format("woff2");
}
```

**Breakpoint annotation guard pattern** (lines 21-29):
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

**Current semantic type primitives to migrate to role utilities** (lines 372-406):
```css
.ax-label,
.ax-eyebrow,
.ax-sidebar-link-label,
.ax-theme-button,
.ax-icon-label {
  font-size: 0.875rem;
  font-weight: 600;
  line-height: var(--ax-leading-normal);
}

.ax-eyebrow {
  margin: 0 0 var(--ax-space-xs);
  letter-spacing: var(--ax-tracking-wide);
  text-transform: uppercase;
}

.ax-body {
  margin: 0;
  font-size: 1rem;
  line-height: var(--ax-leading-relaxed);
  overflow-wrap: anywhere;
}

.ax-measure { max-width: var(--ax-measure); }
```

**Layer consumers to migrate** (lines 408-411, 737-740, 1611-1621, 1950-2009):
```css
.ax-topbar {
  position: sticky;
  top: 0;
  z-index: 10;
}

.ax-detail-drawer-shell {
  position: fixed;
  inset: 0;
  z-index: 30;
}

.ax-dropdown-panel {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  background: var(--ax-elevated);
  box-shadow: var(--ax-shadow-sm);
  z-index: 20;
}

.ax-skip-link:focus {
  left: 1rem;
  top: 1rem;
  z-index: 20;
}

html.accrue-admin.ax-shell-nav-open .ax-sidebar {
  position: fixed;
  z-index: 40;
}
```

**Focus/disabled pattern to harden** (lines 1082-1112, 1476-1493):
```css
.ax-button,
.ax-status-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--ax-space-sm);
  width: fit-content;
  border: 1px solid transparent;
  border-radius: 999px;
  font-size: 0.875rem;
  font-weight: 600;
  line-height: var(--ax-leading-normal);
}

.ax-button:hover,
.ax-button:focus-visible {
  border-color: var(--ax-focus-ring);
  outline: none;
}

.ax-button[aria-disabled="true"],
.ax-button:disabled {
  opacity: 0.5;
  pointer-events: none;
}

.ax-input:focus-visible,
.ax-select:focus-visible,
.ax-checkbox:focus-visible {
  border-color: var(--ax-focus-ring);
  outline: none;
}
```

**Status role consumer pattern to replace color-mix one-offs** (lines 1146-1180):
```css
.ax-status-badge {
  padding: 0.4rem 0.7rem;
  transition: var(--ax-transition-colors);
}

.ax-status-badge-moss {
  background: color-mix(in srgb, var(--ax-success) 14%, var(--ax-elevated));
  color: var(--ax-success-readable);
}

.ax-status-badge-amber {
  background: color-mix(in srgb, var(--ax-warning) 18%, var(--ax-elevated));
  color: var(--ax-warning-readable);
}
```

**Motion class pattern to preserve** (lines 779-834):
```css
/* Phase 177 (v1.51 MOT-02) — Detail drawer enter/exit transition classes
   Used by detail_drawer.ex as phx-mounted/phx-remove JS.show/hide tuples.
   Enter: JS.show(transition: {"ax-drawer-entering","ax-drawer-enter-from","ax-drawer-enter-to"}, time: 240)
   Exit:  JS.hide(transition: {"ax-drawer-leaving","ax-drawer-leave-from","ax-drawer-leave-to"}, time: 140)
   All durations reference --ax-dur-* tokens; zero raw ms literals. */
.ax-drawer-entering {
  transition:
    opacity var(--ax-dur-3) var(--ax-ease-out),
    transform var(--ax-dur-3) var(--ax-ease-out);
}

.ax-drawer-leaving {
  transition: opacity var(--ax-dur-exit) var(--ax-ease-in);
}

.ax-drawer-backdrop-entering {
  transition: opacity var(--ax-dur-3) var(--ax-ease-out);
}
```

**Skeleton exception pattern** (lines 2614-2639):
```css
/* Skeleton loading primitive (reduced-motion: static, no shimmer) */
.ax-skeleton {
  display: block;
  height: 0.875rem;
  border-radius: var(--ax-radius-2xs);
  background:
    linear-gradient(
      90deg,
      var(--ax-sunken) 25%,
      color-mix(in srgb, var(--ax-sunken) 60%, var(--ax-elevated)) 50%,
      var(--ax-sunken) 75%
    );
  background-size: 200% 100%;
  animation: ax-skeleton-shimmer 1.4s var(--ax-ease-inout) infinite;
}

@media (prefers-reduced-motion: reduce) {
  .ax-skeleton {
    animation: none;
    background: var(--ax-sunken);
  }
}
```

### `accrue_admin/assets/tailwind.config.js` and `tailwind_preset.js` (config, transform)

**Analog:** same files, delete targets.

**Config being removed** (tailwind.config.js lines 1-7):
```javascript
const preset = require("./tailwind_preset");

module.exports = {
  content: ["../lib/**/*.{ex,heex}"],
  darkMode: ["variant", '&:where([data-theme="dark"], [data-theme="dark"] *, [data-theme="system"])'],
  presets: [preset]
};
```

**Preset being removed** (tailwind_preset.js lines 1-26):
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        ink: "var(--accrue-ink)",
        base: "var(--ax-base)",
        elevated: "var(--ax-elevated)",
        accent: "var(--ax-accent)",
        success: "var(--ax-success)",
        warning: "var(--ax-warning)"
      }
    }
  }
};
```

### `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` (config, file-I/O)

**Analog:** `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`

**Module and runner injection pattern** (lines 1-25):
```elixir
defmodule Mix.Tasks.AccrueAdmin.Assets.Build do
  @shortdoc "Rebuild the private AccrueAdmin asset bundle"
  @moduledoc """
  Rebuilds the package-local CSS and JS bundle committed under `priv/static/`.
  """

  use Mix.Task

  @runner_env_key :accrue_admin_assets_build_runner
  @tailwind_version "tailwindcss@3.4.17"
  @esbuild_version "esbuild@0.25.3"

  defmodule Runner do
    @moduledoc false
    @callback run(String.t(), [String.t()], keyword()) :: {:ok, integer()} | {:error, term()}
  end
```

**Run-step pattern** (lines 48-60):
```elixir
@impl Mix.Task
def run(_argv) do
  Mix.Task.run("loadpaths")

  root = File.cwd!()
  File.mkdir_p!(Path.join(root, "priv/static"))

  runner = Application.get_env(:accrue_admin, @runner_env_key, ShellRunner)

  run_step!(runner, "tailwind", "npx", tailwind_args(root), cd: root)
  run_step!(runner, "esbuild", "npx", esbuild_args(root), cd: root)

  Mix.shell().info("Rebuilt AccrueAdmin assets in priv/static/")
end
```

**Current Tailwind args to modify** (lines 63-75):
```elixir
defp tailwind_args(root) do
  [
    "--yes",
    @tailwind_version,
    "--config",
    Path.join(root, "assets/tailwind.config.js"),
    "--input",
    Path.join(root, "assets/css/app.css"),
    "--output",
    Path.join(root, "priv/static/accrue_admin.css"),
    "--minify"
  ]
end
```

**Error handling pattern** (lines 89-99):
```elixir
defp run_step!(runner, label, command, args, opts) do
  case runner.run(command, args, opts) do
    {:ok, 0} ->
      :ok

    {:ok, status} ->
      Mix.raise("#{label} build failed with exit status #{status}")

    {:error, reason} ->
      Mix.raise("#{label} build failed: #{Exception.message(reason)}")
  end
end
```

### `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` (test, file-I/O)

**Analog:** `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs`

**Fake runner pattern** (lines 8-24):
```elixir
defmodule FakeRunner do
  @behaviour Build.Runner

  @impl true
  def run("npx", ["--yes", tool | args], opts) do
    send(self(), {:runner_call, tool, args, opts[:cd]})

    output_path =
      case tool do
        "tailwindcss@3.4.17" -> keyword_value(args, "--output")
        "esbuild@0.25.3" -> prefixed_value(args, "--outfile=")
      end

    File.mkdir_p!(Path.dirname(output_path))
    File.write!(output_path, "generated by #{tool}")
    {:ok, 0}
  end
end
```

**Setup/restore committed bundle pattern** (lines 38-61):
```elixir
setup do
  Mix.Task.reenable("accrue_admin.assets.build")

  prior = Application.get_env(:accrue_admin, :accrue_admin_assets_build_runner)
  Application.put_env(:accrue_admin, :accrue_admin_assets_build_runner, FakeRunner)

  root = File.cwd!()
  js_path = Path.join(root, "priv/static/accrue_admin.js")
  css_path = Path.join(root, "priv/static/accrue_admin.css")
  prior_js = File.read!(js_path)
  prior_css = File.read!(css_path)

  on_exit(fn ->
    Mix.Task.reenable("accrue_admin.assets.build")
    File.write!(js_path, prior_js)
    File.write!(css_path, prior_css)
  end)
end
```

**Runner argument assertion pattern** (lines 66-78):
```elixir
test "rebuilds css and js through the package-local runner" do
  output = capture_io(fn -> Build.run([]) end)

  assert_received {:runner_call, "tailwindcss@3.4.17", tailwind_args, cwd}
  assert_received {:runner_call, "esbuild@0.25.3", esbuild_args, ^cwd}
  assert Enum.member?(tailwind_args, Path.join(cwd, "assets/css/app.css"))
  assert Enum.any?(esbuild_args, &String.starts_with?(&1, "--outfile="))
  assert File.read!(Path.join(cwd, "priv/static/accrue_admin.css")) =~ "tailwindcss"
  assert output =~ "Rebuilt AccrueAdmin assets"
end
```

### `scripts/ci/verify_package_docs.sh` (utility, batch)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Helper/error pattern** (lines 5-44):
```bash
ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[verify_package_docs] package docs verification failed: $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}

require_absent_regex() {
  local file=$1
  local pattern=$2

  if grep -Eq "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}
```

**Existing CSS guard pattern to extend** (lines 322-343):
```bash
# Token bypass guards (Phase 174, DSY-01)
app_css="$ROOT_DIR/accrue_admin/assets/css/app.css"
if grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" | grep -qv '\-\-ax-bp-'; then
  fail "$app_css must not have bare breakpoint @media without an --ax-bp-* annotation comment (DSY-01 — add a /* --ax-bp-NAME ↑/↓ */ comment to every breakpoint @media)"
fi

# Motion antipattern guards (Phase 177, MOT-01)
if grep -qE 'transition:\s*all\b' "$app_css"; then
  fail "$app_css must not use 'transition: all' (MOT-01/A1) — name the exact properties or use an --ax-transition-* bundle"
fi

if grep -qE 'cubic-bezier\(' "$app_css"; then
  fail "$app_css must not contain raw cubic-bezier() literals (MOT-01/A3) — use --ax-ease-* atoms from theme.css"
fi

if grep -E '(transition|animation):[^;]*[0-9]+(ms|s)\b' "$app_css" | grep -qv 'ax-skeleton-shimmer'; then
  fail "$app_css must not have raw ms/s duration literals in transition/animation rules (MOT-01/A3) — use --ax-dur-* tokens; exception: ax-skeleton-shimmer 1.4s is allowlisted"
fi
```

### `scripts/ci/verify_foundation_contrast.mjs` (utility, batch)

**Analog:** `scripts/ci/verify_package_docs.sh` helper/error structure plus `accrue/test/accrue/docs/package_docs_verifier_test.exs` negative-fixture style

**Source verifier pattern to derive**:
- Honor `ROOT_DIR` with a repo-root default so package tests can run against temporary fixtures.
- Emit deterministic stderr prefixed with `[foundation_contrast]`, mirroring the existing `[verify_package_docs]` log-scraper pattern.
- Keep the verifier dependency-free and source-based: read `accrue_admin/assets/css/theme.css`, strip comments, resolve the limited color syntax used by foundation tokens, then fail with the theme, pair, and ratio for each contrast miss.
- Pair the permanent guard in Plan 06 with low-contrast fixture coverage, following the existing temp-`ROOT_DIR` negative fixture pattern.

**Do not copy**:
- Shell-specific `grep` helpers from `verify_package_docs.sh`; this verifier needs JavaScript parsing because it resolves `var(...)`, `rgb()`/`rgba()`, `transparent`, and `color-mix(in srgb, ...)`.

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` (test, batch)

**Analog:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

**Verifier shell-out pattern** (lines 7-18):
```elixir
@script_path "../scripts/ci/verify_package_docs.sh"

test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
  accrue_version = extract_version!("accrue/mix.exs")
  accrue_admin_version = extract_version!("accrue_admin/mix.exs")

  assert status == 0

  assert output =~
           "package docs verified for accrue #{accrue_version}, accrue_admin #{accrue_admin_version}, and accrue_portal #{accrue_admin_version}"
end
```

### `accrue_admin/lib/accrue_admin/components/button.ex` (component, render)

**Analog:** `accrue_admin/lib/accrue_admin/components/button.ex`

**Rendering split pattern to preserve**:
```elixir
<a :if={@href} href={@href} class={@classes} aria-disabled={if(@disabled, do: "true", else: nil)} {@rest}>
  <%= render_slot(@inner_block) %>
</a>
<button :if={!@href} type={@type} class={@classes} disabled={@disabled} {@rest}>
  <%= render_slot(@inner_block) %>
</button>
```

Plan 04 should keep the existing `@href` versus native-button branch, preserve `button_variant_class/1`, class-list composition, `@rest`, and slot rendering, and only tighten the disabled-link branch so it omits `href`, adds `aria-disabled="true"`, and adds `tabindex="-1"`.

### `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` (test, render)

**Analog:** `accrue_admin/test/accrue_admin/components/navigation_components_test.exs`

**Component rendering test pattern**:
```elixir
render_component(fn assigns ->
  ~H"""
  <Button.button variant="ghost" href="/billing/webhooks">View webhooks</Button.button>
  """
end)
```

Plan 04 should add tests inside the existing `describe "Button"` group using `render_component` plus string assertions for the rendered tag, classes, attributes, omitted `href`, `aria-disabled`, `tabindex`, native `disabled`, and slot text. Keep this as component rendering coverage; browser/e2e behavior belongs to the later kitchen/computed-style plans.

**Negative fixture pattern** (lines 270-297):
```elixir
test "package docs verifier rejects 'transition: all' in app.css" do
  tmp_dir =
    Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

  File.rm_rf!(tmp_dir)
  on_exit(fn -> File.rm_rf(tmp_dir) end)
  seed_tmp_dir!(tmp_dir)

  app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
  original = File.read!(app_css_path)

  drifted =
    original <>
      "\n.ax-drift { transition: all 180ms; }\n"

  File.write!(app_css_path, drifted)

  {output, status} =
    System.cmd("bash", [@script_path],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}]
    )

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "app.css"
  assert output =~ "transition: all"
end
```

**Fixture copy pattern to update for new files** (lines 412-449):
```elixir
defp copy_fixture!(relative_path, tmp_dir) do
  destination = Path.join(tmp_dir, relative_path)
  File.mkdir_p!(Path.dirname(destination))
  File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
end

defp seed_tmp_dir!(tmp_dir) do
  File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/assets/css"))
  copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)
  File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/guides"))
  copy_fixture!("accrue_admin/guides/motion.md", tmp_dir)
end
```

### `accrue_admin/guides/admin_ui.md` (docs, transform)

**Analog:** `accrue_admin/guides/admin_ui.md`

**Current Tailwind posture to replace** (lines 7-12):
```markdown
## UI stack and polish direction

- **Build:** Tailwind CSS v3 compiles [`assets/css/app.css`](../assets/css/app.css) into `priv/static/accrue_admin.css` via `mix accrue_admin.assets.build`. [`assets/tailwind.config.js`](../assets/tailwind.config.js) scans `lib/**/*.{ex,heex}`; [`assets/tailwind_preset.js`](../assets/tailwind_preset.js) maps CSS variables to Tailwind theme colors so utilities stay on the same tokens as `ax-*` rules.
- **Authoring:** Prefer **`ax-*` classes** in `app.css` / `theme.css` for layout, surfaces, and reusable blocks. Add **Tailwind utilities in HEEx** when they reduce duplication (spacing, responsive tweaks) without fighting the preset.
- **Principles:** least surprise for billing operators; clear hierarchy (context → KPIs → primary work area); visible focus states; explicit empty, loading, and error states on lists; microcopy that matches host and Stripe language (subscription, invoice, webhook) unless the screen is intentionally abstracted.
- **Motion:** light CSS transitions on shells, drawers, and modals; honor `prefers-reduced-motion`; reach for LiveView `JS` only when CSS cannot carry the interaction.
```

**Private bundle statement pattern** (lines 102-117):
```markdown
## Private Asset Bundle

The package serves its own committed bundle from `priv/static/`. The JavaScript bundle must be **valid ES module output** (not a placeholder): it includes Phoenix + LiveView so admin `phx-click` interactions work in the browser. Rebuild it locally with:

```bash
cd accrue_admin
mix accrue_admin.assets.build
```

That task only touches:

- `priv/static/accrue_admin.css`
- `priv/static/accrue_admin.js`

No host Tailwind config edits or host JavaScript bootstrap changes are required.
```

### `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex`

**Imports/aliases pattern** (lines 5-21):
```elixir
use Phoenix.LiveView

alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  Button,
  Detail,
  DropdownMenu,
  FlashGroup,
  Icon,
  KpiCard,
  RelatedResources,
  StatusBadge,
  Tabs
}

alias AccrueAdmin.Dev.ComponentRegistry
```

**Mount availability gate pattern** (lines 23-44):
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  if fake_processor?() do
    {:ok,
     socket
     |> assign_shell(admin, "/dev/components", "Component Kitchen")
     |> assign(:available?, true)
     |> assign(:flashes, [
       %{
         kind: :info,
         message: "Previewing shared admin components against the shipped package CSS."
       }
     ])}
  else
    {:ok,
     socket
     |> assign_shell(admin, "/dev/components", "Component Kitchen")
     |> assign(:available?, false)
     |> assign(:flashes, [])}
  end
end
```

**Kitchen section pattern** (lines 164-214):
```elixir
<%!-- Component variants reference — every button, badge, status, and card with its token map --%>

<section :if={@available?} class="ax-card ax-dev-stack">
  <p class="ax-label">Buttons</p>
  <div class="ax-dev-grid">
    <%= for entry <- ComponentRegistry.variants_for("button") do %>
      <div class="ax-dev-variant-row">
        <div data-ax-theme="light">
          <Button.button variant={entry.variant} type="button">
            <%= String.capitalize(entry.variant) %>
          </Button.button>
        </div>
        <div data-ax-theme="dark" style="background: var(--ax-base); padding: var(--ax-space-sm);">
          <Button.button variant={entry.variant} type="button">
            <%= String.capitalize(entry.variant) %>
          </Button.button>
        </div>
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

**Motion reference table pattern** (lines 278-375):
```elixir
<%!-- Phase 177 — Motion reference (MOT-01) --%>
<section :if={@available?} class="ax-card ax-dev-stack">
  <p class="ax-label">Motion Reference</p>
  <p class="ax-body">
    Nine surfaces animate via Phase 174 <code>--ax-transition-*</code> bundles.
    Full spec: <code>accrue_admin/guides/motion.md</code>. Motion trace review: Phase 179.
  </p>
  <table class="ax-dev-motion-table">
    <thead>
      <tr>
        <th class="ax-label">Surface</th>
        <th class="ax-label">CSS selector</th>
        <th class="ax-label">Trigger</th>
        <th class="ax-label">Token(s)</th>
        <th class="ax-label">Justification</th>
      </tr>
    </thead>
```

### `accrue_admin/lib/accrue_admin/dev/component_registry.ex` (config, transform)

**Analog:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex`

**Compile-gated registry pattern** (lines 1-21):
```elixir
if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
    @moduledoc false

    @type entry :: %{
            family: String.t(),
            variant: String.t(),
            ax_class: String.t(),
            tokens: [String.t()]
          }

    @doc """
    Returns all curated component variant entries across the three DSY-03 families:
    button (4), status (5), card (6 = base + 5 delta tones).
    """
    @spec entries() :: [entry()]
    def entries do
```

**Entry shape pattern** (lines 30-40, 60-76):
```elixir
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
}

%{
  family: "status",
  variant: "moss",
  ax_class: "ax-status-badge ax-status-badge-moss",
  tokens: ["--ax-success", "--ax-success-readable", "--ax-elevated"]
}
```

**Family filter pattern** (lines 134-138):
```elixir
@doc "All entries for a given family string."
@spec variants_for(String.t()) :: [entry()]
def variants_for(family) do
  Enum.filter(entries(), &(&1.family == family))
end
```

### `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` (test, request-response)

**Analog:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs`

**Rendered kitchen coverage pattern** (lines 19-32):
```elixir
test "every registry variant appears in the /dev/components page render", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  for %{ax_class: ax_class} <- ComponentRegistry.entries() do
    [_base, variant_class] = String.split(ax_class, " ", parts: 2)

    assert html =~ variant_class,
           "registry variant #{inspect(ax_class)} — variant class #{inspect(variant_class)} " <>
             "was not found in the /dev/components page HTML"
  end
end
```

**Token definition guard pattern** (lines 93-119):
```elixir
test "all tokens listed in ComponentRegistry.entries() are defined in the design system" do
  theme_css = File.read!(theme_css_path())
  app_css = File.read!(app_css_path())

  known_in_layouts = ["--ax-accent", "--ax-accent-contrast"]

  phantom_tokens =
    for entry <- ComponentRegistry.entries(),
        token <- entry.tokens,
        token not in known_in_layouts,
        definition = token <> ":",
        not String.contains?(theme_css, definition),
        not String.contains?(app_css, definition) do
      {entry.family, entry.variant, token}
    end

  assert phantom_tokens == [],
         """
         Found tokens in ComponentRegistry with no `--token:` definition in theme.css or app.css:
         #{Enum.map_join(phantom_tokens, "\n", fn {family, variant, token} -> "  #{family}/#{variant}: #{token}" end)}
         """
end
```

### `accrue_admin/e2e/*.spec.js` (test, request-response)

**Analogs:** `accrue_admin/e2e/admin-a11y.spec.js`, `accrue_admin/e2e/reduced-motion.spec.js`, `accrue_admin/e2e/kitchen-banner.spec.js`

**Shared login/reset/seed pattern** (admin-a11y lines 4-17):
```javascript
async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}
```

**Theme scan pattern** (admin-a11y lines 19-28, 80-90):
```javascript
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

for (const theme of ["light", "dark"]) {
  const violations = await scan(page, theme);
  for (const v of violations) {
    failures.push(`${name} [${theme}] ${v.id}: ${v.nodes[0]?.target.join(" ")}`);
  }
}

expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
```

**Computed-style kitchen pattern** (kitchen-banner lines 8-31):
```javascript
test("ax-banner-danger paints non-transparent background and token-driven text color in both themes", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  const banner = page.locator("[data-ax-kitchen-banner='danger']");
  await expect(banner).toBeVisible();

  const colors = {};
  for (const theme of ["light", "dark"]) {
    await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
    await page.waitForTimeout(50);

    const bg = await page.evaluate(
      (el) => window.getComputedStyle(el).backgroundColor,
      await banner.elementHandle()
    );
    const color = await page.evaluate(
      (el) => window.getComputedStyle(el).color,
      await banner.elementHandle()
    );
    colors[theme] = { bg, color };
  }
});
```

**Reduced-motion token read pattern** (reduced-motion lines 54-60, 245-267):
```javascript
async function readDur3Token(page) {
  return page.evaluate(() =>
    window.getComputedStyle(document.documentElement).getPropertyValue("--ax-dur-3").trim()
  );
}

test("structural: no transform travel on dropdown/drawer under prefers-reduced-motion", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  const [riseSm, riseMd] = await page.evaluate(() => {
    const style = window.getComputedStyle(document.documentElement);
    return [
      style.getPropertyValue("--ax-rise-sm").trim(),
      style.getPropertyValue("--ax-rise-md").trim(),
    ];
  });

  expect(riseSm).toBe("0px");
  expect(riseMd).toBe("0px");
});
```

## Shared Patterns

### Token Scoping
**Source:** `accrue_admin/assets/css/theme.css` lines 9-14  
**Apply to:** `theme.css`, `app.css`, Playwright computed-style checks

All new root tokens must be scoped to `html.accrue-admin`, with dark overrides duplicated in both `html.accrue-admin[data-theme="dark"]` and `html.accrue-admin[data-theme="system"]` under `@media (prefers-color-scheme: dark)`.

### Semantic Class Consumption
**Source:** `accrue_admin/assets/css/app.css` lines 372-406  
**Apply to:** typography utilities, prose/measure selectors, status/focus/disabled/readonly consumers

Create `.ax-type-{role}` utilities in `app.css`, then migrate existing semantic classes such as `.ax-label`, `.ax-eyebrow`, `.ax-body`, `.ax-heading`, `.ax-display`, `.ax-kpi-value`, `.ax-field-help`, `.ax-field-error`, and empty/help/description selectors to consume the role utilities or equivalent role tokens.

### Guard + Negative Fixture Coupling
**Source:** `scripts/ci/verify_package_docs.sh` lines 322-343 and `accrue/test/accrue/docs/package_docs_verifier_test.exs` lines 270-297  
**Apply to:** Tailwind absence, no `@tailwind`/`@apply`, no Tailwind utility authoring, z-index literals, raw type declarations, semantic token presence

Every new shell guard should have at least one temp-`ROOT_DIR` negative fixture test that mutates copied files and asserts non-zero verifier status plus the expected error text.

### Component Kitchen + Registry Truth
**Source:** `component_kitchen_live.ex` lines 164-214 and `component_registry_test.exs` lines 93-119  
**Apply to:** foundation specimens for type roles, measure, focus, disabled/readonly, status roles, and layer samples

When adding kitchen specimens that carry token metadata, add registry entries with `family`, `variant`, `ax_class`, and `tokens`; tests should assert every registry token is defined and rendered.

### Playwright Computed Style Checks
**Source:** `kitchen-banner.spec.js` lines 8-31 and `reduced-motion.spec.js` lines 245-267  
**Apply to:** type role application, measure width, focus ring/offset/shadow, disabled/readonly token resolution, status color differences, z-index token values, scrollbar tokens where supported

Use `/billing/dev/components`, set `reducedMotion: "reduce"` when checking theme changes, toggle `data-theme` directly, and inspect `window.getComputedStyle(...)` rather than relying only on screenshots.

## No Analog Found

None. All Phase 188 files have exact or role-match analogs in the existing codebase.

## Metadata

**Analog search scope:** `accrue_admin/assets`, `accrue_admin/lib`, `accrue_admin/test`, `accrue_admin/e2e`, `accrue/test/accrue/docs`, `scripts/ci`, `accrue_admin/guides`  
**Files scanned:** 100 admin source files plus targeted planning/research files  
**Pattern extraction date:** 2026-06-15
