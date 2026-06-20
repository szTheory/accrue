---
quick_id: 260620-luy
slug: admin-brand-mark
date: 2026-06-20
status: complete
---

# Summary: Accrue brand mark in admin chrome

## What changed
- `accrue_admin/lib/accrue_admin/components/sidebar.ex`: placeholder "A" → inline
  `.ax-sidebar-brandmark` SVG (ink bars `currentColor`, moss `#5E9E84` accent).
  Host `logo_url` white-label branch untouched.
- `accrue_admin/assets/css/app.css`: `.ax-sidebar-brandmark` sizing rule; theme
  adapts via inherited `currentColor` (no dark override needed).
- `accrue_admin/priv/static/accrue_admin.css`: **rebuilt committed bundle** so
  the new rule actually ships.
- `accrue_admin/lib/accrue_admin/layouts.ex`: favicon "A" → brand mark on the ink
  square (data URI mechanism kept).

## Result
`mix accrue_admin.assets.build` + `mix test` → **320 tests, 0 failures**.
No tests pinned the placeholder. The admin top-left and the browser-tab favicon
now show the real Accrue mark, theme-aware, with white-label override intact.

## Notes
- Theme correctness rides on `.ax-sidebar` foreground inheritance (dark block at
  app.css ~730) — `currentColor` flips for free.
- Brandbook source: `brandbook/logo/accrue-mark.svg` / `favicon.svg`.
