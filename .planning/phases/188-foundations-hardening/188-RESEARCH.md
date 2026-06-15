# Phase 188: Foundations hardening - Research

**Generated:** 2026-06-15
**Status:** Ready for validation and UI contract gate
**Confidence:** High

<domain>
Phase 188 is a foundation-only pass for `accrue_admin` design-system roots. The
work should make downstream component, group, page, and flow phases inherit
correct defaults for type, measure, layers, semantic state roles, Tailwind source
of truth, and motion coverage. It should not become per-page patching, a
Tailwind migration, a PhoenixStorybook integration, host/demo chrome redesign,
`accrue_portal` work, new billing primitives, or a public route/API change.
</domain>

<primary_recommendation>
Implement Phase 188 as one root pass with five vertical slices:

1. Add composed typography role tokens and migrate semantic classes to consume
   them.
2. Replace partial z-index values with the formal layer scale and migrate
   overlay/sticky consumers.
3. Resolve Tailwind source-of-truth ambiguity by deleting the inert config and
   removing `--config` from the package asset task while keeping Tailwind 3 as
   the current compiler/minifier.
4. Complete semantic role tokens for focus, scrollbar, disabled, readonly,
   interactive, and status states across light, dark, and system-dark modes.
5. Extend verifier, ExUnit, component kitchen, and Playwright coverage so the
   foundations remain enforceable after this phase.

The plan should avoid a broad overlay portal rewrite and avoid a CSS build-tool
replacement. Those are separate architectural decisions.
</primary_recommendation>

## Requirements Fit

| Requirement | Research finding |
| --- | --- |
| FND-01 | Keep atomic type tokens, add composed `--ax-type-{role}-font` and `--ax-type-{role}-tracking` roles, and make `ax-*` primitives consume roles instead of rebuilding type property by property. |
| FND-02 | Replace the current partial z-index scale with the exact semantic scale: base, sticky, dropdown, popover, drawer, modal, toast. Enforce no overlay literals outside isolated local micro-stacks. |
| FND-03 | Apply `--ax-measure` to prose/help/error/empty/description text and narrative cells, while avoiding a global cap on raw tables or machine data grids. |
| FND-04 | Delete `assets/tailwind.config.js` and `assets/tailwind_preset.js`, remove `--config` from `mix accrue_admin.assets.build`, and update docs/tests so Tailwind utilities are not treated as an authoring path. |
| FND-05 | Add missing semantic role tokens for focus, scrollbars, disabled, readonly, interactive, and status states in light, dark, and system-dark themes; standardize `:focus-visible` beyond subtle border-only changes. |
| FND-06 | Keep the existing motion-token family and reduced-motion strategy; treat remaining raw durations/easings/transitions as token-gap findings, not new exceptions. |

## Project Context

No project-local agent instructions were found beyond the GSD phase context.
The authoritative local inputs are:

- `.planning/ROADMAP.md` for Phase 188 scope, dependency on Phase 187, and v1.53
  guardrails.
- `.planning/REQUIREMENTS.md` for FND-01 through FND-06.
- `.planning/phases/188-foundations-hardening/188-CONTEXT.md` for locked
  decisions D-01 through D-25.
- `.planning/phases/187-audit-baseline/*` for baseline defects and owner-phase
  routing.
- `brandbook/` and prior v1.51/v1.52 planning artifacts for the existing custom
  `ax-*` CSS posture.

The implementation should stay inside the current package architecture:

- `accrue_admin/assets/css/theme.css` remains the token source of truth.
- `accrue_admin/assets/css/app.css` remains the authored class layer and
  migration surface.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` remains the asset
  build entry point.
- `scripts/ci/verify_package_docs.sh` remains the main source/doc guardrail.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` and
  `component_registry.ex` remain the component-lab extension points.
- ExUnit and Playwright remain the verification stack.

## Current Code Findings

### Typography

`theme.css` already has useful atoms: `--ax-font-*`, `--ax-type-*`,
`--ax-leading-*`, `--ax-tracking-*`, and `--ax-measure`. It does not yet expose
the composed role contract required by D-01 through D-04. `app.css` still has
many raw `font-size`, `font-weight`, `line-height`, `letter-spacing`, and
`font-family` declarations that should be migrated or allowlisted after the
root pass.

The `font` shorthand is viable for composed roles when paired with a separate
letter-spacing token. The CSS shorthand sets style, variant, weight, size,
line-height, and family together; tracking must remain a separate property.

Recommended type role shape:

```css
:root {
  --ax-type-body-font: 400 var(--ax-type-md)/var(--ax-leading-normal) var(--ax-font-sans);
  --ax-type-body-tracking: var(--ax-tracking-normal);
}

.ax-type-body {
  font: var(--ax-type-body-font);
  letter-spacing: var(--ax-type-body-tracking);
}
```

Initial roles should match the context decisions: `body`, `body-sm`,
`body-relaxed`, `label`, `label-sm`, `eyebrow`, `title`, `title-lg`,
`heading`, `display`, `metric`, `code`, and `code-xs`.

### Reading Measure

`.ax-measure` exists in `app.css`, but the measure token is not yet broadly
consumed by the semantic prose/help/error/empty/description regions that Phase
188 is meant to harden. The migration should cap readable copy and narrative
cells, not raw data tables. The acceptance test should check representative
selectors rather than assume all table cells should have a max width.

### Layers

`theme.css` currently exposes a partial layer vocabulary with low values:
`--ax-z-topbar`, `--ax-z-popover`, `--ax-z-drawer`, and `--ax-z-modal`. Phase 188
should replace this with the exact roadmap scale:

```css
--ax-z-base: 0;
--ax-z-sticky: 100;
--ax-z-dropdown: 200;
--ax-z-popover: 300;
--ax-z-drawer: 400;
--ax-z-modal: 500;
--ax-z-toast: 600;
```

Literal overlay values remain in `app.css`, including topbar, detail drawer,
dropdown panel, and mobile sidebar selectors. Existing variable consumers such
as the dev toolbar, tab-more menu, and command palette should be checked against
their semantic layer role. If a `--ax-z-topbar` alias is kept for compatibility,
it should map to `--ax-z-sticky` and be documented as temporary/deprecated.

### Tailwind Source Of Truth

`accrue_admin/assets/tailwind.config.js` and
`accrue_admin/assets/tailwind_preset.js` are ambiguous second sources of styling
truth. The Mix asset build task still passes `--config assets/tailwind.config.js`.
Phase 188 should delete both config files, remove `--config`, and preserve
Tailwind 3.4.17 only as the current package-local CSS compiler/minifier.

`accrue_admin/guides/admin_ui.md` still describes the old Tailwind config and
preset posture. It should instead say that package styles are authored in
`assets/css/theme.css` and `assets/css/app.css` using `--ax-*` tokens and
`ax-*` classes, and that host apps do not configure Tailwind for AccrueAdmin.

### Semantic Roles

`theme.css` currently has `--ax-focus-ring`, but lacks the full role layer
required by D-18:

- focus ring offset and shadow
- scrollbar thumb/track/hover
- disabled background/border/text/opacity/cursor
- readonly background/border/text
- interactive hover/active/selected
- status role families for success, warning, danger, info, and neutral

These roles should be defined in light, dark, and `system` under dark media.
Selectors should consume role tokens when representing semantic state, rather
than accumulating local `color-mix()` one-offs.

Current focus styles rely too often on border-color changes plus
`outline: none`. Phase 188 should standardize visible `:focus-visible` using a
2px outline, offset, and/or halo that remains visible in light and dark modes.

Native controls should continue to use `disabled`. Custom or link-like disabled
controls that use `aria-disabled="true"` must also remove activation and hover
affordance, and either leave the tab sequence intentionally or use
`tabindex="-1"`/omit `href` when they should not be focusable.

Root scrollbars should use `color-scheme` plus `scrollbar-color`, with WebKit
fallback selectors that consume `--ax-scrollbar-*` tokens.

### Motion

The existing motion architecture is mostly aligned with Phase 188. `theme.css`
has motion atoms/bundles and a reduced-motion block. `guides/motion.md` already
documents the policy. The CI verifier already checks for `transition: all`, raw
`cubic-bezier()`, raw `ms`/`s` timing literals in transitions/animations except
the documented skeleton shimmer, and layout-property transitions.

The plan should extend this verifier posture, not introduce a parallel motion
system or a new family of motion tokens.

## External Reference Findings

External research supports the local decisions without requiring new
dependencies:

- Design Tokens Community Group format documents structured token types and
  supports treating composed design decisions as first-class token values:
  `https://tr.designtokens.org/format/`.
