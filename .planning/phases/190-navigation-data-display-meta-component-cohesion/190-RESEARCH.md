# Phase 190: Navigation, data-display & meta-component cohesion - Research

**Researched:** 2026-06-18
**Domain:** Phoenix LiveView admin UI group contracts, data-display composition, accessibility semantics, and validation architecture
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this entire section: [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

### Locked Decisions

The user selected all four gray areas and requested subagent-backed,
recommendation-first research across Elixir/Phoenix idioms, software
architecture, DX, UI/UX, accessibility, operator psychology, design-system
practice, ecosystem lessons, and the repo prompt/brand corpus. Four advisor
researchers independently converged on the same shape: keep Phase 190
contract-first and group-level, use `/billing/dev/components` as the deterministic
proof surface, sample real pages only for integration drift, and hand off
page-flow interaction work explicitly to Phase 191.

#### Group Proof Model

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

#### Data-Display Degradation

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

#### Hierarchy Rhythm

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

#### Overlay And Meta-Component Boundary

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

### the agent's Discretion

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

### Deferred Ideas (OUT OF SCOPE)

- Full modal/drawer focus traps, Escape/click-outside behavior, focus restore,
  scroll locking/reachability, and corrected regression tests - Phase 191.
- LiveView disconnected/reconnecting state, fixture stress, permission-denied
  paths, and page-flow microcopy cleanup - Phase 191.
- Pixel-diff visual regression tooling - still deferred to TOOL-02.
- PhoenixStorybook adoption - still deferred to TOOL-01.
- Replacing Tailwind-as-compiler with another CSS bundler - out of Phase 190.
</user_constraints>

## Summary

Phase 190 should be planned as a group-contract hardening pass on top of the existing Phoenix LiveView function components, LiveComponents, component kitchen, Phase 187 manifest, and Phase 188 `ax-*` token system. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] The strongest plan shape is: add one canonical group contract source, render each contract in `/billing/dev/components`, add `data-component-group` locators that map to Phase 187 `COMPONENT_GROUPS`, and run only representative live-page probes for integration drift. [VERIFIED: accrue_admin/e2e/baseline-manifest.js]

Do not plan a redesign framework, PhoenixStorybook migration, pixel-diff system, route expansion, or dependency upgrade. [VERIFIED: .planning/ROADMAP.md] The repo already has Phoenix 1.8.7, Phoenix LiveView 1.1.31, `DataTable`, component registry/kitchen patterns, Playwright, axe, and custom CSS tokens installed and exercised by tests. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/package.json]

**Primary recommendation:** implement a small `group_contracts/0` registry plus kitchen group specimens, then harden DataTable/AtRisk/KPI/detail/timeline/nav/overlay groups against GRP-01..04 with tokenized spacing, clear hierarchy, responsive card/list degradation, pagination absence behavior, and Phase 191 handoff annotations. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

## Project Constraints (from CLAUDE.md)

