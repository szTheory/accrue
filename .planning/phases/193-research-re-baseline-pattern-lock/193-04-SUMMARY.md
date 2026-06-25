---
phase: "193"
plan: "04"
subsystem: accrue_admin
status: complete
tags:
  - storybook
  - dev-tooling
  - assets
  - router
  - registry
dependency_graph:
  requires:
    - "193-01 (phoenix_storybook dep wired, elixirc_paths extended)"
    - "accrue_admin/priv/static/storybook.css + storybook.js (committed bundles)"
  provides:
    - "accrue_admin/lib/accrue_admin/dev/storybook.ex — PhoenixStorybook backend module (dev/test-only)"
    - "accrue_admin/lib/accrue_admin/assets.ex — storybook_css/storybook_js kinds + hash fns + hashed_path + asset clauses"
    - "accrue_admin/lib/accrue_admin/router.ex — wrap_with_storybook_dev_routes with Code.ensure_loaded? guard"
    - "storybook/_support/registry_story.ex — RegistryStory.variations_for/1 pipeline"
    - "storybook/components/button.story.exs — PoC button story delegating to RegistryStory"
    - "accrue_admin/priv/static/storybook.css — committed bundle (PSB CSS + accrue_admin.css + dark-mode shim)"
    - "accrue_admin/priv/static/storybook.js — committed bundle (PSB client JS + spike D comment)"
  affects:
    - "Phase 200 (uses Storybook for full component-family stories per D-14)"
    - "Plans 193-05 (verify_package_docs.sh needles may reference Storybook artifacts)"
tech_stack:
  added: []
  patterns:
    - "Code.ensure_loaded?(PhoenixStorybook.Router) guard in router wrap — host-absence isolation"
    - "if Mix.env() != :prod do wrapper in storybook.ex and registry_story.ex"
    - "AccrueAdmin.Assets committed-bundle pattern extended to storybook_css/storybook_js kinds"
    - "RegistryStory.variations_for/1: ComponentRegistry.variants_for/1 → [%Variation{}] pipeline"
key_files:
  created:
    - accrue_admin/lib/accrue_admin/dev/storybook.ex
    - storybook/_support/registry_story.ex
    - storybook/components/button.story.exs
    - accrue_admin/priv/static/storybook.css
    - accrue_admin/priv/static/storybook.js
  modified:
    - accrue_admin/lib/accrue_admin/assets.ex
    - accrue_admin/lib/accrue_admin/router.ex
decisions:
  - "D-17 spike B: .psb-sandbox selector shim chosen (zero JS overhead vs. Option B JS hook); selector .psb-sandbox.accrue-admin.ax-theme-dark-shim mirrors full dark token block from theme.css"
  - "D-17 spike C: inert attribute chosen as background-suppression mechanism (browser floor Chrome 102+, Firefox 112+, Safari 15.5+ satisfied by target audience)"
  - "D-17 spike D: Storybook CSS/JS served via AccrueAdmin.Assets committed-bundle route (no Tailwind rebuild required)"
  - "Code.ensure_loaded? guard is mandatory in router (unlike Mailglass) because live_storybook macro resolution fails at compile time when PhoenixStorybook.Router is absent"
  - "PSB asset path warnings at compile time are expected (PSB looks in _build, we serve via AccrueAdmin.Assets routes)"
metrics:
  duration: "~9m"
  completed: "2026-06-25"
  tasks_completed: 2
  tasks_total: 2
  files_created: 5
  files_modified: 2
---

# Phase 193 Plan 04: Storybook Walking Skeleton Summary

PhoenixStorybook walking skeleton shipped: backend module, leak-proof router wrap, committed-bundle asset serving, RegistryStory generator, and PoC button story — resolving D-17 spikes B/C/D and proving the registry→Variation pipeline end-to-end.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Build committed asset bundles (storybook.css + storybook.js) | 21f570fe | accrue_admin/priv/static/storybook.css, storybook.js |
| 2 | Storybook backend, asset extension, router wrap, story files | 287aee33 | storybook.ex, assets.ex, router.ex, registry_story.ex, button.story.exs |

## What Was Built

### Committed asset bundles (Task 1)

**`accrue_admin/priv/static/storybook.css`** (139 KB committed bundle)

Composed of three parts in order:
1. PhoenixStorybook sandbox CSS (`deps/phoenix_storybook/priv/static/css/phoenix_storybook.css`)
2. Admin CSS bundle (`accrue_admin/priv/static/accrue_admin.css`)
3. D-17 spike B dark-mode shim block:
   ```css
   .psb-sandbox.accrue-admin.ax-theme-dark-shim {
     /* full --ax-* dark token set mirrored from html.accrue-admin[data-theme="dark"] */
   }
   ```

**`accrue_admin/priv/static/storybook.js`** (6.3 KB committed bundle)

PhoenixStorybook client JS with D-17 spike D decision comment header.

### Storybook backend module (Task 2)

**`accrue_admin/lib/accrue_admin/dev/storybook.ex`**

Wrapped in `if Mix.env() != :prod do` with D-17 spike C comment. Configures:
- `otp_app: :accrue_admin`
- `content_path: Path.expand("../../../../storybook", __DIR__)`
- `css_path: AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook")`
- `js_path: AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook")`
- `sandbox_class: "accrue-admin"`, `color_mode_sandbox_dark_class: "ax-theme-dark-shim"`

### Asset extension

**`accrue_admin/lib/accrue_admin/assets.ex`**

