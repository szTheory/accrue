# Phase 176 — Per-Screen Rubric Baseline Scorecard

**Phase:** 176-c-systematic-per-screen-rubric-uplift
**Scored by:** Wave 0 executor (code-level audit, 2026-06-04)
**Suite state at scoring:** 227 tests, 0 failures

---

## 600/640 Breakpoint Reconciliation Note

**Decision: Document, do not collapse.**

Two close-together breakpoint rungs in `app.css` were evaluated for possible deduplication:

| Rung | Value | Direction | Current usages |
|------|-------|-----------|----------------|
| `--ax-bp-sm ↓` | 599.98px | `max-width` guard | Line 1903: `.ax-search-trigger-text { display: none }` · Line 2076: `.ax-attention-pill { display: none }` |
| `--ax-bp-content ↑` | 640px | `min-width` promotion | Line 2178: `.ax-launchers` 2-col + `.ax-kpi-grid-4` 2-col · Line 2381: `.ax-field-list` 2-col |

**Why they are NOT duplicates:** The `599.98px` rung is a **max-width chrome-hide guard** — it hides non-essential navigation decoration on phone viewports. The `640px` rung is a **min-width content-promotion step** — it widens content layouts (field lists, launchers, KPI grids) when enough horizontal space exists. These serve orthogonal intents. The 40px gap between 600–640px is observable at unusual intermediate viewport widths but is not visible at the locked @360px design target (which is 360px, well below both rungs). Collapsing them would either strip chrome too aggressively (if moved to 640) or promote content too early (if moved to 599.98). **Kept as-is. Both rungs stay in the registry.**

---

## Rubric Dimension Key

| # | Dimension | Passing signal (code-level) | Score 0–3; ≥2 = pass |
|---|-----------|-----------------------------|-----------------------|
| ① | Token compliance | No `style=` / bare hex in live template (excl. `accent_hex` / `accent_contrast_hex` branding config lines) | 3 = clean; 1 = inline style present |
| ② | Visual hierarchy | `ax-eyebrow` → `ax-display`/`ax-heading` → `ax-body` present; `ax-display` on hero number/title | 3 = all tiers; 2 = heading+body; 1 = partial/flat |
| ③ | Spacing rhythm | No literal `px`/`rem` spacing in template markup; uses `ax-space-*` tokens | 3 = all token; 2 = mostly token; 1 = ax-page semantic mismatch / minor literal |
| ④ | State coverage | Empty, error, populated branches present; redirect-on-nil counts as error path | 3 = all incl. loading; 2 = empty+error+populated; 1 = missing a branch |
| ⑤ | Responsive/mobile-first | List: `card_fields`+`card_title` wired AND breakpoint fires at `--ax-bp-md` (768px); Detail: `ax-grid-2/3` used for multi-column layout | 3 = exemplary; 2 = wired+correct bp; 1 = wired but wrong bp OR no grid on detail |
| ⑥ | Contrast | Status uses text label not color-only; `-readable` variants on tinted surfaces; axe-passing | 3 = all correct; 2 = status badge with text; 1 = color-only risk |
| ⑦ | Focus & semantics | `aria-*`/`scope=`/`role=` present; `dl/dt/dd` for field lists; `th scope="col"` via data_table | 3 = full; 2 = partial aria; 1 = missing dl/dt/dd or key aria on interactive |
| ⑧ | Brand expression | `ax-display` on hero numbers / KPI value; Geist tabular (global inherit); no finance clichés | 3 = display used; 2 = no violations, KPIs present; 1 = no display at all |
| ⑨ | Motion | Record existing state only; all screens inherit global reduced-motion block | 2 = inherited global |
| ⑩ | Reuse/DRY | `Detail.summary_card`/`detail_section`/`detail_field_list` used; no hand-rolled cards | 3 = all primitives; 2 = summary_card+detail_section used; 1 = hand-rolled key/value or card |

**Scoring note for ⑤ list screens before Wave 0 CSS fix:** All 9 list screens already wire `card_fields`+`card_title`, but the breakpoint fires at `--ax-bp-lg` (1024px) not `--ax-bp-md` (768px). Score = 1 until the CSS fix lands. After the fix all 9 list screens move to ⑤ = 2 automatically (no HEEx change needed).

---

## Before-Scores Table

Scores reflect the codebase **before** any Wave 0+ uplift.

