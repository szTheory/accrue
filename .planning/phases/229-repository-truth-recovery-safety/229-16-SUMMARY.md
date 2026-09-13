---
phase: 229-repository-truth-recovery-safety
plan: 16
subsystem: repository-safety
tags: [bash, git-update-ref, rollback, recovery-capsule, failure-injection, tdd]
requires:
  - phase: 229-10
    provides: "Final artifact reconciliation and raw symlink-byte preservation fixtures"
provides:
  - "Transactional preservation-ref creation with object-guarded rollback"
  - "Exact identity-guarded cleanup for temporary and published capsule outputs"
  - "Fresh-repository reached-boundary failure matrix across preparation and publication"
affects: [229-19, 229-20, recovery-capsule-publication]
actuals:
  tokens: 6117
  tasks: 2
  commits: 4
plan_head_before: 4c0beb0c26efee40811a52c8ce9abb217164e29d
commits: 4
tech-stack:
  added: []
  patterns: [absent-old-value ref creation, object-guarded compare-delete, exact output identity ledger, test-only reached checkpoints]
key-files:
  created: []
  modified:
    - scripts/ci/preserve_repository_state.sh
key-decisions:
  - "A preservation ref enters the rollback ledger only after `git update-ref` proves the old object was absent and creates the expected object atomically."
  - "Failure cleanup compare-deletes each ledgered ref against its expected object; a changed ref is retained and reported as a rollback conflict."
  - "All fallible bundle, artifact, manifest, and public-record preparation completes before preservation refs are published."
patterns-established:
  - "Failure-boundary proof: each test owns a fresh repository/capsule, requires an exact reached marker, and compares refs, status, index, worktrees, artifacts, and output entries."
  - "Output ownership uses inode identity for temporary files and inode-plus-digest identity for published outputs before cleanup."
requirements-completed: [REPO-02]
coverage:
  - id: D1
    description: "Every reached preparation/publication failure returns refs, index, status, worktrees, artifacts, and capsule entries to exact pre-invocation state."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "bash scripts/ci/preserve_repository_state.sh --self-test#transaction failure matrix"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rollback targets only invocation-created refs that still equal their recorded objects; pre-existing and concurrently changed refs are retained."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/preserve_repository_state.sh#assert_preexisting_preservation_ref_retained and assert_concurrently_changed_ref_retained"
        status: pass
    human_judgment: false
  - id: D3
    description: "Successful preservation retains all verified refs and capsule outputs after late atomic publication."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "bash -n scripts/ci/preserve_repository_state.sh && bash scripts/ci/preserve_repository_state.sh --self-test && bash scripts/ci/preserve_repository_state.sh --self-test"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 16: Transactional Preservation Publication Summary

**Preservation now prepares recovery authority before publishing refs and rolls back only exact invocation-owned ref objects and capsule outputs across every tested failure boundary.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-13T21:09:49Z
- **Completed:** 2026-09-13T21:19:08Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Reproduced CR-10 on a fresh repository and proved the original post-manifest failure leaked preservation refs rather than short-circuiting on an earlier collision.
- Added atomic absent-old-value creation plus a ref/object rollback ledger that compare-deletes unchanged invocation-owned refs only.
- Moved bundle construction/verification, artifact capture, manifest generation, and public-record preparation ahead of ref publication.
- Added exact identity-ledger cleanup for temporary and published outputs and a ten-boundary failure matrix with fresh repositories and reached markers.
- Proved pre-existing refs remain exact and a concurrently changed ref survives rollback with an explicit conflict report.

## Task Commits

Each task followed an intentional RED then GREEN TDD cycle:

1. **Task 1 RED: Reproduce a post-manifest ref leak on a fresh repository** - `828f9fe0`
2. **Task 1 GREEN: Roll back exact invocation-owned ref objects** - `8926ac31`
3. **Task 2 RED: Expose ref publication before fallible preparation** - `a322743a`
4. **Task 2 GREEN: Reorder and verify the complete transactional boundary matrix** - `f90c0d75`

