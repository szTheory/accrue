---
quick_id: 260620-luy
slug: admin-brand-mark
date: 2026-06-20
---

# Quick Task: Wire the real Accrue brand mark into the admin chrome

## Problem

`/admin/customers` showed a placeholder letter "A" top-left, not the Accrue
logo. The sidebar only renders a logo when a host white-label `logo_url` is set
(defaults to `nil`), falling back to `<span class="ax-sidebar-mark">A</span>`;
the favicon was likewise an "A" letterform. The real v1.52 brand mark (stepped
ascending bars + moss `#5E9E84` accent) lived in `brandbook/logo/` but was never
bundled into `accrue_admin`.

## Fix (library default, theme-aware; white-label still overrides)

1. **`accrue_admin/lib/accrue_admin/components/sidebar.ex`** — replaced the
   fallback `<span>A</span>` with an inline `<svg class="ax-sidebar-brandmark">`
   of the brand mark: ink bars `fill="currentColor"`, moss accent bar
   `fill="#5E9E84"`. Kept the `@brand.logo_url` `<img>` branch unchanged.
2. **`accrue_admin/assets/css/app.css`** — added `.ax-sidebar-brandmark`
   (2.25rem square, `flex-shrink:0`). No theme override needed: the ink bars
   inherit the sidebar foreground via `currentColor`, which the existing
   `html.accrue-admin[data-theme="dark"] .ax-sidebar` block already flips; the
   moss accent is constant. **Rebuilt the committed bundle**
   (`mix accrue_admin.assets.build`) → regenerated `priv/static/accrue_admin.css`.
3. **`accrue_admin/lib/accrue_admin/layouts.ex`** — replaced the `@favicon_svg`
   "A" letterform with the brand mark on a rounded `#111418` ink square
   (`#FAFBFC` bars + moss accent) for 16px legibility; kept the base64 data-URI
   mechanism.

## Out of scope (unchanged)
- `app_name` ("Billing"), the "Accrue Admin" subtitle, the topbar brand chip.

## Verification
- `cd accrue_admin && mix accrue_admin.assets.build` then `mix test` →
  **320 tests, 0 failures**. No tests pinned the placeholder "A"/favicon.
- Bundle confirmed to contain `.ax-sidebar-brandmark`.
- Visual (manual): `make up` → `/admin/customers` shows the stepped mark, flips
  with the theme toggle, favicon shows in the tab.
