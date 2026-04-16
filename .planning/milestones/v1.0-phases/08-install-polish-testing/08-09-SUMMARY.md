---
phase: 08-install-polish-testing
plan: 09
subsystem: testing
tags: [auth, mock-adapter, test-support, tdd, phase-08-gap-closure]

# Dependency graph
requires:
  - phase: 08-04
    provides: "Accrue.Test facade and Fake-first helper patterns"
  - phase: 08-05
    provides: "Mailer and PDF named test adapters"
  - phase: 08-07
    provides: "Auth adapter documentation and production fail-closed guidance"
provides:
  - "Named Accrue.Auth.Mock adapter implementing Accrue.Auth"
  - "Process-local auth test state for host app tests"
  - "Production refusal guard for the test-only auth adapter"
affects: [phase-08, testing, auth, installer-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Auth test adapters keep mutable test identity in the calling process dictionary"
    - "Test-only adapters explicitly refuse :prod via Accrue.ConfigError"

key-files:
  created:
    - accrue/lib/accrue/auth/mock.ex
    - accrue/test/accrue/auth/mock_test.exs
    - .planning/phases/08-install-polish-testing/08-09-SUMMARY.md
  modified: []

key-decisions:
  - "Accrue.Auth.Mock is a real named adapter but is not wired into Accrue.Auth.Default or installer fallback config."
  - "The adapter uses process-local state so host tests can set users without global leakage."
  - "All auth callback surfaces in Accrue.Auth.Mock refuse :prod with Accrue.ConfigError."

patterns-established:
  - "Named test adapters should be directly loadable and export their full behaviour surface for verifier checks."
  - "Production safety tests that mutate Application env run non-async and restore the original env."

requirements-completed: [TEST-07]

# Metrics
duration: 3min
completed: 2026-04-15
---

# Phase 08 Plan 09: Auth Mock Adapter Gap Closure Summary

**Accrue.Auth.Mock now gives host tests a named, process-local auth adapter while refusing production use.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-15T23:00:00Z
- **Completed:** 2026-04-15T23:03:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added focused TDD coverage for the missing `Accrue.Auth.Mock` adapter, including callback exports, process-local user behavior, admin plug pass-through, and production refusal.
- Implemented `Accrue.Auth.Mock` with the full `Accrue.Auth` callback surface plus `put_current_user/1` and `clear_current_user/0`.
- Preserved production auth boundaries by keeping the mock out of `Accrue.Auth.Default` and installer fallback config.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add failing tests for Accrue.Auth.Mock** - `1cb0489` (test)
2. **Task 2: Implement production-guarded Accrue.Auth.Mock** - `bd305c3` (feat)

**Auto-fix:** `3f5d81e` fixed an order-dependent export assertion discovered during final verification.

**Plan metadata:** final docs commit (this summary, STATE.md, ROADMAP.md, and REQUIREMENTS.md if changed)

## Files Created/Modified

- `accrue/test/accrue/auth/mock_test.exs` - Verifies named adapter loading, exported helper/callback surface, mock user behavior, admin plug pass-through, and production refusal.
- `accrue/lib/accrue/auth/mock.ex` - Defines process-local, test-only `Accrue.Auth.Mock`.
- `.planning/phases/08-install-polish-testing/08-09-SUMMARY.md` - Captures plan execution, verification, and decisions.

## Decisions Made

- `Accrue.Auth.Mock` remains opt-in for host tests instead of becoming a default auth path.
- Mock current-user state is stored in the calling process dictionary using `{Accrue.Auth.Mock, :current_user}`.
- Production refusal is enforced inside the mock adapter with `Accrue.ConfigError`, not by installer config.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed order-dependent export assertions**

- **Found during:** Final verification after Task 2
- **Issue:** `function_exported?/3` returned `false` when the export test ran before any test loaded `Accrue.Auth.Mock`.
- **Fix:** Added `Code.ensure_loaded!(Accrue.Auth.Mock)` before the export assertions.
- **Files modified:** `accrue/test/accrue/auth/mock_test.exs`
- **Verification:** `cd accrue && mix test test/accrue/auth/mock_test.exs test/accrue/auth_test.exs`
- **Committed in:** `3f5d81e`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The fix made the planned regression deterministic without changing the production code scope.

## Issues Encountered

- The RED run failed as expected because `Accrue.Auth.Mock` did not exist.
- Targeted test runs emitted the existing OpenTelemetry exporter warning about missing `opentelemetry_exporter`; it did not fail the test command.

## Verification

- RED: `cd accrue && mix test test/accrue/auth/mock_test.exs` failed before implementation because `Accrue.Auth.Mock` was missing.
- GREEN: `cd accrue && mix test test/accrue/auth/mock_test.exs test/accrue/auth_test.exs` passed with 20 tests, 0 failures.
- Acceptance greps passed for the required auth mock test assertions, production refusal text, full callback surface, process dictionary state, and absence of `Accrue.Auth.Mock` wiring in `Accrue.Auth.Default` or installer patches.

## TDD Gate Compliance

- RED gate commit present: `1cb0489`
- GREEN gate commit present after RED: `bd305c3`
- No refactor gate was needed.

## Known Stubs

None. The `nil` assertion in `mock_test.exs` verifies clearing process-local auth state; it is not a UI/data stub.

## Threat Flags

None. The new auth test adapter surface was already covered by the plan threat model and mitigated with process-local state plus production refusal.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The remaining Phase 8 TEST-07 verifier blocker is closed: `Accrue.Auth.Mock`, `Accrue.Mailer.Test`, and `Accrue.PDF.Test` all exist as named test adapters.

## Self-Check: PASSED

- Found created files: `accrue/lib/accrue/auth/mock.ex`, `accrue/test/accrue/auth/mock_test.exs`, `.planning/phases/08-install-polish-testing/08-09-SUMMARY.md`.
- Found task commits: `1cb0489`, `bd305c3`, `3f5d81e`.
- Stub scan found no blocking stubs in files created or modified by this plan.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
