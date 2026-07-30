---
phase: 210-reign-home-certify-answer-first-ia-copy-integrity
plan: 02
subsystem: accrue_admin
tags: [home-reign, page-header, stat-strip, attention-rail, launcher-grid, ia, css-bundle]
requires:
  - "210-01 (Home reign Copy strings in AccrueAdmin.Copy)"
provides:
  - "dashboard_live.ex recomposed onto the canonical PageHeader spine"
  - "DOM marker data-ax-health-verdict (single header verdict)"
  - "DOM marker data-ax-launcher-primary (invoice tile)"
  - "DOM marker data-ax-command-palette-trigger (single customer-lookup control)"
  - "class ax-attention-rail--empty preserved on EmptyState (phase194 e2e hook)"
  - "additive CSS: .ax-launchers-tri / .ax-home-launcher-card (three-tile grid)"
affects:
  - "dashboard_live_test.exs (Plan 03) — asserts against new StatusBadge/StatStrip verdict + new markers"
  - "admin-spec-overview-phase194 / admin-interaction-overlay-phase199 e2e (Plan 03) — rail selector migration"
tech-stack:
  added: []
  patterns:
    - "Verdict = single StatusBadge (data-ax-health-verdict) + exposure-first StatStrip in PageHeader — cross-page parity with Subscriptions (209 D-03)"
    - "Whole-tile/whole-row <a> nav composed from .ax-card / StatusBadge primitives (no per-row action button)"
    - "CSS stop-referencing-not-delete: retired .ax-home-*/.ax-launcher*/.ax-attention* rules preserved for Phase 211"
key-files:
  created: []
  modified:
    - "accrue_admin/lib/accrue_admin/live/dashboard_live.ex"
    - "accrue_admin/assets/css/app.css"
    - "accrue_admin/priv/static/accrue_admin.css"
decisions:
  - "Kept structural .ax-attention-row / .ax-attention-text classes (flex layout + hover/focus + first-child emphasis) — not in the plan's stop-reference list (which enumerates priority-*/dot-*/pill-*/action); only the tone-carrying bespoke spans were retired"
  - "Launcher tile action styled .ax-button-secondary (not primary) so the page keeps exactly ONE primary cobalt CTA (header) per the color contract; primary door emphasis lives on the tile via data-ax-launcher-primary accent border"
  - "Tile padding set to --ax-space-md via new .ax-home-launcher-card (tighter than .ax-card default --ax-space-lg); no widened padding to fill the freed 4th column (density-no-regression)"
metrics:
  duration: ~30m
  completed: 2026-07-19
status: complete
---

# Phase 210 Plan 02: Reign Home onto the canonical spine Summary

Recomposed the Home page (`dashboard_live.ex`) onto the shared-component spine — replaced the hand-rolled `<header>` with `PageHeader`, collapsed the triplicated billing-health verdict to a single `StatusBadge` + exposure-first `StatStrip`, collapsed the triplicated customer-search entry points to one command-palette trigger in the header, rebuilt the attention rail from `StatusBadge`/`.ax-chip`/`EmptyState`, and rebuilt the launcher grid as three `.ax-card` tiles (customer tile removed). Answer-first order and cross-page parity with the reigned Subscriptions page now hold; the KpiCard "At a glance" band and Timeline cards are untouched; no CSS rule was deleted.

## What Was Built

**Task 1 — PageHeader adoption (REIGN-03, IA-01, IA-04, COPY-02):**
- Replaced the hand-rolled `<header class="ax-page-header">` with `PageHeader.page_header`: single self-referential-free breadcrumb `[Dashboard]` (no href), plain title "Dashboard".
- `:description` carries one `StatusBadge` (marked `data-ax-health-verdict="true"`, tone/label from new `verdict_status/label/tone` helpers) + the `home_intro_copy` route line. The h1 verdict sentence, `ax-home-header-health` block, and `ax-attention-summary` block are all removed → one verdict.
- `:actions` = one primary CTA ("Open invoice queue", `.ax-button-primary`) + one customer-search trigger (`data-ax-command-palette-trigger`, label `Copy.home_customer_search_cta()`) + "Audit ledger". Dropped the duplicate "Debug dead-lettered webhooks" and "Dunning after invoices" header links.
- `:stat_strip` = 4-stat exposure-first `StatStrip` (Open invoices `cobalt` → Exposure `exposure_tone` → At-risk subscriptions `amber` → Failed webhooks `stat_webhook_tone`), sourced from Home's `@stats`, in Subscriptions order.
- Added `FlashGroup.flash_group` after PageHeader + copied `flash_messages/1`.
- New helpers: `verdict_status/1`, `verdict_label/1`, `verdict_tone/1`, `exposure_tone/1`, `stat_webhook_tone/1` (distinct name — the pre-existing timeline `webhook_tone/1` is untouched). Removed dead `dashboard_health_headline/1`, `attention_health_summary/1`, `attention_health_issue_summary/1`.

