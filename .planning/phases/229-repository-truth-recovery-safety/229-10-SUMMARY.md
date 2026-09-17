---
phase: 229-repository-truth-recovery-safety
plan: 10
subsystem: repository-safety
tags: [bash, git-bundle, recovery, symlink, sha256, filesystem]
requires:
  - phase: 229-05
    provides: Exclusive recovery-capsule publication and cleanup ownership
provides:
  - Immediate pre-PASS reconciliation of the complete canonical artifact map
  - Raw-Buffer SHA-256 evidence for non-dereferenced symlink link text
affects: [phase-229-verification, repository-synchronization, recovery-capsule-integrity]
actuals:
  tokens: 3527
  tasks: 2
  commits: 4
plan_head_before: 724cdadddf3f648ec88fd1e4383822078dd1aae9
commits: 4
tech-stack:
  added: []
  patterns: [NUL-safe canonical snapshots, raw-Buffer symlink hashing, self-test-only mutation hooks]
key-files:
  created: []
  modified:
    - scripts/ci/preserve_repository_state.sh
key-decisions:
  - "Compare two complete sorted NUL-delimited path/type/digest streams after final bundle validation and before releasing output ownership."
  - "Hash symlink link text only from fs.readlinkSync(path, { encoding: 'buffer' }) without decoding, normalizing, trimming, or dereferencing."
patterns-established:
  - "Final-boundary reconciliation: published outputs remain cleanup-owned until independent state snapshots compare byte-for-byte."
  - "Raw metadata evidence: filesystem bytes are hashed directly from a Buffer and unsupported access fails closed."
requirements-completed: [REPO-02]
coverage:
  - id: D1
    description: Post-snapshot artifact add, removal, rename, type, or digest drift cannot reach preservation PASS.
    requirement: REPO-02
    verification:
      - kind: integration
        ref: bash -n scripts/ci/preserve_repository_state.sh && bash scripts/ci/preserve_repository_state.sh --self-test
        status: pass
    human_judgment: false
  - id: D2
    description: Symlink evidence hashes exact raw link-text bytes, including invalid UTF-8 and newline edges, without dereferencing targets.
    requirement: REPO-02
    verification:
      - kind: integration
        ref: bash scripts/ci/preserve_repository_state.sh --self-test
        status: pass
    human_judgment: false
duration: 10 min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 10: Final Artifact and Raw Symlink Integrity Summary

**Recovery publication now rechecks the complete artifact map at the final boundary and hashes symlink link text byte-for-byte from non-dereferenced Buffers.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-13T18:42:05Z
- **Completed:** 2026-09-13T18:52:06Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Refactored artifact enumeration into one sorted, NUL-safe snapshot routine used for both manifest evidence and immediate pre-PASS reconciliation.
- Kept newly published outputs cleanup-owned until complete path/type/digest equality and the recorded empty-directory policy are verified.
- Replaced shell-mediated symlink hashing with SHA-256 over the exact Buffer returned by `fs.readlinkSync(..., { encoding: "buffer" })`.
- Added deterministic mutation, embedded-newline, trailing-newline, empty-looking, non-UTF-8, unchanged-link, changed-link, and unavailable-byte controls.

## Task Commits

Each task was committed through its TDD RED and GREEN gates:

1. **Task 1 RED: final artifact mutation fixture** - `9a6c5ed0` (test)
2. **Task 1 GREEN: final artifact reconciliation** - `6f3f6d5a` (feat)
3. **Task 2 RED: raw symlink byte fixtures** - `9ecaa1a7` (test)
4. **Task 2 GREEN: raw-Buffer symlink hashing** - `5ac97be4` (feat)

## Files Created/Modified

- `scripts/ci/preserve_repository_state.sh` - Adds reusable final artifact snapshots, raw symlink byte hashing, and deterministic fail-closed fixtures.

## Decisions Made

- The final artifact comparison is a byte-for-byte `cmp` of canonical sorted NUL-delimited triples, so additions, removals, renames, type changes, and digest changes share one exact invariant.
- Test mutation hooks are in-process self-test state only; production CLI arguments and environment variables cannot activate them.
- Symlink targets are never opened or resolved. Only link text returned as a Buffer is hashed, and read/non-Buffer failures terminate preservation without PASS.

## TDD Gate Compliance

- Task 1 RED evidence returned `RED_EVIDENCE_OK`: `post-snapshot artifact mutation is rejected` failed because the stale implementation accepted the deliberate mutation.
- Task 1 GREEN made the same fixture and full preservation self-test pass; the tracer feedback rerun also passed before Task 2 began.
- Task 2 RED evidence returned `RED_EVIDENCE_OK`: `raw Buffer symlink link-text bytes are hashed exactly` failed on the trailing-newline digest mismatch.
- Task 2 GREEN made all raw-byte fixtures and the full preservation self-test pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Split nounset-sensitive local initialization**
- **Found during:** Task 1 GREEN verification
- **Issue:** Assigning `output` and deriving `path_list` in one `local` statement expanded the unset variable under `set -u`.
- **Fix:** Declared `path_list` first, then derived it after `output` was assigned.
- **Files modified:** `scripts/ci/preserve_repository_state.sh`
- **Verification:** The complete self-test passed, then passed twice again at plan verification.
- **Committed in:** `6f3f6d5a`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** The fix was required for the planned reusable snapshot routine to run under the script's existing strict Bash mode; no scope was added.

## Issues Encountered

None remain.

## User Setup Required

None - no external service configuration required.

## Verification

- `bash -n scripts/ci/preserve_repository_state.sh && bash scripts/ci/preserve_repository_state.sh --self-test` passed twice consecutively (`first_status=0`, `second_status=0`).
- All six files in the existing external Phase 229 recovery directory retained their pre-execution SHA-256 digests, including manifest `52f3ea27...` and bundle `4108818c...`.
- The realized task diff from `724cdadd...` through `5ac97be4` modifies only `scripts/ci/preserve_repository_state.sh`.

## Next Phase Readiness

CR-01 and CR-02 are closed with executable process-boundary evidence. Plan 229-11 can proceed without changing the pre-existing recovery capsule or any user-owned workspace artifact.

## Self-Check: PASSED

- `scripts/ci/preserve_repository_state.sh` exists and is the only task-modified tracked file.
- Task commits `9a6c5ed0`, `6f3f6d5a`, `9ecaa1a7`, and `5ac97be4` exist in git history.
- Coverage metadata classifies both deliverables as fully automated and passing.
- Existing external recovery-capsule digests match the pre-execution snapshot.
