# Phase 196: Exemplar C - Subscriptions list + PageHeader - Context

**Gathered:** 2026-06-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 196 delivers the v1.54 LIST archetype exemplar in `accrue_admin` and locks the shared `PageHeader` component API before Phase 197 propagates the pattern to the remaining list pages.

Two deliverables are in scope:

1. **Subscriptions list exemplar** (`accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`) - table-first list grammar conforming to SPEC-LIST: work-queue default, "All" one chip away, visible filter chips + result count + clear-all, identity/state/money/time column priority, row-to-card mobile degradation, and distinct populated / first-run-empty / filtered-empty / loading-skeleton states.
2. **Shared `AccrueAdmin.Components.PageHeader`** - a Phoenix function component whose contract is frozen before propagation: breadcrumbs attr, title attr, description slot, stat-strip slot, actions slot, and filter-toolbar slot, with exactly one content `<h1>` per page.

Fixed guardrails carried forward: `accrue_admin` operator UI only; no `accrue_portal` implementation; no new billing primitives, routes, or breaking public APIs; no Tailwind migration; custom `ax-*` CSS and the committed admin bundle remain the styling SSOT; copy changes go through `AccrueAdmin.Copy`; Storybook is dev/test-only; page-flow forward-only scoring remains the regression mechanism.

</domain>

<decisions>
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

### Claude's Discretion

