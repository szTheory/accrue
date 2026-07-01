# Phase 197: Propagate LIST - Context

**Gathered:** 2026-06-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 197 applies the locked v1.54 LIST archetype to the eight remaining
`accrue_admin` list pages:

- Customers: `accrue_admin/lib/accrue_admin/live/customers_live.ex`
- Invoices: `accrue_admin/lib/accrue_admin/live/invoices_live.ex`
- Payments: `accrue_admin/lib/accrue_admin/live/charges_live.ex` on the `/payments` route
- Coupons: `accrue_admin/lib/accrue_admin/live/coupons_live.ex`
- Promotion codes: `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex`
- Webhooks: `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`
- Events: `accrue_admin/lib/accrue_admin/live/events_live.ex`
- Connect accounts: `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex`

The deliverable is LIST propagation, not new list design: each target page
conforms to SPEC-LIST, adopts `AccrueAdmin.Components.PageHeader`, exposes filter
chips + visible count + clear-all where filters/lenses are active, keeps the
table-first `DataTable` with row-to-card mobile degradation, and covers the four
list states: populated, first-run-empty, filtered-empty, loading-skeleton.

Fixed guardrails: scope is `accrue_admin` operator UI only; no `accrue_portal`
work; no new billing primitives, routes, or breaking public APIs; no Tailwind
migration; custom `ax-*` CSS plus the committed admin bundle remain the styling
SSOT; copy goes through `AccrueAdmin.Copy` / its copy modules; Storybook breadth,
overlay correctness, fixture stress, full microcopy sweep, axe/no-FOUC, and final
zero-regression sign-off remain Phase 199/200 ownership.

</domain>

<decisions>
## Implementation Decisions

### Cohesive Recommendation

- **D-01 - Apply strict LIST exemplar parity without inventing a `ListPage` DSL.** Phase 197 should migrate all eight target pages to the Phase 196 composition: `PageHeader` for orientation, `DataTable.filter_toolbar` in the `PageHeader` `:filter_toolbar` slot, `DataTable` with `render_filter_toolbar={false}`, and `FilterChipBar` in the `DataTable` `:list_status` slot. Do not create a new generic `ListPage` facade, saved-view/lens DSL, or attr-heavy resource map abstraction in this phase. Phoenix idiom here is small stateless function components for shared markup plus LiveViews owning URL/query/bulk/action state.
- **D-02 - Treat "work queue" as the default operator job for each page, not as a forced exception filter everywhere.** SPEC-LIST's work-queue rule means the page opens on the view the operator most likely came to do. For invoices, payments, webhooks, and connect this is an exception queue. For customers and events it is a lookup/ledger default with quick lenses. Do not manufacture weak queues that hide expected records.
- **D-03 - Keep all filters URL-backed and page-owned.** Each LiveView continues to handle `data_table_filter` via `AccrueAdmin.DataTableNav.patch_with_filters/3` and `handle_params/3`. Query decoding, default params, clear-all targets, owner scope, bulk replay, and page-specific copy stay in the page/query module. `PageHeader` must not own filters or resource state.
- **D-04 - Counts stay honest.** `FilterChipBar` should show visible row counts unless a page explicitly implements a scoped exact-count query. Do not imply a query-wide exact total from cursor-paginated visible rows. Copy should read like "Showing N invoices" or equivalent, not "N total invoices" unless true.

### Per-page Default Lenses

