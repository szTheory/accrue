# Phase 189: Primitive & form components + component lab - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Systematize every **primitive and form component** in isolation: exercise each
across its full state matrix (default / hover / focus / active / pressed /
disabled / loading / selected / empty / error / overflow) in both light and dark
themes and across the two declared viewports, verify a11y (correct role, full
keyboard operation, visible focus, accessible name), fix every defect **at the
component root** so it propagates to every consuming page, and grow
`/dev/components` into the systematic gallery that proves it (extended in-app
kitchen — **no PhoenixStorybook dependency, no new build deps**).

This phase consumes the Phase-188 foundation (composed type roles, z-index layer
stack, focus-visible / disabled / readonly / status semantic roles, motion atoms)
and applies it to leaf/atomic components. It is **not** the meta-component /
group pass (Phase 190), the page/flow interaction pass (Phase 191), or the
verification/sign-off pass (Phase 192). No per-page patching, no new billing
primitives, no breaking component public-API changes.

Requirements covered: CMP-01, CMP-02, CMP-03, CMP-04, CMP-05 (see
`.planning/REQUIREMENTS.md`).

</domain>

<decisions>
## Implementation Decisions

User selected all four gray areas (189/190 split, lab gallery structure,
state-matrix scope + verification, root-fix enforcement). Two were researched via
parallel advisor agents (lab gallery, verification); both converged decisively on
**extending the existing Phase-187/188 infrastructure** rather than introducing
new tooling. Per the maintainer's opinionated / `minimal_decisive` profile, the
package below is locked for planning — none of these are high-impact/irreversible
forks.

### 189 / 190 Component Inventory Split

- **D-01:** Phase 189 owns **leaf / atomic primitives and form controls**:
  `button` (primary / secondary / ghost / danger variants), `input`
  (text / number / email / password), `textarea`, checkbox / radio /
  toggle-switch, native `select`, the form field wrapper (label / help / error /
  required affordance), `status_badge` / tag / pill, `icon`, `money_formatter`,
  `json_viewer`, the spinner / skeleton / loading primitive, tooltip, inline
  code / id display, and the **non-interactive empty-state hero** (the CMP-03
  "no misleading affordance" exemplar).
- **D-02:** Phase 190 owns the **composites, navigation, data-display, and
  overlay/meta groups** — explicitly NOT in 189: `data_table`, `kpi_card`,
  `funnel_chart`, `app_shell` / `sidebar` / `topbar`, `tabs`, `breadcrumbs`,
  pagination, `detail` / `detail_drawer`, `timeline` / `campaign_timeline`,
  `dropdown_menu`, `related_resources`, `filter_chip_bar`, `global_search`,
  `step_up_auth_modal`, `flash_group`, modal-confirm, `window_selector`,
  `at_risk_table`, `dunning_banner`, `tax_ownership_card`. Overlay components go
  to 190 because they are group/meta surfaces consuming the 188 layer tokens.
- **D-03:** If a defect found on a 189 primitive actually originates in a 190
  group's composition, fix the primitive root here and record the group-level
  manifestation as a Phase-190 owner-routed note — do not patch the group in 189.

### Lab Gallery Structure

- **D-04:** Keep the **single `/dev/components` route**. Do not split into
  per-component routes — that would erode the registry-as-SSOT story and force a
  rewrite of the four existing `component_registry_test.exs` mount loops for no
  functional gain on a `Mix.env() != :prod` surface.
- **D-05:** Grow `ComponentRegistry` with declarative **`states` and `specimens`**
  fields per entry, and drive ONE matrix renderer off it (rows = applicable
  states; **light and dark columns side-by-side**; viewport handled by the
  existing top-bar theme/width controls). The exact state list a test asserts is
  the exact list the grid paints — "tested ⇔ shown" stays mechanically true.
- **D-06:** Bake **long / overflowing-content specimens** (long IDs, names, URLs,
  module names) into the `specimens` data deliberately — they do not fall out of
  the state list and are required by CMP-02.
- **D-07 (GOTCHA — do not skip):** Per-specimen light/dark wrappers were
  previously **inert** because no CSS re-scoped `--ax-*` inside them (see
  `component_kitchen_live.ex` inline comments ~lines 166-168). The new
  `.ax-dev-state-grid` theme columns MUST genuinely re-scope the token layer, and
  the drift test MUST assert a **resolved-color delta** between the light and dark
  cells — never merely that both theme classes are present.
