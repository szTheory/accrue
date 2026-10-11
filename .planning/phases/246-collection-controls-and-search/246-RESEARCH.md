# Phase 246: Collection Controls and Search - Research

**Researched:** 2026-10-11  
**Domain:** Accrue Admin collection filters, LiveView URL/query state, global search, responsive tables  
**Confidence:** HIGH (bounded source and owner-evidence research)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep stable page identity above a compact shared collection region: view choice, general search and labeled primary criteria; secondary criteria may use an explicit Filters disclosure. Applied constraints and result count sit close to results. Remove the large duplicate Filters card and repeated resets. View/navigation links are not active filter chips.
- **D-02:** Use compact native selects for multiple categorical dimensions (especially Connect charges, payouts, account type, details and authorization). Visible labels distinguish similar All/Enabled/Disabled choices. Reserve segmented radios for genuinely small mutually exclusive choices; avoid five wrapping segmented groups.
- **D-03:** Genuine active chips have an X removal affordance with explicit accessible name, keyboard focus and touch target. Keep one predictable reset-all action. Clear/remove preserve owner scope and unrelated constraints. Distinguish all-results count, current filtered count and paginated visible count; do not fabricate totals.
- **D-04:** Existing multi-status invoice/subscription queues need a shared labeled checkbox selection pattern representing combinations rather than showing All. Within status use OR, across criteria AND. Controls, canonical URL, query, selected chips and rows agree. Default queues, All, direct URL, remove-one and back/forward must be tested together.
- **D-05:** Correct Coupons All/Valid disagreement and other selected-versus-focused styles at their owning state logic. A focus outline must not appear as a second selection. Preserve search and organization scope during transitions.
- **D-06:** A single general search advertises only actual predicates. Do not silently broaden backend matching or drop exact relationship filters to make the toolbar simpler. Place distinct exact Customer/Coupon/Source webhook criteria in secondary filters, named precisely; consolidate only truly equivalent entry points. Preserve host-defined account types and unknown event keys. Prefer native selects or existing suggestions for finite categories; do not replace unbounded/custom values with incomplete hard-coded enums.
- **D-07:** Replace the nested, two-line lookup trigger with one compact search affordance reflecting customers/invoices/subscriptions and its shortcut. Give the dialog concise orientation, balanced padding, compact readable result groups and a subordinate keyboard footer. Remove internal “scoped list” language and excessive initial guidance.
- **D-08:** One active result governs pointer, keyboard, ARIA and Enter activation. Pointer movement can update that active target; stationary hover must not produce a second selected style after keyboard movement. Preserve input focus, focus containment/return, async generation/owner checks, successful-group retention and retry semantics.
- **D-09:** Loading is visible only while a current request is pending; hidden must win in served CSS. Use a deliberately sized existing spinner with reduced-motion support and a meaningful accessible loading state. No dependency is needed.
- **D-10:** Separate primary readable identity from secondary exact identifier through shared cell layout. Prevent concatenation and long unbroken content from displacing status, money and dates. Full identifiers remain accessible and copyable; use existing copy infrastructure where available. Avoid giant rows, arbitrary wide identity columns and crowded edges.
- **D-11:** Order columns by the actual investigation task: recognizable record/customer, significant state, money, relevant timing; secondary ownership/tax/technical facts get explicit labels and suitable priority. Preserve data semantics rather than inventing fee/plan status; Phase 247 owns those semantic corrections. State pills remain concise and restrained, and compound state descriptions do not become paragraphs in pills.
- **D-12:** Fix shared empty-state title/body/action grouping and common spacing at the shared owner. Maintain recovery actions and truthful distinctions between filtered zero, absent records and unavailable reads. Shared fixes must apply to representative consumers plus explicit exceptions; avoid page-local CSS repairs.
- **D-13:** Use existing components/tokens, query owners, LiveView/Node tests and mounted host/browser checks. No new dependency, redesign or migration. Establish a UI design contract before source changes. Use one batched rendered review, one corrective batch and one confirmation for a coherent slice; further iteration requires a named defect.
- **D-14:** Exercise URL/control/query/result agreement and actual mounted interactions, not handler-only or string assertions. Include narrow/wide, light/dark, long name/ID, keyboard/pointer and scope-preserving reset representatives. Bind rendered evidence to changed source and served assets. Keep Phase 245 baseline immutable; write new evidence separately. Optional DOM metadata must be read without waiting for absent elements; wait for LiveView connection before hook interactions.

