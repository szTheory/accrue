# Phase 190: Navigation, data-display & meta-component cohesion - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit and harden recurring `accrue_admin` component groups as units: app shell,
nav, tabs, pagination, tables, cards, detail layouts, timeline, KPI/chart/table
clusters, and meta groups such as page-header + actions + breadcrumbs,
toolbar/search/filter/sort, table + empty/loading/error/pagination,
detail-header + metadata + actions, modal-confirm, drawer + form, and
tabs/subviews.

This phase consumes the Phase 188 foundation tokens and the Phase 189 primitive
matrix. It makes group-level spacing rhythm, hierarchy, responsive degradation,
obvious next action, operator-stress states, and reusable group contracts
coherent. It is not the Phase 191 page/flow pass: full focus traps, page scroll
locking, Escape/click-outside regression coverage, LiveView patch focus
recovery, fixture expansion, disconnected/reconnecting state coverage, and broad
microcopy cleanup belong to Phase 191 unless the reusable group root is clearly
responsible.

Requirements covered: GRP-01, GRP-02, GRP-03, GRP-04 (see
`.planning/REQUIREMENTS.md`).

</domain>

<decisions>
## Implementation Decisions

The user selected all four gray areas and requested subagent-backed,
recommendation-first research across Elixir/Phoenix idioms, software
architecture, DX, UI/UX, accessibility, operator psychology, design-system
practice, ecosystem lessons, and the repo prompt/brand corpus. Four advisor
researchers independently converged on the same shape: keep Phase 190
contract-first and group-level, use `/billing/dev/components` as the deterministic
proof surface, sample real pages only for integration drift, and hand off
page-flow interaction work explicitly to Phase 191.

### Group Proof Model

- **D-01:** Phase 190 uses a **hybrid proof model**. `/billing/dev/components`
  becomes the canonical proof surface for recurring component groups; live admin
  pages provide representative integration probes only.
- **D-02:** Add stable group locators, preferably `data-component-group="{slug}"`,
  matching the Phase 187 `COMPONENT_GROUPS` names:
  `page-header/actions/breadcrumbs`, `toolbar/search/filter/sort`,
  `table/empty/loading/error/pagination`, `KPI/chart/table`,
  `detail-header/metadata/actions`, `modal-confirm`, `drawer/form`, and
  `tabs/subviews`.
- **D-03:** Close the Phase 187 owner-phase 190 visibility gaps by rendering the
  group surfaces concretely in the lab. The baseline currently records 280
  Phase-190 defects, with 245 on `detail-header/metadata/actions` because the
  named group was not visible in static capture.
- **D-04:** Do not add PhoenixStorybook, per-group routes, pixel snapshots, or a
  second visual-regression axis. Extend the in-app kitchen and existing
  Playwright/axe/baseline infrastructure.
- **D-05:** Keep the frozen Phase 187 cell-id grammar and group names. Update
  selectors/specimens around the manifest; do not rename surfaces or dimensions.
- **D-06:** Group specimens must include operator-stress states where applicable:
  long content, overflow, empty, filtered-empty, loading, error, no-pagination,
  has-pagination, selected/filter-active, mobile card/list degradation, and dark
  mode through the global theme toggle.
- **D-07:** Live probes should be narrow and representative: one list/table page,
  one detail page, one recovery/KPI page, one drawer/modal path, and app
  shell/nav/tabs behavior. Do not turn Phase 190 into the Phase 191 page-flow
  matrix.

### Data-Display Degradation

- **D-08:** Standardize **behavior**, not one universal markup shape. `DataTable`
  stays the canonical renderer for entity queues: customers, subscriptions,
  invoices, charges/payments, webhooks, events, coupons, promotion codes, and
  connect accounts.
- **D-09:** Domain-specific data displays such as `AtRiskTable`, KPI/chart/table
  stacks, timelines, and detail metadata may remain specialized, but they must
  implement the same data-display contract: title or label, primary value,
  secondary facts, status/action affordances, empty/loading/error states,
  pagination or explicit no-pagination state, long-content behavior, and mobile
  card/list readability.
- **D-10:** `DataTable` desktop table plus mobile card mode is the default for
  searchable/filterable/bulk-manageable collections. Card fields must be explicit
  per resource so mobile does not lose the row's identity or action context.
- **D-11:** Avoid duplicate accessible DOM and duplicate focus targets. If both
  table and card markup exist at different breakpoints, hidden markup must remain
  inaccessible and non-focusable in the inactive mode.
