---
phase: 11-ci-user-facing-integration-gate
plan: 01
subsystem: testing
tags: [playwright, ci, phoenix, e2e, host-app]
requires:
  - phase: 10-host-app-dogfood-harness
    provides: Signed-in host billing flow, billing-admin replay flow, and seeded fixture contract
provides:
  - Host-local Playwright package manifest and lockfile under examples/accrue_host
  - Desktop-only Playwright config with retained failure traces, screenshots, and HTML report path
  - Blocking host browser spec covering user billing start/cancel and admin webhook replay
affects: [11-02, 11-03, ci, examples/accrue_host]
tech-stack:
  added: [@playwright/test]
  patterns: [host-local Playwright runner, fixture-backed browser auth flow, retained-failure browser artifacts]
key-files:
  created:
    - examples/accrue_host/package.json
    - examples/accrue_host/package-lock.json
    - examples/accrue_host/playwright.config.js
    - examples/accrue_host/e2e/phase11-host-gate.spec.js
  modified: []
key-decisions:
  - "The host browser gate boots the real Phoenix app via test-mode `mix phx.server` on `ACCRUE_HOST_BROWSER_PORT` instead of sharing the admin runner."
  - "The Playwright spec reads `ACCRUE_HOST_E2E_FIXTURE` at test runtime so `playwright test --list` remains usable before seeding."
patterns-established:
  - "Host-local browser gates own their own npm manifest and Playwright config instead of borrowing sibling package tooling."
  - "Browser specs should log request and page failures while asserting shipped copy and real authenticated routes."
requirements-completed: [CI-02, CI-04]
duration: 12m
completed: 2026-04-16
---

# Phase 11 Plan 01: CI User-Facing Integration Gate Summary

**Host-local Playwright browser gate with retained failure artifacts and a seeded user-plus-admin replay spec**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-16T18:43:19Z
- **Completed:** 2026-04-16T18:55:19Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a host-owned Playwright manifest and lockfile so `examples/accrue_host` can run browser checks without depending on `accrue_admin/node_modules`.
- Added a desktop-only Playwright config that retains traces, failure screenshots, and an HTML report path for CI artifact upload.
- Ported the existing raw browser smoke path into a blocking Playwright Test spec that exercises the real signed-in host billing and admin replay flow.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the host-local Playwright contract and dependency manifest** - `47d902f` (feat)
2. **Task 2: Port the browser smoke flow into a blocking Playwright spec** - `af0d519` (feat)

## Files Created/Modified

- `examples/accrue_host/package.json` - host-local Playwright scripts and dependency declaration
- `examples/accrue_host/package-lock.json` - locked Playwright dependency tree for deterministic `npm ci`
- `examples/accrue_host/playwright.config.js` - retained-artifact Playwright runner for the host app
- `examples/accrue_host/e2e/phase11-host-gate.spec.js` - release-blocking signed-in host and admin replay browser flow

## Decisions Made

- Used the host app’s own `MIX_ENV=test mix phx.server` as Playwright `webServer` wiring so the browser gate hits the real Phoenix stack already used by the host UAT path.
- Kept the host browser project to a single `chromium-desktop` target at `1280x900`, matching the approved UI contract without adding a blocking mobile surface.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Unblocked Task 1 verification by making the real spec discoverable during `--list`**
- **Found during:** Task 1 (Create the host-local Playwright contract and dependency manifest)
- **Issue:** The mandated `cd examples/accrue_host && npm ci && npx playwright test --list` verification exits non-zero when no spec exists yet, and top-level fixture loading would also fail discovery before seeding.
- **Fix:** Authored the real Phase 11 spec before Task 1 commit while staging only Task 1 files, and moved fixture loading behind a runtime helper so list-mode discovery stays valid.
- **Files modified:** `examples/accrue_host/e2e/phase11-host-gate.spec.js`
- **Verification:** `cd examples/accrue_host && npm ci && npx playwright test --list`; `cd examples/accrue_host && npm ci && npx playwright test e2e/phase11-host-gate.spec.js --list`
- **Committed in:** `af0d519`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Kept the planned verification commands intact and avoided adding a fake placeholder test.

## Issues Encountered

- Task 1’s verify command assumed a spec already existed. The implementation handled that by writing the real browser spec early and keeping commits atomic through selective staging.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `examples/accrue_host` now exposes the package-local browser command and artifact directories that Plan 11-02 can wire into the shell UAT gate.
- CI workflow wiring in Plan 11-03 can now upload `examples/accrue_host/playwright-report` and `examples/accrue_host/test-results` on failure.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/11-ci-user-facing-integration-gate/11-ci-user-facing-integration-gate-01-SUMMARY.md`
- Task commits `47d902f` and `af0d519` are present in git history
