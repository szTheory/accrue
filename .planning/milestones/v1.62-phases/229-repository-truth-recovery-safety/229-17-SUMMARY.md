---
phase: 229-repository-truth-recovery-safety
plan: 17
subsystem: repository-safety
tags: [git-ancestry, no-follow, sha256, planning-authority, bundle-identity, tdd]
requires:
  - phase: 229-15
    provides: "Exact captured-at active-ref and primary-worktree authority"
provides:
  - "Same-ref A-to-B-to-C capture ancestry with exact inactive ref and worktree continuity"
  - "Independent bounded no-follow digests or exact absence for MILESTONES.md and STATE.md"
  - "Stable current-owner restrictive recovery-bundle authority shared by hashing and Git verification"
affects: [229-19, 229-20, repository-inventory-verification]
actuals:
  tokens: 7891
  tasks: 2
  commits: 4
plan_head_before: 833e52bc3f8eaef094e6f216b8c9a1f98177daf6
commits: 4
tech-stack:
  added: []
  patterns: [same-ref ancestor proof, exact inactive authority, bounded descriptor hashing, no-follow stable identity]
key-files:
  created: []
  modified:
    - scripts/ci/verify_repository_inventory.mjs
key-decisions:
  - "Only the captured active symbolic ref and its identified primary worktree may advance, and only when the captured commit exists and is an ancestor of the independently resolved live object."
  - "Every inactive ref, preservation ref, and non-primary worktree remains an exact set/object identity rather than inheriting active-branch tolerance."
  - "Planning and recovery-bundle inputs are opened without following links and remain acceptable only while their path, descriptor, ownership, mode, size, mtime, and bytes stay stable."
patterns-established:
  - "Point-in-time capture proof reconciles an internally exact A record with live same-ref C ancestry while comparing all non-active authority exactly."
  - "Descriptor-backed Git bundle commands use fresh no-follow descriptors for independent file offsets and compare each descriptor to one anchored identity."
requirements-completed: [REPO-01, REPO-02]
coverage:
  - id: D1
    description: "An inventory captured at A remains valid after canonical commit B and later phase commit C only on the same active ref, while fabricated anchors and inactive advances are rejected."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/ci/verify_repository_inventory.mjs#strict repository inventory flags enforce independent negative controls"
        status: pass
    human_judgment: false
  - id: D2
    description: "Complete categories independently hash bounded planning files or prove exact absence, rejecting fabricated, swapped, stale, malformed, symlinked, missing, and changed authority."
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/ci/verify_repository_inventory.mjs#CR-08 complete categories derive planning digests independently"
        status: pass
    human_judgment: false
  - id: D3
    description: "Standalone recovery rejects aliased, non-regular, foreign-owner, broad-mode, and replaced bundles while one stable restrictive identity passes hashing and both Git bundle operations."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/verify_repository_inventory.mjs#WR-02 standalone recovery rejects followed bundle aliases"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 17: Independent Capture and Filesystem Authority Summary

**Strict inventory verification now tolerates only proven same-ref active ancestry while deriving planning and recovery-bundle truth from bounded, stable, no-follow filesystem authority.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-13T21:24:46Z
- **Completed:** 2026-09-13T21:34:18Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added a real A-to-B-to-C repository fixture and same-ref ancestor proof using shell-disabled Git object and merge-base checks.
- Preserved exact frozen state for every inactive original/preservation ref and non-primary worktree, including negative divergent, descendant, rewritten, wrong-ref, and inactive-advance cases.
- Recomputed MILESTONES.md and STATE.md authority through bounded no-follow descriptors, with exact SHA-256 or a distinct absence marker.
- Bound manifest digest reconciliation, bundle bytes, Git verification, and bundle heads to one current-owner restrictive identity with replacement detection.

## Task Commits

Each task followed an intentional RED then GREEN TDD cycle:

1. **Task 1 RED: Reproduce stale active capture rejection after A-to-B-to-C advancement** - `2a29b4c2`
2. **Task 1 GREEN: Prove captured active ancestry and exact inactive continuity** - `7166dd5d`
3. **Task 2 RED: Expose fabricated planning values and followed bundle aliases** - `b276f106`
4. **Task 2 GREEN: Derive planning and stable no-follow bundle authority** - `15e07d1a`