### the agent's Discretion
Choose exact control layout, secondary-filter disclosure and sensible column widths using these rules and the existing Accrue identity. Auto-follow recommended choices. Stop only for a genuine new scope fork or external irreversible action. No repeat owner approval is needed.

### Deferred Ideas (OUT OF SCOPE)
Timestamp local-display/UTC-copy convention, global destination naming/breadcrumb changes, fee/history/plan evidence semantics, webhook replay/payload/disclosure hierarchy and recovery metrics: Phase 247. Scenario tooling and full owner finding/evidence reconciliation: Phase 248. No production scenario picker, new billing capability, Portal changes or remote tags.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FILTER-01 | Operators can distinguish page/view selection from applied constraints through one coherent shared filter region, visible field labels, compact removable chips and a predictable reset action. | `DataTable.filter_toolbar/1`, `FilterChipBar.filter_chip_bar/1`, page chip constructors, and shared navigation patch contract. |
| FILTER-02 | Operators can select useful combinations of statuses on existing multi-status journeys, with controls, URL, query and displayed results agreeing, including default invoice and subscription queues. | Invoice/subscription page defaults, status query reducers, LiveView filter tests and `DataTableNav.merge_query/2`. |
| FILTER-03 | Operators can use a general search whose stated capabilities match its predicates, with exact relationship filters discoverable and explicitly named instead of duplicate search-like fields. | Query predicate owners and field declarations across each collection; preserve exact relationship filters as separate criteria. |
| SEARCH-01 | Operators can open and use a compact global billing search dialog with one unambiguous active result across mouse and keyboard, truthful loading visibility and usable narrow/wide composition. | `GlobalSearch`, `CommandPalette`, existing component and Node hook tests, served CSS and mounted host. |
| TABLE-01 | Operators can scan primary identity, significant state, money and dates without concatenated names/IDs, excessive row height or long-content displacement; shared tables retain full exact identifiers and useful responsive priorities. | Shared `DataTable` desktop/card renderers, `InlineId`, consumers' row/column definitions and existing responsive styles. |
</phase_requirements>

## Summary

This phase is an internal Accrue Admin UI and interaction pass. Existing shared owners already provide the right seams: `DataTable` renders both the collection filter form and responsive table/card layouts; `FilterChipBar` renders applied chips/count/reset; page LiveViews own parameter decoding, URL patching, filter field definitions and record-specific identity/columns; query modules define actual predicates. Keep the current design system and public query semantics. Fix composition and truthful representation at these owners, then prove mounted URL-to-query-to-result behavior on representative consumers.

The phase's concrete risks are behavioral as much as visual. Some visible filter controls currently do not represent combinations (invoice/subscription status is a single select despite comma-aware query support); `FilterChipBar` treats an item as active by default and conflates navigation links with constraints unless callers provide explicit flags; the toolbar visually hides field labels and preserves unsupported params as hidden inputs. Search helper copy currently overstates some predicates. The search hook already centralizes `activeIndex`, pointer movement, keyboard activation, focus handling and async list updates; preserve these contracts while correcting the CSS hover/active double highlight and idle spinner sizing/visibility.

**Primary recommendation:** Keep criteria and URL semantics in their existing LiveView/query owners, centralize presentation in `DataTable` and `FilterChipBar`, and add mounted interaction coverage that asserts URL, selected controls, count, and returned rows together. No new packages are needed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Collection filter layout and responsive table rendering | Frontend Server (SSR) | Browser / Client | `DataTable` HEEx renders controls and table/cards; CSS controls responsive geometry. |
| Applied filter state, canonical URLs and collection query | API / Backend | Frontend Server (SSR) | LiveViews normalize params and patch URLs; per-page Queries implement predicates; `DataTableNav` merges current query scope. |
| Global search lookup and grouping | API / Backend | Frontend Server (SSR) | `GlobalSearch` async tasks call the existing scoped query modules and render grouped results. |
| Global search active row, keyboard/pointer/focus behavior | Browser / Client | Frontend Server (SSR) | `CommandPalette` hook tracks active index and invokes existing LiveView events/path navigation. |
| Table identity and column priorities | Frontend Server (SSR) | Browser / Client | Consumer row renderers supply facts; shared DataTable CSS and card fields control scan order at breakpoints. |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists in the repository root or discovered project files. `CLAUDE.md` is present; its project stack and admin guidance agree with this phase's locked scope. There are no project `.agents/skills` or `.codex/skills` files to load. Follow CONTEXT.md and existing admin test/component conventions; do not add deps, production scenario UI, Portal work, or billing/query capability.