- Accrue is an Elixir/Phoenix billing and payments library with an admin LiveView companion; Phase 190 work must stay in the admin UI hardening scope and not add billing primitives. [VERIFIED: CLAUDE.md]
- The admin package requires Phoenix LiveView and hard-depends on LiveView for `accrue_admin`; this phase should use Phoenix LiveView idioms rather than introducing a separate frontend framework. [VERIFIED: CLAUDE.md]
- Custom `ax-*` CSS and tokens are the admin design-system source of truth; Tailwind remains only the compiler/scanner path and should not become the design-system API. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/188-foundations-hardening/188-CONTEXT.md]
- The project posture is "stable core, demand-driven expansion"; research should not recommend speculative new features or broad dependency churn. [VERIFIED: CLAUDE.md]
- No `AGENTS.md` file exists in the repository root, so there are no additional project-specific AGENTS directives to apply. [VERIFIED: command `test -f AGENTS.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRP-01 | Each recurring component group (page-header + actions + breadcrumbs; toolbar + search + filters + sort; table + empty/loading/error/pagination; KPI + chart + table; detail-header + metadata + actions; modal-confirm; drawer + form; tabs + subviews) is audited as a unit for spacing rhythm, hierarchy, and obvious next action. [VERIFIED: .planning/REQUIREMENTS.md] | Use the group contract registry, kitchen specimens, and `data-component-group` locator map; evaluate order, primary action placement, tokenized gaps, state visibility, and Phase 191 handoff tags per group. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| GRP-02 | Tables degrade to readable cards/lists (not squished columns) at narrow widths, and tables are not used where a list/card pattern fits the data better. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `DataTable` as the default for searchable/filterable/bulk collections, require explicit `card_fields`, fix `AtRiskTable` as the specialized exemplar, and verify mobile breakpoints in Playwright. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/at_risk_table.ex] |
| GRP-03 | Nested containers do not read as an accidental "box prison," and stat/KPI cards are visually consistent across every screen. [VERIFIED: .planning/REQUIREMENTS.md] | Use Phase 188 tokens, remove unnecessary nested card frames, align `KpiCard`, `Detail.summary_card`, `RelatedResources`, and timeline/card rhythm under one group spacing/elevation contract. [VERIFIED: accrue_admin/assets/css/theme.css] [VERIFIED: accrue_admin/assets/css/app.css] |
| GRP-04 | Pagination and similar affordances disappear or de-emphasize when there is nothing to paginate; filter/sort/active/selected states are unmistakable. [VERIFIED: .planning/REQUIREMENTS.md] | Preserve `next_cursor`-gated DataTable footer behavior, add no-pagination/has-pagination kitchen states, distinguish true-empty from filtered-empty, and assert clear filter/sort/selected states. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] [CITED: https://design-system.service.gov.uk/components/pagination/] |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Group contract registry and slug map | API / Backend | Browser / Client | Phoenix renders group HTML and stable `data-component-group` attributes; CSS/Playwright consume the resulting DOM. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex] |
| `/billing/dev/components` group proof surface | Frontend Server (SSR) | Browser / Client | The dev LiveView renders deterministic specimens, then browser tests verify responsive, dark, focus, and axe behavior. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex] |
| App shell, nav, breadcrumbs, tabs, window selector | Frontend Server (SSR) | Browser / Client | Phoenix components render link/navigation semantics and `aria-current`; browser tests validate current state and responsive shell behavior. [VERIFIED: accrue_admin/lib/accrue_admin/components/sidebar.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/tabs.ex] |
| DataTable entity queues | Frontend Server (SSR) | API / Backend | `DataTable` is a stateful LiveComponent whose query module owns filtering, listing, counts, cursor decoding, and URL-state encoding. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] |
| Specialized data displays | Frontend Server (SSR) | Browser / Client | `AtRiskTable`, `KpiCard`, `FunnelChart`, `Detail`, and timeline components render domain-specific summaries; CSS and responsive tests enforce the shared display contract. [VERIFIED: accrue_admin/lib/accrue_admin/components/at_risk_table.ex] |
| Modal-confirm, drawer+form, dropdown, search, flash | Frontend Server (SSR) | Browser / Client | Phase 190 owns structure, roles, IDs, ordering, layer tokens, and visible states; full focus trap/restore/Escape/click-outside behavior is Phase 191. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Baseline/evidence capture | Browser / Client | API / Backend | Playwright reads Phase 187 manifest surfaces and writes observations; Phoenix only needs stable lab/live DOM for the probes. [VERIFIED: accrue_admin/e2e/admin-baseline.spec.js] [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js] |

## Standard Stack

### Core

| Library / Local Surface | Version | Purpose | Why Standard |
|-------------------------|---------|---------|--------------|
| Phoenix | 1.8.7 locked; 1.8.8 latest as of registry check on 2026-06-18 | Phoenix rendering and component/HEEx foundation | Existing package constraint is `~> 1.8`; do not upgrade in Phase 190 because dependency churn is out of scope. [VERIFIED: npm/hex registry via `mix hex.info phoenix`] [VERIFIED: accrue_admin/mix.exs] |
| Phoenix LiveView | 1.1.31 locked; 1.2.3 latest as of registry check on 2026-06-18 | Function components, LiveComponents, JS commands, live navigation | Existing `DataTable`, component kitchen, global search, and admin pages are LiveView-based; plan against the locked version. [VERIFIED: npm/hex registry via `mix hex.info phoenix_live_view`] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| Phoenix.Component attrs/slots | Phoenix/LiveView bundled | Reusable group shells and narrow component APIs | Phoenix docs describe function components as the rendering building block; use attrs and slots for repeated group markup that does not own state. [CITED: https://phoenix.hexdocs.pm/components.html] |
| Existing `DataTable` LiveComponent | Local | Canonical searchable/filterable/bulk entity queue | It already implements filters, cursor pagination, selection, desktop table, mobile card markup, and empty/filter-clear behavior. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] |
| Existing `ComponentRegistry` and `ComponentKitchenLive` | Local | In-app proof surface and registry-as-SSOT pattern | Phase 189 established registry-driven specimens and `/billing/dev/components` as the deterministic lab; extend this instead of adding Storybook. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex] [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex] |
| `ax-*` CSS tokens | Local | Spacing, type, radius, states, z/layer rhythm | Phase 188 made `theme.css` and `app.css` the source of truth; Phase 190 group CSS must consume existing tokens. [VERIFIED: accrue_admin/assets/css/theme.css] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Phoenix LiveView JS | Bundled with LiveView 1.1.31 | Show/hide/focus/patch helpers for existing overlays and nav | Use only for existing structural commands; defer complete focus trap/restore/Escape/click-outside coverage to Phase 191. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html] |
| Playwright | 1.59.1 installed; 1.61.0 latest on npm on 2026-06-18 | E2E, responsive, baseline, and interaction probes | Use existing npm scripts and specs; do not add visual snapshot tooling. [VERIFIED: command `npm list @playwright/test --depth=0`] [VERIFIED: command `npm view @playwright/test version`] [VERIFIED: accrue_admin/package.json] |
| `@axe-core/playwright` | 4.11.3 installed and latest on npm on 2026-06-18 | Automated accessibility scan in light/dark surfaces | Keep global axe sweep and add group specimen coverage as needed. [VERIFIED: command `npm list @axe-core/playwright --depth=0`] [VERIFIED: command `npm view @axe-core/playwright version`] [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] |
| `lazy_html` | 0.1.11 locked | HTML assertions in component tests | Use for targeted DOM assertions in component tests, especially group locator and duplicate focus checks. [VERIFIED: npm/hex registry via `mix hex.info lazy_html`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Component kitchen group specimens | PhoenixStorybook | Deferred by Phase 190 context; Storybook would add a new dependency and proof surface when the in-app lab already exists. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Baseline/axe/interaction probes | Pixel snapshots | Pixel-diff tooling is deferred to TOOL-02 and would add a second visual regression axis. [VERIFIED: .planning/ROADMAP.md] |
| Small group contract registry | New universal layout framework | Locked scope requires behavior and group cohesion, not page rewrites or rigid layout objects. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Disclosure semantics for current dropdown | Full APG menu button | A menu button requires menu roles plus keyboard/focus behavior; current `DropdownMenu` uses native `details`, so Phase 190 should choose disclosure semantics unless Phase 191 supplies the full menu contract. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/] |

**Installation:**

```bash
# No new packages for Phase 190.
# Use the existing locked Elixir and npm dependencies.
```

**Version verification:** Phoenix, LiveView, Phoenix HTML, lazy_html, Playwright, and axe versions were verified with `mix deps`, `mix hex.info`, `npm list`, and `npm view` on 2026-06-18. [VERIFIED: command output]

## Package Legitimacy Audit

Phase 190 should not install external packages; the package legitimacy gate is therefore not triggered. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | n/a | No new dependency approved or required. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/package.json] |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```text
Phase 187 manifest COMPONENT_GROUPS
  -> Group contract registry (slug, name, states, specimens, probe tags)
    -> /billing/dev/components group sections
      -> data-component-group="{slug}" proof DOM
        -> Playwright baseline + axe + interaction probes
          -> GRP evidence + Phase 191 handoff list

Production admin pages
  -> existing Phoenix components (DataTable, Detail, KPI, Timeline, Nav, Overlay)
    -> narrow live probes only
      -> integration drift findings
```

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/dev/
│   ├── component_registry.ex       # add group_contracts/0 or a small sibling registry
│   └── component_kitchen_live.ex   # render group specimens from the same contracts
├── lib/accrue_admin/components/
│   ├── data_table.ex               # canonical queue display
│   ├── at_risk_table.ex            # specialized-table exemplar to harden
│   ├── detail.ex                   # summary/detail field contract
│   ├── kpi_card.ex                 # KPI consistency contract
│   ├── timeline.ex                 # chronological display contract
│   └── *_drawer/modal/dropdown.ex  # overlay/meta group roots
├── assets/css/
│   ├── theme.css                   # token SSOT
│   └── app.css                     # group layout/state CSS using tokens
├── test/accrue_admin/components/   # component DOM contract tests
└── e2e/                            # baseline, axe, interactions, narrow live probes
```

`accrue_admin/lib/accrue_admin/components/nav.ex` is listed in Phase 190 canonical refs but is not present on disk; shell/nav ownership is currently in `app_shell.ex`, `sidebar.ex`, `topbar.ex`, `breadcrumbs.ex`, `tabs.ex`, and `window_selector.ex`. [VERIFIED: `rg --files accrue_admin/lib/accrue_admin/components`]

### Pattern 1: Canonical Group Contract Registry

**What:** Define one local data source for group names, slugs, required states, primary components, proof specimen IDs, and Phase 191 handoff tags. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex]

