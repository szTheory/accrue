---
phase: 13-canonical-demo-tutorial
plan: 01
subsystem: testing
tags: [elixir, phoenix, mix, docs-contract, playwright, ci]
requires:
  - phase: 10-host-app-dogfood-harness
    provides: host app billing, webhook, admin, and browser proof surfaces
  - phase: 11-ci-user-facing-integration-gate
    provides: repo-root host UAT wrapper and browser smoke coverage
  - phase: 12-first-user-dx-stabilization
    provides: installer/idempotence checks and host-first docs expectations
provides:
  - canonical demo command manifest for first-run and seeded-history modes
  - host-local `mix verify` and `mix verify.full` aliases
  - thin repo-root host UAT wrapper that delegates to `mix verify.full`
affects: [phase-13-docs-parity, examples/accrue_host, scripts/ci]
tech-stack:
  added: []
  patterns: [manifest-backed command contract, package-local fast/full verification aliases, thin repo-root delegation]
key-files:
  created:
    - examples/accrue_host/demo/command_manifest.exs
    - examples/accrue_host/test/demo/command_manifest_test.exs
    - examples/accrue_host/test/mix_alias_contract_test.exs
    - examples/accrue_host/test/repo_wrapper_contract_test.exs
  modified:
    - examples/accrue_host/mix.exs
    - scripts/ci/accrue_host_uat.sh
    - accrue/lib/accrue/config.ex
key-decisions:
  - "The canonical host contract lives in package-local Mix aliases, with the repo-root shell script reduced to environment passthrough plus delegation."
  - "The shared command manifest stores structured mode labels, command labels, and story artifacts instead of scraping prose from docs."
  - "Accrue's boot-time migration check now uses `Ecto.Migrator.with_repo/2` so dev boot validation works before the host supervisor starts its repo."
patterns-established:
  - "Keep tutorial-facing verification commands in `examples/accrue_host/mix.exs`, then have root wrappers call into them."
  - "Use small source-level contract tests to lock command labels and keep shell/docs parity work grep-verifiable."
requirements-completed: [DEMO-04, DEMO-05, DEMO-06]
duration: 26min
completed: 2026-04-17
---

# Phase 13 Plan 01: Canonical Demo Contract Summary

**Manifest-backed demo modes with host-local `mix verify` and `mix verify.full`, plus a repo-root wrapper that now delegates to the same full gate**

## Performance

- **Duration:** 26 min
- **Started:** 2026-04-17T01:22:00Z
- **Completed:** 2026-04-17T01:48:25Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Added a structured demo command manifest covering `First run`, `Seeded history`, command labels, and canonical story artifacts.
- Promoted the host app to a package-local `mix setup` / `mix verify` / `mix verify.full` contract, with the focused proof suite and full CI-equivalent gate living in `examples/accrue_host/mix.exs`.
- Collapsed the repo-root UAT wrapper into a thin delegate and repaired Accrue's migration lookup so bounded dev boot now passes inside the full gate.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the shared demo command manifest**
   - `f865e93` (`test`)
   - `7695b96` (`feat`)
2. **Task 2: Add the host-local `mix verify` and `mix verify.full` contract**
   - `ee2470a` (`test`)
   - `f8e824a` (`feat`)
3. **Task 3: Collapse the repo-root wrapper into a thin delegate**
   - `0b87097` (`test`)
   - `65a0205` (`fix`)

## Files Created/Modified

- `examples/accrue_host/demo/command_manifest.exs` - Canonical structured source for demo modes, command labels, and story artifacts.
- `examples/accrue_host/test/demo/command_manifest_test.exs` - Locks manifest labels, command order, and public-vs-seeded boundaries.
- `examples/accrue_host/test/mix_alias_contract_test.exs` - Locks the focused proof file list and full-gate composition in `mix.exs`.
- `examples/accrue_host/test/repo_wrapper_contract_test.exs` - Locks thin-wrapper delegation to `mix verify.full`.
- `examples/accrue_host/mix.exs` - Adds `verify.install`, `verify`, and `verify.full` plus the dev-boot and browser-smoke command builders.
- `scripts/ci/accrue_host_uat.sh` - Preserves repo-root env and Postgres conveniences while delegating to `cd "$host_dir" && mix verify.full`.
- `accrue/lib/accrue/config.ex` - Uses `Ecto.Migrator.with_repo/2` for migration inspection so boot-time validation works before the host repo supervisor is running.

## Decisions Made

- Kept the public contract small: `mix setup`, `mix verify`, `mix verify.full`, and the repo-root shell delegate.
- Stored demo command metadata as Elixir data in the host app so later docs tests can consume exact values without generating Markdown.
- Fixed the boot-time migration lookup in the library rather than weakening the dev-boot smoke, because the plan's point was to make `mix verify.full` truthful.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired Accrue's migration lookup for pre-repo boot validation**
- **Found during:** Task 3 (Collapse the repo-root wrapper into a thin delegate)
- **Issue:** `mix verify.full` still failed in bounded dev boot with `ACCRUE-DX-MIGRATIONS-PENDING` because `Accrue.Config.ensure_migrations_current!/0` inspected migrations through a repo that had not been started yet.
- **Fix:** Switched the migration inspection path to `Ecto.Migrator.with_repo/2`, which starts the repo long enough to query migration state during dependency startup.
- **Files modified:** `accrue/lib/accrue/config.ex`
- **Verification:** `cd examples/accrue_host && mix verify.full` passed, and `bash scripts/ci/accrue_host_uat.sh` passed through the delegated path.
- **Committed in:** `65a0205`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation was required to make the new canonical full gate truthful. No scope creep beyond the failing boot-path bug.

## Issues Encountered

- The first full-gate implementation passed the focused tests and regression suite but failed inside `mix cmd` because multiline shell helpers were encoded incorrectly. Reworking the helper builder to pass real scripts into `bash -lc` resolved the issue without changing the public alias surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 13 plan 02 can now consume a real command manifest and a truthful verification contract for docs parity checks.
- The host README and First Hour rewrite in plan 03 can teach `mix verify` and `mix verify.full` without inventing a second command graph.

## Self-Check: PASSED

- Verified `.planning/phases/13-canonical-demo-tutorial/13-01-SUMMARY.md` exists.
- Verified task commits `f865e93`, `7695b96`, `ee2470a`, `f8e824a`, `0b87097`, and `65a0205` exist in git history.
