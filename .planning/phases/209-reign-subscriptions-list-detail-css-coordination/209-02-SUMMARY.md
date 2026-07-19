---
phase: 209-reign-subscriptions-list-detail-css-coordination
plan: 02
subsystem: admin-ui
tags: [phoenix-liveview, admin-ui, subscriptions, ia, copy, css-coordination]

# Dependency graph
requires: ["209-01"]
provides:
  - "Canonical PageHeader spine for SubscriptionsLive: single StatusBadge verdict, single primary CTA, unwrapped 4-stat StatStrip in money-at-risk order"
  - "Zero bespoke worklist bands between FlashGroup and DataTable; dead query/helper chain removed"
  - "Compact ax-stack-xs identity_cell/3 and two-chip billing_signals_cell/3 with zero in-cell actions"
  - "6 new Copy.Subscription functions (subscriptions_index_breadcrumb/0, subscriptions_invoice_queue_cta/0, subscriptions_health_verdict_healthy/0, subscriptions_health_verdict_action_required/0, subscriptions_route_line/0, subscriptions_kpi_section_aria_label/0) wired via Copy defdelegate"
affects: [209-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PageHeader spine now structurally matches invoices_live.ex/customers_live.ex: plain ax-page, no PageHeader class= override, unwrapped :stat_strip"
    - "identity_cell/3 two-line ax-stack-xs idiom: primary ax-link to the row's own detail page, secondary ax-label.ax-muted cross-navigation link"
    - "billing_signals_cell/3 reduced to the shared two-chip (ax-chip.ax-label) idiom used by invoices_live.ex"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/copy.ex

key-decisions:
  - "COMP-01 resolves inline per D-02 — no WorkQueueCallout component file created; Subscriptions composes directly from PageHeader/StatStrip/StatusBadge."
  - "verdict_status/1, verdict_label/1, verdict_tone/1, exposure_tone/1, webhook_tone/1 added as new private helpers in subscriptions_live.ex rather than reusing/renaming the old subscriptions_health_verdict/1 (which is removed as dead code)."
  - "Removed the now-orphaned format_date/1 %NaiveDateTime{} clause (Rule 1 auto-fix): its only caller was the deleted billing_signals_cell/3 audit line; leaving it in would have failed the mix compile --warnings-as-errors gate with an unreachable-clause warning."

patterns-established: []

requirements-completed: [REIGN-01, REIGN-02, COMP-01]

coverage:
  - id: D1
    description: "PageHeader spine matches invoices_live.ex/customers_live.ex structurally: plain ax-page, no class= override, unwrapped :stat_strip, single verdict, single primary CTA"
    requirement: "REIGN-01"
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix compile --warnings-as-errors"
        status: pass
      - kind: manual
        ref: "grep -c 'ax-kpi-row ax-subscriptions-kpi-row|Billing health overview|ax-page-compact ax-subscriptions-page' subscriptions_live.ex all return 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "6 new Copy.Subscription functions exist and are wired into the render spine + Copy defdelegate"
    requirement: "REIGN-01"
    verification:
      - kind: unit
        ref: "grep -c 'def subscriptions_index_breadcrumb|...' copy/subscription.ex returns 6"
        status: pass
    human_judgment: false
  - id: D3
    description: "Zero bespoke band <section>s remain between FlashGroup and DataTable; dead query/helper chain fully removed"
    requirement: "REIGN-02"
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix compile --warnings-as-errors"
        status: pass
      - kind: manual
        ref: "grep -c 'ax-inline-worklist|ax-audit-summary-row|ax-subscriptions-*-strip' subscriptions_live.ex returns 0; FlashGroup.flash_group immediately precedes <.live_component"
        status: pass
    human_judgment: false
  - id: D4
    description: "identity_cell/3 and billing_signals_cell/3 are zero-in-cell-action compact cells"
    requirement: "REIGN-02"
    verification:
      - kind: unit
        ref: "awk region-scoped grep for <button|ax-button across both cell function bodies returns 0 for each"
        status: pass
    human_judgment: false
  - id: D5
    description: "COMP-01 resolves inline — no new component file created"
    requirement: "COMP-01"
    verification:
      - kind: manual
        ref: "no file at accrue_admin/lib/accrue_admin/components/work_queue_callout.ex"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-19
status: complete
---

# Phase 209 Plan 02: Subscriptions PageHeader/cell reign Summary

**Rebuilt `subscriptions_live.ex`'s PageHeader spine and list cells onto the canonical Invoices/Customers shape — one StatusBadge verdict, one primary CTA, a 4-stat unwrapped StatStrip, and zero bespoke worklist bands or in-cell action buttons — with COMP-01 resolved inline (no new component file).**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2 completed
- **Files modified:** 3 (`subscriptions_live.ex`, `copy/subscription.ex`, `copy.ex`)

## Accomplishments

- **Task 1 — Header/spine rebuild:** Outer section dropped `ax-page-compact ax-subscriptions-page` down to plain `ax-page`; PageHeader lost its `class=` override entirely. Breadcrumbs became a real 2-crumb `[Home, Subscriptions]` trail (the fake, non-navigable "Billing health overview" parent is gone). The triplicated verdict collapsed to one `StatusBadge` (new `verdict_status/1` / `verdict_label/1` / `verdict_tone/1` helpers), and the three CTA-family buttons collapsed to a single primary "Open invoice queue" action (two pre-existing secondary buttons — Webhooks debug, Events audit log — kept per the phase's resolved Open Question 2). `:stat_strip` now renders `StatStrip.stat_strip` with no wrapping `<div>` and exactly 4 stats in D-03's money-at-risk order (Open invoices → Exposure → At-risk subscriptions → Failed webhooks), dropping the unsupported `tone="slate"` MRR-signal placeholder stat and the duplicate Dunning-funnel stat. Added 6 new `Copy.Subscription` functions with matching `Copy` defdelegates.
- **Task 2 — Band removal + cell rebuild:** Deleted all five bespoke `<section>` bands (invoice-strip, queue-shortcut, invoice-records, at-risk-strip, audit-strip) so `FlashGroup.flash_group` is immediately followed by `<.live_component module={DataTable}`. Removed the `:open_invoice_queue` mount assign and its entire now-dead query/helper chain (`open_invoice_queue/1`, `open_invoice_queue_base/2`, `invoice_queue_record_href/3`, `invoice_queue_due/1`, `invoice_queue_customer_label/1`, `billing_priority_title/1`). Rebuilt `identity_cell/3` to the two-line `ax-stack-xs` idiom (primary `ax-link` → `/subscriptions/:id` per D-01, secondary muted link → the customer) and `billing_signals_cell/3` to the two-chip `ax-chip.ax-label` idiom (Owner/Tax only) — both now contain zero `<button>`/in-cell `ax-button` elements. Renamed the "Signals / audit" column/card-field label to "Signals".
- `invoice_queue_path/2` and `invoice_queue_path_from_table/1` were deliberately kept (still referenced by the CTA/StatStrip and the "Open invoice queue workspace" filter chip, respectively).

## Task Commits

- `735cfb4f` — feat(209-02): rebuild Subscriptions PageHeader spine to canonical single-verdict shape
- `29326067` — feat(209-02): remove bespoke worklist bands and rebuild list cells to compact idiom

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — render/1 spine rebuild, band removal, cell rebuild, dead-code removal.
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` — 6 new Copy fns added under a new "Subscriptions list reign" section header.
- `accrue_admin/lib/accrue_admin/copy.ex` — 6 new `defdelegate` lines added adjacent to the existing `subscription_*`/`subscriptions_list_*` block.

## Decisions Made

- COMP-01 formally resolves **inline** (D-02) — no `work_queue_callout.ex` component file was created; the page composes directly from `PageHeader`/`StatStrip`/`StatusBadge`.
- `exposure_tone/1` and `webhook_tone/1` were added (not spec'd by name elsewhere) matching the plan's explicit instruction, pattern-matching on the `summary` map (`open_invoice_exposure_minor` / `failed_webhook_count`) rather than a raw scalar, for symmetry with `verdict_status/1`.
- Removed the now-orphaned `format_date/1` `%NaiveDateTime{}` clause as a Rule 1 auto-fix: its only caller was inside the deleted `billing_signals_cell/3` audit line (`row.inserted_at |> format_date()`); every remaining caller (`time_cell/1`'s four clauses) already guards on `%DateTime{}`, so the clause became genuinely dead and would have failed the `mix compile --warnings-as-errors` gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed the orphaned `format_date/1` `%NaiveDateTime{}` clause**
- **Found during:** Task 2, after removing `billing_signals_cell/3`'s audit-line caller.
- **Issue:** `mix compile --warnings-as-errors` failed with "this clause of defp format_date/1 is never used" once the only caller passing a `NaiveDateTime` (the deleted audit-fact line) was removed.
- **Fix:** Removed the dead clause; `format_date/1` now has exactly the `%DateTime{}` clause plus its `_value` fallback, matching every remaining caller's guard.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`
- **Commit:** `29326067`

## Issues Encountered

None beyond the auto-fixed dead-clause warning above.

## Known Stubs

None — every removed band's operator datum (open-invoice count, exposure $, at-risk count, failed-webhook count) is relocated into the 4-stat StatStrip or the single verdict badge, per the content-preservation must-have.

## Threat Flags

None — no new trust-boundary or interpolation surface introduced. `identity_cell/3` and `billing_signals_cell/3` continue to pass every dynamic value (`customer_label(row)`, `row.processor_id || row.id`, ownership/tax labels) through the existing `escape/1` (`Phoenix.HTML.html_escape/1` + `safe_to_string/1`) helper exactly as the pre-rebuild code did, matching T-209-01's mitigation. Cross-navigation hrefs (`customer_id`, `subscription.id`) are unescaped in `href=` attributes, consistent with the pre-existing pattern in this file and in `invoices_live.ex`'s `invoice_identity_cell/3` (T-209-02, accepted pre-existing).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `mix test test/accrue_admin/live/subscriptions_live_test.exs` is currently **5/12 red** — this is the expected, plan-documented outcome (the plan's own `<verify>` block states the not-yet-migrated test file is intentionally left red here; Plan 03 owns the test rewrite/selector migration, including the `ax-kpi-row ax-subscriptions-kpi-row` assertion at line 111).
- Plan 03 can now diff the rebuilt list against the Plan 01 pre-reign PNG baseline (`accrue_admin/test-results/admin-visuals-baseline-209/`) for density-no-regression and against the subscription-detail baseline to confirm the detail page (which still references the shared `.ax-inline-worklist*`/`.ax-audit-summary-row` classes, untouched by this plan) remains visually unbroken.
- No blockers.

---
*Phase: 209-reign-subscriptions-list-detail-css-coordination*
*Completed: 2026-07-19*

## Self-Check: PASSED

All 3 modified source files and this SUMMARY.md verified present on disk via `[ -f ... ]`. Both task commits (`735cfb4f`, `29326067`) verified present in `git log --oneline --all`.