**When to use:** Use this for all Phase 190 group specimen rendering, locator tests, and baseline assertions; do not let lab names, Playwright selectors, and component code drift independently. [VERIFIED: accrue_admin/e2e/baseline-manifest.js]

**Example:**

```elixir
# Source: local ComponentRegistry pattern and Phase 187 COMPONENT_GROUPS.
def group_contracts do
  [
    %{
      name: "page-header/actions/breadcrumbs",
      slug: "page-header-actions-breadcrumbs",
      states: [:default, :long_content, :mobile, :dark],
      proof_id: "group-page-header",
      phase191_handoff: []
    },
    %{
      name: "modal-confirm",
      slug: "modal-confirm",
      states: [:default, :destructive, :long_content],
      proof_id: "group-modal-confirm",
      phase191_handoff: [:focus_trap, :focus_restore, :escape, :click_outside]
    }
  ]
end
```

### Pattern 2: Stable Group Locators Without Cell Grammar Changes

**What:** Add `data-component-group={slug}` to each kitchen group specimen root and to reusable group roots where production components naturally own the group. [VERIFIED: accrue_admin/e2e/admin-baseline.spec.js]

**When to use:** Use the slug map derived from Phase 187 names; do not rename `COMPONENT_GROUPS`, surface names, dimensions, or cell-id grammar. [VERIFIED: accrue_admin/e2e/baseline-manifest.js]

