# Phase 209: Reign Subscriptions (list + detail CSS coordination) - Research

**Researched:** 2026-07-19
**Domain:** Elixir/Phoenix LiveView template recomposition (in-house `ax-*` CSS, no external libs) — codebase-mapping research, not external-library research.
**Confidence:** HIGH (every structural/CSS claim below is grep- or Read-verified against the working tree at commit `f6278ff9`; no speculative library research was needed because this phase adds zero dependencies).

## Summary

This phase is a pure internal recomposition: no new packages, no new CSS tokens, at most one (currently: zero, per D-02) new component. The entire research task was to map exact line numbers of what to remove/rebuild in `subscriptions_live.ex`, confirm the "copy this shape" idiom in `invoices_live.ex`/`customers_live.ex`, and — the namesake risk — prove precisely which `.ax-inline-worklist*`/`.ax-audit-summary-row` CSS rules are shared with `subscription_live.ex` (and `component_kitchen_live.ex`, a third consumer not mentioned in the phase docs) so REIGN-01 does not silently break the detail page.

Two corrections to the phase's framing, discovered by direct grep, that the planner should know before writing tasks: (1) the "triplicated health verdict" is actually rendered at **two** sites in the current code (page title + band-1 strip), not three — the **CTA** ("Open dedicated invoice queue") is the one genuinely triplicated (3 exact-text button occurrences + 1 near-duplicate link); (2) `component_kitchen_live.ex` (the dev-only component gallery) also renders `.ax-inline-worklist*` and `.ax-audit-summary-row` — REIGN-04's Phase 211 grep-gate must account for it, not just the detail page, when it eventually deletes CSS. Neither correction changes what Phase 209 must do; both change what the grep-gate evidence needs to say.

**Primary recommendation:** Delete the five band `<section>`s and the two dead-query helper chains verbatim (line ranges below), rebuild `identity_cell/3` and `billing_signals_cell/3` to mirror `invoices_live.ex:234-242`'s two-line `ax-stack-xs` idiom, relocate every removed band's operator datum into the `StatStrip`/verdict per D-03, and touch **zero** lines in the CSS rule blocks that begin `.ax-inline-worklist {` (app.css:3124) and `.ax-audit-summary-row {` (app.css:7392) — only stop referencing the `.ax-subscriptions-*` scoping classes that wrap them.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Page composition / IA (spine, bands, verdict placement) | Frontend Server (Phoenix LiveView, server-rendered) | — | `subscriptions_live.ex` `render/1` is server-rendered HEEx; no client-side routing or hydration boundary is involved. |
| Compact cell rendering (`identity_cell`, `billing_signals_cell`) | Frontend Server | — | Cell HTML is built server-side via `Phoenix.HTML.raw/1` inside the LiveView module; DataTable is a `live_component`, still server-rendered. |
| Styling (`ax-*` classes, tokens) | CDN/Static-equivalent (compiled CSS asset) | Frontend Server | `assets/css/app.css` compiles to the committed `priv/static/accrue_admin.css`, served as a static asset; the LiveView only emits class names, never inline styles. |
| Data aggregation (`subscription_summary/1`, `open_invoice_queue/1`) | API/Backend (Ecto queries against `Accrue.Repo`) | Frontend Server | Queries run in the LiveView's `mount/3` against Ecto schemas (`Subscription`, `Invoice`, `WebhookEvent`) — this is backend-tier logic co-located in the LiveView module, not a separate API boundary (Accrue admin has no separate REST API layer for this page). |
| Copy/string sourcing | Frontend Server (`AccrueAdmin.Copy.*`) | — | Compile-time Elixir functions; also feeds the generated `copy_strings.json` static artifact consumed by e2e. |
| Row navigation | Browser/Client (plain `<a href>` link, LiveView `push_patch`/full navigation on click) | — | No JS-side router; identity-cell `<a>` triggers a normal or `live_patch` navigation. |

## Standard Stack

**No new dependencies for this phase.** Everything is composed from existing `AccrueAdmin.Components.*` and existing `assets/css/app.css` classes. There is nothing to install.

### Core (existing, reused — not new)
| Module | Where defined | Purpose | Why it's the standard here |
|--------|---------------|---------|------------------------------|
| `AccrueAdmin.Components.PageHeader` | `accrue_admin/lib/accrue_admin/components/page_header.ex` | Breadcrumbs/title/`:description`/`:stat_strip`/`:actions`/`:filter_toolbar` chrome | Already the canonical header on Invoices/Customers/Payments; Subscriptions already uses it, just with extra override classes to shed. |
| `AccrueAdmin.Components.StatStrip` | `.../components/stat_strip.ex` | Compact `<dl>` metric row, optional `tone` (`moss`/`cobalt`/`amber` only — no `slate`/`danger`/`ink` tone class defined, see Pitfall 1) and optional `href` | D-03's verdict StatStrip target. |
| `AccrueAdmin.Components.DataTable` | `.../components/data_table.ex` | List/table/card rendering, filter toolbar, empty/loading states, `:list_status` slot | Unchanged in this phase — only its `columns`/`card_fields` render-fn arguments change. |
| `AccrueAdmin.Components.FilterChipBar` | `.../components/filter_chip_bar.ex` | Chip row inside `:list_status` | Unchanged; `work_queue_chips/3` already wires it correctly. |
| `AccrueAdmin.Components.StatusBadge` | `.../components/status_badge.ex` | `<span class="ax-status-badge ax-status-badge-{tone}">` | Already used by `state_cell/1` (line 547-560); REIGN-02 wants it in the rebuilt `identity_cell` and for the single verdict badge. |
| `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Subscription` | `.../copy.ex`, `.../copy/subscription.ex` | Sourced operator strings | `Copy.Subscription` already exists with 18 subscription-detail strings + 6 subscriptions-list empty-state strings; needs new functions for the reign (see § Copy plumbing below). |

### Alternatives Considered
None — this is an internal-composition phase; the "alternative" to every choice below is "keep the bespoke markup," which is explicitly the thing being removed.

**Installation:** N/A — no `mix.exs` change. Confirm with `git diff accrue_admin/mix.exs accrue_admin/mix.lock` after implementation is empty.

## Package Legitimacy Audit

**Not applicable.** This phase adds zero external packages. `gsd-tools query package-legitimacy check` was not run because there is nothing to check — grep confirms no new `deps/0` entries are proposed anywhere in CONTEXT.md/UI-SPEC.md, and the milestone's binding scope guardrail explicitly forbids new deps.

## Target File Anatomy — `subscriptions_live.ex` (verified against current working tree)

