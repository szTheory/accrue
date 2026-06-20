---
phase: quick-260620-qkx
plan: 01
subsystem: accrue_admin
status: complete
tags: [admin-ui, accessibility, csp, loading-bar, chrome-dedup]
requires:
  - accrue_admin shell (sidebar, topbar, breadcrumbs)
provides:
  - utility-bar topbar (search · menu · theme only)
  - single content <h1> per admin page
  - vendored MIT topbar navigation loading bar wired to phx:page-loading events
affects:
  - every mounted admin LiveView (list, detail, dashboard, analytics, dev)
tech-stack:
  added:
    - vendored MIT topbar 3.0.0 (assets/vendor/topbar.js, no mix/npm dep)
  patterns:
    - CSSOM property-setter canvas styling is not governed by CSP style-src
key-files:
  created:
    - accrue_admin/assets/vendor/topbar.js
  modified:
    - accrue_admin/lib/accrue_admin/components/topbar.ex
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
    - accrue_admin/lib/accrue_admin/components/detail.ex
    - accrue_admin/lib/accrue_admin/components/sidebar.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/assets/js/app.js
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
    - 16 live/dev page modules (hero h2→h1, eyebrow removals)
    - accrue_admin/test/accrue_admin/components/app_shell_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
decisions:
  - "No CSP change: vendored topbar styles its canvas via CSSOM property setters, which style-src does not govern — left csp_plug.ex strict (overrode the plan's B4 unsafe-inline step)."
metrics:
  duration_min: 6
  completed: 2026-06-20
  tasks: 2
  files: 28
---

# Quick 260620-qkx: De-duplicate Admin Orientation Chrome + Navigation Loading Bar Summary

