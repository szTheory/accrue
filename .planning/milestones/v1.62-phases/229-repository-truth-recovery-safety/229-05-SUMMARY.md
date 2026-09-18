---
phase: 229-repository-truth-recovery-safety
plan: 05
subsystem: repository-safety
tags: [bash, git-bundle, recovery, atomic-publication, security]
requires:
  - phase: 229-01
    provides: Phase 229 recovery boundary and inventory conventions
provides:
  - Physically validated, externally published recovery capsules
  - Shell-free argv restoration metadata and hostile-ref restoration fixture
affects: [phase-229-verification, repository-synchronization]
tech-stack:
  added: [Git bundle verification, exclusive hard-link publication]
  patterns: [physical-path validation, owned-temp cleanup, argv-only process invocation]
key-files:
  created: []
  modified:
    - scripts/ci/preserve_repository_state.sh
decisions:
  - Use hard-link publication for an exclusive atomic final path instead of overwrite-prone rename.
  - Retain preservation refs on post-recovery failure while removing only invocation-owned scratch and unpublished outputs.
metrics:
  duration: 20m
  completed: 2026-09-13
  tasks: 2
  files: 1
status: complete
plan_head_before: 47cfff585d6339b36e823a5462b36ce25c70356e
commits: 4
actuals:
  tokens: 5363
  tasks: 2
  commits: 4
coverage:
  - id: D1
    description: Atomic capsule preservation rejects aliasing and restores hostile refs without shell evaluation.
    requirement: REPO-01
    verification:
      - kind: integration
        ref: bash scripts/ci/preserve_repository_state.sh --self-test
        status: pass
    human_judgment: false
  - id: D2
    description: Artifact path and temporary-state edge cases clean up safely.
    requirement: REPO-02
    verification:
      - kind: integration
        ref: bash -n scripts/ci/preserve_repository_state.sh && bash scripts/ci/preserve_repository_state.sh --self-test
        status: pass
    human_judgment: false
---

# Phase 229 Plan 05: Atomic Recovery Capsule Safety Summary

**A physically isolated, exclusively published Git recovery capsule with safe argv restoration for hostile refs.**

## Accomplishments

- Validates physical output identities before preservation-ref mutation, rejecting equal, aliased, symlink-parent, existing-inode, nested, repository, and worktree targets.
- Publishes the bundle, private mode-0600 manifest, and optional public record with exclusive atomic links, then re-verifies the final bundle and frozen head set.
- Stores restoration as structured `restore_argv` arrays and proves restoration of `refs/stash` and a valid metacharacter-bearing ref without invoking a shell.
- Accepts `release..notes`, rejects only dot or dot-dot path components, and proves scratch/unpublished-output cleanup on success, empty-input failure, and injected post-manifest failure.

## Verification

- `bash -n scripts/ci/preserve_repository_state.sh && bash scripts/ci/preserve_repository_state.sh --self-test` — passed.
- The self-test validates all three outputs, final bundle verification, public/private digest agreement, mode 0600, hostile-ref restoration, collision/alias/symlink rejection, single-ref success, empty-ref failure, and temporary-state cleanup.
- SHA-256 values for every file in `/Users/dev/projects/accrue-phase229-recovery.9vAj86/` matched the pre-task snapshot.

## Files Created/Modified

- `scripts/ci/preserve_repository_state.sh` — hardened recovery capsule implementation and end-to-end fixtures.

## Decisions Made

- Hard links provide exclusive atomic publication: creating the final name fails if another writer has claimed it, avoiding an overwrite race.
- Preservation refs are intentionally retained after a failure that occurs after ref freezing; only invocation-owned temporary and unpublished outputs are removed.

## TDD Gate Compliance

- RED: `c6761f69` added the hostile public-record/restore fixture and failed on the unbound bundle digest.
- GREEN: `31bd0691` implemented physical path validation, exclusive publication, and argv restoration.
- RED: `367a0309` added a post-manifest cleanup probe that failed because the invocation succeeded.
- GREEN: `dba4d2be` added owned-temporary tracking and failure cleanup.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Replacing the script initially cleared its executable mode; the executable bit was restored before verification.
- The initial cleanup path removed successfully published outputs. The implementation now marks successful publication before the EXIT trap and preserves final artifacts.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Later repository observation and synchronization work can rely on a tested, non-shell recovery barrier without modifying the existing private Phase 229 capsule.

## Self-Check: PASSED

- `scripts/ci/preserve_repository_state.sh` exists.
- Task commits `c6761f69`, `31bd0691`, `367a0309`, and `dba4d2be` exist in git history.
