---
phase: 189-primitive-form-components-component-lab
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/css/theme.css
  - accrue_admin/e2e/admin-a11y.spec.js
  - accrue_admin/e2e/admin-interactions.spec.js
  - accrue_admin/e2e/admin-visuals.spec.js
  - accrue_admin/lib/accrue_admin/components/button.ex
  - accrue_admin/lib/accrue_admin/components/checkbox.ex
  - accrue_admin/lib/accrue_admin/components/empty_state.ex
  - accrue_admin/lib/accrue_admin/components/inline_id.ex
  - accrue_admin/lib/accrue_admin/components/input.ex
  - accrue_admin/lib/accrue_admin/components/radio.ex
  - accrue_admin/lib/accrue_admin/components/select.ex
  - accrue_admin/lib/accrue_admin/components/spinner.ex
  - accrue_admin/lib/accrue_admin/components/textarea.ex
  - accrue_admin/lib/accrue_admin/components/toggle.ex
  - accrue_admin/lib/accrue_admin/components/tooltip.ex
  - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
  - accrue_admin/lib/accrue_admin/dev/component_registry.ex
  - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 1
  warning: 7
  info: 3
  total: 11
status: issues_found
---

# Phase 189: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Reviewed the Phase 189 primitive form components (Input, Textarea, Checkbox,
Radio, Toggle, Select, Tooltip, Spinner, EmptyState, InlineId, Button), the
registry-driven component kitchen LiveView, the supporting tests, the admin CSS,
the Playwright e2e specs, and the CI docs verifier.

The components are well-documented and the registry/test scaffolding is thorough.
However, the review surfaced a genuine accessibility blocker (the Toggle switch
has no accessible name — it will fail the very axe scan this phase ships) and a
cluster of CSS contract gaps where component class hooks declared by the
registry and emitted by the components have **no corresponding CSS rule** at all
(`.ax-field-inline`, `.ax-field-disabled`, `.ax-radio`, plus the
focus-ring claim for checkbox/radio). Because `.ax-field` forces `display: grid`,
the missing `.ax-field-inline` rule means every inline control (checkbox, radio,
toggle) renders stacked instead of as an inline row — a real visual/contract
defect, not a style nit.

The "passing" registry tests mask several of these because they only assert that
class **strings** appear in the page HTML (test (a)/(d)), never that those classes
resolve to any CSS. That is the gap that let unstyled hooks through.

## Critical Issues

### CR-01: Toggle switch has no accessible name — will fail the shipped axe scan

**File:** `accrue_admin/lib/accrue_admin/components/toggle.ex:30-44`

**Issue:** The toggle renders a `<button role="switch">` whose only children are
the decorative `ax-toggle-track` / `ax-toggle-thumb` spans. It has no
`aria-label`, no `aria-labelledby`, and no text content. The visible
`<span class="ax-field-label">@label</span>` is a sibling **inside** the
wrapping `<label>`, but `<label>` association does not apply to `<button>`
elements — only to labelable form controls. The result is a `switch` with no
accessible name.

This is not theoretical: `admin-a11y.spec.js` runs axe (`wcag2a`/`wcag2aa`,
critical+serious) across `/billing/dev/components` in both themes, and the
toggle is a registry entry with `applicable_states` so it renders in both the
light and dark matrix columns. Axe's `button-name` rule (critical impact) will
flag every unnamed toggle, failing the a11y gate this phase introduces.

**Fix:** Give the button a programmatic name. Either reference the label span:

```elixir
def toggle(assigns) do
  ~H"""
  <label class={["ax-field", "ax-field-inline", @disabled && "ax-field-disabled"]}>
    <button
      type="button"
      id={@id}
      class="ax-toggle"
      role="switch"
      aria-checked={if @on, do: "true", else: "false"}
      aria-labelledby={@id <> "-label"}
      disabled={@disabled}
      {@rest}
    >
      <span class="ax-toggle-track"><span class="ax-toggle-thumb" /></span>
    </button>
    <input type="hidden" name={@name} value={if @on, do: "true", else: "false"} />
    <span id={@id <> "-label"} class="ax-field-label"><%= @label %></span>
  </label>
  """
end
```

or set `aria-label={@label}` directly on the button.

## Warnings

### WR-01: `.ax-field-inline` is never defined — inline controls render stacked, not inline

**File:** `accrue_admin/assets/css/app.css` (absent); emitted by
`checkbox.ex:30`, `radio.ex:25`, `toggle.ex:29`

