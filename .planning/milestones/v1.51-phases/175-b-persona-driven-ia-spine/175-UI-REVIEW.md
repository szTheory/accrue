---
phase: 175
slug: b-persona-driven-ia-spine
review_type: ui-audit
audited: 2026-06-04
baseline: 175-UI-SPEC.md (approved)
screenshots: not captured (no Accrue dev server running on audit host; port 4000 returned 404 for /billing)
shadcn: not applicable (Elixir/Phoenix project)
registry_audit: skipped (no components.json)
---

# Phase 175 — UI Review

**Audited:** 2026-06-04
**Baseline:** 175-UI-SPEC.md (approved, status: approved)
**Screenshots:** not captured — no Accrue dev server running on audit host (port 3000 belongs to a different app; port 4000 /billing returned 404). Audit is code-only.

**Scope note:** This is an IA-spine reshape (nav tiering/badges, work-queue defaults, Customer-360 tab tiering, EventLive + bidirectional threading, visible search, compliance lens). Per-screen rubric uplift is Phase 176 (C); full screenshot/axe QA is Phase 179 (F). Per-screen polish is not penalized here; IA-spine contracts are the audit boundary.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Three contracted empty-state strings missing; "Charges" label not fully relabeled to "Payments" across customer_live; modal search placeholder diverges from spec |
| 2. Visuals | 3/4 | IA tiering delivered; "More ▾" dropdown missing position:absolute + wrapper/item CSS — will not overlay content correctly |
| 3. Color | 4/4 | All Phase 175 token-gap closures use color-mix token composition; no new literal hex/rgb; status badge coloring correct |
| 4. Typography | 3/4 | All Phase 175 additions use token references; four pre-existing 0.875rem literals in pre-existing v1.50 classes (anti-churn: not re-opened by this phase — noted only) |
| 5. Spacing | 4/4 | All new CSS spacing resolves from --ax-space-* tokens; no literal px/rem in Phase 175 additions |
| 6. Experience Design | 2/4 | "More ▾" menu lacks positioning CSS (layout-breaking), no search error state, no queue-aware empty states in DataTable, flash missing on EventLive not-found redirect |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **"More ▾" dropdown missing CSS positioning** — the menu currently renders in document flow (pushes tab strip height down, obscures nothing) because `.ax-tab-more-menu` has `z-index` but no `position: absolute`, and `.ax-tab-more-wrapper` has no `position: relative`. User task: Support can't switch to a recessed tab without the menu visually overlaying page content. Fix: add `position: relative` to `.ax-tab-more-wrapper` and `position: absolute; top: 100%; right: 0; min-width: 12rem` to `.ax-tab-more-menu` in `app.css`. Also add display/layout rules for `.ax-tab-more-item` (padding, hover state) — these classes are used in the template but have zero CSS rules.

2. **Work-queue empty states use generic copy instead of contracted strings** — when the persona work-queue filter is active and yields zero rows, DataTable renders the generic entity empty-state (`"No invoices for this organization yet"`, `"No charges for this organization yet"`, `"No subscriptions for this organization yet"`) instead of the UI-SPEC contracted strings. Finance Ops sees a confusing "no invoices yet" message when the queue is actually just clear. Fix: pass queue-context-aware `empty_title` and `empty_copy` based on whether the queue filter is active. Contracted strings: invoices → "Queue clear" / "No open or uncollectible invoices. View All to see every invoice."; subscriptions → "Nothing at risk" / "No past-due or canceling subscriptions. View All to see every subscription."; payments → "No failed payments" / "Nothing failed in this view. View All to see every payment."

3. **"Charges" label not fully relabeled to "Payments" in customer_live** — the Customer-360 tab correctly displays "Payments" via `tab_display_label("charges")`, but three other surfaces still say "Charges": (a) the KPI summary card `label="Charges"` at line 223, (b) the Detail.detail_section `title="Charges"` at line 318, and (c) the Related billing card `label: "Charges"` in `related_items/3` at line 540. Users see "Charges" in three places and "Payments" in the tab — inconsistent terminology within one screen. Fix: update all three to "Payments".

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