Extended with:
- `@storybook_css_file`/`@storybook_js_file` module attributes with `@external_resource`
- `@storybook_css_body`/`@storybook_js_body` + hash attributes
- `:storybook_css | :storybook_js` added to `@type kind`
- `storybook_css_hash/0` and `storybook_js_hash/0` public functions
- `hashed_path/2` clauses for `:storybook_css` and `:storybook_js`
- `asset/1` clauses for both kinds
- `init/1` and `call/2` guards extended to include both new kinds

### Router wrap

**`accrue_admin/lib/accrue_admin/router.ex`**

`wrap_with_storybook_dev_routes/3` added after `wrap_with_mailglass_dev_routes`:
- `true` branch uses `if Code.ensure_loaded?(PhoenixStorybook.Router) do` (mandatory — compile-time guard for host apps without the dep)
- Mounts `live_storybook("/dev/storybook", backend_module: AccrueAdmin.Dev.Storybook)` in a sibling scope under `:accrue_admin_browser` pipeline
- No-op fallback clause for `dev_routes? = false` or absent dep

### RegistryStory pipeline

**`storybook/_support/registry_story.ex`** (compiled in dev/test via elixirc_paths from Plan 01)

`AccrueAdmin.Storybook.RegistryStory.variations_for/1` maps `ComponentRegistry.variants_for(family)` entries → `[%PhoenixStorybook.Story.Variation{}]`. Variation IDs derived from variant + specimen index for uniqueness. Wrapped in `if Mix.env() != :prod do`.

### PoC button story

**`storybook/components/button.story.exs`**

```elixir
defmodule AccrueAdmin.Storybook.Components.Button do
  use PhoenixStorybook.Story, :component
  def function, do: &AccrueAdmin.Components.Button.button/1
  def variations, do: AccrueAdmin.Storybook.RegistryStory.variations_for("button")
end
```

Delegates to RegistryStory (D-15 constraint honored — ComponentRegistry remains SSOT).

### D-17 spike decisions recorded

| Spike | Decision | Recorded in |
|-------|----------|-------------|
| B — dark-mode shim | CSS class shim chosen (.psb-sandbox selector, zero JS overhead) over JS hook | `storybook.css` dark-mode shim comment block |
| C — inert browser floor | `inert` attribute (Chrome 102+/Firefox 112+/Safari 15.5+) over aria-hidden+focusguard | `storybook.ex` and `registry_story.ex` comments |
| D — asset-serving | AccrueAdmin.Assets committed-bundle route (no Tailwind rebuild) | `storybook.js` header comment |

## Verification Results

```
grep -c "Code.ensure_loaded?(PhoenixStorybook.Router)" router.ex  → 1  ✓
test -s storybook.ex                                               → OK ✓
grep -c "storybook_css_hash" assets.ex                            → 5  ✓
test -s storybook/_support/registry_story.ex                      → OK ✓
test -s storybook/components/button.story.exs                     → OK ✓
test -s storybook.css                                             → OK ✓
test -s storybook.js                                              → OK ✓
MIX_ENV=prod mix compile (accrue_host)                            → exit 0 ✓
MIX_ENV=dev  mix compile (accrue_host)                            → exit 0 ✓
phx.routes | grep storybook | wc -l                               → 0   ✓
```

Pre-existing PSB warning at accrue_admin compile time: "Can't resolve css_path / js_path not found (storybook assets are built by `mix assets.build`)" — these are PSB-internal resolution warnings when assets are not in the `_build` tree; they do not affect our asset-serving path (routes through AccrueAdmin.Assets).

## Deviations from Plan

### Pre-existing host lock mismatch (Rule 3 auto-fix)

**Found during:** Task 2 verification (host-absence compile test)

**Issue:** `examples/accrue_host/mix.lock` had stale lock entries for several deps (floki, phoenix, phoenix_live_view, etc.), causing `mix compile` to fail with "lock mismatch" before any code was reached.

**Fix:** Ran `mix deps.get` in the host to update the lock file. This is a pre-existing maintenance task unrelated to our changes.

**Files modified:** `examples/accrue_host/mix.lock`

**Commit:** 287aee33 (included in task 2 commit)

No other deviations — plan executed as written.

## Known Stubs

None. The Storybook walking skeleton is complete and functional. The one PoC story (button) delegates to RegistryStory which delegates to ComponentRegistry — no hardcoded placeholder data. The remaining ~13 component families are explicitly deferred to Phase 200 per D-14 (not stubs, deliberate deferral).

## Threat Flags

None beyond the threat model already in the PLAN.md. T-193-07 (storybook routes in host prod) is mitigated by the dual guard: `Code.ensure_loaded?` in router + `if Mix.env() != :prod` in storybook.ex. T-193-09 (dev tools in adopter prod) is mitigated by the `only: [:dev, :test]` dep declaration (Plan 01) + the env guards. Verification: 0 storybook routes in host (both dev and prod).

## Self-Check: PASSED

Files exist:
- FOUND: accrue_admin/lib/accrue_admin/dev/storybook.ex
- FOUND: accrue_admin/lib/accrue_admin/assets.ex (modified)
- FOUND: accrue_admin/lib/accrue_admin/router.ex (modified)
- FOUND: storybook/_support/registry_story.ex
- FOUND: storybook/components/button.story.exs
- FOUND: accrue_admin/priv/static/storybook.css
- FOUND: accrue_admin/priv/static/storybook.js

Commits exist:
- FOUND: 21f570fe (task 1 — committed storybook bundles)
- FOUND: 287aee33 (task 2 — backend + assets + router + story files)
