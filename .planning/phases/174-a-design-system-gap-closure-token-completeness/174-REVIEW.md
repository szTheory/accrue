---
phase: 174-a-design-system-gap-closure-token-completeness
reviewed: 2026-06-03T21:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/css/theme.css
  - accrue_admin/lib/accrue_admin/components/dunning_banner.ex
  - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
  - accrue_admin/lib/accrue_admin/dev/component_registry.ex
  - accrue_admin/test/accrue_admin/components/dunning_banner_test.exs
  - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 174-A: Code Review Report

**Reviewed:** 2026-06-03T21:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

This phase delivers: (1) the CSS design-token foundation for `ax-banner`/`ax-banner-danger` classes used by the headless `DunningBanner` component, (2) a `ComponentRegistry` cataloguing variant→token relationships for four component families, (3) the `ComponentKitchenLive` dev page that renders all variants, (4) tests for both the registry and the dunning banner, and (5) a CI guard in `verify_package_docs.sh` that rejects unguarded breakpoint `@media` rules in `app.css`.

Two blockers were found: the `ComponentRegistry` documents phantom tokens (`--ax-neutral`, `--ax-ink`, `--ax-neutral-readable`, `--ax-ink-readable`) that are not defined anywhere in the design system — the actual CSS uses different tokens for those variants. Additionally, `seed_tmp_dir!` in the package-docs verifier tests does not copy `examples/accrue_host/docs/adoption-proof-matrix.md`, which the verifier script reads at line 304, silently neutering that guard in all negative-path test runs.

Four warnings cover: duplicate CSS rule blocks for `.ax-kpi-card`, a second (overriding) definition block for `.ax-command-palette-item`, a misleading indentation in the shell `for` loop, and the cobalt-family token mismatch (`--ax-info` vs. the actual `--ax-accent` used by `.ax-status-badge-cobalt` and `.ax-kpi-delta-cobalt`).

---

## Critical Issues

### CR-01: ComponentRegistry documents tokens that do not exist in the design system

**File:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex:82-89, 123-130`
**Issue:** The `status/slate` and `card/slate` entries list `--ax-neutral` and `--ax-neutral-readable`; the `status/ink` and `card/ink` entries list `--ax-ink` and `--ax-ink-readable`. None of these four tokens are defined anywhere in `theme.css` or `app.css`. The actual CSS for those variants uses `--ax-border`, `--ax-muted`, and `--ax-primary`:

```css
/* .ax-status-badge-slate (app.css:1073) */
background: color-mix(in srgb, var(--ax-border) 50%, var(--ax-elevated));
color: var(--ax-muted);

/* .ax-status-badge-ink (app.css:1078) */
background: color-mix(in srgb, var(--ax-primary) 10%, var(--ax-elevated));
color: var(--ax-primary);

/* .ax-kpi-delta-slate / .ax-kpi-delta-ink (app.css:658) */
color: var(--ax-primary);
background: color-mix(in srgb, var(--ax-muted) 12%, transparent);
```

The registry's purpose is to serve as the ground-truth token→component map for drift detection (DSY-03). Phantom tokens mean the registry is lying: it will never catch a real drift on slate/ink variants because the tokens it tracks (`--ax-neutral`, `--ax-ink`) are not the ones actually driving those styles.

**Fix:**

```elixir
# status/slate
%{
  family: "status",
  variant: "slate",
  ax_class: "ax-status-badge ax-status-badge-slate",
  tokens: ["--ax-border", "--ax-muted", "--ax-elevated"]
},
# status/ink
%{
  family: "status",
  variant: "ink",
  ax_class: "ax-status-badge ax-status-badge-ink",
  tokens: ["--ax-primary", "--ax-elevated"]
},
# card/slate
%{
  family: "card",
  variant: "slate",
  ax_class: "ax-kpi-delta ax-kpi-delta-slate",
  tokens: ["--ax-primary", "--ax-muted", "--ax-transition-colors"]
},
# card/ink
%{
  family: "card",
  variant: "ink",
  ax_class: "ax-kpi-delta ax-kpi-delta-ink",
  tokens: ["--ax-primary", "--ax-muted", "--ax-transition-colors"]
}
```

---

### CR-02: `seed_tmp_dir!` missing `examples/accrue_host/docs/adoption-proof-matrix.md`, silently disabling verifier guard in all negative tests

**File:** `accrue/test/accrue/docs/package_docs_verifier_test.exs:276-311`
**Issue:** `verify_package_docs.sh` line 304 reads:

```bash
require_absent_regex "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" \
  'Stripe-only|remain Stripe-only'