## Standard Stack

### Core

| Library / owner | Version | Purpose | Why standard |
|-----------------|---------|---------|--------------|
| Elixir / Phoenix LiveView | Existing project constraints Elixir `~> 1.19`, LiveView `~> 1.1` | Collection state, rendering and URL-patched interactions | Already used by every scoped list. See `accrue_admin/mix.exs:4-14,36-45` [VERIFIED: accrue_admin/mix.exs:4-14,36-45]. |
| Browser hook and CSS | Existing `assets/js/hooks/command_palette.js`, `assets/css/app.css` | Search keyboard/pointer behavior and responsive selection/loading styles | Existing hook owns active result and focus lifecycle; no package needed [VERIFIED: accrue_admin/assets/js/hooks/command_palette.js:1-244]. |
| Existing query modules | `AccrueAdmin.Queries.*` | Search and collection predicates | These are the semantic source of truth; page field copy must match them [VERIFIED: accrue_admin/lib/accrue_admin/queries/:101-235]. |

### Supporting

| Owner | Purpose | Use |
|-------|---------|-----|
| `AccrueAdmin.DataTableNav` | Merge filter params into existing path query and patch | Preserve org scope and other existing URL params on edit/reset [VERIFIED: accrue_admin/lib/accrue_admin/data_table_nav.ex:1-64]. |
| `AccrueAdmin.Components.InlineId` and copy components | Render exact identifiers/copy affordances | Use in identity secondary line where current row helpers permit; preserve full value. |
| Existing LiveView and Node tests | Exercise HEEx, query transitions and JS hook behavior | Extend owning tests rather than adding a new lane [VERIFIED: accrue_admin/test/accrue_admin/components/data_table_test.exs:347-859; accrue_admin/test/js/command_palette_test.mjs]. |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Existing native filter controls | New select/multiselect dependency | Adds package/accessibility/styling surface without need; locked decision is native selects and labeled checkbox status selection. |
| Existing URL/query behavior | Broaden search predicates to collapse exact relationship fields | Changes observable data semantics and can make exact scope ambiguous; explicitly excluded by D-06. |

**Installation:** None. This phase adds no external package.

## Architecture Patterns

### Existing ownership path

```text
Operator control change
  -> DataTable filter form (`phx-change="data_table_filter"`)
  -> owning page LiveView normalizes params and calls DataTableNav.merge_query/2
  -> push_patch / handle_params
  -> page's AccrueAdmin.Queries module applies predicates under owner scope
  -> DataTable renders rows, state, counts and applied chips from normalized assigns

Global search input
  -> GlobalSearch async lookup with current query + owner scope + generation
  -> grouped customers / invoices / subscriptions results
  -> CommandPalette hook shares one activeIndex across pointer, arrows, ARIA status and Enter
  -> scoped record path
```

### Source-of-truth map

| Concern | Primary owner | Existing test owner |
|---------|---------------|---------------------|
| Shared filter controls, hidden unsupported fields, table/card rendering, empty/loading state | `accrue_admin/lib/accrue_admin/components/data_table.ex` | `accrue_admin/test/accrue_admin/components/data_table_test.exs` |
| Chip activity, labels, remove/reset URLs and count | `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs` |
| Filter URL merge and preservation of unrelated query values | `accrue_admin/lib/accrue_admin/data_table_nav.ex` | `accrue_admin/test/accrue_admin/data_table_nav_test.exs` |
| Search trigger/dialog, async group results and active-result ARIA | `accrue_admin/lib/accrue_admin/components/global_search.ex` | `accrue_admin/test/accrue_admin/components/global_search_test.exs` |
| Active index, keyboard/pointer arbitration, focus lifecycle | `accrue_admin/assets/js/hooks/command_palette.js` | `accrue_admin/test/js/command_palette_test.mjs` |
| Hover/active and spinner served styling | `accrue_admin/assets/css/app.css` | browser tests + `mix accrue_admin.assets.build` output check |
| Page criteria, defaults, URL handling and row ordering | `accrue_admin/lib/accrue_admin/live/{charges,invoices,subscriptions,coupons,promotion_codes,events,connect_accounts,customers}_live.ex` | Matching `test/accrue_admin/live/*_live_test.exs` |
| Search/status/exact relationship predicates | `accrue_admin/lib/accrue_admin/queries/*.ex` | Query/live tests adjacent to the page owners |

