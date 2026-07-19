# Architecture Research

**Domain:** `accrue_admin` LiveView admin UI — M1 IA/grammar pivot integration (v1.57, SEED-004 M1)
**Researched:** 2026-07-19
**Confidence:** HIGH (grounded in direct reads of the real modules; no external sources needed)

## Scope of this document

This is **integration architecture**, not greenfield architecture. The admin already has a canonical page skeleton the "good" pages (Payments/Charges, Invoices, Customers) follow. M1 reigns the two outliers — **Home** (`DashboardLive`) and **Subscriptions** (`SubscriptionsLive`) — onto that skeleton and retires ~325 bespoke CSS rules. This maps: (a) the canonical skeleton + shared component APIs, (b) Subscriptions new-vs-modified, (c) Home new-vs-modified, (d) the grep-gated CSS retirement (with detail-page sharing), (e) build order and where the IA-trim decisions live.

All findings are grounded in these real files:
- Canonical: `lib/accrue_admin/live/{charges_live,invoices_live,customers_live}.ex`
- Targets: `lib/accrue_admin/live/{dashboard_live,subscriptions_live}.ex`
- Components: `lib/accrue_admin/components/{page_header,stat_strip,data_table,filter_chip_bar,button,status_badge,empty_state,kpi_card}.ex`
- Bundle: `lib/accrue_admin/assets.ex`, `lib/mix/tasks/accrue_admin.assets.build.ex`, `assets/css/app.css`

---

## Standard Architecture

### The canonical page skeleton (Charges / Invoices / Customers)

Every good list page renders this exact spine (verbatim shape from `charges_live.ex` / `invoices_live.ex` / `customers_live.ex`):

```
AppShell.app_shell (brand, current_path, mount_path, theme, owner_scope, org name)
└── <section class="ax-page">                    ← NO bespoke page-level classes
    ├── PageHeader.page_header
    │     breadcrumbs=[home, <this page>]         ← 2 crumbs, real parent only
    │     title={Copy.<page>_heading()}           ← short noun, NOT a sentence
    │     <:description>  <p class="ax-body">…</p>
    │     <:stat_strip>   <StatStrip.stat_strip>…</StatStrip>   ← plain, unwrapped
    │     <:filter_toolbar> <DataTable.filter_toolbar …/>
    ├── FlashGroup.flash_group
    └── <.live_component module={DataTable} …>
          columns=[%{label, render: &cell/1}, …]  ← compact cell renderers
          card_title=&…/1  card_fields=[…]
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar items={work_queue_chips(…)} …/>
          </:list_status>
```

There is **nothing between `FlashGroup` and the `DataTable`** on a canonical page. The default lens ("failed" / "open,uncollectible" / etc.) + "All one click away" is expressed entirely through `work_queue_chips/2` inside the DataTable's `:list_status` slot — not through extra band `<section>`s.

### Component Responsibilities (shared vocabulary the two pages must adopt)

| Component | API surface (attrs / slots) | Responsibility |
|-----------|------------------------------|----------------|
| `AppShell.app_shell` | `brand, current_path, mount_path, page_title, theme, current_owner_scope, active_organization_name` | Sidebar + topbar chrome. Already used by both targets. |
| `PageHeader.page_header` | attrs `breadcrumbs` (req), `title` (req), `heading_id`, `class`, `component_group`; slots `:description`, `:stat_strip`, `:actions`, `:filter_toolbar` | Breadcrumb + `h1.ax-display` title + bounded caller slots. **`:actions` slot already exists** — Home hand-rolls its own `<header>` instead of using this. |
| `StatStrip.stat_strip` | attr `label` (req); `:stat` slot with `label, value, tone (moss\|cobalt\|amber), href` | Quiet inline `<dl>` metric strip above the table. Tone colors the value only; `href` wraps the pair in a link. |
| `DataTable` (live_component) | `query_module, columns, card_title, card_fields, params, path, list_state, empty_*`, `:list_status` slot | Stateful list: query, cursor paging, table→card degradation, empty/loading states, filter toolbar. Cell renderers are `fn row -> iodata \| Phoenix.HTML.raw`. |
| `FilterChipBar.filter_chip_bar` | `items, label, result_count, result_label, clear_all_href, clear_all_label` | Renders lens/filter chips; each item `%{id, label, value, tone, active, href \| remove_href}`. Lives in DataTable `:list_status`. |
| `Button.button` | `variant (primary\|secondary\|ghost\|danger), href, type, disabled, loading, class`; `:inner_block` | Canonical action affordance (renders `<a>` or `<button>`). **Neither target uses it** — both hand-write `<a class="ax-button ax-button-primary ax-button-sm …">`. |
| `StatusBadge.status_badge` | `status, label, tone` | Semantic dot+label badge with fixed palette mapping. Subscriptions uses it in one cell but hand-rolls the badge markup in another. |
| `EmptyState.empty_state` | `icon, title, body`; `:actions` slot | Non-interactive empty hero (`cursor: default`). Home hand-rolls `.ax-empty` for its attention-empty. |
| `KpiCard.kpi_card` | `label, value, delta, delta_tone, href, aria_label`; `:meta`, `:sparkline` slots | Full-card-linkable KPI. Home already uses it correctly for Zone 3. |
| `Timeline.timeline` | `label, empty_label, items` | Recent-activity list. Home already uses it correctly for Zone 4. |
| `Icon.icon` | `name, size, class` | Heroicon set. Both targets use it. |

