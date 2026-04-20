---
phase: 29-mobile-parity-and-ci
plan: "02"
status: complete
---

## Outcome

- Added `initShellNav()` in `accrue_admin/assets/js/hooks/accrue_shell_nav.js` (capture-phase Menu toggle on `data-sidebar-toggle`, Escape closes `ax-shell-nav-open`, optional close on `.ax-sidebar a.ax-sidebar-link` click).
- Wired `initShellNav` from `assets/js/app.js` `ready()`.
- Mobile-only CSS (`max-width: 1023.98px`) shows fixed `.ax-sidebar` overlay when `html.accrue-admin.ax-shell-nav-open`.
- Rebuilt `priv/static/accrue_admin.js` and `accrue_admin.css` via `mix accrue_admin.assets.build`.
- New Playwright `e2e/verify01-admin-mobile.spec.js`: MOB overflow journey + MOB Menu/Escape; `chromium-mobile` only; sidebar-scoped nav locators.

## Self-Check

PASSED — `npx playwright test e2e/verify01-admin-mobile.spec.js --project=chromium-mobile`  
PASSED — `cd accrue_admin && mix test`

## key-files.created

- `accrue_admin/assets/js/hooks/accrue_shell_nav.js`
- `examples/accrue_host/e2e/verify01-admin-mobile.spec.js`