| Screen | File | Group | ① | ② | ③ | ④ | ⑤ | ⑥ | ⑦ | ⑧ | ⑨ | ⑩ | Min | Pass? |
|--------|------|-------|---|---|---|---|---|---|---|---|---|---|-----|-------|
| DashboardLive | `dashboard_live.ex` | Frozen | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES |
| CustomersLive | `customers_live.ex` | List — polished | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| CustomerLive | `customer_live.ex` | Detail — polished | 3 | 3 | 3 | 3 | 3 | 2 | 3 | 3 | 2 | 3 | 2 | YES |
| SubscriptionsLive | `subscriptions_live.ex` | List — moderate | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| SubscriptionLive | `subscription_live.ex` | Detail — moderate | 3 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | YES |
| InvoicesLive | `invoices_live.ex` | List — moderate | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| InvoiceLive | `invoice_live.ex` | Detail — TAIL | 3 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | YES |
| ChargesLive | `charges_live.ex` | List — moderate | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| ChargeLive | `charge_live.ex` | Detail — gold std | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES |
| CouponsLive | `coupons_live.ex` | List — tail | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| CouponLive | `coupon_live.ex` | Detail — TAIL | 3 | 1 | 1 | 1 | 3 | 2 | 1 | 2 | 2 | 1 | 1 | NO (②③④⑦⑩) |
| PromotionCodesLive | `promotion_codes_live.ex` | List — tail | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| PromotionCodeLive | `promotion_code_live.ex` | Detail — TAIL | 3 | 1 | 3 | 1 | 3 | 2 | 1 | 2 | 2 | 1 | 1 | NO (②④⑦⑩) |
| ConnectAccountsLive | `connect_accounts_live.ex` | List — tail | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| ConnectAccountLive | `connect_account_live.ex` | Detail — TAIL | 3 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | YES |
| EventsLive | `events_live.ex` | List — tail | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| EventLive | `event_live.ex` | Detail — THINNEST | 3 | 1 | 3 | 1 | 2 | 2 | 1 | 2 | 2 | 1 | 1 | NO (②④⑦⑩) |
| WebhooksLive | `webhooks_live.ex` | List — tail | 3 | 3 | 3 | 2 | 1 | 2 | 2 | 3 | 2 | 3 | 1 | NO (⑤) |
| WebhookLive | `webhook_live.ex` | Detail — TAIL | 3 | 3 | 3 | 3 | 2 | 2 | 2 | 3 | 2 | 2 | 2 | YES |
| RecoveryLive | `analytics/recovery_live.ex` | Specialist | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES |
| CampaignLive | `analytics/campaign_live.ex` | Specialist | 3 | 1 | 3 | 1 | 2 | 2 | 1 | 1 | 2 | 2 | 1 | NO (②④⑦⑧) |

**Screens failing ≥1 dimension:** 10 of 21 (before CSS fix: 9 more fail on ⑤)

---

## Per-Screen Score Rationale

### DashboardLive (3-3-3-2-2-2-2-3-2-3 = min 2 PASS)
- ① No inline style= or bare hex (accent_hex excluded); clean.
- ② ax-display headline, ax-heading sections, ax-body copy — full hierarchy.
- ③ Only ax-* spacing classes, no literals.
- ④ Attention rail: empty branch (`@attention == []`) + populated. No explicit error state but dashboard has no failure path by design. Score 2.
- ⑤ Zone 4 uses `ax-grid ax-grid-2` — correct. No data_table on dashboard. Score 2.
- ⑥ Attention rows use tone classes + text label. Status is text-backed. Score 2.
- ⑦ `aria-label` on all 3 home sections. Score 2.
- ⑧ `ax-display` on page heading. KpiCard uses its own display number. Score 3.
- ⑨ Inherits global reduced-motion block. Score 2.
- ⑩ Uses KpiCard, Timeline components. Score 3.

### CustomersLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- ① Clean template, no inline styles or hex.
- ② ax-eyebrow → ax-display → ax-body in header. Score 3.
- ③ All ax-* spacing. Score 3.
- ④ data_table handles empty states. KPI section shows counts. Score 2.
- ⑤ `card_title` and `card_fields` wired. BUT breakpoint fires at 1024px. Score 1.
- ⑥ billing_signals_cell uses chip+text. Score 2.
- ⑦ KPI section has `aria-label`. Score 2.
- ⑧ ax-display in page header, KpiCards. Score 3.
- ⑨ Inherits. Score 2.
- ⑩ DataTable component used; KpiCard used. Score 3.

