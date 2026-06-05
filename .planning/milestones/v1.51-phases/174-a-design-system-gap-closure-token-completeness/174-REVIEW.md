---
phase: 174-a-design-system-gap-closure-token-completeness
reviewed: 2026-06-03T22:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - accrue_admin/lib/accrue_admin/dev/component_registry.ex
  - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue_admin/assets/css/app.css
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 174: Code Review Report

**Reviewed:** 2026-06-03
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Scope was the phase-174 gap-closure changes (plans 174-05 phantom-token replacement +
token-validity test, 174-06 adoption-proof-matrix fixture seeding, 174-07 search-trigger
comment replacement).

Verified-correct work:
- All 16 registry tokens resolve to real CSS custom properties.
- All 15 registry `ax_class` strings match the actual rendered output of `Button`,
  `StatusBadge`, and `KpiCard` (button.ex:34-37, status_badge.ex:21, kpi_card.ex:33/50).
- Registry family counts are correct: button (4 incl. danger), status (5), card (6).
- 174-06: `examples/accrue_host/docs/adoption-proof-matrix.md` exists, is read by
  `verify_package_docs.sh:304`, and is now seeded in `seed_tmp_dir!` — the
  script-to-fixture coupling invariant is satisfied. All 28 script-read files are seeded.
- 174-07: the `.ax-search-trigger` "intentional exception" comment is accurate —
  `--ax-theme-transition`=180ms (`--ax-dur-2`) and `--ax-motion-fast`=120ms (`--ax-dur-1`)
  match theme.css:54-55,66-68; both tokens are defined.

The core concern is that the new token-validity test (174-05's primary deliverable, the
D-21 drift gate) is weaker than its docstring claims and ships with a factually wrong
allowlist — it currently passes by accident rather than by design. No correctness or
security defect in shipped runtime code; findings are about test efficacy and accuracy.

## Warnings

### WR-01: Token-validity test matches `var()` usages, not definitions — defeats the drift gate

**File:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs:83-108`

**Issue:** The token-validity test asserts each registry token "is defined in the design
system" but checks `String.contains?(theme_css, token)` / `String.contains?(app_css, token)`
against raw file text. Substring presence is satisfied by a `var(--token)` *consumption*,
not a `--token: value;` *definition*. Concretely, `--ax-accent-contrast` (registry token for
`button/primary`, component_registry.ex:34) has **no** `--ax-accent-contrast:` definition
anywhere in theme.css or app.css; it is only ever referenced as `var(--ax-accent-contrast)`
at app.css:208, 1017, 1624. The test passes solely because those usages contain the token as
a substring. A genuinely phantom token would therefore pass this gate as long as some
`var()` reference to it exists — exactly the drift case the test claims to prevent (test
comment lines 72-78). This is a false-negative hole in the D-21 enforcement the phase added.

**Fix:** Match on a definition, not bare substring. Anchor on the `--token:` declaration form:
```elixir
defined? = fn css, token ->
  # custom-property *definition*, not a var() reference
  String.contains?(css, token <> ":")
end

phantom_tokens =
  for entry <- ComponentRegistry.entries(),
      token <- entry.tokens,
      token not in known_in_layouts,
      not defined?.(theme_css, token),
      not defined?.(app_css, token) do
    {entry.family, entry.variant, token}
  end
```
Switching to definition-matching will (correctly) surface `--ax-accent-contrast` as
undefined-in-static-CSS, which makes fixing WR-02 mandatory at the same time.

### WR-02: `known_in_layouts` allowlist is factually wrong — omits the runtime-only token, includes a statically-defined one

**File:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs:87`

**Issue:** The allowlist comment (lines 80-87) states it is "for tokens defined via the
server-rendered style tag in layouts.ex rather than in a static CSS file," and lists
`["--ax-accent", "--ax-accent-readable"]`. Ground truth from `layouts.ex:79-86`
(`runtime_theme_style/1`) and the CSS files:
- `--ax-accent` — runtime-only (layouts.ex:82); **correctly** allowlisted.
- `--ax-accent-contrast` — runtime-only (layouts.ex:83), **no** static definition; this is
  the token that genuinely needs the allowlist, yet it is **missing** from it.
- `--ax-accent-readable` — **statically** defined in theme.css:127, 159, 179; it is **not**
  injected by layouts.ex at all. Including it in `known_in_layouts` is incorrect and
  misleading (the comment claims it is layout-injected; it is not).

The mislabeled allowlist masks the WR-01 hole: it tells a future maintainer that
`--ax-accent-contrast` is handled when it is not, and asserts a false fact about
`--ax-accent-readable`'s origin.

**Fix:** Make the allowlist reflect `runtime_theme_style/1` exactly, and drop the
statically-defined token:
```elixir
# Tokens injected at runtime via the <style> tag in AccrueAdmin.Layouts.runtime_theme_style/1
# (layouts.ex:82-83); they cannot be grepped from static CSS files.
known_in_layouts = ["--ax-accent", "--ax-accent-contrast"]
```
(`--ax-accent-readable` is removed because it resolves via theme.css under
definition-matching — keeping it allowlisted would hide future deletion of its real
definition.) Update the comment at lines 80-87 to stop claiming `--ax-accent-readable` is
layout-injected.

## Info

### IN-01: `entries/0` docstring says "four families" but only three exist

**File:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex:12-14`

**Issue:** The `@doc` reads "across the four DSY-03 families: button (4), status (5),
card (6 = base + 5 delta tones)." It says "four" but enumerates and ships only three
families (button, status, card). Stale count from an earlier design.

**Fix:** "across the three DSY-03 families: button (4), status (5), card (6 = base + 5
delta tones)."

### IN-02: Test (a) variant-substring assertion is prefix-weak — won't catch base-card drift

**File:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs:24-33`

**Issue:** Test (a) splits each `ax_class` `parts: 2` and asserts the second token appears
in the page HTML. For `card/base` the second token is `ax-kpi-card`, which is a substring of
unrelated classes always present on the page (`ax-kpi-card-header`, `ax-kpi-card-footer` at
kpi_card.ex:42,49, and `ax-kpi-card--linked` at kpi_card.ex:27). So `html =~ "ax-kpi-card"`
passes even if no actual base KPI card rendered — the drift this test exists to catch would
slip through for that entry. Same prefix-collision risk applies to any future variant whose
class is a prefix of a structural sub-element class.

**Fix:** Assert on a whole-class match rather than bare substring, e.g.
`assert html =~ ~r/\b#{Regex.escape(variant_class)}\b/`, or match `"#{variant_class}"`
within a captured `class="..."` attribute.

### IN-03: Test (a) is partially circular — registry drives both the render loop and the assertion

**File:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs:19-33`

**Issue:** The kitchen page renders families by iterating `ComponentRegistry.variants_for/1`
(component_kitchen_live.ex:161,188,211,234), and test (a) then asserts those same registry
entries appear in the output. A registry entry with a wrong `ax_class` would render that
wrong class via `entry.variant` and the test would still find its own (wrong) substring.
The test validates "registry is internally self-consistent with the page" but not "registry
matches the real component class contract." Test (b) covers that contract for the button
family only; status and card have no equivalent component-vs-registry check.

**Fix:** Acceptable for now given test (b) anchors the button family and the token-validity
test (once WR-01/WR-02 are fixed) anchors token reality. For stronger coverage, extend the
test (b) MapSet-equality pattern to status (`status_tone/1`) and card (`normalize_tone/1`)
so the registry is checked against component output rather than against a page generated
from the registry.

---

_Reviewed: 2026-06-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
