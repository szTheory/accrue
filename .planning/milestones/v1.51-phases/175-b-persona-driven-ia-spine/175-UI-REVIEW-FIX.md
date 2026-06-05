---
phase: 175
fixed_at: 2026-06-04T14:54:00Z
review_path: .planning/phases/175-b-persona-driven-ia-spine/175-UI-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 175 — UI Review Fix Report

**Fixed at:** 2026-06-04T14:54:00Z
**Source review:** .planning/phases/175-b-persona-driven-ia-spine/175-UI-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

---

## Fixed Issues

### Top Fix #1: "More ▾" dropdown missing CSS positioning

**Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`, `accrue_admin/priv/static/accrue_admin.js`
**Commit:** `01b26340`
**Applied fix:**
- Added `position: relative` to `.ax-tab-more-wrapper` — establishes the positioning context so `position: absolute` on the child menu resolves correctly.
- Added `position: absolute; top: 100%; right: 0; min-width: calc(var(--ax-space-3xl) * 3)` to `.ax-tab-more-menu` — menu now overlays page content instead of expanding in document flow. `min-width` uses a `calc()` token composition (`--ax-space-3xl` = 4rem, × 3 = 12rem equivalent) to avoid a bare literal.
- Added display/gap rules to `.ax-tab-more-trigger` (flex, align-items, gap via `--ax-space-xs`).
- Added full layout + hover/focus rules to `.ax-tab-more-item`: padding via `--ax-space-sm`/`--ax-space-md`, color via `--ax-muted` resting → `--ax-primary` hover, background hover via `color-mix(in srgb, var(--ax-accent) 8%, var(--ax-elevated))`, focus ring via `--ax-focus-ring`. All values token-sourced per the no-literal constraint.
- Rebuilt `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js` (tailwindcss@3.4.17 + esbuild@0.25.3).

### Top Fix #3: "Charges" label not fully relabeled to "Payments" in customer_live

**Files modified:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`
**Commit:** `585b1273` (source) + `6808b5e0` (test update)
**Applied fix:**
- KPI summary card `label="Charges"` (line 223) → `label="Payments"`.
- KPI card `<:meta>` text updated from "Charges and invoices" to "Payments and invoices".
- `Detail.detail_section title="Charges"` (line 318) → `title="Payments"`.
- `related_items/3` entry `label: "Charges"` (line 540) → `label: "Payments"`.
- Internal `tab_display_label("charges")` function and the `tab.id = "charges"` identifier are unchanged — only user-visible strings were updated.
- Two tests in `customer_live_test.exs` that asserted `html =~ "Charges"` as a label sanity check were updated to `html =~ "Payments"` to match the new correct state.

### Top Fix #2: Work-queue empty-state copy (UI-SPEC contract)

**Files modified:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex`, `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`, `accrue_admin/lib/accrue_admin/live/charges_live.ex`
**Commit:** `4d0a4d2c`
**Applied fix:**
Each LiveView now passes computed `empty_title` and `empty_copy` to DataTable instead of static Copy function calls. Three private helpers added to each module:

- `queue_active?(params)` — returns true when `params["status"] == @default_queue_status` AND `params["view"] != "all"` (distinguishes queue-active-empty from all-view-empty).
- `queue_empty_title(params)` — returns contracted string when queue is active, falls back to the existing `Copy.*_index_empty_title()` otherwise.
- `queue_empty_copy(params)` — same pattern for body copy.

Contracted strings applied per UI-SPEC Copywriting Contract:
- Invoices queue-empty: "Queue clear" / "No open or uncollectible invoices. View All to see every invoice."
- Subscriptions queue-empty: "Nothing at risk" / "No past-due or canceling subscriptions. View All to see every subscription."
- Payments (charges) queue-empty: "No failed payments" / "Nothing failed in this view. View All to see every payment."

Generic copy is preserved for the unfiltered/All view — no regression for the non-queue case.

### Additional Finding: Modal search placeholder diverges from spec

**Files modified:** `accrue_admin/lib/accrue_admin/components/global_search.ex`
**Commit:** `4011c57f`
**Applied fix:** Changed modal input `placeholder` from `"Search customers, invoices, subscriptions..."` to the contracted `"Search customers, invoices… ⌘K"` (Unicode ellipsis + ⌘K hint, matching the topbar trigger and Home search field exactly).

---

## Deferred / Skipped

The following findings from the UI-REVIEW were explicitly noted as out of scope for this fix pass and are deferred:

**EventLive not-found flash (Pillar 6 WARNING):** Adding `plug :fetch_live_flash` to the `accrue_admin_browser` pipeline to show a flash on stale `/events/:id` redirect. Deferred — the fix is a one-line pipeline change but constitutes an architectural pipeline modification that warrants its own review cycle and is documented as a known limitation in 175-01-SUMMARY.

**Search error state — no rendering path for `on_timeout` (Pillar 6 WARNING):** `global_search.ex` silently discards `{:exit, _}` task results with no user-visible message. The UI-SPEC specifies "Search is unavailable right now. Try again in a moment." Deferred — requires adding a `:search_error` assign and a render branch; low urgency as timeouts are rare and the silent-empty UX is benign.

**Pre-existing v1.50 literal font-size items (Pillar 4 noted):** `.ax-field-label`, `.ax-dropdown-item-label`, `.ax-tab` with literal `0.875rem` values. These are anti-churn surfaces explicitly excluded per the review's own note. Not touched.

---

## Test Suite

227 tests, 0 failures (run with `--seed 0` in worktree with deps symlinked from main project).
The two pre-existing test assertions `html =~ "Charges"` in `customer_live_test.exs` were updated to `html =~ "Payments"` as a direct consequence of the relabeling fix — these are test correctness updates, not behavior regressions.

---

_Fixed: 2026-06-04T14:54:00Z_
_Fixer: Claude Sonnet 4.6 (gsd-code-fixer)_
_Iteration: 1_