### CustomerLive (3-3-3-3-3-2-3-3-2-3 = min 2 PASS)
- ① Clean. No inline styles.
- ② ax-display via summary_card title, ax-heading in section headers. Full hierarchy.
- ③ All ax-* spacing.
- ④ Not-found redirect on mount, empty branches in all tabs (`== []` checks), payment method error state, entitlements error sentinel (`:error`). Score 3.
- ⑤ No list table — detail screen with tabs. ax-kpi-grid (stacks). Score 3.
- ⑥ StatusBadge used. Entitlement badges text-labeled. Score 2.
- ⑦ `aria-label` on KPI section, tabs have `aria-label`, tab items have `aria-current`, more-menu has `aria-haspopup`, `aria-expanded`, `role="menu"/"menuitem"/"none"`. Score 3.
- ⑧ KpiCard values are display numbers; summary_card uses ax-display. Score 3.
- ⑨ Inherits. Score 2.
- ⑩ Detail, RelatedResources, KpiCard, TaxOwnershipCard, Timeline, JsonViewer all used. Score 3.

### SubscriptionsLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- Same pattern as CustomersLive. card_title + card_fields wired. Breakpoint wrong. FilterChipBar used.
- ④ data_table handles empty. Queue-aware empty_title/copy. Score 2.
- ⑤ Score 1 (breakpoint at 1024px).

### SubscriptionLive (3-2-2-2-2-2-2-2-2-2 = min 2 PASS)
- ① Clean.
- ② `Detail.summary_card` with eyebrow+title. KPI grid. ax-heading in inline cards. Score 2 (some inline hand-rolled `ax-page-header` / `ax-eyebrow`+`ax-heading` pattern in the actions card; not fully on summary_card but within spec).
- ③ Uses ax-stack-xl, ax-page-header — no literals. Score 2.
- ④ Redirect on not-found. Conditional `@pending_action` branch. Empty dunning state shown. Score 2.
- ⑤ `ax-grid ax-grid-2` used for actions+timeline section. Correct. Score 2.
- ⑥ StatusBadge used in summary facts and KPI. Dunning status badge has text. Score 2.
- ⑦ `aria-label` on KPI section, nav `aria-label`. Score 2.
- ⑧ KpiCard values; summary_card used; no explicit ax-display but KpiCard handles it. Score 2.
- ⑨ Inherits. Score 2.
- ⑩ Detail.summary_card, RelatedResources, KpiCard, StepUpAuthModal used. Score 2.

### InvoicesLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- Same list-screen pattern. card_title + card_fields wired. Breakpoint wrong. score ⑤ = 1.

### InvoiceLive (3-2-2-2-2-2-2-2-2-2 = min 2 PASS)
- ① Clean.
- ② `Detail.summary_card` with eyebrow+status+facts. KPI grid. Tax-risk section uses `ax-eyebrow`+`ax-heading`. Score 2.
- ③ ax-stack-xl, ax-page-header, ax-grid — no literals. Score 2.
- ④ Not-found redirect. Tax-risk section conditionally visible. Empty line items path. PDF links conditional. Score 2.
- ⑤ `ax-grid ax-grid-2` for actions+PDF section. `ax-grid ax-grid-3` for line-item add form. Stacks on mobile. Score 2.
- ⑥ StatusBadge used in summary_card and KPI meta. Score 2.
- ⑦ `aria-label` on KPI section. RelatedResources has landmark. Score 2.
- ⑧ KpiCard values. summary_card. Score 2.
- ⑨ Inherits. Score 2.
- ⑩ Detail.summary_card, Detail.detail_section, RelatedResources, KpiCard, TaxOwnershipCard, Timeline, StepUpAuthModal all used. Score 2.

### ChargesLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- List screen. card_title + card_fields wired (5 fields). Breakpoint wrong. Score ⑤ = 1.

