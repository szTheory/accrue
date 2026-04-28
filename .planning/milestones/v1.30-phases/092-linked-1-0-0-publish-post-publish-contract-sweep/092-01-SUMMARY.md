---
phase: 092-linked-1-0-0-publish-post-publish-contract-sweep
plan: 01
subsystem: release
tags: [release-please, hex, changelog, docs, github-actions]
requires:
  - phase: 091-pre-publish-prep
    provides: stable changelog preambles, post-1.0 release cadence prose, 1.0.0-ready public docs framing
provides:
  - linked 1.0.0 release-source alignment across both Mix projects and the manifest
  - package-doc install literals pinned to 1.0.0 on the public package surfaces
  - corrected Release Please changelog-path config so future release PRs write package-root changelogs only
affects: [092-02, 092-03, release-please, package-doc verifiers]
tech-stack:
  added: []
  patterns: [linked release PR proof before publish, package-relative release-please changelog paths]
key-files:
  created:
    - .planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-01-SUMMARY.md
  modified:
    - release-please-config.json
    - accrue/mix.exs
    - accrue_admin/mix.exs
    - .release-please-manifest.json
    - accrue/README.md
    - accrue_admin/README.md
    - accrue/guides/first_hour.md
key-decisions:
  - "Used merged Release Please PR #15 as the canonical REL-05 proof because it landed on origin/main during execution."
  - "Fixed release-please changelog-path entries to package-relative CHANGELOG.md after the merged 1.0.0 PR generated nested duplicate changelog files."
patterns-established:
  - "For manifest-mode monorepo packages, release-please changelog-path must be relative to the package directory, not the repo root."
  - "Phase 92 release proof can rely on the merged combined release PR and workflow runs when the upstream release slice lands during execution."
requirements-completed: [REL-05, PPX-09, PPX-12]
duration: 15 min
completed: 2026-04-28
---

# Phase 92 Plan 01 Summary

**Linked `1.0.0` release sources and package-doc pins are aligned, with Release Please corrected to keep future numbered changelogs at each package root only**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-28T13:33:00Z
- **Completed:** 2026-04-28T13:48:50Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Confirmed merged Release Please PR [#15](https://github.com/szTheory/accrue/pull/15) carried the linked `1.0.0` release slice for `accrue` and `accrue_admin`, including the `Release-As: 1.0.0` bootstrap trailer.
- Verified `accrue/mix.exs`, `accrue_admin/mix.exs`, `.release-please-manifest.json`, `accrue/README.md`, `accrue_admin/README.md`, and `accrue/guides/first_hour.md` all reflect `1.0.0`.
- Fixed a release-surface regression from PR `#15` by correcting `release-please-config.json` and removing duplicate nested changelog files.

## Task Commits

1. **Task 1: Lock `1.0.0` across both mix projects and the Release Please manifest** - `1f9675f` (upstream merged release slice in PR `#15`)
2. **Task 2: Prove the combined Release Please PR is forced to `1.0.0` before merge** - PR `#15`, workflow runs `25051925091` and `25055758784`
3. **Task 3: Move package-doc install literals and release-facing prose to `1.0.0`** - `1f9675f` (upstream merged release slice in PR `#15`)

**Deviation fix:** `ee8792f` (`fix(092-01): keep package changelogs at package root`)

## Files Created/Modified

- `release-please-config.json` - corrected package-relative changelog paths for Release Please manifest mode
- `accrue/mix.exs` - `@version "1.0.0"` confirmed in the merged release slice
- `accrue_admin/mix.exs` - `@version "1.0.0"` confirmed with `ACCRUE_ADMIN_HEX_RELEASE` gate preserved
- `.release-please-manifest.json` - both package versions locked to `1.0.0`
- `accrue/README.md` - core install literal pinned to `~> 1.0.0`
- `accrue_admin/README.md` - admin install literal and sibling-package prose pinned to `1.0.0`
- `accrue/guides/first_hour.md` - first-hour install pins aligned to the `1.0.0` pair
- `accrue/accrue/CHANGELOG.md` and `accrue_admin/accrue_admin/CHANGELOG.md` - deleted duplicate generated files

## Decisions Made

- Used the already-merged combined release PR rather than dispatching a second Release Please run, because `origin/main` advanced during execution and already contained the required `1.0.0` slice and proof.
- Treated the nested changelog files as a Rule 1 release-surface bug because they directly contradicted `RELEASING.md` and would recur on future release PRs without a config fix.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed package changelog path drift in Release Please**
- **Found during:** Task 2 (Prove the combined Release Please PR is forced to `1.0.0` before merge)
- **Issue:** Merged release PR `#15` generated `accrue/accrue/CHANGELOG.md` and `accrue_admin/accrue_admin/CHANGELOG.md` because `changelog-path` was configured as repo-relative instead of package-relative.
- **Fix:** Changed both `changelog-path` entries to `CHANGELOG.md` and removed the duplicate nested changelog files.
- **Files modified:** `release-please-config.json`, `accrue/accrue/CHANGELOG.md`, `accrue_admin/accrue_admin/CHANGELOG.md`
- **Verification:** `bash scripts/ci/verify_release_manifest_alignment.sh`; `bash scripts/ci/verify_package_docs.sh`; file absence checks for both nested changelog paths
- **Committed in:** `ee8792f`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix stayed inside the release surface and removed future release-note drift. No phase-scope expansion.

## Issues Encountered

- `origin/main` advanced during execution with the merged `1.0.0` release PR and release workflow, so the local bootstrap commit was rebased away as already-upstream work.
- A direct push to `main` initially failed because the remote had moved; rebasing with `--autostash` preserved the pre-existing local `.planning/STATE.md` and `.planning/ROADMAP.md` edits.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 can use `main` at `ee8792f` as the canonical continuation point; the `1.0.0` version sources and package-doc pins are already live.
- GitHub Actions run [`25056718227`](https://github.com/szTheory/accrue/actions/runs/25056718227) completed successfully for the follow-up changelog-path fix, so Plan 02 starts from a green remote SHA.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED
