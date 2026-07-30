---
phase: 210-reign-home-certify-answer-first-ia-copy-integrity
reviewed: 2026-07-19T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - accrue_admin/lib/accrue_admin/components/stat_strip.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
  - accrue_admin/assets/css/app.css
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
resolution:
  WR-01: fixed (e98d71af — verdict keys off all four attention signals + regression test)
  WR-02: fixed (e98d71af — launcher-tile :focus-visible ring restored, bundle rebuilt)
  IN-01: advisory/open (micro-optimization; verdict recomputed per render)
  IN-02: advisory/open (deliberate StatusBadge palette constraint — no danger tone)
  IN-03: advisory/open (orphaned Copy catalog strings retained)
  IN-04: advisory/open (stretched-link aria-label verbosity nit)
status: warnings_resolved
---

# Phase 210: Code Review Report

**Reviewed:** 2026-07-19
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found (advisory / non-blocking)

## Summary

Phase 210 recomposes the Home dashboard onto the shared PageHeader/StatStrip/StatusBadge/EmptyState spine, adds Copy strings, and restructures the shared `StatStrip` `<dl>` for axe cleanliness (stretched-link inside `<dd>`) plus focus-ring/launcher CSS. Component usages all match their `attr`/`slot` contracts (verified against `page_header.ex`, `flash_group.ex`, `empty_state.ex`, `status_badge.ex`), all referenced CSS custom properties resolve in `theme.css`, and the new Copy functions are correctly added to the export allowlist. Compile + unit + e2e gates are reported green.

No Critical (security / crash / data-loss) issues found. The most significant finding is a **verdict/exceptions contradiction**: the single header health verdict is derived only from `open_invoice_count`, so it can render "Healthy" (green) while the same page lists priority webhook/dunning/meter exceptions below it — directly undercutting the phase's "one correct answer-first verdict" thesis. A secondary a11y concern: the new launcher tiles suppress the focus outline in favor of a hover-identical shadow.

## Warnings

> **RESOLVED (e98d71af):** `verdict_status/1` now returns `:action_required` on any of the four attention signals (`open_invoice_count`, `blocked_webhook_count`, `past_due_subscription_count`, `failed_meter_event_count`), mirroring `attention_items/3`. Regression test in `dashboard_live_test.exs` locks the `open_invoice_count == 0` + webhook-signal case. phase194/phase199 e2e gates unaffected (default seed still shows "Action required").

### WR-01: Home health verdict ignores webhook / dunning / meter exceptions — can show "Healthy" while priority exceptions are listed on the same page

**File:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex:465-466`

**Issue:** The header verdict badge is computed solely from open invoices:

```elixir
defp verdict_status(%{open_invoice_count: count}) when count > 0, do: :action_required
defp verdict_status(_stats), do: :healthy
```

But the attention rail (`attention_items/3`, lines 416-461) is driven by **four independent signals**: `open_invoice_count`, `blocked_webhook_count`, `past_due_subscription_count`, and `failed_meter_event_count`. Concretely, when `open_invoice_count == 0` but `blocked_webhook_count > 0` (or past-due subs / failed meter events > 0):

- The header renders a **moss/green "Healthy"** verdict badge (`data-ax-health-verdict="true"`).
- The attention-rail heading renders **"Priority exceptions"** (`attention_rail_heading/1`, non-empty branch) with a **P2/P3/P4 exception row** beneath it.
- The StatStrip renders **"Failed webhooks: N failed webhooks"** in **amber** (`stat_webhook_tone/1`).

So the single "answer-first" verdict contradicts the exceptions the page itself surfaces. The pre-Phase-210 code keyed the headline off `@attention` (`dashboard_health_headline(_attention) -> "Billing health: Unhealthy"` whenever `@attention != []`), so this is a **behavioral regression** in the verdict's fidelity. The `verdict_status/1` predicate was copied verbatim from `subscriptions_live.ex:345`, but on Subscriptions the summary is invoice-scoped, whereas Home's verdict is meant to be the overall billing-health answer over a strictly larger signal set.

**Fix:** Key the verdict off the same signals the rail uses (i.e. any exception → `:action_required`). For example:

```elixir
defp verdict_status(%{
       open_invoice_count: inv,
       blocked_webhook_count: wh,
       past_due_subscription_count: pd,
       failed_meter_event_count: meter
     })
     when inv > 0 or wh > 0 or pd > 0 or meter > 0,
     do: :action_required

