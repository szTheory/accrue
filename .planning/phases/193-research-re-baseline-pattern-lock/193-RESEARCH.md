# Phase 193: Research, Re-baseline & Pattern Lock

**Researched:** 2026-06-25
**Domain:** `accrue_admin` design contracts, PhoenixStorybook scaffold, forward-only baseline extension, CSS source guards
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** PRIMARY overlay: body-level JS hook portals markup to `#ax-overlay-root`. Reuses shipped `FocusTrap` hook + isolated `--ax-z-*` scale + new ref-counted iOS-safe `ScrollLock` hook + `inert` background + single idempotent dismissal (backdrop click + Escape → same close) + origin-aware enter motion. One primitive, three presentations: modal / drawer / popover sharing the same portal + dismissal + scroll-lock contract.

**D-02** FALLBACK: native `<dialog showModal()>` + top-layer, reserved for individual surfaces only if Phase-199 transformed-ancestor audit finds a `transform`/`filter`/`contain` ancestor that cannot be removed. Reject "hold both open as default."

**D-03** Why portal over `<dialog>` as primary: `<dialog>` `showModal()`/`close()` writes a client-imperative `open` attribute that morphdom actively fights (requires `JS.ignore_attributes("open")` + state-reconciliation bridge hook). The shipped `:if={@open}` + `phx-mounted`/`phx-remove` model in both existing shells is correct and must not be abandoned. `<dialog>`'s "free" wins (Escape, focus containment, inert) are already shipped in `FocusTrap`; its unsolved iOS scroll-lock problem is not solved by `<dialog>` either.

**D-04** Keep the `<dialog>` swap-seam clean. Phase 193 ships the portal as A, isolated behind the primitive's component boundary so Phase 199 can flip individual surfaces to B without touching ~20 call sites.

**D-05** Phase-193 overlay spike must empirically prove (Playwright hit-test): (1) open overlay's primary action AND inner focusable control click-succeed while scrim is present, across desktop+mobile × light/dark; (2) portal re-parent survives LiveView `phx-update`/navigation without orphaning or double-mounting `#ax-overlay-root`; (3) body scroll locked with no scrollbar-gutter jump; (4) transformed-ancestor probe — wrap shell in `transform:translateZ(0)` test ancestor and confirm portal still escapes.

**D-06** Specs ship as ExDoc guides: `accrue_admin/guides/spec-overview.md`, `accrue_admin/guides/spec-list.md`, `accrue_admin/guides/spec-detail.md`. Kebab-case, matching `core-admin-parity.md`/`theme-exceptions.md`.

**D-07** Wire like `motion.md`: add all three to `accrue_admin/mix.exs` `docs/0` `extras` and `Guides:` `groups_for_extras` group. Add one `require_fixed` needle per spec to `scripts/ci/verify_package_docs.sh` (one stable anchor heading each, e.g. `## SPEC-DETAIL — summary-then-drill`) plus the three `mix.exs` `"guides/spec-*.md"` needles.

**D-08** Honor the `verify_package_docs.sh` ↔ `PackageDocsVerifierTest` coupling invariant: every new needle added to the script MUST be mirrored into `seed_tmp_dir!` in `accrue/test/accrue/docs/package_docs_verifier_test.exs`, or all 6 negative tests fail.

**D-09** Layered specs (prose intent + per-archetype machine-checkable invariant checklist).

**D-10** Machine assertion only if page-flow driver / source-guards / axe-core can decide deterministically; residual stays prose for the 12-dim adversarial judge.

**D-11** Concrete invariant split per archetype (see CONTEXT.md for full list).

**D-12** Document the checklist IN the shipped guide (GOV.UK-style published acceptance criteria).

**D-13** Minimal Storybook scaffold. Land in 193: dep + env-guarded backend module + `Code.ensure_loaded?(PhoenixStorybook.Router)`-guarded sibling-scope router wrap + committed-bundle asset serving via `AccrueAdmin.Assets` + one PoC `button` story via `RegistryStory.variations_for/1` + host-absence compile test.

**D-14** Defer to Phase 200: remaining ~13 families + 8 group contracts + both-color-mode theming verification (STY-02/STY-03).

**D-15** Registry stays SSOT; the `/dev/components` kitchen stays as-is.

**D-16** Baseline storage = additive sibling `baseline.page-flow.cells.json`. Clean provenance; existing `baseline.cells.json` (21,276 cells) stays immutable.

**D-17** Three remaining non-overlay Phase-193 spikes: `data-theme` dark-mode shim for Storybook; `inert` vs `aria-hidden`+focusguard browser-floor; Storybook asset-serving without Tailwind rebuild — resolved as part of standing up the single PoC story.

### Claude's Discretion

D-16 is marked as research-recommended (baseline storage). Planner may finalize the exact filename/location next to the v1.53 baseline.

### Deferred Ideas (OUT OF SCOPE)

- Promoting native `<dialog>` to primary overlay (revisited per-surface in Phase 199 only)
- Full Storybook story breadth (13 families + 8 group contracts + theming verification) — Phase 200
- `--ax-dur-sheet` motion token — pending mobile-sheet UAT in Phase 199
- View Transitions API for list/stream motion — explicitly out of v1.54
- Empirical loves/hates pull (HN/Reddit) — optional MEDIUM-confidence hardening only
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RES-01 | Three locked archetype pattern specs (SPEC-OVERVIEW / SPEC-LIST / SPEC-DETAIL) as design contracts | D-06..D-12; seed content in `.planning/research/FEATURES.md`; wiring pattern from `guides/motion.md` precedent |
| RES-02 | Phase-187 scored cell baseline extended with `surface_type:"page-flow"` cells over ~20 admin routes (additive sibling `baseline.page-flow.cells.json`) wired into the forward-only zero-regression gate | D-16; `phase191-page-flow-helpers.js` driver reuse; `baseline.cells.json` schema confirmed |
| RES-03 | Four Phase-193 spikes resolved with recorded decisions: overlay portal-vs-native-`<dialog>`, `data-theme` dark-mode shim, `inert` vs `aria-hidden` browser-floor, Storybook asset-serving without Tailwind rebuild | D-05, D-17; Playwright hit-test as the provenance artifact |
| RES-04 | Three new CSS source guards in `verify_package_docs.sh`/CI: spacing-literal ban, `:focus-visible` enforcement, truncation-without-`min-width:0` | D-07..D-08; mirror FND-01/MOT-01 guard shape |
| STY-01 | `phoenix_storybook` added `only: [:dev, :test]`; `Code.ensure_loaded?`-guarded sibling-scope mount; `examples/accrue_host` compiles in dev and prod with dep absent; no storybook route exposed | D-13; confirmed dep-compat; Mailglass sibling-scope precedent in `router.ex` |
</phase_requirements>

---

## Summary