**Design implication for M1:** the shared vocabulary is *complete enough* to compose both pages. The milestone constraint ("reuse as-is, compose don't fork; one small new shared component only if a work-queue callout shape clearly repeats") is well-founded — the only plausible gap is a repeated "work-queue callout / attention-row" shape (see §Integration Points).

---

## Recommended Project Structure

No new files or directories. M1 is edits-in-place plus a bundle rebuild:

```
accrue_admin/
├── lib/accrue_admin/live/
│   ├── subscriptions_live.ex     # MODIFY: drop override classes, trim bands, rebuild cells
│   └── dashboard_live.ex         # MODIFY: adopt PageHeader, recompose zones from ax-card+Button+Icon
├── lib/accrue_admin/components/
│   └── (optional) work_queue_callout.ex   # NEW — only if the callout shape repeats (§Integration Points)
├── assets/css/app.css            # MODIFY: grep-gated deletion of retired rules
└── priv/static/accrue_admin.css  # REBUILD + COMMIT via `mix accrue_admin.assets.build`
```

### Structure Rationale
- **`ax-*` stays the styling SSOT.** Tailwind is only a compile-time minifier in `assets.build`; no raw utility authoring. (PROJECT.md constraint + `assets.build.ex` confirms `tailwindcss --input assets/css/app.css --output priv/static/accrue_admin.css --minify`.)
- **`priv/static/accrue_admin.css` is embedded at compile time.** `Assets` reads it with `File.read!` under `@external_resource` and serves it md5-hashed. Source CSS edits ship **nothing** until the bundle is rebuilt and committed (this exact trap shipped dead CSS in Phase 189).

---

## Architectural Patterns

### Pattern 1: "Canonical spine, caller-owned content" (the target grammar)

**What:** `<section class="ax-page">` → `PageHeader` → `FlashGroup` → `DataTable`. The header owns chrome; the caller owns breadcrumbs, title, stats, filters, and cell renderers via slots/attrs. No band `<section>`s between flash and table.

**When:** Both target list surfaces. Subscriptions is a list page → this is a near-drop-in. Home is an overview page → it keeps Zones 2–4 (launchers/KPIs/activity) below the header but adopts `PageHeader` for the header itself.

**Trade-off:** Consolidating five Subscriptions bands into the header's `:stat_strip`/`:actions` + one lens row is the highest-value / highest-visible-change move; it directly resolves the round-99 findings (triple-repeated primary action, buried table, padding bloat).

### Pattern 2: Compact cell renderer idiom

**What:** Good-page cells return either a bare string (`&status_summary/1` → `"Succeeded"`) or a *small* raw snippet:

```elixir
# charges_live.ex / invoices_live.ex idiom — tight, 1–2 lines
defp payment_identity_cell(row, mount, scope) do
  Phoenix.HTML.raw(
    ~s(<span class="ax-stack-xs"><a href="#{href}" class="ax-link">#{label}</a>) <>
    ~s(<a href="#{cust}" class="ax-label ax-muted">#{cust_label}</a></span>))
end
defp billing_signals_cell(row) do
  Phoenix.HTML.raw(~s(<span class="ax-chip ax-label">#{owner}</span> <span class="ax-chip ax-label">#{tax}</span>))
end
```

Vocabulary: `ax-stack-xs`, `ax-link`, `ax-label`, `ax-muted`, `ax-chip`, and `StatusBadge` for state.

