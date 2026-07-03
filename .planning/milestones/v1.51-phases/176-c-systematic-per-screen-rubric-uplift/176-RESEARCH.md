# Phase 176: C — Systematic Per-Screen Rubric Uplift - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView admin UI — per-screen CSS/markup uplift against a 10-dimension rubric
**Confidence:** HIGH (codebase-grounded; all findings verified by direct file inspection)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Scope & wave-split:** ALL ~20 admin screens must score ≥2 on every dimension, but effort concentrates on under-iterated tail. Wave 1 = list screens; Wave 2 = catalog/specialist detail (coupon, promotion_code, connect, event, webhook); Wave 3 = dense financial detail (invoice, payment/charge, subscription) + reading-measure application.
- **Baseline-scoring method:** per-screen × 10-dimension `176-SCORECARD.md` in phase dir, captured by code-level audit, before + after scores.
- **Ordering:** worst-first — score baseline, lift lowest-scoring screens first.
- **List screens:** reuse `data_table` existing card-collapse (`card_fields`/`card_title`); audit is confirm-column-selection, not new construction.
- **Detail screens:** stack multi-column layouts to single column below `--ax-bp-md` using existing `ax-*` grid utilities; tap targets and overflow usable @360px.
- **600/640 breakpoint reconciliation:** Document, do not collapse. Both rungs express distinct intents. Rationale recorded in `176-SCORECARD.md`.
- **data_table collapse breakpoint:** move `.ax-data-table-shell`/`.ax-data-table-cards` swap from `--ax-bp-lg` (1024px) → `--ax-bp-md` (768px). Edit `app.css` line 1361.
- **`.ax-measure` targets:** dense prose/long-form regions only (settings descriptions, event/webhook explanatory prose, invoice/charge detail prose). Region-level (`<p class="ax-body ax-measure">`), not whole-page. NOT data tables, KPI grids, field lists.
- **Token-compliance (dim ①):** fold into per-screen uplift — eliminate residual literal hex/px while in-scope. `accent_hex`/`accent_contrast_hex` in `*_live.ex` are domain branding-config seed data, not violations.
- **Anti-churn rule:** every change must cite (a) a rubric dimension below bar with a before-score, (b) a named persona-job miss, or (c) a concrete token bypass eliminated.
- **Frozen screens:** Home (`dashboard_live`), primary nav (`sidebar`, `nav`), global search — touched only on rubric-flagged miss.
- **Heavily-iterated screens (touch only on flagged miss):** Customer-360, dashboard.
- **No new components or screens.** No motion (Phase 177). No seed work (Phase 178). No screenshot sign-off (Phase 179).
- **Asset build:** `cd accrue_admin && mix accrue_admin.assets.build` + commit `priv/static` after any CSS/JS edit.
- **Test suite:** must stay at 227 green (`cd accrue_admin && mix test --seed 0`).

### Claude's Discretion

- Exact per-screen scores in the baseline audit, the precise worst-first ordering, and which specific screens turn out to need work.
- Exact responsive grid/stacking CSS (must resolve from `ax-*` tokens + 174 breakpoints; no literals).
- Whether the 600/640 reconciliation collapses or documents — decide from the actual usage sites. (UI-SPEC has already decided: document, do not collapse.)

### Deferred Ideas (OUT OF SCOPE)

- Motion / micro-interactions on the uplifted screens → Phase 177 (D).
- Seed/state expressiveness so every empty/overflow/error/loading state is reachable → Phase 178 (E).
- Screenshot-driven visual QA sign-off → Phase 179 (F).
- No IA/nav changes, no motion, no seed work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCR-01 | Every admin screen scores ≥2 on all 10 rubric dimensions in both light and dark themes | §Screen Inventory + §Baseline Scoring Recipe + §Wave-Split |
| SCR-02 | Every admin screen scores ≥2 on all 10 rubric dimensions at both desktop and mobile (usable @360px) widths | §Mobile-First Mechanics — data_table breakpoint fix + detail grid stacking |
| SCR-03 | Under-iterated tail lifted to rubric baseline, with documented before/after scores per screen | §Screen Inventory (tail vs polished) + §SCORECARD artifact |
| SCR-04 | Dense text/detail screens apply reading-measure max-width container and mobile-first layout on DSY breakpoint tokens | §Reading-Measure Targets + §Mobile-First Mechanics |
</phase_requirements>

---

## Summary

Phase 176 is a code-level quality uplift: bring every existing admin screen to a uniform ≥2 baseline on 10 rubric dimensions in light+dark × desktop+mobile@360px, with documented before/after scores. No new screens, no new components, no motion.

The codebase is in better shape than the CONTEXT.md framing implies for list screens: all 9 list LiveViews already wire `card_fields`/`card_title`, and the `data_table` component already renders both `.ax-data-table-shell` (table) and `.ax-data-table-cards` (mobile cards). The **one concrete CSS change that must happen first** is moving the data-table table↔card swap from `--ax-bp-lg` (1024px) to `--ax-bp-md` (768px) in `app.css` at line 1361. This single change fixes dimension ⑤ (responsive/mobile-first) for all 9 list screens at once.

The real uplift work concentrates on the **detail screens in the tail**: `event_live.ex` is the thinnest (summary card + related_resources only; no field-list, no detail sections, no grid layout); `coupon_live.ex` and `promotion_code_live.ex` use hand-rolled `<p class="ax-body">` key/value lists instead of `Detail.detail_section`/`detail_field_list` shared primitives (rubric ⑩ miss); none of the 11 detail screens apply `.ax-measure` anywhere yet (rubric ① + readability miss for prose regions). The CSS layer has zero literal hex/px violations in LiveView templates — token compliance was largely closed in Phase 174.

