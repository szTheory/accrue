---
phase: 08-install-polish-testing
plan: 01
subsystem: testing
tags: [exunit, installer, mix-task, fake-processor, opentelemetry, docs]

requires:
  - phase: 08-install-polish-testing
    provides: "08-CONTEXT, 08-VALIDATION, and 08-PATTERNS for Wave 0 contracts"
provides:
  - "Wave 0 red tests for installer, generator, public test helpers, OTel, Billing span coverage, and docs"
  - "Fresh Phoenix-style install fixture helpers"
  - "Task-addressable tags for downstream Phase 08 plans"
affects: [08-install-polish-testing, installer, testing, telemetry, docs]

tech-stack:
  added: []
  patterns:
    - "Contract tests intentionally fail on missing downstream implementation"
    - "Runtime-compiled probes verify macro/use surfaces without breaking test file compilation"

key-files:
  created:
    - accrue/test/support/install_fixture.ex
    - accrue/test/mix/tasks/accrue_install_test.exs
    - accrue/test/mix/tasks/accrue_gen_handler_test.exs
    - accrue/test/accrue/install/sigra_detection_test.exs
    - accrue/test/accrue/test/clock_test.exs
    - accrue/test/accrue/test/webhooks_test.exs
    - accrue/test/accrue/test/event_assertions_test.exs
    - accrue/test/accrue/test/facade_test.exs
    - accrue/test/accrue/telemetry/otel_test.exs
    - accrue/test/accrue/telemetry/billing_span_coverage_test.exs
    - accrue/test/accrue/docs/testing_guide_test.exs
    - accrue/test/accrue/docs/community_auth_test.exs
  modified: []

key-decisions:
  - "Wave 0 tests call future Mix task modules directly inside fixture directories to avoid unresolved fixture dependency failures before implementation exists."
  - "Facade and event assertion contracts use runtime compilation probes so missing macro modules are test failures rather than file-level compile blockers."
  - "OTel compile-matrix contract is executable in ExUnit using exact shell command strings from the validation plan."

patterns-established:
  - "Install fixture helper creates isolated Phoenix-shaped temp apps and never touches the real repo."
  - "Task-addressable ExUnit tags map downstream implementations to narrow verification slices."

requirements-completed: [INST-01, INST-02, INST-03, INST-04, INST-05, INST-06, INST-07, INST-08, INST-09, INST-10, AUTH-04, AUTH-05, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-10, OBS-02]

duration: 10min
completed: 2026-04-15T21:33:08Z
---

# Phase 08 Plan 01: Wave 0 Contract Test Summary

**Executable red test surface for installer DX, public test helpers, optional OpenTelemetry spans, Billing span coverage, and Phase 08 guides**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-15T21:23:06Z
- **Completed:** 2026-04-15T21:33:08Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added installer and generator contract tests with required tags, Stripe test-mode readiness/redaction assertions, no-clobber fingerprints, Sigra/admin wiring checks, and `Accrue.Test.InstallFixture`.
- Added public test-helper contracts for `Accrue.Test`, `Accrue.Test.Clock`, `Accrue.Test.Webhooks`, and `Accrue.Test.EventAssertions`.
- Added OTel privacy/compile-matrix tests, Billing public-function span coverage audit, and testing/auth guide content contracts.

## Task Commits

1. **Task 1: Create installer and generator contract tests** - `8c03701` (test)
2. **Task 2: Create public test helper contract tests** - `5581179` (test)
3. **Task 3: Create OTel and testing guide contract tests** - `6297374` (test)

## Files Created/Modified

- `accrue/test/support/install_fixture.ex` - Phoenix-shaped temporary fixture helpers for installer smoke tests.
- `accrue/test/mix/tasks/accrue_install_test.exs` - Installer option/template/patch/Stripe-readiness/orchestration contracts.
- `accrue/test/mix/tasks/accrue_gen_handler_test.exs` - Handler generator behavior and no-clobber contracts.
- `accrue/test/accrue/install/sigra_detection_test.exs` - Sigra and fallback auth installer contracts.
- `accrue/test/accrue/test/clock_test.exs` - `advance_clock/2` duration parsing and no-sleep contracts.
- `accrue/test/accrue/test/webhooks_test.exs` - `trigger_event/2` normal webhook ingest/handler path contracts.
- `accrue/test/accrue/test/event_assertions_test.exs` - Event assertion matcher contracts.
- `accrue/test/accrue/test/facade_test.exs` - `use Accrue.Test` facade import/delegation contracts.
- `accrue/test/accrue/telemetry/otel_test.exs` - OTel span naming, attribute allowlist, prohibited-key drop, and compile-matrix contracts.
- `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` - Billing public API span coverage audit.
- `accrue/test/accrue/docs/testing_guide_test.exs` - Testing guide content/order contracts.
- `accrue/test/accrue/docs/community_auth_test.exs` - Community auth adapter guide contracts.