**Contrast (what Subscriptions does today — the anti-pattern to remove):** `identity_cell/3` and `billing_signals_cell/3` emit 15–20 line multi-block raw HTML strings full of bespoke classes (`ax-subscription-row-primary-line`, `-customer-scope`, `-meta-grid`, `-meta`, `-id`, `-invoice-controls`, `-signal-primary/-secondary`, `-admin-chips`, `ax-webhook-row-status`, `ax-audit-fact`) with **inline action buttons inside table cells** ("Work open invoices", "Send reminder"). This both fights the density findings and violates the "no destructive/complex actions inline in tables" grammar.

**When:** Rebuild all Subscriptions column + card renderers to identity/state(=StatusBadge)/plan-amount/time/signals-as-chips. Push the per-row action buttons out of the cell (to detail, out of M1 scope) or reduce to a single quiet `ax-link`.

### Pattern 3: Lens model via chips, not bands

**What:** Default work-queue + "All" is one `work_queue_chips/2` list rendered in DataTable's `:list_status`. Subscriptions already has this (`status: "past_due,canceling"` default + "All" chip + "Open invoice queue workspace" chip). The IA fix is to *stop duplicating* that queue state as separate `.ax-inline-worklist` band sections above the table.

**Trade-off:** The "Open dedicated invoice queue" primary action currently appears **3×** (header actions, invoice-strip band, invoice-records band) — a confirmed round-99 finding. Canonical grammar = it appears **once** (PageHeader `:actions`), with the queue count surfaced as a StatStrip stat + a chip.

---

## Data Flow

Unchanged by M1 — this is a presentation pivot. Both targets keep their existing `mount/3` → summary/stats queries → `handle_params` default-lens push_patch → `render/1`. The Subscriptions extra query `open_invoice_queue/1` (top-3 invoices for the `.ax-subscriptions-invoice-records` band) becomes **dead code** once that band is trimmed and should be removed with it.

```
mount → summary/stats (Repo aggregates)         [KEEP]
handle_params → default lens push_patch          [KEEP]
render → skeleton compose                        [REWRITE presentation only]
```

---

## Page-by-page integration

### (b) Subscriptions — ~90% on the skeleton: what's NEW vs MODIFIED

Already imports the full vocabulary (`AppShell, DataTable, FilterChipBar, FlashGroup, PageHeader, StatStrip`, plus `StatusBadge`) and already uses `PageHeader` + `StatStrip` + `DataTable` + `FilterChipBar`. **Nothing new is needed; everything is a MODIFY.**

| Deviation from canonical (real, line-cited) | Fix |
|---|---|
| `<section class="ax-page ax-page-compact ax-subscriptions-page">` (L98) | Drop `ax-page-compact ax-subscriptions-page` → plain `ax-page`. |
| `PageHeader class="ax-page-header-compact ax-subscriptions-header"` (L100) | Drop the override classes. |
| Title is a full sentence: `subscriptions_health_verdict/1` → `"Action required: collect N open invoices…"` (L108, L542) | Short noun title ("Subscriptions") + one health verdict expressed via StatStrip/status; resolves "title competes with banner" finding. |
| Breadcrumb parent `"Billing health overview"` links to a page that doesn't exist (L102–107; round-99 finding) | Use real 2-crumb `[home, "Subscriptions"]` like canonical. |
| `:actions` uses raw `<a class="ax-button ax-button-primary ax-button-sm ax-subscriptions-*-workspace">` ×3 (L116–140) | Use `Button.button` (or plain canonical `ax-button` classes) — **one** primary action, drop `-workspace` bespoke classes + "workspace" jargon (round-99 finding). |
| StatStrip wrapped in `<div class="ax-kpi-row ax-subscriptions-kpi-row">` (L143) | Unwrap — pass `StatStrip` directly into `:stat_strip` like canonical. |
| **Five bespoke band `<section>`s between Flash and DataTable** (L196–279): `.ax-inline-worklist.ax-subscriptions-invoice-strip`, `.ax-subscriptions-queue-shortcut`, `.ax-inline-worklist.ax-subscriptions-invoice-records`, then `.ax-subscriptions-secondary-strips` wrapping `-at-risk-strip` + `-audit-strip` | **Trim to zero** (or ≤1 canonical callout). This is the core IA-trim: redundant bands duplicate the lens/actions and push the table below the fold. |
| `identity_cell/3` + `billing_signals_cell/3` emit huge `.ax-subscription-row-*` / `.ax-webhook-row-status` / `.ax-subscription-setup-gap` raw HTML with inline action buttons (L451–494, L501–538, L603–611) | **Rebuild to the compact idiom** (Pattern 2): identity via `ax-stack-xs`+`ax-link`, state via `StatusBadge` (already used by `state_cell/1` — reuse it), signals via `ax-chip`, remove in-cell action buttons. |
| `open_invoice_queue/1` query feeding the trimmed records band (L53, L407–449) | Delete with the band (dead code). |

