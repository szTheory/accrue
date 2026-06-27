# Phase 197: Propagate LIST - Research

**Researched:** 2026-06-27  
**Domain:** Phoenix LiveView admin LIST propagation  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for all copied bullets in this section: `.planning/phases/197-propagate-list/197-CONTEXT.md` [VERIFIED: codebase grep].

### Locked Decisions

#### Cohesive Recommendation

- **D-01 - Apply strict LIST exemplar parity without inventing a `ListPage` DSL.** Phase 197 should migrate all eight target pages to the Phase 196 composition: `PageHeader` for orientation, `DataTable.filter_toolbar` in the `PageHeader` `:filter_toolbar` slot, `DataTable` with `render_filter_toolbar={false}`, and `FilterChipBar` in the `DataTable` `:list_status` slot. Do not create a new generic `ListPage` facade, saved-view/lens DSL, or attr-heavy resource map abstraction in this phase. Phoenix idiom here is small stateless function components for shared markup plus LiveViews owning URL/query/bulk/action state.
- **D-02 - Treat "work queue" as the default operator job for each page, not as a forced exception filter everywhere.** SPEC-LIST's work-queue rule means the page opens on the view the operator most likely came to do. For invoices, payments, webhooks, and connect this is an exception queue. For customers and events it is a lookup/ledger default with quick lenses. Do not manufacture weak queues that hide expected records.
- **D-03 - Keep all filters URL-backed and page-owned.** Each LiveView continues to handle `data_table_filter` via `AccrueAdmin.DataTableNav.patch_with_filters/3` and `handle_params/3`. Query decoding, default params, clear-all targets, owner scope, bulk replay, and page-specific copy stay in the page/query module. `PageHeader` must not own filters or resource state.
- **D-04 - Counts stay honest.** `FilterChipBar` should show visible row counts unless a page explicitly implements a scoped exact-count query. Do not imply a query-wide exact total from cursor-paginated visible rows. Copy should read like "Showing N invoices" or equivalent, not "N total invoices" unless true.

#### Per-page Default Lenses

- **D-05 - Customers default to all customers, with a missing-payment-method quick lens.** Customers is primarily Support's lookup surface ("Find one customer"). Bare `/customers` should not hide customers. Render an active "All customers" chip/lens and a one-click "Missing payment method" chip using `has_default_payment_method=false`. Clear-all returns to the all-customer view while preserving `org`.
- **D-06 - Invoices default to `Needs collection`.** Keep the existing default `status=open,uncollectible`, but present it as operator language, not raw backend flags. The All escape hatch routes to `view=all`, preserving owner scope and clearing `q`, `status`, `customer_id`, `collection_method`, `cursor`, and any fixture params.
- **D-07 - Payments default to failed charges.** `/payments` is implemented by `ChargesLive`; do not create or reference a `/charges` route in UI/test copy. Default to `status=failed` with user-facing chip/copy like "Failed payments." All routes to `view=all` and preserves owner scope if scope support is present or added.
- **D-08 - Coupons default to valid coupons.** Coupons are inventory/reference objects, but the default operator job is reviewing currently usable discounts. Default `valid=true` and render "Valid coupons" plus All. First-run empty means no coupons exist; queue-empty means no valid coupons are currently usable; filtered-empty means the user's filters excluded rows.
- **D-09 - Promotion codes default to active codes.** Default `active=true` and render "Active codes" plus All. Do not conflate inactive codes with errors; inactive/expired codes remain accessible through All or explicit filters.
- **D-10 - Webhooks default to replayable failures.** Use a user-facing "Needs replay" lens covering failed/dead webhook events. `AccrueAdmin.Queries.Webhooks.filter_query/2` already accepts list statuses, but `decode_status/1` currently decodes only one status. Planning should add safe multi-status decode for `status=failed,dead` (or another named param that compiles to that list) instead of faking this in UI copy. Preserve existing bulk retry selection and confirmation behavior.
- **D-11 - Events default to the full append-only ledger.** Events is Compliance/Audit's ledger: "Who did what, when?" Bare `/events` should not hide ledger rows. Render an active "All ledger" chip and keep quick chips like `actor_type=admin` ("Admin changes") one click away. This follows the v1.51 decision that Compliance is a lens on the event log, not a separate nav group.
- **D-12 - Connect defaults to accounts needing attention via a named OR lens.** The default should surface accounts with deauthorization, onboarding incomplete, charges disabled, or payouts disabled. Current `ConnectAccounts` query filters AND the individual boolean params, so do not approximate this by combining existing booleans. Add a narrow page/query-owned lens such as `needs_attention=true` that compiles to an OR predicate, with All as the escape hatch.

#### PageHeader and JTBD Copy

