# Phase 196: exemplar-c-subscriptions-list-pageheader - Research

**Researched:** 2026-06-26  
**Domain:** Phoenix LiveView admin list archetype, shared function-component header contract, responsive data-table states [VERIFIED: .planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: codebase grep + 196-CONTEXT.md + official HexDocs]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for every copied item in this section: `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md` [VERIFIED: 196-CONTEXT.md]. Copied verbatim for planner enforcement.

### Locked Decisions

## Implementation Decisions

### PageHeader slot contract

- **D-01 - Use a hybrid semantic-attrs + bounded-slots Phoenix function component.** Create `AccrueAdmin.Components.PageHeader.page_header/1` as a stateless `Phoenix.Component`, not a LiveComponent and not a full resource-page DSL. The component should use required semantic attrs for the invariant pieces and named slots for caller-owned content:
  - attrs: `breadcrumbs` list, required `title`, optional `heading_id`, `class`, `component_group`, and `:rest`.
  - slots: `:description`, `:stat_strip`, `:actions`, `:filter_toolbar`.
  - stable markers: `data-ax-page-header`, `data-ax-page-title`, `data-ax-page-actions`, `data-ax-page-filter-toolbar`, and `data-component-group="page-header-actions-breadcrumbs"`.
- **D-02 - PageHeader owns page orientation, not resource behavior.** It renders the `<header class="ax-page-header">`, breadcrumb trail, exactly one `<h1 class="ax-display">`, description/copy wrapper, and responsive layout for optional stat/action/filter slots. It must not own `AppShell`, flashes, query decoding, pagination, table state, filter-chip semantics, domain/provider gating, or backend IDs.
- **D-03 - Freeze the slot names now; later changes are additive only.** Phase 197 must be able to adopt the component across eight list pages without re-litigating names. Do not replace this with an attr-heavy map DSL or a `ListPage` facade in Phase 196. Those patterns either duplicate `StatStrip`/button/filter APIs or create a leaky abstraction over resource-specific filters, scoped paths, bulk actions, and copy.

### Subscriptions list grammar

- **D-04 - Choose `PageHeader` + table-first queue grammar.** The Subscriptions page should read as: PageHeader with breadcrumbs/title/description + stat strip + filter toolbar, then work-queue/filter chips with visible result count and clear-all, then a dense `DataTable`. Do not switch to cards-first, side filters, tabs-plus-chips, infinite scroll, or Nova-style lenses/saved views in this phase.
- **D-05 - Keep server-driven URL state and cursor pagination.** Filters remain Phoenix/LiveView patch-driven and query-backed. No client-only filter state. Bare `/subscriptions` should still canonicalize to the default work queue, but the disconnected SSR render should not flash an unrelated empty state before connect; planners should either render default queue params on first pass or otherwise avoid a misleading first paint.
- **D-06 - Rename the default queue in UI language to operator work, not backend flags.** Keep the default query as `past_due,canceling`, but present it as **At risk** or equivalent. The "All" escape hatch remains one chip/click away. When the only active constraint is the default queue, clear/remove should land on `?view=all`, not a blank URL that immediately redirects back to the queue.
- **D-07 - Column priority is identity, state, money/plan, time, then signals.** Recommended desktop order:
  1. `Customer / subscription` - customer name/email as the primary scan label; subscription processor/internal ID as secondary mono-small text only when useful.
  2. `State` - lifecycle status in human language (`Active`, `Trialing`, `At risk`, `Canceling at period end`, `Paused`, `Canceled`) using existing status/badge patterns where possible.
  3. `Plan / amount` - use resolver-backed amount/plan metadata when available; otherwise show plan/quantity text honestly. Do not fake MRR or money if the local projection lacks it.
  4. `Renews / ends` - current period end or cancellation/end boundary.
  5. `Signals` - compact billing/tax/ownership chips.
  Plumbing columns, raw UUIDs, raw processor IDs, and raw flag names are secondary or detail-page material.
- **D-08 - Preserve row-to-card mobile degradation, but make it intentional.** Desktop remains the comparison table. Mobile cards should show the same priority facts in stacked label/value order. Do not shrink the desktop grid into unreadable horizontal/vertical scroll unless a future page explicitly chooses that degradation.

### Filter chips, result count, clear-all

- **D-09 - Put visible filter state in one stable chip row.** Enhance `FilterChipBar` or an adjacent list-status primitive so active filters render with:
  - `[data-ax-filter-chips]`
  - `[data-ax-result-count]`
  - `[data-ax-clear-all]`
  - one removable chip per active constraint, plus the work-queue/All affordance.
  The result count may honestly be a visible-row count (`Showing N subscriptions`) unless/until a query-wide count API is introduced. Do not imply an exact total from cursor-paginated visible rows.
- **D-10 - Keep filter controls caller-owned but prove the PageHeader slot.** Because PGH-01 requires a `filter-toolbar` slot, Phase 196 should place the Subscriptions filter toolbar through `PageHeader` while keeping decoding and patch behavior resource-owned. The planner may extract a stateless filter-toolbar helper from `DataTable` or add a narrow internal API, but must not turn `PageHeader` into the filter state owner.
- **D-11 - Clear-all preserves owner scope and means "show all."** The clear-all target must preserve `org` / owner-scope params and remove search/status/customer filters. For default queue, clear-all should route to `view=all`. Do not create a redirect loop back to the default queue.

### Four-state coverage

- **D-12 - Add explicit shared list state classification.** `DataTable` should expose stable state markers without replacing existing `data-role` hooks:
  - `[data-ax-list="subscriptions"]`
  - `[data-ax-state="populated"]`
  - `[data-ax-state="first-run-empty"]`
  - `[data-ax-state="filtered-empty"]`
  - `[data-ax-state="loading-skeleton"]`
  - `[data-ax-empty-reason="queue|filter|first-run"]` where useful.
  Do not rely on `any_filter_active?/1` alone; it mislabels first-run empty under the default queue.