**Issue:** Checkbox, Radio, and Toggle all wrap their control in
`class={["ax-field", "ax-field-inline", ...]}`. `.ax-field` sets
`display: grid; gap: var(--ax-space-sm)` (app.css ~1778). The `.ax-field-inline`
class is clearly intended to override that to a horizontal control+label row,
but it does not exist anywhere in `app.css` or `theme.css` (verified by grep —
zero matches). So every inline form primitive renders as a 2-row grid (control
above label) instead of the intended inline row. The registry test (a) passes
only because it checks that the **string** `ax-checkbox`/`ax-radio`/`ax-toggle`
appears in HTML, never that any layout rule applies.

**Fix:** Add the missing rule, e.g.:

```css
.ax-field-inline {
  display: inline-flex;
  flex-direction: row;
  align-items: center;
  gap: var(--ax-space-sm);
}
```

### WR-02: `.ax-field-disabled` is never defined — disabled inline state has no styling

**File:** `accrue_admin/assets/css/app.css` (absent); emitted by
`checkbox.ex:30`, `radio.ex:25`, `toggle.ex:29`

**Issue:** All three inline controls emit `@disabled && "ax-field-disabled"` on
the wrapper, but `.ax-field-disabled` is undefined (grep: zero matches). The
disabled wrapper therefore gets no dimming/cursor treatment; only the native
`disabled` attribute on the inner input applies. This contradicts the wrapper's
apparent intent and the CMP-04 disabled-affordance story for inline controls.

**Fix:** Either define `.ax-field-disabled` (e.g. `opacity: var(--ax-disabled-opacity); cursor: var(--ax-disabled-cursor);`)
or drop the class from the components if the inner-control disabled state is
sufficient. Do not ship a class hook with no behavior.

### WR-03: `.ax-radio` has no CSS at all — radio is unstyled and unthemed

**File:** `accrue_admin/assets/css/app.css` (absent); `radio.ex:31`,
`component_registry.ex:199-200`

**Issue:** The Radio component renders `class="ax-radio"` and the registry
declares the `radio` variant with `ax_class: "ax-field ax-radio"` and tokens
`--ax-interactive-selected` / `--ax-accent-strong`. But there is no `.ax-radio`
selector anywhere (grep: zero matches), and unlike `.ax-checkbox`
(`accent-color: var(--ax-accent)`, app.css ~1750) the radio consumes none of its
declared tokens. The native radio renders with the browser default accent, not
the Accrue accent — a theme-consistency defect and a drift between the registry
contract and reality.

**Fix:** Add `.ax-radio { accent-color: var(--ax-accent); inline-size: 1.25rem; block-size: 1.25rem; }`
(mirroring `.ax-checkbox`).

### WR-04: Checkbox/Radio focus-ring comment is false — no focus-visible rule covers them

**File:** `accrue_admin/assets/css/app.css:1735` (comment) vs `app.css:2941-2960`
(actual shared focus block)

**Issue:** The comment at app.css:1735 states the focus ring for
`.ax-checkbox` (and `.ax-input`/`.ax-select`) "is owned by the" shared block.
But the shared `:focus-visible` block (app.css:2941-2960) lists
`.ax-input`, `.ax-field-control`, `.ax-select-control`, etc. — and does **not**
include `.ax-checkbox` or `.ax-radio` (grep for `ax-checkbox:focus` /
`ax-radio:focus` returns nothing). So checkbox and radio fall back to the
browser-default focus ring, contradicting the comment and the design-system
focus contract. The e2e `focusRingProbe` does not probe these selectors, so the
gap is invisible to CI.

**Fix:** Add `.ax-checkbox` and `.ax-radio` to the shared `:focus-visible`
selector list (or document accurately that native focus is intentional). Correct
or remove the misleading comment either way.

### WR-05: `.ax-money-display` and `.ax-inline-id-short` are phantom classes the registry/test depend on

**File:** `component_registry.ex:441,542`; `component_kitchen_live.ex:867,875,947,955`;
CSS (absent)

**Issue:** The registry declares `money` variant `ax_class: "ax-money ax-money-display"`
and `inline-id` variant `ax_class: "ax-inline-id ax-inline-id-short"`. Registry
test (a) splits on space and asserts the second token (`ax-money-display`,
`ax-inline-id-short`) appears in the page HTML; the kitchen satisfies this by
passing `class="ax-money-display"` / `class="ax-inline-id-short"` to the
components. But neither class has any CSS definition (grep: zero matches). The
test is green yet the "variant" carries no styling — the registry asserts a
variant that does not visually exist. This is exactly the failure mode WR-01..03
share: the tests prove the string is present, not that it does anything.