- **D-13 - All eight pages adopt `PageHeader` exactly as a page-orientation component.** Every page uses `PageHeader.page_header/1` for breadcrumbs, the single content `<h1>`, description copy, stat strip, actions if any, and filter toolbar. Keep `data-ax-page-header`, `data-ax-page-title`, `data-ax-page-actions`, and `data-ax-page-filter-toolbar` stable. Do not render a second content `<h1>` outside it.
- **D-14 - Per-page copy names the operator job, not backend structure.** Use brandbook voice: measured, exact, native, durable. Suggested direction:
  - Customers: "Find a customer" / "Look up a customer and inspect their billing state."
  - Invoices: "Clear open receivables" / "Work invoices that need collection."
  - Payments: "Recover failed payments" / "Inspect charges that need follow-up."
  - Coupons: "Review usable discounts" / "Check which coupon definitions can still be applied."
  - Promotion codes: "Find active codes" / "Review customer-facing codes tied to coupons."
  - Webhooks: "Replay failed deliveries" / "Inspect webhook deliveries that need operator action."
  - Events: "Trace billing activity" / "Read the append-only billing event ledger."
  - Connect: "Finish account readiness" / "Find connected accounts that need onboarding or capability work."
- **D-15 - Copy belongs in `AccrueAdmin.Copy` or the existing copy modules.** Avoid raw strings in touched page templates except unavoidable labels during a narrow migration. If Playwright copy fixtures depend on generated copy strings, regenerate and commit them in the implementation phase.

#### Filter Chips, Clear-all, and Four States

- **D-16 - Use `FilterChipBar` as the selected-lens/filter/status surface.** Every target page should render a chip row through `FilterChipBar.filter_chip_bar/1` in `DataTable`'s `:list_status` slot. It must include `[data-ax-filter-chips]`, `[data-ax-result-count]`, and `[data-ax-clear-all]` when a selected/default/filter lens is removable. Remember `FilterChipBar.active` means "render this chip," not necessarily "selected"; selected-vs-available is expressed through `remove_href`, `href`, tone, and copy.
- **D-17 - Clear-all means the operator can see all rows for this resource.** For narrowed defaults, clear-all routes to `view=all`. For reference defaults (customers/events), clear-all removes filters and returns to the all view/base route. All clear paths must preserve `org` / owner scope and must not create a blank-URL redirect loop.
- **D-18 - Four-state copy is page-specific.** Each page needs distinct populated, first-run-empty, filtered-empty, and loading-skeleton behavior. First-run empty must explain how rows arrive. Filtered empty must offer clear filters. Queue-empty can be a positive state ("Nothing needs replay", "No failed payments") only when the underlying resource exists but the default queue is clear. Loading skeletons are dev/test/story/page-flow fixtures unless a real async path exists; do not add fake production delay.
- **D-19 - Keep table/card column priority focused on operator nouns.** Desktop columns and mobile card fields should prioritize identity, state, money/amount/value, time, then signals. Plumbing IDs, raw UUIDs, and raw backend flags are secondary text or detail-page material. Webhooks/events may legitimately prioritize type/status/subject/actor/time because those are the ledger/debugging nouns.

#### Verification and Planning Shape

- **D-20 - Use all-page contract smoke plus deeper representative coverage.** Phase 197 should not run a full `8 pages x 4 states x 2 themes x 2 viewports` matrix; that duplicates component coverage and steals Phase 200's final sign-off role. Instead:
  - Component tests keep `PageHeader`, `DataTable`, and `FilterChipBar` contracts locked.
  - Each of the eight LiveViews gets focused tests for one `<h1>`, `PageHeader` markers, default lens params, chips/count/clear-all, distinct empty copy, and owner-scope-preserving clear paths.
  - Playwright smokes all eight pages for `PageHeader`, `[data-ax-list]`, active chips/count/clear-all where applicable, mobile row-to-card rendering, no horizontal clipping, and page-level light/dark sanity.
  - Deeper four-state desktop/mobile/theme coverage runs on representative high-risk pages: customers/reference default, invoices or payments/status queue, webhooks/actionable bulk queue, events/ledger lens, and connect/OR attention lens.
- **D-21 - A thin hand-authored LIST contract manifest is acceptable; a generated DSL is not.** The planner may introduce a test-only manifest/table of route, list_id, default lens, all-target, and expected copy for tests. It must not become a runtime resource DSL or source-generate page behavior from itself.
- **D-22 - Slice execution by risk.** Recommended plan order: (1) shared/test contract and any narrow helper seams; (2) simple inventory/reference pages (customers, coupons, promotion codes); (3) queue/action pages (invoices, payments, webhooks, events, connect); (4) browser verification. Preserve Webhooks bulk replay and Connect readiness semantics rather than flattening them into generic list code.

#### Folded Todos