- **D-05 / D-07 SUPERSEDED (2026-06-18, post-execution):** The side-by-side
  **two-column light/dark** layout (D-05) and its **sub-tree token re-scoping**
  mechanism (D-07) are reversed. The lab now renders a **single state-matrix
  column that follows the global topbar theme toggle**, like every other admin
  page. Rationale: (1) dark-mode verification is redundant — `admin-a11y.spec.js`
  already toggles the global `data-theme` and scans every surface, incl. the
  kitchen, in **both** themes; (2) the D-07 `.accrue-admin [data-theme="dark"]`
  sub-tree mechanism was the source of a dark-column text-contrast bug and added
  real complexity; (3) the two-column layout produced a broken mobile render
  (~195,000px — both columns stacked). Removed: the dark column + "Light"/"Dark"
  headers, the `.ax-dev-state-grid-col` `color` re-declaration, the mobile
  collapse rule, and the `themeColumnDeltaProbe` e2e. The `.accrue-admin
  [data-theme="dark"]` block in `theme.css` is retained (now unused by the lab;
  harmless) to avoid frozen-foundation churn and the FND-05 verifier coupling.
  "tested ⇔ shown" still holds for the state list; theme coverage moves to the
  global-toggle a11y/visual sweeps.
- **D-08 (coupling gotcha):** Adding the `states`/`specimens` registry fields
  requires lockstep updates to `component_registry_test.exs`, or the existing
  drift/negative tests break. This mirrors the established verifier ↔
  negative-fixture coupling pattern.

### State-Matrix Scope + Verification

- **D-09:** Add an **`applicable_states`** field per `ComponentRegistry` entry
  gating the frozen Phase-187 `COMPONENT_STATES` taxonomy. Record every
  non-applicable state as an explicit **`n/a` row with a stated reason** (the
  pattern already in `admin-interactions.spec.js`) — coverage stays auditable and
  is never silently dropped.
- **D-10:** Verify correctness in **three deterministic layers** (extend the
  existing harness; introduce no new runner):
  1. `@axe-core/playwright` sweep with `wcag2a` / `wcag2aa` (including
     `color-contrast`) per theme on the kitchen route, on **settled colors**
     (reduced-motion + settle delay) — the pattern `admin-a11y.spec.js` already
     uses.
  2. `getComputedStyle` / `elementFromPoint` probes for the Phase-188 invariants:
     focus-ring `outline-width >= 2px` + offset + halo on `:focus-visible`;
     `disabled` / `readonly` bg / border / text / cursor resolve to the 188
     tokens; accessible name present (aria/label); **no clip** via
     `scrollWidth <= clientWidth` + overlap check; button text vs background
     contrast (CMP-04).
  3. Reuse the existing PNG capture + `score-visuals.mjs` vision pass for the
     subjective hierarchy / brand dimensions.
- **D-11:** Keep the **two frozen viewports** (1440 desktop / 390 mobile) from the
  Phase-187 `baseline-manifest.js` PROJECTS. Do not add breakpoints.
- **D-12:** Write each verification result keyed to the **existing
  `p187__{surface}__{mode}__{theme}__{state}__{dXX}` cell-id grammar** into the
  NDJSON ledger, so Phase 192 re-runs idempotently (`reset` + `seed`, unique-int
  IDs, NDJSON rewritten each run) and scores per-cell against the Phase-187
  baseline with zero regressions. The cell-id grammar is **frozen** — do not
  change it.
- **D-13:** **No visual-regression snapshot tooling** (`toHaveScreenshot`,
  Playwright CT). Pixel snapshots are cross-platform-flaky, semantically blind to
  WCAG (a passing snapshot can still be 2.9:1 contrast or have no focus ring), and
  would create a parallel scoring axis Phase 192 must reconcile against the frozen
  grid.

### Root-Fix Enforcement (CMP-05)

- **D-14:** All component visual/brand fixes land **only** in component HEEx +
  `theme.css` / `app.css` tokens. No per-page CSS overrides of primitive `ax-*`
  classes.
- **D-15:** Add a **verifier + negative-fixture guard** (the established
  Phase-188 coupling pattern) that flags per-page overrides of primitive `ax-*`
  classes and raw inline `style` on primitives — complementing the existing
  typography-literal ban (D-05 of Phase 188) and no-literal-z-index guard.

### Claude's Discretion