**WARNING: Work-queue empty states not implemented**

The UI-SPEC Copywriting Contract (lines 206–211) defines six contracted strings for the three work-queue empty states. The list LiveViews still delegate to generic copy functions:

- `invoices_live.ex:145-146` — `Copy.invoices_index_empty_title()` returns `"No invoices for this organization yet"` (invoice.ex:6), not `"Queue clear"`
- `subscriptions_live.ex:156-157` — `Copy.subscriptions_index_empty_title()` returns `"No subscriptions for this organization yet"` (copy.ex:407), not `"Nothing at risk"`
- `charges_live.ex:132-133` — `Copy.charges_index_empty_title()` returns `"No charges for this organization yet"` (copy.ex:413), not `"No failed payments"`

The empty state is shown when the filtered query returns zero rows. With a persona work-queue filter active, a Finance Ops user clearing a queue would see the generic "No [entity] for this organization yet" message — which reads as misconfiguration rather than task completion. The contracted empty states are the primary copywriting deliverable of IA-03.

**WARNING: "Charges" label not uniformly relabeled to "Payments" in customer_live**

Three surfaces inside `customer_live.ex` retain the old "Charges" label after the route was renamed:
- Line 223: `label="Charges"` in the KPI summary card (visible at the top of the Customer-360 page)
- Line 318: `title="Charges"` in `Detail.detail_section` (renders as the section heading on the charges tab)
- Line 540: `label: "Charges"` in `related_items/3` (renders in the Related billing card)

The tab label itself is correctly relabeled via `tab_display_label("charges") -> "Payments"` (line 621), creating inconsistency within a single screen. The nav leaf and route are correctly renamed.

**WARNING: Modal search placeholder diverges from spec**

`global_search.ex:135` — placeholder is `"Search customers, invoices, subscriptions..."` instead of the contracted `"Search customers, invoices… ⌘K"`. The topbar trigger and Home search field correctly use the spec string. The modal placeholder is a minor deviation since the modal itself is reached via the ⌘K hint, but it breaks string consistency.

**PASS items (Copywriting):**
- Four Home launcher verb relabels correct: "Look up a customer", "Clear the invoice queue", "Recover at-risk revenue", "Investigate an incident" — confirmed in `copy.ex:698–713` and `dashboard_live.ex:116–141`
- Topbar search trigger text: `"Search customers, invoices… ⌘K"` — correct (`topbar.ex:33`)
- Home search placeholder: `"Search customers, invoices… ⌘K"` — correct (`dashboard_live.ex:109`)
- Compliance lens chip label: `"By actor"` — correct (`events_live.ex:148`)
- Escape-hatch chip label: `"All"` — correct across all three work-queue screens
- Badge aria-labels: `"#{n} at-risk subscriptions"` (Recovery), `"#{n} webhooks need attention"` (Developer) — correct (`sidebar.ex:126-128`)
- GlobalSearch quick-link verb relabels all correct (`global_search.ex:153–163`)

---

### Pillar 2: Visuals (3/4)

**WARNING: "More ▾" dropdown positioning architecture incomplete**

`customer_live.ex:255-285` renders the tab overflow using three classes: `ax-tab-more-wrapper` (the relative-position anchor), `ax-tab-more-trigger` (the button), and `ax-tab-more-item` (the menu items). None of these three classes have any CSS rules in `app.css` or the compiled bundle. Only `ax-tab-more-menu` (the `<ul>`) has rules — and those rules include `z-index: var(--ax-z-popover)` but no `position: absolute`.

Without `position: absolute` on the menu and `position: relative` on the wrapper, the `<ul>` will render in document flow inside the `ax-tabs` grid container, pushing all content below the tab strip downward when open. The `z-index` token is referenced but non-functional without a positioning context. The menu will not visually overlay the page as designed.

