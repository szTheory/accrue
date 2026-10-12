---
phase: "246"
slug: "collection-controls-and-search"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-11"
---

# Phase 246 — UI Design Contract

> Operate-mode contract for improving Accrue Admin's existing collection controls, global billing search, and shared table reading. Preserve the current Accrue identity and host/query boundaries. Implement at shared component and predicate owners; do not add a dependency, new visual system, billing capability, or Phase 247 detail/timestamp semantics.

## Design System

| Property | Value |
|----------|-------|
| Tool | Accrue Admin in-repository design system; no shadcn |
| Preset | Not applicable |
| Component library | Custom Phoenix LiveView function components in `accrue_admin/lib/accrue_admin/components/` |
| Icon library | Existing inline Heroicons via `AccrueAdmin.Components.Icon` |
| Font | Self-hosted Geist and Geist Mono, with current system fallbacks |

Use existing `DataTable`, `FilterChipBar`, `PageHeader`, `Select`, `Radio`, `Checkbox`, `EmptyState`, `GlobalSearch`, `InlineId`, `StatusBadge`, and `Icon` owners as appropriate. Preserve existing semantic tokens in `accrue_admin/assets/css/theme.css` and component styles in `app.css`. Do not create a page-local visual language or change token values for this phase.

## Component Inventory

Enumerated by `rg --files accrue_admin/lib/accrue_admin/components -g '*.ex' | sort | wc -l` — 43 component source files — `accrue_admin@1.6.0` (in-repository Phoenix UI; version from `accrue_admin/mix.exs`) — 2026-10-11. This sample is non-exhaustive, not a closed allowlist; inspect the source inventory for other suitable components.

| Component | Import path | Notes |
|-----------|-------------|-------|
| DataTable | `AccrueAdmin.Components.DataTable` | Shared toolbar, responsive table/card rendering, counts, loading and empty states |
| FilterChipBar | `AccrueAdmin.Components.FilterChipBar` | Applied constraints, remove-one actions and one reset-all action |
| PageHeader | `AccrueAdmin.Components.PageHeader` | Stable destination identity and page-level actions |
| Select / Checkbox / Radio | `AccrueAdmin.Components.Select`, `AccrueAdmin.Components.Checkbox`, `AccrueAdmin.Components.Radio` | Native categorical controls, true multi-status selection and small mutually exclusive views |
| GlobalSearch | `AccrueAdmin.Components.GlobalSearch` | Shared customers/invoices/subscriptions search dialog and async state |
| InlineId | `AccrueAdmin.Components.InlineId` | Exact secondary identifiers with existing copy affordance |
| EmptyState | `AccrueAdmin.Components.EmptyState` | Shared title, supporting copy and recovery action grouping |
| StatusBadge | `AccrueAdmin.Components.StatusBadge` | Concise evidence-backed status presentation |
| Icon | `AccrueAdmin.Components.Icon` | Existing inline Heroicons and named icon treatment |

## Spacing Scale

Use the established 4px-based scale and the existing CSS tokens. This contract declares four common layout steps; larger tokens remain available for major page sections.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps and tight inline separation |
| sm | 8px | Compact control gaps, chip gaps, field label spacing |
| md | 16px | Toolbar padding, control groups, table cell grouping |
| lg | 24px | Separation between page identity, collection region and results |
| xl | 32px | Major section/layout gap where the existing page uses it |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Major page-level separation |

Exceptions: none. Do not add new sub-4px values or use the legacy 2px dense-table token to create new geometry. Interactive icon targets, including chip removal, are at least 44×44px even when the visible glyph is 16px.

## Typography

Use Geist for interface text and Geist Mono for exact processor/technical identifiers. These four roles and two weights are the declared contract; map them to the existing tokens.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px (`--ax-type-md`) | 400 | 1.4 |
| Label/control | 14px (`--ax-type-sm`) | 600 | 1.4 |
| Heading | 28px (`--ax-type-2xl`) | 600 | 1.2 |
| Display | 36px (`--ax-type-3xl`) | 600 | 1.2 |

Use the 14px label role for compact controls and secondary identifiers. Keep exact IDs visually secondary with mono styling, while retaining their full readable/copyable value. Do not add new tiny type or promote IDs to the same weight/size as record names. Long-form supporting copy uses the existing 1.5 line-height role.