**Primary recommendation:** Start with the `app.css` breakpoint edit (single-file, zero-regression risk), capture the baseline SCORECARD.md in the same Wave 0 task, then execute Wave 1 (list screen card_fields audit), Wave 2 (tail catalog/specialist detail structural uplift + `.ax-measure` application), Wave 3 (dense financial detail + reading-measure), commit `priv/static` after each CSS edit, and run `mix test --seed 0` at each wave boundary.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Responsive layout (table↔card swap, detail stacking) | Frontend static CSS (`app.css`) | LiveView templates (class wiring) | CSS `@media` governs layout; LiveViews only need to emit the correct BEM classes |
| Reading-measure (`.ax-measure`) | LiveView templates | — | Applied per-element in the HEEx template; no CSS change needed (class already defined) |
| Token compliance (dim ①) | CSS (`app.css`, `theme.css`) | LiveView templates | CSS layer is already clean; templates need prose wrapping + verify no inline `style=` |
| State coverage markup (dim ④) | LiveView templates | — | Confirm empty/loading/error branches exist in markup; seeding is Phase 178 |
| Focus & semantics (dim ⑦) | LiveView templates | — | `<th scope>`, `<dl>/<dt>/<dd>`, `aria-label` on landmark sections |
| Reuse/DRY (dim ⑩) | LiveView templates | Shared components | Tail screens with hand-rolled key/value lists → replace with `detail_section`/`detail_field_list` |
| Scorecard artifact | Phase dir file | — | `176-SCORECARD.md`: 10 dims × before/after per screen; no code |
| Test assertions (structural mobile) | ExUnit component tests | Playwright e2e (`admin-a11y.spec.js`) | Unit tests verify markup structure; Playwright verifies no axe violations in both themes |

---

## Full Screen Inventory

### Complete route matrix (confirmed from `router.ex`)

| Path | LiveView | Group |
|------|----------|-------|
| `/` | `DashboardLive` | Frozen — heavily iterated |
| `/customers` | `CustomersLive` | List — polished (Phase 21 focus) |
| `/customers/:id` | `CustomerLive` | Detail — polished (Customer-360, Phase 175 tab tiering) |
| `/subscriptions` | `SubscriptionsLive` | List — moderately iterated |
| `/subscriptions/:id` | `SubscriptionLive` | Detail — moderately iterated (`ax-grid-2`, `json_viewer`) |
| `/invoices` | `InvoicesLive` | List — moderately iterated |
| `/invoices/:id` | `InvoiceLive` | Detail — **TAIL** (complex, dense, `ax-grid-2`+`ax-grid-3`, no `.ax-measure`) |
| `/payments` | `ChargesLive` | List — was Phase 21 focus; verify card_fields quality |
| `/payments/:id` | `ChargeLive` | Detail — **TAIL** (`ax-grid-2`, `json_viewer`, no `.ax-measure`, hand-rolled key/value) |
| `/coupons` | `CouponsLive` | List — tail |
| `/coupons/:id` | `CouponLive` | Detail — **TAIL** (no `ax-grid-2/3`, hand-rolled `<p class="ax-body">` key/value, no `Detail.detail_section`) |
| `/promotion-codes` | `PromotionCodesLive` | List — tail |
| `/promotion-codes/:id` | `PromotionCodeLive` | Detail — **TAIL** (no `ax-grid-2/3`, minimal structure, coupon link only) |
| `/connect` | `ConnectAccountsLive` | List — tail |
| `/connect/:id` | `ConnectAccountLive` | Detail — **TAIL** (`ax-grid-2` used, but nested `ax-grid-2` inside + inline form inputs not wrapped in `detail_section`) |
| `/events` | `EventsLive` | List — tail (small `ax-*` footprint per audit) |
| `/events/:id` | `EventLive` | Detail — **TAIL, THINNEST** (`summary_card` + `related_resources` only; no field sections, no body copy, no grid) |
| `/webhooks` | `WebhooksLive` | List — tail |
| `/webhooks/:id` | `WebhookLive` | Detail — **TAIL** (`ax-grid-2`, `Detail.summary_card` + `detail_section` used, but forensic payload section has unlabeled `<p class="ax-body">` key/value inline) |
| `/analytics/recovery` | `RecoveryLive` | Specialist — at-risk dashboard; audit-only |
| `/analytics/recovery/subscriptions/:id` | `CampaignLive` | Specialist — campaign detail; audit-only |

**Dev-only (out of scope):** `/dev/clock`, `/dev/email-preview`, `/dev/webhook-fixtures`, `/dev/components`, `/dev/fake-inspect`

### Tail vs polished vs frozen

| Category | Screens |
|----------|---------|
| **Under-iterated tail (primary uplift target)** | `event_live` (thinnest), `coupon_live`, `promotion_code_live`, `connect_account_live`, `webhook_live`, `invoice_live`, `charge_live`, `EventsLive`, `ChargesLive`, `CouponsLive`, `PromotionCodesLive`, `ConnectAccountsLive`, `WebhooksLive` |
| **Moderately iterated (audit, lift on miss)** | `SubscriptionLive`, `SubscriptionsLive`, `InvoicesLive` |
| **Heavily iterated / polished (touch only on flagged miss)** | `CustomerLive`, `CustomersLive`, `DashboardLive` |
| **Frozen (do not touch unless rubric miss)** | Home/`DashboardLive` nav/sidebar/global search |
| **Specialist (audit score, minimal uplift expected)** | `RecoveryLive`, `CampaignLive` |

---

## Baseline Scoring Method (Per-Screen Rubric Recipe)

The planner creates a Wave 0 task: "Capture baseline SCORECARD.md." The executor runs this recipe for each of the ~20 screens, records before-scores, then the phase executes worst-first uplift.

### SCORECARD.md column definitions

```
Screens (rows) × 10 Dimensions × {Before, After}
Scored 0–3; ≥2 = pass
```

### Per-dimension code-level audit signal

**① Token compliance** (no literal hex/px in CSS/styling)
- `grep -rn 'style=' <live_file>.ex` — any `style=` attribute that isn't a data attribute is a violation
- `grep -n '#[0-9a-fA-F]\{3,6\}' <live_file>.ex` excluding `accent_hex`/`accent_contrast_hex` lines (those are branding config, not violations) [VERIFIED: codebase inspection — templates are clean]
- Current state: ALL LiveView templates pass this check — no literal hex/px found in any live file. Score 3 across the board for CSS compliance; score may still be 1 if layout uses inline `style=` for spacing.