- Exact registry schema shape for `states` / `specimens` / `applicable_states`
  (keyword list vs map vs struct), as long as it stays the single source the lab
  renderer and the drift/coverage tests both read.
- Exact `.ax-dev-state-grid` layout/markup, provided the theme columns genuinely
  re-scope `--ax-*` and side-by-side light/dark is achieved.
- Whether the per-page-override guard is an Elixir test, a shell verifier, or
  both — provided it follows the verifier ↔ negative-fixture coupling pattern.
- Plan/wave decomposition (e.g. registry+renderer first, then per-family root
  fixes, then verification harness) — left to the planner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Milestone Scope
- `.planning/ROADMAP.md` — Phase 189 goal, 5 success criteria, v1.53 guardrails,
  strictly-linear 187→…→192 dependency sequence.
- `.planning/PROJECT.md` — v1.53 posture, admin-UI hardening rationale, no-new-
  feature boundary.
- `.planning/REQUIREMENTS.md` — CMP-01..05 plus v1.53 out-of-scope constraints.
- `.planning/STATE.md` — current milestone state and accumulated v1.53 decisions.

### Prior Phase Foundation (MUST READ — Phase 189 consumes these)
- `.planning/phases/188-foundations-hardening/188-CONTEXT.md` — locked foundation
  decisions: composed type roles (D-01..06), layer stack (D-07..11), Tailwind SSOT
  resolution (D-12..16), semantic role completion incl. focus-visible / disabled /
  readonly / status tokens (D-17..22), motion gap closure (D-23..25).
- `.planning/phases/187-audit-baseline/187-RUBRIC.md` — rubric dimensions, overlay
  tags, owner-phase mapping; the dimensions Phase 192 scores against.
- `.planning/phases/187-audit-baseline/187-BASELINE.md` — baseline summary +
  defect-ledger overview.
- `.planning/phases/187-audit-baseline/defects.ndjson` — machine-readable defect
  ledger; filter `owner_phase == 189` for the primitives/form defects this phase
  remediates.
- `.planning/phases/187-audit-baseline/baseline.cells.json` — canonical scored
  cells for Phase-192 comparison.

### Prior Admin-UI / Design-System Decisions
- `.planning/research/v1.51-admin-ui-depth-design.md` — locked admin design
  source: custom `ax-*` CSS, no Tailwind migration, quiet developer-tooling
  direction, mobile-first, anti-churn doctrine.

### Brand & Voice
- `brandbook/README.md`, `brandbook/voice.md`, `brandbook/copy.md`,
  `brandbook/tokens/README.md`, `brandbook/tokens/tokens.json` — brand asset
  guidance, ratified voice (measured, exact, native, durable), token layer.

### Existing Code (primary edit surfaces)
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — SSOT to extend with
  `states` / `specimens` / `applicable_states` schema.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — single
  `/dev/components` route; convert hand-authored sections to a registry-driven
  matrix renderer. Note inline comments (~lines 166-168) flagging previously-inert
  per-specimen theme wrappers (see D-07).
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — 4 drift/token
  tests reading the registry against the one mounted page; extend in lockstep
  (D-08).
- `accrue_admin/lib/accrue_admin/router.ex` — `live("/dev/components", ...)` route
  to keep.
- `accrue_admin/assets/css/app.css` — `ax-*` class system + existing
  `.ax-dev-grid` / `.ax-dev-variant-row`; add `.ax-dev-state-grid` + side-by-side
  theme-column rules; primitive component state selectors.
- `accrue_admin/assets/css/theme.css` — token SSOT consumed by primitives.
- Primitive/form component sources owned by this phase:
  `accrue_admin/lib/accrue_admin/components/button.ex`, `input.ex`, `select.ex`,
  `status_badge.ex`, `icon.ex`, `money_formatter.ex`, `json_viewer.ex` (plus any
  checkbox/radio/toggle/textarea/spinner/tooltip/empty-state primitives surfaced
  during planning).
- `accrue_admin/e2e/baseline-manifest.js` — frozen `COMPONENT_STATES` taxonomy,
  `p187__…` cell-id grammar, two PROJECTS (1440/390). Do not mutate the grammar.
- `accrue_admin/e2e/admin-a11y.spec.js` — settled-color axe sweep pattern to
  extend.
- `accrue_admin/e2e/admin-interactions.spec.js` — NDJSON ledger +
  `getComputedStyle` / `elementFromPoint` probe + `n/a`-with-reason pattern.
