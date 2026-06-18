# Phase 191: page-flow-interaction-pass-fixture-stress-microcopy - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 191 is the page and flow integration pass for the already-hardened
`accrue_admin` surface. It walks every canonical admin page against its primary
operator job across happy, empty, loading, error, permission-denied, boundary,
advanced, disconnected/reconnecting, overflow, long-content, and
interactive-open paths.

This phase must fix the Phase 187 owner-phase `191` behavioral defects, expand
`examples/accrue_host` seeds and test-only forcing so every page-flow matrix
cell is reachable, and clean up page-flow microcopy using the Accrue brand voice.
It consumes the Phase 188 foundation tokens, Phase 189 primitive matrix, and
Phase 190 group contracts. It does not add billing primitives, public route/API
breaks, Tailwind migration, PhoenixStorybook, pixel-diff tooling, host chrome
redesign, or `accrue_portal` work.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**The Phase 191 UI design and interaction contract is locked.** See
`191-UI-SPEC.md` for the full design-system, page-flow, interaction, fixture,
microcopy, and verification contract. Downstream agents MUST read
`191-UI-SPEC.md` before planning or implementing. Requirements are not duplicated
here.

**In scope (from UI-SPEC and ROADMAP):**
- Resolve all Phase 187 `owner_phase == "191"` defects: currently 178 rows
  (70 high, 108 medium), with interaction-integrity, microcopy, state-coverage,
  scroll-reachability, layer/position, actionability, focus, and fixture gaps.
- Prove all canonical page flows from `accrue_admin/e2e/baseline-manifest.js`.
- Fix modal, drawer, dropdown, popover, toast, command-palette, mobile nav, and
  LiveView patch focus behavior where page-flow integration is responsible.
- Expand `examples/accrue_host` seeds and E2E forcing helpers for missing page
  matrix cells: null/missing optional fields, permission-denied, boundary
  pagination, high counts, non-ASCII names, disconnected/reconnecting, stable
  loading, and stable error states.
- Correct empty, filtered-empty, unavailable, permission, disconnected,
  recovery, error, and destructive-confirmation copy using Accrue voice.
- Produce trace-backed or observation-row evidence for fixed behavior at
  320, 375, 768, 1024, and 1440 widths in light and dark.

**Out of scope (from UI-SPEC and roadmap guardrails):**
- New billing domain features, new billing primitives, or public API/route
  breakage.
- `accrue_portal` work, host/demo chrome redesign, or product changes outside
  `accrue_admin` and `examples/accrue_host` fixture/test support.
- shadcn, third-party UI registries, Tailwind utility authoring, PhoenixStorybook,
  a new UI package, or a new visual-regression service.
- Re-opening Phase 188 token decisions, Phase 189 primitive decisions, or Phase
  190 group-contract decisions unless a root defect in those layers blocks this
  phase's page-flow contract.

</spec_lock>

<decisions>
## Implementation Decisions

### Discussion Outcome

- **D-01:** No additional user-facing decisions are required before planning.
  Phase 191 already has a locked UI-SPEC plus a Phase 190 handoff; the remaining
  choices are technical planning and research choices.
- **D-02:** Treat the corrected behavior in `191-UI-SPEC.md` as the regression
  target. Do not encode broken Phase 187 observations as expected behavior.
- **D-03:** Keep Phase 191 bounded to page-flow integration, fixture reachability,
  and microcopy. New capabilities discovered while walking pages belong in
  deferred ideas or later phases.

### Interaction Closure

- **D-04:** Phase 191 must close the Phase 190 D-30 handoff categories:
  focus trap, focus restore, Escape, click outside, scroll reachability, overlay
  position/layering, LiveView patch focus, fixture gaps, and microcopy.
- **D-05:** Active modal, drawer, command-palette, dropdown/popover, mobile nav,
  and protected confirmation behavior must be deterministic: focus stays inside
  while active, background controls are unreachable, close restores focus to the
  trigger or a stable fallback, Escape does not submit or navigate, and outside
  click never confirms or mutates billing state.
- **D-06:** LiveView patch, filter submit, pagination/load-more, row selection,
  tab/window change, optimistic update, reconnect, and async action completion
  must leave focus on a retained control, updated state alert, or page heading.
  Focus must not land on `body` or behind an overlay.
- **D-07:** Regression tests and planning artifacts must cite AX187 IDs or
  overlay tags for the behavior they cover.

### Page Matrix And Fixtures

- **D-08:** The page-flow matrix comes from `baseline-manifest.js` and the
  expanded `191-UI-SPEC.md` viewport/theme contract. Use the canonical surfaces
  and jobs-to-be-done already defined there.
- **D-09:** Fixture work should extend `examples/accrue_host` seeds and
  `accrue_admin/test/support` E2E forcing helpers only. Keep seeds deterministic,
  re-runnable, and namespaced (`e2e_phase191_*` or an equivalent clear namespace).
- **D-10:** One-click reachability is required. Each state cell must be reachable
  from a deterministic route, fixture endpoint, query param, dashboard launcher,
  filter chip, component proof link, or E2E helper without manual database edits.