### Filter state and control pattern

Treat a view preset as route/task selection and active chips as actual URL constraints. Current shared chip renderer selects active items with `Map.get(item, :active, true)` and renders `:href` as an activation link only when there is no `:remove_href`; callers therefore need to explicitly model view links separately and mark actual criteria. It currently labels removal action “Clear”; phase intent requires an X control with an explicit accessible name. The toolbar currently sets each filter label class to `ax-visually-hidden`, and copies params not declared in `filter_fields` into hidden inputs [VERIFIED: accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex:20-110; accrue_admin/lib/accrue_admin/components/data_table.ex:580-643].

URL edits should flow through the existing parent-targeted DataTable form and `DataTableNav.merge_query/2`. That function decodes the path's existing query, merges submitted params, rejects blanks, and emits one encoded query, which is the scope-preservation seam; reset/remove actions should reuse it or equivalent page-owned paths instead of constructing URLs by string concatenation [VERIFIED: accrue_admin/lib/accrue_admin/data_table_nav.ex:19-64].

For status sets, encode selected status values in the existing comma-delimited `status` parameter. The query implementations apply OR within that set, while `Enum.reduce` applies each separate filter key successively (AND). Existing defaults are invoice `"open,uncollectible"` and subscription `"past_due,canceling"` [VERIFIED: accrue_admin/lib/accrue_admin/live/invoices_live.ex:25,327-343; accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:27,457-479; accrue_admin/lib/accrue_admin/queries/invoices.ex:109-160; accrue_admin/lib/accrue_admin/queries/subscriptions.ex:146-237]. Selection rendering and canonical serialization must preserve these defaults, All/view sentinel behavior, unknown handling and direct URLs.

### Query predicate contract to preserve

Do not use placeholders as a source for search claims. Current general `q` predicates are:

| Collection | General `q` matches (current source) | Keep exact as a distinct constraint |
|------------|--------------------------------------|------------------------------------|
| Customers | email, name, owner ID, processor ID | owner type and payment-method presence |
| Payments/charges | processor ID, customer email, customer name | customer ID, fee-settled state |
| Invoices | invoice number, processor ID, customer email, customer name | customer ID, collection method |
| Subscriptions | customer email, customer name, subscription processor ID | customer ID. Existing field placeholder currently claims customer ID/actor too; correct copy to predicate truth, do not change query to match it. |
| Coupons | coupon name, processor ID | validity |
| Promotion codes | code, processor ID, associated coupon name | exact associated local coupon ID |
| Events | type, subject ID, actor ID | exact type, actor type, subject type, source webhook event ID |
| Connect accounts | Stripe account ID, email, owner ID | account type, charges/payouts enabled, details submitted, deauthorization, attention view |

Evidence: `Queries.Customers.filter_query/2` `:107-130`; `Charges.filter_query/2` `:101-129`; `Invoices.filter_query/2` `:109-137`; `Subscriptions.filter_query/2` `:146-168`; `Coupons.filter_query/2` `:71-88`; `PromotionCodes.filter_query/2` `:73-93`; `Events.filter_query/2` `:174-202`; `ConnectAccounts.filter_query/2` `:102-143` [VERIFIED: those source paths/line ranges].

Events' `type` predicate is exact equality, but event keys are extensible/custom: use an input with suggestions if helpful without excluding unknown/historical keys. Connect account type options are host/runtime-derived; preserve them. Use exact relationship criteria in a secondary region with explicit field names rather than folding them into fuzzy `q`.

### Global search active-result pattern

`CommandPalette` already binds pointer movement to `activeIndex`, applies/removes `.ax-active`, updates the live status, handles arrows/Enter, and maintains focus trap/return. CSS separately defines `.ax-command-palette-item:hover` and `.ax-command-palette-item.ax-active`; align hover presentation so it cannot suggest a second selected item when keyboard active is elsewhere. Keep the input focused as the operator navigates. Preserve `GlobalSearch` generation/owner/query checks, partial successful groups and per-group retry behavior; current tests assert those contracts [VERIFIED: accrue_admin/assets/js/hooks/command_palette.js:1-244; accrue_admin/assets/css/app.css:4312-4322; accrue_admin/test/accrue_admin/components/global_search_test.exs:172-220,296-381].