Collapsed the admin topbar to a pure utility bar (search · menu · theme), promoted each page's visible hero to the document's single `<h1>`, removed the 9 redundant page-header eyebrows, and vendored + wired the canonical MIT `topbar` navigation loading bar to LiveView `phx:page-loading` events — **with no CSP relaxation** (the plan's proposed `style-src 'unsafe-inline'` was overridden and proved unnecessary).

## What Was Built

**Part A — Orientation chrome de-duplication (commit `ae5c32d4`)**
- `topbar.ex` reduced to a utility bar: `<header class="ax-topbar">` → skip link (first focusable child) → `ax-topbar-actions` (search trigger, menu toggle, ThemePicker). Removed the `ax-topbar-copy` block (app_name eyebrow + page_title `ax-heading`) and the entire `ax-topbar-brand-chip`. Dropped the now-unused `:brand` and `:page_title` attrs; kept `:theme`.
- `app_shell.ex` `<Topbar.topbar>` call passes only `theme={@theme}`; the `:page_title` / `:brand` assigns on app_shell itself are intact (page_title still feeds `layouts.ex` document `<title>`; brand still flows to the sidebar).
- Single content `<h1>` per page: 16 list/dashboard/analytics/dev heroes changed `<h2 class="ax-display">`→`<h1 class="ax-display">`, and `detail.ex` `summary_card` title `<h2 class="ax-summary-title">`→`<h1>` (covers every detail page incl. analytics/campaign).
- Removed 9 redundant page-header eyebrows (subscriptions, customers, charges, invoices, coupons, promotion_codes, connect_accounts, events, analytics/recovery, webhooks "Webhook operations"). Kept all in-card/section `ax-eyebrow` labels and the detail summary-card eyebrow. Dev-page eyebrows were not in the locked 9-item list, so they were kept (only their heroes promoted).
- Removed the now-orphaned `billing_events_eyebrow/1` private helper (grep-confirmed zero callers; left the `Copy` delegates untouched to avoid widening scope).
- Sidebar brand lockup accessible name = `@brand.app_name` (SVG `aria-label` + `<title>`), white-label correct.
- Re-pointed `app_shell_test` (brand honored via sidebar aria-label/title; refutes brand chip + topbar page-title `ax-heading`) and removed the stale `invoices_index_eyebrow` assertion from `invoices_live_test`.

**Part B — Navigation loading bar (commit `c16eca09`)**
- Vendored canonical MIT `topbar` 3.0.0 at `assets/vendor/topbar.js` (ESM, `export default topbar`, MIT header retained verbatim, no mix/npm dep).
- `app.js` imports it, reads `--ax-accent` (fallback `#5D79F6`), `topbar.config({ barColors: {0: accent}, shadowColor: "rgba(0,0,0,.15)", barThickness: 2 })`, and wires `phx:page-loading-start` (`show(reduce.matches ? 0 : 300)`) / `phx:page-loading-stop` (`hide()`) with `prefers-reduced-motion` handling. All existing hooks/`liveSocket` setup untouched.
- Rebuilt and committed both `priv/static/accrue_admin.{js,css}` (admin serves the committed bundle; `assets_test.exs` asserts the new md5).

## CSP Security-Boundary Finding (override applied — NO relaxation)

The plan's step B4 proposed adding `'unsafe-inline'` to the admin `style-src` to make the topbar canvas render. **This was explicitly overridden — I did NOT weaken CSP.**

Investigation: the vendored canonical `topbar` 3.0.0 positions and fades its `<canvas>` exclusively via **individual CSSOM property setters** — `canvas.style.position = "fixed"`, `style.top/left/right/margin/padding = 0`, `style.zIndex = 100001`, and `canvas.style.opacity` during show/hide. Per the CSP spec, programmatic CSSOM style-property mutations are **NOT** governed by `style-src` (only `<style>` elements, `style=` attributes, `el.style.cssText = …`, and `setAttribute("style", …)` are). I grep-confirmed the vendored file contains **no `cssText` and no `setAttribute("style", …)`**.

Result: the loading bar works under the existing strict `style-src 'self' 'nonce-#{nonce}'`. **`csp_plug.ex` was left untouched** — `git diff` does not include it, and no `'unsafe-inline'` was added to any directive. This closes threat T-qkx-01 by avoiding the relaxation entirely rather than accepting it.

## Heroes Promoted to `<h1>` (17 sites)

subscriptions, customers, invoices, charges, coupons, promotion_codes, connect_accounts, events, webhooks, dashboard, analytics/recovery (all `ax-display`), dev/clock, dev/fake_inspect, dev/webhook_fixture, dev/component_kitchen, dev/email_preview (all `ax-display`), plus `detail.ex` `summary_card` (`ax-summary-title`, covers all detail pages).

## Orphaned Functions Removed

- `billing_events_eyebrow/1` (private, in `events_live.ex`) — sole caller was the removed page-header eyebrow. The two `Copy.billing_events_eyebrow_organization/0` / `_global/0` delegates were left in place (scope-narrowing per "grep first, remove only zero-reference").

## Deviations from Plan

**1. [Override directive] CSP `style-src` left strict (plan B4 NOT applied)**
- Plan proposed adding `'unsafe-inline'` to admin `style-src`. Per explicit task override, I confirmed via grep that the vendored topbar uses only CSSOM property setters (not `cssText`/`setAttribute('style')`), which `style-src` does not govern. No CSP change was needed or made. `csp_plug.ex` is absent from the diff.

No other deviations — Parts A and B otherwise executed exactly as written.

## Verification

From `accrue_admin/`:
- `mix compile --warnings-as-errors` — clean (no warnings).
- `mix accrue_admin.assets.build` — succeeds (`accrue_admin.js` 146.0kb).
- `mix test` — **325 tests, 0 failures** (incl. `components/app_shell_test.exs`, `components/navigation_components_test.exs`, `live/invoices_live_test.exs`, `assets_test.exs`, the live suites, and the axe-a11y / component-lab guardrails — single-`<h1>` `page-has-heading-one` green).
- `grep -c topbar priv/static/accrue_admin.js` — 2 (≥ 1).
- `ax-topbar-brand-chip` — GONE from `priv/static/accrue_admin.css` (rc=1); `ax-eyebrow` and `ax-display` — both PRESENT.
- `git diff` — does NOT touch `csp_plug.ex`; does NOT stage `examples/accrue_host/mix.lock` (pre-existing dirty, untouched) or `.planning/research/.cache/`.

## Future Seed (deferred, not built)

A shared `page_header` component (breadcrumb + hero + page-copy) would consolidate the ~17 hand-rolled `ax-page-header` blocks across list/dashboard/analytics/dev pages and centralize the single-`<h1>` invariant. Worthwhile but out of scope for this quick task.

## Self-Check: PASSED

- `accrue_admin/assets/vendor/topbar.js` — FOUND
- `accrue_admin/priv/static/accrue_admin.js` / `.css` — FOUND (rebuilt + committed)
- Commit `ae5c32d4` (Part A) — FOUND
- Commit `c16eca09` (Part B) — FOUND