## Color

The 60/30/10 ratio is a qualitative surface guide. Retain the current light and dark token assignments; do not hard-code a new phase palette.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `--ax-base` / Paper `#fafbfc`; dark `#0f1318` | Page canvas and primary reading surface |
| Secondary (30%) | Light `--ax-elevated` `#ffffff` and `--ax-sunken` `#f1f5f8`; dark `--ax-elevated` `#171d24` and `--ax-sunken` `#0b1015` | Navigation, control surfaces, table/card surfaces and subdued regions |
| Accent (10%) | Existing `--ax-accent` / Cobalt `#5d79f6`, through theme-aware accent tokens | Selected view/filter, primary action, links and visible focus treatment only |
| Destructive | Existing `--ax-danger` and readable/surface variants | Destructive actions or evidence-supported danger state only; no new destructive action is introduced |

Accent reserved for: selected view and applied-filter states, primary action, links, and visible keyboard focus. Hover remains a neutral transient cue. Focus styling must not look like a second selected value. Keep status colors attached to named, supported states; never use color alone to express selection, loading, error, or billing truth.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Search billing` (global search trigger; describe the supported customer, invoice and subscription destinations) |
| Empty state heading | Filtered zero: `No billing records match these filters`. First-run default: `Nothing in this list yet`; retain a truthful page-specific `Copy.*_list_first_run_empty_title/0` where defined |
| Empty state body | Filtered zero: `Clear or adjust the filters above to inspect matching billing records.` First-run default: `Billing records appear here when they match this view. If you expected rows, check filters or organization scope.` Retain the matching page-specific `Copy.*_list_first_run_empty_body/0` where defined; show a recovery action only when that page supports it |
| Error state | `Results couldn't be loaded. Try again.` Keep retry scoped to the failed collection/search group and preserve successful groups and current owner/query scope |
| Destructive confirmation | None. Removing a constraint and resetting filters are reversible, immediate actions and do not require confirmation |

Show only search capabilities the owning query implements. General `q` predicates remain:

| Collection | General search (`q`) actually matches | Separate exact criteria stay explicitly named |
|------------|--------------------------------------|------------------------------------------|
| Customers | Email, name, owner ID, processor ID | Account type and payment-method presence |
| Payments/charges | Processor ID, customer email, customer name | Customer ID and fee-settled state |
| Invoices | Invoice number, processor ID, customer email, customer name | Customer ID and collection method |
| Subscriptions | Customer email, customer name, subscription processor ID | Customer ID |
| Coupons | Coupon name and processor ID | Validity |
| Promotion codes | Code, processor ID, associated coupon name | Exact associated local coupon ID |
| Events | Type, subject ID, actor ID | Exact event type, actor type, subject type, source webhook event ID |
| Connect accounts | Stripe account ID, email, owner ID | Host/runtime account type, charges/payouts enabled, details submitted, deauthorization, attention view |

Use category-specific field labels/placeholders that describe only those predicates. Keep exact relationship criteria in a secondary `Filters` disclosure with precise names; preserve custom host account types and unknown/historical event keys. Do not turn finite examples into a restrictive enum when the source is extensible.

## Interaction and Layout Contract

