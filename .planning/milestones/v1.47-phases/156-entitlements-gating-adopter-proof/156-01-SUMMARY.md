---
phase: 156-entitlements-gating-adopter-proof
plan: 01
subsystem: entitlements
tags: [entitlements, liveview, phoenix, ecto, adopter-proof]

requires:
  - phase: 153-close-v1-46-audit-trail-verification-md-for-phase-151-roadma
    provides: v1.46 closure baseline before v1.47 adopter-proof work
provides:
  - Shared entitlement guard normalization for unloaded Ecto billable associations
  - Route-level adopter proof for fail-closed entitlement gating
  - Example host resolver and router ordering guidance
affects: [entitlements, examples-accrue-host, admin-recovery-analytics, e2e-overflow-checks]

tech-stack:
  added: []
  patterns:
    - Fail-closed billable normalization in Accrue.Entitlements.Guard
    - Auth-before-entitlements LiveView live_session ordering contract
    - Bounded currency atom mapping for admin recovery KPIs

key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/guard.ex
    - examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - accrue/guides/entitlements.md
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - examples/accrue_host/e2e/support/overflow.js
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css

key-decisions:
  - "Normalize `%Ecto.Association.NotLoaded{}` in the shared guard seam rather than the LiveView surface adapter."
  - "Keep unloaded billables on the generic fail-closed deny path; no new organization-selection UX was added."
  - "Use a concise router contract and keep the fuller adopter explanation in `accrue/guides/entitlements.md`."

patterns-established:
  - "Unloaded billable sentinel: host resolver and shared guard both collapse unloaded organization billables to denyable nil."
  - "Route-level entitlement proof: `/app/reports/advanced` remains the merge-blocking adopter test surface."

requirements-completed: [PRF-01]

duration: 8min
completed: 2026-05-31
---

# Phase 156 Plan 01: Entitlements Gating Adopter Proof Summary

**Fail-closed LiveView entitlement gating for unloaded organization billables, proven through the checked-in example host route.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-31T15:14:55Z
- **Completed:** 2026-05-31T15:23:09Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- `Accrue.Entitlements.Guard` now normalizes `%Ecto.Association.NotLoaded{}` to `nil` before entitlement predicates run.
- `examples/accrue_host` has a route-level regression proving `/app/reports/advanced` denies safely with the existing generic flash when the billable resolver returns an unloaded association.
- The example host resolver, router comment, and entitlement guide now make auth-before-entitlements ordering and fail-closed unloaded-billable behavior explicit.

## Task Commits

Each task was committed atomically:

1. **Task 1: Harden guard and prove route fail-closed behavior** - `0deb0c9d` (test), `47ab4bb3` (fix), `0514c174` (test format)
2. **Task 2: Make example host pattern explicit** - `e78eeb7c` (docs/config)

**Verification unblockers:** `76beb474` (recovery analytics bounded currency mapping), `4517fc9b` (subpixel viewport tolerance), `05e201c6` (mobile admin display bounds), `46e62b0c` (dark admin contrast)

**Code review fixes:** `c6273bdf` resolved one blocker and two warnings from `156-REVIEW.md`; `f472db62` recorded the clean review report.

## Files Created/Modified