- Material 3 type scale tokens, Carbon typography, and Primer typography all
  support role-oriented type contracts over ad-hoc property assembly:
  `https://m3.material.io/styles/typography/type-scale-tokens`,
  `https://carbondesignsystem.com/elements/typography/overview/`,
  `https://primer.style/product/getting-started/foundations/typography/`.
- MDN documents the CSS `font` shorthand constraints, which justify storing
  font role bundles separately from tracking:
  `https://developer.mozilla.org/en-US/docs/Web/CSS/font`.
- WCAG text spacing guidance supports keeping readable type and measure
  resilient to user spacing overrides:
  `https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html`.
- Bootstrap and USWDS both treat z-index as a coordinated design-system scale
  rather than local literals:
  `https://getbootstrap.com/docs/5.3/layout/z-index/`,
  `https://designsystem.digital.gov/design-tokens/z-index/`.
- MDN stacking-context guidance reinforces why root layer tokens do not solve
  every overlay bug if an ancestor creates a new stacking context:
  `https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_positioned_layout/Stacking_context`.
- WAI-ARIA dialog guidance and Phoenix LiveView JS docs support keeping modal
  and overlay behavior aligned with focus management and DOM-patch-aware
  transitions:
  `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/`,
  `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html`.
- Phoenix asset management docs and Tailwind v3 content configuration support
  treating Tailwind as an asset pipeline tool here, not as the package styling
  contract:
  `https://phoenix.hexdocs.pm/asset_management.html`,
  `https://v3.tailwindcss.com/docs/content-configuration`.
- MDN references for `color-scheme`, `scrollbar-color`, and `aria-disabled`
  support the semantic-role approach for dark mode, scrollbars, and custom
  disabled controls:
  `https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme`,
  `https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-color`,
  `https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-disabled`.

## Recommended Implementation Slices

### Slice 1: Typography Roles And Measure

Add the composed type role tokens in `theme.css`, then add matching
`.ax-type-{role}` utilities and migrate semantic admin selectors in `app.css` to
consume roles. Keep atomic tokens for internal composition. Apply `--ax-measure`
to prose/help/error/empty/description selectors and narrative table content
where useful.

Guardrails:

- Do not remove the atomic tokens.
- Do not cap raw machine-data tables globally.
- Do not use numeric/t-shirt role names as the public contract.
- Keep code and metric roles distinct from body roles.

### Slice 2: Layer System

Replace the partial z-index tokens with the exact semantic scale. Migrate
topbar, skip link, mobile sidebar, dropdown menus, floating panels, drawers,
modals, command palette, step-up auth, and flash/toast surfaces to the correct
token. Add a verifier guard that bans overlay z-index literals except local
`-1`, `0`, or `1` micro-stacking inside isolated components.

Guardrails:

- Do not create a broad portal abstraction.
- Do not let `--ax-z-topbar` become a second scheme.
- Treat stacking-context bugs as specific follow-up findings if they require
  page-flow ownership outside this foundation pass.

### Slice 3: Tailwind Source Of Truth

Delete the Tailwind config and preset files, remove `--config` from the Mix
task, and update tests/docs so the source of truth is unambiguous. Add guards
for absence of config files, absence of `@tailwind` and `@apply`, docs not
inviting utility authoring, and HEEx not accumulating obvious Tailwind utility
class authoring outside intentional `ax-*` classes.

Guardrails:

- Do not replace the Tailwind CLI in this phase.
- Do not start a Tailwind migration.
- Do not require host apps to configure Tailwind for AccrueAdmin.

### Slice 4: Semantic Role Completion

Add the required semantic role layer in `theme.css` and migrate focus,
scrollbar, disabled, readonly, interactive, and status selectors to consume it.
Standardize focus visible styles. Update custom disabled controls where needed
so ARIA state and behavior match.

Guardrails:

- Every role must resolve in light, dark, and system-dark mode.
- Focus cannot be border-only.
- Disabled controls cannot retain active hover/activation affordances.
- Scrollbar colors must come from `--ax-scrollbar-*` tokens.

### Slice 5: Verification And Lab Coverage

Extend the component kitchen with foundation specimens for type roles, measure,
focus, disabled/readonly, status roles, and any layer specimen that can be shown
without creating a brittle overlay demo. Add Playwright computed-style checks
against the kitchen, and extend the existing axe/reduced-motion checks rather
than adding a separate browser harness.

Guardrails:

- Keep specimens as maintainer-facing reference surfaces, not marketing chrome.
- Favor computed style checks for token resolution over screenshot-only proof.
- Preserve existing Phase 187 baseline/a11y/reduced-motion behavior.

## Validation Architecture

The validation strategy should use the existing repo stack: shell verifier,
ExUnit, and Playwright.

### Source And Documentation Guards

Extend `scripts/ci/verify_package_docs.sh` with guards for:

- `accrue_admin/assets/tailwind.config.js` and
  `accrue_admin/assets/tailwind_preset.js` staying absent.
- `mix accrue_admin.assets.build` no longer passing `--config`.
- `@tailwind` and `@apply` staying out of package CSS.
- Package docs not inviting Tailwind utility authoring or host Tailwind config.
- Obvious Tailwind utility authoring not appearing in HEEx outside intentional
  `ax-*` package classes.
- Overlay `z-index` literals being absent outside documented micro-stack
  exceptions.
- Raw type declarations being absent outside allowlisted zones after migration.
- Required semantic role tokens existing in root, dark, and system-dark scopes.
- Existing motion guards remaining intact.

Extend `accrue/test/accrue/docs/package_docs_verifier_test.exs` with negative
fixtures for each new guard. The fixture helper should copy any additional files
needed for the new checks, especially `theme.css`, `admin_ui.md`, Tailwind config
paths, and representative HEEx/CSS fixtures.

### ExUnit Guards

Update `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` so the
asset build task asserts:

- input and output paths are still passed correctly,
- `--config` is absent,
- the committed bundle behavior remains unchanged.

Add or extend package tests for:

- required type role token names and utility class names,
- required semantic role token names across light/dark/system scopes,
- component registry entries for new foundation kitchen specimens.

### Playwright Guards

Extend existing browser checks instead of creating a new harness:

- `accrue_admin/e2e/reduced-motion.spec.js` continues to prove travel/overshoot
  collapse while crossfades remain perceptible.
- `accrue_admin/e2e/admin-a11y.spec.js` continues to run axe across the existing
  light/dark surface set.
- Add or extend component-kitchen computed-style checks for:
  - composed typography role application,
  - readable measure on prose/help/empty/description specimens,
  - focus outline/offset/halo on focusable controls,
  - disabled and readonly token resolution,
  - scrollbar token resolution where browser support exposes computed values,
  - status role color differences in light and dark themes,
  - z-index token values on representative sticky/dropdown/popover/drawer/modal
    elements when available.

### Manual Review

Manual review should be limited to a maintainer-facing component kitchen pass in
light and dark modes. It should check that foundation specimens are legible,
focus rings are obvious, disabled states read as unavailable, status surfaces
have sufficient contrast, and measure caps improve prose without hiding dense
data.

## Threat Model

Phase 188 is mostly CSS/docs/build-task work, so the primary risks are
accessibility and regression risks rather than data exfiltration or privilege
changes.

- Spoofing: focus and disabled states must not make controls appear active when
  they are unavailable.
- Tampering: deleting Tailwind config files should not let host app utility
  config affect package output.
- Repudiation: verifier and test failures should point to the offending source
  file so regressions are attributable.
- Information disclosure: no new user data surfaces are expected.
- Denial of service: asset build changes must preserve deterministic package CSS
  generation.
- Elevation of privilege: custom `aria-disabled` controls must remove activation
  paths so unavailable actions cannot still fire.

## Pitfalls To Avoid

- Do not globally apply `max-width` to all tables or data grids.
- Do not add a new motion token family.
- Do not treat raw motion literals as acceptable one-off exceptions after this
  pass.
- Do not use `outline: none` without a stronger `:focus-visible` replacement.
- Do not replace the CSS compiler/minifier as part of FND-04.
- Do not introduce Tailwind utilities as a new authoring path.
- Do not make `--ax-z-topbar` a long-term parallel layer vocabulary.
- Do not patch individual pages beyond selectors needed to make root primitives
  consume the new roles.

## Out Of Scope

- Tailwind migration or utility-first authoring.
- Replacing Tailwind CLI with a different CSS bundler.
- PhoenixStorybook or a new component documentation system.
- Broad overlay portal architecture.
- New billing primitives, public API changes, or route changes.
- Host/demo chrome redesign.
- `accrue_portal` work.
- Per-page visual uplift outside root foundation selectors.

## RESEARCH COMPLETE