- `accrue_admin/e2e/reduced-motion.spec.js` — reduced-motion regression guard.
- `accrue_admin/e2e/score-visuals.mjs` — vision-score layer for subjective
  dimensions.
- `scripts/ci/verify_package_docs.sh` — existing verifier pattern for the CMP-05
  per-page-override guard (verifier ↔ negative-fixture coupling).

### External Primary References
- `https://playwright.dev/docs/accessibility-testing` — axe-core/Playwright a11y
  testing.
- `https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html` — focus
  indicator size/contrast expectations (CMP-03, D-10).
- `https://www.w3.org/WAI/ARIA/apg/patterns/` — ARIA APG patterns for interactive
  primitives (role/keyboard/name).
- `https://storybook.js.org/docs/writing-stories/stories-for-multiple-components`
  — component-state-matrix gallery idiom (concept reference; we do NOT adopt
  Storybook).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ComponentRegistry` already drives 4 drift/token tests against the one mounted
  `/billing/dev/components` page — the proven SSOT to deepen (add state-matrix
  metadata), not replace.
- The Phase-187 e2e harness already provides everything the verification gray
  area needs: frozen cell-id grammar, `COMPONENT_STATES` taxonomy, two viewports,
  NDJSON observation ledger with `coverage_status` / `failure_kind`, axe sweep,
  computed-style probes, and a vision-score pass.
- Native HTML controls (`<select>`, `<input>`) mean keyboard operation and role
  largely come for free — no custom listbox/combobox build is needed; preserve
  the native controls.
- Phase 188 foundation tokens (focus-visible, disabled, readonly, status pairs,
  type roles, motion atoms) are the values primitives must consume — Phase 189 is
  application + proof, not token invention.

### Established Patterns
- Custom `ax-*` CSS + CSS custom properties are the implementation SSOT; host apps
  never run AccrueAdmin's Tailwind.
- Verifier changes must update both the guard and its negative-test fixture.
- Generated screenshots/traces stay outside committed planning artifacts; only
  references/checksums/cell results belong in planning docs unless a human sign-off
  asks for representative evidence.
- "Tested ⇔ shown": the registry state list a test asserts is the same list the
  lab grid renders.

### Integration Points
- Registry `states`/`specimens`/`applicable_states` feed BOTH the lab matrix
  renderer and the drift/coverage tests — single source.
- Component root fixes flow through component HEEx + `theme.css`/`app.css`; no
  LiveView route or public component API change expected.
- Verification results key into the existing `p187__…` NDJSON cell grid so Phase
  192 diffs against the Phase-187 baseline idempotently.
- Phase 190 consumes the same hardened primitives inside recurring component
  groups; Phase 191 owns page/flow-specific interaction defects not solvable at
  the component root.

</code_context>

<specifics>
## Specific Ideas

- Both advisor researchers independently reached the same conclusion: the
  decisive move is to **extend the frozen Phase-187/188 scaffolding**, because any
  parallel tool (per-component routes, visual-regression snapshots, Playwright CT)
  would erode the registry-as-SSOT story and force Phase 192 to reconcile a second
  scoring axis against the frozen cell grid.
- The operator-psychology lens from Phase 188 carries forward: a primitive must
  make "actionable / disabled / focused / selected / loading / error" visually
  unmistakable on its own, before any page context.
- Brand lens unchanged: quiet polish, well-made developer tooling — status and
  focus states unmistakable, not decorative.

</specifics>

<deferred>
## Deferred Ideas

- Per-component lab routes / Storybook-style isolated canvases — deferred; single
  registry-driven route is sufficient for a dev-only surface (D-04).
- Visual-regression snapshot baselines (`toHaveScreenshot` / Playwright CT) —
  deferred/rejected for this milestone (D-13); flaky and semantically blind to
  WCAG.
- Meta-component / group cohesion (tables, cards, nav, tabs, pagination, KPI,
  detail, timeline, drawer, modal-confirm) — **Phase 190**.
- Page/flow interaction defects, focus restoration after LiveView patches,
  per-page scroll/overlay behavior, microcopy, seed/fixture stress — **Phase
  191**.
- PhoenixStorybook adoption — still deferred across v1.53 (TOOL-01).

</deferred>

---

*Phase: 189-primitive-form-components-component-lab*
*Context gathered: 2026-06-17*