- **D-13 - Keep production loading truthful.** The production route can remain SSR-synchronous. Do not introduce a broad `assign_async` rewrite just to show a skeleton on fast local database reads. Loading skeletons should exist as explicit dev/test/story/page-flow fixture states and for any future genuinely async path, not as fake animation on every patch.
- **D-14 - Loading skeletons match the table/card shape and stay accessible.** Desktop skeletons should use table-shaped rows; mobile skeletons should use card-shaped rows. Use `aria-busy`, one `role="status"` label, `aria-hidden` on decorative skeleton cells, no focus movement, and reduced-motion-safe shimmer/static fallback.
- **D-15 - Empty-state copy is state-specific.** Use brandbook voice: measured, exact, native, short. Suggested copy direction:
  - first-run empty: "No subscriptions yet." Body: "Subscriptions appear after a customer completes checkout."
  - work queue clear: "Nothing at risk." Body: "No past-due or canceling subscriptions. View All to see every subscription."
  - filtered empty: "No subscriptions match these filters." Body: "Clear filters or adjust the search to see subscriptions."
  First-run must not render clear filters; filtered-empty must render clear filters.

### Propagation boundary and verification

- **D-16 - Phase 196 locks API and selectors; Phase 197 propagates.** Phase 196 applies `PageHeader` and the LIST state/filter markers only to Subscriptions. Do not migrate customers, invoices, payments, coupons, promotion codes, webhooks, events, or connect in this phase except for tests/docs that prove the future API. Phase 197 owns those page rewrites.
- **D-17 - Phase 199/200 boundaries stay intact.** Phase 196 must not reopen overlay architecture, portal work, broad interaction sweeps, theme FOUC, or full Storybook story breadth. Phase 199 owns cross-cutting overlay/interaction/fixture stress/microcopy sweep. Phase 200 owns final Storybook completeness, both color modes, axe, and zero-regression sign-off.
- **D-18 - Tests should lock behavior, not taste.** Add component tests for `PageHeader`, `FilterChipBar`, and `DataTable` state markers; `SubscriptionsLive` tests for exactly one `<h1>`, default queue/All chip behavior, chips/count/clear-all, distinct empty states, and column-priority/no-primary-raw-ID behavior; Playwright page-flow coverage for populated / first-run-empty / filtered-empty / loading across desktop/mobile and light/dark. Judge-graded density/hierarchy remains rubric work.

### Folded Todos