### ChargeLive (3-3-3-2-2-2-2-3-2-3 = min 2 PASS — gold standard)
- ① Clean.
- ② summary_card with eyebrow+status+facts. KPI grid. ax-eyebrow+ax-heading in fee/refund cards. Score 3.
- ③ ax-stack-xl, ax-page-header, ax-grid, ax-list-row — no literals. Score 3.
- ④ Nil redirect on load. Empty refunds path. Pending refund conditional. Score 2.
- ⑤ `ax-grid ax-grid-2` for fee+refund section. Stacks on mobile. Score 2.
- ⑥ StatusBadge in summary_card and KPI. Score 2.
- ⑦ `aria-label` on KPI section. RelatedResources. Score 2.
- ⑧ KpiCard values. summary_card. Score 3.
- ⑨ Inherits. Score 2.
- ⑩ Detail.summary_card, Detail.detail_field_list (inside detail_section), Detail.detail_section x4, RelatedResources, KpiCard, TaxOwnershipCard, Timeline, JsonViewer, StepUpAuthModal. Score 3.

### CouponsLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- List screen. card_title + card_fields wired (4 fields). Breakpoint wrong. Score ⑤ = 1.

### CouponLive (3-1-1-1-3-2-1-2-2-1 = min 1 FAIL — multiple dims)
- ① Clean — no inline style. Score 3.
- ② Hand-rolled `<header class="ax-page-header">` with `ax-eyebrow`+`ax-display` but no `Detail.summary_card`. The projection section uses `<section class="ax-card">` with `ax-page-header` inside, creating a flat heading hierarchy not on the hero card. Score 1 (no summary_card hero; heading structure is partial).
- ③ Projection section uses `<div class="ax-page">` as a key/value container — `ax-page` is a page-level stack primitive, not a card-content spacing utility. Semantic mismatch. Score 1.
- ④ Nil redirect on load. BUT the `nil -> redirect` case on line 17 is silent — no flash/not-found state shown to user (redirect just goes back to index). No promotion-codes empty body copy when `@promotion_codes == []` — only `AccrueAdmin.Copy.coupon_detail_promotion_codes_empty()` text (that exists, ok). But the projection section has no error/disabled state. Score 1.
- ⑤ No `ax-grid-2/3` needed — all single-column card layout. That is fine for mobile. But the page IS usable at mobile. Score 3 (single-column is correct for this screen; no layout regression).
- ⑥ Status comes from `status_summary/1` returning text ("Valid"/"Invalid") displayed as plain body text, not `StatusBadge`. No color-only risk since it is plain text. Score 2.
- ⑦ No `dl/dt/dd` for the key/value projection section (`<p class="ax-body">Label value</p>` pattern). No aria-label on the card sections. Score 1.
- ⑧ `ax-display` used for page title. KpiCard values. Score 2.
- ⑨ Inherits. Score 2.
- ⑩ No `Detail` alias. Hand-rolled `<section class="ax-card">` + `<div class="ax-page">` key/value. Score 1.

### PromotionCodesLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- List screen. card_title + card_fields wired (4 fields). Breakpoint wrong. Score ⑤ = 1.

### PromotionCodeLive (3-1-3-1-3-2-1-2-2-1 = min 1 FAIL — multiple dims)
- ① Clean. Score 3.
- ② Hand-rolled `<header class="ax-page-header">` with `ax-eyebrow`+`ax-display`. No `Detail.summary_card`. Flat heading for parent-coupon section. Score 1.
- ③ No suspicious literal spacing in markup. Uses ax-page-copy, ax-body. Score 3.
- ④ Nil redirect. Parent coupon section has `:if/@promotion_code.coupon` + `:if={!@promotion_code.coupon}` branches. But NO explicit not-found copy (silent redirect). Score 1.
- ⑤ Single-column layout. Fine for mobile. Score 3.
- ⑥ Status text via `status_summary/1` — plain text, no badge. No color-only risk. Score 2.
- ⑦ No `dl/dt/dd`. No aria-label on card sections. Score 1.
- ⑧ `ax-display` in header. KpiCard. Score 2.
- ⑨ Inherits. Score 2.
- ⑩ No `Detail` alias. Hand-rolled `<section class="ax-card">` for parent coupon section. Score 1.

### ConnectAccountsLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- List screen. card_title + card_fields wired (4 fields). Breakpoint wrong. Score ⑤ = 1.