**Example:**

```heex
<section
  id="group-table-empty-loading-error-pagination"
  class="ax-group-specimen ax-stack ax-stack--lg"
  data-component-group="table-empty-loading-error-pagination"
>
  <.live_component module={AccrueAdmin.Components.DataTable} id="group-table-demo" query_module={...} />
</section>
```

### Pattern 3: Behavior Contract Over Universal Markup

**What:** Entity queues use `DataTable`; specialized displays can keep their markup if they expose the same group states: title/label, primary value, secondary facts, status/action affordances, empty/loading/error, pagination/no-pagination, long content, and mobile card/list readability. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

**When to use:** Apply this to `AtRiskTable`, KPI/chart/table, timelines, and detail metadata so the operator can scan identity, status, next action, and scope consistently without forcing all displays into a generic table. [VERIFIED: accrue_admin/lib/accrue_admin/components/at_risk_table.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/kpi_card.ex]

**Example:**

```heex
<section class="ax-at-risk-group" data-component-group="table-empty-loading-error-pagination">
  <header class="ax-group-heading">
    <h2 class="ax-title-sm">At-risk subscriptions</h2>
    <p class="ax-body-sm">Rows need recovery triage.</p>
  </header>

  <div class="ax-at-risk-grid" aria-hidden={@mobile?}>
    <%!-- desktop table --%>
  </div>

  <div class="ax-at-risk-cards">
    <%!-- mobile cards with explicit identity, status, eta, action --%>
  </div>
</section>
```

### Pattern 4: Link Navigation Stays Link Navigation

**What:** Keep `Tabs` and `WindowSelector` as navigational links with `aria-current="page"` for route/patch navigation. [VERIFIED: accrue_admin/lib/accrue_admin/components/tabs.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/window_selector.ex]

**When to use:** Use APG `tablist` only if the component renders same-page tab panels and implements tab keyboard behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/]

**Example:**

```heex
<nav class="ax-tabs" aria-label="Billing views" data-component-group="tabs-subviews">
  <.link :for={tab <- @tabs} patch={tab.to} aria-current={tab.active && "page"}>
    {tab.label}
  </.link>
</nav>
```

### Pattern 5: Overlay Contracts Stop At Structure In Phase 190

**What:** `modal-confirm` and `drawer + form` contracts define title/description IDs, action order, cancel/destructive affordance, scrollable body/footer behavior, responsive sizing, semantic layer role, and tokenized z-index. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

**When to use:** Use this for `DetailDrawer`, `StepUpAuthModal`, confirmation modal specimens, and overlay kitchen proof; do not plan full focus trap/restore/Escape/click-outside completion until Phase 191. [VERIFIED: accrue_admin/lib/accrue_admin/components/detail_drawer.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex]

**Example:**

```heex
<section
  role="dialog"
  aria-modal="true"
  aria-labelledby={"#{@id}-title"}
  aria-describedby={"#{@id}-description"}
  data-component-group="modal-confirm"
  class="ax-modal-confirm"
>
  <header><h2 id={"#{@id}-title"}>Cancel invoice?</h2></header>
  <p id={"#{@id}-description"}>This cannot be undone after confirmation.</p>
  <footer class="ax-action-row">
    <button type="button" class="ax-btn ax-btn--secondary">Keep invoice</button>
    <button type="button" class="ax-btn ax-btn--danger">Cancel invoice</button>
  </footer>
</section>
```

### Anti-Patterns to Avoid

- **Role without behavior:** Do not keep `role="menu"` on `DropdownMenu` while using native disclosure semantics and no menu keyboard contract. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/]
- **Lab-only proof:** Do not stop at kitchen specimens; add representative live probes for one list/table, one detail, one recovery/KPI, one overlay path, and shell/nav/tabs. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
- **Live-page-only proof:** Do not use production pages as the sole evidence source; Phase 187 already showed group visibility gaps when named group surfaces are not concretely rendered in static capture. [VERIFIED: .planning/phases/187-audit-baseline/187-BASELINE.md]
- **Box prison:** Do not nest cards inside cards except repeated items or genuinely framed tools; prefer unframed group sections with consistent spacing and repeated item cards only where the content is an item. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
- **One-off spacing:** Do not introduce local pixel values when `--ax-space-*`, type, radius, and layer tokens already exist. [VERIFIED: accrue_admin/assets/css/theme.css]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Component proof surface | PhoenixStorybook or per-group route system | Existing `/billing/dev/components` and registry pattern | Locked by context; avoids new dependency and proof-surface split. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Entity queue display | A second generic table system | Existing `DataTable` LiveComponent | It already handles filters, cursor pagination, selection, desktop/mobile rendering, empty state, and polling. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] |
| Responsive queue cards | Auto-generated mobile cards from every column | Explicit `card_fields` per resource | Explicit fields preserve row identity and action context on mobile. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Overlay focus model | Custom partial focus trap in Phase 190 | Structural contract now, Phase 191 focus/dismiss pass later | Context explicitly defers focus trap, focus restore, Escape, click-outside, scroll locking, and regression tests. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Dropdown accessibility | ARIA menu roles without keyboard support | Native disclosure semantics for current `details` component | APG menu-button requires menu focus behavior; current component is a disclosure. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] |
| Visual regression | New pixel diff axis | Existing baseline/axe/interaction specs | Pixel-diff tooling is deferred to TOOL-02. [VERIFIED: .planning/ROADMAP.md] |

