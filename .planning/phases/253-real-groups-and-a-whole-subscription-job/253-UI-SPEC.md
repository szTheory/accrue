---
phase: "253"
slug: "real-groups-and-a-whole-subscription-job"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-27"
---

# Phase 253 — UI Design Contract

> Visual and interaction contract for the production-shared subscription collection, whole detail composition, and guarded subscription journey. This contract records source owners and intended presentation; it is not evidence that the phase is implemented or mounted behavior is verified.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — Accrue Admin design system |
| Preset | None |
| Component library | In-repo Phoenix function components and LiveComponents (HEEx); no shadcn |
| Icon library | `AccrueAdmin.Components.Icon`, inline Heroicons v2 |
| Font | Geist for UI text; Geist Mono for identifiers |

`brandbook/` and `accrue_admin/assets/css/theme.css` remain authoritative. Use Admin semantic tokens, retaining host accent overrides; do not hard-code colors in views or add a design system, package, dependency, page schema, or parallel story-only page. Route, scope, copy, action eligibility, and DataTable state/event owners remain production-owned.

## Surface Contract

### Collection — production `SubscriptionsLive.render/1` and `DataTable`

Keep the actual PageHeader group: Billing breadcrumb and Subscriptions title, route description, subscription summary stat strip, filter toolbar, and then the production DataTable group. The primary visual anchors are the **Subscriptions heading → filter toolbar → results**. Within results preserve the subscription view navigation, work-queue filter chips, visible result count, reset/clear behavior, row links, cursor/load-more affordance, and the existing table/card switch. Render through the retained `DataTable` LiveComponent (`id="subscriptions"`, production `Subscriptions` query, current owner scope, route path/params); no static table can stand in for it.

| Settled review state | Required visible composition |
|----------------------|-------------------------------|
| New-host first-run empty | Production empty heading/body, toolbar and summary remain in their source order; keep only the action supplied by the state owner. Do not fabricate a row. |
| Filtered empty | Production filtered-empty heading/body, active filter context, and clear/reset path remain available. |
| One row / multiple rows | Real subscription identity link, lifecycle state, plan and exact amount, renews/ends value, billing-owner signal, result count, and available view/filter controls. Do not hide an essential field on cards. |
| Page boundary | Real cursor boundary with current rows and the existing `Load more` action only when `next_cursor` exists; load-more appends rows and preserves query/scope ownership. |
| Loading | Source-supported `loading-skeleton` fixture with `Loading subscriptions.`; never use a story-authored spinner or claim a database read is in progress when only a settled fixture is rendered. |
| Initial read unavailable | Keep DataTable's `role="alert"`, `History unavailable`, its current `unavailable_copy` (`This history could not be loaded. Try again.`), and `Retry`. |
| Partial cursor read error | Keep existing rows, `role="alert"`, `Some results could not be loaded. The rows shown may be incomplete. Try again.`, and `Retry loading remaining rows`. |

Preserve DataTable state values `unavailable`, `loading-skeleton`, `populated`, `filtered-empty`, and `first-run-empty`; `first-run` and `filter` reasons stay distinct. Keep LiveComponent state/lifecycle, filtering and URL patch authority, scoped query, polling/reload behavior, cursor paging, and event targeting (`load-more` / `retry-read` use `phx-target={@myself}`). Do not wire those events to the parent LiveView or duplicate the state machine. Preserve the bounded existing recovery labels `Retry` and `Retry loading remaining rows` exactly as owned by current Copy/DataTable recovery behavior; do not relabel source-supported read failures in stories.

### Detail — production `SubscriptionLive.render/1` and `subscription_area/1`

Render the whole existing routed page in this order: AppShell; Billing breadcrumbs (scoped Subscriptions and customer links plus current subscription); context return link; shared summary card (customer/subscription title, lifecycle text, full copyable subscription ID); ordered summary facts; flash and truthful action-result status; existing action band; related resources; the existing `Subscription details` disclosure group (`Billing & items`, `Dunning & recovery`, activity timeline/events, and lazy `Raw JSON`); action drawer and applicable step-up modal. The primary detail visual anchors are **subscription title → lifecycle state → summary facts**, before supporting evidence and related resources. Preserve existing disclosure defaults and lazy loading. Keep `SubscriptionLive` as route/current-owner authority; share presentation through normal function-component attrs/slots only.