- **D-12:** Pagination and "load more" controls appear only when there is a
  `next_cursor` or equivalent more-data signal. If there is nothing to paginate,
  the control disappears or de-emphasizes; row count remains useful only when it
  helps the operator understand scope.
- **D-13:** Filtered-empty and true-empty states are distinct. Filtered-empty copy
  should make clearing filters the next useful action; true-empty copy should
  explain when records will appear.
- **D-14:** Tables should degrade to readable cards/lists below the established
  medium breakpoint where the data shape allows it. Horizontal overflow is a
  last resort for machine-like data, not the default for operator queues.
- **D-15:** `AtRiskTable` is the main specialized-table exemplar to fix: it may
  keep its domain-specific component, but it needs mobile card/list behavior and
  the shared empty/loading/error/pagination/no-pagination contract.

### Hierarchy Rhythm

- **D-16:** Phase 190 defines a **small group contract**, not a broad new layout
  framework. Prefer specimens, CSS refinements, and narrow slot/API additions
  over replacing existing page markup with many new wrapper components.
- **D-17:** Group contracts should document order and hierarchy:
  breadcrumbs/orientation before task heading, primary action in the same visual
  band as the task, filters close to the table they constrain, summary KPIs
  before row-level evidence, and detail actions adjacent to the object identity.
- **D-18:** Fix nested "box prison" at the group level. Do not stack cards inside
  cards unless the inner card is a repeated item or genuinely framed tool. Detail
  sections, related resources, KPI cards, timeline cards, and summary cards need
  a consistent elevation and spacing rhythm.
- **D-19:** `ax-*` spacing/type/radius/layer tokens remain the implementation
  source of truth. Any new group CSS must consume existing Phase 188 tokens
  rather than adding local one-off values.
- **D-20:** Keep Phoenix component ergonomics flexible: use function components,
  attrs, and slots for reusable group shells where repeated markup is already
  painful; avoid rigid "layout objects" that force every page into the same
  wrapper.
- **D-21:** The component kitchen should include group specimens for page header,
  toolbar/filter state, table with pagination states, KPI/chart/table, detail
  header with actions/metadata, drawer/form, modal-confirm, and tabs/subviews.
  These are proof specimens, not a new public documentation site.
- **D-22:** Mobile and dark/system theme checks follow existing global mechanisms.
  Do not revive Phase 189's rejected side-by-side light/dark columns.

### Overlay And Meta-Component Boundary

- **D-23:** Phase 190 owns reusable group contracts for `modal-confirm`,
  `drawer + form`, `dropdown/menu`, `global_search` command palette,
  `tabs/subviews`, `window_selector`, `data_table + empty/loading/error/pagination`,
  `flash/toast`, toolbar/search/filter/sort, page-header/actions/breadcrumbs,
  KPI/chart/table, and detail-header/metadata/actions.
- **D-24:** Phase 190 may change group markup, CSS, and API shape only for GRP
  outcomes: spacing rhythm, hierarchy, obvious next action, responsive
  degradation, operator-stress states, layer-token consumption, and reusable
  slot/action layout.
- **D-25:** Phase 190 must not complete full focus traps, page scroll locking,
  Escape/click-outside regression coverage, LiveView patch focus recovery,
  fixture expansion, or broad microcopy cleanup. Those are Phase 191 unless the
  reusable group root is provably the cause.
- **D-26:** `modal-confirm` and `drawer + form` contracts should define
  title/description IDs, action order, cancel/destructive affordance, scrollable
  body/footer behavior, responsive sizing, and semantic layer role. Focus trap,
  focus restore, Escape, and click-outside behavior are handed to Phase 191.
- **D-27:** `dropdown_menu` must choose disclosure semantics or true menu-button
  semantics. Do not keep `role="menu"` on a simple disclosure unless Phase 191
  supplies the corresponding menu keyboard contract.
- **D-28:** `tabs` and `window_selector` stay link-navigation with
  `aria-current="page"` unless a surface actually renders same-page tab panels.
  Do not force APG `tablist` semantics onto route or patch navigation.
- **D-29:** Pagination belongs to Phase 190 for visual/group behavior:
  placement, absent state, active/filter states, readable mobile card/list
  degradation, and table footer rhythm. Cursor behavior and page-flow stress
  remain Phase 191 when fixture-dependent.