The rendered spinner is `<span id="search-spinner" class="ax-spinner" hidden={not @loading}>`; the base `.ax-spinner` has `display:inline-block` and size only comes from `ax-spinner-sm/md/lg`. Inspect browser-computed style of the built/served CSS: author display can override the HTML hidden behavior. Add an existing size modifier, and ensure `[hidden]` wins in actual served CSS; keep reduced-motion rule and the current role=status “Searching billing records…” [VERIFIED: global_search.ex:278-314; app.css:4342-4350].

### Table identity and responsive pattern

`DataTable` owns a desktop semantic table and a card list for narrow viewports. Keep the row's recognizable primary name/code separate from an exact secondary identifier, with min-width/overflow wrapping applied to the identity child, not by widening the whole column. Preserve exact IDs and existing `InlineId` copy behavior. Use meaningful `card_fields` and existing desktop/card column priorities; do not duplicate timestamp/fee/plan semantics that are deferred to Phase 247 [VERIFIED: data_table.ex:484-547; app.css:3413-3589,3778-3810].

Use existing consumer row helpers as the data-preserving seam: `CustomersLive.customer_link/4`, `PromotionCodesLive.promotion_code_link/3`, and invoice/subscription/event equivalents. Phase 245 F01 records the rendered collision across those consumers and marks the shared identity treatment for this phase; Phase 245's baseline artifacts remain immutable. Current baseline only supports rendered identity/filter-composition observations; it does not prove filter transitions, mobile interaction or all route states [CITED: .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md; .planning/phases/245-rendered-baseline-and-realistic-preview/245-UI-REVIEW.md].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL query merge with owner scope | Ad hoc concatenation or hand-built per-filter URLs | `DataTableNav.merge_query/2` / existing page patch paths | Existing query may already include `org`; merge avoids double `?`, preserves unrelated params and drops blanks. |
| Result query semantics | New UI-only search interpretation or fuzzy relationship search | Existing `AccrueAdmin.Queries.*` predicates | Keeps displayed claims aligned with actual database behavior and owner scope. |
| Keyboard/pointer result state | Separate hover selection state or new palette library | `CommandPalette.activeIndex` | One index already drives keyboard movement, active class and ARIA status. |
| Responsive table abstraction | New table package or page-local CSS overrides | `DataTable` desktop/card modes and shared CSS | Reuses responsive accessibility and current column/card contract. |
| Loading indicator | New spinner dependency or CSS animation | Existing `.ax-spinner` modifiers and reduced-motion rule | Existing tokenized spinner exists; fix its size and hidden precedence. |

## Common Pitfalls

### Treating view presets as active filter chips
**What goes wrong:** Navigation choices such as “Needs attention” or “All accounts” appear as removable constraints and can be mistaken for query state.  
**Why:** Chip bar defaults `active` to true; page callers may model view links and filter values together.  
**How to avoid:** Give views their own selected-state control, enumerate only actual criteria as chips, and verify deep-link/back-forward behavior on Connect, Coupons, Payments and Promotion codes.  
**Warning signs:** More than one selected state for All/Valid, route tabs rendered in the filter chip region, or resetting scope accidentally switches the chosen view.

### Using a single-select widget for an existing status set
**What goes wrong:** Operators cannot represent the default invoice/subscription queues as selections and displayed chips diverge from serialized status.  
**Why:** Page fields currently declare `type: :select` though query handlers accept comma-separated status values.  
**How to avoid:** Shared labeled checkbox group, OR inside status selection, AND across other keys; test exact default strings `"open,uncollectible"` and `"past_due,canceling"` and direct URL transitions.  
**Warning signs:** A click on one status drops the other default member; an All item remains visually selected alongside explicit states.

### Broadening search to simplify controls
**What goes wrong:** An exact relationship filter silently becomes fuzzy or a query starts matching fields it did not before.  
**Why:** Search labels/placeholders are treated as if they defined behavior.  
**How to avoid:** Document `q` from query clauses above; change only labels/control placement in this phase and retain exact `customer_id`, `coupon_id`, and `source_webhook_event_id` criteria.  
**Warning signs:** Tests assert placeholder text but never prove result predicates; custom event types disappear from a finite option list.