**Key insight:** Phase 190 is a cohesion phase, not a framework phase; group contracts should make repeated compositions observable, testable, and consistent while leaving complex page-flow behavior to Phase 191. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: `data-component-group` Slugs Drift From Phase 187 Names

**What goes wrong:** Baseline probes continue to miss group surfaces or generate misleading gaps. [VERIFIED: accrue_admin/e2e/admin-baseline.spec.js]
**Why it happens:** The lab, component code, and manifest use different names or slugs. [VERIFIED: accrue_admin/e2e/baseline-manifest.js]
**How to avoid:** Store Phase 187 name and derived slug in one group contract registry and test every group appears once in the kitchen. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex]
**Warning signs:** `admin-baseline.spec.js` still records visibility gaps for component-group surfaces after the lab changes. [VERIFIED: .planning/phases/187-audit-baseline/defects.ndjson]

### Pitfall 2: Duplicate Focusable DOM In Table/Card Breakpoints

**What goes wrong:** Keyboard users can tab to both desktop and mobile controls or assistive tech sees duplicate row actions. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
**Why it happens:** Both table and card markup exist for breakpoints; if hidden with visual-only CSS, inactive markup remains reachable. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]
**How to avoid:** Keep inactive mode `display: none` or otherwise remove it from accessibility/focus order; add a Playwright tab-order or focusable-count assertion at mobile and desktop widths. [VERIFIED: accrue_admin/assets/css/app.css]
**Warning signs:** `locator('a,button,input,select,textarea,[tabindex]')` returns duplicate row actions in hidden table/card mode. [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js]

### Pitfall 3: Treating Pagination As Decoration

**What goes wrong:** Operators see disabled or irrelevant pagination when there is no more data, or they miss pagination when there is a `next_cursor`. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Pagination controls are styled as a fixed table footer rather than rendered from the more-data signal. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]
**How to avoid:** Render pagination/load-more only for `next_cursor` or equivalent; include no-pagination and has-pagination specimens in the lab. [CITED: https://design-system.service.gov.uk/components/pagination/]
**Warning signs:** Empty or short data sets still show disabled page controls, or footer rhythm changes when filters are active. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 4: APG Role Mismatch

**What goes wrong:** Axe may pass while keyboard behavior remains wrong because ARIA roles imply interaction that does not exist. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/]
**Why it happens:** `DropdownMenu` currently uses native `details` but renders `role="menu"` and `role="menuitem"`. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex]
**How to avoid:** Use disclosure semantics now; reserve true menu-button semantics for Phase 191 if it implements the keyboard contract. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/]
**Warning signs:** Tests assert `role="menu"` but do not assert arrow-key navigation, focus movement, or menu closing behavior. [VERIFIED: accrue_admin/test/accrue_admin/components/navigation_components_test.exs]

### Pitfall 5: Overlays Creep Into Phase 191 Work

**What goes wrong:** Phase 190 burns scope on focus traps, Escape/click-outside, scroll lock, fixture expansion, or LiveView patch focus recovery. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
**Why it happens:** Modal/drawer structure and modal/drawer behavior are easy to conflate. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]
**How to avoid:** Phase 190 only defines title/description IDs, action order, cancel/destructive affordance, scrollable body/footer layout, responsive sizing, role/layer semantics, and handoff tags. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
**Warning signs:** A Phase 190 task adds new global keydown/click-outside listeners or rewrites overlay JS behavior. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

Verified patterns from official and local sources:

### Group Locator Assertion

```elixir
# Source: local component test pattern + Phase 187 group manifest.
test "all Phase 187 component groups render in the kitchen" do
  html = render_component_kitchen()

  for slug <- [
        "page-header-actions-breadcrumbs",
        "toolbar-search-filter-sort",
        "table-empty-loading-error-pagination",
        "kpi-chart-table",
        "detail-header-metadata-actions",
        "modal-confirm",
        "drawer-form",
        "tabs-subviews"
      ] do
    assert html =~ ~s(data-component-group="#{slug}")
  end
end
```

### Pagination Gate

```heex
<!-- Source: DataTable currently gates load-more on @next_cursor. -->
<footer class="ax-data-table-footer">
  <p class="ax-data-table-count">{length(@rows)} records</p>
  <button
    :if={@next_cursor}
    type="button"
    class="ax-btn ax-btn--secondary"
    phx-click="load_more"
    phx-target={@myself}
  >
    Load more
  </button>
</footer>
```

