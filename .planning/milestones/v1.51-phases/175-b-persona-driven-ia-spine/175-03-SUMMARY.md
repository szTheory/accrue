---
phase: 175
plan: "03"
subsystem: accrue_admin
tags:
  - sidebar
  - navigation
  - routing
  - css
  - redirect
  - IA-02
  - IA-06
dependency_graph:
  requires:
    - "175-01"
    - "175-02"
  provides:
    - "collapsible-sidebar-groups"
    - "status-toned-badges"
    - "redirect-controller"
    - "payments-routes"
  affects:
    - "175-04"
    - "175-05"
    - "175-06"
    - "175-07"
tech_stack:
  added: []
  patterns:
    - "Phoenix.Controller redirect-only controller"
    - "CSS color-mix token composition (no literals)"
    - "aria-expanded / aria-controls collapsible group pattern"
    - "phx-hook SidebarCollapse wiring"
key_files:
  created:
    - accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex
  modified:
    - accrue_admin/lib/accrue_admin/components/sidebar.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
    - accrue_admin/test/accrue_admin/router_test.exs
decisions:
  - "URI.encode/1 applied to :id in RedirectController.charges_show/2 per threat model T-175-03-02"
  - "Added id attr to collapsible <section> elements (required by phx-hook LiveView constraint)"
  - "live('/events/:id') route added even though EventLive doesn't exist yet — Phoenix LiveView emits a compile warning but does not fail compilation; Wave 3 will create the module"
  - "Deferred live('/events/:id') compile-warning is acceptable per plan spec; no test failure occurs"
  - "1px (border) and 2px (focus outline) are established CSS constants used throughout app.css — not treated as token-violating literals per codebase convention"
metrics:
  duration: "4 minutes"
  completed: "2026-06-04T08:19:10Z"
  tasks_completed: 2
  files_changed: 6
---

# Phase 175 Plan 03: Sidebar Rewrite + Route Redirects Summary

Collapsible persona-shaped sidebar with status-toned badges; /charges bookmark preservation via RedirectController; /payments routes wired to existing ChargesLive.

## What Was Built

### Task 1: Sidebar.ex rewrite + CSS token-gap classes + asset rebuild (commit de7a0b85)

Rewrote `sidebar.ex` to support the IA-02 persona-shaped navigation:

- `grouped_items/1` now returns `{group, items, group_meta}` 3-tuples. `group_meta = %{collapsible: bool, badge: integer|nil, tone: atom}` is derived from the first item of each group (all items in a group share these fields from `nav.ex`).
- Collapsible groups (Recovery, Developer, Catalog) render a `<button>` with class `ax-sidebar-group-label ax-sidebar-group-toggle`, `aria-expanded`, `aria-controls`, `data-collapse-toggle="true"`, and `phx-hook="SidebarCollapse"`. The section element carries `id="sidebar-group-section-{slug}"` (required by LiveView for phx-hook).
- Badge renders only when `group_meta.badge` is a positive integer; tone-matched class (`ax-badge-warning` for Recovery, `ax-badge-danger` for Developer, default for Catalog).
- Non-collapsible groups (Billing, Connect, nil/Home) render a static `<p class="ax-sidebar-group-label">`.
- Link list wrapped in `<div id="sidebar-group-links-{slug}" hidden={not group_initially_expanded?(group_meta)}>`. Default: expanded when `collapsible: false` OR `badge > 0`.
- Added helpers: `group_initially_expanded?/1`, `badge_class/1`, `badge_aria_label/2`, `badge_tone/1`, `slugify/1`.

Added 5 CSS token-gap classes to `app.css` (all values from `ax-*` tokens, no literal hex/px dimension values):
- `.ax-badge-warning`: `color-mix(in srgb, var(--ax-warning) 12%, var(--ax-elevated))` background + `var(--ax-warning-readable)` text.
- `.ax-badge-danger`: `color-mix(in srgb, var(--ax-danger) 12%, var(--ax-elevated))` background + `var(--ax-danger-readable)` text.
- `.ax-sidebar-group-chevron`: muted color, flex-none, `var(--ax-transition-transform)`. Rotates 90deg when `[aria-expanded="true"]` parent set.
- `.ax-sidebar-group-toggle`: strips button chrome (background: none, border: none, cursor: pointer); matches `.ax-sidebar-group-label` visual appearance; focus ring via `var(--ax-focus-ring)`.
- `.ax-tab-more-menu`: elevated surface with border + radius + shadow + z-popover + padding — all `ax-*` tokens.

