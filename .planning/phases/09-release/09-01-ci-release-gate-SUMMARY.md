---
phase: 09-release
plan: 01
subsystem: infra
tags: [github-actions, ci, elixir, otp, dialyzer, exdoc, hex]
requires:
  - phase: 08-install-polish-testing
    provides: conditional compilation coverage for Sigra and OpenTelemetry
provides:
  - unified release-gate workflow for accrue and accrue_admin
  - Elixir/OTP matrix coverage with explicit Sigra and OpenTelemetry cells
  - split PLT caching for core and admin package Dialyzer runs
affects: [release automation, docs verification, admin package release readiness]
tech-stack:
  added: []
  patterns: [single workflow release gate, split restore-save PLT caching, package-explicit CI steps]
key-files:
  created: [.planning/phases/09-release/09-01-SUMMARY.md]
  modified: [.github/workflows/ci.yml]
key-decisions:
  - "Keep one shared GitHub Actions release gate and run both packages explicitly in that workflow."
  - "Model conditional compilation as concrete matrix cells for Sigra and OpenTelemetry instead of hiding it in ad hoc scripts."
patterns-established:
  - "Release CI names each package step explicitly so failures point at accrue vs accrue_admin immediately."
  - "Dialyzer PLTs use split restore/save caches keyed by Elixir, OTP, and conditional compilation toggles."
requirements-completed: [OSS-02, OSS-03, OSS-04, OSS-05, OSS-06]
duration: 10m
completed: 2026-04-16
---

# Phase 09 Plan 01: CI Release Gate Summary

**GitHub Actions release gate covering both packages with explicit Elixir/OTP, Sigra, and OpenTelemetry matrix cells plus package-specific Dialyzer/docs/audit checks**

## Performance

- **Duration:** 10m
- **Started:** 2026-04-15T23:55:00Z
- **Completed:** 2026-04-16T00:04:42Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Expanded the main CI job into a Phase 9 release gate with the required Elixir/OTP floor, primary, forward-compat, Sigra, and OpenTelemetry cells.
- Exported release-gate environment toggles for Sigra and OpenTelemetry so the matrix carries conditional compilation intent directly in workflow state.
- Enforced the full required command set for both `accrue` and `accrue_admin`, including split PLT restore/save caching for each package.

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand the matrix axes and package coverage in ci.yml** - `b3231b9` (feat)
2. **Task 2: Add exact release-gate steps for both packages and split PLT caching** - `42b33ff` (feat)

## Files Created/Modified
- `.github/workflows/ci.yml` - Turns the main CI workflow into the Phase 9 release gate for both packages.
- `.planning/phases/09-release/09-01-SUMMARY.md` - Records execution results, decisions, and verification for this plan.

## Decisions Made
- Kept the advisory `live-stripe` job unchanged and isolated from the main release gate so CI hardening does not broaden publish or live-test scope.
- Added an explicit OpenTelemetry matrix cell and exported both `ACCRUE_CI_OPENTELEMETRY` and `ACCRUE_OTEL_MATRIX` so the workflow aligns with the repo's existing optional-compile test contract.
- Mirrored the split PLT cache pattern for `accrue_admin` in the workflow now, so the admin package's release gate shape is already in place when its Dialyxir support lands.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan requires two separate task commits while both tasks modify the same workflow file. The workflow was intentionally reapplied in two passes so each task could land as its own commit without bundling unrelated hunks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 09 release automation can now rely on a single workflow file that already expresses the expected release gate surface for both packages.
- Later Phase 09 plans still need to supply the admin package pieces that make every gated command pass in CI, especially Dialyxir and docs support in `accrue_admin`.

## Self-Check: PASSED

- Found `.planning/phases/09-release/09-01-SUMMARY.md`
- Found commit `b3231b9`
- Found commit `42b33ff`