- **D-11:** Existing host fixture assets already cover long names,
  multi-currency/JPY, dunning/at-risk, canceling subscriptions, webhook failure,
  overflow rows, and basic member-login permission probing. Phase 191 must fill
  the missing cells rather than duplicating these blindly.

### Microcopy

- **D-12:** Use the Accrue voice contract: measured, exact, native, durable.
  Copy must name the affected object, route, event, invoice, subscription,
  charge, customer, owner scope, config key, or recovery path.
- **D-13:** Empty-state copy must distinguish true empty, filtered empty, data
  unavailable, permission denied, and disconnected/reconnecting. Error copy must
  say what happened and what to do next.
- **D-14:** Destructive and consequential confirmations must name the action,
  specific object, billing effect, and audit consequence when applicable.

### Verification Evidence

- **D-15:** Evidence belongs in existing ignored Playwright output paths such as
  `accrue_admin/test-results`; committed planning artifacts should store
  references and summaries, not generated screenshots/traces.
- **D-16:** Keep existing gates green while adding Phase 191 coverage, especially
  `cd accrue_admin && npm run e2e:group-contracts`, touched admin a11y specs, and
  host seed idempotency tests.

### Claude's Discretion

- Exact plan decomposition, test file names, fixture endpoint/query-param shape,
  and sharding strategy are left to researcher/planner discretion, provided the
  locked UI-SPEC, canonical page matrix, and AX187/tag traceability are preserved.
- Technical choices for focus management may use Phoenix LiveView JS, small
  package-local hooks, or existing hooks/components. Do not add a broad client
  framework or third-party UI primitive library to solve this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 191 Contract

- `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-UI-SPEC.md` - Locked Phase 191 UI design, interaction, fixture, microcopy, registry-safety, page-flow, and evidence contract.
- `.planning/ROADMAP.md` - Phase 191 goal, requirements, success criteria, dependency on Phase 190, and v1.53 guardrails.
- `.planning/REQUIREMENTS.md` - IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02, plus milestone out-of-scope constraints.
- `.planning/PROJECT.md` - v1.53 reopen decision, stable-core posture, no-new-feature boundary, and admin UI hardening rationale.
- `.planning/STATE.md` - Current milestone position and accumulated v1.53 decisions.

### Baseline And Handoff