## Verification

- `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_gen_handler_test.exs test/accrue/install/sigra_detection_test.exs` ran: 13 tests, 13 expected failures on missing `Mix.Tasks.Accrue.Install` and `Mix.Tasks.Accrue.Gen.Handler`.
- `cd accrue && mix test test/accrue/test/clock_test.exs test/accrue/test/webhooks_test.exs test/accrue/test/event_assertions_test.exs test/accrue/test/facade_test.exs` ran: 13 tests, 13 expected failures on missing `Accrue.Test*` modules and helper files.
- `cd accrue && mix test test/accrue/telemetry/otel_test.exs test/accrue/telemetry/billing_span_coverage_test.exs test/accrue/docs/testing_guide_test.exs test/accrue/docs/community_auth_test.exs` ran: 10 tests, 9 expected failures; OTel compile-matrix command test passed.
- Full Wave 0 command across all new files ran: 36 tests, 35 expected failures.
- All plan grep acceptance checks passed.

## Decisions Made

- Future Mix task contracts invoke `Mix.Tasks.Accrue.Install.run/1` and `Mix.Tasks.Accrue.Gen.Handler.run/1` directly while `File.cd!/2` is inside fixture apps. This preserves fixture filesystem semantics without requiring unresolved fixture deps to load.
- Macro-facing contracts use `Code.compile_string/1` or `Code.eval_string/1` probes so missing modules fail at test runtime while the test files still compile.
- Billing span coverage uses a test-owned audited exception map and expects no unaudited public Billing functions at steady state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed env restoration helper compile error**
- **Found during:** Task 1
- **Issue:** `with_env/2` used an `after` clause that could not access the `previous` binding.
- **Fix:** Wrapped the callback in `try/after` so env vars restore correctly.
- **Files modified:** `accrue/test/mix/tasks/accrue_install_test.exs`
- **Verification:** Task 1 targeted tests compiled and reached missing-task failures.
- **Committed in:** `8c03701`

**2. [Rule 3 - Blocking] Avoided fixture dependency load failure before missing installer behavior**
- **Found during:** Task 1
- **Issue:** Running `Mix.Task.run/2` from an unfetched fixture app failed on dependency loadpaths before reaching the installer/generator contract.
- **Fix:** Called the future task modules directly inside `File.cd!/2` fixture contexts.
- **Files modified:** `accrue/test/mix/tasks/accrue_install_test.exs`, `accrue/test/mix/tasks/accrue_gen_handler_test.exs`, `accrue/test/accrue/install/sigra_detection_test.exs`
- **Verification:** Task 1 targeted tests now fail on missing task modules.
- **Committed in:** `8c03701`

**3. [Rule 1 - Bug] Replaced nonexistent `String.index/2` in guide order test**
- **Found during:** Task 3
- **Issue:** `String.index/2` is not available in this Elixir version and would create a false failure after guide files exist.
- **Fix:** Added a small `:binary.match/2` helper.
- **Files modified:** `accrue/test/accrue/docs/testing_guide_test.exs`
- **Verification:** Task 3 targeted tests reran and only failed on intended missing docs/OTel/span behavior.
- **Committed in:** `6297374`

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking issue)
**Impact on plan:** All fixes preserved the Wave 0 scope and made failures point at downstream implementation gaps.

## Known Stubs

None. The new files are tests and fixture helpers; no production or UI stubs were introduced.

## Threat Flags

None. The plan added test-only files and isolated temporary filesystem fixtures; no new production trust boundary was introduced.

## User Setup Required

None.

## Next Phase Readiness

Plans 08-02 through 08-07 can now use narrow tags and file-level commands to implement installer, helper, OTel, and docs behavior against explicit red contracts.

## Self-Check: PASSED

- Verified all created test and fixture files exist.
- Verified task commits `8c03701`, `5581179`, and `6297374` exist in git history.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