**New shared components for Subscriptions:** none.

### (c) Home (`DashboardLive`) — hand-rolls its header; no shared component for its unique zones

Home is the bigger lift. It does **not** use `PageHeader`; it hand-writes `<header class="ax-page-header ax-page-header-compact">` with `Breadcrumbs` directly (L53–104), and its two signature zones (attention rail, launcher tiles) have **no shared component** — they are pure bespoke CSS.

| Zone | Today | M1 target |
|---|---|---|
| Header (L52–104) | Hand-rolled `<header>` + `Breadcrumbs` + `.ax-dashboard-title-row` + `.ax-home-header-health.ax-health-summary` + `.ax-page-actions` with 5 raw `.ax-home-*-action` buttons | Adopt `PageHeader.page_header` (breadcrumbs + title + `:description` + `:actions` using `Button`+`Icon`). One health verdict in title/description, one primary action first (round-99: health is "buried in dense red/orange blocks"). |
| Zone 1 attention rail (L106–143) | `.ax-attention-summary` + `.ax-card.ax-attention` with `.ax-attention-row/-priority/-dot/-text/-pill/-action`; empty via hand-rolled `.ax-empty` | Compose from `.ax-card` + `StatusBadge` (tone/priority) + `Button`/`ax-link` + `Icon`. Empty → `EmptyState.empty_state`. **Candidate for the one allowed new component** if this row shape matches a Subscriptions callout. |
| "Find one customer" strip (L145–159) | `.ax-home-customer-search-strip` (round-99: "buried at the very bottom") | Fold into PageHeader `:actions` (command-palette trigger button) — it's already duplicated there; drop the redundant strip. |
| Zone 2 launcher tiles (L161–221) | `.ax-launchers` grid of `.ax-launcher*` (`-icon/-title/-action/-meta/-health/-copy`) | Compose tiles from `.ax-card` + `Icon` + `Button`/`ax-link`. This is the largest bespoke set to retire. |
| Zone 3 KPIs (L223–276) | `KpiCard` in `.ax-kpi-grid` | Already canonical — **keep as-is.** |
| Zone 4 recent activity (L278–360) | `Timeline` in `.ax-card` | Already canonical — **keep** (may trim `.ax-dashboard-audit-summary` / `.ax-audit-summary-row` shims). |

**New shared components for Home:** at most **one** — a "work-queue callout / attention-row" if that shape is shared with the trimmed Subscriptions worklist (decide during Subscriptions build; see build order).

---

## (d) CSS retirement — grep-gated, with a detail-page sharing hazard

Rule counts in `assets/css/app.css` (selectors containing each prefix):

| Prefix | Rules | Owner page(s) in source | Safe to delete? |
|---|---:|---|---|
| `.ax-home*` | 38 | dashboard only | Yes (after Home rebuild) |
| `.ax-launcher*` | 37 | dashboard only | Yes |
| `.ax-attention*` | 43 | dashboard only | Yes |
| `.ax-health-summary*` | 7 | dashboard only | Yes |
| `.ax-subscriptions-*` | 146 | subscriptions LIST only | Yes |
| `.ax-subscription-row*` | 41 | subscriptions LIST only | Yes |
| `.ax-subscription-setup*` | 4 | subscriptions LIST only | Yes |
| `.ax-inline-worklist*` | 20 | **subscriptions LIST + subscription DETAIL** | **GATED** |
| `.ax-audit-summary*` | 7 | **dashboard + subscriptions LIST + subscription DETAIL** | **GATED** |

Sum of the clearly-retirable sets ≈ **325 rules** (38+37+43+146+41+20 ≈ 325), matching the milestone estimate.

**The hazard (must be flagged to the roadmapper):** `subscription_live.ex` — the subscription **DETAIL** page, which is **out of M1 scope** — still references these exact classes:
- `.ax-inline-worklist`
- `.ax-inline-worklist-copy`
- `.ax-audit-summary-row`