```

`seed_tmp_dir!` never calls `copy_fixture!("examples/accrue_host/docs/adoption-proof-matrix.md", tmp_dir)` and never creates the `examples/accrue_host/docs/` directory. When the verifier runs inside a negative test's `tmp_dir`, `grep` on the missing file exits with code 2 (file not found). Because `require_absent_regex` wraps `grep` inside an `if` condition, bash's `set -e` is suppressed, the `if` evaluates to false (grep did not match), and the function returns without failing. The guard passes silently as if the file contained nothing forbidden.

This means the "Stripe-only" regression guard is completely unenforced in CI's test-based verification path. A PR that reintroduces "Stripe-only" wording into `adoption-proof-matrix.md` will not be caught by the package-docs verifier tests.

The positive test (`"package docs verifier succeeds"`) is unaffected because it runs against the real repo (no `ROOT_DIR` override).

**Fix:**

```elixir
defp seed_tmp_dir!(tmp_dir) do
  # add this directory creation:
  File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host/docs"))

  # ... existing copies ...

  # add this copy:
  copy_fixture!("examples/accrue_host/docs/adoption-proof-matrix.md", tmp_dir)
end
```

---

## Warnings

### WR-01: ComponentRegistry cobalt-family entries list `--ax-info` but actual CSS uses `--ax-accent`

**File:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex:68-72, 108-113`
**Issue:** Both the `status/cobalt` and `card/cobalt` registry entries list `--ax-info` and `--ax-info-readable` as their tokens. The actual CSS for these classes uses `--ax-accent` and `--ax-accent-readable`, not the info-blue tokens:

```css
/* .ax-status-badge-cobalt (app.css:1063) */
background: color-mix(in srgb, var(--ax-accent) 14%, var(--ax-elevated));
color: var(--ax-accent-readable);

/* .ax-kpi-delta-cobalt (app.css:648) */
color: var(--ax-accent-readable);
background: color-mix(in srgb, var(--ax-accent) 16%, transparent);
```

This is a documentation/drift-detection accuracy issue: "cobalt" in the component vocabulary means the interactive-accent color (the brand blue), not the `--ax-info` teal-blue. The registry will fail to detect accent token substitution in cobalt variants.

**Fix:**
```elixir
# status/cobalt
tokens: ["--ax-accent", "--ax-accent-readable", "--ax-elevated"]

# card/cobalt
tokens: ["--ax-accent", "--ax-accent-readable", "--ax-transition-colors"]
```

---

### WR-02: Duplicate `.ax-command-palette-item` rule block — Phase 169 addition overrides layout without merging

**File:** `accrue_admin/assets/css/app.css:1551-1558, 2022-2026`
**Issue:** `.ax-command-palette-item` is defined twice. The first definition (line 1551) sets `min-height`, `padding`, `border`, `border-radius`, `color`, `cursor`. The second definition (line 2022, added in Phase 169) sets `display: flex; align-items: center; gap: var(--ax-space-sm)`. Because CSS is additive and the second rule adds properties not in the first, both are in effect — no actual property conflict exists. However, the layout property (`display: flex`) that makes the icon+label rows work is split from the sizing/spacing properties, making the rule harder to maintain. If a future edit needs to change `display` it must know to look at line 2022, not line 1551.

**Fix:** Merge the two blocks at their first definition site:
```css
.ax-command-palette-item {
  display: flex;
  align-items: center;
  gap: var(--ax-space-sm);
  min-height: 2.75rem;
  padding: 0.75rem 0.875rem;
  border: 1px solid transparent;
  border-radius: var(--ax-radius-md);
  color: var(--ax-primary);
  cursor: pointer;
}
```

---

### WR-03: Duplicate `.ax-field-label` rule block — Phase 171 addition silently overrides prior font-size