### Disclosure Dropdown Semantics

```heex
<!-- Source: WAI APG Disclosure pattern and current DropdownMenu details structure. -->
<details class="ax-dropdown" data-component-group="toolbar-search-filter-sort">
  <summary class="ax-btn ax-btn--secondary">
    Actions
  </summary>
  <div class="ax-dropdown-panel" aria-label="Actions">
    <a :for={item <- @items} href={item.href} class="ax-dropdown-item">
      {item.label}
    </a>
  </div>
</details>
```

### Link Navigation Tabs

```heex
<!-- Source: local Tabs/WindowSelector plus APG tabs boundary. -->
<nav class="ax-tabs" aria-label={@label} data-component-group="tabs-subviews">
  <.link :for={tab <- @tabs} patch={tab.to} aria-current={tab.active && "page"}>
    <span>{tab.label}</span>
    <span :if={tab[:count]} class="ax-tabs-count">{tab.count}</span>
  </.link>
</nav>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Storybook-style proof via new dependency | In-app component kitchen specimens | Locked for Phase 190 on 2026-06-18 | Planner should extend `/billing/dev/components`, not add PhoenixStorybook. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |
| Live-page-only UI audit | Deterministic lab plus narrow live probes | Phase 187 -> 190 split | Group visibility gaps close in the lab while production probes detect integration drift. [VERIFIED: .planning/phases/187-audit-baseline/187-BASELINE.md] |
| Generic horizontal table at every width | Table on desktop plus explicit mobile card/list where the data supports it | GRP-02 scope | USWDS documents stacked tables for narrow screens and local `DataTable` already has card markup. [CITED: https://designsystem.digital.gov/components/table/] [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] |
| Route tabs modeled as APG tab widgets | Link navigation with `aria-current="page"` | Phase 190 decision | Avoids tablist semantics unless same-page tab panels exist. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/] |
| Local z-index fixes | Semantic `--ax-z-*` layer tokens | Phase 188 | Overlay group work should use existing `--ax-z-dropdown`, `--ax-z-drawer`, `--ax-z-modal`, and `--ax-z-toast`. [VERIFIED: accrue_admin/assets/css/theme.css] |

**Deprecated/outdated:**

- `role="menu"` on a native disclosure without menu keyboard behavior is out of bounds for Phase 190; use disclosure semantics now. [VERIFIED: accrue_admin/lib/accrue_admin/components/dropdown_menu.ex] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/]
- Side-by-side light/dark lab columns were rejected by Phase 189; use the global theme toggle and light/dark e2e sweeps. [VERIFIED: .planning/phases/189-primitive-form-components-component-lab/189-CONTEXT.md]
- Horizontal overflow as the default mobile table strategy should be last resort for machine-like data, not normal operator queues. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | No `[ASSUMED]` claims were used. | All sections | No user confirmation required for assumed claims. |

## Open Questions (RESOLVED)

These items were open during research because the exact implementation shape was
left to the agent's discretion in `190-CONTEXT.md`. They are resolved for the
current plans and are retained here only as traceable decision records.

1. **Should the canonical group contract live inside `ComponentRegistry` or a sibling dev module?**
   - What we know: Phase 189 already uses `ComponentRegistry` as a dev-only registry-as-SSOT, and 190-CONTEXT allows registry entries, a planning artifact, kitchen sections, or a combination. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex] [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
   - What's unclear: The exact implementation file is discretionary. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
   - **RESOLVED:** Use `AccrueAdmin.Dev.ComponentRegistry.group_contracts/0` as the canonical source. Plans 01 and 02 depend on that helper and keep the kitchen, registry tests, group contract ledger, and Playwright probes reading the same source. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-01-PLAN.md] [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-02-PLAN.md]

2. **Which live routes should be representative probes?**
   - What we know: Context requires one list/table, one detail, one recovery/KPI, one overlay path, and shell/nav. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
   - What's unclear: Exact routes are discretionary. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md]
   - **RESOLVED:** Use `/billing/invoices` or `/billing/subscriptions` for list/table, a matching detail route for detail, `/billing/analytics/recovery` for KPI/chart/table, the existing drawer/modal path covered by admin interactions, and `/billing/dev/components` for shell/nav/tabs proof. Plan 05 owns the representative live-probe wiring and must keep the probe set narrow per D-07. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-05-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix compile/tests | Yes | 1.19.5 with OTP 28 | None needed. [VERIFIED: command `elixir --version`] |
| Mix | Elixir tests, deps, assets | Yes | 1.19.5 | None needed. [VERIFIED: command `mix --version`] |
| Phoenix | Admin rendering | Yes | 1.8.7 locked | Do not upgrade in Phase 190. [VERIFIED: command `mix deps`] |
| Phoenix LiveView | Components, LiveComponents, JS helpers | Yes | 1.1.31 locked | Do not upgrade in Phase 190. [VERIFIED: command `mix deps`] |
| Node.js | Playwright/e2e tooling | Yes | 22.14.0 | None needed. [VERIFIED: command `node --version`] |
| npm | e2e scripts and package checks | Yes | 11.1.0 | None needed. [VERIFIED: command `npm --version`] |
| Playwright CLI | e2e validation | Yes | 1.59.1 | None needed; use existing scripts. [VERIFIED: command `./node_modules/.bin/playwright --version`] |
| Knowledge graph | Optional graph context | No | `.planning/graphs/graph.json` absent | Continue without graph context. [VERIFIED: command `test -f .planning/graphs/graph.json`] |

**Missing dependencies with no fallback:**

- None for Phase 190 research/planning. [VERIFIED: command output]

**Missing dependencies with fallback:**

- Knowledge graph is absent; local file/context review is sufficient for this phase. [VERIFIED: command `test -f .planning/graphs/graph.json`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix component rendering, Playwright 1.59.1, `@axe-core/playwright` 4.11.3. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/package.json] |
| Config file | `accrue_admin/package.json` scripts plus Mix project config. [VERIFIED: accrue_admin/package.json] [VERIFIED: accrue_admin/mix.exs] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/display_components_test.exs` |
| Full suite command | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && mix test && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js && npm run e2e -- e2e/admin-interactions.spec.js` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| GRP-01 | Every Phase 187 group has one canonical contract, kitchen specimen, and `data-component-group` locator; group order/hierarchy/primary action is inspectable. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] | unit + e2e baseline | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/components/navigation_components_test.exs && npm run e2e -- e2e/admin-baseline.spec.js` | Partial; registry test likely needs Wave 0 expansion. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex] |
| GRP-02 | `DataTable` retains desktop/table plus mobile/card behavior; `AtRiskTable` gains mobile card/list behavior and shared state contract. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/at_risk_table.ex] | unit + responsive e2e | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/display_components_test.exs && npm run e2e -- e2e/admin-baseline.spec.js` | Partial; add `AtRiskTable` coverage. [VERIFIED: accrue_admin/test/accrue_admin/components/display_components_test.exs] |
| GRP-03 | Nested card/elevation rhythm and KPI consistency use `--ax-*` tokens and avoid card-in-card except repeated items/framed tools. [VERIFIED: accrue_admin/assets/css/theme.css] | component + e2e visual/a11y assertions | `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs && npm run e2e:a11y` | Partial; CSS rhythm assertions need targeted probes. [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] |
| GRP-04 | Pagination hidden/de-emphasized when no cursor; filter/sort/active/selected states visible and distinct; true-empty and filtered-empty differ. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] | unit + interaction e2e | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs && npm run e2e -- e2e/admin-interactions.spec.js` | Partial; add no-pagination/has-pagination kitchen states. [VERIFIED: accrue_admin/test/accrue_admin/components/data_table_test.exs] |

