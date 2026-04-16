---
phase: 11-ci-user-facing-integration-gate
plan: 02
subsystem: testing
tags: [ci, playwright, github-actions, bash, phoenix, host-app]
requires:
  - phase: 11-01
    provides: Host-local Playwright package, config, and blocking browser spec for the example host app
provides:
  - Canonical host UAT shell gate that runs install, drift, compile, tests, bounded boot, and Playwright browser flow
  - Explicit annotation sweep script for release-gate and host-integration warning or failure blockers
affects: [11-03, ci, scripts/ci, examples/accrue_host]
tech-stack:
  added: []
  patterns: [host-local Playwright shell orchestration, release-facing annotation sweep via GitHub Actions API]
key-files:
  created:
    - scripts/ci/annotation_sweep.sh
  modified:
    - scripts/ci/accrue_host_uat.sh
key-decisions:
  - "The host UAT shell script now seeds the fixture, boots Phoenix itself, and runs the host-local Playwright package instead of the older custom Node smoke runner."
  - "Annotation blocking matches release-facing jobs by normalized job-name selectors and reads the current workflow run through gh api first, then curl as a fail-closed fallback."
patterns-established:
  - "Local and CI host reproduction should install and run browser tooling from examples/accrue_host rather than reusing accrue_admin node_modules."
  - "Release-facing annotation gates should require explicit GITHUB_REPOSITORY, GITHUB_RUN_ID, and token inputs so local runs fail closed instead of silently passing."
requirements-completed: [CI-02, CI-06]
duration: 5m
completed: 2026-04-16
---

# Phase 11 Plan 02: CI User-Facing Integration Gate Summary

**Playwright-backed host release-gate shell flow plus a fail-closed GitHub annotation sweep for release-facing jobs**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T18:56:00Z
- **Completed:** 2026-04-16T19:00:54Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Promoted `scripts/ci/accrue_host_uat.sh` into the canonical host release-gate command while preserving installer rerun, drift blocking, warning-clean compile/tests, asset build, and bounded Phoenix boot.
- Replaced the old custom browser runner handoff with the host-local Playwright package, fixture seeding, Chromium install, and retained server-log output on browser failure.
- Added `scripts/ci/annotation_sweep.sh` so CI can explicitly fail on surviving warning, failure, or error annotations for named release-facing jobs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Promote the host UAT shell script to the canonical Playwright-backed release-gate command** - `451f9e6` (feat)
2. **Task 2: Add an explicit workflow-annotation blocker for release-facing jobs** - `2da7f32` (feat)

## Files Created/Modified

- `scripts/ci/accrue_host_uat.sh` - Runs the host install, drift, compile, tests, bounded boot, fixture seeding, Phoenix browser server, and host-local Playwright gate in one shell entrypoint.
- `scripts/ci/annotation_sweep.sh` - Queries the current workflow run through `gh api` or `curl`, matches named release-facing jobs, and fails on surviving warning/failure/error annotations.

## Decisions Made

- Kept the Phoenix browser server under the shell script instead of Playwright's `webServer` ownership for this path so the script can preserve and print a concrete `browser_log_file` on failures.
- Used normalized job-name selector matching for `release-gate`, `host-integration`, and similar names so matrix-expanded GitHub job display names still match the intended sweep target.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 11-03 can wire `bash scripts/ci/accrue_host_uat.sh` into the main CI workflow as the host integration gate.
- Plan 11-03 can call `scripts/ci/annotation_sweep.sh` with release-facing job selectors after the ordered workflow jobs complete.
- The host gate now emits a stable browser server log path on failure, which is ready for GitHub Actions artifact upload.

## Verification

- `bash -n scripts/ci/accrue_host_uat.sh`
- `bash -n scripts/ci/annotation_sweep.sh`
- `bash scripts/ci/accrue_host_uat.sh`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/11-ci-user-facing-integration-gate/11-02-SUMMARY.md`
- Task commits `451f9e6` and `2da7f32` are present in git history