For `active`, `scheduled_cancellation`, and `incomplete_evidence`, display actual scenario/domain values and the current production fact order. A missing projection keeps the production `Unavailable` value and its caveat in source order; omit only genuinely optional rows/groups. Never invent a date, amount, provider capability, action, or empty subscription. Preserve lifecycle wording, exact money, full technical IDs, and current scoped destinations. The details screen remains a routed production composition; a story may render only its settled presentation.

### Guarded journey — mounted behavior contract

The mounted journey is a scoped real list link → scoped detail → supported `cancel_now` review → dismissal without dispatch → restaged review with applicable fresh step-up → truthful result → return to the originating list context. Keep the staged review copy from `Copy.subscription_confirm_workflow_message/2`, its exact subscription/customer/source identifiers, the existing `Confirm {action}` control, and `Back to subscription` dismissal. Confirmation must preserve production checks for current actor and owner scope, refreshed subscription/action eligibility, exact target and review fingerprint, and applicable step-up. Dismissal clears pending review and causes no dispatch or persisted change.

Result text and optional destination stay with current `SubscriptionLive` / `Copy` / domain outcome owners. Render the current result in its existing `role="status"` / polite live region; distinguish confirmed, pending, and failed work truthfully. A requested or pending operation is never presented as provider completion. Return via the validated `@return_path` / `@return_label` and `ScopedPath` owner so scope and original filters survive. Stories prove settled content only; persistence, dispatch count, audit, authority, dismissal, and provider outcomes require mounted automated evidence.

### Responsive and semantic contract

Check at **320 CSS px**, a **640px constrained content container**, both sides of the actual table/card breakpoint (**767px and 768px**), and **1280px**, in both light and dark themes. Render every collection state above and all three detail variations at 320px and 1280px in both themes. At 767/768px and 640px, cover populated collection/card-to-table transition, filtered empty, each detail variation, and the open review/result composition in both themes. At all widths keep customer/subscription identity, complete copyable ID, exact amount, lifecycle text, dates, result/caveat text, and currently eligible actions visible and usable. Text wraps as needed; no essential content is clipped, removed, color-only, or replaced to avoid page-level horizontal overflow. Preserve the existing DataTable CSS rule: cards below 768px, grid table from 768px. Check the table's own existing scroll boundary separately from page overflow.

Retain native/production semantics: page `h1`, section headings, facts as `dl`/`dt`/`dd`, status badges with text and decorative-only dots, links as anchors, actions as buttons, named view navigation, DataTable's own event targets, and existing named menu/group/menuitem structure. Keep visible keyboard focus and the result's polite status announcement. This phase preserves those owners; it does not claim Phase 254's broader accessibility audit.

## Component Inventory

Enumerated by `rg --files accrue_admin/lib/accrue_admin/components -g '*.ex' | wc -l` — 46 components — accrue_admin@1.7.0 — 2026-10-27.

Cross-check: `find accrue_admin/lib/accrue_admin/components -type f -name '*.ex' | wc -l` also returns 46. This is a non-exhaustive list of known-good local components, never an allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `PageHeader.page_header/1` | `AccrueAdmin.Components.PageHeader` | Production collection title, summary, and filter slots. |
| `StatStrip.stat_strip/1` | `AccrueAdmin.Components.StatStrip` | Existing subscription summary metrics. |
| `DataTable` | `AccrueAdmin.Components.DataTable` | Stateful list, loading/error/empty, row/card renderer, cursor and event target owner. |
| `FilterChipBar.filter_chip_bar/1` | `AccrueAdmin.Components.FilterChipBar` | Production work-queue chips and result count. |
| `Detail.summary_card/1`, `summary_list/1`, `detail_field_list/1` | `AccrueAdmin.Components.Detail` | Existing identity, ordered facts, and detail fields. |
| `StatusBadge.status_badge/1` | `AccrueAdmin.Components.StatusBadge` | Lifecycle text and production semantic tone. |
| `IdBadge.id_badge/1` | `AccrueAdmin.Components.IdBadge` | Full, copyable technical identifier. |
| `RelatedResources.related_resources/1` | `AccrueAdmin.Components.RelatedResources` | Existing scoped related-resource destinations. |
| `DropdownMenu.action_menu/1` | `AccrueAdmin.Components.DropdownMenu` | Available actions only, existing menu/group semantics. |
| `DetailDrawer.detail_drawer/1`; `StepUpAuthModal.step_up_auth_modal/1` | `AccrueAdmin.Components.DetailDrawer`; `AccrueAdmin.Components.StepUpAuthModal` | Existing review and step-up presentation owners. |

