# Phase 188: Foundations hardening - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the root `accrue_admin` design-system foundations so downstream component,
group, page, and flow work inherits correct defaults: composed typography
bundles, reading-measure application, a formal z-index/layer system, motion-gap
closure, inert-Tailwind resolution, and complete semantic roles in light, dark,
and system themes. This phase is foundation-only: no per-page patching, no
Tailwind migration, no PhoenixStorybook dependency, no host/demo chrome redesign,
no `accrue_portal` work, no new billing primitives, and no public route/API
breakage.

</domain>

<decisions>
## Implementation Decisions

The user selected all four gray areas and explicitly requested subagent-backed,
recommendation-first research across software architecture, Phoenix/LiveView
idioms, UI/UX/accessibility, design-system practice, DX, ecosystem lessons, and
the repo's prompt/brand corpus. Four advisor researchers returned compatible
recommendations; the package below is locked for planning.

### Typography Bundle Contract

- **D-01:** Keep the existing atomic type tokens (`--ax-type-*`,
  `--ax-leading-*`, `--ax-tracking-*`, `--ax-font-*`, `--ax-measure`) but add
  composed role tokens in `theme.css` as the maintainer-facing contract.
- **D-02:** Use a two-token role shape: `--ax-type-{role}-font` for CSS `font`
  shorthand and `--ax-type-{role}-tracking` for letter spacing. Example:
  `--ax-type-body-font: 400 var(--ax-type-md)/var(--ax-leading-normal)
  var(--ax-font-sans);` plus `--ax-type-body-tracking:
  var(--ax-tracking-normal);`.
- **D-03:** Initial role set: `body`, `body-sm`, `body-relaxed`, `label`,
  `label-sm`, `eyebrow`, `title`, `title-lg`, `heading`, `display`, `metric`,
  `code`, and `code-xs`. Names are semantic and role-driven, not numeric
  t-shirt sizes.
- **D-04:** Consume the composed roles through `.ax-type-{role}` utilities and
  existing semantic classes. Downstream component work should choose a role,
  not reassemble font family, size, weight, line-height, and tracking property
  by property.
- **D-05:** Migration is strict after the Phase 188 root pass. Ban raw
  `font-size`, `line-height`, `letter-spacing`, `font-weight`, and `font-family`
  in admin component/page CSS except documented allowlist zones: `@font-face`,
  root body inheritance, icon/SVG mechanics, and explicitly justified
  one-off exceptions.
- **D-06:** Reading measure stays rooted in `--ax-measure`, but the phase should
  apply it to real prose/help/error/empty-state/description regions, not merely
  define `.ax-measure`. Dense data surfaces should cap explanatory copy and
  long narrative cells; do not globally cap raw tables or machine data grids in
  a way that hides information.

### Layer Stack Contract

- **D-07:** Replace the partial z-index scale with the exact semantic layer
  tokens required by the roadmap: `--ax-z-base: 0`, `--ax-z-sticky: 100`,
  `--ax-z-dropdown: 200`, `--ax-z-popover: 300`, `--ax-z-drawer: 400`,
  `--ax-z-modal: 500`, and `--ax-z-toast: 600`.
- **D-08:** Migrate existing uses by role: topbar, skip link, and mobile sidebar
  use `sticky`; dropdown menus use `dropdown`; tab-more/help/dev floating panels
  use `popover` when they are non-menu floats; detail drawers use `drawer`;
  command palette and step-up auth use `modal`; flash/toast surfaces use
  `toast`.
- **D-09:** A temporary `--ax-z-topbar: var(--ax-z-sticky)` alias may exist only
  as a deprecated compatibility alias during the migration. It should not become
  a second naming scheme.
- **D-10:** Enforce no literal overlay `z-index` values in `accrue_admin` CSS.
  The only acceptable exceptions are local micro-stacking values `-1`, `0`, or
  `1` inside an isolated component, documented inline and paired with
  `isolation: isolate` when needed.
- **D-11:** Phase 188 should set the layer foundation and tests, not perform a
  broad portal/refactor of every overlay. If a stacking-context trap is found
  while migrating the root layers, fix the root cause or document the specific
  Phase 191 interaction owner; do not turn this into a page-flow pass.

### Tailwind Source-of-Truth Resolution

- **D-12:** Delete `accrue_admin/assets/tailwind.config.js` and
  `accrue_admin/assets/tailwind_preset.js`. The config/preset files are the
  ambiguous second styling source of truth.
- **D-13:** Keep `tailwindcss@3.4.17` only as the package-local CSS
  compiler/minifier for the committed bundle. Remove `--config` from
  `mix accrue_admin.assets.build`; no expected `priv/static/accrue_admin.css`
  diff was observed by the advisor when compiling without config.
