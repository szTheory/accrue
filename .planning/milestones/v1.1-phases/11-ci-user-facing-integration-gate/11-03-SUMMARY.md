---
phase: 11-ci-user-facing-integration-gate
plan: 03
subsystem: infra
tags: [github-actions, ci, playwright, phoenix, roadmap]
requires:
  - phase: 11-01
    provides: Host-local Playwright package, retained browser artifacts, and the blocking host browser spec
  - phase: 11-02
    provides: Canonical host UAT shell gate and release-facing annotation sweep script
provides:
  - Ordered CI workflow with release-gate, admin drift/docs, host integration, and annotation sweep jobs
  - Failure-only host browser artifact uploads from the canonical CI workflow
  - Manual-only legacy host/admin auxiliary workflows and aligned Phase 11 roadmap plan list
affects: [ci, github-actions, roadmap, examples/accrue_host, scripts/ci]
tech-stack:
  added: []
  patterns: [ordered GitHub Actions release gate, failure-only artifact uploads, manual-only legacy workflow demotion]
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/accrue_host_uat.yml
    - .github/workflows/accrue_admin_assets.yml
    - scripts/ci/accrue_host_uat.sh
    - .planning/ROADMAP.md
key-decisions:
  - "The canonical PR and main release gate now lives in ci.yml, with legacy host and admin asset workflows demoted to workflow_dispatch-only to avoid duplicate required checks."
  - "Host browser artifacts upload only on failure, and the shell gate now accepts ACCRUE_HOST_BROWSER_LOG so GitHub Actions can reliably collect the Phoenix server log."
patterns-established:
  - "Release-facing CI ordering is expressed through explicit needs chains inside one workflow rather than through multiple competing required workflows."
  - "When a shell-driven browser gate must upload logs after failure, the workflow provides a stable log path and the script preserves it."
requirements-completed: [CI-01, CI-03, CI-04, CI-05, CI-06]
duration: 5m
completed: 2026-04-16
---

# Phase 11 Plan 03: CI User-Facing Integration Gate Summary

**Canonical CI workflow ordering with admin drift/docs blocking, fake-backed host integration artifacts, and advisory-only live Stripe**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-16T19:00:00Z
- **Completed:** 2026-04-16T19:04:41Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Folded the mandatory admin drift/docs check and host integration gate into `.github/workflows/ci.yml` behind the existing `release-gate`.
- Added failure-only uploads for the host Playwright report, traces, and Phoenix server log while keeping live Stripe manual or scheduled advisory-only.
- Demoted the old host and admin asset workflows to manual-only behavior and aligned the Phase 11 roadmap block to the finalized three-plan set.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewire the main CI workflow into an ordered package-to-host release gate** - `0906850` (feat)
2. **Task 2: Verify roadmap alignment and only edit if the Phase 11 plan list drifts** - `c9a2f6e` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` - Owns the ordered `release-gate -> admin-drift-docs -> host-integration -> annotation-sweep` chain and failure artifact uploads.
- `.github/workflows/accrue_host_uat.yml` - Demoted to `workflow_dispatch` only so it no longer competes with the canonical gate.
- `.github/workflows/accrue_admin_assets.yml` - Demoted to `workflow_dispatch` only after moving the blocking logic into `ci.yml`.
- `scripts/ci/accrue_host_uat.sh` - Accepts a stable browser log path from CI so the failure artifact upload can capture the Phoenix server log.
- `.planning/ROADMAP.md` - Updated the Phase 11 plan count line to the approved three-plan set.

## Decisions Made

- Restricted the workflow token to read-only scopes for Actions, checks, and repository contents, which is enough for checkout, annotation reads, and artifact uploads while avoiding broader token permissions.
- Kept the post-job annotation sweep as a final blocker after the ordered jobs so release-facing warning and error annotations still fail the canonical workflow.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Preserved a stable host browser log for artifact upload**
- **Found during:** Task 1 (Rewire the main CI workflow into an ordered package-to-host release gate)
- **Issue:** `scripts/ci/accrue_host_uat.sh` wrote the browser server log to a temp file and deleted it on success, which left the workflow without a reliable path to upload `accrue-host-server-log` after a host gate failure.
- **Fix:** Added `ACCRUE_HOST_BROWSER_LOG` support in the shell gate and set it from `ci.yml` to `${{ github.workspace }}/accrue-host-server.log`.
- **Files modified:** `.github/workflows/ci.yml`, `scripts/ci/accrue_host_uat.sh`
- **Verification:** `rg -n 'accrue-host-server-log|ACCRUE_HOST_BROWSER_LOG' .github/workflows/ci.yml scripts/ci/accrue_host_uat.sh`
- **Committed in:** `0906850`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The auto-fix was required for CI-04 to work as specified. No scope creep.

## Issues Encountered

- The repo-local `ruby` shim had no version selected, so the YAML parse verification used the installed asdf Ruby binary directly at `/Users/jon/.asdf/installs/ruby/3.3.4/bin/ruby`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 11 now has its canonical release-facing workflow shape in source control and is ready for repository-side required-check validation.
- The final metadata commit can update `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` to mark the plan complete.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/11-ci-user-facing-integration-gate/11-03-SUMMARY.md`
- Task commits `0906850` and `c9a2f6e` are present in git history
