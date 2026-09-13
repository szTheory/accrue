---
phase: 229-repository-truth-recovery-safety
plan: 13
subsystem: repository-safety
tags: [git, recovery, worktrees, provenance, privacy, node-test]
requires:
  - phase: 229-10
    provides: Final artifact reconciliation and raw symlink-byte evidence
  - phase: 229-11
    provides: Bounded plural GitHub pagination and ordered request provenance
  - phase: 229-12
    provides: Absolute CI deadline and selected/viewed run identity binding
provides:
  - Independent live-object and exact canonical ref reconciliation
  - Direct worktree and ship-window authority comparison with multiplicity
  - Exact category-specific GitHub provenance and cross-platform privacy enforcement
  - Named CR-01 through CR-09 plus WR-02 adversarial process matrix
affects: [229-14, phase-229-verification, repository-inventory, release-handoff]
actuals:
  tokens: 9440
  tasks: 2
  commits: 4
plan_head_before: 7c149fd02bc6dc7f38b39bee1e557fe5245b6df8
commits: 4
tech-stack:
  added: []
  patterns: [independent authority reconciliation, exact multiset comparison, category-specific provenance, field-safe privacy validation]
key-files:
  created: []
  modified:
    - scripts/ci/verify_repository_inventory.mjs
    - scripts/ci/phase229_gap_closure.test.mjs
key-decisions:
  - "The active branch is the only allowed frozen-ref continuity exception, and its canonical object must equal the independently resolved live symbolic ref object."
  - "Canonical worktrees and ship windows are exact multisets read independently by the verifier from Git porcelain and bounded WINDOWS.md parsing."
  - "Plural remote provenance is an exact contiguous page sequence whose SHA count proves a short terminal page when evidence is available."
  - "Privacy rejection covers POSIX, Windows, UNC, drive-relative, file-URI, C0, and DEL forms while dedicated normalized repository-relative artifact paths remain valid."
patterns-established:
  - "Authority split: private manifest, bundle heads, live preservation refs, canonical preservation rows, and canonical non-preservation rows are independently compared."
  - "Adversarial matrix: every refreshed Phase 229 blocker is exercised through the same public function, CLI, or subprocess boundary maintainers use."
requirements-completed: [REPO-01, REPO-02, REPO-03]
coverage:
  - id: D1
    description: Strict recovery resolves the live active object and exactly reconciles canonical preservation and non-preservation ref maps.
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "scripts/ci/phase229_gap_closure.test.mjs#CR-04 and CR-05"
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical worktrees and ship windows exactly match independent Git and planning-ledger authorities.
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/ci/phase229_gap_closure.test.mjs#CR-06"
        status: pass
    human_judgment: false
  - id: D3
    description: Remote evidence has exact bounded provenance and committed strings cannot expose path-like or control-bearing private locations.
    requirement: REPO-01
    verification:
      - kind: integration
        ref: "scripts/ci/phase229_gap_closure.test.mjs#CR-07 and CR-08"
        status: pass
    human_judgment: false
  - id: D4
    description: One named suite replays CR-01 through CR-09 and WR-02 through public and process interfaces.
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node --test scripts/ci/phase229_gap_closure.test.mjs"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 13: Independent Repository Authority and Adversarial Matrix Summary

**Strict inventory verification now resolves repository and planning authorities directly, enforces exact remote provenance and privacy boundaries, and replays every refreshed blocker through executable regressions.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-13T19:23:08Z
- **Completed:** 2026-09-13T19:34:18Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Proved the canonical active branch against the live symbolic ref and existing Git object, while preserving the frozen object independently in manifest, bundle, and encoded refs.
- Compared canonical preservation refs, non-preservation refs, worktrees, and ship windows exactly against independent authorities, including missing, extra, duplicate, dirty, detached, and changed-state cases.
- Replaced repository-prefix provenance with exact main, PR, release-ref, and Actions request contracts, bounded contiguous pages, and available-result terminal-page proof.
- Rejected POSIX, Windows, UNC, drive-relative, file-URI, C0, and DEL private/path-like values before committed evidence can pass strict verification.
- Expanded the gap-closure suite to 20 tests with named CR-01 through CR-09 and WR-02 public/process coverage.

## Task Commits

Each task was committed through its TDD RED and GREEN gates:

1. **Task 1 RED: authority reconciliation probes** - `7f4fa20a` (test)
2. **Task 1 GREEN: live ref and local authority reconciliation** - `996e5435` (feat)
3. **Task 2 RED: provenance, privacy, and complete adversarial matrix** - `047988b9` (test)
4. **Task 2 GREEN: exact provenance and comprehensive privacy enforcement** - `0117e720` (feat)

## Files Created/Modified

- `scripts/ci/verify_repository_inventory.mjs` - Adds live active-object proof, exact preservation/canonical ref maps, verifier-owned worktree/window reads, exact remote request sequences, and comprehensive private-location rejection.
- `scripts/ci/phase229_gap_closure.test.mjs` - Adds isolated temporary authorities and named CR-01 through CR-09 plus WR-02 process/public-interface regressions.

## Decisions Made

- The narrow active-branch continuity exception is accepted only after `symbolic-ref`, `rev-parse`, and `cat-file` independently prove the current object; canonical data cannot nominate its own exception value.
- Worktrees use exact sorted multiplicity rather than a keyed map so indistinguishable sanitized rows cannot hide duplicate or missing worktrees.
- Available plural evidence proves termination by combining an exact contiguous request sequence with the retained SHA count; unavailable evidence retains only its exact attempted sequence and bounded reason.
- Generic privacy scanning rejects machine-location syntax and controls, while the inventory schema remains the dedicated authority for normalized repository-relative artifact paths.

## TDD Gate Compliance

- Task 1 RED returned `RED_EVIDENCE_OK`: all three named CR-04, CR-05, and CR-06 tests failed because fabricated/incomplete canonical evidence returned verifier status 0.
- Task 1 GREEN passed the 13-test gap suite and strict recovery fixture command; the tracer feedback rerun passed before Task 2 began.
- Task 2 RED returned `RED_EVIDENCE_OK`: the unrelated same-repository endpoint and `/var/private/...` location were accepted by the public strict command.
- Task 2 GREEN passed the final 20-test matrix, all-flags fixture command, syntax check, and eight-test embedded verifier suite.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned existing verifier fixtures with Plan 229-11 plural provenance**

- **Found during:** Task 1 GREEN verification
- **Issue:** The verifier's pre-existing private fixture still emitted plural `request` fields after Plan 229-11 intentionally changed plural evidence to ordered `requests` arrays, so the mandated fixture command failed before reaching Task 1 assertions.
- **Fix:** Updated the existing fixture and compatibility assertion to use the ordered plural schema before tightening it in Task 2.
- **Files modified:** `scripts/ci/verify_repository_inventory.mjs`
- **Verification:** The Task 1 strict fixture command and final all-flags fixture command both pass.
- **Committed in:** `996e5435`

---

**Total deviations:** 1 auto-fixed (1 Rule 3 blocking issue).
**Impact on plan:** The compatibility repair was required to exercise the planned verifier boundary after its direct Plan 229-11 dependency; it added no API capability or production scope.

## Issues Encountered

- Node's test runner propagates `NODE_TEST_CONTEXT` to child processes. The gap suite explicitly removes it from public CLI subprocess environments so verifier and renderer children execute their CLI entry points instead of registering nested tests.

## Authentication Gates

None.

## Known Stubs

None. Empty arrays, nullable fixture state, and generated mutation variants are intentional test data or exact empty-category representations, not unwired behavior.

## User Setup Required

None - tests create and remove only their own temporary repositories and recovery capsules.

## Verification

- `node --check scripts/ci/verify_repository_inventory.mjs` - PASS.
- `node --test scripts/ci/phase229_gap_closure.test.mjs` - PASS, 20/20 tests.
- Full strict fixture command with recovery, all-ref, typed-artifact, complete-category, edge-case, provenance, privacy, and determinism flags - PASS.
- `node --test scripts/ci/verify_repository_inventory.mjs` - PASS, 8/8 tests including imported collector controls.
- `git status --short` contains only the same seven pre-existing untracked paths; no external recovery capsule path was read, written, or removed.

## Next Phase Readiness

- Plan 229-14 can recapture and render the canonical inventory against an verifier that no longer trusts self-consistent ref, local-category, provenance, or privacy assertions.
- REPO-01, REPO-02, and REPO-03 now have executable independent-authority coverage across every refreshed critical boundary.

## Self-Check: PASSED

- Both modified implementation/test files and `229-13-SUMMARY.md` exist.
- Task commits `7f4fa20a`, `996e5435`, `047988b9`, and `0117e720` exist in git history.
- The persisted plan ledger measures four task commits from base `7c149fd02bc6dc7f38b39bee1e557fe5245b6df8`.
- No plan-owned stub, skipped test, unrun verification, or unmodeled threat surface remains.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