- **D-05 - Customers default to all customers, with a missing-payment-method quick lens.** Customers is primarily Support's lookup surface ("Find one customer"). Bare `/customers` should not hide customers. Render an active "All customers" chip/lens and a one-click "Missing payment method" chip using `has_default_payment_method=false`. Clear-all returns to the all-customer view while preserving `org`.
- **D-06 - Invoices default to `Needs collection`.** Keep the existing default `status=open,uncollectible`, but present it as operator language, not raw backend flags. The All escape hatch routes to `view=all`, preserving owner scope and clearing `q`, `status`, `customer_id`, `collection_method`, `cursor`, and any fixture params.
- **D-07 - Payments default to failed charges.** `/payments` is implemented by `ChargesLive`; do not create or reference a `/charges` route in UI/test copy. Default to `status=failed` with user-facing chip/copy like "Failed payments." All routes to `view=all` and preserves owner scope if scope support is present or added.
- **D-08 - Coupons default to valid coupons.** Coupons are inventory/reference objects, but the default operator job is reviewing currently usable discounts. Default `valid=true` and render "Valid coupons" plus All. First-run empty means no coupons exist; queue-empty means no valid coupons are currently usable; filtered-empty means the user's filters excluded rows.
- **D-09 - Promotion codes default to active codes.** Default `active=true` and render "Active codes" plus All. Do not conflate inactive codes with errors; inactive/expired codes remain accessible through All or explicit filters.
- **D-10 - Webhooks default to replayable failures.** Use a user-facing "Needs replay" lens covering failed/dead webhook events. `AccrueAdmin.Queries.Webhooks.filter_query/2` already accepts list statuses, but `decode_status/1` currently decodes only one status. Planning should add safe multi-status decode for `status=failed,dead` (or another named param that compiles to that list) instead of faking this in UI copy. Preserve existing bulk retry selection and confirmation behavior.
- **D-11 - Events default to the full append-only ledger.** Events is Compliance/Audit's ledger: "Who did what, when?" Bare `/events` should not hide ledger rows. Render an active "All ledger" chip and keep quick chips like `actor_type=admin` ("Admin changes") one click away. This follows the v1.51 decision that Compliance is a lens on the event log, not a separate nav group.
- **D-12 - Connect defaults to accounts needing attention via a named OR lens.** The default should surface accounts with deauthorization, onboarding incomplete, charges disabled, or payouts disabled. Current `ConnectAccounts` query filters AND the individual boolean params, so do not approximate this by combining existing booleans. Add a narrow page/query-owned lens such as `needs_attention=true` that compiles to an OR predicate, with All as the escape hatch.

### PageHeader and JTBD Copy

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

### Filter Chips, Clear-all, and Four States

- **D-16 - Use `FilterChipBar` as the selected-lens/filter/status surface.** Every target page should render a chip row through `FilterChipBar.filter_chip_bar/1` in `DataTable`'s `:list_status` slot. It must include `[data-ax-filter-chips]`, `[data-ax-result-count]`, and `[data-ax-clear-all]` when a selected/default/filter lens is removable. Remember `FilterChipBar.active` means "render this chip," not necessarily "selected"; selected-vs-available is expressed through `remove_href`, `href`, tone, and copy.
- **D-17 - Clear-all means the operator can see all rows for this resource.** For narrowed defaults, clear-all routes to `view=all`. For reference defaults (customers/events), clear-all removes filters and returns to the all view/base route. All clear paths must preserve `org` / owner scope and must not create a blank-URL redirect loop.
- **D-18 - Four-state copy is page-specific.** Each page needs distinct populated, first-run-empty, filtered-empty, and loading-skeleton behavior. First-run empty must explain how rows arrive. Filtered empty must offer clear filters. Queue-empty can be a positive state ("Nothing needs replay", "No failed payments") only when the underlying resource exists but the default queue is clear. Loading skeletons are dev/test/story/page-flow fixtures unless a real async path exists; do not add fake production delay.
- **D-19 - Keep table/card column priority focused on operator nouns.** Desktop columns and mobile card fields should prioritize identity, state, money/amount/value, time, then signals. Plumbing IDs, raw UUIDs, and raw backend flags are secondary text or detail-page material. Webhooks/events may legitimately prioritize type/status/subject/actor/time because those are the ledger/debugging nouns.

### Verification and Planning Shape

- **D-20 - Use all-page contract smoke plus deeper representative coverage.** Phase 197 should not run a full `8 pages x 4 states x 2 themes x 2 viewports` matrix; that duplicates component coverage and steals Phase 200's final sign-off role. Instead:
  - Component tests keep `PageHeader`, `DataTable`, and `FilterChipBar` contracts locked.
  - Each of the eight LiveViews gets focused tests for one `<h1>`, `PageHeader` markers, default lens params, chips/count/clear-all, distinct empty copy, and owner-scope-preserving clear paths.
  - Playwright smokes all eight pages for `PageHeader`, `[data-ax-list]`, active chips/count/clear-all where applicable, mobile row-to-card rendering, no horizontal clipping, and page-level light/dark sanity.
  - Deeper four-state desktop/mobile/theme coverage runs on representative high-risk pages: customers/reference default, invoices or payments/status queue, webhooks/actionable bulk queue, events/ledger lens, and connect/OR attention lens.