**PASS items (Visuals):**
- Sidebar tiering is structurally implemented: Billing always-expanded, specialist zones (Recovery/Developer/Catalog) render collapsible `<button>` toggles with chevron icons
- Connect stands alone as a single non-collapsible leaf
- Attention badges render only when count > 0 (conditional on `group_meta.badge` — `sidebar.ex:62`)
- Visible search field on Home (`dashboard_live.ex:99-111`) — `.ax-input-search` styled as a full-width labeled input with leading search icon
- Topbar search trigger renders visible text "Search customers, invoices… ⌘K" (not icon-only above mobile breakpoint)
- Compliance lens chip "By actor" visible as a persistent chip above the events DataTable
- Related billing card present on all 8 detail screens (confirmed via grep: customer, subscription, invoice, charge, coupon, promotion_code, connect_account, webhook + event — 9 render callsites in live/)
- EventLive at `/events/:id` exists and closes the Webhook→Event→entity thread

---

### Pillar 3: Color (4/4)

All Phase 175 CSS additions correctly compose from `ax-*` tokens with no new literal hex values or RGB values.

**Token-gap closures (all correct):**
- `.ax-badge-warning`: `color-mix(in srgb, var(--ax-warning) 12%, var(--ax-elevated))` + `var(--ax-warning-readable)` — matches UI-SPEC §2 badge spec exactly (`app.css:1204-1207`)
- `.ax-badge-danger`: `color-mix(in srgb, var(--ax-danger) 12%, var(--ax-elevated))` + `var(--ax-danger-readable)` — matches UI-SPEC §2 (`app.css:1210-1213`)
- `.ax-sidebar-group-chevron` color: `var(--ax-muted)` — matches spec (`app.css:1219`)
- `.ax-sidebar-group-toggle` color: `var(--ax-muted)` — specialist zones correctly de-emphasized vs Billing (`app.css:1241`)
- `.ax-tab-more-menu` surface: `var(--ax-elevated)`, border `var(--ax-border)`, shadow `var(--ax-shadow-md)` — all token-correct (`app.css:1257-1264`)
- `.ax-input-search` and placeholder: `var(--ax-elevated)` background, `var(--ax-muted)` color, `var(--ax-border)` border — all token-correct (`app.css:1878-1906`)

**60/30/10 distribution check (Phase 175 additions only):**
- Dominant (60%): new sidebar chrome uses `var(--ax-elevated)` sidebar surface — correct
- Secondary (30%): specialist zone labels and chevrons use `var(--ax-muted)` — correct weight gradient vs Billing zone
- Accent (10%): accent appears only on the active tab underline (`ax-tab-active` — pre-existing), focus rings, and active queue chips — not overused

Pre-existing dark-mode literal overrides (`#f4f7fa`, `#1f283d`, `#171d24`) are v1.50 surfaces per the anti-churn ledger and were not introduced or modified by Phase 175.

---

### Pillar 4: Typography (3/4)

All Phase 175 new typography rules use token references:
- `.ax-sidebar-group-toggle`: `var(--ax-type-xs)` / weight 700 / `var(--ax-tracking-caps)` / uppercase — matches spec §1 group eyebrow role (`app.css:1243-1245`)
- `.ax-sidebar-group-toggle:focus-visible`: `2px solid var(--ax-focus-ring)` — correct
- `.ax-input-placeholder`: `var(--ax-type-sm)` — matches spec §6 body/search-placeholder role (`app.css:1905`)
- Attention badge inner number (`ax-badge`): `var(--ax-type-sm)` / weight 700 — matches spec §2 badge role (`app.css:1192-1193`)

**Pre-existing literal font-size warnings (not introduced in Phase 175, noted for record):**
- `.ax-field-label` (line 1337): `font-size: 0.875rem` — literal, not token
- `.ax-dropdown-item-label` (line 1434): `font-size: 0.875rem` — literal, not token
- `.ax-tab` (line 1465): `font-size: 0.875rem` — literal, not token

