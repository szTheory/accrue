---
quick_id: 260620-mn0
slug: admin-sidebar-logo-lockup
date: 2026-06-20
status: complete
---

# Summary: Admin sidebar combined Accrue logo lockup

## What changed
- `accrue_admin/lib/accrue_admin/components/sidebar.ex`: mark-only fallback + two
  redundant `<p>` brand-text lines → one inline Accrue logo lockup SVG
  (`.ax-sidebar-logo-mark`, mark + "Accrue" wordmark, `currentColor` ink/wordmark
  + fixed moss accent, theme-aware). White-label `logo_url` `<img>` branch kept.
- `accrue_admin/assets/css/app.css`: `.ax-sidebar-brandmark` → `.ax-sidebar-logo-mark`
  (height-sized, width auto); removed unused `.ax-sidebar-brand-sub`.
- `accrue_admin/priv/static/accrue_admin.css`: rebuilt committed bundle.

## Result
`mix test` → 320 tests, 0 failures. Bundle carries `ax-sidebar-logo-mark` (×1);
no `ax-sidebar-brandmark`/`brand-sub` left. Fixes the duplicated "Accrue Admin"
text and renders a single combined logo graphic.

## Notes
- Wordmark path copied verbatim from `brandbook/logo/accrue-logo.svg`.
- Demo hot-reloaded via the reloadable_apps DX (task 260620-mfh) — no restart.
- `app_name` data model untouched; topbar chip + img alt still use it.