### Recreating the simultaneous hover/keyboard highlight in CSS
**What goes wrong:** A hovered row and keyboard active row both read as selected.  
**Why:** `.ax-command-palette-item:hover` and `.ax-active` styles are separate while JS has one active target.  
**How to avoid:** Make hover a transient affordance that does not compete with keyboard active state; test pointer movement, subsequent keyboard movement and Enter activation on actual DOM.  
**Warning signs:** The visually highlighted item differs from the ARIA active-result announcement or Enter destination.

### Hidden state lost to spinner display rule
**What goes wrong:** Idle spinner remains visible at zero size or loading affordance appears after request completion.  
**Why:** Base spinner display rule conflicts with browser hidden styling and no size class is present in current markup.  
**How to avoid:** Inspect served computed style at idle and while a current request is pending, and include reduced-motion check.  
**Warning signs:** Source HTML has `hidden` but screenshot/accessibility tree still includes a tiny spinner.

### Solving long content with an oversized identity column
**What goes wrong:** Long names/IDs push status, amount and dates out of the scan path or make giant mobile rows.  
**Why:** Wrapping is applied to the table/card instead of separately sizing the primary and secondary identity lines.  
**How to avoid:** Shared identity line structure, min-width:0 and overflow-wrap on exact-value container; validate both desktop and narrow card mode with long names and unbroken IDs.  
**Warning signs:** Horizontal page overflow, rows materially taller than neighbors, truncated/unavailable exact ID.

### Counting only visible page rows as the filtered total
**What goes wrong:** Cursor-paginated views imply the current page size is the matching-result total.  
**Why:** `DataTable` knows visible rows, while query/cursor interfaces may expose a total or may not.  
**How to avoid:** Label only facts the existing query returns; differentiate total/filtered/current-page counts and omit unknown totals. Events currently use a bounded cursor and separate counts, so don't relabel 25 rows as the full filtered total.  
**Warning signs:** “Showing 25 events” without explaining current page when additional cursor exists.

## Code Examples

Verified existing URL merge path:

```elixir
DataTableNav.merge_query("/billing/customers?org=acme", %{"q" => "Ada"})
# Expected shape: one query string retaining `org` and adding `q`.
```

Source: `accrue_admin/lib/accrue_admin/data_table_nav.ex:29-44`. The exact example values are illustrative; source explicitly documents the `org=acme` preservation case at lines 8-17.

Status state contract (source values quoted verbatim): invoice default `@default_queue_status "open,uncollectible"` [VERIFIED: `accrue_admin/lib/accrue_admin/live/invoices_live.ex:25`]; subscription default `@default_queue_status "past_due,canceling"` [VERIFIED: `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:27`]. The query modules split these strings on commas and combine selected predicates with OR; other filter keys are reduced successively.

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json` (`workflow.nyquist_validation: true`) [VERIFIED: `.planning/config.json`, opened this session].

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / LiveView tests; Node built-in test runner for hook |
| Config file | `accrue_admin/test/test_helper.exs`; JS tests in `accrue_admin/test/js/` |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/global_search_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/customers_live_test.exs` |
| Hook test command | `cd accrue_admin && node --test test/js/command_palette_test.mjs` |
| Full package command | `cd accrue_admin && mix test --warnings-as-errors` |
| Asset command | `cd accrue_admin && mix accrue_admin.assets.build` |