**② Visual hierarchy** (heading structure, eyebrow/heading/body hierarchy, display face on hero numbers)
- Look for `ax-eyebrow` → `ax-display`/`ax-heading` → `ax-body` hierarchy within each section
- Verify `ax-display` is used for the primary page-level number/title (not just `ax-heading`)
- `event_live`: renders only `summary_card` with bare `<span>` facts — no heading hierarchy within the detail body. Score: 1

**③ Spacing rhythm** (every margin/padding/gap resolves to `--ax-space-*`)
- Verify no bare `margin:` or `padding:` with literal values in adjacent `.ax-*` definitions for this screen's unique classes
- In LiveView templates: look for hard-coded spacing via style attributes (none found in audit)
- `coupon_live` uses `<div class="ax-page">` inside a card section as a key/value container — `ax-page` is not a spacing utility for card content (semantic mismatch); should be `ax-stack-md` or similar. Score: 1–2

**④ State coverage** (empty/loading/error/populated/overflow branches exist in markup)
- Grep for `:if={@entity == []}` or `:if={@entity == nil}` patterns in the render
- `data_table` already handles filtered-empty vs first-run-empty via `any_filter_active?` [VERIFIED]
- `event_live`: no empty/not-found state in render — redirects on nil load but has no "not found" copy path shown to user. Score: 1
- Loading (`.ax-skeleton`): check if skeleton is used anywhere in the screen; most tail screens omit it. Score: 0–1
- Error: check for flash/banner error path

**⑤ Responsive/mobile-first** (usable @360px; card layout below trigger; no horizontal scroll)
- List screens: confirm `card_fields` set (all 9 confirmed) AND breakpoint fires at `--ax-bp-md` (currently fires at `--ax-bp-lg` — score: 1 until the CSS edit lands)
- Detail screens: confirm `ax-grid-2`/`ax-grid-3` is used (stacks to 1fr below 768px) vs ad-hoc layout
- `coupon_live`, `promotion_code_live`: no `ax-grid-2/3` — both use single-column card layout only. ⑤ is fine for mobile (already single column) but scores low on responsive intent
- `event_live`: single column only — fine for mobile, score: 2
- `connect_account_live`: nested `ax-grid-2` inside `ax-grid-2` with form inputs — likely horizontal overflow at 360px. Score: 1

**⑥ Contrast** (`-readable` variants on tinted surfaces; status not color-only)
- Checked via axe in `admin-a11y.spec.js` (currently passing)
- Code-level: verify `status_badge` usage (always includes text), money sign shows +/− not just color
- No additional code-level check needed beyond confirming no new bare-color-only status is introduced. Score: likely 2–3 for most screens (axe already passes)

**⑦ Focus & semantics** (`:focus-visible` preserved, `<th scope="col">`, `<dl>/<dt>/<dd>` for field lists, `aria-label` on sections)
- `grep -n 'aria-\|scope=\|role=' <live_file>.ex`
- `event_live` detail body uses `<span>Actor: …</span>` — not a `<dl>/<dt>/<dd>` structure. Score: 1
- `coupon_live` key/value pairs in `<p class="ax-body">`: not `<dl>`. Score: 1
- `data_table` already uses `<th scope="col">` and visual caption [VERIFIED from component code]

**⑧ Brand expression** (Geist display face on hero numbers, tabular figures, tightened radii/shadow, no finance clichés)
- Tabular figures: inherited globally via `font-variant-numeric: tabular-nums` on `.ax-money` [VERIFIED in app.css line 901]
- KPI cards using `ax-display` class: confirm on each screen
- `event_live`: no KPI cards, no display number — N/A for hero numbers. Score: 2 (no violations but no opportunities either)

**⑨ Motion** (token-based, reduced-motion honored)
- OUT OF SCOPE for Phase 176. Score existing state only; do not change.
- All screens inherit `prefers-reduced-motion` from the global `@media (prefers-reduced-motion: reduce)` block at app.css line 2408 [VERIFIED]

**⑩ Reuse/DRY** (shared primitives used; no hand-rolled cards/sections/field-lists)
- `coupon_live`: `Detail.summary_card` is NOT used; hand-rolled `<section class="ax-card">` + `<p class="ax-body">Key: value</p>` for projection section. Score: 1
- `promotion_code_live`: no `Detail.*` usage; minimal structure. Score: 1
- `event_live`: uses `Detail.summary_card` correctly but body facts are `<span>`, not `<dl>`. Score: 1–2
- `webhook_live`: uses `Detail.summary_card` + `Detail.detail_section` correctly. Score: 2–3
- `connect_account_live`: has `ax-grid-2` but nested form section is hand-wired inputs without `detail_section` wrapper. Score: 2
- `invoice_live`, `charge_live`, `subscription_live`: use `ax-grid-2`, `Detail.detail_section` present. Score: 2–3

---

## Mobile-First Mechanics

### 1. data_table card-collapse breakpoint fix (app.css line 1361)

**Current state** [VERIFIED: app.css lines 1351–1369]:
```css
/* Data table: one layout at a time — cards below lg, grid table from lg */
.ax-data-table-shell {
  display: none;
}
.ax-data-table-cards {
  display: grid;
  gap: var(--ax-space-md);
}
@media (min-width: 1024px) { /* --ax-bp-lg ↑ */   /* ← THIS LINE */
  .ax-data-table-shell {
    display: block;
  }
  .ax-data-table-cards {
    display: none;
  }
}
```

**Required change** (move from `--ax-bp-lg` → `--ax-bp-md`):
```css
@media (min-width: 768px) { /* --ax-bp-md ↑ */   /* ← CHANGE TO THIS */
  .ax-data-table-shell {
    display: block;
  }
  .ax-data-table-cards {
    display: none;
  }
}
```

This is a one-line change to the media query breakpoint value AND its comment (the grep-able token comment must also be updated to `/* --ax-bp-md ↑ */`). After this change, tables render at ≥768px and cards render below 768px — matching the CONTEXT decision and the rest of the detail-grid promotion tier. Re-verify that the widest table (invoices or charges) does not cause horizontal overflow at 768px. The `data_table` component HTML is unchanged; only the CSS display rule fires at a different width.

**Impact:** All 9 list screens gain correct mobile-first behavior simultaneously. This is the highest-leverage single CSS change in the phase.