defp verdict_status(_stats), do: :healthy
```

Or, more directly, derive it from the already-computed `@attention` list (`if @attention == [], do: :healthy, else: :action_required`) so the verdict and the rail can never disagree.

> **RESOLVED (e98d71af):** `.ax-home-launcher-card:focus-visible` split out of the hover rule and given the standard admin focus ring (`outline: 2px solid var(--ax-focus-ring); outline-offset: 2px; box-shadow: var(--ax-focus-shadow)`), matching the attention-rail focus-ring treatment. Committed `priv/static/accrue_admin.css` bundle rebuilt. admin-a11y gate unchanged (still only the 2 deferred dark-mode contrast items).

### WR-02: Launcher tiles suppress the focus outline; keyboard focus is indistinguishable from hover

**File:** `accrue_admin/assets/css/app.css:6342-6347`

**Issue:** The new primary-navigation launcher tiles are `<a>` elements whose focus state collapses onto the same visual as hover, with the outline explicitly removed:

```css
.ax-home-launcher-card:hover,
.ax-home-launcher-card:focus-visible {
  box-shadow: var(--ax-shadow-md);
  outline: none;
}
```

A keyboard user tabbing through the three task tiles gets only `--ax-shadow-md` — identical to hover and with no ring — so there is no distinct, unambiguous focus indicator (WCAG 2.4.7 / 2.4.11). This is inconsistent with the phase's own posture: Plan 03 went out of its way to *restore* the `--ax-focus-ring` on the attention-rail focusables (app.css:7725-7735) precisely because an `outline: none` was swallowing the focus ring there. The launcher tiles reintroduce the same pattern without the ring.

**Fix:** Give `:focus-visible` a distinct ring rather than reusing the hover shadow, e.g.:

```css
.ax-home-launcher-card:focus-visible {
  outline: 2px solid var(--ax-focus-ring);
  outline-offset: 2px;
  box-shadow: var(--ax-focus-shadow);
}
```

## Info

### IN-01: `verdict_status(@stats)` recomputed three times per render

**File:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex:71-75`

**Issue:** The header calls `verdict_status(@stats)` once for `status`, and again inside `verdict_label(verdict_status(@stats))` and `verdict_tone(verdict_status(@stats))` — three evaluations of the same pure function per render.

**Fix:** Compute once (assign in `mount`, or a `<% status = verdict_status(@stats) %>` binding) and pass the atom to `verdict_label/1` and `verdict_tone/1`.

### IN-02: `attention_status_badge_tone/1` collapses "warning" and "danger" to the same amber

**File:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex:495-498`

**Issue:** Both `"warning"` and `"danger"` map to `"amber"`, so the P2 danger row (webhooks) is visually indistinguishable from the P1/P3 warning rows. The old markup carried a distinct `ax-attention-dot-danger` tone. This is a constrained loss — StatusBadge's palette (moss/cobalt/amber/slate/ink) has no dedicated danger/red — but the severity distinction is gone.

**Fix:** Accept as a deliberate palette constraint, or introduce a distinct StatusBadge danger tone if severity differentiation matters for operators.

### IN-03: Orphaned Copy strings after customer-tile and verdict-headline removal

**File:** `accrue_admin/lib/accrue_admin/copy.ex:1318, 1361, 1366`

**Issue:** With the customer launcher tile removed and the old headline path deleted, `home_intro_headline/0`, `home_launcher_customers_title/0`, and `home_launcher_customers_meta/0` are no longer referenced by `dashboard_live.ex`. They remain public catalog functions (no compiler warning), but are now dead relative to Home.

**Fix:** Confirm no other surface consumes them; if none, remove them (and their allowlist entries) or leave a comment noting they are intentionally retained for the copy catalog.

### IN-04: StatStrip stretched-link aria-label repeats the value already present as `<dd>` text

**File:** `accrue_admin/lib/accrue_admin/components/stat_strip.ex:41-47`

**Issue:** The `<dd>` renders `<span class="ax-stat-value-text">value</span>` and then the overlay `<a aria-label={"#{label}: #{value}"}>`. In screen-reader browse mode the value is announced as part of the `<dd>` and again as the link's accessible name, yielding mild redundancy ("Open invoices … 3 invoices … Open invoices: 3 invoices, link"). The structure is axe-clean and functionally correct; this is a verbosity nit, not a defect.

**Fix:** Optional — the label alone (`aria-label={"#{label}, view details"}`) would still give the link a meaningful name without duplicating the value.

---

_Reviewed: 2026-07-19_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