- **D-14:** Update docs to say: AccrueAdmin styles are authored only in
  `assets/css/theme.css` and `assets/css/app.css` using `--ax-*` tokens and
  `ax-*` classes. Tailwind utilities are not an authoring path. Host apps never
  configure Tailwind for `accrue_admin`.
- **D-15:** Add tests/guards that the deleted Tailwind config files stay absent,
  `@tailwind`/`@apply` do not appear in package CSS, package docs do not invite
  Tailwind utilities, and live HEEx does not grow obvious Tailwind utility
  authoring outside intentional `ax-*` classes.
- **D-16:** Replacing the Tailwind CLI entirely with a neutral CSS bundler is a
  separate build-pipeline decision and is not part of Phase 188. Phase 188
  resolves the SSOT ambiguity with minimal build risk.

### Semantic Role Completion

- **D-17:** Add a local semantic role layer in `theme.css`, borrowing proven
  patterns from Primer/Polaris/Radix/GOV.UK without importing their tokens or
  adding dependencies.
- **D-18:** Required root roles: `--ax-focus-ring`,
  `--ax-focus-ring-offset`, `--ax-focus-shadow`,
  `--ax-scrollbar-thumb`, `--ax-scrollbar-track`,
  `--ax-scrollbar-thumb-hover`, `--ax-disabled-bg`,
  `--ax-disabled-border`, `--ax-disabled-text`,
  `--ax-disabled-opacity`, `--ax-disabled-cursor`,
  `--ax-readonly-bg`, `--ax-readonly-border`, `--ax-readonly-text`,
  `--ax-interactive-hover`, `--ax-interactive-active`,
  `--ax-interactive-selected`, and status pairs
  `--ax-status-{success,warning,danger,info,neutral}-{bg,border,text,solid,on-solid}`.
- **D-19:** Define every semantic role in light, dark, and `system` under dark
  media. Component selectors should consume roles instead of local
  `color-mix()` one-offs when the value represents a semantic state.
- **D-20:** Focus is standardized as `:focus-visible` with a 2px outline,
  offset, and/or halo that meets WCAG focus contrast expectations. Do not rely
  on subtle border-only color changes as the sole visible focus indicator.
- **D-21:** Native controls use `disabled`. Custom or link-like controls use
  `aria-disabled="true"` only with matching behavior: remove activation, remove
  hover/active affordance, and use `tabindex="-1"` or omit `href` where the
  control must leave the tab sequence.
- **D-22:** Root scrollbars should use `color-scheme` plus `scrollbar-color`
  with a WebKit fallback. Values must resolve through `--ax-scrollbar-*` tokens
  and stay readable in light, dark, and system themes.

### Motion Gap Closure

- **D-23:** Do not create a new motion token family. Close Phase 188 motion gaps
  by routing every remaining transition/animation through the existing
  Phase-174/177 atoms and bundles: `--ax-dur-*`, `--ax-ease-*`,
  `--ax-rise-*`, `--ax-press-scale`, and `--ax-transition-*`.
- **D-24:** Keep the reduced-motion strategy already locked in `theme.css` and
  `accrue_admin/guides/motion.md`: travel, transform, and overshoot collapse;
  opacity feedback can remain perceptible. Raw `ms`, `s`, `cubic-bezier()`, and
  `transition: all` remain banned except the documented skeleton loading loop.
- **D-25:** If a component still needs a raw motion literal, that is a token-gap
  finding for Phase 188, not permission to add another local exception.

### the agent's Discretion

- Exact placement/order of new token blocks in `theme.css`, provided the file
  remains readable and the role groups are obvious.
- Exact guard implementation (Elixir test, shell verifier, or both), provided it
  catches regressions and follows the existing verifier/negative-fixture
  coupling pattern.
- Whether to keep a short-lived `--ax-z-topbar` alias during migration, as long
  as the canonical layer language is `sticky`.
- Exact component-lab presentation of type, layer, focus, disabled, scrollbar,
  and status specimens, as long as Phase 189 can consume the reference.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Milestone Scope

- `.planning/ROADMAP.md` - Phase 188 goal, success criteria, v1.53 guardrails,
  and dependency sequence.
- `.planning/PROJECT.md` - v1.53 posture, admin UI hardening rationale, and
  no-new-feature boundary.
- `.planning/REQUIREMENTS.md` - FND-01 through FND-06 plus v1.53 out-of-scope
  constraints.
- `.planning/STATE.md` - current milestone state, Phase 187 handoff, and
  accumulated v1.53 decisions.

### Prior Phase Baseline