### ConnectAccountLive (3-2-2-2-2-2-2-2-2-2 = min 2 PASS)
- ① Clean — no inline styles or hex. Score 3.
- ② `Detail.summary_card` used (eyebrow + title + facts). KPI grid. Score 2.
- ③ No literal px spacing in template. ax-grid, ax-page-header. Score 2. Note: `<p class="ax-body">` at line 145 for platform-fee prose — no `ax-measure` applied (Wave 2 target).
- ④ Nil redirect on mount. override_preview has `%{error: nil}` and `%{error: reason}` branches. Score 2.
- ⑤ `ax-grid ax-grid-2` outer section (lines 123–141). Inner `ax-grid ax-grid-2` for form inputs (line 149). At mobile both collapse to single column. Score 2. (Verify no horizontal overflow at 360px is a Wave 2 task.)
- ⑥ `enabled_label/1` returns text. Score 2.
- ⑦ `aria-label` on KPI section. Score 2.
- ⑧ KpiCard values, summary_card. Score 2.
- ⑨ Inherits. Score 2.
- ⑩ Detail.summary_card, Detail.detail_section x3, Detail.detail_field_list x2, RelatedResources all used. Score 2.

### EventsLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- List screen. `card_title = &card_title/1` (returns `row.type`). card_fields wired (4 fields). Breakpoint wrong. Score ⑤ = 1.

### EventLive (3-1-3-1-2-2-1-2-2-1 = min 1 FAIL — multiple dims)
- ① Clean. Score 3.
- ② `Detail.summary_card` used but `:facts` slot contains bare `<span>Actor: ...` — no inner heading hierarchy within detail body. No detail sections. Score 1.
- ③ No literal spacing. ax-page, ax-body only. Score 3.
- ④ Nil/not-found redirect is silent (no flash, no rendered not-found copy). No error branch shown to user. Score 1.
- ⑤ Single-column layout — only summary_card + related_resources. Fine for mobile. Score 2.
- ⑥ No status badge, no color-only risk. Score 2.
- ⑦ Bare `<span>Actor: value</span>` in `:facts` slot — not `dl/dt/dd`. No aria-label on sections. Score 1.
- ⑧ `ax-display` via summary_card title. Score 2.
- ⑨ Inherits. Score 2.
- ⑩ `Detail.summary_card` used but no `Detail.detail_section`, no `Detail.detail_field_list`. Facts are bare spans not semantic dl. Score 1.

### WebhooksLive (3-3-3-2-1-2-2-3-2-3 = min 1 FAIL ⑤)
- List screen. card_title + card_fields wired (4 fields). Breakpoint wrong. Score ⑤ = 1. DLQ bulk replay section is a hand-rolled `<section class="ax-card">` but it is a functional action panel, not a detail display card — acceptable in context.

### WebhookLive (3-3-3-3-2-2-2-3-2-2 = min 2 PASS)
- ① Clean. Score 3.
- ② `Detail.summary_card` with eyebrow+title+facts. KPI grid with aria-label. `Detail.detail_section` titles. Score 3.
- ③ ax-stack-xl, ax-page-header, ax-grid. No literals. Score 3.
- ④ `:not_found` redirect with flash. `:ambiguous` state rendered (copy shown). Populated state. Score 3.
- ⑤ `ax-grid ax-grid-2` for dispatch+ledger timelines section. Score 2.
- ⑥ Status text ("Verified", humanize(status)). Score 2.
- ⑦ aria-label on KPI section. Score 2.
- ⑧ KpiCard values. summary_card. Score 3.
- ⑨ Inherits. Score 2.
- ⑩ Detail.summary_card, Detail.detail_section x3, RelatedResources, KpiCard, Timeline, JsonViewer used. Forensic section (lines 216–239) is a hand-rolled `<section class="ax-card">` with `<p class="ax-body">` key/value for Endpoint/Processed/Activity. Score 2 (most primitives used; one remaining hand-rolled section).

### RecoveryLive (3-3-3-2-2-2-2-3-2-3 = min 2 PASS)
- ① Clean. Score 3.
- ② ax-eyebrow → ax-display in header. KpiCard values. Score 3.
- ③ ax-kpi-grid, ax-page-header, ax-section-gap. No literals visible. Score 3.
- ④ KPI pairs rendered for each currency (empty if no data = empty list means no KPI cards, which gracefully shows nothing). Score 2.
- ⑤ ax-kpi-grid already handles stacking. AtRiskTable + FunnelChart are specialist components. Score 2.
- ⑥ KpiCard delta_tone conveys status with text labels. Score 2.
- ⑦ aria-label not checked on specialist components (AtRiskTable, FunnelChart, WindowSelector) — these are outside plain LiveView templates. Score 2.
- ⑧ ax-display for "Revenue Recovery" heading. KpiCard values. Score 3.
- ⑨ Inherits. Score 2.
- ⑩ KpiCard, AtRiskTable, FunnelChart, WindowSelector, Breadcrumbs all used. Score 3.