- `.planning/phases/187-audit-baseline/187-CONTEXT.md` - Phase 187 baseline decisions, owner-phase routing, and structured-artifact rule.
- `.planning/phases/187-audit-baseline/187-RUBRIC.md` - The 12 dimensions, overlay tags, and state taxonomy Phase 191 must satisfy.
- `.planning/phases/187-audit-baseline/187-BASELINE.md` - Baseline summary for only-forward comparison.
- `.planning/phases/187-audit-baseline/defects.ndjson` - Machine-readable defect ledger; filter `owner_phase == "191"` and cite AX187 IDs/tags in tests.
- `.planning/phases/187-audit-baseline/baseline.cells.json` - Frozen Phase 192 comparison cells and cell-id grammar.
- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-PHASE-191-HANDOFF.md` - D-30 handoff categories and Phase 191 acceptance targets.
- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md` - Group-contract decisions and explicit Phase 191 boundary.
- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md` - Recurring group contracts that Phase 191 must preserve while fixing flow behavior.

### Prior UI Decisions

- `.planning/phases/188-foundations-hardening/188-CONTEXT.md` - Locked foundation tokens, semantic layer stack, type roles, focus/disabled/read-only/status roles, motion and Tailwind SSOT decisions.
- `.planning/phases/189-primitive-form-components-component-lab/189-CONTEXT.md` - Primitive/form state-matrix decisions and single-column global-theme lab reversal.
- `.planning/research/v1.51-admin-ui-depth-design.md` - Prior admin design source: custom `ax-*` CSS, quiet developer-tooling direction, mobile-first posture, and anti-churn doctrine.

### Brand And Copy

- `brandbook/voice.md` - Ratified Accrue voice: measured, exact, native, durable.
- `brandbook/copy.md` - Approved copy blocks and mechanism-led wording examples.
- `brandbook/tokens/README.md` - Brand/admin token relationship; admin `--ax-*` tokens remain implementation SSOT.

### Code And Test Surfaces

- `accrue_admin/e2e/baseline-manifest.js` - Canonical page flows, state taxonomy, projects, themes, overlay tags, component groups, and cell-id grammar.
- `accrue_admin/e2e/admin-interactions.spec.js` - Existing observation-only live interaction probe; Phase 191 should convert relevant gaps into corrected regression coverage.
- `accrue_admin/e2e/admin-group-contracts.spec.js` - Phase 190 group-contract browser gate to keep green.
- `accrue_admin/e2e/admin-a11y.spec.js` and `accrue_admin/e2e/admin-visuals.spec.js` - Existing light/dark a11y and visual sweep patterns.
- `accrue_admin/assets/css/theme.css` - Admin token SSOT.
- `accrue_admin/assets/css/app.css` - Existing overlay, drawer, modal, dropdown, focus, disabled, read-only, responsive, and state class layer.
- `accrue_admin/assets/js/hooks/dropdown.js` - Current details-dropdown Escape/outside-click behavior.
- `accrue_admin/assets/js/hooks/command_palette.js` - Current command-palette focus restore, Escape, and keyboard selection hook.
- `accrue_admin/assets/js/hooks/accrue_shell_nav.js` - Current mobile nav Escape and close behavior.
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` - Shared drawer structure and current missing trap/restore behavior target.
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` - Shared protected confirmation modal and current focus push/pop baseline.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` - Canonical entity-queue data display; preserve pagination/filter/card-mode behavior.
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` and `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` - Phase 189/190 proof-surface registry and lab patterns.
- `accrue_admin/test/support/e2e_plug.ex` and `accrue_admin/test/support/e2e_fixtures.ex` - E2E reset/login/seed helper endpoints and fixture integration point.
- `examples/accrue_host/priv/repo/seeds/edge_states.exs`, `examples/accrue_host/priv/repo/seeds/showcase.exs`, `examples/accrue_host/priv/repo/seeds/background_data.exs`, and `examples/accrue_host/test/seeds_idempotency_test.exs` - Host seed patterns and idempotency guardrails.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `baseline-manifest.js` already enumerates the 20 canonical page flows and their
  operator jobs. Treat it as the page matrix backbone.
- `admin-interactions.spec.js` already has helpers for reset, seeding, login,
  member-login, observation rows, top-element checks, focus cycling, scroll
  probing, keyboard-only flow probing, permission probing, and offline probing.
- `DetailDrawer.detail_drawer/1` provides dialog semantics, backdrop, body, and
  footer structure for drawer fixes.
- `StepUpAuthModal.step_up_auth_modal/1` uses `Phoenix.LiveView.JS.push_focus/0`
  and `pop_focus/0`; it still needs full Phase 191 trap/dismissal behavior if
  required by the contract.
- `dropdown.js`, `command_palette.js`, and `accrue_shell_nav.js` already cover
  parts of Escape, outside click, and focus restore for transient UI.
- `E2E.Plug` and `E2E.Fixtures` already expose test-only reset/login/seed
  endpoints. Extend that layer for stable Phase 191 forcing rather than adding
  ad hoc test setup.

### Established Patterns

- Custom `ax-*` CSS classes and `--ax-*` tokens are the implementation source of
  truth. Phase 191 should consume existing type, focus, layer, status, disabled,
  read-only, spacing, and motion tokens.
- Existing generated evidence stays under `accrue_admin/test-results` or other
  ignored output paths; planning docs cite references and summaries.
- The Phase 187 cell-id grammar is frozen. New regression evidence should align
  to that grammar instead of inventing another result format.
- Phase 190 moved group proof into `/billing/dev/components`; Phase 191 uses
  those group contracts but must prove live page-flow behavior.

### Integration Points

- Page-flow tests enter through `/__e2e__/login`, `/__e2e__/login-member`,
  `/__e2e__/reset`, and `/__e2e__/seed/*`.
- Fixture expansion connects to `AccrueAdmin.E2E.Fixtures` for E2E tests and to
  `examples/accrue_host/priv/repo/seeds/*.exs` for local click-through data.
- Overlay and focus fixes connect through shared components/hooks first, then
  page-specific LiveViews only when the defect is genuinely page-flow local.
- Microcopy fixes connect through existing copy helpers where present; otherwise
  keep object-specific strings close to the affected component/page and avoid
  vague state labels.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 191 as the closure pass for the handoff list, not as a new audit.
  Start from `defects.ndjson`, `190-PHASE-191-HANDOFF.md`, and `191-UI-SPEC.md`.
- Use `admin-interactions.spec.js` as a pattern library, but write corrected
  behavior assertions where Phase 187 only recorded observations or gaps.
- Prefer shared root fixes for overlay/focus behavior when the same issue appears
  on multiple pages. Page-local fixes are acceptable only when the state or
  LiveView patch is genuinely page-local.
- Fixture expansion should be minimal and matrix-driven: add the smallest stable
  seed/helper needed to prove each missing state cell.
- Keep copy plain and object-specific. Examples from the locked contract include
  `Access restricted`, `Connection lost. Reconnecting before actions can run.`,
  `No billing records yet`, `No records match these filters`, and verb+noun
  button labels such as `Replay webhook`, `Refund charge`, and `Clear filters`.

</specifics>

<deferred>
## Deferred Ideas

- Pixel-diff visual-regression tooling remains deferred to TOOL-02.
- PhoenixStorybook remains deferred to TOOL-01.
- Replacing Tailwind-as-compiler with a different CSS bundler remains outside
  Phase 191.
- Broad product, billing-domain, or `accrue_portal` capabilities remain outside
  this milestone unless a future strategy artifact reopens them.

</deferred>

---

*Phase: 191-page-flow-interaction-pass-fixture-stress-microcopy*
*Context gathered: 2026-06-18*