(Confirmed by grep: `ax-inline-worklist` and `ax-audit-summary` each resolve to `subscription_live.ex` in addition to the in-scope pages.) Deleting those CSS rules wholesale would silently break the out-of-scope detail page's styling — a change **invisible to source-text CI gates** (the classes still exist in that template; only the CSS vanishes).

**Retirement protocol (grep-gate):** for every candidate class, `grep -r "<class>" accrue_admin/lib` across the whole tree; delete the CSS rule **only if zero `.ex` references remain** after the two target pages are rebuilt. Concretely: `.ax-inline-worklist`, `.ax-inline-worklist-copy`, and `.ax-audit-summary-row` are **retained**; the LIST-only siblings (`.ax-inline-worklist-actions`, `.ax-subscriptions-*`, `.ax-subscription-row-*`, `.ax-audit-fact`, dashboard-only `.ax-audit-summary` variants) are removed. A cheap automated guard: a test/script asserting no orphan `ax-*` class in `app.css` lacks a source reference, and no source `ax-*` class lacks a CSS rule.

---

## (e) Build order and where IA-trim decisions live

**Recommended order: Subscriptions first, then Home.** Justification:
1. **Closest to canonical** — Subscriptions already imports and uses the entire shared vocabulary; it is override-drop + cell-rebuild + band-trim, not a from-scratch compose. Lower risk, fast coherence win.
2. **It surfaces the one-new-component decision** — the milestone allows a single new shared "work-queue callout" component *only if the shape repeats*. Trimming Subscriptions' five bands to a canonical callout reveals whether that shape is real and reusable **before** Home's attention rail needs to consume it. Building Home first would force the decision blind.
3. **Home is the larger lift** — it needs full `PageHeader` adoption plus recomposition of two zones (attention rail, launchers) that have no shared component today; doing it second lets it reuse anything Subscriptions establishes.

**Where the IA-trim decisions live (for the roadmapper / planner):**
- **Which bands survive:** in `subscriptions_live.ex` `render/1` (delete band `<section>`s L196–279) and the coupled query `open_invoice_queue/1`.
- **One-verdict / one-primary-action:** in each page's `render/1` header block + the `*_health_verdict` / `attention_*` helper functions (title string + `:actions` slot contents).
- **Cell density:** in the Subscriptions `identity_cell/3`, `billing_signals_cell/3`, `plan_amount_cell/1`, `state_cell/1`, `setup_gap_cell/2` renderers.
- **Round-99 findings mapping:** `.planning/research/admin-ratchet-round99-confirmed-findings.json` (31 entries; `surface` ∈ {subscriptions, dashboard, subscription-detail, component-kitchen}). The subscriptions + dashboard entries are the M1 acceptance checklist; the `subscription-detail` entries are **explicitly M-later** (out of scope but adjacent — do not fix the detail page in M1).

### Ship mechanics (per edit cycle)
```
1. Edit lib/accrue_admin/live/{subscriptions,dashboard}_live.ex  (+ optional new component)
2. Edit assets/css/app.css  (grep-gated deletions only)
3. mix accrue_admin.assets.build        # tailwind minify → priv/static/accrue_admin.css ; esbuild → .js
4. COMMIT priv/static/accrue_admin.css  # embedded via Assets @external_resource + File.read!; nothing ships otherwise
5. PNG-verify against canonical Payments/Customers/Invoices reference (Playwright)
```

---

## Anti-Patterns (specific to this pivot)

### Anti-Pattern 1: Editing `app.css` without rebuilding the bundle
**What people do:** Change source CSS, run tests, ship. **Why it's wrong:** `Assets` embeds `priv/static/accrue_admin.css` at compile time; source `app.css` is inert until `mix accrue_admin.assets.build` regenerates and you commit the bundle. Phase 189 shipped dead CSS this way. **Instead:** always rebuild + commit the bundle in the same change.

### Anti-Pattern 2: Blind prefix-delete of retired CSS
**What people do:** `sed`-delete every `.ax-inline-worklist*` / `.ax-audit-summary*` rule. **Why it's wrong:** the out-of-scope subscription **detail** page still uses `.ax-inline-worklist`, `.ax-inline-worklist-copy`, `.ax-audit-summary-row`; source-text CI stays green while the detail page's styling silently breaks. **Instead:** grep-gate each class against the whole `lib/` tree; retain shared classes.