Phase 193 is a **contract-shipping + foundation-standing-up** phase, not a user-visible feature phase. It delivers four durable artifacts that every subsequent Phase 194–200 conforms against: three archetype pattern specs as ExDoc guides with machine-checkable invariant checklists; an extended forward-only baseline with page-flow cells over ~20 routes; a minimal PhoenixStorybook scaffold with one PoC story proving the registry→Storybook pipeline; and three new CSS source guards wired into CI.

**All gray-area decisions (D-01..D-17) are pre-locked in CONTEXT.md.** The research task is verification-of-ground-truth: confirm exact module names, function signatures, file paths, hook semantics, and guard shapes the planner will reference, and surface any drift between what CONTEXT.md assumes and what the code actually is.

**Key finding from code verification:** The codebase matches CONTEXT.md's assumptions well. Critical confirmations: `FocusTrap` hook is shipped and solid (full Escape/Tab/focusin containment, `deactivateFocusTrap` + `restoreFocus`); both overlay shells (`DetailDrawer`, `StepUpAuthModal`) use the `:if={@open}` + `phx-mounted`/`phx-remove` + `phx-hook="FocusTrap"` shape; `AccrueAdmin.Assets` uses `File.read!` + `@external_resource` + md5 hash + content-hash routes — the exact committed-bundle serving mechanism Storybook must reuse; `wrap_with_mailglass_dev_routes/3` in `router.ex` is the exact sibling-scope precedent for the Storybook wrap; `ComponentRegistry` is `if Mix.env() != :prod`-guarded and exposes `entries/0`, `group_contracts/0`, `variants_for/1`; `verify_package_docs.sh` has a well-established `require_fixed` / `require_regex` / `require_absent_regex` API; `PackageDocsVerifierTest.seed_tmp_dir!` copies specific files into a temp directory and MUST be kept in sync with the script.

**Primary recommendation:** Execute Phase 193 as four parallel work-streams — specs authoring, baseline extension, Storybook scaffold, CSS guards — but apply the `verify_package_docs.sh`/`seed_tmp_dir!` coupling fix as a single atomic commit covering all three guards and spec needles together.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pattern specs (archetype guides) | Frontend Server (accrue_admin package) | — | Shipped ExDoc guides + CI needles; no runtime tier needed |
| Forward-only baseline extension | CI / Test harness | Browser (Playwright) | New cells appended to `baseline.page-flow.cells.json`; gate runs via `regressions.ndjson` in CI |
| Storybook scaffold (dep + mount + backend) | Frontend Server (accrue_admin dev/test) | — | `only: [:dev, :test]`; router macro expands sibling scope at compile time |
| CSS source guards | CI (verify_package_docs.sh) | — | Grep-shaped lint; no runtime tier |
| Overlay spike (D-05 Playwright proof) | Browser (Playwright hit-test) | Frontend Server (LiveView) | Runtime behavior proven via `assertTopPointerTarget` against real composed page |
| Registry-driven story generator | Frontend Server (accrue_admin dev/test) | — | `RegistryStory` is a compiled `.ex` in `storybook/_support/`; no production compile path |
| Storybook asset serving | Frontend Server (AccrueAdmin.Assets) | — | Reuses the committed-bundle controller; `File.read!` + hash route |

---

## Standard Stack

### Core (pre-verified, all in `accrue_admin/mix.exs`)

| Library | Current Version | Purpose | Status |
|---------|----------------|---------|--------|
| `phoenix_storybook` | `~> 1.2` (1.2.0, released 2026-06-11) | Storybook scaffold | NEW — add to `deps` |
| `phoenix_live_view` | `~> 1.1` | LiveView (already required) | EXISTING |
| `phoenix` | `~> 1.8` | Router/Endpoint (already required) | EXISTING |
| `mailglass_admin` | `~> 1.0`, `only: [:dev, :test]` | Sibling-scope mount precedent | EXISTING |

### New dep line for `accrue_admin/mix.exs`

```elixir
{:phoenix_storybook, "~> 1.2", only: [:dev, :test]},
```

No conflict risk: `phoenix_storybook 1.2.0` requires Elixir `~> 1.15`, Phoenix `~> 1.8.1`, LiveView `~> 1.1.21 or ~> 1.2.0` — all satisfied by `accrue_admin`'s existing pins. New transitives (`makeup_eex`, `makeup_html`, `mdex`) are dev/test-only and never reach a host runtime.

### Package Legitimacy Audit

| Package | Registry | Age | Confidence | Verdict | Disposition |
|---------|----------|-----|-----------|---------|-------------|
| `phoenix_storybook` | Hex.pm | 2+ years (0.x → 1.0 → 1.1 → 1.2.0 2026-06-11) | HIGH — hexdocs + hex.pm verified in prior research | OK | Approved |

All other packages referenced in this phase are already in `accrue_admin`'s deps tree; no new external packages beyond `phoenix_storybook`.

---

## Architecture Patterns

### System Architecture Diagram (Phase 193 deliverables)

```
accrue_admin/mix.exs deps
  └─ {:phoenix_storybook, "~> 1.2", only: [:dev, :test]}
        │
        ▼
accrue_admin/lib/accrue_admin/dev/storybook.ex  [if Mix.env() != :prod]
  use PhoenixStorybook (otp_app, content_path, css_path, js_path, sandbox_class, color_mode)
        │
        ▼
accrue_admin/lib/accrue_admin/router.ex
  accrue_admin/2 macro
    └─ |> wrap_with_mailglass_dev_routes(dev_routes?, mount_path)
    └─ |> wrap_with_storybook_dev_routes(dev_routes?, mount_path)
                │  Code.ensure_loaded?(PhoenixStorybook.Router) guard
                │  imports PhoenixStorybook.Router ONLY inside true-branch quote
                │  live_storybook("/dev/storybook", backend_module: AccrueAdmin.Dev.Storybook)
                │
                ▼
        storybook/_support/registry_story.ex  [compiled .ex, NOT .story.exs]
          AccrueAdmin.Dev.ComponentRegistry.variants_for(family)
          → [%Variation{id, attributes, slots, description}]
                │
                ▼
        storybook/components/button.story.exs  [PoC proof]
          use PhoenixStorybook.Story, :component
          def variations, do: AccrueAdmin.Storybook.RegistryStory.variations_for("button")

AccrueAdmin.Assets (committed-bundle serving)
  priv/static/accrue_admin.css   → existing :css route
  priv/static/storybook.css      → NEW :storybook_css route  (ax bundle + dark shim + psb sandbox css)
  priv/static/storybook.js       → NEW :storybook_js route   (storybook hooks)
  File.read! + @external_resource + md5 hash (same pattern as :css/:js)

scripts/ci/verify_package_docs.sh
  require_fixed "accrue_admin/guides/spec-overview.md" "## SPEC-OVERVIEW — "
  require_fixed "accrue_admin/guides/spec-list.md"     "## SPEC-LIST — "
  require_fixed "accrue_admin/guides/spec-detail.md"   "## SPEC-DETAIL — summary-then-drill"
  require_fixed "accrue_admin/mix.exs"                 '"guides/spec-overview.md"'
  require_fixed "accrue_admin/mix.exs"                 '"guides/spec-list.md"'
  require_fixed "accrue_admin/mix.exs"                 '"guides/spec-detail.md"'
  [3 new CSS guards for spacing-literal / :focus-visible / truncation-without-min-width]

.planning/milestones/v1.53-phases/187-audit-baseline/
  baseline.cells.json            (21,276 cells — IMMUTABLE, read-only)
  baseline.page-flow.cells.json  (NEW — additive sibling, page-flow cells for ~20 routes)
```