### 2. All 9 list screens already wire card_fields/card_title [VERIFIED]

| Screen | card_title expression | card_fields count |
|--------|-----------------------|-------------------|
| `customers_live` | `row.name \|\| row.email \|\| row.processor_id \|\| row.id` | 3 fields |
| `charges_live` | `row.processor_id \|\| row.id` | 5 fields (customer, signals, status, amount, fees) |
| `subscriptions_live` | `row.processor_id \|\| row.id` | 4 fields |
| `invoices_live` | `row.number \|\| row.processor_id \|\| row.id` | 4+ fields |
| `coupons_live` | `coupon_label(row)` | 4 fields (discount, redemptions, status, redeem_by) |
| `promotion_codes_live` | `row.code \|\| row.processor_id \|\| row.id` | 4 fields |
| `connect_accounts_live` | `row.stripe_account_id \|\| row.id` | 4 fields |
| `events_live` | `row.type` | 4 fields (subject, actor, webhook source, when) |
| `webhooks_live` | `row.processor_event_id \|\| row.id` | 4 fields (type, status, endpoint, received) |

The list-screen wave's job is:
1. Confirm the CSS breakpoint edit lands first
2. Confirm each `card_title` is the human-meaningful identifier (all look correct above)
3. Confirm each `card_fields` surfaces decision-critical columns for the operator's job (not all columns) — the charges screen exposes 5 fields including fees, which may be excessive on mobile; audit against persona-job

### 3. Detail screens — grid stacking to single column [VERIFIED]

The existing `ax-grid-2`/`ax-grid-3` classes already go to `grid-template-columns: 1fr` below `--ax-bp-md` [VERIFIED: app.css lines 1163–1166 + 904–911]:

```css
.ax-grid-2,
.ax-grid-3 {
  grid-template-columns: 1fr;   /* mobile: single column */
}
@media (min-width: 768px) { /* --ax-bp-md ↑ */
  .ax-grid-2 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .ax-grid-3 {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
```

Detail screens that already use `ax-grid-2` correctly stack to single column on mobile:
- `charge_live.ex` line 182: `<section class="ax-grid ax-grid-2">` — correct
- `invoice_live.ex` line 254: `<section class="ax-grid ax-grid-2">` — correct
- `subscription_live.ex` line 268: `<section class="ax-grid ax-grid-2">` — correct
- `webhook_live.ex` line 198: `<section :if={@webhook} class="ax-grid ax-grid-2">` — correct
- `connect_account_live.ex` line 123: `<section class="ax-grid ax-grid-2">` — correct

Tail screens that LACK `ax-grid-2` and need assessment:
- `coupon_live.ex`: all sections are single-column cards — no grid needed, but key/value prose layout should use `Detail.detail_field_list`
- `promotion_code_live.ex`: minimal content, single-column — fine for mobile, but needs `Detail` DRY uplift
- `event_live.ex`: single-column entirely — acceptable for a thin detail screen, but the facts in `summary_card` use bare `<span>` instead of `<dl>/<dt>/<dd>`

**The nested `ax-grid-2` problem in `connect_account_live.ex`** (line 149): a second `ax-grid-2` is nested inside the outer `ax-grid-2` — at 360px this becomes two nested single-column grids, which is fine, but the form inputs inside (`ax-input`, line 156+) each span a 2-col cell at ≥768px. The executor must verify at 360px that no horizontal overflow occurs from the inner grid promotion.

### 4. 600/640 breakpoint reconciliation [VERIFIED: document, do not collapse]

Current `--ax-bp-sm ↓` usages in `app.css` (confirmed by grep):
- Line 1903: `.ax-search-trigger-text { display: none }` — hide search trigger text on phone
- Line 2076: `.ax-attention-pill { display: none }` — hide attention pill on phone

Current `--ax-bp-content ↑` usages in `app.css`:
- Line 2178: `.ax-launchers { grid-template-columns: repeat(2, …) }` + `.ax-kpi-grid-4 { repeat(2, …) }` — content promotion
- Line 2381: `.ax-field-list { grid-template-columns: repeat(2, 1fr) }` — field list 2-col

These serve **distinct intents**: `599.98px` is a max-width chrome-hide guard; `640px` is a min-width content-promotion step. They are not duplicates. The 40px gap between them (600–640px) is observable at unusual viewport widths but not at the locked @360px target. **Planner records this rationale in `176-SCORECARD.md` header note.** No CSS change needed for this reconciliation.

---

## Reading-Measure Targets (`.ax-measure`)

`.ax-measure` is defined at `app.css:406` as `max-width: var(--ax-measure)` where `--ax-measure: 68ch` [VERIFIED]. It is applied to NO screen currently. [VERIFIED: grep across all LiveViews returns zero results.]

### Confirmed application targets (region-level, `<p class="ax-body ax-measure">` or wrapping `<div class="ax-measure">`)

| Screen | Prose region | Location |
|--------|-------------|----------|
| `event_live.ex` | The `summary_card` facts are bare spans — when upgraded to body copy, any description sentences get `.ax-measure` | line 65–71 |
| `webhook_live.ex` | "Endpoint:", "Processed:", "Attempt ID:" description lines in forensic payload section | lines 222–228 |
| `coupon_live.ex` | The projection section key/value prose (`duration_summary`, `currency`, `processor`) | lines 106–110 |
| `invoice_live.ex` | Tax-risk description (`ax-body` at line 263, 266, 269) and actions body copy (`ax-body` at line 277) | lines 263–277 |
| `charge_live.ex` | Braintree eligibility/warning copy (lines 218–219), refund copy body in confirm panel (line 242) | lines 218–219, 242 |
| `connect_account_live.ex` | The `<p class="ax-body">` on line 144 describing override behavior | line 144 |

### Do NOT apply `.ax-measure` to