## Spacing Scale

Use existing `--ax-space-*` tokens in `accrue_admin/assets/css/theme.css` for new or adjusted layout spacing.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline/icon gaps |
| sm | 8px | Compact control and label gaps |
| md | 16px | Default row/card spacing |
| lg | 24px | Adjacent major areas |
| xl | 32px | Section separation |
| 2xl | 48px | Major page breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: the existing dense-table micro-gap token remains with its current component owner and is excluded from this phase's numeric layout scale; do not change or newly use it as a layout rung. No new touch-target or layout-spacing exception.

## Typography

Use the existing Geist roles and only these four size steps / two weights for this phase.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | Regular 400 | 1.4 |
| Label / dense table metadata | 12px | Semibold 600 | 1.4 |
| Compact value | 14px | Regular 400 | 1.4 |
| Page heading | 28px | Semibold 600 | 1.2 |

## Color

Keep the 60/30/10 balance through semantic tokens; listed values are current defaults and host brand overrides remain authoritative.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `--ax-base` (`#fafbfc`); dark `#0f1318` | Page and primary surfaces. |
| Secondary (30%) | Light `--ax-elevated` `#fff` / `--ax-sunken` `#f1f5f8`; dark `#171d24` / `#0b1015` | Cards, table/card rows, recessed regions. |
| Accent (10%) | `--ax-accent` via brandbook host token; default `#5d79f6` | Existing eligible primary subscription action, current selected view/filter affordances, text links, and visible keyboard focus. |
| Destructive | Light `--ax-danger-readable: #9b1c1c`; dark `#ffaaaa` | Existing destructive menu/review state only. |