### Recommended New File Structure

```
accrue_admin/
├── lib/accrue_admin/dev/
│   └── storybook.ex                        # env-guarded backend module
├── guides/
│   ├── spec-overview.md                    # RES-01 spec A
│   ├── spec-list.md                        # RES-01 spec B
│   └── spec-detail.md                      # RES-01 spec C
├── priv/static/
│   ├── storybook.css                       # committed: ax bundle + dark shim + psb css
│   └── storybook.js                        # committed: storybook hooks
storybook/
├── _support/
│   └── registry_story.ex                   # compiled generator (NOT .story.exs, NOT under lib/)
└── components/
    └── button.story.exs                    # PoC proof story

.planning/milestones/v1.53-phases/187-audit-baseline/
└── baseline.page-flow.cells.json           # additive sibling baseline (RES-02)
```

---

## Code Verification — Confirmed Ground Truth

The following are **verified against the actual current code**, resolving any potential drift between CONTEXT.md assumptions and reality.

### `AccrueAdmin.Router` — Mailglass sibling-scope precedent

**File:** `accrue_admin/lib/accrue_admin/router.ex`

Confirmed structure (lines 107–138):
- The `accrue_admin/2` macro builds a quote AST, then pipes it through `|> wrap_with_mailglass_dev_routes(dev_routes?, mount_path)`.
- `wrap_with_mailglass_dev_routes/3` has TWO clauses: `(base_ast, true, mount_path)` and `(base_ast, _dev_routes?, _mount_path)` (fallback no-op).
- The `true` clause builds a `dev_ast` quote and returns `quote do: unquote(base_ast); unquote(dev_ast)` — exactly the sibling-scope chaining pattern.
- `import MailglassAdmin.Router` is inside the `quote bind_quoted:` inside the `true` clause — NOT at module top-level.
- NOTE: The Mailglass wrap does NOT use `Code.ensure_loaded?`. That guard is mandatory for Storybook (D-13) because `mailglass_admin` is explicitly in `accrue_admin`'s deps, whereas `phoenix_storybook` is not available to host apps' dev compile.

**Confirmed wrap-chain site (line 107–108):**
```elixir
    end
    |> wrap_with_mailglass_dev_routes(dev_routes?, mount_path)
```

The Storybook wrap chains after this line:
```elixir
    |> wrap_with_mailglass_dev_routes(dev_routes?, mount_path)
    |> wrap_with_storybook_dev_routes(dev_routes?, mount_path)
```

**`dev_routes?` computation (lines 187–191):**
```elixir
allow_live_reload =
  case Keyword.get(opts, :allow_live_reload, Mix.env() != :prod) do
    value when is_boolean(value) -> value
    _ -> raise ArgumentError, ":allow_live_reload must be a boolean"
  end
```

So `dev_routes? == false` in host `:prod` compile (default `Mix.env() != :prod` = false). The `Code.ensure_loaded?` guard is the second safety belt for host `:dev` compile where `dev_routes? == true` but `phoenix_storybook` was never downloaded.

**Pipeline name for Storybook routes:** `:accrue_admin_browser` (defined in the outer scope block at lines 43–49). Use `pipe_through(:accrue_admin_browser)` in both Storybook scope blocks.

### `AccrueAdmin.Assets` — committed-bundle serving mechanism

**File:** `accrue_admin/lib/accrue_admin/assets.ex`

Confirmed pattern:
- Module attributes at compile time: `@css_file Application.app_dir(:accrue_admin, "priv/static/accrue_admin.css")`
- `@external_resource @css_file` (triggers recompile when file changes)
- `@css_body File.read!(@css_file)` (inlines at compile)
- `@css_hash :md5 |> :crypto.hash(@css_body) |> Base.encode16(case: :lower)`
- Route registered as: `get("/assets/css-#{AccrueAdmin.Assets.css_hash()}", AccrueAdmin.Assets, :css)`
- `call/2` dispatches to `asset/1` which returns `{body, content_type, etag}`

For Storybook, add:
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

The Storybook backend module's `css_path` and `js_path` must match the hashed route URLs. Example: `css_path: "#{mount_path}/assets/storybook-css-#{@storybook_css_hash}"`.

**NOTE:** The `@external_resource`s are module-level — they trigger a recompile of `AccrueAdmin.Assets` when the committed bundle changes. This is the correct discipline: edit `storybook.css` source, run `mix accrue_admin.assets.build` equivalent, commit the new bundle, recompile triggers fresh hash, route updates automatically.

**DRIFT ALERT — `hashed_path/2` only supports `:brand | :css | :js`:** The current `hashed_path/2` has a guard `kind in [:brand, :css, :js]`. Adding `:storybook_css` / `:storybook_js` requires extending the type and the function clause. This is a small but concrete change the planner must include.

### `AccrueAdmin.Components.DetailDrawer` — `:if={@open}` + `phx-mounted`/`phx-remove` shape

**File:** `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`

Confirmed:
- `section :if={@open}` — server-driven conditional render (not CSS hide/show)
- `phx-hook="FocusTrap"` on the shell section
- `phx-mounted={JS.show(transition: {"ax-drawer-entering", "ax-drawer-enter-from", "ax-drawer-enter-to"}, time: 240)}`
- `phx-remove={JS.hide(transition: {"ax-drawer-leaving", "ax-drawer-leave-from", "ax-drawer-leave-to"}, time: 140)}`
- `data-focus-trap-close-event` + `data-focus-trap-close-target` + `data-focus-trap-fallback` on the shell
- `aria-modal="true"`, `role="dialog"`, `aria-labelledby`/`aria-describedby`
- CONFIRMED BUG (R-3 geometry): drawer uses classes `ax-drawer-entering` / `ax-drawer-enter-from` / `ax-drawer-enter-to` — the CSS for these classes may have the wrong-axis `translateX` mentioned in ARCHITECTURE.md. The Phase-193 spike must NOT fix this; D-04 says the primitive's enter motion is Phase 199. Phase 193 only records the R-3 finding as one of the four spike decisions (D-05 #4 / RES-03).

### `AccrueAdmin.Components.StepUpAuthModal` — second overlay shell