- `.planning/phases/187-audit-baseline/187-CONTEXT.md` - Phase 187 decisions,
  canonical structured artifact rule, and owner-phase routing.
- `.planning/phases/187-audit-baseline/187-RUBRIC.md` - rubric dimensions,
  overlay tags, and owner-phase mapping for foundation defects.
- `.planning/phases/187-audit-baseline/187-BASELINE.md` - Phase 187 baseline
  summary and defect ledger overview.
- `.planning/phases/187-audit-baseline/defects.ndjson` - machine-readable
  defect ledger; use for cross-checking owner-phase and overlay tags.
- `.planning/phases/187-audit-baseline/baseline.cells.json` - canonical scored
  cells for Phase 192 comparison.

### Prior Admin UI Decisions

- `.planning/research/v1.51-admin-ui-depth-design.md` - locked admin design
  source: custom `ax-*` CSS, no Tailwind migration, quiet developer-tooling
  visual direction, mobile-first, and anti-churn doctrine.
- `.planning/milestones/v1.51-phases/174-a-design-system-gap-closure-token-completeness/174-CONTEXT.md` - prior token decisions: breakpoint comments, type atoms, transition bundles, measure token, no new build deps.
- `.planning/milestones/v1.51-phases/177-d-motion-micro-interaction-design/177-CONTEXT.md` - prior motion decisions: restrained functional motion, no raw timing literals, reduced-motion behavior.
- `.planning/milestones/v1.51-phases/176-c-systematic-per-screen-rubric-uplift/176-CONTEXT.md` - prior screen-rubric decisions and custom CSS posture.
- `.planning/milestones/v1.51-phases/179-f-screenshot-driven-visual-qa-loop-sign-off/179-CONTEXT.md` - prior screenshot/axe/vision scoring decisions and committed-bundle warning.

### Brand and Prompt Corpus

- `brandbook/README.md` - current brand asset guidance; supersedes older prompt
  copy where they conflict.
- `brandbook/tokens/README.md` - brand token layer and admin `--ax-*` mapping.
- `brandbook/tokens/tokens.json` - current brand token source.
- `brandbook/voice.md` - ratified voice: measured, exact, native, durable.
- `brandbook/copy.md` - approved copy and microcopy patterns.
- `prompts/accrue-brand-book.md` - historical brand seed only where it does not
  conflict with `brandbook/`.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - maintainer preference for
  subagent-backed research, high DX, and done-enough judgment.

### Existing Code and Docs

- `accrue_admin/assets/css/theme.css` - admin token SSOT and primary Phase 188
  edit surface.
- `accrue_admin/assets/css/app.css` - admin class definitions, current literal
  z-index/type/dark-role migration surface, and component state selectors.
- `accrue_admin/assets/tailwind.config.js` - delete as part of FND-04.
- `accrue_admin/assets/tailwind_preset.js` - delete as part of FND-04.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` - asset build task;
  remove `--config` and preserve committed-bundle behavior.
- `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` - build task
  regression tests.
- `accrue_admin/guides/admin_ui.md` - update Tailwind/authoring posture.
- `accrue_admin/guides/motion.md` - existing motion contract and enforcement
  expectations.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` - component lab
  extension point for foundation specimens.
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` - current component
  registry pattern for shared lab/test truth.
- `accrue_admin/e2e/admin-a11y.spec.js` - axe sweep to keep theme/state changes
  accessible.
- `accrue_admin/e2e/reduced-motion.spec.js` - reduced-motion regression guard.
- `scripts/ci/verify_package_docs.sh` - existing verifier pattern for style/doc
  guardrails.

### External Primary References

- `https://tr.designtokens.org/format/` - DTCG design token format and
  composite-token precedent.
- `https://m3.material.io/styles/typography/type-scale-tokens` - role-based
  typography precedent.
- `https://carbondesignsystem.com/elements/typography/overview/` - type style
  precedent for product UI systems.
- `https://primer.style/product/getting-started/foundations/typography/` -
  developer-tooling typography precedent.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/font` - CSS `font`
  shorthand semantics for composed role tokens.
- `https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html` - text
  spacing expectations.
- `https://getbootstrap.com/docs/5.3/layout/z-index/` - z-index values as a
  coordinated scale.
- `https://designsystem.digital.gov/design-tokens/z-index/` - stepped z-index
  token precedent.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_positioned_layout/Stacking_context` - stacking context causes and footguns.
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` - modal dialog focus
  and inertness model.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html` - LiveView JS
  commands for DOM-patch-aware show/hide/focus behavior.
- `https://phoenix.hexdocs.pm/asset_management.html` - Phoenix asset management
  and Tailwind/esbuild defaults.
