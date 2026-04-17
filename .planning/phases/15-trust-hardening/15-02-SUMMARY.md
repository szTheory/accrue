---
phase: 15-trust-hardening
plan: 02
subsystem: testing
tags: [elixir, phoenix, playwright, accessibility, responsive, performance-smoke]
requires:
  - phase: 13-canonical-demo-tutorial
    provides: canonical host verify contract, seeded browser walkthrough, screenshot labels
  - phase: 15-trust-hardening
    provides: trust review and release-gate wording from 15-01
provides:
  - seeded webhook ingest smoke coverage inside the host verify alias
  - desktop and Pixel 5 trust coverage for the canonical host browser flow
  - deterministic standalone Playwright seeding for the trust grep lane
  - mobile admin shell overflow fix validated by the trust browser flow
affects: [phase-15-plan-03, host-verify, accrue_admin-ui]
tech-stack:
  added: [Playwright global setup for host trust seeding]
  patterns: [seeded smoke timing in focused host tests, per-project responsive trust assertions, idempotent browser fixture reseeding]
key-files:
  created:
    - examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs
    - examples/accrue_host/e2e/global-setup.js
  modified:
    - examples/accrue_host/mix.exs
    - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
    - examples/accrue_host/playwright.config.js
    - scripts/ci/accrue_host_seed_e2e.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
key-decisions:
  - "Keep trust smoke in the existing `mix verify` lane instead of adding a second host gate."
  - "Make the trust Playwright grep runnable on its own by reseeding deterministic fixture state before each project run."
  - "Fix the mobile admin overflow in `accrue_admin` rather than weakening the responsive trust assertion."
patterns-established:
  - "Focused host trust tests measure only the signed request path and fail with release-blocking messaging."
  - "Responsive browser trust checks use named desktop/mobile projects, critical+serious Axe gates, and page-level overflow assertions."
requirements-completed: [TRUST-02, TRUST-04]
duration: 12min
completed: 2026-04-17
---

# Phase 15 Plan 02: Trust Hardening Summary

**Seeded webhook latency smoke in `mix verify` plus desktop/mobile admin trust coverage with blocking Axe and responsiveness checks**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-17T09:34:50Z
- **Completed:** 2026-04-17T09:46:13Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added a focused ExUnit trust smoke that times only the signed webhook verify/persist/enqueue/200 request path against the `<100ms` host budget.
- Folded the new trust smoke into the locked `examples/accrue_host` verify contract without changing the public `mix verify` and `mix verify.full` entrypoints.
- Extended the canonical Playwright walkthrough to cover desktop and Pixel 5 trust states, critical/serious Axe checks, transition timing, compact success screenshots, and replay/admin reachability.
- Fixed deterministic browser seeding and a real mobile admin overflow bug surfaced by the new trust coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add seeded webhook trust smoke tests and wire them into the host verify contract** - `f175589` (`test`)
2. **Task 1: Add seeded webhook trust smoke tests and wire them into the host verify contract** - `285f27d` (`feat`)
3. **Task 2: Extend the host Playwright flow for desktop/mobile responsive, accessibility, and admin timing trust coverage** - `a5cb4e8` (`test`)
4. **Task 2: Extend the host Playwright flow for desktop/mobile responsive, accessibility, and admin timing trust coverage** - `60e4984` (`feat`)

## Files Created/Modified

- `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs` - signed webhook smoke budget proof with release-blocking failure messaging.
- `examples/accrue_host/mix.exs` - locked `mix verify` alias now includes the trust smoke file.
- `examples/accrue_host/e2e/global-setup.js` - deterministic Playwright setup for test DB migration and fixture generation.
- `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` - trust-tagged responsive browser proof with Axe gates, transition timing, and compact canonical screenshots.
- `examples/accrue_host/playwright.config.js` - two-project host browser config for desktop and Pixel 5 with failure-only heavy artifacts.
- `scripts/ci/accrue_host_seed_e2e.exs` - idempotent seeded browser fixture cleanup and rewrite-safe replay data.
- `accrue_admin/assets/css/app.css` - mobile shell/content wrapping fix for the admin dashboard.
- `accrue_admin/priv/static/accrue_admin.css` - rebuilt committed admin asset bundle containing the mobile layout fix.

## Decisions Made

- Reused the existing host verify lane and browser walkthrough so trust checks stay in the canonical proof path users already run locally and in CI.
- Reseeded the host browser fixture before each Playwright project because the desktop trust flow mutates the same seeded billing state the mobile project needs.
- Treated the Pixel 5 overflow as a product bug in `accrue_admin`, not as a test nuisance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added standalone Playwright trust seeding and fresh server startup**
- **Found during:** Task 2
- **Issue:** `npx playwright test ... --grep @phase15-trust` failed outside `mix verify.full` because the fixture path and seeded browser state only existed in the shell wrapper, and local Playwright reused stale Phoenix servers.
- **Fix:** Added `examples/accrue_host/e2e/global-setup.js`, disabled implicit local server reuse in the Playwright config, and made the seeded fixture script idempotent so the trust lane can prepare its own DB and fixture state.
- **Files modified:** `examples/accrue_host/e2e/global-setup.js`, `examples/accrue_host/playwright.config.js`, `scripts/ci/accrue_host_seed_e2e.exs`
- **Verification:** `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust`
- **Committed in:** `60e4984`

**2. [Rule 1 - Bug] Fixed mobile admin shell overflow surfaced by the new trust checks**
- **Found during:** Task 2
- **Issue:** The Pixel 5 trust run showed clipped admin dashboard content and overflow pressure in the mobile shell.
- **Fix:** Updated `accrue_admin` shell/content CSS to shrink correctly on mobile, wrap long copy, and rebuilt the committed package asset bundle.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --grep @phase15-trust`
- **Committed in:** `60e4984`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were necessary to make the planned trust lane deterministic and to satisfy the mobile responsive requirement with real evidence.

## Issues Encountered

- The plan’s `mix test ... -x` verification form does not match the current Mix CLI in this repo; verification used `--trace` instead for the focused ExUnit smoke runs.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Phase 15 now has the seeded webhook and browser trust evidence needed before extending the CI matrix in `15-03`.
- The host and admin trust surfaces are deterministic enough to wire into broader compatibility and release gates next.

## Self-Check

PASSED

---
*Phase: 15-trust-hardening*
*Completed: 2026-04-17*