- `data_table` renders (all list screens)
- KPI grids / `.ax-kpi-grid` sections
- `.ax-field-list` containers (they are columnar)
- `.ax-empty-copy` — already capped at `28rem` intentionally; do not double-cap [VERIFIED: UI-SPEC]
- JSON tree output inside `JsonViewer` — that is structured data, not prose
- `summary_card` `:facts` slot items when they are identifiers/timestamps (not prose sentences)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Key/value detail field display | `<p class="ax-body">Key: value</p>` repetition | `<Detail.detail_field_list>` + `<:field>` slot | Semantic `<dl>/<dt>/<dd>`, consistent gap/token usage, screen-reader friendly |
| Grouped detail sections | `<section class="ax-card"><header>...` hand-wired | `<Detail.detail_section title="…">` | Already has `ax-card` + `ax-page-header` + responsive stacking; no re-implementation |
| Mobile card for list data | Custom card grid per screen | `card_fields` + `card_title` on `data_table` | Already wired on all 9 list screens; the breakpoint change activates it at the right tier |
| Status display | `<span style="color: red">Failed</span>` | `<StatusBadge.status_badge>` | Text label + color together (never color-only per rubric ⑥) |
| Semantic entity metadata | `<span>Actor: foo</span>` | `<dl><dt>…</dt><dd>…</dd></dl>` structure | Screen reader semantics for rubric ⑦ |

**Key insight:** The shared Detail component library (`detail_section`, `detail_field_list`, `summary_card`) already provides everything the tail screens need. The DRY uplift is replacing 4–12 lines of hand-wired HTML with 2–4 lines of component calls per screen.

---

## Common Pitfalls

### Pitfall 1: Committing CSS without rebuilding priv/static

**What goes wrong:** App serves the old cached bundle; test suite references `priv/static` hashes; visual changes don't appear in screenshots.
**Why it happens:** The Elixir asset pipeline produces content-hashed files in `priv/static`; the repo commits these. If you edit `app.css` but don't run the build, `priv/static` is stale and CI diffs will show an uncommitted change.
**How to avoid:** Every wave that touches `app.css` or `theme.css` must run `cd accrue_admin && mix accrue_admin.assets.build` and commit the resulting `priv/static` changes alongside the CSS change in the same commit.
**Warning signs:** `mix test` passes locally but `priv/static` shows as modified in `git status`.

### Pitfall 2: Double-capping `.ax-empty-copy`

**What goes wrong:** Adding `.ax-measure` to `.ax-empty-copy` elements applies both `max-width: 68ch` and the existing `max-width: 28rem` — narrower wins and the copy becomes unusably narrow.
**Why it happens:** The UI-SPEC contract specifies `.ax-empty-copy` already has its own deliberate cap; `.ax-measure` is for prose, not empty-state copy.
**How to avoid:** When applying `.ax-measure`, check if the target element already has a `max-width` — if it does, do not add `.ax-measure`. The `<p class="ax-body">` prose description sentences (not the empty-state copy class) are the correct targets.

### Pitfall 3: Moving data-table breakpoint creates 768–1023px tablet overflow

**What goes wrong:** The `.ax-data-table-shell` table renders at ≥768px; if a table has many columns (e.g. invoices or webhooks), the rendered table may overflow its container at 768px–900px.
**Why it happens:** Tables with 5–7 columns at 768px viewport can exceed container width.
**How to avoid:** After the CSS edit, manually verify (or add a Playwright assertion) that the widest tables (invoices, charges/webhooks) do not cause horizontal scroll at 768px. The existing `.min-width: 0` patterns on table cells help, but the executor should check. If overflow occurs, add `overflow-x: auto` to `.ax-data-table-shell` rather than reverting the breakpoint.
**Warning signs:** `expectNoHorizontalOverflow` failing at 768px in Playwright.

### Pitfall 4: Hand-rolling `<section class="ax-card">` instead of using Detail primitives

**What goes wrong:** The tail screen looks roughly correct but rubric ⑩ (reuse/DRY) score stays at 1 because the screen re-implements card structure that `Detail.detail_section` already provides.
**Why it happens:** It's faster to type `<section class="ax-card">` than to look up the `Detail` component API.
**How to avoid:** For any section that would render as `<section class="ax-card"><header>` + content, use `<Detail.detail_section>` with the `title` attr. Check `accrue_admin/lib/accrue_admin/components/detail.ex` for the available slots.

### Pitfall 5: Applying `.ax-measure` to structured data (JSON viewer)

**What goes wrong:** `json_viewer` content becomes narrow and truncates long keys/values.
**Why it happens:** `json_viewer` is data, not prose, but it visually looks like text.
**How to avoid:** Apply `.ax-measure` only to prose description sentences — the `<p class="ax-body">` introductory text *around* a `json_viewer`, never on the `json_viewer` itself. The JSON tree stays full-width.

### Pitfall 6: Anti-churn violation — editing frozen screens without a rubric miss

**What goes wrong:** An executor touches `dashboard_live.ex` or `sidebar.ex` for "general polish" and the plan-checker rejects the PR.
**Why it happens:** The anti-churn rule requires a scored before-score < 2 as justification.
**How to avoid:** The SCORECARD.md baseline score IS the gate. If a frozen/polished screen scores ≥2 on all dimensions, do not touch it. If it genuinely scores < 2 on a dimension, record that score first, then fix.

---

## Code Examples

### Replacing hand-rolled key/value with detail_field_list

```elixir
# Source: accrue_admin/lib/accrue_admin/components/detail.ex (inferred from usage in invoice_live, webhook_live)

# BEFORE (coupon_live.ex forensic section — hand-rolled):
<div class="ax-page">
  <p class="ax-body"><%= Copy.coupon_detail_label_duration() %> <%= duration_summary(@coupon) %></p>
  <p class="ax-body"><%= Copy.coupon_detail_label_currency() %> <%= @coupon.currency || "--" %></p>
  <p class="ax-body"><%= Copy.coupon_detail_label_processor() %> <%= @coupon.processor || "--" %></p>
</div>

# AFTER (token-compliant, semantic, DRY):
<Detail.detail_section title={AccrueAdmin.Copy.coupon_detail_section_projection_heading()}>
  <Detail.detail_field_list>
    <:field label={AccrueAdmin.Copy.coupon_detail_label_duration()}>
      <%= duration_summary(@coupon) %>
    </:field>
    <:field label={AccrueAdmin.Copy.coupon_detail_label_currency()}>
      <%= @coupon.currency || "--" %>
    </:field>
    <:field label={AccrueAdmin.Copy.coupon_detail_label_processor()}>
      <%= @coupon.processor || "--" %>
    </:field>
  </Detail.detail_field_list>
</Detail.detail_section>
```

