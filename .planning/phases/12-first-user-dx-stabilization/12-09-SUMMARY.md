---
phase: 12-first-user-dx-stabilization
plan: 09
subsystem: testing
tags: [installer, diagnostics, phoenix-router, ecto-migrations, dx]
requires:
  - phase: 12-05
    provides: shared setup diagnostics and installer --check taxonomy
provides:
  - scope-aware webhook preflight tied to the mounted webhook route
  - migration lookup failures mapped to ACCRUE-DX-MIGRATIONS-PENDING
  - installer preflight auth-adapter checks that honor runtime config
affects: [phase-12, installer, boot-validation, examples-accrue_host]
tech-stack:
  added: []
  patterns: [tdd, scope-bounded router inspection, explicit migration lookup error mapping]
key-files:
  created: []
  modified:
    - accrue/lib/mix/tasks/accrue.install.ex
    - accrue/lib/accrue/config.ex
    - accrue/test/mix/tasks/accrue_install_test.exs
    - accrue/test/mix/tasks/accrue_install_uat_test.exs
    - accrue/test/accrue/config_test.exs
key-decisions:
  - "Webhook preflight now derives misuse from the webhook route context instead of router-wide string matches."
  - "Migration inspection only translates expected lookup failures into ACCRUE-DX-MIGRATIONS-PENDING; arbitrary exceptions still bubble."
  - "Installer auth-adapter preflight accepts host adapters declared in config/runtime.exs, matching the example host app."
patterns-established:
  - "Installer preflight checks should read the specific mounted route or config surface they are validating, not unrelated global text."
  - "Boot diagnostics may redact and normalize expected infrastructure failures, but they should not swallow unexpected exceptions."
requirements-completed: [DX-02]
duration: 5m
completed: 2026-04-16
---

# Phase 12 Plan 09: Trustworthy setup diagnostics for webhook scopes and migration lookup failures

**Webhook preflight now inspects the mounted webhook scope, and migration inspection failures raise the shared setup diagnostic instead of silently returning `:ok`.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T22:41:15Z
- **Completed:** 2026-04-16T22:46:03Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added RED coverage for valid host-style routers so unrelated browser/auth pipelines no longer trip `ACCRUE-DX-WEBHOOK-PIPELINE`.
- Reworked installer preflight to inspect the webhook route context and to honor runtime auth-adapter config during `--check`.
- Added migration diagnostics coverage and changed boot validation to raise `Accrue.ConfigError` with `ACCRUE-DX-MIGRATIONS-PENDING` on expected lookup failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make webhook pipeline preflight inspect the webhook scope, not unrelated router pipelines**
   - `ba530f8` `test(12-09): add failing webhook scope regression coverage`
   - `e01207f` `fix(12-09): scope webhook preflight to the mounted route`
2. **Task 2: Turn migration lookup failures into explicit setup diagnostics and fail loud on unexpected exceptions**
   - `8c032ba` `test(12-09): add failing migration lookup diagnostics coverage`
   - `31c673f` `fix(12-09): surface migration inspection failures as setup diagnostics`

**Additional verification fix:** `0b3692c` `fix(12-09): let preflight honor runtime auth adapter config`

## Files Created/Modified

- `accrue/lib/mix/tasks/accrue.install.ex` - Scoped webhook misuse detection to the actual webhook route context and accepted runtime auth-adapter config during preflight.
- `accrue/lib/accrue/config.ex` - Added explicit migration lookup failure mapping and preserved fail-loud behavior for unexpected exceptions.
- `accrue/test/mix/tasks/accrue_install_test.exs` - Added valid-router and runtime-auth regression coverage for installer `--check`.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - Added host-style router UAT coverage for the isolated webhook scope pass case.
- `accrue/test/accrue/config_test.exs` - Added regression tests for migration lookup failures and unexpected exception bubbling.

## Decisions Made

- Used bounded webhook route context inspection instead of router-wide string matching so browser/auth text elsewhere in the router cannot poison the webhook check.
- Added a function-based migration fetch path in `ensure_migrations_current!/1` to test and enforce the expected-vs-unexpected exception split directly.
- Skipped boot-time migration inspection in `MIX_ENV=test` so library tests still start cleanly while explicit config tests cover the migration diagnostic contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installer preflight ignored host auth adapters set in runtime config**
- **Found during:** Plan verification (`cd examples/accrue_host && mix accrue.install --check`)
- **Issue:** `--check` only looked at `config/config.exs`, so the example host app failed `ACCRUE-DX-AUTH-ADAPTER` even though `config/runtime.exs` sets `AccrueHost.Auth`.
- **Fix:** Updated preflight auth-adapter detection to inspect both config sources and added installer regression coverage.
- **Files modified:** `accrue/lib/mix/tasks/accrue.install.ex`, `accrue/test/mix/tasks/accrue_install_test.exs`
- **Verification:** `cd accrue && mix test test/mix/tasks/accrue_install_test.exs --only install_check`; `cd examples/accrue_host && mix accrue.install --check`
- **Committed in:** `0b3692c`

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking)
**Impact on plan:** Required to satisfy the plan's real host verification command. The change stayed inside the existing installer preflight surface.

## Issues Encountered

- Tightening migration inspection exposed a test-environment startup dependency on the old rescue-all path. The resolution was to keep the strict migration check out of `MIX_ENV=test` boot while preserving explicit migration diagnostic tests.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Phase 12 gap closure now leaves only `12-10` for the docs/config-key drift fix.
- Installer preflight and boot diagnostics now match the host app more closely, which should reduce false-green and false-red first-user failures.

## Self-Check: PASSED

- Summary file exists: `.planning/phases/12-first-user-dx-stabilization/12-09-SUMMARY.md`
- Commits verified: `ba530f8`, `e01207f`, `8c032ba`, `31c673f`, `0b3692c`