**File:** `accrue_admin/assets/css/app.css:1267-1271, 2215-2222`
**Issue:** `.ax-field-label` is defined at line 1267 (`font-size: 0.875rem; font-weight: 600; line-height: var(--ax-leading-normal)`) and again at line 2215 (`font-size: var(--ax-type-xs); font-weight: 600; color: var(--ax-muted); text-transform: uppercase; letter-spacing: var(--ax-tracking-wide)`). The second definition silently overrides `font-size` from `0.875rem` to `var(--ax-type-xs)` (which is `0.75rem`) and adds `color: var(--ax-muted)` and uppercase treatment. This means any code relying on `.ax-field-label` yielding `0.875rem` text (the first definition) is silently broken — the second definition wins everywhere.

More broadly, `.ax-field` itself also has two definitions (lines 1260 and 2209) with different `gap` values (`var(--ax-space-sm)` vs `var(--ax-space-2xs)`). The second wins for all elements that match both. This is a Phase 171 authoring artifact where a "detail field list" pattern was defined without consolidating with the earlier form-field usage of the same class name.

**Fix:** Either rename the Phase 171 variants (`ax-detail-field-label`, `ax-detail-field`) to avoid the collision, or deliberately consolidate the definitions. The current state is semantically ambiguous — `.ax-field-label` has two different intended styles.

---

### WR-04: Shell for-loop body indentation is misleading in `verify_package_docs.sh`

**File:** `scripts/ci/verify_package_docs.sh:309-311`
**Issue:** The `require_fixed` call for the `stripe:` needle (line 310) is not indented, while the surrounding lines 309 and 311 are indented by two spaces. The `done` keyword closes the loop at line 312, so line 310 IS functionally inside the loop body. However, the missing indent gives a strong visual impression that the `stripe:` check runs only once (outside the loop), when in fact it runs for every `$guide`. A future editor may believe line 310 is outside the loop and remove it or restructure without understanding the actual scope.

**Fix:** Add the two-space indent:
```bash
for guide in \
  "$ROOT_DIR/accrue/guides/first_hour.md" \
  "$ROOT_DIR/accrue/guides/troubleshooting.md"; do
  require_fixed "$guide" 'config :accrue, :webhook_signing_secrets, %{'
  require_fixed "$guide" 'stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")'
  require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
done
```

---

## Info

### IN-01: `DunningBanner` uses an `if/else` returning two separate `~H` sigils rather than a single template with a conditional

**File:** `accrue_admin/lib/accrue_admin/components/dunning_banner.ex:18-34`
**Issue:** The function body branches at the Elixir level (`if ... do ~H"""...""" else ~H"" end`) rather than using a single `~H` template with a `:if` directive. This works correctly for a stateless Phoenix function component but bypasses Phoenix's diff-tracking infrastructure. When embedded in a LiveView template, the entire banner output is regenerated on every re-render rather than being diff-tracked. The idiomatic Phoenix pattern keeps a single template and conditionally renders content within it.

**Fix:**
```elixir
def dunning_banner(assigns) do
  assigns = assign(assigns, :dunning_active?, Accrue.Dunning.requires_attention?(assigns.customer))

  ~H"""
  <div :if={@dunning_active?} class="accrue-dunning-banner-wrapper">
    <%= if @inner_block != [] do %>
      <%= render_slot(@inner_block) %>
    <% else %>
      <div class="accrue-default-dunning-banner ax-banner ax-banner-danger">
        Action Required: We were unable to process your recent payment. Please update your payment method to avoid service interruption.
      </div>
    <% end %>
  </div>
  """
end
```

---

### IN-02: `component_registry_test.exs` line 27 hardcodes assumption that every `ax_class` has exactly two space-separated tokens

**File:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs:27`
**Issue:** The pattern `[_base, variant_class] = String.split(ax_class, " ", parts: 2)` will raise `MatchError` if any registry entry ever has a single-word `ax_class` (no space). All current entries have exactly two space-separated classes, so this is not a current bug, but it is an implicit constraint with no guard or documentation.

**Fix:** Either add a comment explaining the two-class invariant, or use a more defensive pattern:
```elixir
variant_class = ax_class |> String.split(" ") |> List.last()
```
This also correctly handles the three-class case (takes only the final variant-specific class).

---

_Reviewed: 2026-06-03T21:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