**File:** `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex`

Confirmed:
- `section :if={@pending}` — same `:if={}` conditional render
- `phx-hook="FocusTrap"`, `data-focus-trap-close-event="step_up_dismiss"`, `data-focus-trap-initial="#step-up-code"`, `data-focus-trap-fallback="#step-up-title"`
- `phx-mounted={JS.push_focus() |> JS.focus_first(to: "#accrue-admin-step-up-dialog")}` (NOTE: uses LiveView JS primitives directly, not `JS.show` transition — different from DrawerDrawer)
- `phx-remove={JS.pop_focus()}`
- Backdrop: `div.ax-step-up-modal-backdrop` with `phx-click="step_up_dismiss"` — no JS transition on backdrop separately

### `FocusTrap` hook — confirmed API

**File:** `accrue_admin/assets/js/hooks/focus_trap.js`

Confirmed:
- Exported as `export const FocusTrap = { ... }` (named export, not default)
- `mounted()` / `updated()` / `destroyed()` lifecycle methods
- `isFocusTrapActive()` checks `this.el.dataset.focusTrapActive !== "false"` — so setting `data-focus-trap-active="false"` on the element deactivates without removing it from DOM
- `dispatchFocusTrapClose()` reads `this.el.dataset.focusTrapCloseEvent` and calls `this.pushEventTo(target, eventName, {})` or `this.pushEvent(eventName, {})`
- Keydown: Escape → `dispatchFocusTrapClose()`; Tab → cycle through `focusableElements()`
- `scheduleInitialFocus()` uses `setTimeout(..., 0)` — asynchronous, avoids racing with LiveView DOM settle
- `restoreFocus()` restores to `previouslyFocused` or falls back to `fallbackFocusTarget()`
- CONFIRMED: hook does NOT add `inert` to background or lock body scroll — those are left to the portal primitive (D-01, R-1)

### `AccrueAdmin.Dev.ComponentRegistry` — SSOT structure