**Fix:** Either define the classes (give them real per-variant styling) or change
the registry `ax_class` to the actually-styled token (`ax-money` / `ax-inline-id`)
and adjust the test accordingly. Do not leave class hooks that resolve to no
rule.

### WR-06: Button `:global` swallows `aria-busy`/`disabled` mismatch on loading anchors

**File:** `accrue_admin/lib/accrue_admin/components/button.ex:26-41`

**Issue:** The `loading` attr only has an effect on the `<button>` branch
(`disabled={@disabled || @loading}`, `aria-busy`). When `@href` is set, both
anchor branches ignore `@loading` entirely — a "loading" link renders as a fully
active, clickable link with no busy indication and no click suppression. A caller
passing `loading` on an href button gets a silently incorrect control (it neither
disables nor signals busy). Given the registry includes a "Loading" specimen for
every button variant, this is a real behavioral gap for the link form.

**Fix:** Either honor `loading` on the anchor branch (e.g. route to the disabled
anchor branch when `@href && @loading`, with `aria-busy="true"`), or document/
validate that `loading` is mutually exclusive with `href` (e.g. raise/guard in
the function head).

### WR-07: `focusRingProbe` uses `.focus()` but asserts `:focus-visible` styling — flaky/false-negative for buttons

**File:** `accrue_admin/e2e/admin-interactions.spec.js:777-830,1069-1094`

**Issue:** `focusRingProbe` calls `locator.focus()` (programmatic focus) and then
asserts `outlineWidth >= 2 && outlineOffset >= 2`. The admin focus ring is
applied via `:focus-visible` (app.css:2941). In Chromium, programmatic `.focus()`
on a `<button>` does **not** match `:focus-visible` (that heuristic requires
keyboard interaction), so `getComputedStyle().outlineWidth` will read `0px` for
`.ax-button`, producing a spurious `focus-ring-missing` failure that fails the
test (`expect(missing).toHaveLength(0)`). Text inputs (`.ax-field-control`)
usually still match `:focus-visible` under script focus, so the inconsistency is
selector-dependent and brittle.

**Fix:** Drive focus via the keyboard (`page.keyboard.press("Tab")` until the
target is active) so `:focus-visible` matches, or read the `:focus-visible`
ring through `getComputedStyle(el, null)` after a real keydown. Alternatively
assert on `boxShadow` (which the same rule also sets via `--ax-focus-shadow`) so
the probe is not coupled to the `:focus-visible` activation heuristic.

## Info

### IN-01: InlineId interpolates an unvalidated attr into an inline `style`

**File:** `accrue_admin/lib/accrue_admin/components/inline_id.ex:31`

**Issue:** `style={"max-width: #{@max_width};"}` interpolates the free-form
`:string` `@max_width` attr into a `style` attribute. HEEx HTML-escapes attribute
values (quotes become entities), so this cannot break out of the attribute and
is not an XSS vector. It is, however, an unvalidated CSS value sink: a caller
passing attacker-influenced text injects arbitrary CSS declarations into
`max-width` (e.g. `16ch; position: fixed; ...`). Low severity because callers
are first-party and the value is structural, but worth constraining.

**Fix:** Validate with a `values:`-style guard or a small regex on mount
(e.g. accept only `\d+(\.\d+)?(ch|rem|px|em|%)`), or move the width to a CSS
custom property set on a known-safe element.

### IN-02: Registry `ax_class` semantics differ between Phase-189 entries and earlier entries

**File:** `component_registry.ex:122-125,441,463-467`

**Issue:** For most entries `ax_class` is the literal rendered class string, but
several Phase-189 entries (`input` → `"ax-field ax-field-control"`,
`json-viewer` → `"ax-json-viewer ax-json-tree"`) are synthesized from two
different elements (wrapper + inner) rather than a single element's class
attribute. The inline comments acknowledge this. It works for the substring test
but makes the field's contract ambiguous for future maintainers and for test (b)
which assumes the rendered element carries the full string. Document the
"composite ax_class" convention explicitly in the `@type entry` doc.

### IN-03: Spinner reduced-motion freeze sets `animation-duration: 0ms`

**File:** `accrue_admin/assets/css/app.css:2192`

**Issue:** The reduced-motion override uses `animation-duration: 0ms`. This is
correct behavior and (correctly) escapes the MOT-01 raw-duration guard because
that regex only matches the `animation:`/`transition:` shorthand, not the
longhand `animation-duration:`. Noting it so a future tightening of the verifier
regex to include longhands does not surprise this allowlisted-by-omission case.

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
