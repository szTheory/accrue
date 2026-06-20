---
quick_id: 260620-mn0
slug: admin-sidebar-logo-lockup
date: 2026-06-20
---

# Quick Task: Admin sidebar — combined Accrue logo lockup

## Problem

The sidebar brand block rendered the mark SVG **plus two always-on text lines**
— `<p class="ax-sidebar-name">{@brand.app_name}</p>` and a hardcoded
`<p class="ax-sidebar-brand-sub">Accrue Admin</p>`. The demo host sets
`app_name = "Accrue Admin"`, so "Accrue Admin" appeared **twice** as live DOM
text next to a separate mark. The user wanted a single combined logo graphic and
no brand text in the DOM.

## Fix

1. `accrue_admin/lib/accrue_admin/components/sidebar.ex`: replaced the mark-only
   fallback + the two `<p>` lines with the **full Accrue lockup as one inline
   SVG** (`.ax-sidebar-logo-mark`, viewBox `0 0 3974.5 994`, `role="img"
   aria-label="Accrue"`): mark group (ink bars `currentColor` + moss `#5E9E84`)
   followed by the wordmark path copied verbatim from
   `brandbook/logo/accrue-logo.svg` (fill → `currentColor`). The host
   `@brand.logo_url` `<img>` white-label branch is unchanged. Both `<p>` lines
   deleted.
2. `accrue_admin/assets/css/app.css`: replaced obsolete `.ax-sidebar-brandmark`
   with `.ax-sidebar-logo-mark { height: 2rem; width: auto; max-width: 100%;
   display: block; }` (no `color` → inherits sidebar foreground = theme-aware).
   Removed the now-unused `.ax-sidebar-brand-sub` rule; left `.ax-sidebar-name`
   (shared selector) untouched. Rebuilt the committed
   `priv/static/accrue_admin.css` bundle.

## Out of scope (unchanged)
- favicon (layouts.ex), topbar brand chip, brand plug / `app_name` data model.

## Verification
- `mix accrue_admin.assets.build` + `mix test` → **320 tests, 0 failures**.
- Bundle: `ax-sidebar-logo-mark` = 1; `ax-sidebar-brandmark`/`brand-sub` = 0.
- No tests pinned the removed markup.
- Running demo hot-recompiled accrue_admin on the next request (reloadable_apps),
  no restart — hard-refresh `/admin/customers` shows one "▙ Accrue" lockup, no
  duplicated text.