- `https://v3.tailwindcss.com/docs/content-configuration` - Tailwind v3 content
  config behavior.
- `https://tailwindcss.com/docs/upgrade-guide` - Tailwind v4 migration context.
- `https://tailwindcss.com/docs/detecting-classes-in-source-files` - Tailwind
  source detection behavior.
- `https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html` - focus
  indicator size/contrast expectations.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme` - native theme
  color-scheme behavior.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/scrollbar-color` - scrollbar
  color semantics.
- `https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-disabled` - `aria-disabled` semantics and author obligations.
- `https://design-system.service.gov.uk/get-started/focus-states/` - GOV.UK
  focus-state precedent.
- `https://primer.style/product/getting-started/foundations/color-usage` -
  semantic color usage precedent.
- `https://polaris-react.shopify.com/tokens/color` - commerce/admin role-token
  precedent.
- `https://www.radix-ui.com/colors` - accessible light/dark color scale
  precedent; reference only, do not import.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `accrue_admin/assets/css/theme.css` already hosts the admin token SSOT:
  fonts, type scale, spacing, radii, shadows, motion atoms, transition bundles,
  current partial z tokens, semantic colors, and light/dark/system theme values.
- `accrue_admin/assets/css/app.css` already has the `ax-*` class system and the
  migration targets: literal font sizes, literal z-index values, local
  dark-mode overrides, status color mixes, focus selectors, disabled selectors,
  and scrollbar gaps.
- `accrue_admin/guides/motion.md` already documents the motion contract and CI
  guard posture; Phase 188 should close gaps against it instead of inventing a
  new motion model.
- `/billing/dev/components` via `component_kitchen_live.ex` and
  `component_registry.ex` gives Phase 188 a place to expose foundation
  specimens before Phase 189 expands the lab.
- Existing Playwright a11y and reduced-motion specs can be extended with
  computed-style checks instead of relying only on screenshot review.

### Established Patterns

- Custom `ax-*` CSS and CSS custom properties are the implementation SSOT.
- The admin package ships a committed private asset bundle; host apps do not run
  AccrueAdmin's Tailwind configuration.
- Existing verifier changes must update both the guard and its negative-test
  fixture, matching the established package-doc verifier pattern.
- Generated screenshots/traces stay outside committed planning artifacts; only
  references/checksums belong in planning docs unless a human sign-off explicitly
  asks for representative evidence.

### Integration Points

- `theme.css` token additions feed `app.css` and component selectors; no
  LiveView route or public component API change is needed for most foundation
  work.
- `accrue_admin.assets.build` must keep producing the committed CSS/JS bundle
  without requiring host Tailwind or host JS wiring.
- Phase 189 consumes the typography, status, disabled, read-only, focus, and
  scrollbar roles in primitives/forms and proves them in the component lab.
- Phase 190 consumes the layer and role tokens in recurring component groups.
- Phase 191 owns flow-specific interaction defects, focus restoration after
  LiveView patches, and per-page scroll/overlay behavior not solvable at the
  root layer.

</code_context>

<specifics>
## Specific Ideas

- Treat the four recommendations as one package: composed type roles, semantic
  layers, Tailwind config deletion, and semantic role completion all reduce the
  same maintainer failure mode: local CSS choices that look harmless but break
  dark mode, focus, overlays, or future component reuse.
- The strongest prior-art lesson is not to import another system's tokens, but
  to adopt their discipline: semantic roles, tokenized states, coordinated layer
  scales, and strict no-literal guardrails.
- The brand lens remains "quiet polish, well-made developer tooling, not
  generic fintech." Status colors and focus states should be unmistakable, not
  decorative.
- The operator psychology lens: admin users scan under stress. Foundations
  should make "what is actionable, disabled, focused, selected, above/below,
  fresh/stale, and safe/dangerous" visually obvious without page-specific
  invention.

</specifics>

<deferred>
## Deferred Ideas

- Full replacement of Tailwind CLI with a neutral CSS bundler/minifier - future
  build-pipeline hardening only if Tailwind-as-compiler becomes a real
  maintenance problem.
- Broad overlay portaling/root overlay architecture - defer unless Phase 188
  discovers an unavoidable root stacking-context issue; page-flow overlay bugs
  remain Phase 191.
- Importing Radix/Primer/Polaris token packages - deferred; Phase 188 implements
  local `--ax-*` roles and uses those systems only as references.
- PhoenixStorybook adoption - still deferred; v1.53 extends the in-app
  `/dev/components` kitchen.

</deferred>

---

*Phase: 188-foundations-hardening*
*Context gathered: 2026-06-15*