- Keep the destination heading and page identity above one shared collection region. On wide layouts, keep the selected view, general search, and labeled primary criteria together; place less-used exact criteria in an explicit `Filters` disclosure. Use compact native selects for categorical criteria, including the distinct Connect enabled fields. Use checkboxes for invoice/subscription status combinations (OR within status; AND across different criteria); reserve segmented radios for genuinely small mutually exclusive view choices.
- Place actual applied-filter chips and an accurate result count immediately above the results. Each constraint chip has a 44×44px removal target with an explicit accessible name such as `Remove Status Open filter`; provide one predictable `Clear filters` reset. View/navigation links are not chips. Clear-one and clear-all preserve owner scope, search, view state where applicable, and unrelated constraints.
- Selected control, canonical URL, server query, chips, count and rendered rows describe the same state. No focused outline is a second selection. Invoice defaults remain Open + Uncollectible; subscription defaults remain Past due + Canceling. Counts distinguish matching/filtered total, current page, and all-results total only when the query actually provides each fact; never infer a total from visible cursor-paginated rows.
- On screens below the existing 768px breakpoint, stack search and primary controls in the task order, keep labels visible, allow chip wrapping, and use the existing responsive card-table mode. Do not force horizontal page overflow. At 320px wide, each primary control remains operable without overlapping the result count or reset action. Use existing breakpoints, not new breakpoint tokens.
- Keep the global-search trigger to one compact line and one keyboard shortcut hint. The dialog opens with the input focused, concise orientation text, balanced padding, readable Customers / Invoices / Subscriptions result groups, and a subordinate keyboard-help footer. Remove internal language such as “scoped list.”
- One `activeIndex` governs visual highlight, `aria-activedescendant`/active announcement, pointer movement, keyboard movement and Enter activation. Keep input focus during result navigation; pointer hover updates the same active result and cannot leave a second item visually selected. Escape closes; focus returns to the invoking control; focus remains contained while the dialog is open.
- Loading appears only while a current request is pending. Use the existing spinner with an explicit size modifier and a meaningful live `role=status` label; the served CSS must make `[hidden]` win. Retain reduced-motion support. On partial failure, keep successful groups visible and expose retry beside each failed group. Discard stale query/owner generations without presenting them as current.
- In shared table identity cells, put the human-readable name/code on the primary line and the exact ID on a separate secondary line. Apply `min-width: 0` and wrapping to the identity child so long/unbroken values cannot push status, amount, and date columns away. Preserve the complete exact ID and existing copy affordance; do not widen an entire table column or allow giant mobile cards.
- Order collection information for investigation: recognizable record/customer, meaningful current state, money, then relevant timing. Put technical, ownership and tax details in clearly labeled lower-priority fields. Use concise status pills; do not place compound explanatory sentences in pills or invent fee/plan/timestamp semantics deferred to Phase 247. Shared `DataTable` and `EmptyState` fixes must reach representative consumers, not be replaced by page-local spacing patches.
- Preserve native labels, keyboard order, visible focus, accessible names, non-color state cues, reduced motion and touch access. Search and reset behavior must remain scoped to the current owner and authorized host context.

## UI Considerations

Post-check deterministic UI probe: E1 collection form/list/navigation, E2 global search form/list/control, E3 table/card list/content/control. Authored kind overrides include all relevant kinds. The engine raised 24 applicable rows (eight categories for each surface), zero unclassified. Every row maps to the category-specific criteria below; long-text rows retain the explicit held-out rendered backstop. No row is silently dismissed. The planner must carry and wire these checks for each applicable surface.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Collection list, global search result groups | ✅ covered | Filtered zero uses the filtered copy above; first-run uses `Nothing in this list yet` plus its body above unless a truthful page-specific pair exists. Global search no-match says `No billing records match "{query}". Adjust the search or open the customers list.` |
| loading | Collection list, global search, search result group | ✅ covered | Use existing table skeleton for list load; show a sized spinner and live status only for a current pending search; preserve completed groups during partial search loading/failure. |
| error | Collection list, global search, result group | ✅ covered | State the load failure and offer retry in the affected scope; stale owner/query responses do not replace current results. |
| populated | Collection table/card, search result groups | ✅ covered | Identity, state, money and timing remain in scan order; exact identifier remains available on its secondary line and copyable. |
| partial | Collection table, search result groups | ✅ covered | Preserve readable rows and successful groups when one data source fails; label incomplete/unavailable data rather than implying zero or success. |
| overflow | Collection identity cells, applied-filter row, responsive table | ✅ covered | Wrap long/unbroken names and IDs inside identity children; chips wrap; narrow layouts use existing cards and preserve essential state/money access. |
| zero-one-many | Collection count and rows, search groups | ✅ covered | Use singular/plural counts accurately; show a coherent one-row layout; many rows preserve current pagination/cursor truth and never imply the visible page is the total. |
| long-text | Search input, filter values, primary/secondary table identity | 🧪 backstop | Held-out long-name, long-email and unbroken-ID layouts reflow within wide and 320px narrow viewports while exact values remain accessible and copyable. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Not applicable | None | No shadcn or third-party registry; existing in-repository Phoenix components only |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-11; independent checker passed 7/7 after one copy-only correction.