### CampaignLive (3-1-3-1-2-2-1-1-2-2 = min 1 FAIL — multiple dims)
- ① Clean. Score 3.
- ② `h1 class="ax-heading"` (not ax-display) for "Dunning Timeline". No ax-eyebrow. No summary_card or page-level display number. Score 1.
- ③ ax-page, ax-muted, ax-body. No literals. Score 3.
- ④ No nil/not-found handling for the subscription_id — if `subscription_id` references a non-existent subscription, `Dunning.campaign_timeline_grouped/1` and `Dunning.invoices_for_campaign/1` return empty maps/lists; the template renders with empty CampaignTimeline. There is no redirect or error state for unknown IDs. Score 1.
- ⑤ CampaignTimeline is a specialist component; single-column. Score 2.
- ⑥ CampaignTimeline handles its own status display. Score 2.
- ⑦ Breadcrumbs has items. No explicit aria-label on page sections. Score 1.
- ⑧ No `ax-display`. Uses `ax-heading` for page title. No KPI numbers. Score 1.
- ⑨ Inherits. Score 2.
- ⑩ CampaignTimeline component used. Breadcrumbs. Score 2.

---

## Worst-First Ordering (ascending minimum score)

Priority is given to screens with the lowest minimum dimension score, then by number of failing dimensions.

| Priority | Screen | Group | Min Score | Failing Dimensions | Wave |
|----------|--------|-------|-----------|--------------------|------|
| 1 | CouponLive | Detail — TAIL | 1 | ②③④⑦⑩ (5 dims) | Wave 2 |
| 2 | EventLive | Detail — THINNEST | 1 | ②④⑦⑩ (4 dims) | Wave 2 |
| 3 | PromotionCodeLive | Detail — TAIL | 1 | ②④⑦⑩ (4 dims) | Wave 2 |
| 4 | CampaignLive | Specialist | 1 | ②④⑦⑧ (4 dims) | Wave 2 (targeted) |
| 5 | CustomersLive | List — polished | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 6 | SubscriptionsLive | List — moderate | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 7 | InvoicesLive | List — moderate | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 8 | ChargesLive | List — moderate | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 9 | CouponsLive | List — tail | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 10 | PromotionCodesLive | List — tail | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 11 | ConnectAccountsLive | List — tail | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 12 | EventsLive | List — tail | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 13 | WebhooksLive | List — tail | 1 | ⑤ (1 dim) | Wave 1 (CSS fix auto-resolves) |
| 14 | SubscriptionLive | Detail — moderate | 2 | none | Monitor |
| 15 | InvoiceLive | Detail — TAIL | 2 | none (but ①prose+⑩prose targets in Wave 3) | Wave 3 |
| 16 | ConnectAccountLive | Detail — TAIL | 2 | none (but ③prose target in Wave 2) | Wave 2 (minor) |
| 17 | WebhookLive | Detail — TAIL | 2 | none (but ⑩forensic section in Wave 2) | Wave 2 (minor) |
| 18 | ChargeLive | Detail — gold std | 2 | none (but ③prose target in Wave 3) | Wave 3 (minor) |
| 19 | DashboardLive | Frozen | 2 | none | Skip |
| 20 | CustomerLive | Detail — polished | 2 | none | Skip |
| 21 | RecoveryLive | Specialist | 2 | none | Skip |

**After Wave 0 CSS fix:** All 9 list screens (priorities 5–13) automatically move from ⑤=1 to ⑤=2 and become PASSING on all dimensions. No HEEx changes needed.

**Post-Wave-0 remaining failing screens:**
- CouponLive (min 1, 5 dims)
- EventLive (min 1, 4 dims)
- PromotionCodeLive (min 1, 4 dims)
- CampaignLive (min 1, 4 dims)

---

## After-Scores Table (to be filled in by wave executors)