**File:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex`

Confirmed:
- `if Mix.env() != :prod do` wrapper — same guard pattern for `storybook.ex`
- `@type entry :: %{family:, variant:, ax_class:, tokens:, applicable_states:, na_states:, specimens:}`
- `@type group_contract :: %{name:, slug:, proof_id:, required_states:, primary_components:, locators:, phase191_handoff_tags:, behavior_contracts:, hierarchy:, representative_route_category:, decisions:}`
- Public functions: `group_contracts/0`, `entries/0` (implied by SUMMARY.md), `variants_for/1` (used in RegistryStory)
- `specimens` per entry: `[%{label: String.t(), props: map(), content: String.t() | nil}]`
- CONFIRMED: `variants_for/1` takes a family name string and returns matching entries

### `verify_package_docs.sh` — existing guard shape

**File:** `scripts/ci/verify_package_docs.sh`

Confirmed functions:
- `require_fixed FILE NEEDLE` — `grep -Fq -- "$needle" "$file"` (exact string match)
- `require_regex FILE PATTERN` — `grep -Eq -- "$pattern" "$file"` (extended regex)
- `require_absent_regex FILE PATTERN` — fails if match found
- `require_any_fixed FILE NEEDLE...` — passes if any needle matches

Existing guard patterns for reference (FND-01/MOT-01 mirror shape):
- Tailwind guards: bash conditional + `grep -E ... | grep -qv ...` with detailed failure message
- z-index guard: `perl -0ne '...'` multi-line script for context-aware detection
- Motion guards: single `grep -qE` per antipattern

**Three new guards shape (RES-04):**

Guard A — Spacing-literal ban (no raw `px` on `padding`/`margin`/`gap` in `app.css` outside allowlist):
```bash
# Phase 193 CSS source guards (RES-04)
spacing_literal_hit=$(
  perl -0ne '
    # Skip theme-exception and font-face blocks
    while (/([^\n]+)\n/g) {
      my $line = $1;
      next if $line =~ /\/\*/;  # inline comment lines
      next if $line =~ /ax-spacing-exception:/;
      if ($line =~ /\b(padding|margin|gap)\s*:[^;]*\b(\d+)px\b/ && $line !~ /var\(--ax-/) {
        print "$2\n";
        last;
      }
    }
  ' "$app_css"
)
[[ -z "$spacing_literal_hit" ]] || fail "$app_css must not use raw px spacing outside --ax-space-* tokens (RES-04 spacing-literal guard)"
```

Guard B — `:focus-visible` enforcement (focus styles must target `:focus-visible`, not `:focus`):
```bash
focus_ring_hit=$(
  grep -Eqn ':focus\b[^-]' "$app_css" | grep -v ':focus-visible' | head -n 1 || true
)
[[ -z "$focus_ring_hit" ]] || fail "$app_css contains :focus selector without :focus-visible (RES-04 focus-visible guard)"
```

Guard C — Truncation without `min-width:0` (`overflow:hidden` / `text-overflow:ellipsis` / `truncate` without `min-width:0` sibling):
```bash
truncation_hit=$(
  perl -0ne '...' "$app_css"  # context-aware: check block containing text-overflow: ellipsis also has min-width: 0
)
[[ -z "$truncation_hit" ]] || fail "$app_css has truncation without min-width:0 in the same block (RES-04 truncation guard)"
```

The exact guard implementation details are discretionary for the planner — the pattern is: grep/perl + `head -n 1 || true` + `[[ -z ... ]] || fail`.

### `PackageDocsVerifierTest.seed_tmp_dir!` — D-08 coupling invariant

**File:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

The `seed_tmp_dir!` function (lines 665–712) copies specific files using `copy_fixture!/2` into the temp directory. Every file referenced by a `require_fixed` needle in the script MUST be copied here, or the negative tests fail (they use `ROOT_DIR=tmp_dir` to force the script to check the temp tree).

**For Phase 193 additions, `seed_tmp_dir!` needs these new `copy_fixture!` calls:**

```elixir
# Add inside seed_tmp_dir! after the existing accrue_admin/guides copies:
File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/guides"))  # already exists
copy_fixture!("accrue_admin/guides/spec-overview.md", tmp_dir)
copy_fixture!("accrue_admin/guides/spec-list.md", tmp_dir)
copy_fixture!("accrue_admin/guides/spec-detail.md", tmp_dir)
```

**Why the test tree must also mirror the mix.exs needles:** The script checks `require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-overview.md"'` — but `seed_tmp_dir!` already copies `accrue_admin/mix.exs`. So once the real `mix.exs` is updated with the spec extras, `seed_tmp_dir!` automatically picks up the updated version via `copy_fixture!`. The only new entries needed are the three spec guide files themselves.

**NOTE on `guides/motion.md`:** Line 703 of the test already copies `copy_fixture!("accrue_admin/guides/motion.md", tmp_dir)` — this confirms the established pattern. The motion.md needle is `require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/motion.md"'` (line 519 of the script). Exactly the same shape must be used for the three spec guides.

### Forward-only baseline machinery — confirmed schema

**File:** `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json`

Confirmed `cell_id` schema:
```
{prefix}__{surface}__{mode}__{theme}__{state}__{dimension}
Example: "p187__app-shell__chromium-desktop__dark__default-populated__d01"
```

Fields per cell: `cell_id`, `surface`, `surface_type` (component/group), `mode`, `viewport_width`, `theme`, `state`, `dimension`, `dimension_name`, `score`, `coverage_status`, `evidence_refs`, `notes`, `targeted_label`, `breakpoint`.

**New page-flow cells use:** `surface_type: "page-flow"` with `surface` = route slug (e.g. `"dashboard"`, `"subscriptions-list"`, `"subscription-detail"`).

The `phase191-page-flow-helpers.js` already imports from `./baseline-manifest.js` and filters `surface.surface_type === "page-flow"` in `phase191PageFlows()`. The additive sibling `baseline.page-flow.cells.json` file must be merged at gate time with the existing `baseline.cells.json` to compute the union baseline for `regressions.ndjson`.

**Baseline storage location:** The CONTEXT.md says "additive sibling" — the v1.53 baseline lives at `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json`. The new file goes at the same directory: `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json`.

### Page-flow Playwright driver — confirmed assertions

**File:** `accrue_admin/e2e/phase191-page-flow-helpers.js`

Confirmed exported assertions (the ones D-05 and D-11/SPEC-DETAIL reference):

| Function | Signature | What it proves |
|---|---|---|
| `assertTopPointerTarget(locator, label?)` | locator = Playwright locator | Element is the topmost hit-testable element at its center point — proves overlay is NOT painted behind scrim |
| `assertScrollReachable(locator, label?)` | locator = scroll container | Container can actually scroll (scrollTop/scrollLeft changes) |
| `assertNoHorizontalClip(page, selector?, label?)` | page-wide | No element extends outside viewport bounds |
| `assertFocusWithin(page, target, label?)` | target = CSS selector or locator | `document.activeElement` is contained within the target element |
| `assertNoBodyFocus(page, label?)` | — | `document.activeElement !== document.body` |

**For D-05 overlay spike proof (Playwright hit-test):** Use `assertTopPointerTarget` on the overlay's primary action button while the scrim is present. Wrap the shell in a `transform:translateZ(0)` ancestor in a test fixture and assert the portal still escapes (portal element is inside `#ax-overlay-root` which is a direct child of `<body>`, outside the transformed ancestor).

**`setPhase191Theme(page, theme)` confirmed** (line 119–131): sets `document.documentElement.setAttribute("data-theme", value)` and `localStorage.setItem("accrue_admin_theme", value)`.

### `accrue_admin/mix.exs` — docs/0 confirmed structure

**File:** `accrue_admin/mix.exs`

Current `extras` (lines 65–70):
```elixir
extras: [
  "README.md",
  "guides/admin_ui.md",
  "guides/local_demo.md",
  "guides/core-admin-parity.md",
  "guides/theme-exceptions.md",
  "guides/motion.md"
],
```

Current `groups_for_extras` (lines 73–80):
```elixir
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

**For Phase 193** add to `extras` and `Guides:` (after `"guides/motion.md"`):
```elixir
"guides/spec-overview.md",
"guides/spec-list.md",
"guides/spec-detail.md",
```

`package.files` is `~w(lib config guides priv/static mix.exs README* LICENSE* CHANGELOG*)` — `guides/` is already included, so all three spec files are automatically in the published tarball.

`skip_code_autolink_to` pattern already covers `^AccrueAdmin\.Dev\.` — the new Storybook backend module `AccrueAdmin.Dev.Storybook` is pre-covered.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Story authoring boilerplate | 14 hand-written per-variant stories | `AccrueAdmin.Storybook.RegistryStory.variations_for/1` generator | Registry already encodes `specimens`/`applicable_states`/`props`/`content`; generator is O(1) for new families |
| Storybook dark-mode CSS | Custom LiveView hook to mirror `data-theme` attribute | CSS shim Option A: `.psb-sandbox.accrue-admin.ax-theme-dark-shim { same --ax-* dark custom-property values }` | CSS shim is zero JS, purely additive, lives only in `storybook.css`, never in the shipped bundle |
| Overlay focus containment | Hand-roll Tab/Escape/focusin loop | Reuse shipped `FocusTrap` hook verbatim | Already battle-tested with edge cases (disabled elements, `aria-hidden`, `tabindex="-1"`, async initial-focus, fallback targets) |
| Page-flow visual regression | Pixel-diff snapshots (`toHaveScreenshot`) | `assertTopPointerTarget` / `assertScrollReachable` / rubric-scored cells | Pixel-diff flags every intentional v1.54 improvement as a regression |
| Custom Storybook asset pipeline | Tailwind/esbuild integration | Committed-bundle `AccrueAdmin.Assets` route serving | accrue_admin has no Tailwind; editing source ships nothing until rebuilt+committed — Phase 189 footgun |

---

## Spike Plans — Implementation-Ready

Each spike resolves one of the four D-05/D-17 recorded decisions (RES-03). Each spike MUST produce a recorded decision artifact per RES-03.

### Spike A — Overlay portal vs native `<dialog>` (D-05)

**What to prove:** Portal markup at `#ax-overlay-root` (direct body child) is hit-testable above its scrim across desktop+mobile × light/dark, survives LiveView navigation, locks body scroll without gutter jump, and escapes transformed ancestors.

**Test fixture setup:**
1. Render `detail_drawer.ex` with `@open={true}` on a real admin route (subscriptions list or detail — has both scrim and interactive content).
2. Playwright test calls `assertTopPointerTarget(page.locator('[role=dialog] .ax-button').first(), "drawer primary action")` while scrim div is present.
3. Verify `document.getElementById("ax-overlay-root")` is a direct child of `<body>` (or the portal mechanism attaches there).
4. LiveView navigation: navigate to another route with the drawer open; assert `document.getElementById("ax-overlay-root")` is present exactly once and contains no stale content.
5. Scroll lock: capture `document.querySelector('.ax-page-header').getBoundingClientRect().top` before/after drawer open; assert delta == 0 (no scrollbar-gutter jump).
6. Transformed-ancestor: inject `data-test-transform` style `transform: translateZ(0)` on the LiveView root via `page.evaluate`, open drawer, assert `assertTopPointerTarget` passes.

**Provenance artifact (RES-03):** `accrue_admin/e2e/spike-overlay-portal.spec.js` with all four assertions green + a comment block `/* D-05 recorded decision: portal primary (A) — transformed-ancestor probe PASSED/FAILED */`.

**Decision tree:**
- All four green → record D-01 confirmed, proceed with portal
- Proof 4 fails → record D-02 trigger condition; flag for Phase 199 per-surface fallback; D-01 still primary for all other surfaces

### Spike B — Storybook `data-theme` dark-mode shim (D-17)

**What to prove:** The CSS Option A shim (`color_mode_sandbox_dark_class: "ax-theme-dark-shim"` + `.psb-sandbox.accrue-admin.ax-theme-dark-shim { /* --ax-* dark block */ }`) correctly activates accrue_admin dark tokens inside the Storybook sandbox.

**Implementation:**
1. In `storybook.css`, after the main `accrue_admin.css` content, add:
   ```css
   /* Storybook-only dark-mode shim (D-17) */
   /* Bridges Storybook's class-based sandbox toggle to accrue_admin's [data-theme="dark"] attribute scoping */
   .psb-sandbox.accrue-admin.ax-theme-dark-shim {
     /* Mirror the [data-theme="dark"] token block from theme.css verbatim */
     --ax-base: ...;
     /* ... all dark custom-property values ... */
   }
   ```
2. Playwright assertion: toggle Storybook color mode to dark; `page.evaluate(() => getComputedStyle(document.querySelector('.psb-sandbox')).getPropertyValue('--ax-base'))` must return the dark token value, not the light one.

**Provenance artifact (RES-03):** Comment in `storybook.css` shim block: `/* D-17 spike B: CSS shim — class→attribute bridge; Option B JS hook not needed */`.

**MEDIUM-confidence risk:** Selector specificity conflict if `.psb-sandbox.accrue-admin.ax-theme-dark-shim` has lower specificity than accrue_admin's `html.accrue-admin[data-theme="dark"]` in the concatenated bundle. The shim MUST appear AFTER the main bundle in `storybook.css` and MUST target `.psb-sandbox` (which is the sandbox wrapper Storybook adds) rather than `html`. If this fails, fall back to Option B (JS hook sets `data-theme` attribute on the sandbox element).

### Spike C — `inert` vs `aria-hidden` browser-floor (D-17)

**What to prove:** `inert` attribute on the background (non-overlay content) is safe at the accrue_admin browser floor.

**Browser-floor research:** [ASSUMED] `inert` is supported in Chrome 102+, Firefox 112+, Safari 15.5+. accrue_admin targets modern browsers (no IE legacy requirement per CLAUDE.md). Elixir 1.17+ / Phoenix 1.8+ users are on modern browsers.

**Implementation:** In the overlay primitive, add `inert` attribute to the app shell content when an overlay opens. The `FocusTrap` hook already handles keyboard navigation within the overlay; `inert` prevents pointer events and Tab reaching background content.

**Provenance artifact (RES-03):** Comment in `ScrollLock` hook (or the new portal hook): `/* D-17 spike C: inert chosen over aria-hidden+focusguard — browser floor satisfied */`.

**Fallback:** If `inert` causes issues, use `aria-hidden="true"` + the existing `FocusTrap` focusin handler (already traps Tab-out). The `FocusTrap` hook already handles `isHidden` via `aria-hidden` check in `isFocusable()`.

### Spike D — Storybook asset serving without Tailwind rebuild (D-17)

**What to prove:** `storybook.css` (committed bundle = `accrue_admin.css` + dark shim + PhoenixStorybook sandbox CSS) and `storybook.js` (PhoenixStorybook required JS) are served correctly via the `AccrueAdmin.Assets`-style routes and render the lab with shipped styles.

**Implementation:**
1. Create `storybook.css` by concatenating: PhoenixStorybook's required sandbox CSS + committed `accrue_admin.css` content + dark-mode shim.
2. Create `storybook.js` by extracting PhoenixStorybook's required client JS (from `deps/phoenix_storybook/priv/static/`).
3. In `AccrueAdmin.Assets`, add `@storybook_css_file` / `@storybook_js_file` module attributes (same `Application.app_dir` + `File.read!` + `@external_resource` + md5 hash pattern).
4. Register dev-only routes in `wrap_with_storybook_dev_routes`: `get("/assets/storybook-css-#{@storybook_css_hash}", AccrueAdmin.Assets, :storybook_css)` inside the same scoped block.
5. Configure Storybook backend: `css_path: "#{mount_path}/assets/storybook-css-#{AccrueAdmin.Assets.storybook_css_hash()}"`.

**Provenance artifact (RES-03):** The passing PoC story render in `mix accrue_admin.e2e.server` + Playwright navigation to `/dev/storybook`.

---

## Common Pitfalls

### Pitfall 1: `verify_package_docs.sh` needle without `seed_tmp_dir!` mirror (D-08)

**What goes wrong:** Adding a `require_fixed "accrue_admin/guides/spec-overview.md"` needle to the script works in the standalone run. But `PackageDocsVerifierTest` runs the script with `ROOT_DIR` set to a temp dir built by `seed_tmp_dir!`. If `spec-overview.md` is not copied into the temp dir, the script exits with "missing needle" for the WRONG reason (file not found, not drift detection). All 6 negative tests fail because the script exits early.

**How to avoid:** ALWAYS add the corresponding `copy_fixture!("accrue_admin/guides/spec-overview.md", tmp_dir)` call to `seed_tmp_dir!` in the same commit as the script needle. The three spec guides + the `accrue_admin/mix.exs` needles: mix.exs is already copied (line 695 of the test); only the three new guide files need new `copy_fixture!` calls.

**Warning signs:** All 6 negative tests fail simultaneously with `[verify_package_docs] package docs verification failed: accrue_admin/guides/spec-overview.md is missing: ## SPEC-OVERVIEW` even for tests that aren't about spec-overview.

### Pitfall 2: `import PhoenixStorybook.Router` at module scope (D-13)

**What goes wrong:** Placing `import PhoenixStorybook.Router` at the router module's top level causes the import to execute during host `:prod` compile where `phoenix_storybook` is absent, breaking host builds.

**How to avoid:** The import MUST be inside the `true`-arm `quote bind_quoted:` block, exactly like the Mailglass pattern. Confirmed from `router.ex` lines 123–128: `import MailglassAdmin.Router` is inside `quote bind_quoted: [mount_path: mount_path] do ... end` inside `wrap_with_mailglass_dev_routes(base_ast, true, mount_path)`.

**Warning signs:** Host app `mix compile` fails with `(UndefinedFunctionError) function PhoenixStorybook.Router.live_storybook/2 is undefined` in `:prod` environment.

### Pitfall 3: `storybook/` story files under `lib/` (D-13)

**What goes wrong:** Story `.exs` files under `lib/` get included in the published Hex tarball (because `package.files` includes `lib`) and compile into `:prod` builds. The `content_path` resolution in `:prod` breaks.

**How to avoid:** Stories go in top-level `storybook/` directory. `package.files = ~w(lib config guides priv/static ...)` does NOT include `storybook/`, so stories are auto-excluded.

**Warning signs:** `mix hex.build` includes files from `storybook/`.

### Pitfall 4: Editing `storybook.css` source without rebuilding + committing (Phase 189 repeat)

**What goes wrong:** `AccrueAdmin.Assets` serves the COMMITTED bundle from `priv/static/storybook.css`. Editing the CSS source ships nothing until `mix accrue_admin.assets.build` (or equivalent) is run and the result committed.

**How to avoid:** The `storybook.css` rebuild must be part of the Phase 193 asset-build workflow. The `@external_resource @storybook_css_file` declaration in `AccrueAdmin.Assets` ensures a recompile happens when the committed file changes — but the file must be rebuilt first.

**Warning signs:** Storybook renders with wrong styles; `AccrueAdmin.Assets.storybook_css_hash()` returns a stale value.

### Pitfall 5: `variations_for/1` calling registry functions at story eval time

**What goes wrong:** `.story.exs` files are evaluated, not compiled. If `RegistryStory.variations_for/1` is placed inline in the `.exs` rather than in a compiled `.ex` module, the function call happens at story eval time with no compile-time guarantees.

**How to avoid:** `RegistryStory` MUST be a compiled `.ex` file at `storybook/_support/registry_story.ex` (not `.exs`). The `.story.exs` shims call into it: `def variations, do: AccrueAdmin.Storybook.RegistryStory.variations_for("button")`.

### Pitfall 6: Three spec guides wired to `extras` but not `groups_for_extras`

**What goes wrong:** Guides added to `extras` but missing from `groups_for_extras` appear under "Pages" in ExDoc, not under "Guides." The `verify_package_docs.sh` needle `require_fixed ... 'Guides:'` passes (Guides key still present), but the spec guides are not grouped with the other guides.

**How to avoid:** Add all three spec guide paths to both `extras` and to the `Guides:` list in `groups_for_extras`.

---

## State of the Art (relevant changes)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `motion.md` as the only shipped guide with CI needle | motion.md + three archetype spec guides (Phase 193) | Phase 193 | Establishes the multi-spec pattern for v1.54 propagation phases |
| Kitchen (`/dev/components`) as sole component renderer | Kitchen + PhoenixStorybook as second renderer | Phase 193 | Registry stays SSOT; Storybook is additive |
| `baseline.cells.json` with component/group surface types only | + `baseline.page-flow.cells.json` with page-flow cells | Phase 193 | Extends the zero-regression gate to cover composed routes |
| No scroll-lock hook | New `ScrollLock` hook (Phase 193 spike records) | Phase 193 | Unblocks Phase 199's body scroll-lock fix |

---

## Validation Architecture

> `workflow.nyquist_validation` is enabled (not explicitly disabled in `.planning/config.json`). This section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework (Elixir) | ExUnit (mix test) |
| Framework (E2E) | Playwright (`mix accrue_admin.e2e.server` + `npx playwright test`) |
| Config file | `accrue_admin/playwright.config.js` |
| Quick Elixir run | `mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` |
| Full Elixir suite | `cd accrue && mix test` |
| Quick E2E | `npx playwright test accrue_admin/e2e/admin-page-flow-phase191.spec.js` |
| Full E2E | `npx playwright test` |
| Source guard | `bash scripts/ci/verify_package_docs.sh` |

### Phase Requirements → Validation Map

| Req ID | Behavior | Test Type | Mechanism | File Exists? |
|--------|----------|-----------|-----------|-------------|
| RES-01 | Three spec guides exist with anchor headings | Source guard | `require_fixed` needles in `verify_package_docs.sh` | Guides: NEW in Phase 193 |
| RES-01 | Three spec guides wired in mix.exs extras + groups | Source guard | `require_fixed` needle for `"guides/spec-overview.md"` in mix.exs | mix.exs: ✅ (to be updated) |
| RES-01 | PackageDocsVerifierTest mirrors new needles | Unit test | `seed_tmp_dir!` includes three spec guide files | ✅ wave 0 gap |
| RES-02 | `baseline.page-flow.cells.json` exists with page-flow cells | File existence + schema | Manual/judge verification; gates via `regressions.ndjson` | NEW in Phase 193 |
| RES-02 | Additive baseline gated by zero-regression rule | E2E | `regressions.ndjson` gate remains zero-regression | Existing gate: ✅ |
| RES-03 | Overlay portal hit-test passes four D-05 proofs | E2E | `accrue_admin/e2e/spike-overlay-portal.spec.js` | NEW in Phase 193 |
| RES-03 | Dark-mode shim activates correct tokens in sandbox | E2E/manual | Playwright evaluate `getComputedStyle` on `.psb-sandbox` in dark mode | NEW in Phase 193 |
| RES-03 | `inert` browser-floor confirmed | Manual + code comment | Comment in portal hook source | NEW in Phase 193 |
| RES-03 | Storybook assets served correctly (PoC story renders) | E2E/manual | Playwright navigates to `/dev/storybook` and button story visible | NEW in Phase 193 |
| RES-04 | Spacing-literal guard blocks raw px in app.css | Source guard (negative) | New `require_absent_regex`-style perl guard in `verify_package_docs.sh` | Script: existing, NEW guard |
| RES-04 | `:focus-visible` guard | Source guard | New grep guard | Script: existing, NEW guard |
| RES-04 | Truncation-without-min-width guard | Source guard | New perl guard | Script: existing, NEW guard |
| RES-04 | PackageDocsVerifierTest negative tests for 3 new guards | Unit test | 3 new test cases in `package_docs_verifier_test.exs` | ✅ wave 0 gap |
| STY-01 | `phoenix_storybook` in mix.exs `only: [:dev, :test]` | Source guard | `require_fixed "accrue_admin/mix.exs" ':phoenix_storybook'` | mix.exs: NEW |
| STY-01 | `Code.ensure_loaded?` guard present in router | Source guard / grep | `grep -q "Code.ensure_loaded?(PhoenixStorybook.Router)"` | router.ex: NEW |
| STY-01 | Host dev compile with dep absent succeeds | Compile test | `cd examples/accrue_host && MIX_ENV=dev mix compile` + assert no `/dev/storybook` route | NEW in Phase 193 |
| STY-01 | Host prod compile with dep absent succeeds | Compile test | `cd examples/accrue_host && MIX_ENV=prod mix compile` | NEW in Phase 193 |

### Sampling Rate

- **Per task commit:** `bash scripts/ci/verify_package_docs.sh` (fast, < 5s)
- **Per wave merge:** `cd accrue && mix test accrue/test/accrue/docs/package_docs_verifier_test.exs`
- **Phase gate:** Full `mix test` green + `bash scripts/ci/verify_package_docs.sh` green + host compile tests passing + PoC story renders in Storybook

### Wave 0 Gaps

- [ ] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add `seed_tmp_dir!` copies for 3 spec guides
- [ ] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add 3 negative tests for new CSS guards (spacing-literal, focus-visible, truncation)
- [ ] `accrue_admin/e2e/spike-overlay-portal.spec.js` — new overlay hit-test spec (4 proofs per D-05)
- [ ] Host-absence compile test — `examples/accrue_host` dev+prod compile assertions

---

## Security Domain

> `security_enforcement` is not explicitly disabled. Phase 193 is configuration/documentation/test-only — no new network-accessible routes in production, no new data handling, no new auth pathways.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Storybook routes are dev-only and inherit `:accrue_admin_browser` pipeline (includes `protect_from_forgery`) |
| V3 Session Management | No | No new session state |
| V4 Access Control | Partial | Storybook must not be accessible in prod — enforced by `Code.ensure_loaded?` + `if Mix.env() != :prod` backend guard |
| V5 Input Validation | No | No user input; spec guides are static markdown |
| V6 Cryptography | No | No new crypto — md5 hashes are for cache-busting only, not security |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Storybook leaking to host prod build | Information Disclosure | `Code.ensure_loaded?(PhoenixStorybook.Router)` + `if Mix.env() != :prod` backend guard |
| Story files in Hex tarball | Information Disclosure | `storybook/` excluded from `package.files` allowlist |
| Dev tools exposed in production | Elevation of Privilege | `dev_routes?` computed as `Mix.env() != :prod`; guard is host-compile-time, not runtime toggle |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `inert` attribute is safe at accrue_admin's browser floor (Chrome 102+, Firefox 112+, Safari 15.5+) | Spike C | Could require `aria-hidden`+focusguard fallback instead; FocusTrap hook already provides focusin containment as fallback |
| A2 | PhoenixStorybook `%Variation{id:, attributes:, slots:, description:}` struct fields are stable in 1.2.x | Standard Stack | May need field name adjustment; low risk — stable across 1.x per research |
| A3 | `baseline-manifest.js` (imported by `phase191-page-flow-helpers.js`) exports a `SURFACES` array that the new page-flow cells can be added to or supplemented alongside | RES-02 validation | Could require a different approach to registering page-flow surfaces; module is existing in-repo |

---

## Open Questions

1. **`storybook.css` build tooling: how to regenerate?**
   - What we know: `mix accrue_admin.assets.build` rebuilds `accrue_admin.css`/`.js`. Storybook's PhoenixStorybook sandbox CSS is in `deps/phoenix_storybook/priv/static/`.
   - What's unclear: Whether to extend `accrue_admin.assets.build` task to also produce `storybook.css`, or use a separate Mix task.
   - Recommendation: Add a `mix accrue_admin.storybook.build` task that concatenates: psb static CSS + `priv/static/accrue_admin.css` + dark shim CSS. Documented in guides, not run automatically.

2. **Baseline merge tooling: where does the merge gate live?**
   - What we know: `regressions.ndjson` gate runs over `baseline.cells.json`. Adding `baseline.page-flow.cells.json` requires the gate to load both files.
   - What's unclear: Whether `admin-baseline.spec.js` already supports loading multiple baseline files or needs a union-merge step.
   - Recommendation: Planner should inspect `admin-baseline.spec.js` to determine how to wire the additive sibling; may require a small merge helper function.

3. **`RegistryStory` module location in Mix elixirc_paths:**
   - What we know: `elixirc_paths(:test)` returns `["lib", "test/support"]`; `elixirc_paths(_env)` returns `["lib"]`.
   - What's unclear: `storybook/_support/registry_story.ex` is NOT under `lib/` — it will NOT be compiled automatically.
   - Recommendation: Add `storybook/_support` to `elixirc_paths(:dev)` → `["lib", "storybook/_support"]`. This is a concrete mix.exs change the planner must include. The `.exs` story shims call `AccrueAdmin.Storybook.RegistryStory` which must exist as a compiled module.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `phoenix_storybook` hex dep | STY-01 Storybook scaffold | Not yet (NEW dep) | 1.2.0 from hex.pm | N/A — must be added |
| PhoenixStorybook sandbox CSS/JS | `storybook.css` / `storybook.js` build | After `mix deps.get` | In `deps/phoenix_storybook/priv/static/` | N/A |
| Playwright + Node.js | E2E overlay spike proof (RES-03) | Existing (Phase 191 harness) | As per `playwright.config.js` | N/A — already required |
| `examples/accrue_host` compile | STY-01 host-absence test | Existing demo host | As per `examples/accrue_host/mix.exs` | N/A |

---

## Sources

### Primary (HIGH confidence — verified against current code)

- `accrue_admin/lib/accrue_admin/router.ex` — Mailglass sibling-scope precedent, `dev_routes?` computation, pipeline name, wrap-chain site (lines 107–138)
- `accrue_admin/lib/accrue_admin/assets.ex` — committed-bundle serving mechanism, `File.read!` + `@external_resource` + md5 + content-hash routes, `hashed_path/2` kinds
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` — `:if={@open}` + `phx-mounted`/`phx-remove` + `FocusTrap` shape, motion class names, R-3 geometry bug confirmed
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` — second overlay shell, `JS.push_focus()`/`pop_focus()` lifecycle
- `accrue_admin/assets/js/hooks/focus_trap.js` — full hook API, `isFocusTrapActive`, `dispatchFocusTrapClose`, `scheduleInitialFocus`, `restoreFocus`
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — `if Mix.env() != :prod` guard, `@type entry`, `@type group_contract`, public API
- `accrue_admin/mix.exs` — current `extras`/`groups_for_extras` shape, `package.files`, `skip_code_autolink_to`, `elixirc_paths`
- `scripts/ci/verify_package_docs.sh` — `require_fixed`/`require_regex`/`require_absent_regex` API, existing guard patterns
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — `seed_tmp_dir!` full implementation, `copy_fixture!/2` pattern, test structure
- `accrue_admin/e2e/phase191-page-flow-helpers.js` — confirmed `assertTopPointerTarget`/`assertScrollReachable`/`assertFocusWithin`/`assertNoHorizontalClip` signatures
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` — confirmed cell schema (`cell_id` format, all field names)
- `.planning/research/SUMMARY.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `v1.54-storybook-and-forward-only-qa.md` — prior research corpus synthesized into CONTEXT.md decisions

### Secondary (MEDIUM confidence)

- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` — locked decisions D-01..D-17, canonical refs, code context
- `.planning/REQUIREMENTS.md` — RES-01..RES-04, STY-01 requirement text

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `phoenix_storybook 1.2.0` verified by prior research; all other deps existing
- Architecture patterns: HIGH — verified against actual code; no drift detected in primary canonical refs
- Code verification: HIGH — all six canonical code files read and confirmed
- CSS guard implementation: MEDIUM — guard shapes confirmed from existing guards; exact perl/grep expressions require implementation iteration
- `RegistryStory` `elixirc_paths` issue: HIGH — confirmed from mix.exs; concrete fix identified

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (30 days; stable stack)