### Anti-Pattern 3: Actions and destructive controls inside table cells
**What people do:** Keep the "Work open invoices" / "Send reminder" buttons inside Subscriptions row cells. **Why it's wrong:** violates the operator grammar (actions belong to detail/modals, not scannable rows) and fights the density findings. **Instead:** compact identity/state/signals cells; single quiet link out.

### Anti-Pattern 4: Re-forking new bespoke classes to "make it look designed"
**What people do:** Replace `.ax-launcher*` with `.ax-home-tile*`. **Why it's wrong:** the milestone's whole point is convergence onto the shared vocabulary; a rename is not a retire. **Instead:** compose from `.ax-card` + `Button` + `Icon` + `StatusBadge`; introduce **at most one** genuinely-shared new component (the work-queue callout) and only if the shape repeats.

---

## Integration Points

### Internal boundaries

| Boundary | Communication | Notes / gotchas |
|---|---|---|
| Target pages ↔ shared components | HEEx slots/attrs (compile-time) | `PageHeader` already exposes `:actions` — Home just isn't using it. Zero component API changes needed for M1 unless the new callout is added. |
| `app.css` (source) ↔ `priv/static/accrue_admin.css` (served) | `mix accrue_admin.assets.build` (tailwind `--minify`) → committed bundle → `Assets` `@external_resource`/`File.read!` embed | Must rebuild+commit; hashed/immutable serving means stale bundle = stale UI. |
| In-scope LIST pages ↔ out-of-scope DETAIL page | Shared `ax-*` CSS classes only | The `.ax-inline-worklist*` / `.ax-audit-summary-row` sharing is the retirement hazard; grep-gate. |
| M1 output ↔ parked v1.56 ratchet | `accrue_admin/e2e/ratchet/` baseline + Playwright selectors | The ratchet re-locks the redesign *after* M1. Expect e2e selectors keyed on retired classes / `data-ax-zone` / `data-phase19x` attrs to need updating when bands/cells change; treat selector churn as part of M1, and refresh the ratchet baseline post-M1 (not during). |
| One new shared component (conditional) | New `components/*.ex` | Allowed **only** if the work-queue callout shape is shared between Home's attention rail and Subscriptions' consolidated worklist. Decide during Subscriptions build. |

### Candidate new component: `WorkQueueCallout` (conditional)
If, after trimming Subscriptions to one canonical worklist callout, that callout's shape (title + count/exposure + one primary action, danger/warn tone) matches Home's attention-rail row shape, extract a single `AccrueAdmin.Components.WorkQueueCallout` composed from `.ax-card` + `StatusBadge` + `Button` + `Icon`. If the shapes diverge, compose both inline from primitives and add no new component (favor the milestone's "compose, don't fork" default).

---

## Scaling / risk notes

Not a scaling problem — data volume is unchanged. The "what breaks first" risks are:
1. **Bundle staleness** (Anti-Pattern 1) — highest-frequency footgun.
2. **Detail-page CSS breakage** via blind delete (Anti-Pattern 2) — highest-severity silent regression, invisible to source-text gates.
3. **E2E/ratchet selector churn** — retired classes and removed bands will break `accrue_admin/e2e` selectors and the parked ratchet baseline; budget selector updates and a post-M1 ratchet re-freeze.

---

## Sources

- Direct reads (HIGH confidence, 2026-07-19): `lib/accrue_admin/live/{charges,invoices,customers,subscriptions,dashboard}_live.ex`; `lib/accrue_admin/live/subscription_live.ex` (detail, for sharing check); `lib/accrue_admin/components/{page_header,stat_strip,data_table,filter_chip_bar,button,status_badge,empty_state,kpi_card}.ex`; `lib/accrue_admin/assets.ex`; `lib/mix/tasks/accrue_admin.assets.build.ex`; `assets/css/app.css` (rule counts via grep).
- Grep-verified sharing: `.ax-inline-worklist*` and `.ax-audit-summary*` referenced by `subscription_live.ex` (out of scope) in addition to the M1 targets.
- Findings: `.planning/research/admin-ratchet-round99-confirmed-findings.json` (31 confirmed; subscriptions/dashboard entries = M1 checklist, subscription-detail entries = out of scope).
- Context: `.planning/PROJECT.md` (v1.57 M1 scope/constraints), `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` (§9 M1 decomposition, §6 posture, `ax-*` SSOT).

---
*Architecture research for: accrue_admin M1 IA/grammar pivot (v1.57 SEED-004 M1)*
*Researched: 2026-07-19*