Accent reserved for the existing eligible `Change plan` action, active view/filter state, scoped text links, and focus. Lifecycle/status uses the semantic badge palette, never accent alone; preserve text labels and existing dangerous-action treatment. Do not add color-only state.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Change plan` only when production eligibility exposes it; otherwise omit. Collection identity links and all action labels remain with their existing `Copy`/route owners. |
| First-run empty | Heading `No subscriptions yet.` Body `Subscriptions appear after a customer completes checkout.` Use current production owner. |
| Filtered empty | Heading `No subscriptions match these filters.` Body `Clear filters or adjust the search to see subscriptions.` Keep the existing clear/reset destination. |
| Queue empty when source state selects it | Preserve heading `Nothing at risk.` and body `No past-due or canceling subscriptions. View All to see every subscription.` with existing `View all subscriptions` action. |
| Error / recovery | DataTable owns exact unavailable and partial-read copy/actions in Surface Contract. Missing/unscoped detail follows existing owner-denied scoped route. Incomplete facts keep production unavailable/caveat copy. Action failures use existing flash/result copy; no story-local errors. |
| Destructive confirmation | `Cancel immediately`, `Comp this subscription`, and `Remove item` remain only where production eligibility puts them in `More actions` → `Danger zone`. Use staged `Copy.subscription_confirm_workflow_message/2`, fresh review checks, and applicable step-up; confirmation says `Confirm {action}` and dismissal says `Back to subscription`. |

## UI Considerations

The compiled UI probe raised 26 applicable states across four surfaces. Kind confirmation was performed under owner-delegated autonomous defaults: E1 form/nav/list/control; E2 static/list/nav/control; E3 form/control/static; E4 nav/control. The engine has validated 26 explicit acceptance specifications; this is planned coverage, not executed evidence. Machine report: `253-UI-PROBE.json`.

| ID | State | Status | Verification | Acceptance criterion |
|----|-------|--------|--------------|----------------------|
| E1 | empty | resolved | explicit | New-host and filtered-empty collection cases render their distinct production heading, recovery and active filter context without invented rows. |
| E1 | loading | resolved | explicit | The source-supported loading-skeleton collection renders Loading subscriptions. through the actual DataTable renderer; no story claims an active read. |
| E1 | error | resolved | explicit | Initial unavailable renders the production alert and Retry; cursor failure retains current rows and Retry loading remaining rows. |
| E1 | populated | resolved | explicit | One-row and multiple-row collection cases render actual identity links, exact available amounts, lifecycle text, result count and production controls. |
| E1 | partial | resolved | explicit | Incomplete row projections retain production unavailable values; partial cursor failure preserves loaded rows and a truthful incomplete-results alert. |
| E1 | overflow | resolved | explicit | Collection at the contract widths/themes has no page overflow or hidden essential content; existing table-local scroll and 767/768 card/table transition are asserted separately. |
| E1 | zero-one-many | resolved | explicit | Zero, one, multiple and page-boundary collection cases keep production count/copy; Load more appears only with next_cursor and appends scoped rows. |
| E1 | long-text | resolved | explicit | Long customer names, full subscription IDs and filter text remain readable with essential values and actions at 320px in both themes. |
| E2 | empty | resolved | explicit | Missing optional detail groups follow production omission rules; missing required projections remain explicit unavailable evidence without inventing facts. |
| E2 | loading | resolved | explicit | Whole-page lazy detail disclosure retains the production loading/settled presentation; static stories make no live-read claim. |
| E2 | error | resolved | explicit | Missing or inaccessible subscription uses the existing scoped denial destination in mounted tests; missing evidence within a real detail retains production caveats. |
| E2 | populated | resolved | explicit | Whole detail uses production areas in declared order with exact identity, lifecycle, summary, supporting evidence and eligible actions. |
| E2 | partial | resolved | explicit | Incomplete-evidence whole-detail variation keeps available facts plus production unavailable values and caveats in source order. |
| E2 | overflow | resolved | explicit | Whole detail content, related destinations and disclosure regions retain essential identity/money/state/actions without page overflow at every contracted width/theme. |
| E2 | zero-one-many | resolved | explicit | Supported empty, single and multiple related-resource/item collections use existing detail owners without fabricated rows or labels. |
| E2 | long-text | resolved | explicit | Long names, exact identifiers, timestamps and caveats wrap or use their existing scoped content boundary without hiding essential text. |
| E3 | empty | resolved | explicit | Review without a valid staged action does not dispatch; optional inputs and missing evidence use current production validation and copy. |
| E3 | loading | resolved | explicit | In-flight review/confirmation follows existing production availability and result state; static fixtures never claim actual dispatch. |
| E3 | error | resolved | explicit | Rejected authority, stale target, invalid step-up and failed action preserve existing recovery messages and produce no unauthorized dispatch. |
| E3 | partial | resolved | explicit | Review shows only actual available action evidence; a pending result stays pending and never invents provider completion. |
| E3 | overflow | resolved | explicit | Review drawer and step-up/result presentation at contracted widths/themes keep consequences, identity and confirm/dismiss controls available without page overflow. |
| E3 | long-text | resolved | explicit | Long review identifiers, consequences and recovery text remain readable and named controls remain reachable in both themes. |
| E4 | loading | resolved | explicit | Return navigation uses the current production anchor/LiveView behavior and arrives at the scoped list without a story-created loading state. |
| E4 | error | resolved | explicit | Invalid or external return origins use the existing safe scoped fallback; mounted tests assert actual destination. |
| E4 | overflow | resolved | explicit | Return navigation and label remain available at the contract widths/themes without page-level overflow. |
| E4 | long-text | resolved | explicit | Return labels and long originating query values preserve validated context without clipping the navigation affordance. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | Not applicable — shadcn is not initialized. |
| Third-party registries | none | None declared; no external blocks or dependencies are introduced. |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: accepted nonblocking FLAG — existing Copy-owned Retry retained; no change recommended
- [x] Dimension 2 Visuals: PASS — independent check 2026-10-27
- [x] Dimension 3 Color: PASS — independent check 2026-10-27
- [x] Dimension 4 Typography: PASS — independent check 2026-10-27
- [x] Dimension 5 Spacing: PASS — independent check 2026-10-27
- [x] Dimension 6 Registry Safety: PASS — independent check 2026-10-27
- [x] Dimension 7 Inventory Provenance: PASS — independent check 2026-10-27

**Approval:** approved by independent UI checker 2026-10-27: six PASS dimensions and one accepted nonblocking copy FLAG. UI probe specifications recorded afterward. No runtime/implementation verification claimed.