## Files Created/Modified

- `scripts/ci/preserve_repository_state.sh` - Late ref publication, exact ref/output rollback ledgers, internal failure checkpoints, and process-boundary transactional fixtures.

## Decisions Made

- Used Git's zero old-object argument as the atomic proof that a preservation ref was absent before this invocation.
- Stored ref and expected-object pairs in creation order and rolled them back in reverse order with compare-and-delete.
- Initialized all failure controls inside the script and allowed them to change only within the self-test's process-local subshells; production arguments and environment cannot select a new failure point.
- Kept a concurrently changed ref as authoritative external state rather than forcing cleanup, while still removing every unchanged invocation-owned ref/output.

## TDD Gate Compliance

- RED `828f9fe0` reached the post-manifest checkpoint and failed only because exact pre/post ref authority differed; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- GREEN `8926ac31` made that fresh-repository transaction fixture and the complete prior self-test pass.
- RED `a322743a` reached the post-manifest checkpoint and failed only because preservation refs were already visible before preparation completed; `check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- GREEN `f90c0d75` passed the full matrix twice consecutively, including preparation, publication, pre-existing-ref, concurrent-ref, and success cases.

## Verification

- `bash -n scripts/ci/preserve_repository_state.sh` - PASS.
- First `bash scripts/ci/preserve_repository_state.sh --self-test` - PASS.
- Second consecutive self-test - PASS.
- Original private manifest SHA-256 remained `52f3ea27d5551fba55d3666b44911104a20386b6ce1610eb8e194aab395817b4`.
- Original recovery bundle SHA-256 remained `4108818c08a1d2a2c3c75058a30789bd89f6e5f44f1268e09252f337c714a869`.
- `git diff --check` - PASS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Refreshed temporary bundle identity after Git replaced the prepared inode**

- **Found during:** Task 2 GREEN verification
- **Issue:** `git bundle create` replaces the pre-created `mktemp` file, so the initial inode ledger caused safe cleanup to retain the replacement temporary bundle after injected failure.
- **Fix:** Refresh the registered temporary identity immediately after successful bundle construction, before any later failure boundary.
- **Files modified:** `scripts/ci/preserve_repository_state.sh`
- **Verification:** The exact output-entry comparisons pass at all ten injected boundaries in two consecutive self-tests.
- **Committed in:** `f90c0d75`

**2. [Rule 1 - Bug] Removed a collision-short-circuited legacy injection check**

- **Found during:** Task 2 GREEN verification
- **Issue:** The old environment-triggered injection reused a repository after successful preservation, so it still passed by colliding before the intended boundary.
- **Fix:** Removed the obsolete external hook/check; process-local fresh-repository checkpoints now prove every intended boundary was reached.
- **Files modified:** `scripts/ci/preserve_repository_state.sh`
- **Verification:** Each matrix case requires its own exact reached marker and final-state comparison.
- **Committed in:** `f90c0d75`

---

**Total deviations:** 2 auto-fixed bugs.
**Impact on plan:** Both fixes were necessary for exact cleanup ownership and trustworthy boundary coverage; no mutation capability was exposed to production callers.

## Issues Encountered

None remain.

## Authentication Gates

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 229-19 can wrap canonical output publication knowing preservation refs and capsule outputs return transactionally on every tested failure.
- Plan 229-20 can run the preservation self-test repeatedly without collision-short-circuiting its failure evidence.
- The original private recovery capsule and unrelated/untracked workspace files remain unchanged.

## Self-Check: PASSED

- The preservation script and this summary exist.
- Task commits `828f9fe0`, `8926ac31`, `a322743a`, and `f90c0d75` are present in git history.
- The plan ledger measures four task commits from base `4c0beb0c26efee40811a52c8ce9abb217164e29d`.
- Two consecutive full self-tests passed with the original manifest and bundle hashes unchanged.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