- Exact CSS class names under the locked `data-ax-*` markers, as long as they use existing `ax-*` tokens and rebuild the committed admin bundle when source CSS changes.
- Whether the filter toolbar extraction is a small helper in `DataTable`, a sibling component, or a narrow internal slot, as long as `PageHeader` proves the `:filter_toolbar` slot and remains state-free.
- Exact lifecycle badge copy and plan/amount fallback text, bounded by domain honesty and `AccrueAdmin.Copy`.
- Whether result count is emitted from `FilterChipBar` or a thin list-status wrapper; the visible marker and honest label are locked.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked LIST contract
- `accrue_admin/guides/spec-list.md` - authoritative SPEC-LIST contract for Phase 196/197: table-first, chips + count + clear-all, four distinct states, identity/state/money/time priority, dense row rhythm, no one-page pagination.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` - foundation decisions for archetype specs, source-guard strategy, Storybook posture, and forward-only page-flow baseline.

### Prior exemplar decisions
- `.planning/phases/194-exemplar-a-dashboard/194-CONTEXT.md` - additive `data-ax-*` marker convention, refine-not-rebuild posture, copy/asset rebuild footguns.
- `.planning/phases/195-exemplar-b-subscription-detail/195-CONTEXT.md` - boundary discipline, overlay API already frozen, copy regeneration and committed CSS bundle footguns.
- `.planning/phases/195-exemplar-b-subscription-detail/195-PATTERNS.md` - implementation analogs for component API locking, Storybook stories, page-flow selectors, and frozen propagation contracts.

### v1.54 design source
- `.planning/research/SUMMARY.md` - v1.54 synthesis: defects are structural; page-design work is archetype-driven; list pattern is table-first + PageHeader + chips/count/clear-all.
- `.planning/research/FEATURES.md` - detailed archetype research for LIST pages, table-vs-card rationale, work-queue defaults, and anti-patterns.
- `.planning/research/ARCHITECTURE.md` - interaction/motion constraints: no decorative row stagger, keep token vocabulary, defer overlay work to 199.
- `.planning/research/PITFALLS.md` - source-guard and rendered-gate rationale, especially truncation/min-width, no hover on non-interactive empty states, and conditional affordances.
- `.planning/research/v1.54-storybook-and-forward-only-qa.md` - Storybook/forward-only page-flow expectations and why Storybook is lab, not the page regression engine.

### Brand, voice, and admin UI
- `brandbook/voice.md` - ratified voice system: measured, exact, native, durable; avoid adjective-led claims and salesy/admin-inappropriate copy.
- `brandbook/copy.md` - copy examples and empty-state tone; Phase 196 state-specific copy supersedes its older generic Subscriptions empty-state string.
- `brandbook/tokens/README.md` - brand token documentation; admin `--ax-*` tokens remain implementation SSOT.
- `accrue_admin/guides/admin_ui.md` - admin integration guide and UI principles: least surprise, clear hierarchy, visible focus, explicit list states, host-auth/package boundary, committed bundle rebuild.
- `accrue_admin/guides/core-admin-parity.md` - existing route/copy/token parity matrix; useful to identify current list page copy gaps for Phase 197.

### Todos folded into this context
- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` - direct PageHeader extraction TODO.
- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` - portal design-system TODO folded only as boundary/deferred signal; do not implement in Phase 196.

### Surfaces this phase edits or reuses
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` - exemplar page to convert.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` - shared stateful list primitive; add explicit state markers, optional loading skeleton support, filter/result/clear affordance support as needed.
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` - shared chip row; likely home for chips/count/clear-all markers.
- `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex` - breadcrumb primitive to wrap/reuse inside `PageHeader`.
- `accrue_admin/lib/accrue_admin/components/stat_strip.ex` - stat-strip slot content for `PageHeader`.
- `accrue_admin/lib/accrue_admin/components/status_badge.ex` - lifecycle state display if the Subscriptions columns adopt badges.
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` - query/filter source; preserve server-side filtering and owner scope.
- `accrue_admin/lib/accrue_admin/copy.ex` - copy home for new list/header/empty/loading strings.
- `accrue_admin/assets/css/app.css` and `accrue_admin/assets/css/theme.css` - source CSS; rebuild `accrue_admin/priv/static/accrue_admin.css` after changes.

### Verification seams
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` - extend for state markers, result count, clear-all, loading skeleton fixture.
- `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs` - extend for chips/count/clear-all markers and href behavior.
- `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` or a new `page_header_test.exs` - add `PageHeader` component tests.
- `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` - extend for one `<h1>`, default queue, chips/count/clear-all, distinct empty states, and column priority.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` and `accrue_admin/e2e/phase191-page-flow-helpers.js` - reuse page-flow driver patterns for Phase 196 SPEC-LIST coverage.
- `storybook/components/` - add `page_header.story.exs` and, if budget allows, a Subscriptions-list composite story that uses real components.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`SubscriptionsLive`** already has the default queue (`past_due,canceling`), stat strip, work-queue chips, DataTable, mobile `card_fields`, owner-scoped paths, and queue-aware empty copy. Phase 196 should refine and lock, not rebuild.
- **`DataTable`** already owns server-side query loading, filter form, cursor pagination, mobile card degradation, selectable rows, polling, empty-state resolution, and `data-component-group="table-empty-loading-error-pagination"`.
- **`FilterChipBar`** already supports active chips, inactive/activation links, remove links, tones, and Phase 191 focus anchors. It is the natural place to add `data-ax-filter-chips`, result count, and clear-all.
- **`Breadcrumbs` + `StatStrip`** already exist as small function components. `PageHeader` should compose them rather than duplicating their internal APIs.
- **Component kitchen/registry group** already includes table empty/loading/error/pagination examples. Use it as precedent for Storybook states and loading fixtures.
- **Phase 191 page-flow helpers** already assert no horizontal clipping, scroll reachability, focus containment, and pointer hit-testing. Reuse the pattern for SPEC-LIST state/viewport coverage.

### Established Patterns

- **Phoenix function components with `attr`/`slot`** are the right local style for stateless, reusable markup. LiveComponents are reserved for stateful behavior like `DataTable`.
- **URL patch filters** are the established list pattern. Parent-targeted `data_table_filter` forms drive `push_patch`; do not introduce client-only filter state.
- **Source-lint where mechanical, render-detect where compositional.** Data markers and state selectors are machine assertions; density, hierarchy, and whether columns serve the operator job remain rubric/judge checks.
- **Custom `ax-*` CSS + committed bundle is SSOT.** Editing source CSS ships nothing unless `mix accrue_admin.assets.build` is run and the generated bundle is committed.
- **Copy belongs in `AccrueAdmin.Copy`.** Subscriptions currently has some raw strings; Phase 196 should burn down touched strings through Copy and regenerate any committed copy fixture if the Playwright suite depends on it.

### Integration Points

- `PageHeader` should be imported/aliased into Subscriptions and later list pages.
- `FilterChipBar` / list-status markers wire directly into SPEC-LIST Playwright assertions: chips, result count, clear-all.
- `DataTable` state markers wire into populated / first-run-empty / filtered-empty / loading page-flow cells.
- Subscriptions query/presentation may need additional projection for plan/amount. If amount cannot be derived honestly, use plan/quantity language and defer exact money.
- Storybook adds a `PageHeader` story now; Phase 200 completes all families/groups.

</code_context>

<specifics>
## Specific Ideas

- The final recommendation is one cohesive package: `PageHeader` provides stable page orientation; the list keeps resource-owned filters/query state; `FilterChipBar` makes current constraints legible; `DataTable` owns rows/pagination/states; Subscriptions proves the whole LIST grammar before propagation.
- User intent for this discussion was full delegation after research: "one-shot a perfect set of recommendations so I don't have to think." No further user choice is needed before planning unless implementation uncovers a hard technical blocker.
- External patterns considered by advisor research:
  - Phoenix `Phoenix.Component` attrs/slots and `Phoenix.LiveComponent` boundaries.
  - Shopify Polaris Page / IndexTable / IndexFilters style separation of page shell, table, and caller-owned resource state.
  - Stripe subscription/resource list conventions and Dashboard clarity.
  - ActiveAdmin and Laravel Nova resource tables/lenses: resource-owned filters/actions behind shared conventions, not one giant generic facade.
  - GOV.UK / MOJ selected-filter and table guidance: selected filters visible above results; tables for comparison tasks.
  - WAI-ARIA / accessibility guidance for breadcrumbs, busy/status announcements, and non-disruptive loading.
- Brand precedence: current admin/v1.54 research and shipped guides first; ratified `brandbook/` next; older `prompts/accrue-brand-book.md` as conceptual background only.

</specifics>

<deferred>
## Deferred Ideas

- **Full LIST propagation** - Phase 197 owns customers, invoices, payments, coupons, promotion codes, webhooks, events, and connect adopting `PageHeader` and SPEC-LIST.
- **Full `ListPage` facade / resource DSL** - rejected for Phase 196. Revisit only if repeated Phase 197 code proves real duplication beyond `PageHeader` + `DataTable` + `FilterChipBar`.
- **Saved views / Nova-style lenses / scope tabs** - deferred unless a future product need emerges for named operator queues. Current At risk / All chips are enough.
- **Exact total-count query API across all lists** - deferred. Use honest visible-row count labels for cursor pagination unless Phase 197/200 makes exact totals a hard requirement.
- **Broad async DataTable rewrite** - deferred. Use explicit loading fixtures/skeletons and keep production SSR-synchronous unless a real slow query path appears.
- **Bulk actions on subscriptions list** - not in Phase 196 unless already present and trivial; saved for a future operator workflow if sourced by usage.
- **Cross-cutting overlay/interaction/theme/microcopy sweep** - Phase 199/200.
- **`accrue_portal` white-label billing portal design-system pass** - future portal milestone. The folded portal TODO is explicitly not implemented in this admin LIST exemplar.

</deferred>

---

*Phase: 196-exemplar-c-subscriptions-list-pageheader*
*Context gathered: 2026-06-26*
