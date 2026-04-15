---
phase: 07-admin-ui-accrue-admin
plan: 01
subsystem: ui
tags: [phoenix, liveview, router, assets, testing]
requires:
  - phase: 06-email-pdf
    provides: Accrue branding/config conventions and LiveView-compatible rendering patterns
provides:
  - Mountable `accrue_admin` router macro with isolated scope and live session
  - Hash-addressed package-owned CSS and JS asset routes
  - Shared admin conn/live test harness and smoke coverage
affects: [07-02, 07-03, 07-04, 07-05, 07-06, 07-07, 07-08, 07-09, 07-10, 07-11, 07-12]
tech-stack:
  added: []
  patterns: [mountable Phoenix router macro, package-owned hashed asset serving, dependency-safe dev/test-only Credo checks]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/assets.ex
    - accrue_admin/lib/accrue_admin/layouts.ex
    - accrue_admin/test/support/live_case.ex
  modified:
    - accrue_admin/mix.exs
    - accrue_admin/config/test.exs
    - accrue/mix.exs
    - accrue_admin/test/accrue_admin/router_test.exs
key-decisions:
  - "Mounted admin assets are served from library-owned hash-suffixed Phoenix routes instead of host Plug.Static."
  - "The initial admin surface ships as a minimal placeholder LiveView so later page plans inherit a real live_session boundary and root layout."
  - "Accrue's custom Credo check now compiles only in dev/test so sibling packages can depend on `:accrue` without pulling lint-only code into runtime builds."
patterns-established:
  - "Router macro pattern: define a dedicated admin browser pipeline, emit asset routes, and wrap the package entrypoint in its own live_session."
  - "Asset ownership pattern: compile-time file digests plus immutable cache headers for committed package bundles."
requirements-completed: [ADMIN-25, ADMIN-26]
duration: 8m
completed: 2026-04-15
---

# Phase 7 Plan 01: Admin Package Foundation Summary

**Mountable admin package scaffold with package-owned hashed assets, a real live_session boundary, and reusable smoke-test harnesses**

## Performance

- **Duration:** 8m
- **Started:** 2026-04-15T16:43:00Z
- **Completed:** 2026-04-15T16:51:06Z
- **Tasks:** 2
- **Files modified:** 21

## Accomplishments

- Added `AccrueAdmin.Router.accrue_admin/2`, `AccrueAdmin.Assets`, committed CSS/JS bundles, and a minimal placeholder LiveView/root layout so the package mounts cleanly without host layout or static-file edits.
- Added shared `ConnCase` and `LiveCase` support plus router/asset smoke tests that prove explicit session-key forwarding, asset route hashing, and compile-time omission of dev-only routes.
- Unblocked `accrue_admin` verification by upgrading its locked `lattice_stripe` version and moving Accrue's custom Credo check to dev/test compile paths.

## Task Commits

1. **Task 1: Build the mountable package foundation per D7-01 and D7-02** - `62d995d` (feat)
2. **Task 2: Add the shared admin test harness and smoke coverage** - `ddb4e94` (test)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/router.ex` - mount macro, admin pipeline, live session wiring, and explicit session filtering.
- `accrue_admin/lib/accrue_admin/assets.ex` - hash-addressed asset serving from committed `priv/static` bundles.
- `accrue_admin/lib/accrue_admin/layouts.ex` and `page_live.ex` - minimal package-owned layout and landing LiveView for the initial mounted surface.
- `accrue_admin/test/support/conn_case.ex` and `live_case.ex` - reusable test harness with a package-owned test router/endpoint.
- `accrue_admin/test/accrue_admin/router_test.exs` and `assets_test.exs` - smoke coverage for route shape, session filtering, dev-route gating, and asset serving.
- `accrue/mix.exs` and `accrue/credo_checks/accrue/credo/no_raw_status_access.ex` - dev/test-only compile path for the custom Credo check so `:accrue` behaves as a dependency.

## Decisions Made

- Served admin bundles through explicit Phoenix routes rather than host static config so hosts only need `import AccrueAdmin.Router` and `accrue_admin "/billing"`.
- Kept the first admin page intentionally minimal; later plans can replace the placeholder without changing the mount contract.
- Treated the sibling-package dependency/compiler issues as Rule 3 blockers because they prevented plan verification even though the admin implementation itself was correct.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Upgraded `accrue_admin` lockfile to match `:accrue`'s `lattice_stripe ~> 1.1` requirement**
- **Found during:** Task 1 verification
- **Issue:** `accrue_admin/mix.lock` still pinned `lattice_stripe` to `0.2.0`, so `mix test` stopped before compiling the new admin package.
- **Fix:** Ran `mix deps.get` in `accrue_admin` and committed the updated lockfile with the package foundation.
- **Files modified:** `accrue_admin/mix.lock`
- **Verification:** `mix test test/accrue_admin/router_test.exs test/accrue_admin/assets_test.exs`
- **Committed in:** `62d995d`

**2. [Rule 3 - Blocking] Moved Accrue's custom Credo check onto dev/test compile paths**
- **Found during:** Task 2 verification
- **Issue:** The sibling `:accrue` dependency compiled `lib/accrue/credo/no_raw_status_access.ex` when loaded from `accrue_admin`, but `Credo.Check` is unavailable in dependency runtime builds.
- **Fix:** Added `credo_checks/` to `accrue` dev/test `elixirc_paths`, moved the custom check there, and left runtime builds on `lib/` only.
- **Files modified:** `accrue/mix.exs`, `accrue/credo_checks/accrue/credo/no_raw_status_access.ex`
- **Verification:** `mix test test/accrue_admin/router_test.exs test/accrue_admin/assets_test.exs --warnings-as-errors`
- **Committed in:** `ddb4e94`

---

**Total deviations:** 2 auto-fixed (2 Rule 3)
**Impact on plan:** Both fixes were required to make the planned admin scaffold verifiable. No scope creep beyond dependency-safe compilation and test execution.

## Issues Encountered

- `:accrue_admin` needed the same `ex_cldr` / `ex_money` and Swoosh bootstrap config as the sibling package because the test harness starts enough of the dependency tree to surface those application prerequisites.
- The admin pipeline's `:fetch_session` plug required test requests to initialize a session explicitly; the smoke tests now do that so later LiveView tests inherit the correct mount path.

## Known Stubs

- `accrue_admin/lib/accrue_admin/page_live.ex:24` renders a placeholder `Accrue Admin` heading only. This is intentional Wave 0 scaffolding so later Phase 7 plans can land real pages on top of an already-mounted live session.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 07-02 can build theming, CSP, and the full app shell on top of a package-owned root layout and asset contract.
- Later page plans can reuse `AccrueAdmin.LiveCase` and the mounted test router instead of re-deriving endpoint/session wiring.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-01-SUMMARY.md`
- Found task commits `62d995d` and `ddb4e94` in git history