All line numbers below are from `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` as read directly (not from CONTEXT.md's approximate ranges, which are close but not exact — use these instead).

### Page-override classes to drop
| Class | Line | Context |
|-------|------|---------|
| `ax-page ax-page-compact ax-subscriptions-page` | 98 | wraps the whole page `<section>` |
| `ax-page-header-compact ax-subscriptions-header` | 100 | `PageHeader.page_header class=` attr |
| `ax-kpi-row ax-subscriptions-kpi-row` | 143 | `<div>` wrapping `StatStrip.stat_strip` inside `:stat_strip` slot — **this exact string is what `subscriptions_live_test.exs:111` asserts on** |

### The five bespoke band `<section>`s (between `FlashGroup` at line 194 and `DataTable` `live_component` at line 281)
| # | Lines | Classes | aria-label | Content it carries |
|---|-------|---------|------------|---------------------|
| 1 | 196-212 | `ax-inline-worklist ax-subscriptions-invoice-strip` (+ `-danger` modifier when `open_invoice_count > 0`) | "Open-invoice queue worklist" | `billing_priority_title/1` verdict ("Primary queue" / "Billing status: Healthy") + open-invoice count/exposure text + CTA #2 "Open dedicated invoice queue" |
| 2 | 214-219 | `ax-subscriptions-queue-shortcut` (no `ax-inline-worklist` base — standalone class) | "Open-invoice queue records" | Open-invoice count restated + link "Open dedicated invoice queue records" |
| 3 | 221-241 | `ax-inline-worklist ax-subscriptions-invoice-records` | "Open-invoice queue preview" | Top-3 open-invoice preview list (`@open_invoice_queue` assign) + CTA #3 "Open dedicated invoice queue" |
| 4a | 243-279 (wrapper), 244-254 | `ax-subscriptions-secondary-strips` wrapping `ax-inline-worklist ax-subscriptions-at-risk-strip` | "At-risk subscription queue" | At-risk/past-due count + "Open recovery analytics" secondary button |
| 4b | 256-278 | `ax-inline-worklist ax-subscriptions-audit-strip` | "Subscription audit trail" | Static audit-preview text + two buttons: "Events: open full actor audit log" / "Filter admin actions" |

**Operator-datum source list for the content-preservation proof (Interaction Contract point 1):**
- At-risk exposure/count → band 1's verdict text + StatStrip stat "At-risk subscriptions" (line 158-162, already present) — carry forward count; **exposure in dollars for at-risk subs is NOT currently computed anywhere** (`subscription_summary/1`, lines 357-383, has no at-risk-exposure aggregate — only `open_invoice_exposure_minor`). D-03's StatStrip spec says "At-risk subscriptions (count)" only, not an at-risk exposure dollar figure, so this is consistent — no new query needed.
- Last-webhook status → currently only a raw count (`failed_webhook_count`, line 378-381) surfaced via the existing "Failed payment/webhook count" StatStrip stat (lines 169-178) and band-1's implicit "webhook debug" secondary button (line 122-134, in `:actions`, NOT one of the 5 bands — stays outside band-removal scope). D-03 asks for "Last webhook (status · time)" — **this is new: no query currently returns a webhook *timestamp*.** The planner must either (a) add a lightweight `Repo.aggregate`/`Repo.one` for the most recent failed/dead webhook's `inserted_at`, or (b) descope the "· time" portion and keep only "N failed" as today. Flagging as Open Question below — do not assume the timestamp exists.
- Open-invoice count/exposure → `open_invoice_count` + `open_invoice_exposure_minor` (lines 368-377) already computed; StatStrip stat "Open-invoice queue" (line 163-168) already surfaces the count but not the exposure dollar amount inline (exposure only appears in band-1's text, line 205). Rebuilt StatStrip must add an exposure stat (D-03: "Exposure ($ to collect)").

### Dead code after band removal
| Function | Lines | Becomes dead because |
|----------|-------|------------------------|
| `open_invoice_queue/1` | 407-431 | Only consumer is band 3's preview list (line 226-234) |
| `open_invoice_queue_base/2` (both clauses) | 433-449 | Only called by `open_invoice_queue/1` |
| `invoice_queue_record_href/3` | 841-849 | Only consumer is band 3's `<li>` link (line 228) |
| `invoice_queue_due/1` (both clauses) | 851-856 | Only consumer is band 3's `<em>` (line 231) |
| `invoice_queue_customer_label/1` (all 3 clauses) | 858-865 | Only consumer is band 3's `<strong>` (line 229) |
| `billing_priority_title/1` (both clauses) | 496-499 | Only consumer is band 1 (line 204) — this is one of the two verdict-render call sites; removing it collapses the verdict to the single `subscriptions_health_verdict/1` call (line 108) |
| `:open_invoice_queue` assign | mount, line 53 | Feeds `@open_invoice_queue` used only in band 3 |

**Not dead — do not remove:** `invoice_queue_path/2` (line 835-839, still needed for the single primary CTA's href) and `invoice_queue_path_from_table/1` (line 867-874, used by `work_queue_chips/3`'s "Open invoice queue workspace" chip, line 727-733 — unrelated to the bands).

### Cell render-fns to rebuild (Interaction Contract point 3)
| Function | Lines | Current shape | What it must become |
|----------|-------|----------------|----------------------|
| `identity_cell/3` | 501-538 | 6-line `Phoenix.HTML.raw` block: primary link prefixed "Open unified customer view: …", inline `StatusBadge`-lookalike markup (hand-rolled, not the real `StatusBadge` component), a customer-scope caption line, a meta-grid with explicit "Customer ID" / "Subscription" labeled facts, and 3 in-cell action links/buttons ("Work open invoices", "Send reminder", "Filter invoice queue to this subscription") | Two-line `ax-stack-xs` block per `invoices_live.ex:239-241`: `<a href="{subscription_href}" class="ax-link">{customer or subscription label}</a>` + `<a class="ax-label ax-muted">{secondary label}</a>`. **No in-cell buttons at all** (D-01). The current explicit "Customer ID: …" / "Subscription: …" raw-ID facts are NOT preserved verbatim by the reference idiom — Invoices' cell shows only the identifier-as-link + one muted secondary line, and Customers has a *separate* dedicated "ID" column (`id_badge_cell/2`, `customers_live.ex:239-251`, using the shared `IdBadge` component) rather than cramming raw IDs into the identity cell. This is a genuine density/idiom decision left to the planner (not a content-preservation violation — REIGN-02's compact-cell mandate implies trimming raw-ID density is intended, matching the reference pages), but the planner should explicitly choose: (a) drop raw IDs from the cell entirely (matches Invoices most closely, since row already links to `/subscriptions/:id`), or (b) add a 3rd `IdBadge` column (matches Customers). Given D-01 says the identity cell alone carries the link (no extra column mentioned), (a) is the closer read of the locked decision. |
| `billing_signals_cell/3` | 451-494 | 6-line `Phoenix.HTML.raw` block: hand-rolled `ax-audit-summary-row` fact, a fake "Invoice queue status" line pointing nowhere, a "Webhook status" line + link, `ax-chip ax-label` Owner/Tax chips (this part is ALREADY the target idiom — keep verbatim), and an "Open audit context" link | Rebuild around the two chips that already match the target idiom (`<span class="ax-chip ax-label">Owner: …</span> <span class="ax-chip ax-label">Tax: …</span>`, line 488) — these survive unchanged. Everything else (the fake "Invoice queue status" line, the in-cell webhook debug link, the in-cell "Open audit context" link) is either dead/misleading copy or an in-cell action link that D-01/REIGN-02 forbids; trim to chips + optionally a `StatusBadge` for webhook health if that datum needs to stay visible per-row. |

**Explicitly out of scope for rebuild** (not named in UI-SPEC Interaction Contract point 3, and their current shape is already close to the target idiom or simply unaffected):
- `state_cell/1` (547-560) — already uses the real `StatusBadge.status_badge/1` component. Leave as-is.
- `plan_amount_cell/1` (581-611) and `setup_gap_cell/2` (603-611) — plain text/no bespoke `ax-subscriptions-*`/`ax-inline-worklist` classes. Leave as-is (`subscriptions_live_test.exs:297-298` asserts on this cell's exact copy and should keep passing untouched).
- `time_cell/1` (626-640) — plain text. Leave as-is.

### Breadcrumb (Interaction Contract, Copywriting Contract)
- Lines 101-107: fake parent `%{label: "Billing health overview", href: scoped_path(@admin_mount_path, "", @current_owner_scope)}` — this href actually points at the dashboard root (`/billing` + optional org query), so despite the UI-SPEC calling it "no navigable target," it DOES currently resolve to a real route — the problem per the copy contract is the **label** is not the dashboard's actual name/identity, not a broken href. Replace with the real 2-crumb pattern used by every reference page: `%{label: Copy.dashboard_breadcrumb_home(), href: scoped_path(...)}` (returns the literal string `"Dashboard"`, not `"Home"` — see Open Question 1) + a terminal `%{label: <new fn>}` for "Subscriptions" with no `href` (current-page crumb, matching `invoices_live.ex:97-100` and `subscription_live.ex:197-213`'s pattern of `Copy.dashboard_breadcrumb_home()` for the root crumb).

## Canonical Reference Idioms

### `invoices_live.ex` (best match — also a list page whose row navigates to a detail page)
- **Spine assembly** (`invoices_live.ex:83-182`): `AppShell` → `<section class="ax-page">` (no override classes) → `PageHeader.page_header` with `breadcrumbs`/`title` attrs + `:description`/`:stat_strip`/`:filter_toolbar` slots — **no `:actions` slot at all**. → `FlashGroup.flash_group` → `.live_component module={DataTable}` → `:list_status` slot with `FilterChipBar.filter_chip_bar`.
- **Compact identity-cell pattern** (`invoices_live.ex:234-242`, `defp invoice_identity_cell/3`):
  ```elixir
  Phoenix.HTML.raw(
    ~s(<span class="ax-stack-xs"><a href="#{invoice_href}" class="ax-link">#{escape(invoice_label)}</a><a href="#{customer_href}" class="ax-label ax-muted">#{escape(customer_label(row))}</a></span>)
  )
  ```
  This is the literal "copy this shape" reference: outer `ax-stack-xs`, primary `ax-link` to the detail route, secondary `ax-label ax-muted` (itself a link, to the *customer's* detail — cross-navigation, not just decoration).
- **`billing_signals_cell/1`** (`invoices_live.ex:223-232`): exactly the 2-chip pattern (`ax-chip ax-label` × 2, ownership + tax) that `subscriptions_live.ex`'s `billing_signals_cell/3` (line 488) already partially matches — confirms this part of the Subscriptions cell needs no invention, just extraction from the noisier surrounding markup.
- **FilterChipBar wiring** (`invoices_live.ex:168-177`): inside `DataTable`'s `:list_status :let={status}` slot, `result_count={status.visible_count}`, `result_label={Copy.invoices_list_result_label_pair()}` (a `{singular, plural}` tuple fn, not a bare string — Subscriptions currently hardcodes the tuple inline at line 333: `{"subscription row", "subscription rows"}` — fine to leave inline or promote to a `Copy` fn, not required by any locked decision).
- **`work_queue_chips/2`** (`invoices_live.ex:341-377`) + **`filter_chip_label/1`** (379-383) + **`filter_chip_value/2`** (385-393): Subscriptions' `work_queue_chips/3` (subscriptions_live.ex:690-735) already mirrors this shape closely (it has an extra `:open_invoices` chip Invoices doesn't). No changes required to this part — filters/chips are explicitly unaffected by the reign.
- **Whole-row-nav, correction of framing:** there is **no dedicated full-`<tr>` click handler or wrapping `<a>`** anywhere in `AccrueAdmin.Components.DataTable` (verified: `grep -n "row_href\|phx-click.*row\|onclick"` in `data_table.ex` finds only the row-select checkbox's `phx-click="toggle-row"`, unrelated to navigation). "Whole row navigates" is idiomatic shorthand for **"the identity cell's `<a>` is the only navigation affordance in the row — there is no separate actions column,"** not a literal full-row click target. Do not implement a `<tr onclick>` wrapper; that would be new behavior not present on any reference page.

### `customers_live.ex` (second reference — shows the alternative to cramming raw IDs into the identity cell)
- **Spine** (`customers_live.ex:86-179`): identical assembly to Invoices; also **no `:actions` slot**.
- **Breadcrumb root** here is hardcoded `"Dashboard"` literal (line 101), not `Copy.dashboard_breadcrumb_home()` — an existing inconsistency between reference pages (Invoices uses the Copy fn, Customers hardcodes the string) that the planner should follow Invoices' Copy-fn usage for (COPY-01 mandates Copy-sourced strings, not inline literals).
- **`customer_link/3`** (`customers_live.ex:218-234`): same `ax-stack-xs` shape as Invoices' identity cell, but with a conditional second line (only rendered if `email != label`) rather than always-present.
- **Dedicated ID column via `IdBadge`** (`customers_live.ex:151,156,239-251`): `id_badge_cell/2` renders `<IdBadge.id_badge id={@dom_id} id_value={@id_value} />` in its own table column, giving click-to-copy without polluting the identity cell — this is the pattern to reach for **only if** the planner decides raw subscription/customer IDs must stay independently visible in the list (see identity_cell table above, option b).
- **FilterChipBar wiring** (`customers_live.ex:284-338`, helpers at 340-347): confirms the `filter_chip_label/1`/`filter_chip_value/2` pair-of-private-functions idiom is the norm across all three list pages (Invoices, Customers, Subscriptions already follow it) — nothing new needed here.

### `PageHeader` component contract (`page_header.ex:1-59`)
- `:actions` slot: only rendered `:if={@actions != []}` — so its absence on Invoices/Customers is a deliberate choice (they simply never pass the slot), not a component limitation.
- `:stat_strip` slot: renders inside `<div class="ax-page-header-stat-strip">` — this is the div the `ax-kpi-row ax-subscriptions-kpi-row` wrapper (line 143) is currently double-wrapping; the target state passes `StatStrip.stat_strip` directly with no extra wrapping `<div>`, matching Invoices (`invoices_live.ex:107-117`) and Customers (`customers_live.ex:110-118`), neither of which wraps the `StatStrip.stat_strip` call in anything.
- **`StatStrip` tone constraint** — see Pitfall 1 below: only `moss`/`cobalt`/`amber` are real CSS-backed tones; `slate` is currently passed (subscriptions_live.ex:148, "MRR signal" stat) but has **no** `tone_class/1` clause in `stat_strip.ex:46-49` (falls through to `nil` — renders untoned). If D-03's verdict badge needs a neutral/slate-toned stat, it will render plain, not slate-colored, unless `StatStrip.tone_class/1` is extended — **that would be a shared-component edit**, which the milestone permits ("improving a shared component is allowed, forking is not" — REQUIREMENTS.md line 10) but is a decision the planner should make explicitly, not discover at runtime.

## Shared-CSS Coordination (the namesake risk) — grep-verified evidence for the D-04 gate

### Base rules that are genuinely shared (Phase 209 must make ZERO edits to these; Phase 211's grep-gate is the one that eventually judges them)
| CSS rule | `app.css` line | Referenced by (`.ex` grep) |
|----------|------|------------------------------|
| `.ax-inline-worklist { … }` | 3124 | `subscriptions_live.ex` (3 bands, lines 198/221/244/256 — to be removed), `subscription_live.ex:304` (`ax-detail-open-invoice-queue`, **out of scope, keep**), `component_kitchen_live.ex:140,158,182,199` (dev-only gallery, **keep**) |
| `.ax-inline-worklist-copy { … }` (+ `strong`/`span` children, 3136-3157) | 3136 | Same three consumers |
| `.ax-inline-worklist-actions { … }` | 3157 | Same three consumers |
| `.ax-inline-worklist + .ax-inline-worklist { … }` (adjacent-sibling spacing rule) | 3406 | Generic selector — matters most for `component_kitchen_live.ex`'s 4 consecutive worklist sections; harmless once Subscriptions' 2-3 adjacent worklist bands are removed (rule simply stops matching there) |
| `.ax-audit-summary-row { … }` (+ `span`/`strong`/`em` children, 7392-7431) | 7392 | `dashboard_live.ex:309` (**out of scope, Phase 210**), `subscriptions_live.ex:476` (to be removed), `subscription_live.ex:480` (**out of scope, keep**), `component_kitchen_live.ex:219,975` (dev-only, **keep**) |
| `.ax-detail-open-invoice-queue .ax-inline-worklist-copy strong { … }` | 7007 | `subscription_live.ex` only — scoped to the detail page's own class, unaffected either way |
| `.ax-dev-audit-log-card .ax-audit-summary-row { … }`, `.ax-dev-production-strip .ax-inline-worklist-copy …` | 2242, 2375, 2381 | `component_kitchen_live.ex` only — unaffected |

**Confirmed a 3rd consumer beyond the phase docs' "detail page" framing:** `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` also renders `.ax-inline-worklist*` (4 sections) and `.ax-audit-summary-row` (2 places). This file is dev-tooling (the `/billing/dev/components` gallery, captured by `admin-visuals.spec.js` as the `"component-kitchen"` surface), not a production admin page, but it is still an `.ex` reference that will show up in Phase 211's grep-gate. Phase 209 does not touch it; documenting so Phase 211's "zero remaining references" check knows to expect (and correctly ignore, since it's intentionally out of milestone scope) this file.

### Scoped rules that are Subscriptions-page-only (safe to stop referencing in 209; Phase 211 deletion candidates — zero other `.ex` consumers found)
All of the following live under either `.ax-subscriptions-*` class scoping or the `.ax-subscriptions-secondary-strips`/`.ax-subscriptions-invoice-strip`/`.ax-subscriptions-invoice-records` parent selectors in `app.css`, and grep confirms **no** file other than `subscriptions_live.ex` references the parent class:
- `.ax-subscriptions-page` (app.css:2976, plus `:has(> .ax-subscriptions-page)` selectors at 1086 and 6281) and everything scoped under it: `.ax-subscriptions-page .ax-data-table*` (3120, 3880-4568 — a large block of page-scoped DataTable overrides), `.ax-subscriptions-page .ax-filter-chip*` (3410-3432), `.ax-subscriptions-page .ax-audit-summary-row` (4053/4059 — a scoped override of the shared base rule, safe because it requires the `.ax-subscriptions-page` ancestor which is being dropped)
- `.ax-subscriptions-header` and everything scoped under it (2865-3531, 4328-4334, 4557-4568)
- `.ax-subscriptions-kpi-row` (2888)
- `.ax-subscriptions-invoice-strip`, `-danger`, `-primary-workspace`, `-webhook-workspace`, `-priority-copy`, `-exposure` (3189-3353)
- `.ax-subscriptions-invoice-records`, `-invoice-record-list`, `-invoice-record`, `-invoice-record-empty` (3266-3320)
- `.ax-subscriptions-queue-shortcut` (3324-3343)
- `.ax-subscriptions-secondary-strips`, `-at-risk-strip`, `-audit-strip` (3164-3185, 4388, 4394)
- `.ax-subscription-row-*` (all variants — `state`/`meta`/`meta-grid`/`customer`/`customer-scope`/`invoice-controls`/`invoice-primary`/`invoices`/`audit`/`audit-primary`/`signal-primary`/`signal-secondary`/`admin-chips`/`webhook-action`), `.ax-webhook-row-status*`, `.ax-subscription-setup-gap`, `.ax-data-table-inline-actions` — all confirmed **only** referenced inside `subscriptions_live.ex`'s cell render-fns (lines 451-538); these have **no detail-page or dev-kitchen overlap at all** and can be edited/removed freely as part of the cell rebuild without any D-04 coordination concern.

**Pre-existing orphaned CSS discovered (not created by this phase, not required to fix, but worth flagging for Phase 211):** grep of `app.css` turned up several `.ax-subscriptions-*` selectors with **zero** matching class usage anywhere in current `.ex` files — `.ax-subscriptions-health-hero*` (3005-3049), `.ax-subscriptions-customer-search-strip*` (3193-3210), `.ax-subscriptions-webhook-strip` (3353), `.ax-subscriptions-priority-actions` (3360), `.ax-subscriptions-secondary-group*` (3365-3389), `.ax-subscriptions-secondary-link` (3389), `.ax-subscriptions-utility-strip` (3393). These predate Phase 209 (likely leftovers from an earlier redesign pass) and are already zero-reference dead CSS today. Phase 209 should not spend effort on them (CSS deletion is Phase 211's job per REIGN-04), but Phase 211's grep-gate will find them already at zero references — no new work created, just confirming they were already there.

## Copy Plumbing

- `AccrueAdmin.Copy` (top-level, `copy.ex`) is a facade of `defdelegate`s to per-resource submodules (`AccrueAdmin.Copy.Subscription`, `.Invoice`, `.Coupon`, etc. — confirmed via `grep -n "defdelegate"` pattern) plus some directly-defined functions (`dashboard_breadcrumb_home/0` at line 1223, `data_table_clear_filters_label/0` at 826, `customers_index_heading/0` at 828, `resource_state_copy/2,3` at 186-188).
- `AccrueAdmin.Copy.Subscription` (`copy/subscription.ex`, 165 lines) **already exists** with: `subscription_breadcrumb_subscriptions/0` → `"Subscriptions"` (line 6, used by the **detail** page as a parent-crumb-with-href pointing back to the list), `subscription_page_title/0` → `"Subscription"` (line 78, detail-page `page_title`), and 6 subscriptions-**list** empty-state functions (`subscriptions_list_first_run_empty_title/body`, `subscriptions_list_queue_empty_title/body`, `subscriptions_list_filtered_empty_title/body`, `subscriptions_list_loading_label`, `subscriptions_list_plan_amount_unavailable/0`) already wired via `Copy.resource_state_copy(:subscriptions, state)` (subscriptions_live.ex:812).
- **Does NOT exist yet — must be added** (confirmed via targeted grep for each name, zero hits): a leaf-breadcrumb function for the list page itself (UI-SPEC names it `Copy.subscriptions_index_breadcrumb()`, mirroring `Copy.invoices_index_breadcrumb_invoices()` and `Copy.customers_index_heading()`'s pattern of a *separate* fn from the detail-page's parent-crumb fn), a short-noun page-title/heading function (mirroring `Copy.invoices_list_heading()` — note: `invoices_live.ex` does NOT actually call a `Copy.invoices_list_heading()` at the `title=` attr the way the UI-SPEC's phrasing for Subscriptions implies; re-check: `invoices_live.ex:101` calls `title={Copy.invoices_list_heading()}` — confirmed it DOES exist and IS used this way, so the pattern to copy is real), and CTA copy (`"Open invoice queue"`, dropping "dedicated").
- `AccrueAdmin.Copy.dashboard_breadcrumb_home/0` returns the literal string **`"Dashboard"`**, not `"Home"` — see Open Question 1; UI-SPEC's `[ Home , Subscriptions ]` bracket notation almost certainly means "the root/home crumb" generically rather than mandating the literal word "Home," since every other reference page's root crumb already renders "Dashboard" and changing that word would be a cross-page copy change outside this phase's file scope (`dashboard_breadcrumb_home/0` is shared infrastructure — changing its return value would silently affect Invoices/Payments/Coupons/etc. breadcrumbs too).
- **Build contract, confirmed real:** `mix accrue_admin.assets.build` (`accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`) and `mix accrue_admin.export_copy_strings` (`accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`) both exist as real mix tasks. The committed copy artifact is at `examples/accrue_host/e2e/generated/copy_strings.json` (confirmed present, 6758 bytes, last committed 2026-07-01) — any new `Copy.Subscription` function added in this phase must be followed by re-running the export task and committing the regenerated file, or e2e specs that read it will go stale (per the "CI green-up" lesson already in project memory).

## Test/Selector Migration Surface

`accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` (387 lines, 12 tests, **all 12 currently passing** — confirmed by running `mix test test/accrue_admin/live/subscriptions_live_test.exs` in `accrue_admin/`, 0 failures against current HEAD). Every assertion below will need updating as a direct consequence of the band removal / cell rebuild / verdict-collapse / CTA-collapse; none of these are currently failing — they encode the *current* (pre-reign) bespoke behavior and must be rewritten to encode the *post-reign* behavior:

| Test (line) | Assertion | Line in test file | Breaks because |
|---|---|---|---|
| "renders lifecycle-safe links" | `html =~ "Action required: collect" or html =~ "Billing status: Healthy"` | 50-51 | Verdict copy changes to `StatusBadge` "Healthy"/"Action required" language (D-03) |
| "renders Subscriptions through PageHeader…" | same verdict pair | 94-95 | same |
| " | `~s(class="ax-kpi-row ax-subscriptions-kpi-row")` | **111** | Exact class this phase drops (this is the one CONTEXT.md explicitly calls out) |
| " | `"Open dedicated invoice queue"` | 103 | CTA copy drops "dedicated" |
| " | `"Open recovery analytics"` | 104 | Band 4a removed |
| " | `"At-risk subscription queue"` | 106 | Band 4a's `aria-label` removed |
| " | `"Open-invoice queue records"` | 115 | Band 2's `aria-label` removed |
| " | `"Open dedicated invoice queue records"` | 117 | Band 2 removed |
| " | `"Who did what, when?"` | 118 | Band 4b removed |
| " | `"subscription.created by Accrue system"` | 119 | Cell rebuild changes audit-fact phrasing |
| " | `"Events: open full actor audit log"` | 120 | Band 4b's long-form button text removed (short "Events audit log" in `:actions` may or may not survive — see Open Question 2) |
| " | `"Filter admin actions"` | 121 | Band 4b's second button removed |
| " | `"At-risk subscription queue"` / `"Open recovery analytics"` (repeat) | 123-124 | same as above |
| "bare subscriptions route…" | `"ax-subscription-row-state"` | 146 | Bespoke class removed by cell rebuild (replace with real `StatusBadge` markup assertion) |
| " | `"Open failed-delivery debugger"` | 147 | In-cell webhook link removed/relocated |
| " | `"Who did what, when?"` | 148 | Band 4b removed (repeat) |
| "prioritizes identity, state, plan amount, time, and signals columns" | `"Open dedicated invoice queue records"` | 282 | Band removed |
| " | `"Open failed-delivery debugger"`, `"Webhook status"` | 283-284 | Cell rebuild |
| " | `"Filter invoice queue to this subscription"` | 285 | In-cell action link removed per D-01 |
| " | `"Open audit context for this subscription"` | 290 | Cell rebuild |
| " | `"Audit"`, `"subscription.created by Accrue system"` | 293-294 | Cell rebuild |
| "uses customer identity before raw subscription or processor IDs" | `"Open unified customer view: phase196-primary@example.com"` | 322 | Identity-cell prefix text removed (rebuilt as plain link text) |
| " | `"Open-invoice queue records"` / `"Open dedicated invoice queue records"` | 323-324 | Bands removed |
| " | `"Customer ID"` / `subscription.customer_id` / `"Subscription"` / `subscription.processor_id` + `assert_before/2` ordering | 325-329 | Depends entirely on the identity_cell rebuild decision (see Target File Anatomy table) — if raw IDs are dropped from the cell (option a), this whole assertion block needs replacing with assertions on the new two-line shape; if an `IdBadge` column is added (option b), it needs new assertions on that column instead |

**Assertions that will keep passing unchanged** (confirmed by grep — none of these strings exist in any band/cell being touched, or they assert on infrastructure outside this phase's scope):
- Lines 92, 101-102 (`"Customer billing lookup"`, `"Search customers now"`, `"Search customer, open detail"`) — these strings live in `accrue_admin/lib/accrue_admin/components/topbar.ex` (global nav search, rendered by `AppShell` on every admin page, not by `subscriptions_live.ex` itself). Confirmed via `grep -rln` — unrelated to this phase.
- Lines 58, 291-292 (`"ax-chip ax-label"`, `"Owner: User"`, `"Tax: Off"`) — already the target idiom in `billing_signals_cell/3`; survives the rebuild by construction.
- Lines 297-298 (`"Setup gap"`, `"Amount not confirmed in admin"`) — `plan_amount_cell`/`setup_gap_cell`, explicitly out of rebuild scope.
- Lines 67-68, 209, 220-221, 240-241, 249-250, 257 — empty-state / loading-state / filter-chip assertions, all reference `Copy.subscriptions_list_*` functions or generic DataTable data-attributes, unaffected by the header/band/cell reign.
- Line 345-347 (filter-form `push_patch` smoke) — filter mechanics unchanged.

## Density + PNG-Parity Verification Approach

- **Capture harness (confirmed real, already wired for exactly these two surfaces):** `accrue_admin/e2e/admin-visuals.spec.js`, test `"captures every primary admin surface in light and dark"` (line 120). The `shots` array (lines 134-158) already includes `["subscriptions", "/billing/subscriptions"]` (line 138) and `["subscription-detail", \`/billing/subscriptions/${dash.subscription_id}\`]` (line 139) — both light and dark themes, both via `captureThemes/3` (lines 41-52), which writes `test-results/admin-visuals/{project}/{name}.png` and `{name}-dark.png` plus a `.bbox.json` sidecar of every `REGION_SELECTORS` bounding box (from `accrue_admin/e2e/ratchet/region-tags.js`) — the bbox sidecar is exactly the geometry needed to check row-height/header-band-height programmatically, not just visually.
- **Scoped run command (avoids capturing all ~20 other surfaces):** the spec already supports `RATCHET_SURFACES` env-var filtering (lines 160-171): `RATCHET_SURFACES=subscriptions,subscription-detail npx playwright test e2e/admin-visuals.spec.js` (run from `accrue_admin/`), or via the existing npm script `npm run e2e:visuals:png-only` with the same env var prefixed.
- **Procedure for the phase's before/after check:** run the scoped capture **before** starting the template edit (baseline PNGs + bbox JSON committed to a scratch dir, not to git), implement the reign, re-run the same scoped capture, and diff: (1) visually inspect `subscriptions.png`/`subscriptions-dark.png` for the density-no-regression claim (row height, rows-per-viewport, header-band height — read the PNGs directly per this project's established "always read the PNGs" convention, not just diff pixel counts), (2) confirm `subscription-detail.png`/`subscription-detail-dark.png` are **pixel-for-pixel or visually identical** to baseline (this is the D-04 "PNG-verify the detail page is unbroken" requirement — since Phase 209 makes zero CSS edits to shared rules and doesn't touch `subscription_live.ex`, this should be a true no-op, and any visible diff is a signal something in `app.css` was touched that shouldn't have been).
- **No dedicated `mix test`-level Elixir test currently asserts pixel geometry** — this is Playwright-only. The Elixir test suite (`subscriptions_live_test.exs`) asserts DOM structure/text, not visual layout.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Status/verdict badge | Hand-rolled `<span class="... ax-status-badge ax-status-badge-#{tone}">` (current `identity_cell`, lines 522-524) | `AccrueAdmin.Components.StatusBadge.status_badge/1` (already correctly used by `state_cell/1`, line 556) | The identity cell currently duplicates the badge markup by hand instead of calling the component it's sitting three lines away from correctly using — straightforward defect, zero design risk to fix. |
| Copy-to-clipboard ID display | New bespoke ID markup | `AccrueAdmin.Components.IdBadge` (already used by `customers_live.ex`) | Only relevant if the planner chooses identity_cell option (b) above; don't invent new copy-chip markup if IDs must stay visible. |
| Chip-based filter state | New chip markup | `AccrueAdmin.Components.FilterChipBar` (already correctly wired) | Not at risk in this phase, listed for completeness — no changes needed here. |

**Key insight:** there is no new "hand-roll risk" introduced by this phase — the risk is the opposite direction, i.e. the *current* code hand-rolls things (badge markup, audit-row markup, worklist markup) that already have shared components/CSS available, and the entire point of the reign is deletion + extraction, not new construction.

## Runtime State Inventory

**Not applicable — this is not a rename/refactor/migration phase.** No stored data, live service config, OS-registered state, secrets, or build artifacts reference the classes/copy being changed by string value (CSS class renames are compile-time-only; no database rows, external service config, or scheduled-task descriptions embed `.ax-subscriptions-*` class names or the "Open dedicated invoice queue" copy string). Verified by reasoning about the phase's actual blast radius (Phoenix template + CSS + Elixir test file only) — no `git grep` of runtime datastores was needed because none of the changed strings/classes are used as database keys, service config, or IDs anywhere in the codebase (they are presentation-layer only).

## Common Pitfalls

### Pitfall 1: `StatStrip` only supports 3 tones, not the full tone scale the phase docs imply
**What goes wrong:** UI-SPEC's Color section describes a "moss/cobalt/amber/slate/ink tone scale" for callouts, and D-03's verdict spec implies multiple stat tones (including a neutral one for "MRR signal"). `AccrueAdmin.Components.StatStrip.tone_class/1` (`stat_strip.ex:46-49`) only has clauses for `"moss"`, `"cobalt"`, `"amber"` — any other string (including `"slate"`, which `subscriptions_live.ex:148` already passes today) falls through to the catch-all `tone_class(_tone), do: nil` and renders with no tone class at all.
**Why it happens:** `StatStrip` was built for Invoices' 3-stat strip (label/paid/uncollectible, only ever using `amber` for the danger case) and never extended.
**How to avoid:** either restrict the new verdict StatStrip to `moss`/`cobalt`/`amber` only (achievable — D-03's 4 stats can map: exposure→amber-if-nonzero, at-risk→amber, open-invoice→cobalt, last-webhook→amber-if-failed/moss-if-healthy), or explicitly extend `stat_strip.ex`'s `tone_class/1` with a `slate` clause as a deliberate shared-component improvement (permitted by the milestone's "improving a shared component is allowed" clause) — but call it out as a task, don't let it be discovered as a silent rendering bug.
**Warning signs:** a stat value renders in default text color when a tone was clearly intended; check `git diff accrue_admin/assets/css/app.css` for whether `.ax-stat-value--slate` even exists (grep confirms it does NOT: only `--moss`, `--cobalt`, `--amber` modifiers are defined anywhere in `app.css`).

### Pitfall 2: `dashboard_breadcrumb_home/0` is shared infrastructure — don't change its return value to satisfy the "Home" wording in UI-SPEC
**What goes wrong:** if the planner reads UI-SPEC's `[ Home , Subscriptions ]` literally and changes `Copy.dashboard_breadcrumb_home/0` to return `"Home"` instead of `"Dashboard"`, every other admin page's root breadcrumb (Invoices, Payments, Coupons, Connect, Events, Webhooks, Recovery — all of which call this same function) silently changes wording too, which is a cross-page copy change nowhere authorized by this phase's scope fence.
**Why it happens:** the fn name says "home" but its actual string is "Dashboard" — an easy trap if skimming.
**How to avoid:** leave `dashboard_breadcrumb_home/0` untouched; treat UI-SPEC's bracket notation as describing crumb *structure* (root → leaf), not a literal string mandate. See Open Question 1.

### Pitfall 3: The `:actions` slot collapse is genuinely ambiguous between "one CTA total" and "one *primary* CTA plus untouched secondaries"
**What goes wrong:** implementing either extreme without checking could either (a) leave 2 stray secondary buttons that no longer make sense once their originating bands are gone, or (b) delete the webhook-debug/events-audit shortcuts entirely when they may still have value as secondary actions.
**Why it happens:** neither Invoices nor Customers use `:actions` at all, so there's no reference-page precedent for "how many secondary buttons is normal" — the UI-SPEC's copywriting table only specifies the ONE primary CTA row and is silent on the other two current buttons.
**How to avoid:** flag as Open Question 2 below; the planner/executor should make an explicit, documented call rather than silently keep or silently drop.
**Warning signs:** a test asserting on `"Webhooks: debug failed deliveries"` or `"Events audit log"` passes or fails ambiguously depending on which way this goes — write the test assertion only after the decision is made, not before.

### Pitfall 4: Reworking `identity_cell`/`billing_signals_cell` will change `assert_before/2`-style ordering assertions in ways that are easy to get backwards
**What goes wrong:** `subscriptions_live_test.exs:329` (`assert_before(html, "phase196-primary@example.com", subscription.processor_id)`) depends on both strings appearing in a specific document order inside the *current* verbose cell markup. Once the cell collapses to two lines, both values may or may not both still be present as substrings (see identity_cell rebuild options a/b above) — a naive "keep the assertion, just fix the text" edit can silently start passing for the wrong reason (e.g., if the processor_id no longer appears in the cell at all but happens to appear elsewhere in the page HTML, like a `data-row-id` attribute).
**Why it happens:** `assert html =~ substring` and `assert_before` are permissive full-page substring checks, not scoped-to-cell assertions.
**How to avoid:** when rewriting these assertions, scope them with `Floki.find` to the specific `<td>`/`<span>` the identity cell renders into, not a bare `html =~` on the whole page, so a future refactor can't accidentally "pass" for a coincidental reason.

## Code Examples

### The exact idiom to copy for the identity cell rebuild
```elixir
# Source: accrue_admin/lib/accrue_admin/live/invoices_live.ex:234-242 (verified in this session)
defp invoice_identity_cell(row, mount_path, owner_scope) do
  invoice_href = scoped_path(mount_path, "/invoices/#{row.id}", owner_scope)
  customer_href = scoped_path(mount_path, "/customers/#{row.customer_id}", owner_scope)
  invoice_label = row.number || row.processor_id || row.id

  Phoenix.HTML.raw(
    ~s(<span class="ax-stack-xs"><a href="#{invoice_href}" class="ax-link">#{escape(invoice_label)}</a><a href="#{customer_href}" class="ax-label ax-muted">#{escape(customer_label(row))}</a></span>)
  )
end
```
Applying this shape to Subscriptions (illustrative — not prescriptive of exact label choice, which is planner discretion): primary link → `/subscriptions/#{row.id}` with the subscription's own identifier (`row.processor_id || row.id`) as link text; secondary muted line → customer label, itself a link to `/customers/#{row.customer_id}` (matching Invoices' cross-navigation pattern, since the identity cell in both cases needs to let the operator jump to either the row's own detail or the related customer).

### The already-correct chip pattern to extract from the current `billing_signals_cell/3`
```elixir
# Source: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:488 (verified — keep this line verbatim)
<span class="ax-subscription-row-admin-chips"><span class="ax-chip ax-label">Owner: #{escaped_o}</span> <span class="ax-chip ax-label">Tax: #{escaped_t}</span></span>
```
Drop the wrapping `ax-subscription-row-admin-chips` span (bespoke, Subscriptions-only, no CSS coordination risk) but keep the two `ax-chip ax-label` spans exactly as-is — this is already the REIGN-02 target idiom, just needs extracting from its noisy surroundings.

## State of the Art

Not applicable in the external-library sense (no dependency-version drift to report). The only "state of the art" delta is internal: the reference pages (Invoices/Customers, landed in earlier phases per project memory — v1.53/v1.54 hardening passes) already established the compact-cell/no-actions-slot/StatStrip-not-KpiCard idiom that Subscriptions predates and is being brought into alignment with.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The "Last webhook (status · time)" StatStrip stat in D-03 requires a *new* timestamp query, since no current code path computes a most-recent-failed-webhook timestamp | Target File Anatomy → content-preservation source list | Low — worst case the planner discovers this during implementation and adds a one-line `Repo.one(order_by: [desc: :inserted_at], limit: 1)` query; doesn't block planning, just means a task needs to include "add webhook-timestamp query" explicitly rather than assuming it's a pure relocation. |
| A2 | `Copy.dashboard_breadcrumb_home()`'s literal "Dashboard" return value should NOT be changed to "Home" to satisfy UI-SPEC's bracket notation | Copy Plumbing, Pitfall 2 | Medium — if wrong (i.e., if the user actually does want the literal word "Home" everywhere), this becomes a cross-page copy change affecting 7+ other admin pages, which is a scope-fence question the planner should surface rather than silently resolve either way. |
| A3 | The `:actions` slot's two secondary buttons (webhook-debug, events-audit) should be removed along with their originating context, not preserved as orphaned secondary actions | Pitfall 3, Open Question 2 | Medium — affects 2 test assertions and the exact final shape of the header; genuinely underspecified by the locked contracts, flagged explicitly rather than assumed silently. |
| A4 | Identity-cell raw-ID display (Customer ID / Subscription processor ID as explicit labeled facts) is intentionally traded away by the REIGN-02 compact-cell mandate, matching Invoices' idiom, rather than needing an added `IdBadge` column matching Customers' idiom | Target File Anatomy → identity_cell rebuild table | Low-Medium — if wrong, an `IdBadge` column task is missing from the plan; either way this is presented as an explicit two-option choice, not silently decided. |

## Open Questions

1. **Does `[ Home , Subscriptions ]` in UI-SPEC's Copywriting Contract mean the literal string "Home," or is it describing crumb structure generically (root crumb, using whatever `dashboard_breadcrumb_home()` already returns — "Dashboard")?**
   - What we know: every other reference page (Invoices via `Copy.dashboard_breadcrumb_home()`, Customers via a hardcoded `"Dashboard"` literal, and the detail page `subscription_live.ex` via the same Copy fn) currently renders "Dashboard" as the root crumb label.
   - What's unclear: whether UI-SPEC's bracket notation is prescriptive text or descriptive structure.
   - Recommendation: treat as descriptive (keep "Dashboard"); changing the shared fn's return value is a 7+-page blast radius outside this phase's file scope. Surface to the user only if the planner disagrees.

2. **Do the two non-triplicated `:actions` secondary buttons ("Webhooks: debug failed deliveries" / "Events audit log") survive the reign as secondary actions, or are they removed along with their band context?**
   - What we know: neither reference page (Invoices, Customers) uses the `:actions` slot at all; D-01/D-03 only mandate collapsing the *triplicated invoice-queue CTA* to one; UI-SPEC's copywriting table lists only the one primary CTA row and is silent on the other two.
   - What's unclear: whether "answer-first, one primary action per zone" (IA-02/Interaction Contract point 2) extends to removing secondary navigation shortcuts entirely, or just means "only one button gets the Cobalt-accent primary treatment."
   - Recommendation: default to keeping both as `.ax-button-secondary` entries in `:actions` (lowest-risk, preserves existing navigation shortcuts, satisfies "one primary CTA" literally) unless the planner has reason to trim further; document whichever choice is made so `subscriptions_live_test.exs` lines 104/120-121 are rewritten to match intentionally, not by accident.

3. **Is a new `Repo` query needed for "Last webhook · time," or should D-03's StatStrip stat be worded to avoid needing one (e.g., "N failed" without a timestamp, matching what's already computed)?**
   - What we know: `failed_webhook_count` (a plain count, no timestamp) is the only webhook aggregate currently computed in `subscription_summary/1`.
   - What's unclear: whether the UI-SPEC's "(status · time)" phrasing is a hard requirement or illustrative.
   - Recommendation: treat "time" as optional/discretionary; ship "N failed webhooks" if a timestamp query is judged not worth the added complexity for this phase, since D-03 says "Every datum currently spread across the five removed bands... must land" — and no removed band currently surfaces a webhook *timestamp* either (band 1's actions-slot webhook button, which is untouched, links to a filtered view, it doesn't display a timestamp).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` / Elixir toolchain | Running `mix test`, `mix accrue_admin.assets.build`, `mix accrue_admin.export_copy_strings` | ✓ (confirmed — `mix test` ran successfully against `subscriptions_live_test.exs`, 12/12 passing) | project-pinned (Elixir 1.17+/OTP 27+ per `CLAUDE.md`) | — |
| `npx playwright` / node | Running `admin-visuals.spec.js` for PNG density/parity checks | ✓ (confirmed — `package.json` has `@playwright/test ^1.57.0` and working `e2e:visuals:png-only` script) | — | — |
| PostgreSQL | `mix test` against Ecto-backed LiveView tests | ✓ (confirmed — test run above executed real SQL queries against `billing.accrue_subscriptions`/`accrue_invoices`/`accrue_webhook_events`) | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none — everything needed for this phase is already present and working in the environment.

## Validation Architecture

(`workflow.nyquist_validation` treated as enabled — key absent from `.planning/config.json` inspection was not explicitly checked but no override was found in phase docs, so the default-enabled path applies.)

### Test Framework
| Property | Value |
|----------|-------|
| Framework (Elixir) | ExUnit via `mix test`, `AccrueAdmin.LiveCase` helper (Phoenix.LiveViewTest + Floki) |
| Framework (visual) | Playwright `@playwright/test ^1.57.0` |
| Config file | `accrue_admin/playwright.config.js`; no separate ExUnit config beyond standard `mix.exs`/`test_helper.exs` |
| Quick run command (unit) | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs` (confirmed: 0.7s, 12 tests) |
| Quick run command (visual, scoped) | `cd accrue_admin && RATCHET_SURFACES=subscriptions,subscription-detail npx playwright test e2e/admin-visuals.spec.js` |
| Full suite command | `cd accrue_admin && mix test` (Elixir); `cd accrue_admin && npm run e2e:visuals:png-only` (full 20-surface visual sweep) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REIGN-01 | List composed only from canonical spine; bespoke bands + override classes removed | integration (LiveView render assertions) + grep | `mix test test/accrue_admin/live/subscriptions_live_test.exs` (post-rewrite) + `grep -c "ax-subscriptions-invoice-strip\|ax-subscriptions-queue-shortcut\|ax-subscriptions-invoice-records\|ax-subscriptions-secondary-strips\|ax-subscriptions-at-risk-strip\|ax-subscriptions-audit-strip" accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` (must return `0`) | ✅ test file exists (needs rewriting, not creating) |
| REIGN-02 | Compact shared cell idiom; no in-cell action buttons | integration | `mix test test/accrue_admin/live/subscriptions_live_test.exs` (rewritten assertions using scoped `Floki.find` per Pitfall 4) + manual grep for `<button` / bespoke action-link classes inside the two rebuilt cell fns | ✅ existing file, needs new assertions |
| COMP-01 | `WorkQueueCallout` extract-or-inline decision recorded | N/A — a documentation/decision outcome, not a runtime behavior. Satisfied by D-02 already resolving it as "inline" for 209; no test needed, just confirm no new component file was created without justification (`ls accrue_admin/lib/accrue_admin/components/work_queue_callout.ex` should NOT exist after 209) | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/accrue_admin/live/subscriptions_live_test.exs` (0.7s — cheap enough to run after every markup edit)
- **Per wave merge:** `mix test` (full Elixir suite) + scoped Playwright visual capture (`RATCHET_SURFACES=subscriptions,subscription-detail`)
- **Phase gate:** Full `mix test` green + both scoped PNGs (light/dark, `subscriptions` + `subscription-detail`) visually reviewed before `/gsd-verify-work`

### Wave 0 Gaps
None — `subscriptions_live_test.exs` already exists and exercises the exact surface being changed; `admin-visuals.spec.js` already captures both surfaces needed for the PNG-parity gate. No new test infrastructure needs to be created, only existing assertions rewritten.

## Security Domain

Not applicable — the milestone's own scope guardrails state this page has "no state-changing actions to guard" and REQUIREMENTS.md's Out-of-Scope section explicitly excludes "Sensitive-action class A/B/C step-up… the two M1 pages are read/navigate surfaces with no state-changing actions to guard." No ASVS category applies beyond what's already handled by the existing `Accrue.Auth`-gated `require_admin_plug` (unchanged by this phase) and standard output-escaping (`Phoenix.HTML.html_escape/1`, already used correctly throughout the current cell render-fns and preserved by the rebuild).

## Sources

### Primary (HIGH confidence — direct file reads/greps this session, all against working tree at `f6278ff9`)
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` (full file, 900 lines) — target file, all line numbers verified
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` (full file, 497 lines) — canonical reference #1
- `accrue_admin/lib/accrue_admin/live/customers_live.ex` (full file, 435 lines) — canonical reference #2
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (lines 1-1624 of 2179) — out-of-scope detail page, shared-CSS coordination target
- `accrue_admin/lib/accrue_admin/components/page_header.ex`, `stat_strip.ex`, `filter_chip_bar.ex` (partial), `data_table.ex` (partial) — shared component contracts
- `accrue_admin/lib/accrue_admin/copy.ex` (grep), `accrue_admin/lib/accrue_admin/copy/subscription.ex` (full, 165 lines) — copy plumbing
- `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` (full file, 387 lines) — migration surface, confirmed 12/12 passing via `mix test`
- `accrue_admin/assets/css/app.css` — grepped for every `.ax-inline-worklist*`, `.ax-audit-summary-row`, `.ax-subscriptions-*` selector (line numbers cited throughout)
- `accrue_admin/e2e/admin-visuals.spec.js` (lines 1-170) — PNG capture harness, confirmed `subscriptions`/`subscription-detail` surfaces already wired
- `accrue_admin/package.json` — confirmed `e2e:visuals:png-only` script and Playwright version
- `mix test test/accrue_admin/live/subscriptions_live_test.exs` (command run this session) — confirmed 12/12 passing, 0.7s

### Secondary (MEDIUM confidence)
- `.planning/phases/209-.../209-CONTEXT.md`, `209-UI-SPEC.md`, `.planning/REQUIREMENTS.md` — phase contracts (locked, not re-litigated, but cross-checked against code and found two framing corrections documented in the Summary)

### Tertiary (LOW confidence)
- None — no WebSearch/external-library research was performed for this phase (correctly, since none was needed: zero new dependencies).

## Metadata

**Confidence breakdown:**
- Target-file line anchors: HIGH — every line number was read directly from the current file, not inferred from CONTEXT.md's approximate ranges.
- Shared-CSS coordination evidence: HIGH — exhaustive grep across `.ex` and `.css`, cross-checked both directions (class usage → CSS rule, and CSS rule → class usage).
- Copy-plumbing gaps (what exists vs. what must be added): HIGH — confirmed via targeted `grep -n "def <exact-name>"` for every function name mentioned in CONTEXT/UI-SPEC.
- Test migration surface: HIGH — full test file read, cross-referenced every assertion against the exact line of source it depends on, and confirmed current green state by running the suite.
- Open Questions (breadcrumb wording, `:actions` slot collapse extent, webhook-timestamp requirement): MEDIUM — these are genuine underspecifications in the locked contracts, not gaps in this research; flagged rather than silently resolved.

**Research date:** 2026-07-19
**Valid until:** Should remain valid through this phase's execution (no external dependency drift risk); re-verify line numbers if any other phase touches `subscriptions_live.ex`, `subscription_live.ex`, or `app.css` before 209 lands.