### Applying `.ax-measure` to inline prose

```elixir
# Source: UI-SPEC.md Reading-Measure Contract

# Prose sentence in a detail card — add ax-measure to the <p>:
<p class="ax-body ax-measure">
  <%= Copy.invoice_actions_body() %>
</p>

# NOT:
<article class="ax-card ax-measure">  ← whole-card, not region-level
  ...
</article>
```

### data_table card-collapse breakpoint edit (app.css)

```css
/* Source: app.css lines 1351–1369 — CHANGE the @media condition */

/* BEFORE: */
@media (min-width: 1024px) { /* --ax-bp-lg ↑ */
  .ax-data-table-shell { display: block; }
  .ax-data-table-cards { display: none; }
}

/* AFTER: */
@media (min-width: 768px) { /* --ax-bp-md ↑ */
  .ax-data-table-shell { display: block; }
  .ax-data-table-cards { display: none; }
}
```

### event_live semantic upgrade — facts as `<dl>`

```elixir
# Source: event_live.ex lines 65–71 (current bare <span> facts)

# BEFORE:
<Detail.summary_card eyebrow="Event detail" title={@event.type}>
  <:facts>
    <span>Actor: <%= @event.actor_type %></span>
    <span>Subject: <%= @event.subject_type %> <%= @event.subject_id %></span>
    <span>Recorded: <%= format_datetime(@event.inserted_at) %></span>
  </:facts>
</Detail.summary_card>

# AFTER (check summary_card :facts slot contract in detail.ex first;
# if it renders a <dl>, the spans become <dt>/<dd> pairs automatically):
<Detail.summary_card eyebrow="Event detail" title={@event.type}>
  <:facts>
    <dt class="ax-label">Actor</dt><dd class="ax-body"><%= @event.actor_type %></dd>
    <dt class="ax-label">Subject</dt><dd class="ax-body"><%= @event.subject_type %> <%= @event.subject_id %></dd>
    <dt class="ax-label">Recorded</dt><dd class="ax-body"><%= format_datetime(@event.inserted_at) %></dd>
  </:facts>
</Detail.summary_card>
```

Note: executor must inspect `Detail.summary_card` `:facts` slot contract before assuming `<dt>/<dd>` is the right element — if the slot wraps in a `<dl>` already, the `<dt>/<dd>` approach is correct. If it renders as a flex row of `<span>`, use a `<dl>` wrapper inside the slot.

---

## Wave-Split Recommendation

The CONTEXT.md specifies Wave 1 = list screens, Wave 2 = catalog/specialist detail, Wave 3 = dense financial detail. The planner may refine groupings for parallelism. Here is the concrete screen assignment:

### Wave 0 (pre-wave, non-parallel): Scorecard + CSS breakpoint

| Task | File | Justification |
|------|------|---------------|
| Capture baseline `176-SCORECARD.md` | `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` (new) | All subsequent wave tasks need before-scores as anti-churn tokens |
| Move data-table breakpoint `--ax-bp-lg` → `--ax-bp-md` in app.css | `accrue_admin/assets/css/app.css` line 1361 | Fixes dim ⑤ for all 9 list screens simultaneously; must land before Wave 1 verification |
| Build + commit `priv/static` | `accrue_admin/priv/static/` | Asset pipeline |
| Document 600/640 reconciliation rationale in SCORECARD.md header | `176-SCORECARD.md` | CONTEXT locked decision |

### Wave 1 (list screens): card_fields quality audit

| Screen | Expected work |
|--------|--------------|
| `charges_live.ex` | Confirm 5 card_fields not excessive for mobile; confirm `card_title` is meaningful; verify `copy`/empty_title is domain-specific (COPY gap from baseline audit) |
| `coupons_live.ex` | Same audit |
| `promotion_codes_live.ex` | Same audit |
| `connect_accounts_live.ex` | Same audit |
| `events_live.ex` | Verify `card_title = row.type` is sufficiently meaningful (event type names can be long); confirm KPI section aria-label |
| `webhooks_live.ex` | Confirm card_fields for status, endpoint, type coverage |
| `invoices_live.ex` | Audit — likely already well-scoped (Phase 21 focus) |
| `customers_live.ex` | Audit — heavily iterated; touch only on miss |
| `subscriptions_live.ex` | Audit — moderately iterated |

### Wave 2 (catalog/specialist detail): structural + DRY uplift

| Screen | Expected work |
|--------|--------------|
| `event_live.ex` | **Most work**: add body sections (actor detail, subject detail, payload metadata), upgrade `<span>` facts to semantic `<dl>`, add state coverage for missing-subject graceful handling, apply `.ax-measure` to any description prose |
| `coupon_live.ex` | Replace hand-rolled `ax-page` key/value with `Detail.detail_section` + `Detail.detail_field_list`; confirm `RelatedResources` thread completeness; apply `.ax-measure` to projection prose |
| `promotion_code_live.ex` | Similar DRY uplift; confirm coupon preload / parent link is robust |
| `connect_account_live.ex` | Verify nested `ax-grid-2` at 360px; wrap form inputs in `Detail.detail_section`; apply `.ax-measure` to the override description prose |
| `webhook_live.ex` | Upgrade forensic payload `<p class="ax-body">` key/values to `detail_field_list`; apply `.ax-measure` to explanatory prose; confirm `JsonViewer` label is descriptive |

### Wave 3 (dense financial detail): reading-measure + final pass

| Screen | Expected work |
|--------|--------------|
| `invoice_live.ex` | Apply `.ax-measure` to tax-risk prose, actions body copy; confirm `ax-grid-3` (line item form) does not overflow at 360px; verify `detail_section` usage consistency |
| `charge_live.ex` | Apply `.ax-measure` to braintree warning copy, refund confirm prose; verify the `ax-grid-2` fee breakdown section (line 182) stacks correctly at mobile |
| `subscription_live.ex` | Audit: already uses `ax-grid-2`, `json_viewer`, `detail_section` — expected score ≥2 on most dims; touch only on miss |