- **Shared page_header component for accrue_admin list pages** (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`) - folded into Phase 197 as propagation of the Phase 196 `PageHeader` contract. The component already exists and is proven on Subscriptions; Phase 197 adopts it across the remaining list pages and finishes the todo's original goal.

### the agent's Discretion

- Exact helper extraction after the first two or three page migrations, provided helpers stay pure/narrow and LiveViews own resource state.
- Exact chip labels, empty-state body copy, and stat-strip labels, bounded by the per-page default lenses and brandbook voice.
- Whether the test-only contract manifest lives in ExUnit test support, Playwright fixtures, or both.
- Which queue pages receive the deepest Playwright state coverage, provided the representative set includes reference, status queue, bulk-action, ledger, and OR-lens cases.

### Deferred Ideas (OUT OF SCOPE)

- **Runtime `ListPage` facade / resource DSL** - deferred. Revisit only if Phase 197 leaves repeated, proven boilerplate that a narrow abstraction would remove without owning resource state.
- **Saved views, persisted lenses, user-defined queues** - new capability and out of Phase 197. Current default lenses and quick chips are enough.
- **Exact total-count API across every list** - deferred. Use honest visible counts unless a future phase needs exact query-wide totals and can pay the query/scoping cost.
- **Full browser matrix for all eight pages** - Phase 200. Phase 197 proves propagation with all-page smoke plus representative deep coverage.
- **Storybook completeness for every family/group** - Phase 200.
- **Cross-cutting overlay/theme/fixture-stress/microcopy sweep** - Phase 199/200 ownership.
- **`accrue_portal` white-label billing portal design-system pass** - future portal milestone, explicitly not part of admin LIST propagation.

#### Reviewed Todos (not folded)

- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) - reviewed and deferred because Phase 197 is `accrue_admin` operator UI only. It remains valid future `accrue_portal` work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRP-01 | All 8 remaining list pages (customers · invoices · payments · coupons · promotion-codes · webhooks · events · connect) conform to SPEC-LIST, adopt `PageHeader`, and carry per-page JTBD microcopy + four-state coverage. | Existing Phase 196 exemplar, `PageHeader`, `DataTable`, `FilterChipBar`, and `DataTableNav` already provide the shared contract; target pages need page-owned propagation plus Webhooks multi-status decode and Connect `needs_attention` OR lens. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Accrue is a two-package Elixir/Phoenix monorepo with `accrue/` and `accrue_admin/`; Phase 197 work is confined to `accrue_admin` operator UI. [VERIFIED: CLAUDE.md]
- Locked stack posture is Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+, with `phoenix_live_view` required but core `accrue` kept LiveView-runtime-free. [VERIFIED: CLAUDE.md]
- Security posture requires webhook signature verification to remain mandatory, sensitive Stripe fields not to be logged, and payment method details to stay as Stripe references rather than PII; Phase 197 must preserve Webhooks replay scoping and not add logging of raw payload details. [VERIFIED: CLAUDE.md]
- UI styling remains custom `ax-*` CSS plus committed admin bundle; no Tailwind migration is allowed, and CSS changes require rebuilding `accrue_admin/priv/static/accrue_admin.css`. [VERIFIED: CLAUDE.md] [VERIFIED: scripts/ci/verify_package_docs.sh]
- Copy should go through `AccrueAdmin.Copy` or existing copy modules; raw strings in touched templates are a migration smell unless narrowly unavoidable. [VERIFIED: 197-CONTEXT.md]
- Project skills discovery found no `.claude/skills/` or `.agents/skills/` project skill files in this repo. [VERIFIED: rg --hidden]

## Summary

Phase 197 is a propagation phase, not a component-design phase: the Phase 196 Subscriptions exemplar already locked the `PageHeader` slot contract, the table-first `DataTable` state markers, and `FilterChipBar` chips/count/clear-all surface. The planner should keep implementation page-owned and URL-backed, using the existing components rather than adding a generic `ListPage` facade. [VERIFIED: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex] [VERIFIED: accrue_admin/lib/accrue_admin/components/page_header.ex] [VERIFIED: 196-CONTEXT.md]

The eight target pages are already LiveViews that render `DataTable`, but none fully matches the exemplar shape yet: current headers are inline, stat strips sit outside `PageHeader`, filter toolbars are still rendered inside `DataTable`, and chip/count/clear-all coverage is partial. The largest non-mechanical risks are `Webhooks` needing safe multi-status default decoding for `failed,dead`, `ConnectAccounts` needing a named OR predicate for readiness attention, and several pages needing owner-scope-safe path construction aligned with `ScopedPath` or `DataTableNav.merge_query/2`. [VERIFIED: codebase grep]

**Primary recommendation:** build a small test-only LIST contract manifest, migrate pages in risk order, and preserve each page's query/copy semantics while reusing `PageHeader`, `DataTable.filter_toolbar`, and `FilterChipBar` exactly as Phase 196 did. [VERIFIED: 197-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Page orientation, breadcrumbs, single `<h1>` | Browser / Client rendered by LiveView | Frontend Server (LiveView render) | `PageHeader` renders static HEEx chrome and markers; it must not own URL state or table queries. [VERIFIED: page_header.ex] |
| URL-backed filters and default lenses | Frontend Server (LiveView) | API / Backend query modules | LiveViews handle `data_table_filter` and `handle_params/3`; query modules decode/encode filters and apply Ecto predicates. [VERIFIED: target LiveViews] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.LiveView.html] |
| Row data, pagination, and owner scoping | API / Backend | Database / Storage | Query modules own `list/1`, `decode_filter/1`, cursor predicates, and owner-scope SQL/post-fetch filtering. [VERIFIED: queries/*.ex] |
| List visual states and mobile degradation | Browser / Client rendered by LiveComponent | Frontend Server (LiveComponent update) | `DataTable` emits `data-ax-state`, empty reason, skeleton markup, table rows, and `[data-role="card-list"]`. [VERIFIED: data_table.ex] |
| Chips, visible counts, clear-all | Browser / Client rendered by component | Frontend Server route helpers | `FilterChipBar` renders `[data-ax-filter-chips]`, `[data-ax-result-count]`, and `[data-ax-clear-all]`; callers provide href semantics. [VERIFIED: filter_chip_bar.ex] |
| Webhook bulk replay | API / Backend | Browser / Client selection UI | `WebhooksLive` preserves selection and confirmation, then calls `DLQ.requeue/1` after owner-scope checks. [VERIFIED: webhooks_live.ex] |

## Standard Stack

### Core

| Library / Component | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| `Phoenix.LiveView` | 1.1.31 locked | Server-rendered LiveViews, `handle_params/3`, patch navigation, and LiveComponents. | Existing admin UI stack and official patch semantics fit URL-backed list filters without client-only state. [VERIFIED: accrue_admin/mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.LiveView.html] |
| `Phoenix.Component` | via LiveView 1.1.31 | Function-component `attr` and `slot` contracts. | `PageHeader` is correctly modeled as stateless page chrome with bounded slots. [VERIFIED: accrue_admin/mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.Component.html] |
| `AccrueAdmin.Components.PageHeader` | repo current | Breadcrumbs, one content `<h1>`, description, stat strip, actions, filter toolbar. | Phase 196 locked it as the shared page-orientation component. [VERIFIED: page_header.ex] [VERIFIED: 196-CONTEXT.md] |
| `AccrueAdmin.Components.DataTable` | repo current | Cursor-paginated table, state markers, filter toolbar helper, loading skeleton, mobile cards. | It already provides SPEC-LIST data hooks and row-to-card degradation. [VERIFIED: data_table.ex] [VERIFIED: data_table_test.exs] |
| `AccrueAdmin.Components.FilterChipBar` | repo current | Active/default lens chips, result count, clear-all, chip activation/removal links. | It already exposes the Phase 196 selectors the planner must propagate. [VERIFIED: filter_chip_bar.ex] [VERIFIED: filter_chip_bar_test.exs] |
| `AccrueAdmin.DataTableNav` / `ScopedPath` | repo current | Safe URL query merge and owner-scope path construction. | Prevents double-`?` query corruption and preserves `org` on clear/apply paths. [VERIFIED: data_table_nav.ex] [VERIFIED: scoped_path.ex] |

### Supporting

| Library / Component | Version | Purpose | When to Use |
|---------------------|---------|---------|-------------|
| `AccrueAdmin.Copy` modules | repo current | Page titles, empty-state copy, filter labels, status labels. | Add page-specific JTBD and four-state strings here, not as raw template text. [VERIFIED: copy.ex] [VERIFIED: copy/*.ex] |
| `@playwright/test` | 1.59.1 installed | Browser LIST smokes, viewport checks, theme checks. | Use for all-page smoke and representative deep coverage. [VERIFIED: npm ls] [CITED: https://playwright.dev/docs/api/class-locatorassertions] |
| `@axe-core/playwright` | 4.11.3 installed | Accessibility scan in existing admin e2e suite. | Phase 197 can rely on existing a11y sweep; final axe breadth remains Phase 200. [VERIFIED: npm ls] [VERIFIED: accrue_admin/e2e/admin-a11y.spec.js] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Page-owned LiveView filters | Runtime `ListPage` DSL | Rejected by context because it would hide page-specific query, owner scope, bulk action, and copy semantics. [VERIFIED: 197-CONTEXT.md] |
| Visible-row count | Query-wide exact totals | Deferred because cursor-paginated rows do not imply exact totals and exact counts add query/scoping cost. [VERIFIED: 197-CONTEXT.md] |
| Existing `DataTable` mobile cards | Separate mobile list component | Rejected because `DataTable` already renders card degradation and tests lock it. [VERIFIED: data_table.ex] [VERIFIED: data_table_test.exs] |

**Installation:**

No package installation is required for Phase 197; use the existing `accrue_admin` Hex deps and npm dev deps. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/package.json]

## Package Legitimacy Audit

This phase should not install external packages. The standard stack uses existing locked Hex/npm dependencies and internal components only. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue_admin/package.json]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| N/A | N/A | N/A | N/A | N/A | N/A | No new package install |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens /billing/<resource>[?org=...]
  |
  v
LiveView mount/handle_params
  |-- if bare route needs default queue -> push_patch/assign default params
  |-- preserve org owner scope via ScopedPath/DataTableNav
  |
  v
PageHeader renders breadcrumbs + one h1 + stat strip + filter toolbar slot
  |
  v
DataTable receives params + query_module + render_filter_toolbar=false
  |
  v
Query module decode_filter -> Ecto predicates / owner-scope filtering
  |
  v
Rows + next_cursor
  |
  +--> populated -> desktop table + mobile card list
  +--> first-run-empty -> onboarding copy, no clear filters
  +--> filtered-empty / queue-empty -> distinct copy + clear filters/all
  +--> loading-skeleton fixture -> aria-busy + one status label
  |
  v
FilterChipBar in :list_status shows active lens/filter chips + visible count + clear-all
```

### Recommended Project Structure

```text
accrue_admin/
├── lib/accrue_admin/live/                 # Eight page-owned LIST migrations
├── lib/accrue_admin/queries/              # Webhooks multi-status + Connect OR lens
├── lib/accrue_admin/copy.ex               # General list copy delegates
├── lib/accrue_admin/copy/*.ex             # Resource-specific JTBD/state copy
├── test/accrue_admin/live/                # Focused per-page LiveView contracts
├── test/accrue_admin/components/          # Existing component contract tests
└── e2e/                                   # Phase 197 all-page smoke + representative deep spec
```

### Pattern 1: PageHeader + DataTable Split

**What:** Put `DataTable.filter_toolbar/1` inside `PageHeader`'s `:filter_toolbar` slot and render the `DataTable` with `render_filter_toolbar={false}`. [VERIFIED: subscriptions_live.ex]

**When to use:** Every target list page in Phase 197. [VERIFIED: 197-CONTEXT.md]

**Example:**

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
<PageHeader.page_header breadcrumbs={...} title={Copy.subscriptions_index_heading()}>
  <:description><p class="ax-body"><%= Copy.subscriptions_index_subtitle() %></p></:description>
  <:stat_strip>...</:stat_strip>
  <:filter_toolbar>
    <DataTable.filter_toolbar
      id="subscriptions"
      filter_fields={subscription_filter_fields()}
      filter_params={filter_params(@params)}
      path={@table_path}
      clear_href={clear_all_href(@params, @table_path)}
      clear_visible={filter_active?(@params)}
    />
  </:filter_toolbar>
</PageHeader.page_header>

<.live_component
  module={DataTable}
  id="subscriptions"
  render_filter_toolbar={false}
  ...
/>
```

### Pattern 2: FilterChipBar in DataTable list_status

**What:** Render the current/default lens and any active filters in `DataTable`'s `:list_status` slot; pass `status.visible_count` as an honest visible-row count. [VERIFIED: subscriptions_live.ex]

**When to use:** Every target page, including reference defaults like Customers and Events. [VERIFIED: 197-CONTEXT.md]

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
<:list_status :let={status}>
  <FilterChipBar.filter_chip_bar
    items={work_queue_chips(@params, @table_path)}
    label="Work queue"
    result_count={status.visible_count}
    result_label={{"subscription", "subscriptions"}}
    clear_all_href={active_clear_all_href(@params, @table_path)}
    clear_all_label={Copy.data_table_clear_filters_label()}
  />
</:list_status>
```

### Pattern 3: Default Lens Canonicalization

**What:** For narrowed defaults, bare route should patch to default params when connected and assign equivalent params on disconnected first render to avoid a misleading first-run flash. [VERIFIED: subscriptions_live.ex]

**When to use:** Invoices, Payments, Coupons, Promotion codes, Webhooks, Connect. Customers and Events should default to all rows without hiding records. [VERIFIED: 197-CONTEXT.md]

### Anti-Patterns to Avoid

- **Runtime `ListPage` facade:** It would centralize page-specific URL, query, owner-scope, copy, and bulk-action semantics that the locked context says must remain page-owned. [VERIFIED: 197-CONTEXT.md]
- **Naive `path <> "?" <> URI.encode_query(...)`:** This can corrupt paths that already contain `?org=...`; use `DataTableNav.merge_query/2`. [VERIFIED: data_table_nav.ex]
- **Combining Connect booleans for attention:** Existing `ConnectAccounts` filters are AND predicates; a default attention queue needs a named OR lens. [VERIFIED: connect_accounts.ex] [VERIFIED: 197-CONTEXT.md]
- **Faking Webhooks default with copy only:** `Webhooks.decode_status/1` decodes one atom today; the replay queue needs real list-status decoding. [VERIFIED: webhooks.ex]
- **Adding artificial loading delay:** `DataTable` already supports explicit loading fixtures; production should stay truthful and not sleep. [VERIFIED: data_table.ex] [VERIFIED: data_table_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Page header chrome | One-off `<header>` + `Breadcrumbs` + `<h1>` per page | `PageHeader.page_header/1` | Locks exactly one h1 and stable page-header markers. [VERIFIED: page_header_test.exs] |
| Filter forms | Custom forms per page | `DataTable.filter_toolbar/1` | Keeps parent-targeted `data_table_filter` and existing input styles. [VERIFIED: data_table.ex] |
| Query string mutation | String concatenation | `DataTableNav.merge_query/2` / `patch_with_filters/3` | Preserves existing query params such as `org` and drops blanks. [VERIFIED: data_table_nav.ex] |
| Mobile list rendering | Separate card component | `DataTable` card fields | Existing breakpoint and focus/selection behavior are tested. [VERIFIED: data_table_test.exs] |
| Selected-filter UI | Ad hoc chip markup | `FilterChipBar.filter_chip_bar/1` | It already emits chips/count/clear-all markers and activation/removal links. [VERIFIED: filter_chip_bar_test.exs] |
| Loading skeleton accessibility | Spinner or fake async delay | `DataTable` loading fixture | Existing skeleton uses `aria-busy`, one `role=status`, and decorative hidden skeleton cells. [VERIFIED: data_table.ex] [CITED: https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-busy] |

**Key insight:** the difficult part is resource semantics, not shared markup; push duplication down only after two or three migrations prove the helper boundary. [VERIFIED: 197-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Owner Scope Drops on Clear-All

**What goes wrong:** clear-all or filter-apply links lose `org`, showing global rows or failing auth for non-platform admins. [VERIFIED: data_table_nav.ex] [VERIFIED: owner_scope.ex]

**Why it happens:** string-appended query params create a second `?` or rebuild a path without existing query state. [VERIFIED: data_table_nav.ex]

**How to avoid:** build table paths with `ScopedPath.build/4` or page-local `scoped_path/3`, then mutate them with `DataTableNav.merge_query/2`. [VERIFIED: scoped_path.ex] [VERIFIED: data_table_nav.ex]

**Warning signs:** tests assert `href="/billing/...?...org=allowed-org...view=all"` fails or `assert_patch/1` returns a URL missing `org`. [VERIFIED: subscriptions_live_test.exs]

### Pitfall 2: First-Run Empty vs Queue-Empty Collapse

**What goes wrong:** a narrowed default queue with zero rows renders onboarding copy even though the resource exists. [VERIFIED: subscriptions_live.ex]

**Why it happens:** deriving empty state from `any_filter_active?/1` alone cannot distinguish no records from a cleared queue. [VERIFIED: data_table.ex] [VERIFIED: 196-CONTEXT.md]

**How to avoid:** pass explicit `empty_reason`/copy from each page when a default queue can be empty, and test first-run-empty separately from filtered-empty/queue-empty. [VERIFIED: subscriptions_live_test.exs]

### Pitfall 3: Query-Wide Count Implication

**What goes wrong:** chip copy says or implies "total" when only cursor-visible rows are counted. [VERIFIED: filter_chip_bar.ex]

**Why it happens:** `DataTable` exposes `visible_count: length(@rows)` to the slot. [VERIFIED: data_table.ex]

**How to avoid:** use "Showing N <resource>" unless a page adds a scoped exact-count query. [VERIFIED: 197-CONTEXT.md]

### Pitfall 4: Multi-Status Defaults Done Unsafely

**What goes wrong:** Webhooks needs `failed,dead`, but current `decode_status/1` tries a whole string as one existing atom. [VERIFIED: webhooks.ex]

**Why it happens:** `filter_query/2` supports list statuses, but `decode_filter/1` never emits a list from comma-separated status text. [VERIFIED: webhooks.ex]

**How to avoid:** add allowlisted comma-split decode returning `[:failed, :dead]` and encode lists back to comma strings; model after Invoices' allowlist. [VERIFIED: invoices.ex] [VERIFIED: webhooks.ex]

### Pitfall 5: Connect Attention Lens as AND Filters

**What goes wrong:** using `deauthorized=true&charges_enabled=false&payouts_enabled=false&details_submitted=false` would only show accounts matching every condition, not any account needing attention. [VERIFIED: connect_accounts.ex]

**Why it happens:** current `ConnectAccounts.filter_query/2` reduces filters with AND semantics. [VERIFIED: connect_accounts.ex]

**How to avoid:** add `needs_attention=true` in `decode_filter/1` and a single OR predicate covering deauthorized, incomplete onboarding, disabled charges, or disabled payouts. [VERIFIED: 197-CONTEXT.md]

## Code Examples

### Safe Clear-All Target

```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
defp clear_all_href(_params, table_path) do
  AccrueAdmin.DataTableNav.merge_query(table_path, %{
    "view" => "all",
    "q" => nil,
    "status" => nil,
    "customer_id" => nil,
    "cursor" => nil,
    "phase196_state" => nil
  })
end
```

### Allowlisted Multi-Status Decode Shape

```elixir
# Source pattern: accrue_admin/lib/accrue_admin/queries/invoices.ex
@valid_invoice_statuses ~w(draft open paid uncollectible void)

defp filter_status(query, status) when is_binary(status) do
  values =
    status
    |> String.split(",", trim: true)
    |> Enum.filter(&(&1 in @valid_invoice_statuses))

  case values do
    [] -> query
    [single] -> where(query, [invoice, _customer], invoice.status == ^String.to_existing_atom(single))
    multiple -> where(query, [invoice, _customer], invoice.status in ^Enum.map(multiple, &String.to_existing_atom/1))
  end
end
```

### Playwright PageHeader Contract

```javascript
// Source: accrue_admin/e2e/admin-spec-list-phase196.spec.js
async function assertPageHeaderContract(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);
  await expect(page.locator("[data-ax-page-header]"), `${label}: PageHeader marker`).toBeVisible();
  await expect(page.locator("[data-ax-page-title]"), `${label}: title marker`).toBeVisible();
  await expect(page.locator("[data-ax-page-filter-toolbar]"), `${label}: filter toolbar slot`).toBeVisible();
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline page headers on each list | Shared `PageHeader` with slot contract | Phase 196 | Phase 197 should migrate all remaining list pages without rethinking the header API. [VERIFIED: 196-CONTEXT.md] [VERIFIED: page_header.ex] |
| DataTable-owned filter toolbar | Toolbar passed through `PageHeader` slot, `DataTable` renders rows/states only | Phase 196 | Planner must move filters out of DataTable chrome while keeping `DataTable.filter_toolbar/1`. [VERIFIED: subscriptions_live.ex] |
| Generic empty copy | Per-state copy: first-run, filtered, queue, loading | Phase 196 | Planner must add page-specific copy for all targets. [VERIFIED: subscriptions_live_test.exs] |
| Page-flow blind source gates | Rendered Playwright state/viewport/theme checks | v1.54 Phases 193/196 | Phase 197 should add smokes and representative deep coverage, not full exhaustive matrix. [VERIFIED: 193-CONTEXT.md] [VERIFIED: 197-CONTEXT.md] |

**Deprecated/outdated:**

- Inline `<header class="ax-page-header">` plus separate stat strip is outdated for target list pages; use `PageHeader.page_header/1`. [VERIFIED: target LiveViews] [VERIFIED: page_header.ex]
- `/charges` UI language is outdated for payments; `/payments` is the route and `ChargesLive` is only the implementation module. [VERIFIED: router.ex] [VERIFIED: 197-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Use one cross-page `phase197_state=loading-skeleton` test param rather than page-specific loading fixture params. | Open Questions; Validation Architecture | Planner may need per-page fixture params instead, increasing test helper work. |
| A2 | Add Charges owner-scope filtering while migrating Payments. | Open Questions; Security Domain | If intentionally deferred, the planner should turn this into a checkpoint instead of implementation work. |
| A3 | Add `admin-spec-list-phase197.spec.js` and an `e2e:phase197` npm script for the Phase 197 browser gate. | Validation Architecture | Planner may choose an existing script or alternate spec name, but still needs equivalent coverage. |
| A4 | Put the hand-authored LIST contract manifest in `accrue_admin/test/support/list_contracts.ex` or an equivalent test-only support module. | Validation Architecture | Wrong location could create test-support churn, but runtime behavior is unaffected. |
| A5 | Treat this research as valid until 2026-07-27 unless dependency versions or Phase 196/197 decisions change sooner. | Metadata | Planner should re-run version/context checks if execution happens after that date or after relevant upstream changes. |

## Open Questions

1. **Should page-specific loading fixture params share a generic name?**
   - What we know: Subscriptions uses `phase196_state=loading-skeleton`; `DataTable` accepts `loading_fixture`/`loading_state?`. [VERIFIED: subscriptions_live.ex] [VERIFIED: data_table.ex]
   - What's unclear: Whether Phase 197 should use one cross-page test param such as `phase197_state=loading-skeleton` or page-specific params. [ASSUMED]
   - Recommendation: Use a single test-only `phase197_state=loading-skeleton` helper pattern across target pages to simplify Playwright coverage, and strip it in clear-all targets. [ASSUMED]

2. **Should Charges query gain owner-scope SQL support in this phase?**
   - What we know: `ChargesLive` passes `current_owner_scope` to `DataTable`, but `Queries.Charges.list/1` currently ignores `owner_scope`; Invoices and Subscriptions do scope through customer joins. [VERIFIED: charges_live.ex] [VERIFIED: charges.ex] [VERIFIED: invoices.ex]
   - What's unclear: Whether this was intentionally deferred or simply missed. [ASSUMED]
   - Recommendation: Add owner-scope filtering for Charges while migrating Payments, because clear-all preservation without query scoping is incomplete for org mode. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | ExUnit and asset tasks | yes | Mix 1.19.5 / OTP 28 | None needed. [VERIFIED: `mix --version`] |
| PostgreSQL | LiveView/query tests | yes | psql 14.17; `pg_isready` accepting connections | None needed. [VERIFIED: `psql --version`] [VERIFIED: `pg_isready`] |
| Node.js | Playwright e2e | yes | v22.14.0 | None needed. [VERIFIED: `node --version`] |
| npm | Playwright e2e scripts | yes | 11.1.0 | None needed. [VERIFIED: `npm --version`] |
| Chromium | Playwright browser | yes | `/opt/homebrew/bin/chromium` | `npm run e2e:install` if missing. [VERIFIED: `command -v chromium`] [VERIFIED: package.json] |
| `@playwright/test` | Browser smoke/deep coverage | yes | 1.59.1 installed | Use existing package lock/install. [VERIFIED: `npm ls`] |

**Missing dependencies with no fallback:** none. [VERIFIED: environment audit]

**Missing dependencies with fallback:** none currently; if a browser is missing in another environment, run `cd accrue_admin && npm run e2e:install`. [VERIFIED: package.json]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through `mix test`; Playwright through `@playwright/test` 1.59.1. [VERIFIED: mix.exs] [VERIFIED: npm ls] |
| Config file | `accrue_admin/playwright.config.js`; ExUnit helper at `accrue_admin/test/test_helper.exs`. [VERIFIED: rg --files] |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` [VERIFIED: test files exist] |
| Full suite command | `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase197` after adding a Phase 197 script/spec; until then use targeted spec path with `npx playwright test e2e/admin-spec-list-phase197.spec.js --timeout=60000 --workers=1`. [VERIFIED: package.json] [ASSUMED] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRP-01 | Eight target LiveViews render `PageHeader`, exactly one `<h1>`, toolbar slot, list marker, chips/count/clear-all, and page-specific states. | ExUnit LiveView | `cd accrue_admin && mix test test/accrue_admin/live/*_live_test.exs --warnings-as-errors` | Existing files yes; assertions need expansion. [VERIFIED: rg --files] |
| PRP-01 | All eight target routes smoke in browser across light/dark and desktop/mobile for no clipping and row-to-card degradation. | Playwright | `cd accrue_admin && npx playwright test e2e/admin-spec-list-phase197.spec.js --timeout=60000 --workers=1` | No; create in Wave 0. [VERIFIED: e2e dir] |
| PRP-01 | Representative pages cover first-run-empty, filtered-empty, queue-empty, loading skeleton. | ExUnit + Playwright | ExUnit per-page tests plus representative Playwright cases. | Partial via Subscriptions only; target pages need gaps filled. [VERIFIED: subscriptions_live_test.exs] |

### Sampling Rate

- **Per task commit:** run the touched page's LiveView test plus any touched query test or component test. [VERIFIED: existing test layout]
- **Per wave merge:** run the eight target LiveView tests and the Phase 197 Playwright smoke. [ASSUMED]
- **Phase gate:** `cd accrue_admin && mix test --warnings-as-errors` plus Phase 197 Playwright spec; full Phase 200 gate remains later. [VERIFIED: 197-CONTEXT.md] [ASSUMED]

### Wave 0 Gaps

- [ ] `accrue_admin/test/support/list_contracts.ex` or equivalent test-only manifest for target route, list_id, default lens, all-target, expected copy. [ASSUMED]
- [ ] `accrue_admin/e2e/admin-spec-list-phase197.spec.js` all-page smoke plus representative deep cases. [VERIFIED: e2e dir] [ASSUMED]
- [ ] `accrue_admin/package.json` script `e2e:phase197` for the new Playwright spec. [VERIFIED: package.json] [ASSUMED]
- [ ] Expanded copy functions for per-page first-run, queue, filtered, and loading labels. [VERIFIED: copy modules]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Existing `AccrueAdmin.AuthHook` on mounted LiveView session; do not bypass. [VERIFIED: router.ex] [VERIFIED: auth_hook.ex] |
| V3 Session Management | yes | Existing Phoenix session threaded by router; Phase 197 should not change session keys. [VERIFIED: router.ex] |
| V4 Access Control | yes | Preserve `current_owner_scope`, `org` params, and query scoping on filter/clear paths. [VERIFIED: owner_scope.ex] [VERIFIED: data_table_nav.ex] |
| V5 Input Validation | yes | Query modules normalize and compact filter params; Webhooks multi-status must be allowlisted. [VERIFIED: queries/*.ex] |
| V6 Cryptography | no direct change | Webhook signature verification is outside this UI phase; preserve replay semantics and avoid raw sensitive logging. [VERIFIED: CLAUDE.md] |

### Known Threat Patterns for Phoenix LiveView Admin Lists

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Owner-scope leakage through dropped `org` param | Information Disclosure / Elevation of Privilege | Use `ScopedPath` and `DataTableNav.merge_query/2`; test clear-all with organization sessions. [VERIFIED: scoped_path.ex] [VERIFIED: data_table_nav_test.exs] |
| Atom abuse from URL filter params | Denial of Service | Use allowlisted string splits before `String.to_existing_atom/1`; model after Invoices. [VERIFIED: invoices.ex] |
| Replay action on out-of-scope webhook rows | Elevation of Privilege | Preserve `scope_selected_ids/2` before `DLQ.requeue/1`. [VERIFIED: webhooks_live.ex] [VERIFIED: webhooks_live_test.exs] |
| Misleading total count from visible page length | Tampering / Repudiation via UI misinformation | Label count as visible rows ("Showing N") unless exact scoped counts are implemented. [VERIFIED: filter_chip_bar.ex] [VERIFIED: 197-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/197-propagate-list/197-CONTEXT.md` - locked decisions, target pages, default lenses, verification breadth. [VERIFIED: codebase grep]
- `accrue_admin/guides/spec-list.md` - authoritative LIST contract. [VERIFIED: codebase grep]
- `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md` - Phase 196 exemplar and `PageHeader` contract. [VERIFIED: codebase grep]
- `accrue_admin/lib/accrue_admin/components/page_header.ex`, `data_table.ex`, `filter_chip_bar.ex`, `data_table_nav.ex` - implementation contracts. [VERIFIED: codebase grep]
- Eight target LiveViews and query modules under `accrue_admin/lib/accrue_admin/live/` and `queries/`. [VERIFIED: codebase grep]
- Existing ExUnit and Playwright tests in `accrue_admin/test/` and `accrue_admin/e2e/`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Phoenix.Component HexDocs 1.1.31 - attrs and slots. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.Component.html]
- Phoenix.LiveView HexDocs 1.1.31 - patch navigation and `handle_params/3`. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.LiveView.html]
- Playwright LocatorAssertions docs - `toHaveCount` and locator assertions. [CITED: https://playwright.dev/docs/api/class-locatorassertions]
- MDN `aria-busy` reference - loading/busy state semantics. [CITED: https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-busy]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - all recommended runtime pieces are existing locked deps or repo-local components. [VERIFIED: mix.lock] [VERIFIED: package.json] [VERIFIED: component source]
- Architecture: HIGH - Phase 196 exemplar and context explicitly lock the target composition. [VERIFIED: 196-CONTEXT.md] [VERIFIED: subscriptions_live.ex]
- Pitfalls: HIGH - each pitfall maps to observed target/query code or prior tests. [VERIFIED: codebase grep]
- External documentation: MEDIUM - official docs were checked by URL and cached through the research seam; they support framework mechanics but do not decide product semantics. [CITED: official docs]

**Research date:** 2026-06-27  
**Valid until:** 2026-07-27 for internal code-shape findings; re-check package/docs versions if dependency updates land before execution. [ASSUMED]