These are v1.50 surfaces within the anti-churn ledger and Phase 175 correctly did not re-open them. Flagged as pre-existing technical debt for a future cleanup phase.

**Weight distribution (Phase 175 additions):** 400 (body, search placeholder), 600 (nav links, tab labels), 700 (badges, group eyebrows) — matches the three-weight system declared in UI-SPEC Typography. No new weights introduced.

---

### Pillar 5: Spacing (4/4)

All spacing in Phase 175 CSS additions resolves from `--ax-space-*` tokens. Git diff analysis of Phase 175 commits confirms:

**Phase 175-03 CSS additions (`app.css` diff `ea8df670`→`de7a0b85`):**
- `ax-sidebar-group-toggle` padding: `0 var(--ax-space-sm)` — token correct
- `ax-sidebar-group-toggle` margin: `0 0 var(--ax-space-xs)` — token correct
- `ax-sidebar-group-toggle` gap: `var(--ax-space-xs)` — token correct
- `ax-sidebar-group-toggle:focus-visible` outline-offset: `var(--ax-space-2xs)` — token correct
- `ax-tab-more-menu` padding: `var(--ax-space-sm)` — token correct

**Phase 175-04 CSS additions (`app.css` diff `de7a0b85`→`6efb78b1`):**
- `ax-home-search` margin-bottom: `var(--ax-space-md)` — token correct
- `ax-input-search` gap: `var(--ax-space-sm)` — token correct
- `ax-input-search` padding-inline: `var(--ax-space-md)` — token correct

No arbitrary `[...]px` or `[...]rem` spacing values introduced. The `2px` in `.ax-sidebar-group-toggle:focus-visible { outline: 2px ... }` is an established CSS constant throughout the codebase per the PATTERNS.md decision note and the UI-SPEC exception clause (1px/2px borders are conventional constants, not token-violating literals).

---

### Pillar 6: Experience Design (2/4)

**BLOCKER: "More ▾" dropdown positioning breaks interaction**

As noted in Pillar 2, the `.ax-tab-more-menu` lacks `position: absolute` and `.ax-tab-more-wrapper` lacks `position: relative`. The menu will expand in-flow when `@more_tabs_open` is true, pushing page content downward instead of overlaying it. For a user attempting to switch to a recessed tab (Payment methods, Entitlements, Events, Metadata), clicking "More" will shift all visible content below the tab strip, producing a jarring layout shift and making it unclear that a menu opened. The aria semantics (`aria-haspopup="menu"`, `aria-expanded`) are correct — the CSS is what fails.

**WARNING: No queue-context-aware empty state**

The DataTable `empty_title` and `empty_copy` props in `invoices_live.ex`, `subscriptions_live.ex`, and `charges_live.ex` are hardwired to generic entity-level copy regardless of which filter is active. When the work-queue filter yields zero results (queue is clear), the user sees "No [entities] for this organization yet" — which could be read as a data-missing error rather than a task-complete state. The UI-SPEC §3 explicitly calls for context-aware empty states that point to the "All" escape hatch.

**WARNING: EventLive not-found has no flash message**

`event_live.ex` redirects to `/billing/events` on not-found without a flash (explicitly documented in Plan 05 SUMMARY as a known limitation: `fetch_flash` not in the `accrue_admin_browser` pipeline). Users who follow a stale `/events/:id` link are redirected silently to the event list with no explanation. The fix — adding `plug :fetch_live_flash` to the `accrue_admin_browser` pipeline — is a one-line pipeline change.

**WARNING: Search error state not implemented**

`global_search.ex` has no error rendering path. Task timeouts (`on_timeout: :kill_task` at 3000ms) are silently discarded via the `{:exit, _}` clause (line 105) — the results for that entity type just come back empty with no user-visible message. The UI-SPEC Copywriting Contract specifies the error string `"Search is unavailable right now. Try again in a moment."` for this case. Without it, a search timeout looks identical to zero results.

