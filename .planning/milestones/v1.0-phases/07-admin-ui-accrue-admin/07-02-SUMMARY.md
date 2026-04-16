---
phase: 07-admin-ui-accrue-admin
plan: 02
subsystem: ui
tags: [phoenix, liveview, theme, csp, tailwind]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Mountable router macro, hashed asset routes, and package-owned root layout boundary
provides:
  - Responsive admin shell with sidebar/topbar navigation
  - Cookie-backed `light|dark|system` theme pipeline with anti-FOUC ordering
  - Router-owned branding and CSP assigns sourced from `Accrue.Config`
affects: [07-03, 07-04, 07-05, 07-06, 07-07, 07-08, 07-09, 07-10, 07-11, 07-12]
tech-stack:
  added: []
  patterns: [semantic CSS token layering over brand palette, router-owned CSP nonce + theme session payload, package-private Tailwind preset]
key-files:
  created:
    - accrue_admin/assets/css/app.css
    - accrue_admin/assets/js/hooks/accrue_theme.js
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
    - accrue_admin/test/accrue_admin/theme_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/layouts.ex
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/brand_plug.ex
    - accrue_admin/lib/accrue_admin/csp_plug.ex
    - accrue_admin/priv/static/accrue_admin.css
key-decisions:
  - "Brand values continue to flow from `Accrue.Config.branding/0`; the admin package only derives display-safe app name, logo URL, and accent contrast."
  - "Theme persistence lives in the `accrue_theme` cookie with `system` as the only fallback for invalid client input in both Plug and browser paths."
  - "The shell ships as semantic CSS plus a private Tailwind preset/config pair so later admin components can reuse tokens without depending on host tooling."
patterns-established:
  - "Root layout ordering pattern: anti-FOUC script before brand/app styles, runtime accent override after styles, admin bundle last."
  - "Router session payload pattern: asset paths, CSP nonce, brand map, and sanitized theme are bundled under `session[\"accrue_admin\"]`."
requirements-completed: [ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-06]
duration: 8m
completed: 2026-04-15
---

# Phase 7 Plan 02: Admin Theme and Shell Summary

**Responsive admin shell with router-owned branding, CSP nonce enforcement, and cookie-backed light/dark/system theme persistence**

## Performance

- **Duration:** 8m
- **Started:** 2026-04-15T16:53:00Z
- **Completed:** 2026-04-15T17:01:15Z
- **Tasks:** 1
- **Files modified:** 21

## Accomplishments

- Replaced the placeholder admin root with a real shell: sticky topbar, desktop sidebar, mobile-first content framing, and explicit text labels for the topbar controls.
- Implemented the theme pipeline end-to-end with semantic CSS tokens, `data-theme="light|dark|system"`, cookie/localStorage persistence, and anti-FOUC head ordering.
- Added `AccrueAdmin.BrandPlug` and `AccrueAdmin.CSPPlug` as router-owned boundaries that sanitize the theme cookie, derive safe brand assigns from `Accrue.Config`, and propagate a CSP nonce into the LiveView session payload.

## Task Commits

1. **Task 1: Implement the admin theme pipeline and responsive root shell** - `9c5b69d` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/layouts.ex` - root layout with anti-FOUC script, brand stylesheet ordering, runtime accent override, and external admin bundle loading.
- `accrue_admin/lib/accrue_admin/router.ex` and `assets.ex` - session payload now carries brand/theme/CSP data and serves a dedicated `brand.css` asset route alongside the app bundle.
- `accrue_admin/lib/accrue_admin/brand_plug.ex` and `csp_plug.ex` - sanitize the theme cookie, resolve display-only branding from `Accrue.Config.branding/0`, and emit nonce-scoped CSP headers.
- `accrue_admin/lib/accrue_admin/components/app_shell.ex`, `sidebar.ex`, and `topbar.ex` - layout composition only, with no page-local data loading mixed into the shared shell.
- `accrue_admin/assets/css/*.css`, `assets/js/*.js`, and `assets/tailwind*.js` - private semantic token source files and theme control behavior for future asset rebuilds.
- `accrue_admin/priv/static/accrue_admin.css` and `accrue_admin.js` - committed bundle contents served by the package-owned asset controller.
- `accrue_admin/test/accrue_admin/theme_test.exs` plus router/assets test updates - regression coverage for theme sanitization, session wiring, and load-bearing root-layout ordering.

## Decisions Made

- Kept admin branding display-only and derived contrast locally instead of introducing any new persisted branding authority.
- Treated `system` as the canonical fallback theme in both Plug and JS paths so client-controlled cookie tampering cannot force unknown states into the layout.
- Served `brand.css` through the same package-owned asset controller as the admin bundle to preserve the required head ordering without depending on host static setup.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Shared admin components can now land on top of a stable responsive shell, consistent semantic tokens, and router-owned brand/theme/CSP assigns.
- Later page plans can reuse the `session["accrue_admin"]` contract instead of re-deriving asset paths, theme state, or brand metadata.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-02-SUMMARY.md`
- Found `accrue_admin/assets/css/app.css`
- Found `accrue_admin/lib/accrue_admin/components/app_shell.ex`
- Found `accrue_admin/test/accrue_admin/theme_test.exs`
- Found task commit `9c5b69d` in git history