**Task 2 — Attention rail from primitives (REIGN-03, IA-02):**
- Rebuilt each rail row from `StatusBadge` (its built-in `.ax-status-dot` replaces the bespoke dot) + `.ax-stack-xs` metric/label + optional `.ax-chip.ax-label` pill + a quiet `.ax-link-quiet` action; whole-row `<a href>` nav preserved. The P4 `failed_meter_event_count` row still renders (`attention_items/3` unchanged — content preserved).
- Empty branch now renders via `EmptyState.empty_state` with `class="ax-attention-rail--empty"` preserved (phase194 e2e hook; non-interactive per D-06).
- Deleted the `ax-attention-summary` verdict block and the entire `ax-home-customer-search-strip` section. Zone heading sourced from `Copy.home_attention_priority_heading/0`. Added `attention_status_badge_tone/1`.

**Task 3 — Three-tile launcher grid (REIGN-03, IA-02):**
- Rebuilt three tiles (Invoice queue / Dunning funnel / Investigate an incident) from `.ax-card` + `Icon` (lg) + heading + conditional `.ax-chip` meta + secondary-button action. Removed the `ax-launcher-customer` tile (customer lookup is header-only — three tiles is correct per D-02a). Retired `invoice_launcher_title/1`. Invoice tile carries `data-ax-launcher-primary="true"`.
- Added additive CSS (`.ax-launchers-tri` 3-up grid at ≥1024px, `.ax-home-launcher-card` internal layout, `data-ax-launcher-primary` accent emphasis) — no existing `.ax-launcher*` rule touched. Rebuilt the committed `priv/static/accrue_admin.css` bundle via `mix accrue_admin.assets.build`.

## Verification

- `mix compile --warnings-as-errors` clean after every task.
- Grep gates PASS: no `dashboard_health_headline`/`attention_health_summary`/`attention_health_issue_summary`/`ax-home-header-health`/`Billing health: Unhealthy`; no `ax-attention-summary`/`ax-home-customer-search-strip`/`Find ONE customer`/`Open customer search`; no `ax-launcher-customer`/`Open global customer search`/`invoice_launcher_title`. Markers present: `data-ax-health-verdict`, `data-ax-command-palette-trigger`, `data-ax-launcher-primary`, `ax-attention-rail--empty`; `EmptyState.empty_state` present.
- Answer-first order confirmed in source: PageHeader (verdict + StatStrip) → FlashGroup → attention-rail → task-launcher → kpi-cluster → recent-activity.
- KpiCard "At a glance" band and Timeline cards byte-for-byte unchanged (`git diff base..HEAD` shows no edit in those zones).
- CSS bundle regenerated: `accrue_admin.css` contains the new `.ax-home-launcher-card`/`.ax-launchers-tri` selectors.
- Render sanity: the Dashboard LiveView mounts and renders full HTML with no runtime crash. The one failing unit assertion (`html =~ "Billing health: Unhealthy"`) is the expected verdict-language change that Plan 03 migrates in-phase (D-05) — this plan's gate is compile + grep + render sanity, not the unit suite.

## Deviations from Plan

### Auto-fixed / auto-added

**1. [Rule 3 - Blocking] EmptyState alias staged with its usage to keep every commit compiling**
- **Found during:** Task 1 compile.
- **Issue:** The plan's Task 1 adds `EmptyState` to the alias block, but `EmptyState` is not used until Task 2 — `mix compile --warnings-as-errors` failed on `unused alias EmptyState` at the Task 1 boundary.
- **Fix:** Added `EmptyState` to the alias block in Task 2 (when its usage lands) instead of Task 1, so each atomic commit compiles clean. Net alias set is identical to the plan.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`.
- **Commits:** 8fc185ae (Task 1), 1a07fbd5 (Task 2).

### Judgment calls (within Claude's Discretion / plan latitude)

- Kept the structural `.ax-attention-row` / `.ax-attention-text` classes (flex layout, hover/focus, first-child emphasis) — these are not in the plan's explicit stop-reference list (`ax-attention-priority-*`/`-dot-*`/`-pill-*`/`-action`) and provide the dense row layout without any CSS edit. Only the tone-carrying bespoke spans were retired.
- Launcher tile actions are `.ax-button-secondary` (not primary) so the page keeps exactly one primary cobalt CTA (the header), honoring the color contract; the primary door emphasis lives on the tile via the `data-ax-launcher-primary` accent border.

## Known Stubs

None — every zone is wired to live `@stats`/`@attention` assigns; no placeholder/empty data paths were introduced.

## Commits

- `8fc185ae` — feat(210-02): adopt PageHeader on Home — single verdict badge + 4-stat StatStrip
- `1a07fbd5` — feat(210-02): rebuild attention rail from primitives + EmptyState; drop verdict-summary + customer-search strip
- `cecef2b0` — feat(210-02): rebuild launcher grid as three .ax-card tiles; remove customer tile

## Self-Check: PASSED