**PASS items (Experience Design):**
- Loading state: `@loading` assign exists in GlobalSearch; `ax-spinner` class toggled on search input (`global_search.ex:143`); debounce set at 150ms
- Collapse state persistence: `SidebarCollapse` JS hook writes/reads `localStorage` with mount_path-prefixed keys — state survives navigation (`sidebar_collapse.js:49-54`)
- Default collapse state: specialist zones auto-expand when badge > 0 (`sidebar.ex:116-118`)
- Escape key closes "More ▾" menu: `phx-window-keydown="close_more_tabs" phx-key="Escape"` (`customer_live.ex:257-258`)
- `aria-haspopup="menu"` and `aria-expanded` on "More ▾" trigger are correct (`customer_live.ex:263-264`)
- `aria-current="page"` on active primary tab and active recessed tab in menu (`customer_live.ex:250, 278`)
- Badge aria-labels populated correctly (`sidebar.ex:126-128`)
- Focus ring on sidebar group toggle via `var(--ax-focus-ring)` (`app.css:1249-1253`)
- `aria-expanded` and `aria-controls` on collapsible sidebar button (`sidebar.ex:56-57`)
- DB-error rescue in `NavBadgeHook` — nav never crashes on a bad count query (`nav_badge_hook.ex`)
- Bidirectional Related cards: all 8 detail screens render RelatedResources (9 callsites confirmed)
- Webhook→Event→entity thread: EventLive at `/events/:id` exists; WebhookLive Related card links to events; EventLive Related card links to source webhook and affected entity
- `/charges` → `/payments` redirect: `RedirectController` correctly redirects index and show routes with query-string preservation; existing bookmarks survive
- `push_patch` work-queue default: default filter applied in LiveView via `handle_params` + `push_patch` (not HTTP redirect), URL reflects `?status=…`, shareable/bookmarkable. `connected?` guard prevents static-render redirect loop.
- Compliance "By actor" chip: always visible, tone switches cobalt/slate on activation, URL-param synced (`events_live.ex:138-157`)

---

## Registry Safety

No `components.json` found. Elixir/Phoenix project — no shadcn, no component registry, no third-party UI blocks. Registry vetting gate not applicable.

---

## Files Audited

- `.planning/phases/175-b-persona-driven-ia-spine/175-UI-SPEC.md`
- `.planning/phases/175-b-persona-driven-ia-spine/175-CONTEXT.md`
- `.planning/phases/175-b-persona-driven-ia-spine/175-01-SUMMARY.md` through `175-07-SUMMARY.md`
- `accrue_admin/lib/accrue_admin/nav.ex`
- `accrue_admin/lib/accrue_admin/components/sidebar.ex`
- `accrue_admin/lib/accrue_admin/components/app_shell.ex`
- `accrue_admin/lib/accrue_admin/components/topbar.ex`
- `accrue_admin/lib/accrue_admin/components/global_search.ex`
- `accrue_admin/lib/accrue_admin/attention_counts.ex`
- `accrue_admin/lib/accrue_admin/nav_badge_hook.ex`
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`
- `accrue_admin/lib/accrue_admin/live/customer_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` (partial)
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` (partial)
- `accrue_admin/lib/accrue_admin/live/charges_live.ex` (partial)
- `accrue_admin/lib/accrue_admin/live/events_live.ex` (partial)
- `accrue_admin/lib/accrue_admin/live/event_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` (partial)
- `accrue_admin/lib/accrue_admin/copy.ex` (partial)
- `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `accrue_admin/assets/css/app.css` (Phase 175 additions + context)
- `accrue_admin/assets/js/hooks/sidebar_collapse.js`
- `accrue_admin/priv/static/accrue_admin.css` (spot-check compiled output)