- **Shared page_header component for accrue_admin list pages** (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`) - folded directly into PGH-01. It provides the problem statement for extracting breadcrumb/title/copy duplication into `AccrueAdmin.Components.PageHeader`. Phase 196 resolves the open "breadcrumb sibling vs component-owned" question by making breadcrumbs an attr rendered by `PageHeader`.
- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) - folded as an explicit boundary and future-design signal, not as implementation scope. Phase 196 remains `accrue_admin` only. Do not edit `accrue_portal`; carry forward the lesson that portal/list/action components need their own future white-label pass.

### the agent's Discretion

- Exact CSS class names under the locked `data-ax-*` markers, as long as they use existing `ax-*` tokens and rebuild the committed admin bundle when source CSS changes.
- Whether the filter toolbar extraction is a small helper in `DataTable`, a sibling component, or a narrow internal slot, as long as `PageHeader` proves the `:filter_toolbar` slot and remains state-free.
- Exact lifecycle badge copy and plan/amount fallback text, bounded by domain honesty and `AccrueAdmin.Copy`.
- Whether result count is emitted from `FilterChipBar` or a thin list-status wrapper; the visible marker and honest label are locked.

### Deferred Ideas (OUT OF SCOPE)

- **Full LIST propagation** - Phase 197 owns customers, invoices, payments, coupons, promotion codes, webhooks, events, and connect adopting `PageHeader` and SPEC-LIST.
- **Full `ListPage` facade / resource DSL** - rejected for Phase 196. Revisit only if repeated Phase 197 code proves real duplication beyond `PageHeader` + `DataTable` + `FilterChipBar`.
- **Saved views / Nova-style lenses / scope tabs** - deferred unless a future product need emerges for named operator queues. Current At risk / All chips are enough.
- **Exact total-count query API across all lists** - deferred. Use honest visible-row count labels for cursor pagination unless Phase 197/200 makes exact totals a hard requirement.
- **Broad async DataTable rewrite** - deferred. Use explicit loading fixtures/skeletons and keep production SSR-synchronous unless a real slow query path appears.
- **Bulk actions on subscriptions list** - not in Phase 196 unless already present and trivial; saved for a future operator workflow if sourced by usage.
- **Cross-cutting overlay/interaction/theme/microcopy sweep** - Phase 199/200.
- **`accrue_portal` white-label billing portal design-system pass** - future portal milestone. The folded portal TODO is explicitly not implemented in this admin LIST exemplar.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXE-03 | The Subscriptions list is converted to the locked list spec: table-first with row->card mobile degradation, persistent filter chips + result count + clear-all, work-queue default, and four distinct states. [VERIFIED: .planning/REQUIREMENTS.md] | Existing `SubscriptionsLive`, `DataTable`, and `FilterChipBar` already provide URL filters, cursor pagination, table/card rendering, and work-queue chips; Phase 196 must add explicit state markers, count/clear-all markers, truthful loading fixtures, and column priority. [VERIFIED: codebase grep] |
| PGH-01 | A shared `AccrueAdmin.Components.PageHeader` is extracted with breadcrumb + title + stat-strip + actions + filter-toolbar slots, proven on Subscriptions, and preserving exactly one `<h1>` per page. [VERIFIED: .planning/REQUIREMENTS.md] | Phoenix function components support required attrs and named slots, and no `AccrueAdmin.Components.PageHeader` currently exists; Phase 196 should add it as a stateless component and adopt it only on Subscriptions. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html] [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints

- `AGENTS.md` is absent in the repository, so there are no AGENTS-specific directives to copy. [VERIFIED: `find . -maxdepth 2 -name AGENTS.md`]  
- `CLAUDE.md` states `accrue_admin` owns LiveView runtime UI work while core `accrue` must stay LiveView-runtime-free. [VERIFIED: CLAUDE.md]  
- `CLAUDE.md` states the admin UI uses custom `ax-*` CSS and committed admin bundles; Tailwind utility authoring is not the implementation path. [VERIFIED: CLAUDE.md]  
- `CLAUDE.md` states GSD workflow discipline applies before file-changing work; this research file is itself a GSD phase artifact requested by the orchestrator. [VERIFIED: CLAUDE.md]  
- No project-local `SKILL.md` files were found under `.claude` or `.agents`. [VERIFIED: `find .claude .agents -maxdepth 3 -type f -name SKILL.md`]

## Summary

Phase 196 should be planned as one narrow exemplar package: add a stateless `AccrueAdmin.Components.PageHeader`, prove its frozen slot contract on `SubscriptionsLive`, and make the existing subscriptions list satisfy SPEC-LIST selectors and states without moving query ownership into the header. [VERIFIED: 196-CONTEXT.md] [VERIFIED: codebase grep] The existing page already has the core substrate: `@default_queue_status "past_due,canceling"`, owner-scoped table paths, server patch filters, `StatStrip`, `FilterChipBar`, and `DataTable` table/card degradation. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]

The highest-risk planning point is the filter-toolbar seam. `DataTable` currently owns and renders its filter `<form>` internally while `PageHeader` must prove a `:filter_toolbar` slot. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] Plan a small extraction that preserves the parent-targeted `phx-change="data_table_filter"` contract and current `DataTableNav.patch_with_filters/3` behavior, rather than turning `PageHeader` into a state owner. [VERIFIED: accrue_admin/test/accrue_admin/components/data_table_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/live-navigation.html]

**Primary recommendation:** Implement `PageHeader` as a stateless function component, move Subscriptions orientation/stat/filter-toolbar rendering through its slots, then add additive `data-ax-*` state/filter markers to `FilterChipBar` and `DataTable`; do not introduce new dependencies, routes, or a generic `ListPage` facade. [VERIFIED: 196-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Page orientation, breadcrumbs, title, header slots | Browser / Client render via Phoenix HEEx component | Frontend Server / LiveView render | `PageHeader` is rendered HTML structure and must stay stateless; LiveView supplies assigns. [VERIFIED: 196-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html] |
| Subscription filters and default queue URL state | Frontend Server / LiveView | API / Backend query module | `SubscriptionsLive.handle_params/3` and `handle_event/3` own URL params; `AccrueAdmin.Queries.Subscriptions` decodes and applies filters. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] [VERIFIED: accrue_admin/lib/accrue_admin/queries/subscriptions.ex] |
| Cursor pagination and table reloads | Frontend Server / LiveComponent | Database / Storage | `DataTable` reloads rows through the query behaviour and cursor helpers; the database remains the persistence/query source. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] |
| Filter chips, visible result count, clear-all | Browser / Client render via Phoenix components | Frontend Server / LiveView patch URLs | `FilterChipBar` renders active chips; clear-all must use owner-scoped patch targets supplied by `SubscriptionsLive`. [VERIFIED: accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex] [VERIFIED: 196-CONTEXT.md] |
| Four list states and loading skeleton fixtures | Frontend Server / component state classification | Browser / Playwright verification | `DataTable` must emit stable state selectors, and Phase 196 Playwright coverage should assert populated/empty/loading states on rendered routes. [VERIFIED: accrue_admin/guides/spec-list.md] [VERIFIED: 196-CONTEXT.md] |
| Owner-scope preservation | API / Backend query scope + LiveView path construction | Frontend Server / URL generation | `scope_query/2` filters by owner scope and `scoped_path/3` carries `org` URLs; clear-all must preserve this. [VERIFIED: accrue_admin/lib/accrue_admin/queries/subscriptions.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | Locked `1.1.31`, released 2026-05-29; latest compatible line has `1.2.x` releases, but repo lock is 1.1.31. [VERIFIED: Hex registry] | LiveView runtime, `Phoenix.Component`, HEEx function components, LiveComponents. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html] | Existing `accrue_admin` uses LiveViews and LiveComponents; Phase 196 should stay on the locked dependency, not upgrade. [VERIFIED: accrue_admin/mix.lock] |
| `phoenix` | Locked `1.8.7`, released 2026-05-06. [VERIFIED: Hex registry] | Router/endpoint and LiveView integration base. [VERIFIED: accrue_admin/mix.lock] | Project constraints target Phoenix 1.8+ and current code compiles against it. [VERIFIED: CLAUDE.md] |
| `phoenix_html` | Locked `4.3.0`, released 2025-09-28. [VERIFIED: Hex registry] | HTML-safe rendering helpers used by current cells/links. [VERIFIED: accrue_admin/mix.lock] | Existing components use Phoenix HTML safe strings for rendered cell helpers. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] |
| `lazy_html` | Locked `0.1.11`, released 2026-04-02. [VERIFIED: Hex registry] | Test HTML assertions through LiveView dependency stack. [VERIFIED: accrue_admin/mix.lock] | Already present as test dependency; no new HTML parser is needed. [VERIFIED: accrue_admin/mix.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `phoenix_storybook` | Locked `1.2.0`, released 2026-06-11, dev/test only. [VERIFIED: Hex registry] | Component story lab for `PageHeader` proof story. [VERIFIED: accrue_admin/mix.exs] | Add `storybook/components/page_header.story.exs` only; do not expand full story breadth in Phase 196. [VERIFIED: 196-CONTEXT.md] |
| Playwright `@playwright/test` | `^1.57.0` in package.json; `npm exec playwright -- --version` reports 1.59.1 installed. [VERIFIED: accrue_admin/package.json] [VERIFIED: npm exec] | Browser page-flow checks for desktop/mobile/theme/state. [VERIFIED: accrue_admin/e2e/admin-spec-detail-phase195.spec.js] | Add a phase-specific `e2e:phase196` script following the Phase 195 pattern. [VERIFIED: accrue_admin/package.json] |
| `mix accrue_admin.assets.build` | Local Mix task exists. [VERIFIED: accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex] | Rebuild committed CSS/JS bundle after `assets/css` changes. [VERIFIED: accrue_admin/guides/admin_ui.md] | Required if PageHeader/list CSS changes. [VERIFIED: CLAUDE.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Stateless `PageHeader` function component | `Phoenix.LiveComponent` | LiveComponent is for stateful component lifecycle/events; PageHeader must not own state. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.LiveComponent.html] [VERIFIED: 196-CONTEXT.md] |
| `PageHeader` + existing `DataTable`/`FilterChipBar` | Full `ListPage` facade / resource DSL | The DSL is explicitly out of scope and would leak resource-specific filters/actions/copy. [VERIFIED: 196-CONTEXT.md] |
| Cursor-paginated visible row count | Query-wide total-count API | Exact totals are deferred; visible-row count is honest for cursor pagination. [VERIFIED: 196-CONTEXT.md] |
| Explicit loading fixtures/skeleton support | Broad `assign_async` rewrite | Production reads are SSR-synchronous; fake animation on every patch is explicitly rejected. [VERIFIED: 196-CONTEXT.md] |

**Installation:**
```bash
# No package installation for Phase 196. Use the existing locked deps.
cd accrue_admin
mix deps
```

**Version verification performed:**
```bash
cd accrue_admin
mix deps | rg 'phoenix_live_view|phoenix\s|phoenix_html|phoenix_storybook'
mix hex.info phoenix_live_view 1.1.31
mix hex.info phoenix 1.8.7
mix hex.info phoenix_html 4.3.0
mix hex.info phoenix_storybook 1.2.0
npm exec playwright -- --version
```

## Package Legitimacy Audit

Phase 196 should not install external packages. [VERIFIED: 196-CONTEXT.md] Package legitimacy gating is not required unless the plan adds a new dependency, which this research recommends against. [VERIFIED: package_legitimacy_protocol]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | — | — | — | — | — | No package install planned. [VERIFIED: 196-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new package recommendations]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new package recommendations]

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens /billing/subscriptions
  |
  v
SubscriptionsLive.mount/3 assigns shell, scoped paths, summary stats
  |
  v
handle_params/3 canonicalizes bare URL to default queue or accepts ?view=all/filter params
  |
  v
PageHeader.page_header/1 renders orientation only
  |-- breadcrumbs attr -> Breadcrumbs.breadcrumbs/1
  |-- title attr -> exactly one h1
  |-- :description slot -> Copy-backed page copy
  |-- :stat_strip slot -> StatStrip.stat_strip/1
  |-- :filter_toolbar slot -> caller-owned filter controls
  v
FilterChipBar / list-status renders chips + visible count + clear-all
  |
  v
DataTable LiveComponent decodes params through AccrueAdmin.Queries.Subscriptions
  |
  +--> rows found -> data-ax-state="populated" -> desktop table + mobile cards
  |
  +--> no rows, no records ever -> data-ax-state="first-run-empty"
  |
  +--> no rows, active filter/default queue -> data-ax-state="filtered-empty" or queue reason
  |
  +--> fixture/future async -> data-ax-state="loading-skeleton"
  |
  v
Playwright + ExUnit assert selectors, one h1, URL state, owner-scope, and mobile degradation
```

All data flow above is implemented in the frontend server/render tier except the query filtering, which belongs to `AccrueAdmin.Queries.Subscriptions` and the database. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/components/page_header.ex          # new stateless PageHeader component [VERIFIED: 196-CONTEXT.md]
├── lib/accrue_admin/components/data_table.ex           # add LIST state markers and optional loading fixture surface [VERIFIED: codebase grep]
├── lib/accrue_admin/components/filter_chip_bar.ex      # add chips/count/clear-all markers or narrow wrapper support [VERIFIED: codebase grep]
├── lib/accrue_admin/live/subscriptions_live.ex         # only production page adoption in Phase 196 [VERIFIED: 196-CONTEXT.md]
├── lib/accrue_admin/copy/subscription.ex               # add list/header/empty/loading copy [VERIFIED: codebase grep]
├── assets/css/app.css                                  # PageHeader/list-state styling if needed; rebuild bundle [VERIFIED: CLAUDE.md]
├── test/accrue_admin/components/page_header_test.exs   # new component contract tests [VERIFIED: 196-CONTEXT.md]
├── test/accrue_admin/live/subscriptions_live_test.exs  # one-h1/default queue/chips/states/columns [VERIFIED: codebase grep]
├── e2e/admin-spec-list-phase196.spec.js                # new phase browser gate [VERIFIED: Phase 195 e2e pattern]
└── storybook/components/page_header.story.exs          # focused PageHeader story [VERIFIED: 196-CONTEXT.md]
```

### Pattern 1: Stateless PageHeader With Bounded Slots

**What:** Define `AccrueAdmin.Components.PageHeader.page_header/1` with required semantic attrs and named slots. [VERIFIED: 196-CONTEXT.md]  
**When to use:** Any page needs shared orientation/header layout, but resource state remains caller-owned. [VERIFIED: 196-CONTEXT.md]  
**Example:**
```elixir
# Source: Phoenix.Component attr/slot docs and Phase 196 locked contract.
# [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html]
defmodule AccrueAdmin.Components.PageHeader do
  use Phoenix.Component

  alias AccrueAdmin.Components.Breadcrumbs

  attr :breadcrumbs, :list, required: true
  attr :title, :string, required: true
  attr :heading_id, :string, default: nil
  attr :class, :string, default: nil
  attr :component_group, :string, default: "page-header-actions-breadcrumbs"
  attr :rest, :global

  slot :description
  slot :stat_strip
  slot :actions
  slot :filter_toolbar

  def page_header(assigns) do
    ~H"""
    <header
      class={["ax-page-header", @class]}
      data-ax-page-header
      data-component-group={@component_group}
      {@rest}
    >
      <Breadcrumbs.breadcrumbs items={@breadcrumbs} />
      <h1 id={@heading_id} class="ax-display" data-ax-page-title><%= @title %></h1>
      <div :if={@description != []} class="ax-page-copy"><%= render_slot(@description) %></div>
      <div :if={@actions != []} data-ax-page-actions><%= render_slot(@actions) %></div>
      <div :if={@stat_strip != []}><%= render_slot(@stat_strip) %></div>
      <div :if={@filter_toolbar != []} data-ax-page-filter-toolbar><%= render_slot(@filter_toolbar) %></div>
    </header>
    """
  end
end
```

### Pattern 2: Preserve Parent-Owned URL Filters

**What:** Keep `phx-change="data_table_filter"` and `push_patch` ownership in `SubscriptionsLive`; if filter markup is extracted, it must remain parent-targeted and query-backed. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] [VERIFIED: accrue_admin/test/accrue_admin/components/data_table_test.exs]  
**When to use:** Any list filter toolbar rendered through PageHeader. [VERIFIED: 196-CONTEXT.md]  
**Example:**
```elixir
# Source: existing DataTable filter contract.
# [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]
def handle_event("data_table_filter", params, socket) do
  {:noreply,
   AccrueAdmin.DataTableNav.patch_with_filters(
     socket,
     socket.assigns.table_path,
     Map.drop(params, ["_target", "_csrf_token"])
   )}
end
```

### Pattern 3: Explicit LIST State Classification

**What:** Classify the list state directly instead of inferring first-run vs filtered-empty only from `any_filter_active?/1`. [VERIFIED: 196-CONTEXT.md]  
**When to use:** `DataTable` render path before empty/populated/loading markup. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]  
**Example:**
```elixir
# Source: SPEC-LIST + Phase 196 D-12.
# [VERIFIED: accrue_admin/guides/spec-list.md]
defp list_state(%{loading?: true}), do: {"loading-skeleton", nil}
defp list_state(%{rows: rows}) when rows != [], do: {"populated", nil}
defp list_state(%{record_count: 0}), do: {"first-run-empty", "first-run"}
defp list_state(%{queue_active?: true}), do: {"filtered-empty", "queue"}
defp list_state(%{filter_active?: true}), do: {"filtered-empty", "filter"}
```

### Anti-Patterns to Avoid

- **Moving query/filter state into PageHeader:** It violates D-02 and makes Phase 197 propagation brittle. [VERIFIED: 196-CONTEXT.md]  
- **Using raw backend labels as primary UI:** `past_due,canceling`, UUIDs, and processor IDs are plumbing; the locked list grammar prioritizes customer/state/plan/time. [VERIFIED: 196-CONTEXT.md]  
- **Fake production skeletons:** Loading skeletons are required as states/fixtures, not as artificial animation on synchronous reads. [VERIFIED: 196-CONTEXT.md]  
- **Clear-all to a blank URL:** Blank `/subscriptions` re-canonicalizes to the default queue; clear-all for the default queue must route to `?view=all`. [VERIFIED: 196-CONTEXT.md]  
- **Weakening existing hooks:** Keep `data-role` and `data-phase191-focus` while adding `data-ax-*` selectors. [VERIFIED: 196-CONTEXT.md] [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Header composition | Resource-page DSL or stateful LiveComponent | Phoenix function component with `attr`/`slot` | The official component model supports the needed contract, and the phase forbids resource behavior in PageHeader. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html] [VERIFIED: 196-CONTEXT.md] |
| Filtering and URL state | Client-only JS filter store | Existing `DataTableNav.patch_with_filters/3` + query modules | Existing tests prove parent-targeted filters and patch URLs. [VERIFIED: accrue_admin/test/accrue_admin/components/data_table_test.exs] |
| Pagination totals | Exact total-count layer across all list pages | Honest visible-row count | Exact count API is deferred; cursor pagination already returns visible rows and next cursor. [VERIFIED: 196-CONTEXT.md] [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex] |
| Status presentation | New badge system | Existing `StatusBadge.status_badge/1` or existing chip patterns | StatusBadge maps lifecycle-like values onto existing palette tones. [VERIFIED: accrue_admin/lib/accrue_admin/components/status_badge.ex] |
| Accessibility announcements | Custom focus-moving loader | `aria-busy`, one `role="status"`, decorative `aria-hidden` skeleton cells | WAI/W3C guidance supports status announcements without disrupting focus. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22] |

**Key insight:** The phase is not missing primitives; it is missing a frozen composition boundary and stable LIST markers. [VERIFIED: 196-CONTEXT.md] Custom abstractions beyond `PageHeader` would increase propagation risk for Phase 197. [VERIFIED: 196-CONTEXT.md]

## Runtime State Inventory

This phase extracts/refines UI components but does not rename persisted identifiers, routes, env vars, package names, or service registrations. [VERIFIED: 196-CONTEXT.md]

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — Phase 196 changes rendered `accrue_admin` UI and does not rename database keys or stored state. [VERIFIED: 196-CONTEXT.md] | None. [VERIFIED: 196-CONTEXT.md] |
| Live service config | None — no external service configuration is in scope. [VERIFIED: 196-CONTEXT.md] | None. [VERIFIED: 196-CONTEXT.md] |
| OS-registered state | None — no launchd/systemd/pm2/task registrations are touched. [VERIFIED: 196-CONTEXT.md] | None. [VERIFIED: 196-CONTEXT.md] |
| Secrets/env vars | None — no secret key or env var names change. [VERIFIED: 196-CONTEXT.md] | None. [VERIFIED: 196-CONTEXT.md] |
| Build artifacts | Admin CSS/JS committed bundle may need regeneration if source CSS/JS changes. [VERIFIED: accrue_admin/guides/admin_ui.md] | Run `cd accrue_admin && mix accrue_admin.assets.build` when source assets change, then commit generated bundle. [VERIFIED: accrue_admin/guides/admin_ui.md] |

## Common Pitfalls

### Pitfall 1: Disconnected First Paint Shows the Wrong Empty State
**What goes wrong:** Bare `/subscriptions` renders without default queue params during disconnected SSR, then patches to `status=past_due,canceling` after connect. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]  
**Why it happens:** Current `handle_params/3` only `push_patch`es the default when `connected?(socket)` is true. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]  
**How to avoid:** Plan a first-render default params assignment or another strategy that prevents a misleading first paint. [VERIFIED: 196-CONTEXT.md]  
**Warning signs:** Tests pass on connected LiveView but screenshots show first-run empty copy on bare route. [VERIFIED: 196-CONTEXT.md]

### Pitfall 2: `any_filter_active?/1` Mislabels Queue Empty
**What goes wrong:** Default queue empty can be treated as generic filtered-empty or first-run empty. [VERIFIED: 196-CONTEXT.md]  
**Why it happens:** `DataTable.resolve_empty_state/1` currently checks only whether filter params carry values. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]  
**How to avoid:** Add explicit state/reason inputs for `first-run`, `queue`, `filter`, and `loading-skeleton`. [VERIFIED: 196-CONTEXT.md]  
**Warning signs:** First-run empty renders clear filters, or queue-empty copy says no subscriptions exist. [VERIFIED: 196-CONTEXT.md]

### Pitfall 3: PageHeader Becomes a List DSL
**What goes wrong:** The component starts accepting filter maps, status options, count APIs, or resource-specific paths. [VERIFIED: 196-CONTEXT.md]  
**Why it happens:** Pulling the filter toolbar into a slot can tempt planners to move filter state into the header. [VERIFIED: 196-CONTEXT.md]  
**How to avoid:** Slots render caller content only; PageHeader owns layout and one-h1 semantics. [VERIFIED: 196-CONTEXT.md]  
**Warning signs:** `PageHeader` imports `DataTableNav`, calls query modules, or knows `status`/`customer_id`. [VERIFIED: 196-CONTEXT.md]

### Pitfall 4: Clear-All Drops Owner Scope
**What goes wrong:** Organization-scoped operators clear filters and land on global results or a redirect loop. [VERIFIED: 196-CONTEXT.md]  
**Why it happens:** Existing scoped paths append `?org=slug`; clear-all URLs must preserve that while removing other params. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]  
**How to avoid:** Centralize clear-all URL construction and test org-scope paths. [VERIFIED: 196-CONTEXT.md]  
**Warning signs:** Clear-all href equals `/billing/subscriptions` when current scope has `org`. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]

### Pitfall 5: CSS Source Changes Without Bundle Rebuild
**What goes wrong:** Source CSS looks correct but browser tests still serve old static CSS. [VERIFIED: accrue_admin/guides/admin_ui.md]  
**Why it happens:** `accrue_admin` ships a committed private static bundle. [VERIFIED: accrue_admin/guides/admin_ui.md]  
**How to avoid:** Run `mix accrue_admin.assets.build` after editing `assets/css/app.css` or `assets/css/theme.css`. [VERIFIED: accrue_admin/guides/admin_ui.md]  
**Warning signs:** ExUnit source checks pass but Playwright screenshots do not reflect CSS changes. [VERIFIED: accrue_admin/guides/admin_ui.md]

## Code Examples

Verified patterns from official and in-repo sources:

### Parent-Targeted Filter Form
```elixir
# Source: existing DataTable render path.
# [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]
<form
  phx-change="data_table_filter"
  phx-submit="data_table_filter"
  class="ax-data-table-filters"
  data-role="filter-form"
>
  ...
</form>
```

### Owner-Scoped Default Queue Params
```elixir
# Source: current SubscriptionsLive helper.
# [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex]
defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
     when is_binary(slug) do
  %{"status" => status, "org" => slug}
end
```

### Breadcrumb Semantics To Reuse Inside PageHeader
```elixir
# Source: existing Breadcrumbs component.
# [VERIFIED: accrue_admin/lib/accrue_admin/components/breadcrumbs.ex]
<nav class="ax-breadcrumbs" aria-label="Breadcrumb">
  <ol class="ax-breadcrumbs-list">
    ...
  </ol>
</nav>
```

### Phase-Specific Playwright Script Pattern
```json
{
  "scripts": {
    "e2e:phase196": "env -u NO_COLOR playwright test e2e/admin-spec-list-phase196.spec.js --timeout=60000 --workers=1"
  }
}
```
Source: Phase 195 added the same one-spec, one-worker, sixty-second pattern for `e2e:phase195`. [VERIFIED: accrue_admin/package.json] [VERIFIED: accrue_admin/e2e/admin-spec-detail-phase195.spec.js]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline per-page `<header class="ax-page-header">` | Shared `PageHeader` function component with attrs/slots | Phase 196 planned after Phase 193 SPEC-LIST lock. [VERIFIED: 196-CONTEXT.md] | Reduces Phase 197 propagation churn while preserving one `<h1>`. [VERIFIED: 196-CONTEXT.md] |
| Table-only or shrunk desktop grid on mobile | Desktop table plus mobile stacked row cards | Existing `DataTable` already implements one-layout-at-a-time table/card CSS. [VERIFIED: accrue_admin/assets/css/app.css] | Keeps comparison on desktop and readable single-record cards on mobile. [VERIFIED: accrue_admin/guides/spec-list.md] |
| Hidden filter state | Persistent chips + visible count + clear-all | SPEC-LIST locked in Phase 193. [VERIFIED: accrue_admin/guides/spec-list.md] | Operators can see what constraints are active without reopening controls. [VERIFIED: accrue_admin/guides/spec-list.md] |
| Source-only visual checks | Rendered page-flow gates with phase-specific Playwright specs | Phase 193/195 established page-flow and exemplar scripts. [VERIFIED: .planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md] [VERIFIED: accrue_admin/package.json] | Phase 196 should add rendered state/viewport proof instead of relying only on unit tests. [VERIFIED: 196-CONTEXT.md] |

**Deprecated/outdated:**
- Cards-first list layouts are rejected for billing queues because SPEC-LIST is table-first. [VERIFIED: accrue_admin/guides/spec-list.md]  
- Infinite scroll is rejected for operator queues; server cursor pagination remains the pattern. [VERIFIED: .planning/research/FEATURES.md]  
- Native exact totals are deferred; visible-row count is the honest current label. [VERIFIED: 196-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | All actionable claims in this research were verified from the codebase, phase context, project planning docs, Hex registry output, or official documentation. [VERIFIED: source list below] | — | — |

## Open Questions

1. **Where should the filter-toolbar extraction live?**  
   - What we know: It may be a DataTable helper, sibling component, or narrow internal slot, but PageHeader must remain state-free. [VERIFIED: 196-CONTEXT.md]  
   - What's unclear: The lowest-churn implementation depends on how much markup must move out of `DataTable.render/1`. [VERIFIED: accrue_admin/lib/accrue_admin/components/data_table.ex]  
   - Recommendation: Start with the smallest extraction that renders the existing filter form through PageHeader while preserving tests for parent-targeted `phx-change`. [VERIFIED: accrue_admin/test/accrue_admin/components/data_table_test.exs]

2. **Can plan/amount be derived honestly from current list projection?**  
   - What we know: Current query selects status, customer, tax/ownership signals, period/end fields, and IDs, but no plan/amount fields. [VERIFIED: accrue_admin/lib/accrue_admin/queries/subscriptions.ex]  
   - What's unclear: Whether a resolver-backed amount/plan projection can be added cheaply without widening domain scope. [VERIFIED: 196-CONTEXT.md]  
   - Recommendation: Add plan/amount only if available from existing local projection/resolver; otherwise use honest plan/quantity fallback copy. [VERIFIED: 196-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Compile and ExUnit | yes [VERIFIED: local command] | Elixir 1.19.5 / OTP 28; Mix 1.19.5 [VERIFIED: local command] | None needed. |
| Node.js | Playwright and asset tooling | yes [VERIFIED: local command] | v22.14.0 [VERIFIED: local command] | None needed. |
| npm | Playwright script execution | yes [VERIFIED: local command] | 11.1.0 [VERIFIED: local command] | None needed. |
| Playwright | Browser phase gate | yes via `npm exec` [VERIFIED: local command] | 1.59.1 installed locally [VERIFIED: local command] | Use `npm ci && npm run e2e:install` if local install is missing. [VERIFIED: accrue_admin/package.json] |
| PostgreSQL | LiveView tests and Ecto sandbox | yes [VERIFIED: pg_isready] | psql 14.17; `/tmp:5432` accepting connections [VERIFIED: local command] | None for local tests; CI provides service. [VERIFIED: test support] |
| `mix accrue_admin.assets.build` | Committed admin bundle rebuild | yes [VERIFIED: codebase grep] | local Mix task [VERIFIED: accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex] | None; required after source asset edits. |

**Missing dependencies with no fallback:** none found. [VERIFIED: local environment audit]  
**Missing dependencies with fallback:** global `playwright` binary is not required because local `npm exec playwright` works. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest + Playwright. [VERIFIED: accrue_admin/test/support/live_case.ex] [VERIFIED: accrue_admin/package.json] |
| Config file | `accrue_admin/mix.exs`, `accrue_admin/package.json`, `accrue_admin/playwright.config.js`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/subscriptions_live_test.exs` [VERIFIED: existing test paths except new page_header_test] |
| Full suite command | `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase196` [VERIFIED: package test pattern] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PGH-01 | `PageHeader` renders breadcrumbs, one h1, slots, and stable `data-ax-*` markers. [VERIFIED: 196-CONTEXT.md] | component | `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs` | no, Wave 0. [VERIFIED: file list] |
| PGH-01 | Subscriptions uses PageHeader and renders exactly one page h1. [VERIFIED: 196-CONTEXT.md] | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs` | yes. [VERIFIED: codebase grep] |
| EXE-03 | Default At risk queue, All one click away, clear-all routes to `view=all`. [VERIFIED: 196-CONTEXT.md] | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs` | yes. [VERIFIED: codebase grep] |
| EXE-03 | Chips + result count + clear-all markers exist together. [VERIFIED: accrue_admin/guides/spec-list.md] | component + browser | `cd accrue_admin && mix test test/accrue_admin/components/filter_chip_bar_test.exs && npm run e2e:phase196` | component file yes; e2e file no, Wave 0. [VERIFIED: codebase grep] |
| EXE-03 | Populated / first-run-empty / filtered-empty / loading-skeleton render distinct selectors and copy. [VERIFIED: 196-CONTEXT.md] | component + LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/subscriptions_live_test.exs && npm run e2e:phase196` | partial; loading and new markers need Wave 0. [VERIFIED: codebase grep] |
| EXE-03 | Identity/state/money/time column priority, plumbing IDs de-emphasized. [VERIFIED: 196-CONTEXT.md] | LiveView + browser + rubric | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs && npm run e2e:phase196` | partial; new assertions needed. [VERIFIED: current test file] |

### Sampling Rate

- **Per task commit:** `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/subscriptions_live_test.exs` [VERIFIED: local test structure]  
- **Per wave merge:** `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase196` [VERIFIED: Phase 195 pattern]  
- **Phase gate:** Run package docs guard, asset build if CSS/JS changed, full ExUnit, and `e2e:phase196`; then preserve v1.54 forward-only gate inputs. [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: accrue_admin/guides/admin_ui.md]

### Wave 0 Gaps

- [ ] `accrue_admin/test/accrue_admin/components/page_header_test.exs` — covers PGH-01 slot contract and one h1. [VERIFIED: missing file]  
- [ ] `accrue_admin/e2e/admin-spec-list-phase196.spec.js` — covers EXE-03 rendered states across desktop/mobile and light/dark. [VERIFIED: missing file]  
- [ ] `accrue_admin/package.json` `e2e:phase196` script — follows `e2e:phase195` style. [VERIFIED: package.json]  
- [ ] DataTable loading fixture/test hook — needed for truthful `loading-skeleton` without production fake async. [VERIFIED: 196-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth behavior [VERIFIED: 196-CONTEXT.md] | Existing admin auth/session boundary remains in router/test support. [VERIFIED: accrue_admin/test/support/live_case.ex] |
| V3 Session Management | no new session behavior [VERIFIED: 196-CONTEXT.md] | Preserve mounted LiveView session behavior; no client-only filter state. [VERIFIED: 196-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: owner-scope code] | Preserve owner scope in `scoped_path/3` and `AccrueAdmin.Queries.Subscriptions.scope_query/2`; clear-all must not drop `org`. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] [VERIFIED: accrue_admin/lib/accrue_admin/queries/subscriptions.ex] |
| V5 Input Validation | yes [VERIFIED: query filter code] | Keep query decoding through `Subscriptions.decode_filter/1` and existing filter normalization; no client-only filters. [VERIFIED: accrue_admin/lib/accrue_admin/queries/subscriptions.ex] |
| V6 Cryptography | no [VERIFIED: 196-CONTEXT.md] | No cryptographic primitives in scope. [VERIFIED: 196-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin Lists

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Owner-scope leakage through clear-all/filter URLs | Information Disclosure | Preserve `org` param and backend `scope_query/2` filtering. [VERIFIED: codebase grep] |
| Raw IDs promoted as primary UI identity | Information Disclosure / Usability risk | De-emphasize plumbing IDs and route operators through detail pages. [VERIFIED: 196-CONTEXT.md] |
| XSS through rendered row helpers | Tampering / XSS | Continue `Phoenix.HTML.html_escape()` before raw link/chip strings or render safe HEEx components. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] |
| Client-only filter state drift | Tampering / Repudiation | Keep filters URL-backed and query-decoded server-side. [VERIFIED: 196-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/live-navigation.html] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md` — locked phase boundary, decisions, selectors, tests, and deferred scope. [VERIFIED: local read]  
- `.planning/REQUIREMENTS.md` — EXE-03 and PGH-01 requirement text. [VERIFIED: local read]  
- `accrue_admin/guides/spec-list.md` — authoritative list archetype contract. [VERIFIED: local read]  
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — existing Subscriptions list implementation. [VERIFIED: local read]  
- `accrue_admin/lib/accrue_admin/components/data_table.ex` — existing stateful list primitive. [VERIFIED: local read]  
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` — existing chip primitive. [VERIFIED: local read]  
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` — query/filter/owner-scope source. [VERIFIED: local read]  
- `scripts/ci/verify_package_docs.sh` — current spacing/focus/truncation guards. [VERIFIED: codebase grep]  
- Hex registry output for `phoenix_live_view 1.1.31`, `phoenix 1.8.7`, `phoenix_html 4.3.0`, `phoenix_storybook 1.2.0`, and `lazy_html 0.1.11`. [VERIFIED: Hex registry]

### Secondary (MEDIUM confidence)

- Phoenix LiveView `Phoenix.Component` docs — attrs/slots/function components. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.Component.html]  
- Phoenix LiveView `Phoenix.LiveComponent` docs — stateful component boundary. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/Phoenix.LiveComponent.html]  
- Phoenix LiveView live navigation docs — patch URL state and `handle_params`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.31/live-navigation.html]  
- WAI-ARIA APG breadcrumb pattern. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/]  
- W3C WCAG ARIA22 role=status technique. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: sources list]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified from `mix.lock`, `mix deps`, and Hex registry output; no new packages recommended. [VERIFIED: local commands]  
- Architecture: HIGH — constrained by locked Phase 196 decisions and current code boundaries. [VERIFIED: 196-CONTEXT.md] [VERIFIED: codebase grep]  
- Pitfalls: HIGH — tied to current code behavior, SPEC-LIST, and locked phase decisions. [VERIFIED: local reads]  

**Research date:** 2026-06-26  
**Valid until:** 2026-07-26 for codebase-scoped planning; re-check HexDocs if upgrading LiveView or Phoenix before implementation. [VERIFIED: current dependency audit]
