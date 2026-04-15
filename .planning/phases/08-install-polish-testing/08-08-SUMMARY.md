---
phase: 08-install-polish-testing
plan: 08
subsystem: testing
tags: [installer, test-support, mailer, tdd, phase-08-gap-closure]

# Dependency graph
requires:
  - phase: 08-03
    provides: "Installer host wiring and generated test-support snippet"
  - phase: 08-05
    provides: "Mailer assertion helpers and Accrue.Mailer.Test side-effect capture"
provides:
  - "Generated test support configures Accrue.Mailer.Test through the behavior-layer :mailer key"
  - "Installer regression coverage rejects the stale :mailer_adapter key in test/support/accrue_case.ex"
affects: [phase-08, installer, testing, mailer]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generated host test config must target behavior dispatch keys, not lower-level adapter keys"
    - "Gap closures keep verifier blockers pinned with explicit positive and negative installer assertions"

key-files:
  created:
    - .planning/phases/08-install-polish-testing/08-08-SUMMARY.md
  modified:
    - accrue/lib/accrue/install/patches.ex
    - accrue/test/mix/tasks/accrue_install_test.exs

key-decisions:
  - "Installer test support now configures Accrue.Mailer.Test under :mailer because Accrue.Mailer.impl/0 reads Application.get_env(:accrue, :mailer, Accrue.Mailer.Default)."
  - "The unrelated :mailer_adapter configuration surface remains untouched; this gap only covered Accrue.Mailer behavior dispatch."

patterns-established:
  - "Mailer test support regression asserts both the required :mailer key and absence of the rejected :mailer_adapter snippet."

requirements-completed: [TEST-04, TEST-07]

# Metrics
duration: 3min
completed: 2026-04-15
---

# Phase 08 Plan 08: Installer Mailer Test-Support Gap Closure Summary

**Fresh installer test support now routes Accrue.Mailer.deliver/2 through Accrue.Mailer.Test without touching real SMTP.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-15T22:56:32Z
- **Completed:** 2026-04-15T22:59:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a failing installer regression that reads generated `test/support/accrue_case.ex` and asserts the behavior-layer mailer key.
- Updated `Accrue.Install.Patches.test_support_snippet/0` to emit `config :accrue, :mailer, Accrue.Mailer.Test`.
- Preserved the existing generated `Accrue.Processor.Fake`, `Accrue.PDF.Test`, `use Accrue.Test`, router, admin, auth, and Oban assertions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add installer regression for behavior-layer mailer config** - `110a312` (test)
2. **Task 2: Correct generated test-support mailer key** - `918cdf5` (fix)

**Plan metadata:** final docs commit (this summary, STATE.md, and ROADMAP.md)

## Files Created/Modified

- `accrue/test/mix/tasks/accrue_install_test.exs` - Adds positive and negative assertions for generated test-support mailer config.
- `accrue/lib/accrue/install/patches.ex` - Changes the generated mailer test adapter config from `:mailer_adapter` to `:mailer`.
- `.planning/phases/08-install-polish-testing/08-08-SUMMARY.md` - Captures plan execution, verification, and decisions.

## Decisions Made

- Generated test support now uses the same `:mailer` key that `Accrue.Mailer.impl/0` reads.
- The lower-level `:mailer_adapter` key was not globally changed because this plan only targeted the generated `Accrue.Mailer.Test` behavior adapter snippet.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED run failed on the new assertion as expected before implementation.
- Targeted test runs emitted an existing OpenTelemetry exporter warning about missing `opentelemetry_exporter`; it did not fail the test command.

## Verification

- RED: `cd accrue && mix test test/mix/tasks/accrue_install_test.exs --only install_patches` failed on the new `config :accrue, :mailer, Accrue.Mailer.Test` assertion before Task 2.
- GREEN: `cd accrue && mix test test/mix/tasks/accrue_install_test.exs --only install_patches` passed with 2 tests, 0 failures.
- Acceptance greps passed for the required `:mailer` key, rejected `:mailer_adapter` snippet, and unchanged processor/PDF/Accrue.Test lines.

## TDD Gate Compliance

- RED gate commit present: `110a312`
- GREEN gate commit present after RED: `918cdf5`
- No refactor gate was needed.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 08-09 remains the next gap closure item for `Accrue.Auth.Mock`. This plan closes the verifier blocker for fresh-install mailer test-support wiring.

## Self-Check: PASSED

- Found modified files: `accrue/test/mix/tasks/accrue_install_test.exs`, `accrue/lib/accrue/install/patches.ex`, `.planning/phases/08-install-polish-testing/08-08-SUMMARY.md`.
- Found task commits: `110a312`, `918cdf5`.
- Stub scan found no blocking stubs in files created or modified by this plan.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
