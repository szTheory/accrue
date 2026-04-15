---
phase: 07-admin-ui-accrue-admin
plan: 08
subsystem: ui
tags: [phoenix, liveview, dev-tools, assets, ci, docs]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Shared admin shell, component primitives, and billing pages from plans 07-01 through 07-07 and 07-09 through 07-12
provides:
  - Compile-gated dev-only LiveView tooling and floating toolbar for non-prod admin sessions
  - Package-local `mix accrue_admin.assets.build` workflow for rebuilding the committed private bundle
  - Admin package guide and CI drift check for asset freshness and mount-path docs
affects: []
tech-stack:
  added: []
  patterns: [compile-time dev-surface omission, Fake-only runtime guardrails, package-local asset rebuild task with fakeable runner]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/components/dev_toolbar.ex
    - accrue_admin/lib/accrue_admin/dev/clock_live.ex
    - accrue_admin/lib/accrue_admin/dev/email_preview_live.ex
    - accrue_admin/lib/accrue_admin/dev/webhook_fixture_live.ex
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
    - accrue_admin/lib/accrue_admin/dev/fake_inspect_live.ex
    - accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex
    - accrue_admin/guides/admin_ui.md
    - .github/workflows/accrue_admin_assets.yml
    - accrue_admin/test/accrue_admin/dev/dev_routes_test.exs
    - accrue_admin/test/accrue_admin/dev/email_preview_live_test.exs
    - accrue_admin/test/accrue_admin/dev/component_kitchen_live_test.exs
    - accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs
    - accrue_admin/config/prod.exs
  modified:
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
    - accrue_admin/lib/accrue_admin/page_live.ex
    - accrue_admin/test/accrue_admin/router_test.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
key-decisions:
  - "Dev tooling ships as compile-gated modules and routes, then applies a second runtime guard that only exposes controls when `Accrue.Processor.Fake` is configured."
  - "The floating toolbar is rendered from the shared app shell so every non-prod admin page can reach the dev surfaces without host-app wiring."
  - "Asset freshness stays package-local through a single `mix accrue_admin.assets.build` task plus CI drift checks, rather than requiring host Tailwind or JS setup."
patterns-established:
  - "Dev-surface pattern: define dev-only modules with `if Mix.env() != :prod`, mount them only in non-prod routers, and render an unavailable state instead of tooling when Fake is not active."
  - "Package asset maintenance pattern: test the mix task through an injectable runner, then use the same task in CI to rebuild committed `priv/static` artifacts."
requirements-completed: [ADMIN-24]
duration: 16m
completed: 2026-04-15
---

# Phase 7 Plan 08: Dev Admin Tooling and Asset Pipeline Summary

**Compile-gated admin dev tooling with Fake-only runtime access, plus a package-local asset rebuild task, guide, and CI freshness check**

## Performance

- **Duration:** 16m
- **Started:** 2026-04-15T19:00:00Z
- **Completed:** 2026-04-15T19:16:21Z
- **Tasks:** 2
- **Files modified:** 21

## Accomplishments

- Added five non-prod admin dev LiveViews for clock control, email fixture preview, webhook fixture inspection, component preview, and Fake-state inspection, all wired through a floating toolbar.
- Enforced the planned dev guardrails by omitting the routes and modules from prod builds and refusing to expose tooling unless `Accrue.Processor.Fake` is the active processor.
- Added a package-local asset rebuild task, focused smoke test, integration guide, CI freshness workflow, and refreshed committed `priv/static` bundle artifacts.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement compile-gated dev routes, toolbar, and inspection surfaces** - `ecc631f` (feat)
2. **Task 2: Add asset-build workflow, docs, and final package polish** - `4894633` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/dev/*.ex` and `components/dev_toolbar.ex` - non-prod dev LiveViews and the shared floating toolbar for Fake-only admin tooling.
- `accrue_admin/lib/accrue_admin/router.ex`, `components/app_shell.ex`, `page_live.ex`, and `test/accrue_admin/router_test.exs` - compile-time route gating, shell integration, and regression updates around the dev surface.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` and `test/mix/tasks/accrue_admin_assets_build_test.exs` - package-local asset rebuild task with a fakeable runner for a narrow smoke test.
- `accrue_admin/guides/admin_ui.md` and `.github/workflows/accrue_admin_assets.yml` - package-scoped host integration docs and CI drift enforcement for the committed bundle.
- `accrue_admin/assets/css/app.css`, `priv/static/accrue_admin.css`, and `priv/static/accrue_admin.js` - toolbar styling and rebuilt shipped assets.
- `accrue_admin/config/prod.exs` - minimal prod config needed to run the required `MIX_ENV=prod mix compile` verification in this package.

## Decisions Made

- Kept the dev pages as thin shells over existing `Accrue.Emails.Fixtures` and `Accrue.Processor.Fake` helpers instead of inventing new admin-side billing abstractions.
- Rendered an explicit unavailable state when Fake is not configured, which still blocks the tooling while avoiding a brittle mount-time redirect path in the package test endpoint.
- Put the asset maintenance contract in the package itself so maintainers rebuild the same committed bundle locally and in CI with one command.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing `accrue_admin/config/prod.exs`**
- **Found during:** Task 1 verification
- **Issue:** The required `MIX_ENV=prod mix compile` smoke check could not run because the package imported a nonexistent `config/prod.exs`.
- **Fix:** Added a minimal prod config file that sets `:accrue_admin` and `:accrue` env markers without introducing new runtime behavior.
- **Files modified:** `accrue_admin/config/prod.exs`
- **Verification:** `cd accrue_admin && MIX_ENV=prod mix compile`
- **Committed in:** `ecc631f`

---

**Total deviations:** 1 auto-fixed (1 Rule 3)
**Impact on plan:** The fix was required to execute the plan’s compile-time prod gate. No scope creep beyond the requested verification contract.

## Issues Encountered

- The package test endpoint turned mount-time redirects into 500 responses, so the runtime Fake guard was implemented as an explicit unavailable state instead of a redirect.
- `Accrue.Emails.Fixtures` includes keyword-list branding data, so the email preview page normalizes that fixture payload before sending it through the shared JSON viewer.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Maintainers now have one documented, package-local command for rebuilding the admin asset bundle and one CI workflow to catch drift.
- Non-prod billing sessions can inspect Fake state and fixture-backed surfaces without risking those tools compiling into prod builds.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-08-SUMMARY.md`
- Found task commit `ecc631f` in git history
- Found task commit `4894633` in git history