Tests already exist at the component and all targeted live page owners. In particular, invoice LiveView tests cover default queue, `view=all`, clear preserving org, list state, columns and filter submission; subscription tests cover default past_due/canceling queue, clearing to all while preserving scope, list states, columns and URL patch; coupon/Connect tests are the proper owners for All/Valid and categorical transitions. Search component tests already check partial failure retention, retry, async generation/owner/query rejection, owner-scope change and advertised predicate text. Existing Node hook tests own active-index/focus behavior.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FILTER-01 | Labeled controls, correct view-versus-constraint representation, X remove-one and single reset preserve scope | LiveView + component | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/coupons_live_test.exs` | Yes; extend interaction assertions |
| FILTER-02 | Multi-status selection round-trips default/direct URLs and agrees with query/results; back/forward and clear-one/all | LiveView + mounted browser | Run the focused ExUnit set above; mounted host Playwright path should exercise real browser history | Partial; browser proof is required |
| FILTER-03 | General q labels reflect actual q predicates and exact relationship constraints remain discoverable | Query + LiveView | `cd accrue_admin && mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/customers_live_test.exs` | Yes; add predicate/render alignment where missing |
| SEARCH-01 | One visible active result, mouse/keyboard/Enter agreement, focus return, truthful spinner and narrow/wide dialog | Component + Node + mounted browser | `cd accrue_admin && mix test test/accrue_admin/components/global_search_test.exs && node --test test/js/command_palette_test.mjs` | Yes; mounted coverage needs the phase's host session |
| TABLE-01 | Separate readable identity/exact copyable ID, stable state/money/date visibility and narrow card layout | LiveView + mounted responsive browser | Focused page test files above plus current host browser tests | Yes for static rendering; mounted narrow/wide long-content coverage needed |

Mounted browser acceptance should use the existing ordinary Phase 245 host fixture and appropriate host Playwright config, await LiveView connection, and verify changed/served JS/CSS provenance. Write new captures/evidence under the Phase 246 evidence location; do not modify Phase 245 manifest, captures, findings, or review. No broad new CI lane is warranted. The existing CI package test command is `cd accrue_admin && mix test --warnings-as-errors` (`.github/workflows/ci.yml:683`); asset build and clean generated-static check are already in CI at lines 818-821.

## Environment Availability

No external package or new service is required. Existing build/test tools and host/browser availability were not probed in this bounded research pass; use repository CI commands and the existing Phase 245 ordinary host/browser setup as the execution source. `node`, Mix dependencies, Chromium and the preview host are therefore **not asserted available** on a particular runner; if absent locally, rely on CI or the repository's existing host setup rather than adding tooling or falling back to a new dependency.

## Security Domain

This phase must preserve existing collection owner scope and authorization. URL merge preservation is behavior-critical: page query paths may carry `org`; all filter edits, chip removal, reset, global search paths, async callbacks and history transitions must retain current owner scope according to their existing owner modules. Do not interpret a client filter or hidden field as authorization. Server query modules remain responsible for scoping and permitted fields. No auth or capability change is in scope.

Applicable controls: V2 Authentication and V4 Access Control apply through existing authenticated/scoped LiveViews; V5 Input Validation applies to URL parameters and search/filter values. Preserve bounded/allowlisted handling in invoice status filtering and existing handling of unknown subscription states; do not convert URL strings into unrestricted atoms. V3/V6 are not changed by this phase. Primary threat patterns are cross-owner data exposure through malformed query merge, unbounded/incorrect search semantics, and stale async search results leaking across query/owner changes; existing DataTableNav and GlobalSearch generation/scope checks mitigate these and must remain covered.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Phase 245 ordinary host and browser session will still be available to the executor for mounted testing. | Validation Architecture / Environment Availability | Browser acceptance may need to run through the established CI or host launcher instead of a locally running preview. |

## Open Questions

1. The exact Playwright spec/config that should own the Phase 246 mounted collection/search acceptance is not declared in phase context. Reuse the existing host suite/config that can mount authenticated Admin against the isolated Phase 245 ordinary data; create a narrowly named spec only if no current spec can cover these real interactions.
2. Counts differ by collection: some queries expose totals, while cursor-backed event paths can carry separate total/current-page/newer counts. Keep labels specific to values actually returned; no new aggregate count query should be added solely for visual symmetry.

## Sources

### Primary (HIGH confidence)

- `.planning/phases/246-collection-controls-and-search/246-CONTEXT.md` — locked interaction contracts, boundaries and named targets.
- `.planning/notes/2026-10-11-admin-owner-feedback.md` — concrete page-by-page owner evidence and predicate corrections.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md` and `245-UI-REVIEW.md` — accepted current-render observations and explicit unverified interaction limits. Baseline is cited only, not rewritten.
- Admin source owners cited inline above — read directly during this research session.
- `.planning/config.json`, `accrue_admin/mix.exs`, `.github/workflows/ci.yml` and existing component/live/Node test files — validation configuration and recurring owners.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — reused local source owners; no new external package.
- Architecture: HIGH — LiveView/queries/hook ownership read in source.
- Pitfalls: HIGH — grounded in the phase decisions and current source/test gaps; baseline interaction claims retain recorded limits.

**Research date:** 2026-10-11  
**Valid until:** 2026-11-10 (stable internal ownership; reassess if Admin components or query contracts change).