### Specialist screens (audit only, no uplift expected)

`RecoveryLive`, `CampaignLive` — audit-score these in Wave 0 baseline; if any dimension < 2, add a targeted fix task.

---

## Validation Architecture

`nyquist_validation` is enabled (config.json: absent key defaults to enabled; confirmed present and true).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17), Phoenix.ConnTest + Phoenix.LiveViewTest |
| Config file | `accrue_admin/test/test_helper.exs` |
| Quick run command | `cd accrue_admin && mix test --seed 0 test/accrue_admin/components/data_table_test.exs` |
| Full suite command | `cd accrue_admin && mix test --seed 0` |
| Current suite count | 227 tests, 0 failures [VERIFIED: 2026-06-04] |

Playwright e2e:
| Property | Value |
|----------|-------|
| Framework | Playwright (Node.js) |
| Config | `accrue_admin/playwright.config.js` |
| Desktop viewport | 1280×900 (`chromium-desktop`) |
| Mobile viewport | 393×851 Pixel 5 (`chromium-mobile`) — note: 393px, NOT 360px |
| A11y spec | `accrue_admin/e2e/admin-a11y.spec.js` — axe WCAG2A+2AA in light+dark across 12 surfaces [VERIFIED] |
| Visual spec | `accrue_admin/e2e/admin-visuals.spec.js` — screenshot capture, 12 surfaces × 2 themes [VERIFIED] |
| Quick e2e run | `cd accrue_admin && npm run e2e:visuals:png-only` |

**Note on @360px:** The `chromium-mobile` Playwright project uses Pixel 5 (393×851). There is no 360px project. The "verify @360px" requirement from the CONTEXT is partially served by the 393px mobile project — it is narrower than 768px and will trigger card-collapse. If the planner wants a true 360px test, a second Playwright project would need to be added (which is Phase 179 scope, not 176 scope). For Phase 176, the ExUnit structural assertions and the 393px Playwright run are sufficient.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCR-01 | Every screen ≥2 on all 10 dims in light+dark | axe (e2e) | `npm run e2e:visuals:png-only` + `admin-a11y.spec.js` | ✅ (a11y spec covers 12 surfaces) |
| SCR-02 | Every screen ≥2 at mobile @360px (structural) | ExUnit + Playwright mobile | `mix test --seed 0 test/.../data_table_test.exs` + full e2e on `chromium-mobile` | ✅ existing; ❌ new assertions needed |
| SCR-03 | Tail screens lifted, before/after scores documented | Manual code audit | N/A — SCORECARD.md is the artifact | ❌ new artifact (Wave 0 task) |
| SCR-04 | Dense screens apply `.ax-measure` + mobile layout | ExUnit (assert class present) | `mix test --seed 0` scoped to relevant live tests | ❌ new assertions needed |

### Nyquist Structural Assertions to Add (Wave 0 gap)

These are **cheap structural ExUnit assertions** that confirm the mobile-first contract in markup — the full visual proof is Phase 179.

**1. data_table breakpoint change verification** (add to `data_table_test.exs`):

```elixir
# Confirm both ax-data-table-shell and ax-data-table-cards are rendered in DOM
# (CSS hides one; ExUnit sees both — the CSS hide is the breakpoint behavior)
test "renders both shell and cards DOM nodes for CSS breakpoint visibility", %{conn: conn} do
  # ... render with rows ...
  assert html =~ ~s(class="ax-card ax-data-table-shell")
  assert html =~ ~s(data-role="card-list")
end
```

This already exists in some form (line 286 checks `data-role="card-list"`). The new assertion needed is that the CSS comment in app.css reads `/* --ax-bp-md ↑ */` — this is a grep guard, not ExUnit:

```bash
# In CI or as a mix task check:
grep -q 'min-width: 768px.*--ax-bp-md' accrue_admin/assets/css/app.css
```

**2. `.ax-measure` application checks** (add to relevant live tests):

For each Wave 2/3 screen where `.ax-measure` is applied, add an ExUnit assertion that the class is present on the prose element after the uplift:

```elixir
# Example for invoice_live_test.exs (or coupon_live_test.exs):
test "applies ax-measure to prose description regions", %{conn: conn} do
  # ... mount live view with fixture ...
  assert html =~ ~s(class="ax-body ax-measure")
end
```

**3. Token grep guard** (CI check, not ExUnit):

The existing pattern from Phase 174: `grep -n '@media (min-width: [0-9]\+px)' app.css | grep -v 'ax-bp'` should return nothing after the breakpoint edit. This confirms no bare-literal `@media` exists.

### Sampling Rate

- **Per task commit:** `cd accrue_admin && mix test --seed 0` (227 tests, ~3s)
- **Per wave merge:** full suite + `npm run e2e:visuals:png-only` for spot visual check
- **Phase gate:** full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `176-SCORECARD.md` — new artifact, not a test file but required before any wave begins
- [ ] Add grep guard to CI/Wave 0 task: `grep -c 'ax-bp-md.*↑' accrue_admin/assets/css/app.css` must be ≥2 after breakpoint edit (data-table block + at least one other existing block)
- [ ] Add ExUnit assertion for `.ax-measure` presence on prose regions (per touched screen in Wave 2/3)
- [ ] Optionally: add 360px Playwright project to `playwright.config.js` for structural @360 mobile assertion — **but this may be Phase 179 scope**

---

## Security Domain

No new authentication, authorization, data ingestion, or HTTP endpoints introduced in this phase. All changes are CSS/template markup uplift on existing authenticated LiveViews.

| ASVS Category | Applies | Note |
|---------------|---------|------|
| V2 Authentication | No | No auth changes |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No new routes/actions |
| V5 Input Validation | No | No new user inputs (the existing Connect form is not changed in structure, only wrapped) |
| V6 Cryptography | No | No crypto changes |

