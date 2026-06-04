---
phase: 175
plan: "04"
subsystem: accrue_admin
tags: [work-queue-defaults, filter-chip-bar, persona-ia, search-field, home-ux]
dependency_graph:
  requires: ["175-01", "175-02", "175-03"]
  provides: ["work-queue-default-invoices", "work-queue-default-subscriptions", "work-queue-default-payments", "home-visible-search"]
  affects: ["invoices_live", "subscriptions_live", "charges_live", "dashboard_live", "app.css"]
tech_stack:
  added: []
  patterns:
    - "3-clause handle_params: view=all guard / connected? push_patch / passthrough"
    - "FilterChipBar with cobalt Queue chip + slate All escape-hatch chip"
    - "connected?(socket) guard prevents static-render redirect loop"
    - "ax-input-search CSS: button styled as input field, all values from --ax-* tokens"
key_files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
decisions:
  - "connected?(socket) guard on push_patch empty-params clause: LiveView 1.1 push_patch during static render causes {error, live_redirect} in tests; guarding with connected? prevents this while preserving the intended live-navigation redirect behavior"
  - "All chip active when queue_active OR all_active: the All chip must always be visible when the queue is active (escape hatch); this differs from the PATTERNS.md literal but is correct per UI-SPEC §3 persistent chip"
  - "charges_live current_path updated from /charges to /payments: consistent with table_path and sidebar nav active state"
metrics:
  duration: "15m"
  completed: "2026-06-04"
  tasks_completed: 2
  files_changed: 10
---

# Phase 175 Plan 04: Work-Queue Defaults + Home Search Summary

Work-queue default filters applied to three list screens; visible search field added to Home.

## What Was Built

**Task 1: Work-queue default filters (invoices, subscriptions, charges/payments)**

Each list screen now has a 3-clause `handle_params`:
- Clause 1: `%{"view" => "all"}` → assigns params, no redirect (sentinel prevents loop)
- Clause 2: empty params → `push_patch` to default queue URL (only when `connected?`)
- Clause 3: passthrough → assigns params as-is

Module attributes set the default status for each screen:
- `invoices_live.ex`: `@default_queue_status "open,uncollectible"`
- `subscriptions_live.ex`: `@default_queue_status "past_due,canceling"`
- `charges_live.ex`: `@default_queue_status "failed"`

FilterChipBar renders above DataTable with:
- Queue chip (cobalt, `active: queue_active`): visible when queue filter is active; `remove_href` points to `?view=all`
- All chip (slate, `active: queue_active or all_active`): always visible when either mode is active, serving as the escape hatch

`charges_live.ex` `table_path`, `current_path`, and `charge_link` all updated to `/payments`.

`build_default_params/2` preserves `?org=` for OwnerScope organization mode.

**Task 2: Visible search field on Home**

Added `<button role="search">` above the launcher grid in Zone 2 of `dashboard_live.ex`. The button uses `phx-click="open" phx-target="#global-search"` — identical to the topbar trigger pattern, avoiding LiveComponent event-targeting complexity.

New CSS classes added to `app.css`:
- `.ax-home-search`: wrapper with `margin-bottom: var(--ax-space-md)`
- `.ax-input-search`: full-width button styled as input field using `--ax-elevated`, `--ax-border`, `--ax-radius-md`, `--ax-space-sm/md` tokens
- `.ax-input-icon`: icon sizing within the field
- `.ax-input-placeholder`: `--ax-type-sm` + `--ax-muted` for placeholder text

Anti-churn enforced: attention rail, KPI strip, and recent-activity zones were NOT touched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] connected?(socket) guard on push_patch empty-params clause**
- **Found during:** Task 1 TDD RED→GREEN cycle
- **Issue:** Phoenix LiveView 1.1's `push_patch` called during the static (dead) render phase returns `{:error, {:live_redirect, ...}}` in tests, causing `live(conn, path)` to fail even when navigating to a URL that should NOT redirect (e.g. `?view=all`). The PATTERNS.md example did not include the `connected?` guard.
- **Fix:** Wrapped the empty-params `push_patch` in `if connected?(socket)` — in the static render, assigns empty params instead; in the connected state, push_patches to the default queue URL as intended. This preserves the correct runtime behavior while fixing test failures.
- **Files modified:** `invoices_live.ex`, `subscriptions_live.ex`, `charges_live.ex`
- **Commit:** 88c9cff3

**2. [Rule 2 - Missing Critical Functionality] All chip active state covers queue_active OR all_active**
- **Found during:** Task 1 GREEN phase
- **Issue:** PATTERNS.md shows `active: all_active?` for the All chip, meaning it only renders when `?view=all` is active. But the chip should always be visible when the queue filter is active (as an escape hatch) — this is the "persistent chip" semantic from UI-SPEC §3.
- **Fix:** Changed `active: all_active` to `active: queue_active or all_active` so the All chip renders whenever either mode is active (i.e., when the queue is showing, the All chip is the visible escape; when all-view is showing, the All chip confirms the mode).
- **Files modified:** `invoices_live.ex`, `subscriptions_live.ex`, `charges_live.ex`
- **Commit:** 88c9cff3

## TDD Gate Compliance

- RED gate: `test(175-04)` commit e94c9e5f — 10 failing tests
- GREEN gate: `feat(175-04)` commit 88c9cff3 — 10 tests passing

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. The `push_patch` URL construction uses `@default_queue_status` module attributes (not user input) — T-175-04-01 mitigated as planned. The `?view=all` sentinel guards prevent re-redirect loops — T-175-04-02 is scoped-query protected as designed.

## Self-Check: PASSED

- FOUND: accrue_admin/lib/accrue_admin/live/invoices_live.ex
- FOUND: accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
- FOUND: accrue_admin/lib/accrue_admin/live/charges_live.ex
- FOUND: accrue_admin/lib/accrue_admin/live/dashboard_live.ex
- FOUND: accrue_admin/assets/css/app.css
- FOUND: accrue_admin/priv/static/accrue_admin.css
- FOUND commit: e94c9e5f (test RED)
- FOUND commit: 88c9cff3 (feat GREEN)
- FOUND commit: 6efb78b1 (feat Task 2)
