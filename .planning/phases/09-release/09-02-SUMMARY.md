---
phase: 09-release
plan: 02
subsystem: infra
tags: [github-actions, release-please, hex, elixir, release-automation]
requires:
  - phase: 09-release
    provides: CI release gate and package-aware workflow conventions
provides:
  - root-manifest Release Please automation for accrue and accrue_admin
  - same-workflow Hex publish gating from trusted release outputs
  - manual workflow_dispatch Hex recovery flow and same-day v1.0.0 runbook
affects: [release automation, hex publishing, release docs, package versioning]
tech-stack:
  added: []
  patterns: [root manifest release-please, same-workflow publish gating, manual recovery publish workflow]
key-files:
  created: [.github/workflows/release-please.yml, .github/workflows/publish-hex.yml, release-please-config.json, .release-please-manifest.json, RELEASING.md]
  modified: []
key-decisions:
  - "Keep automated Hex publishing inside the same release-please workflow so publish jobs trust only same-workflow outputs."
  - "Use publish-hex.yml only as a manual recovery/bootstrap path with explicit package, ref, and version inputs."
patterns-established:
  - "Release automation exports path-scoped Release Please outputs as stable job outputs before downstream publish jobs consume them."
  - "Admin package publish steps always set ACCRUE_ADMIN_HEX_RELEASE=1 in both automated and manual recovery flows."
requirements-completed: [OSS-07, OSS-08, OSS-09, OSS-10]
duration: 5m
completed: 2026-04-16
---

# Phase 09 Plan 02: Release Please and Hex Automation Summary

**Root-manifest Release Please automation with same-workflow Hex publishing, path-scoped package outputs, and a same-day `1.0.0` release runbook**

## Performance

- **Duration:** 5m
- **Started:** 2026-04-16T00:04:10Z
- **Completed:** 2026-04-16T00:09:09Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added a root-manifest Release Please workflow for `accrue` and `accrue_admin` with the required least-privilege permissions and a dedicated `RELEASE_PLEASE_TOKEN`.
- Wired automated Hex publishing into the same workflow graph so package publishes trust only `needs.release.outputs.*` values from the `release` job.
- Added a manual `workflow_dispatch` recovery workflow and documented the same-day `1.0.0` bootstrap, publish order, review checklist, and secret handling in `RELEASING.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create root-manifest Release Please automation with least-privilege permissions** - `f676305` (feat)
2. **Task 2: Create publish workflow and same-day release runbook with explicit package order** - `64dfbc2` (feat)

## Files Created/Modified
- `.github/workflows/release-please.yml` - Release Please workflow plus same-workflow publish jobs for `accrue` then `accrue_admin`.
- `.github/workflows/publish-hex.yml` - Manual `workflow_dispatch` recovery/bootstrap publish workflow using explicit package, tag, and version inputs.
- `release-please-config.json` - Root manifest configuration for both Elixir packages with package-local changelog paths.
- `.release-please-manifest.json` - Version manifest seeded from the current `0.1.0` state for both packages.
- `RELEASING.md` - Same-day `1.0.0` release runbook, checklist, and manual fallback instructions.

## Decisions Made
- Kept the automated publish path in `.github/workflows/release-please.yml` instead of splitting it across workflows, because the plan's threat model requires trusted same-workflow outputs at the release-to-publish boundary.
- Made `.github/workflows/publish-hex.yml` manual-only and explicit-ref-only so recovery publishes cannot accidentally depend on foreign workflow outputs or implicit branch state.
- Seeded the manifest at `0.1.0` while documenting first-public-release bootstrap through `Release-As: 1.0.0` instructions and a release PR checklist rather than hard-coding a one-time version override into the steady-state config.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Cleared a transient git index lock during Task 2 commit**
- **Found during:** Task 2
- **Issue:** `git commit` failed with a stale `.git/index.lock`, blocking the required atomic task commit.
- **Fix:** Confirmed no active git process was holding the lock, then retried the commit serially.
- **Files modified:** none
- **Verification:** Task 2 committed successfully as `64dfbc2`.
- **Committed in:** `64dfbc2` (task commit completed after the retry)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No product-scope change. The fix only restored normal git execution so the planned task commit could land cleanly.

## Issues Encountered

- One acceptance criterion conflicts with the implementation requirements: it asks for `needs.release.outputs...` from a `release` job while also expecting `rg -n "pull_request|release:" .github/workflows/release-please.yml` to return no matches. The required `release` job id necessarily introduces `release:` in YAML, so the workflow follows the explicit job-wiring requirement rather than the contradictory grep.

## User Setup Required

None - no external service configuration required beyond repository GitHub Actions secrets already named in the workflows and runbook.

## Next Phase Readiness

- Phase 09 now has the release automation skeleton needed for package-local changelog ownership, same-day publish ordering, and documented manual recovery.
- Later release/doc plans still need to finish the remaining public package surface, including package metadata and docs details that the workflows assume exist at release time.

## Self-Check: PASSED

- Found `.planning/phases/09-release/09-02-SUMMARY.md`
- Found commit `f676305`
- Found commit `64dfbc2`