## Files Created/Modified

- `scripts/ci/verify_repository_inventory.mjs` - Point-in-time ancestry reconciliation, exact inactive authorities, independent planning facts, stable bundle inspection, and adversarial fixtures.

## Decisions Made

- Kept the committed inventory as a point-in-time A record. Live C is independently resolved and accepted only through the same full symbolic ref and an existing-commit ancestor proof.
- Compared the complete captured ref map to live refs with exactly one active exception; new, missing, or changed inactive and preservation refs remain invalid.
- Identified the live primary worktree by its real top-level path, then substituted only its live descendant HEAD before exact multiset comparison.
- Used fresh descriptor-backed paths for each Git bundle command because duplicated child descriptors share offsets; every fresh descriptor must match the initially anchored identity.

## TDD Gate Compliance

- RED `2a29b4c2` rejected the named A-to-B-to-C fixture because strict recovery still required captured A to equal live C. The evidence checker returned `RED_EVIDENCE_OK` with `target_test_failed`.
- GREEN `7166dd5d` passed the real ancestry case and rejected nonexistent, divergent, descendant-nominated, wrong-ref, wrong-primary-worktree, rewritten, inactive-ref, and inactive-worktree variants.
- RED `b276f106` produced the two named assertion failures because fabricated planning strings and a bundle symlink were still accepted. The evidence checker returned `RED_EVIDENCE_OK` with `target_test_failed`.
- GREEN `15e07d1a` passed all four embedded verifier tests and the strict recovery/complete-category fixture CLI.

## Validation Evidence

- Node syntax validation passed.
- Embedded verifier suite passed 4/4.
- Strict recovery plus all-ref and complete-category fixture CLI passed.
- Gap suite passed 14/18 unaffected cases; its four pre-capture fixtures remain assigned to Plan 229-19.
- Original private manifest SHA-256 remained `52f3ea27d5551fba55d3666b44911104a20386b6ce1610eb8e194aab395817b4`.
- Original recovery bundle SHA-256 remained `4108818c08a1d2a2c3c75058a30789bd89f6e5f44f1268e09252f337c714a869`.
- Git whitespace validation passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Opened a fresh stable descriptor for each Git bundle command**

- **Found during:** Task 2 GREEN verification
- **Issue:** Reusing one inherited descriptor made bundle verification advance the shared file offset, so bundle head listing observed EOF rather than the anchored bytes.
- **Fix:** Each Git command now receives a fresh no-follow descriptor that must match the original identity; the original descriptor remains open for the independent first and second byte digests.
- **Files modified:** `scripts/ci/verify_repository_inventory.mjs`
- **Verification:** Stable bundle verification and list-heads pass, while deterministic replacement between hashing and Git inspection is rejected.
- **Committed in:** `15e07d1a`

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The fix preserves the planned single-identity authority while respecting independent child-process file offsets; no authority or mutation scope was widened.

## Issues Encountered

- The required broader gap suite reports four known pre-capture fixture drifts: WR-01 documented strict command, CR-04 active-ref recovery, CR-07 provenance, and CR-08 privacy. Each stops at the capture schema added by Plan 229-15. Per orchestrator direction, `scripts/ci/phase229_gap_closure.test.mjs` remains owned by dependent Plan 229-19; all 14 unaffected cases pass.

## Authentication Gates

None.

## Known Stubs

None. Absence markers, empty-file digests, unavailable remote rows, and temporary fixture objects are intentional exact test states.

## User Setup Required

None.

## Next Phase Readiness

- Plan 229-19 can update its real-chain and documented-command fixtures against the stable capture schema and post-capture ancestry rule.
- Plan 229-20 can recapture canonical inventory without ordinary later active-branch commits self-invalidating it.
- The original private recovery capsule and all unrelated user-owned workspace files remain unchanged.

## Self-Check: PASSED

- The modified verifier and this summary exist.
- Task commits `2a29b4c2`, `7166dd5d`, `b276f106`, and `15e07d1a` are present in git history.
- The persisted plan ledger measures four task commits from base `833e52bc3f8eaef094e6f216b8c9a1f98177daf6`.
- All Plan-17-owned targeted checks pass with unchanged original recovery-capsule hashes.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