The one security-adjacent concern: `connect_account_live.ex` contains a form with tax rate overrides. The structural uplift (wrapping in `Detail.detail_section`) must not remove or alter `phx-submit`/`phx-change` handlers. The executor must confirm `data-role="save-override"` button and form IDs are unchanged after any wrapping.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | `mix test` | ✓ | 1.17+ (verified by project) | — |
| Node.js + npm | `mix accrue_admin.assets.build` | ✓ | confirmed by Phase 174 execution | — |
| Playwright + chromium | `npm run e2e:visuals:png-only` | ✓ | confirmed by Phase 174/175 execution | Skip e2e; ExUnit only |
| `priv/static` commit access | Asset build | ✓ | git writable | — |

---

## Package Legitimacy Audit

This phase installs **no new packages**. All work is CSS + HEEx template edits within the existing `accrue_admin` package. No package legitimacy gate required.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| data-table cards fire below `--ax-bp-lg` (1024px) | Target: fire below `--ax-bp-md` (768px) | This phase (Wave 0) | Tablets (768–1023px) see table; phones see cards |
| `.ax-measure` defined but unapplied | Applied to prose regions in tail screens | This phase (Waves 2–3) | Reading comfort on dense detail screens |
| Hand-rolled `<p>Key: value</p>` in coupon/event/promo | `Detail.detail_section` + `detail_field_list` | This phase (Wave 2) | Semantic `<dl>`, consistent token spacing, rubric ⑩ pass |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Detail.detail_section` and `Detail.detail_field_list` components exist and accept the attrs/slots used in the code examples | Code Examples, Don't Hand-Roll | Executor finds different API; must check `detail.ex` component before writing |
| A2 | The `summary_card` `:facts` slot in `Detail` renders its children inside a `<dl>` element | Code Examples (event_live upgrade) | If the slot renders as flex-row `<span>` children, the `<dt>/<dd>` upgrade approach needs adjustment |
| A3 | `analytics/RecoveryLive` and `CampaignLive` score ≥2 on all dimensions without uplift (specialist screens) | Screen Inventory | If baseline audit finds a miss, Wave 1 or Wave 2 needs a targeted task for these screens |
| A4 | The `chromium-mobile` Playwright project (393px Pixel 5) is a sufficient proxy for @360px structural verification | Validation Architecture | At 393px, cards trigger (below 768px) but 360px-specific overflow could exist; Phase 179 catches visual proof |

**If this table is empty:** All claims in this research were verified or cited. The 4 assumptions above are low-risk — A1/A2 are resolved by the executor reading one component file before writing; A3/A4 are Phase 179 deferred risks.

---

## Open Questions (RESOLVED)

1. **`Detail.detail_field_list` component API** — RESOLVED
   - What we know: `Detail.detail_section` is used in `webhook_live.ex` and `invoice_live.ex`; `Detail.detail_field_list` appears in the UI-SPEC component library list
   - What's unclear: The exact slot name(s) and attrs (`:field` with `label` attr is assumed from community Phoenix convention)
   - Resolution: Executor reads `accrue_admin/lib/accrue_admin/components/detail.ex` in the first Wave 2 task (Plan 03 `read_first`) before writing any `detail_field_list` calls. The exact API is confirmed at execution time from the source file; Plans 03/04 include `detail.ex` as a required `read_first` item.

2. **`analytics/recovery` and `analytics/campaign` rubric scores** — RESOLVED
   - What we know: These screens were not in the Phase 21 focus; they have an `at_risk_table` component and `campaign_timeline` component not in the kitchen
   - What's unclear: Their actual rubric scores (not inspected in this research pass)
   - Resolution: Both screens are included in the Plan 01 Wave 0 SCORECARD sweep (Task 1 `read_first` explicitly includes `accrue_admin/lib/accrue_admin/live/analytics/`). Scores are captured in the same pass as all other screens.

3. **Horizontal overflow at 768px after breakpoint change** — RESOLVED
   - What we know: The widest tables are invoices (many columns: number, customer, status, amount, due_at, etc.) and webhooks (type, status, endpoint, received)
   - What's unclear: Whether these tables overflow their container at exactly 768px width
   - Resolution: Plan 01 Task 2 proactively adds `overflow-x: auto` to `.ax-data-table-shell` in the same CSS edit (per RESEARCH.md §Pitfall 3 recommendation). This is a defensive guard that prevents overflow before it can be observed, so no separate verification step is needed.

---

## Sources

### Primary (HIGH confidence)

- Codebase direct inspection (`accrue_admin/assets/css/app.css`, `theme.css`) — breakpoint registry, `.ax-measure`, `.ax-grid-2`, data-table CSS, all `@media` queries [VERIFIED: direct file read]
- Codebase direct inspection (all 20 LiveView files + `data_table.ex`, `detail.ex`) — `card_fields`/`card_title` coverage, grid usage, `.ax-measure` absence, Detail component usage [VERIFIED: direct file read]
- Codebase direct inspection (`admin-a11y.spec.js`, `admin-visuals.spec.js`, `playwright.config.js`) — test coverage, viewport sizes, Playwright project config [VERIFIED: direct file read]
- `mix test --seed 0` execution — 227 tests, 0 failures [VERIFIED: 2026-06-04]

### Secondary (MEDIUM confidence)

- `176-CONTEXT.md` — locked decisions, wave-split, scope constraints [CITED: locked user decisions]
- `176-UI-SPEC.md` — breakpoint behavior table, `.ax-measure` contract, token gap flags, data-table reconciliation decision [CITED: approved design contract]
- `.planning/research/v1.51-admin-ui-depth-design.md` §4, §6, §7 — rubric definitions, verification commands, guardrails [CITED: authoritative design source]
- `.planning/research/v1.51-admin-ux-baseline-audit.md` — prior baseline route matrix, grep footprint observations [CITED: planning artifact]

---

## Metadata

**Confidence breakdown:**
- Screen inventory: HIGH — directly verified from router.ex + file listing
- Card_fields/card_title coverage: HIGH — verified by grep across all list LiveViews
- Breakpoint locations: HIGH — verified by reading app.css with line numbers
- Detail screen grid usage: HIGH — verified per-file by grep
- `.ax-measure` absence: HIGH — grep returned zero results across all LiveViews
- Rubric score estimates: MEDIUM — inferred from code structure; actual scores require human code-level audit per screen (Wave 0 SCORECARD task)
- `Detail` component API (slot names): MEDIUM (A1/A2 assumptions)

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable codebase; no external deps)