- **D-21 - A thin hand-authored LIST contract manifest is acceptable; a generated DSL is not.** The planner may introduce a test-only manifest/table of route, list_id, default lens, all-target, and expected copy for tests. It must not become a runtime resource DSL or source-generate page behavior from itself.
- **D-22 - Slice execution by risk.** Recommended plan order: (1) shared/test contract and any narrow helper seams; (2) simple inventory/reference pages (customers, coupons, promotion codes); (3) queue/action pages (invoices, payments, webhooks, events, connect); (4) browser verification. Preserve Webhooks bulk replay and Connect readiness semantics rather than flattening them into generic list code.

### Folded Todos

- **Shared page_header component for accrue_admin list pages** (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`) - folded into Phase 197 as propagation of the Phase 196 `PageHeader` contract. The component already exists and is proven on Subscriptions; Phase 197 adopts it across the remaining list pages and finishes the todo's original goal.

### Claude's Discretion

- Exact helper extraction after the first two or three page migrations, provided helpers stay pure/narrow and LiveViews own resource state.
- Exact chip labels, empty-state body copy, and stat-strip labels, bounded by the per-page default lenses and brandbook voice.
- Whether the test-only contract manifest lives in ExUnit test support, Playwright fixtures, or both.
- Which queue pages receive the deepest Playwright state coverage, provided the representative set includes reference, status queue, bulk-action, ledger, and OR-lens cases.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked LIST Contract and Phase Inputs

- `accrue_admin/guides/spec-list.md` - authoritative SPEC-LIST contract: table-first, four states, chips/count/clear-all, row-to-card mobile degradation, identity/state/money/time priority.
- `.planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-CONTEXT.md` - locks `PageHeader`, `DataTable`, `FilterChipBar`, default queue/All behavior, and Phase 197 propagation boundary.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` - archetype specs, source-guard strategy, Storybook posture, and page-flow baseline context.
- `.planning/ROADMAP.md` - Phase 197 scope and PRP-01 success criteria.
- `.planning/REQUIREMENTS.md` - PRP-01 mapping and v1.54 exclusions.
- `.planning/STATE.md` - current milestone state and prior Phase 196 decisions.

### v1.54 Research and Prior Persona Decisions

- `.planning/research/SUMMARY.md` - v1.54 synthesis: defects are structural; list pattern is table-first + `PageHeader` + chips/count/clear-all.
- `.planning/research/FEATURES.md` - detailed LIST archetype rationale, table vs cards, work-queue defaults, and anti-patterns.
- `.planning/research/PITFALLS.md` - no hover on non-interactive surfaces, truncation/min-width, conditional affordance, disabled/focus/contrast pitfalls.
- `.planning/research/ARCHITECTURE.md` - interaction/motion boundaries; no row stagger; keep overlay work in Phase 199.
- `.planning/research/v1.54-storybook-and-forward-only-qa.md` - rendered state-matrix and forward-only page-flow expectations.
- `.planning/research/v1.51-admin-ui-depth-design.md` - operator personas and prior decision that list screens default to persona work queues, with Compliance as an event-log actor lens.
- `.planning/research/STACK.md` - canonical Elixir/Phoenix stack posture for mounted LiveView package UX.

### Brand, Voice, and Prompt Corpus

- `brandbook/voice.md` - current source of truth for voice: measured, exact, native, durable; avoid sales/fintech/posturing language.
- `brandbook/copy.md` - approved microcopy examples and empty-state tone; older examples should be adapted to current LIST state semantics.
- `brandbook/tokens/README.md` - brand token documentation; admin `--ax-*` tokens remain implementation SSOT.
- `prompts/accrue-brand-book.md` - older brand seed; use only where it reinforces the current brandbook, and prefer `brandbook/` on conflict.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - durable adopter/DX lens: optimize for realistic operator value, least surprise, and repo-local proof over polish churn.

### Existing Components and Helpers

- `accrue_admin/lib/accrue_admin/components/page_header.ex` - locked stateless `PageHeader` component and slot contract.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` - shared LiveComponent: list-state markers, loading skeleton fixture, filter toolbar, row-to-card cards, `:list_status` slot.
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` - chip row with `[data-ax-filter-chips]`, `[data-ax-result-count]`, and `[data-ax-clear-all]`.
- `accrue_admin/lib/accrue_admin/components/stat_strip.ex` - stat strip slot content for `PageHeader`.
- `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex` - breadcrumb primitive composed by `PageHeader`.
- `accrue_admin/lib/accrue_admin/data_table_nav.ex` - URL merge helper that preserves existing query params such as `org`; use for filter and clear-all patches.
- `accrue_admin/lib/accrue_admin/copy.ex` and `accrue_admin/lib/accrue_admin/copy/*.ex` - home for touched page copy.

### Target Pages

- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` - LIST exemplar to copy structurally, not a target of Phase 197 except for regression protection.
- `accrue_admin/lib/accrue_admin/live/customers_live.ex` - customer lookup/reference list.
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` - needs-collection invoice queue.
- `accrue_admin/lib/accrue_admin/live/charges_live.ex` - payments route implementation; default failed-payment queue.
- `accrue_admin/lib/accrue_admin/live/coupons_live.ex` - valid coupon inventory.
- `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` - active promotion-code inventory.
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` - failed/dead webhook replay queue with bulk replay action.
- `accrue_admin/lib/accrue_admin/live/events_live.ex` - append-only billing event ledger with actor/source lenses.
- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` - connected-account readiness list.

### Query Seams

- `accrue_admin/lib/accrue_admin/queries/invoices.ex` - already supports comma-separated invoice status filters.
- `accrue_admin/lib/accrue_admin/queries/charges.ex` - payments/charges query; supports comma-separated status strings.
- `accrue_admin/lib/accrue_admin/queries/customers.ex` - supports `has_default_payment_method`.
- `accrue_admin/lib/accrue_admin/queries/coupons.ex` - supports `valid`.
- `accrue_admin/lib/accrue_admin/queries/promotion_codes.ex` - supports `active`.
- `accrue_admin/lib/accrue_admin/queries/webhooks.ex` - `filter_query/2` supports status lists, but decoder currently needs safe multi-status handling for the "Needs replay" default.
- `accrue_admin/lib/accrue_admin/queries/events.ex` - supports actor/type/source filters for ledger lenses.
- `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex` - supports individual readiness booleans; Phase 197 needs a named OR lens for "Needs attention."

### Verification Seams

- `accrue_admin/test/accrue_admin/components/page_header_test.exs` - PageHeader contract tests.
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` - DataTable state marker, loading, toolbar, and list-status tests.
- `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs` - chip/count/clear-all marker tests.
- `accrue_admin/test/accrue_admin/data_table_nav_test.exs` - query merge and owner-scope preservation tests.
- `accrue_admin/test/accrue_admin/live/*_live_test.exs` - per-page LiveView contract tests for the target pages.
- `accrue_admin/e2e/admin-spec-list-phase196.spec.js` - Subscriptions LIST exemplar Playwright contract to extend or mirror for Phase 197.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` - reusable Playwright helpers for clipping, scroll, viewport, and page-flow assertions.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` - prior page-flow driver pattern.

### Todos Considered

- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` - folded into Phase 197 propagation.
- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` - reviewed as boundary context only; future `accrue_portal` work, not Phase 197.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`PageHeader.page_header/1`** already exists with required `breadcrumbs` and `title` attrs plus `:description`, `:stat_strip`, `:actions`, and `:filter_toolbar` slots. It composes `Breadcrumbs` and renders the one content `<h1>`.
- **`DataTable`** already exposes `data-ax-list`, `data-ax-state`, `data-ax-empty-reason`, `loading_fixture`, `loading_label`, `render_filter_toolbar`, the `:list_status` slot, table skeletons, mobile card skeletons, and row-to-card rendering.
- **`FilterChipBar`** already renders active chips, result counts, clear-all, activation links, and clear links. It is the correct surface for current lens/filter visibility.
- **`DataTableNav.merge_query/2`** prevents double-`?` query corruption and preserves scope params. Clear-all and default patches should use it rather than string concatenation.
- **Target pages already use `DataTable`.** Phase 197 is mostly structural propagation plus copy/default/state work, not a table rewrite.

### Established Patterns

- **Phoenix function components for stateless shared chrome; LiveComponents for stateful list behavior.** This supports keeping `PageHeader` stateless and avoiding a broad `ListPage` facade.
- **URL patch filters are the local list pattern.** Parent-targeted `data_table_filter` events call `DataTableNav`; query modules decode URL params.
- **Source-lint where mechanical, rendered-detect where compositional.** Page-level hierarchy, density, and whether a default lens serves the operator job remain page-flow/rubric work, not a source-only guard.
- **Copy and committed assets need lockstep.** New copy should live in copy modules. CSS changes require rebuilding the committed admin bundle.
- **Reference/ledger pages are legitimate LIST pages.** They can satisfy SPEC-LIST without pretending every list is an exception queue.

### Integration Points

- Each target LiveView imports/aliases `PageHeader` and `FilterChipBar` as needed.
- Filter toolbar moves from `DataTable` header into `PageHeader` while keeping `DataTable`'s `render_filter_toolbar={false}`.
- Each page adds default-param handling patterned after Subscriptions for SSR-safe first paint where a narrowed default exists.
- Webhooks may need decoder support for multi-status defaults; Connect needs a named OR lens. These are query-owned seams, not component changes.
- Phase 197 Playwright should reuse the Phase 196 LIST selectors and page-flow helpers so Phase 200 can fold the results into the forward-only baseline.

</code_context>

<specifics>
## Specific Ideas

- User asked to discuss all gray areas and delegate the research: work-queue defaults, PageHeader/JTBD copy, chip/count/clear-all semantics, and verification breadth were each researched by a separate advisor subagent.
- All four research lenses converged on the same architecture: strict Phase 196 exemplar propagation, semantic per-resource defaults, LiveView-owned URL state, no `ListPage` DSL, and all-page smoke plus representative deep verification.
- External lessons applied:
  - Shopify Polaris separates page shell from resource table/filter behavior.
  - Stripe-style dashboards distinguish lookup/ledger pages from operational queues.
  - GOV.UK/MOJ reinforce visible selected filters, clear filters, and table-first comparison tasks.
  - ActiveAdmin/Nova scopes/lenses are resource-owned; the lesson is not to hide all resource semantics in a universal shell.
  - Phoenix idiom favors attrs/slots for stateless components and LiveView/LiveComponent boundaries for state.
- Design pillars considered for this phase: accessibility (one h1, status/count visibility, mobile cards), performance (cursor pagination and no exact-total count unless real), consistency (PageHeader + chips + table rhythm), resilience (owner-scope preserving URLs), brand voice (measured/exact/native copy), dark/light/system correctness (reuse existing `ax-*` tokens), and maintainability/DX (small helpers over a generic DSL).

</specifics>

<deferred>
## Deferred Ideas

- **Runtime `ListPage` facade / resource DSL** - deferred. Revisit only if Phase 197 leaves repeated, proven boilerplate that a narrow abstraction would remove without owning resource state.
- **Saved views, persisted lenses, user-defined queues** - new capability and out of Phase 197. Current default lenses and quick chips are enough.
- **Exact total-count API across every list** - deferred. Use honest visible counts unless a future phase needs exact query-wide totals and can pay the query/scoping cost.
- **Full browser matrix for all eight pages** - Phase 200. Phase 197 proves propagation with all-page smoke plus representative deep coverage.
- **Storybook completeness for every family/group** - Phase 200.
- **Cross-cutting overlay/theme/fixture-stress/microcopy sweep** - Phase 199/200 ownership.
- **`accrue_portal` white-label billing portal design-system pass** - future portal milestone, explicitly not part of admin LIST propagation.

### Reviewed Todos (not folded)

- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) - reviewed and deferred because Phase 197 is `accrue_admin` operator UI only. It remains valid future `accrue_portal` work.

</deferred>

---

*Phase: 197-propagate-list*
*Context gathered: 2026-06-27*
