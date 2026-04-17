---
phase: 10-host-app-dogfood-harness
plan: 03
subsystem: testing
tags: [phoenix, elixir, accrue, accrue_admin, host-app, exunit]
requires:
  - phase: 10-01
    provides: Phoenix host app scaffold and host-owned repo config at examples/accrue_host
  - phase: 10-02
    provides: Host-owned Phoenix auth/session boundary and generated ConnCase baseline
provides:
  - Host-owned Accrue integration test support for the example app
  - Executable Wave 0 installer boundary proof for public router and host facade output
  - Phase-tagged Wave 0 proof files for billing, subscription, webhook, and admin flows
affects: [phase-10, host-app, testing, installer, admin-ui, webhooks]
tech-stack:
  added: [exunit]
  patterns: [host-owned-accrue-test-harness, wave0-proof-file-contract]
key-files:
  created:
    - examples/accrue_host/test/support/accrue_case.ex
    - examples/accrue_host/test/install_boundary_test.exs
    - examples/accrue_host/test/accrue_host/billing_facade_test.exs
    - examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs
    - examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs
    - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
    - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
  modified:
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/test/support/data_case.ex
    - examples/accrue_host/test/support/conn_case.ex
key-decisions:
  - "Keep the install-boundary proof executable in Wave 0 by running `mix accrue.install` against a temporary Phoenix-shaped host fixture instead of waiting for the example app to be patched in Plan 10-04."
  - "Make the host app's DataCase, ConnCase, and AccrueCase all import the public `Accrue.Test` facade so later billing, webhook, and admin proofs stay host-owned while exercising public test helpers."
patterns-established:
  - "Host-owned test support owns Repo sandbox setup and layers Accrue helpers on top rather than importing private core-package fixtures."
  - "Wave 0 proof files are real ExUnit modules with exact future-proof module names, `@moduletag :phase10`, and an explicit handoff to the later executable-plan number."
requirements-completed: [HOST-01, HOST-08]
duration: 5min
completed: 2026-04-16
---

# Phase 10 Plan 03: Host App Dogfood Harness Summary

**Host-owned Accrue test support plus Wave 0 proof files for installer, billing, webhook, and admin validation**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T16:33:00Z
- **Completed:** 2026-04-16T16:37:31Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Added a reusable host-owned test harness that combines Repo sandbox setup with the public `Accrue.Test` facade.
- Created the executable install-boundary proof that asserts `mix accrue.install` generates the webhook route, `/billing` admin mount, local path deps, and host billing facade.
- Added all remaining Wave 0 proof files as compile-safe, phase-tagged scaffold modules so later plans can replace behavior without renaming validation targets.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add host-owned test support for Repo, Conn, and Accrue integration helpers** - `1565fce` (feat)
2. **Task 2: Create the Wave 0 verification files required by 10-VALIDATION.md** - `89da6db` (test)

## Files Created/Modified
- `examples/accrue_host/test/support/accrue_case.ex` - host-owned Accrue integration case with sandbox setup and public test helpers
- `examples/accrue_host/test/support/data_case.ex` - host data case now imports `Accrue.Test`
- `examples/accrue_host/test/support/conn_case.ex` - host conn case now imports `Accrue.Test`
- `examples/accrue_host/test/install_boundary_test.exs` - executable temp-app installer proof for webhook, admin mount, and billing facade output
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` - Wave 0 scaffold for Plan 10-04
- `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` - Wave 0 scaffold for Plan 10-05
- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` - Wave 0 scaffold for Plan 10-06
- `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` - Wave 0 scaffold for Plan 10-07 mount protection proof
- `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` - Wave 0 scaffold for Plan 10-07 replay/audit proof
- `examples/accrue_host/config/config.exs` - host app now declares the Accrue CLDR backend required to boot `ex_money`
- `examples/accrue_host/config/test.exs` - host test config now supplies required Accrue branding defaults

## Decisions Made
- Kept the installer proof independent from the evolving example app so Wave 0 can verify public install output immediately.
- Used the public `Accrue.Test` facade in host support modules instead of copying private fixture behavior into the example app.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added host CLDR backend config required for test boot**
- **Found during:** Task 1 (Add host-owned test support for Repo, Conn, and Accrue integration helpers)
- **Issue:** `mix test` could not start `ex_money` because the host app had no default CLDR backend configured.
- **Fix:** Added `:ex_cldr` and `:ex_money` backend config pointing at `Accrue.Cldr` in the host app config.
- **Files modified:** `examples/accrue_host/config/config.exs`
- **Verification:** `cd examples/accrue_host && mix test`
- **Committed in:** `1565fce` (part of task commit)

**2. [Rule 3 - Blocking] Added required branding defaults for Accrue test boot**
- **Found during:** Task 1 (Add host-owned test support for Repo, Conn, and Accrue integration helpers)
- **Issue:** `Accrue.Config.validate_at_boot!/0` rejected the host test environment because required branding emails were missing.
- **Fix:** Added minimal test branding config with `from_email` and `support_email`.
- **Files modified:** `examples/accrue_host/config/test.exs`
- **Verification:** `cd examples/accrue_host && mix test`
- **Committed in:** `1565fce` (part of task commit)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required for the host harness to boot under the plan's verification command. No scope expansion beyond executable test support.

## Issues Encountered
None

## Known Stubs

- `examples/accrue_host/test/accrue_host/billing_facade_test.exs:6` - intentional Wave 0 scaffold deferred to Plan 10-04
- `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs:6` - intentional Wave 0 scaffold deferred to Plan 10-05
- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:6` - intentional Wave 0 scaffold deferred to Plan 10-06
- `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs:6` - intentional Wave 0 scaffold deferred to Plan 10-07
- `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:6` - intentional Wave 0 scaffold deferred to Plan 10-07

## User Setup Required

None - no external service configuration required for this plan's test gate.

## Next Phase Readiness
- Plan 10-04 can now replace the billing facade scaffold and point the example app through the real installer output while keeping the install-boundary proof file stable.
- Plans 10-05 through 10-07 have named proof targets ready for subscription, webhook, and admin execution without changing the validation contract.

## Self-Check: PASSED
- Found `.planning/phases/10-host-app-dogfood-harness/10-03-SUMMARY.md`
- Found commit `1565fce` in git history
- Found commit `89da6db` in git history

---
*Phase: 10-host-app-dogfood-harness*
*Completed: 2026-04-16*