### Sampling Rate

- **Per task commit:** `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/display_components_test.exs`
- **Per CSS-affecting task:** `cd accrue_admin && mix accrue_admin.assets.build` before e2e, because Phase 189 verification recorded that source CSS must be rebuilt into `priv/static/accrue_admin.css`. [VERIFIED: .planning/phases/189-primitive-form-components-component-lab/189-VERIFICATION.md]
- **Per wave merge:** `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && mix test && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js`
- **Phase gate:** Full suite plus `npm run e2e -- e2e/admin-interactions.spec.js`, with generated observations left in existing `test-results/` paths. [VERIFIED: accrue_admin/e2e/admin-interactions.spec.js]

### Wave 0 Gaps

- [ ] `test/accrue_admin/dev/component_group_registry_test.exs` or extension of existing registry tests - covers GRP-01 group slugs, states, proof IDs, and Phase 191 handoff tags. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_registry.ex]
- [ ] `test/accrue_admin/components/at_risk_table_test.exs` or added display component tests - covers GRP-02 mobile card/list, empty/loading/error/no-pagination contract. [VERIFIED: accrue_admin/lib/accrue_admin/components/at_risk_table.ex]
- [ ] `e2e/admin-group-contracts.spec.js` or a narrow block in existing baseline/interactions specs - covers group locator visibility, mobile/desktop inactive DOM, no duplicate focus targets, and selected/filter-active state proof. [VERIFIED: accrue_admin/e2e/admin-baseline.spec.js]
- [ ] Update `navigation_components_test.exs` if `DropdownMenu` switches from menu roles to disclosure semantics; the current test asserts `role="menu"`. [VERIFIED: accrue_admin/test/accrue_admin/components/navigation_components_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No direct auth change | Step-up/modal structure may be touched, but authentication policy and verification remain outside Phase 190. [VERIFIED: accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex] |
| V3 Session Management | No | No session creation, cookie policy, or token lifetime work is in scope. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | Indirect | Do not add routes or expose new billing data through group specimens; dev lab remains the proof surface already in use. [VERIFIED: accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex] |
| V5 Input Validation | Yes | Keep `DataTable` filter params through query module decode/encode boundaries and keep global search bounded; do not add unsanitized HTML. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/global_search.ex] |
| V6 Cryptography | No | No cryptographic primitives or signed cursor changes should be introduced in Phase 190. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS through labels, empty copy, metadata, timeline details, or JSON display | Tampering | Use HEEx escaping and existing component render helpers; preserve JsonViewer/display tests. [VERIFIED: accrue_admin/test/accrue_admin/components/display_components_test.exs] |
| Sensitive data leakage in `data-component-group` | Information Disclosure | Only emit static group slugs derived from Phase 187 names; never embed account IDs, customer IDs, invoice IDs, or secrets in group locators. [VERIFIED: accrue_admin/e2e/baseline-manifest.js] |
| Duplicate hidden focus targets in responsive table/card DOM | Elevation of Privilege / Usability Security | Ensure inactive DOM is `display: none` or non-focusable and add focus-order probes. [VERIFIED: accrue_admin/assets/css/app.css] |
| ARIA role overclaiming on dropdowns or tabs | Spoofing / Tampering | Match semantics to implemented behavior: disclosure for `details`, link nav for route tabs, dialog roles only when dialog behavior is structurally true. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/] |
| Destructive action ambiguity in modal-confirm/drawer actions | Repudiation / Tampering | Contract must place cancel and destructive action visibly, name the object, and keep destructive affordance visually distinct; full keyboard/focus behavior is Phase 191. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Unauthorized fixture expansion during probes | Information Disclosure | Use existing representative pages and lab specimens; do not broaden production fixture state in Phase 190. [VERIFIED: .planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-CONTEXT.md` - locked Phase 190 decisions, discretion, deferred boundaries, and canonical refs.
- `.planning/REQUIREMENTS.md` - GRP-01..04 requirement text.
- `.planning/ROADMAP.md` - v1.53 phase split and guardrails.
- `.planning/phases/187-audit-baseline/187-BASELINE.md`, `defects.ndjson`, `baseline.cells.json`, and `accrue_admin/e2e/baseline-manifest.js` - Phase 187 group manifest, dimensions, state taxonomy, and defect counts.
- `.planning/phases/188-foundations-hardening/188-CONTEXT.md`, `accrue_admin/assets/css/theme.css`, and `accrue_admin/assets/css/app.css` - token, layer, type, spacing, and responsive implementation context.
- `.planning/phases/189-primitive-form-components-component-lab/189-CONTEXT.md`, `189-RESEARCH.md`, `189-PATTERNS.md`, and `189-VERIFICATION.md` - registry/lab pattern, single-column lab decision, and asset-build warning.
- `accrue_admin/lib/accrue_admin/components/*.ex`, `accrue_admin/lib/accrue_admin/dev/*.ex`, and listed component tests - current implementation shape and test coverage.
- `accrue_admin/package.json`, `accrue_admin/mix.exs`, `mix deps`, `mix hex.info`, `npm list`, and `npm view` - installed versions and registry checks.

### Secondary (MEDIUM confidence)

- `https://phoenix.hexdocs.pm/components.html` - Phoenix Components and HEEx attrs/slots. [CITED: https://phoenix.hexdocs.pm/components.html]
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html` - LiveComponent state/markup/event boundary. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html` - LiveView JS focus/show/hide/patch helpers. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html]
- `https://phoenix-live-view.hexdocs.pm/live-navigation.html` - live patch/navigation behavior. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
- `https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/`, `tabs/`, `menu-button/`, and `disclosure/` - official ARIA pattern boundaries. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/]
- `https://carbondesignsystem.com/components/data-table/usage/`, `https://designsystem.digital.gov/components/table/`, `https://design-system.service.gov.uk/components/pagination/`, and `https://polaris-react.shopify.com/components/layout-and-structure/empty-state` - official design-system guidance for table anatomy, responsive stacked tables, pagination, filtering, and empty states.

### Tertiary (LOW confidence)

- GSD `research-plan` and `research-store` seams were available through `/Users/jon/.claude/gsd-core/bin/gsd-tools.cjs`; the `/Users/jon/.codex` and `/Users/jon/.cursor` shims failed because package metadata was missing, and the global `gsd-tools` bridge did not expose `research-plan`. [VERIFIED: command output]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - verified from `mix.exs`, lock/deps output, `package.json`, `npm list`, `npm view`, and Hex registry output.
- Architecture: HIGH - constrained by Phase 190 locked context and verified against current Phoenix component/lab/test files.
- Pitfalls: HIGH - derived from Phase 187 defects, Phase 190 decisions, current code, and official APG/design-system docs.
- External documentation: MEDIUM - official docs were fetched directly, but Context7 MCP was unavailable and GSD classified direct web fetches conservatively.

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for stack and local architecture; re-check npm/Hex versions if planning is delayed past that date.