| Screen | File | ① | ② | ③ | ④ | ⑤ | ⑥ | ⑦ | ⑧ | ⑨ | ⑩ | Min | Pass? | Wave |
|--------|------|---|---|---|---|---|---|---|---|---|---|-----|-------|------|
| DashboardLive | `dashboard_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | skip |
| CustomersLive | `customers_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| CustomerLive | `customer_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | skip |
| SubscriptionsLive | `subscriptions_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| SubscriptionLive | `subscription_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | skip |
| InvoicesLive | `invoices_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| InvoiceLive | `invoice_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W3 |
| ChargesLive | `charges_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| ChargeLive | `charge_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W3 |
| CouponsLive | `coupons_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| CouponLive | `coupon_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W2 |
| PromotionCodesLive | `promotion_codes_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| PromotionCodeLive | `promotion_code_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W2 |
| ConnectAccountsLive | `connect_accounts_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| ConnectAccountLive | `connect_account_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W2 |
| EventsLive | `events_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| EventLive | `event_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W2 |
| WebhooksLive | `webhooks_live.ex` | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | W0/1 |
| WebhookLive | `webhook_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W2 |
| RecoveryLive | `analytics/recovery_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | skip |
| CampaignLive | `analytics/campaign_live.ex` | — | — | — | — | — | — | — | — | — | — | — | — | W2 |

---

## Wave 1 After-Score Rationale (9 List Screens — Plan 176-02)

**Scored by:** Wave 1 executor (2026-06-04)

All 9 list screens move from ⑤=1 (before Wave 0 CSS fix) to ⑤=2 (after CSS fix). All other
dimensions were already ≥2. No HEEx changes needed for any list screen except one card_fields
reorder in webhooks_live.

### All 9 list screens: ① ② ③ ④ ⑥ ⑦ ⑧ ⑨ ⑩ — unchanged from before-scores (all ≥2)

- ① Token compliance: all clean — no inline style= or bare hex in templates.
- ② Visual hierarchy: all list screens use ax-eyebrow → ax-display → ax-body in page header.
- ③ Spacing rhythm: all list screens use ax-* spacing classes only.
- ④ State coverage: data_table handles empty states; KPI sections show counts; queue-aware
  empty_title/copy wired on charges, invoices, subscriptions.
- ⑥ Contrast: status chips/text present; billing_signals chips use text labels.
- ⑦ Focus & semantics: aria-label present on all KPI grid sections.
- ⑧ Brand expression: ax-display on page header; KpiCards handle display values.
- ⑨ Motion: inherits global reduced-motion block.
- ⑩ Reuse/DRY: DataTable component + KpiCard used on all screens.

### ⑤ Responsive/mobile-first: 1 → 2 for all 9 list screens (Wave 0 CSS fix)

The CSS breakpoint in `app.css` was changed from `min-width: 1024px` to `min-width: 768px`
(Plan 176-01). All 9 list screens already had card_title + card_fields wired — the breakpoint
was the only reason they scored ⑤=1. After the CSS fix, all 9 move to ⑤=2 automatically.

### WebhooksLive: card_fields reordered (persona-job fix, dim ⑩)

**Change:** Status moved before Type in card_fields.
**Justification:** Developer debugging persona needs failure triage first; status (delivered /
failed / dead-letter) is the primary decision field on mobile; type is secondary context.
**Before order:** type, status, endpoint, received
**After order:** status, type, endpoint, received
**File:** `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`

### Screens with no code changes (anti-churn confirmed):

| Screen | Reason no change |
|--------|-----------------|
| CustomersLive | All dims ≥2. card_title=name/email/processor_id/id, card_fields=owner_type/owner_id/signals/default_pm — correct for Support persona. |
| SubscriptionsLive | All dims ≥2. card_fields=customer/signals/lifecycle/current_period_end — correct for Finance Ops persona. Work-queue default filters not regressed. |
| InvoicesLive | All dims ≥2. card_fields=customer/signals/status/balance/collection_method, card_title=number/processor_id/id — correct for Finance Ops persona. KPI aria-label present. |
| ChargesLive | All dims ≥2. 5 card_fields (customer, signals, status, amount, fees) — all genuinely decision-critical for payment-support persona. Signals = ownership + tax health, both decision-critical for support triage. |
| CouponsLive | All dims ≥2. card_fields=discount/redemptions/status/redeem_by — correct for catalog persona. |
| PromotionCodesLive | All dims ≥2. card_fields=coupon/status/redemptions/expires — correct for catalog persona. |
| ConnectAccountsLive | All dims ≥2. card_fields=owner/readiness/override/status — correct for developer persona. |
| EventsLive | All dims ≥2. card_fields=subject/actor/webhook_source/when — correct for compliance/developer persona. KPI aria-label already present. |