- `accrue/lib/accrue/entitlements/guard.ex` - normalizes unloaded Ecto billables before guard predicates.
- `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` - adds the route-level `NotLoaded` regression while preserving existing allow/deny proofs.
- `examples/accrue_host/config/config.exs` - makes loaded, nil, and unloaded organization billable branches explicit.
- `examples/accrue_host/lib/accrue_host_web/router.ex` - documents the live_session ordering contract next to the gated route.
- `accrue/guides/entitlements.md` - documents unloaded billables denying instead of raising in the LiveView gating recipe.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` - bounds recovery KPI currency atom conversion for suite stability.
- `examples/accrue_host/e2e/support/overflow.js` - adds half-pixel tolerance for viewport bounds assertions.
- `accrue_admin/assets/css/app.css` - constrains mobile admin display copy and pins dark-mode topbar/action contrast for axe.
- `accrue_admin/priv/static/accrue_admin.css` - rebuilt packaged admin stylesheet.

## Decisions Made

- Kept `Accrue.Live.Entitlements` unchanged so the LiveView module remains only a transport adapter.
- Matched `Ecto.Association.NotLoaded` in `examples/accrue_host/config/config.exs` via `__struct__` to avoid expanding Ecto structs during config compilation.
- Fixed unrelated verification blockers as explicit deviations because they prevented the required full host verification gate from passing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Recovery analytics JPY currency atom conversion**
- **Found during:** Plan verification (`mix test --seed 0`)
- **Issue:** `AccrueAdmin.Live.Analytics.RecoveryLive` called `String.to_existing_atom("jpy")`, failing the existing recovery analytics test when the lowercase atom had not been loaded.
- **Fix:** Added a bounded known-currency atom list and converter instead of creating atoms dynamically.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
- **Verification:** `mix test test/accrue_host_web/live/recovery_analytics_test.exs --seed 0`; `mix test --seed 0`; `mix verify.full`
- **Committed in:** `76beb474`

**2. [Rule 3 - Blocking] Subpixel Playwright viewport assertion**
- **Found during:** Plan verification (`mix verify.full`)
- **Issue:** The canonical desktop e2e spec failed on a `-0.21875px` heading bound, a browser fractional layout value rather than meaningful clipping.
- **Fix:** Added a `0.5px` tolerance to the shared viewport visibility helper.
- **Files modified:** `examples/accrue_host/e2e/support/overflow.js`
- **Verification:** `npm run e2e -- e2e/phase13-canonical-demo.spec.js --project=chromium-desktop`; `mix verify.full`
- **Committed in:** `4517fc9b`

**3. [Rule 3 - Blocking] Mobile admin display overflow**
- **Found during:** Plan verification (`mix verify.full`) after strengthening right/bottom viewport checks.
- **Issue:** The canonical mobile demo exposed an admin dashboard heading that exceeded viewport bounds.
- **Fix:** Constrained admin page/header/display widths and reduced mobile display/KPI font size while preserving desktop sizing.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** `npm run e2e -- e2e/phase13-canonical-demo.spec.js --project=chromium-mobile`; `mix verify.full`
- **Committed in:** `05e201c6`

**4. [Rule 3 - Blocking] Dark admin contrast regression**
- **Found during:** Plan verification (`mix verify.full`) in the desktop admin axe suite.
- **Issue:** Theme toggle, topbar brand chip, and ghost action buttons inherited insufficient contrast in dark mode under host theme tokens.
- **Fix:** Added narrow dark/system@dark color overrides for the reported controls and rebuilt the packaged admin stylesheet.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** `npm run e2e -- e2e/verify01-admin-a11y.spec.js --project=chromium-desktop`; `mix verify.full`
- **Committed in:** `46e62b0c`

---

**Total deviations:** 4 auto-fixed blocking verification issues.
**Impact on plan:** Phase 156 scope was preserved; these fixes were required only to make the mandated verification gate trustworthy and green.

## Issues Encountered

- The new entitlement regression passed before the explicit guard normalization landed, showing the existing predicate path already denied safely. The shared normalization was still added to close PRF-01 at the intended seam and prevent future predicate-path coupling.

## Verification

- `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs --seed 0` - 3 tests, 0 failures
- `cd examples/accrue_host && mix test --seed 0` - 187 tests, 0 failures
- `cd examples/accrue_host && npm run e2e -- e2e/verify01-admin-a11y.spec.js --project=chromium-desktop` - 11 tests, 0 failures
- `cd examples/accrue_host && npm run e2e -- e2e/phase13-canonical-demo.spec.js --project=chromium-mobile` - 1 test, 0 failures
- `cd examples/accrue_host && mix verify.full` - bounded tests, full tests, boot smoke, and Playwright checks passed; browser phase reported 29 passed, 16 skipped
- Source assertions for `Ecto.Association.NotLoaded`, router ordering contract, and route redirect proof passed with `rg`

## Self-Check: PASSED

- All plan tasks completed.
- All task acceptance criteria satisfied.
- No `accrue/test/accrue/entitlements/guard_test.exs` changes were made.
- Required verification commands passed after documented deviation fixes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 156 passed phase-level verification and completion. PRF-01 is closed by shared guard behavior, example-host proof, and copyable adopter documentation.

---
*Phase: 156-entitlements-gating-adopter-proof*
*Completed: 2026-05-31*