- **D-30:** Phase 190 must emit a Phase 191 handoff list keyed to Phase 187 defect
  IDs or overlay tags for focus trap, focus restore, Escape, click-outside,
  scroll reachability, overlay position, LiveView patch focus, fixture gaps, and
  microcopy.

### Claude's Discretion

- Exact implementation shape for group contracts: registry entries, a
  `GROUP-CONTRACTS.md` planning artifact, component-kitchen sections, or a
  combination, provided downstream planning has one canonical contract and the
  lab/probes read from the same names.
- Exact slug grammar for `data-component-group`, as long as it maps directly to
  Phase 187 `COMPONENT_GROUPS` and avoids changing the cell-id grammar.
- Exact division of CSS-only refinements versus small slot/API additions, as long
  as new abstractions are introduced only where repeated group markup already
  creates drift.
- Exact representative live routes for integration probes, as long as they cover
  one list/table, one detail, one recovery/KPI, one overlay path, and shell/nav.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Milestone Scope

- `.planning/ROADMAP.md` - Phase 190 goal, success criteria, v1.53 guardrails,
  and strict 187 -> 188 -> 189 -> 190 -> 191 -> 192 dependency shape.
- `.planning/PROJECT.md` - v1.53 posture, admin UI hardening rationale, and
  no-new-feature boundary.
- `.planning/REQUIREMENTS.md` - GRP-01..04 plus adjacent IXN/PAGE/CPY/SEED
  boundaries that remain Phase 191.
- `.planning/STATE.md` - current milestone state and accumulated v1.53 decisions,
  including the Phase 189 single-column lab reversal.

### Prior Phase Baseline And Decisions

- `.planning/phases/187-audit-baseline/187-CONTEXT.md` - baseline decisions,
  owner-phase routing, structured artifact rule.
- `.planning/phases/187-audit-baseline/187-RUBRIC.md` - 12 dimensions, overlay
  tags, state taxonomy, and owner-phase split for 190 versus 191.
- `.planning/phases/187-audit-baseline/187-BASELINE.md` - baseline summary; note
  Phase 190 has 280 group-owned defects.
- `.planning/phases/187-audit-baseline/defects.ndjson` - machine-readable defect
  ledger; filter `owner_phase == "190"` for group gaps and responsive risk probes.
- `.planning/phases/187-audit-baseline/baseline.cells.json` - canonical Phase 192
  comparison cells; do not change cell grammar.
- `.planning/phases/188-foundations-hardening/188-CONTEXT.md` - foundation
  tokens, layer stack, type roles, semantic states, focus/disabled/scrollbar
  roles, and Tailwind SSOT decisions.
- `.planning/phases/189-primitive-form-components-component-lab/189-CONTEXT.md`
  - primitive/form split, Phase 190 ownership of composites/overlays, and the
  post-execution single-column global-theme lab decision.

### Prior Admin UI And Brand Decisions

- `.planning/research/v1.51-admin-ui-depth-design.md` - locked admin design
  source: cordoned hybrid IA, custom `ax-*` CSS, mobile-first posture, quiet
  developer-tooling direction, anti-churn doctrine.
- `brandbook/voice.md` - ratified voice: measured, exact, native, durable;
  microcopy boundary and vocabulary.
- `brandbook/copy.md` - approved error/empty-state microcopy patterns.
- `brandbook/tokens/README.md` - brand/admin token relationship; admin
  `--ax-*` tokens stay implementation SSOT.
- `brandbook/tokens/tokens.json` - current brand-token SSOT.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - maintainer preference for
  subagent-backed research, idiomatic Elixir lens, DX/UX-first judgment, and
  done-enough restraint.
- `prompts/accrue-brand-book.md` - historical brand seed only where it does not
  conflict with `brandbook/`.

### Existing Code Surfaces

- `accrue_admin/e2e/baseline-manifest.js` - Phase 187 dimensions, state taxonomy,
  projects, `COMPONENT_GROUPS`, surface names, and frozen cell-id grammar.
- `accrue_admin/e2e/admin-a11y.spec.js` - global light/dark a11y sweep pattern.
- `accrue_admin/e2e/admin-interactions.spec.js` - live interaction observations,
  NDJSON pattern, and Phase 191 handoff signals.
- `accrue_admin/e2e/admin-baseline.spec.js` - baseline capture entry point if
  present/used by planner.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` - in-app
  `/billing/dev/components` surface to extend with group specimens.
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` - existing
  registry-as-SSOT pattern from Phase 189; extend or mirror for group contracts.