Asset bundle rebuilt: `priv/static/accrue_admin.css` committed.

### Task 2: RedirectController + router.ex reshaping (commit 11dfc35e)

Created `AccrueAdmin.RedirectController`:
- `charges_index/2`: derives mount_path via `String.replace_suffix(conn.request_path, "/charges", "")`, redirects to `{mount_path}/payments{?qs}`.
- `charges_show/2`: same pattern with `/charges/{id}` suffix; `URI.encode/1` applied to `:id` to prevent path traversal (T-175-03-02 mitigated).
- Uses `Phoenix.Controller, formats: []` (redirect-only, no view templates).

Router changes in `router.ex`:
- Removed `live("/charges", ...)` and `live("/charges/:id", ...)` from `live_session` block.
- Added `live("/payments", AccrueAdmin.Live.ChargesLive, :index)` and `live("/payments/:id", AccrueAdmin.Live.ChargeLive, :show)` inside `live_session`.
- Added `live("/events/:id", AccrueAdmin.Live.EventLive, :show)` route stub (Wave 3 creates EventLive; emits a compile warning but does not break compilation or tests).
- Added `get("/charges", AccrueAdmin.RedirectController, :charges_index)` and `get("/charges/:id", AccrueAdmin.RedirectController, :charges_show)` **outside** the `live_session` block, inside the `scope` block after `pipe_through(:accrue_admin_browser)`.

Removed `@tag :pending` + `@tag :skip` from the two redirect tests scaffolded in Plan 175-01. Both tests now pass green.

## Test Results

```
24 tests, 0 failures
```

- 18 navigation component tests (all pre-existing + 6 new sidebar collapsible group tests)
- 6 router tests (all pre-existing + 2 redirect tests un-pending'd)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added id attr to collapsible <section> elements**
- **Found during:** Task 1 — compilation error from Phoenix.LiveView.Tokenizer.ParseError
- **Issue:** `phx-hook` requires the element to have an `id` attribute; the original design in PATTERNS.md showed `id` on the `section` but the initial implementation omitted it.
- **Fix:** Added `id={"sidebar-group-section-#{slugify(group)}"}` to collapsible section elements.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/sidebar.ex`
- **Commit:** de7a0b85

**2. [Rule 3 - Blocking] Added `formats: []` to `use Phoenix.Controller`**
- **Found during:** Task 2 — compilation warning about missing `:formats` option.
- **Issue:** Phoenix.Controller in Phoenix 1.8 requires explicit formats declaration to silence compatibility warning.
- **Fix:** Changed `use Phoenix.Controller` to `use Phoenix.Controller, formats: []` (redirect-only controller renders no views).
- **Files modified:** `accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex`
- **Commit:** 11dfc35e

## Known Stubs

None — the sidebar fully renders collapsible groups with live data from `Nav.items/3` + `nav_attention_counts`. The `/events/:id` route stub points to a not-yet-existing `EventLive` module; Wave 3 (Plan 175-05) creates the module and resolves the compile warning.

## Threat Flags

No new unplanned threat surface. T-175-03-02 (open redirect via :id) mitigated as planned via `URI.encode/1`. T-175-03-01 (redirect bypasses live_session auth) is a non-issue — the redirect only sends 302 and the destination `/payments` is inside `live_session` which runs `AuthHook`.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| sidebar.ex exists | FOUND |
| redirect_controller.ex exists | FOUND |
| router.ex exists | FOUND |
| app.css exists | FOUND |
| priv/static/accrue_admin.css exists | FOUND |
| Commit de7a0b85 (task 1) | FOUND |
| Commit 11dfc35e (task 2) | FOUND |
| .ax-badge-warning in app.css | FOUND |
| .ax-badge-danger in app.css | FOUND |
| .ax-sidebar-group-chevron in app.css | FOUND |
| .ax-sidebar-group-toggle in app.css | FOUND |
| .ax-tab-more-menu in app.css | FOUND |
| live("/payments") in router | FOUND |
| GET /charges redirect in router | FOUND |
| live("/charges") removed from router | CONFIRMED REMOVED |