- `accrue_admin/assets/css/theme.css` - admin token SSOT.
- `accrue_admin/assets/css/app.css` - group CSS, responsive breakpoints, card,
  data-table, detail, KPI, tabs, nav, overlay, and layer styles.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` - canonical
  entity-queue data display with filters, cursor pagination, selection, empty
  state, poll/newer rows, desktop table, and mobile cards.
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` - specialized
  recovery table requiring shared data-display state/responsive contract.
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` - applied-filter
  state and clear-action group.
- `accrue_admin/lib/accrue_admin/components/kpi_card.ex` - KPI card contract,
  linked-card affordance, delta tone, sparkline/meta slots.
- `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` - KPI/chart/table
  recovery cluster companion.
- `accrue_admin/lib/accrue_admin/components/detail.ex` - summary card, detail
  section, and field-list group building blocks.
- `accrue_admin/lib/accrue_admin/components/related_resources.ex` - related
  billing cross-link card and detail-threading group.
- `accrue_admin/lib/accrue_admin/components/timeline.ex` and
  `campaign_timeline.ex` - chronological data-display groups.
- `accrue_admin/lib/accrue_admin/components/app_shell.ex`, `sidebar.ex`,
  `topbar.ex`, and `nav.ex` - shell/nav group.
- `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex`, `tabs.ex`, and
  `window_selector.ex` - navigation/meta groups.
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`,
  `dropdown_menu.ex`, `global_search.ex`, `step_up_auth_modal.ex`, and
  `flash_group.ex` - overlay/meta groups whose composition belongs to 190 and
  live interaction behavior mostly belongs to 191.
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` - existing
  query/filter/cursor/card-mode tests.
- `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` -
  current nav/tabs/window/dropdown tests.
- `accrue_admin/test/accrue_admin/components/display_components_test.exs` -
  current display/detail/KPI/timeline/filter tests.
- `accrue_admin/lib/accrue_admin/live/*_live.ex` - production list/detail pages
  that provide representative live-page integration probes.

### External Primary References

- `https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html` - Phoenix
  function components, attrs, and slots for reusable markup contracts.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html` - stateful
  LiveComponent boundary used by `DataTable` and similar components.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html` - DOM-patch
  aware JS commands, show/hide/toggle/transitions, and focus helpers.
- `https://phoenix-live-view.hexdocs.pm/live-navigation.html` - LiveView patch
  navigation and URL/query-state behavior.
- `https://www.w3.org/WAI/ARIA/apg/patterns/` - APG pattern index for dialog,
  breadcrumb, tabs, menu button, and disclosure distinctions.
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/` - modal dialog focus,
  inertness, Escape, and focus-return contract for Phase 191 handoff.
- `https://www.w3.org/WAI/ARIA/apg/patterns/tabs/` - use only when same-page
  tab panels exist; route-navigation tabs should remain links.
- `https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/` and
  `https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/` - dropdown semantics
  decision point.
- `https://shopify.dev/docs/api/app-home/patterns/compositions/index-table` -
  index-table composition: search/filter/sort/bulk/pagination as one group.
- `https://carbondesignsystem.com/components/data-table/usage/` - data-table
  anatomy, toolbar, pagination, row action, and density guidance.
- `https://carbondesignsystem.com/patterns/empty-states-pattern/` - empty-state
  distinctions and recovery guidance.
- `https://design-system.service.gov.uk/components/pagination/` - pagination,
  filtering/sorting, and defaults that reduce paging burden.
- `https://docs.stripe.com/stripe-apps/patterns/empty-state` - billing-adjacent
  empty-state pattern: explain no data and link to the relevant place when useful.
- `https://docs.stripe.com/api/pagination` - cursor-style pagination precedent
  for billing records.
- `https://designsystem.digital.gov/components/table/` - responsive stacked
  table precedent when rows become cards/lists.
- `https://getbootstrap.com/docs/5.3/content/tables/` - horizontal overflow
  pattern as fallback, not default.
- `https://getbootstrap.com/docs/5.0/layout/z-index/` - coordinated z-index
  scale lesson; Accrue already implements semantic layer tokens locally.
- `https://www.radix-ui.com/primitives/docs/components/dialog` - complete
  dialog anatomy/behavior reference for Phase 191, not a Phase 190 dependency.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `DataTable` already has the right Phoenix/Ecto shape for entity queues:
  query modules with `decode_filter/1`, `encode_filter/1`, `list/1`,
  `count_newer_than/1`, signed opaque cursor pagination, URL filter params,
  selection, desktop table, and mobile card markup.
- `AtRiskTable` is a domain-specific data display that currently reads like a
  horizontal table. It is the exemplar for "specialized component must still
  honor the shared group contract."
- `ComponentKitchenLive` and `ComponentRegistry` already proved the lab-as-SSOT
  pattern in Phase 189. Phase 190 should extend this pattern to group specimens
  rather than introduce a new dependency or page structure.
- `baseline-manifest.js` already enumerates exactly the component groups Phase
  190 must prove; use those names as the planning and locator backbone.
- `Detail.summary_card`, `Detail.detail_section`, `RelatedResources`,
  `KpiCard`, `Timeline`, `FilterChipBar`, `Tabs`, `WindowSelector`,
  `Sidebar`, `Topbar`, `DetailDrawer`, `DropdownMenu`, `GlobalSearch`,
  `StepUpAuthModal`, and `FlashGroup` are the group building blocks; do not
  rebuild them from scratch.

### Established Patterns

- Custom `ax-*` CSS and CSS custom properties are the design-system SSOT.
- Existing verifier changes should follow the Phase 188/189 pattern: update the
  guard and any negative fixture together.
- Generated screenshots/traces stay in `test-results/` or existing generated
  output conventions; planning artifacts reference paths/checksums/cell results.
- The lab follows the global theme toggle. Dark-mode coverage comes from
  global a11y/visual sweeps rather than side-by-side theme columns.
- Phase 187 structured artifacts win over markdown if there is disagreement.
- Route/navigation tab components currently use link semantics with
  `aria-current`; APG `tablist` is not automatically appropriate.

### Integration Points

- Group specimens connect through `/billing/dev/components` and should be
  reachable by the Phase 187 manifest route/anchor or equivalent group selector.
- Representative live probes connect through existing admin routes such as
  `/billing/invoices`, `/billing/subscriptions`, `/billing/webhooks`,
  `/billing/analytics/recovery`, and detail pages.
- Phase 192 consumes the same `baseline.cells.json` and `defects.ndjson` grammar;
  Phase 190 should produce evidence in that shape rather than inventing a new
  result format.
- Phase 191 consumes the handoff list for focus trap, focus restore, Escape,
  click-outside, scroll reachability, overlay position, LiveView patch focus,
  fixture gaps, and microcopy.

</code_context>

<specifics>
## Specific Ideas

- The coherent implementation package is: **small group contracts + canonical
  kitchen specimens + representative live probes + explicit Phase 191 handoff**.
  This preserves the v1.53 phase split and gives the planner enough structure to
  avoid re-litigating tools or semantics.
- The strongest data-display rule is "standardize the behavior, not the markup."
  Entity queues use `DataTable`; specialized domain displays keep their shape
  only if they satisfy the same state/responsive/action contract.
- Operator psychology lens: billing operators scan under stress. Component
  groups should make identity, status, next action, filters, pagination, and
  destructive/cancel affordances obvious without relying on page-specific taste.
- Design direction stays "quiet, well-made developer tooling." Avoid generic
  SaaS dashboard decoration, noisy cards, overly rounded containers, nested
  panels, and hidden controls that require remembering keyboard shortcuts.
- Ecosystem lessons to copy: Storybook-style multi-component stories without
  the dependency; Polaris/Carbon table compositions; GOV.UK pagination defaults;
  Stripe/Carbon empty states that explain data absence and next action.
- Ecosystem footguns to avoid: one universal table API that flattens domain
  meaning; live-page-only proof that hides group gaps; lab-only proof that never
  exercises shell constraints; APG roles without the corresponding keyboard
  behavior; one-off z-index fixes instead of semantic layer tokens.

</specifics>

<deferred>
## Deferred Ideas

- Full modal/drawer focus traps, Escape/click-outside behavior, focus restore,
  scroll locking/reachability, and corrected regression tests - Phase 191.
- LiveView disconnected/reconnecting state, fixture stress, permission-denied
  paths, and page-flow microcopy cleanup - Phase 191.
- Pixel-diff visual regression tooling - still deferred to TOOL-02.
- PhoenixStorybook adoption - still deferred to TOOL-01.
- Replacing Tailwind-as-compiler with another CSS bundler - out of Phase 190.

</deferred>

---

*Phase: 190-navigation-data-display-meta-component-cohesion*
*Context gathered: 2026-06-18*
