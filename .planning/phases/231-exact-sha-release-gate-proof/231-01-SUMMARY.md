---
phase: 231-exact-sha-release-gate-proof
plan: 01
subsystem: infra
tags: [git, ci-evidence, node, release-gate]

requires:
  - phase: 230-reviewable-history-integration
    provides: refs/heads/integration/v1.62-candidate, verify_integration_disposition.mjs, verify_phase230_archive_invariants.mjs, phase_evidence_path.mjs
provides:
  - "integration/v1.62-candidate re-cut to a new merge (85aed062) + two re-applied commits (tip f524f2a6), superseding bab50d92"
  - scripts/ci/verify_recut_candidate.mjs (D-04 shape/ancestry/revert/toolchain gate verifier, 4th-triad-style module)
  - .planning/phases/231-exact-sha-release-gate-proof/231-ROLLBACK-POINT.json (re-minted rollback point)
affects: [231-02, 231-03, 231-04, 231-05, 231-06]

actuals:
  tokens: 8751
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "collectRecutGates re-derives shape/ancestry/revert-proof/toolchain gates live from git plumbing and compares against an externally-recorded expectation (never the same live value it just derived), so the comparison cannot be tautologically true"
    - "shape/unique-commit-count judged against the RECORDED milestone-HEAD-at-cut/origin-main identity, not the candidate's own derived immediate parents — the only way to detect a 'second merge point' (D-05 advance-by-merging), since a bona-fide 2-parent merge's own parents always yield unique_commit_count=1 by construction"
    - "revert-proof and toolchain-pin gates compare against record-supplied expectations (expected_reverted_tree, superseded .tool-versions blob) rather than re-deriving the same value being tested, for the same tautology-avoidance reason"

key-files:
  created:
    - scripts/ci/verify_recut_candidate.mjs
    - .planning/phases/231-exact-sha-release-gate-proof/231-ROLLBACK-POINT.json
  modified: []

key-decisions:
  - "Re-cut integration/v1.62-candidate from a freshly re-measured milestone HEAD (8a3bdd60) rather than freezing the superseded bab50d92, which predated its own gating verifiers (D-01)."
  - "collectRecutGates takes explicit expected identity (firstParent/secondParent/expectedRevertedTree) as parameters rather than deriving everything from the candidate's own immediate parents — required to make the D-05 'second merge point' failure mode detectable at all, since git's own revert/rev-list semantics make a self-referential comparison tautologically true."
  - "Cherry-picked the two unique non-merge commits (31d19449 toolchain pin, bab50d92 config.ex test) from the superseded candidate verbatim rather than re-authoring them, so content cannot drift (per plan instruction)."
  - "Removed the stale untracked root .tool-versions (nodejs-only) before cherry-picking, since it would have silently blocked the toolchain-pin commit from landing and left the working tree's toolchain pin incomplete (231-RESEARCH.md Pitfall 2)."

patterns-established:
  - "Fourth-generation collect/verify-style script (verify_recut_candidate.mjs) follows the same fail()/fields()/fullSha()/run() primitives and --fixtures/--require-* CLI convention as verify_integration_disposition.mjs."

requirements-completed: [GATE-01]

coverage:
  - id: D1
    description: "scripts/ci/verify_recut_candidate.mjs re-derives every D-04 shape, ancestry, revert-proof, and toolchain gate live from git plumbing, with negative controls for each --require-* flag"
    requirement: GATE-01
    verification:
      - kind: unit
        ref: "scripts/ci/verify_recut_candidate.mjs#recut candidate fixtures pass every negative control"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_recut_candidate.mjs --fixtures --expected-repository szTheory/accrue"
        status: pass
    human_judgment: false
  - id: D2
    description: "integration/v1.62-candidate re-cut to a new commit (85aed062 merge / f524f2a6 tip) containing the Phase 230 verifiers, satisfying every D-04 shape/ancestry/revert/toolchain gate under the strict verifier"
    requirement: GATE-01
    verification:
      - kind: other
        ref: "node scripts/ci/verify_recut_candidate.mjs --repo . --record .planning/phases/231-exact-sha-release-gate-proof/231-ROLLBACK-POINT.json --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain --require-supersession"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-15
status: complete
---

# Phase 231 Plan 1: Exact-SHA Release Gate Proof — Re-cut Summary

Re-cut `integration/v1.62-candidate` to a fresh merge of `origin/main` into current milestone HEAD, containing the Phase 230 verifiers the release gates depend on, and froze it behind a new executable D-04 shape/ancestry/revert/toolchain verifier with a negative control per strict flag.

## Performance

- **Duration:** 55 min
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- Authored `scripts/ci/verify_recut_candidate.mjs`: `RECUT_RECORD_FIELDS` closed allow-list, `validateRecutRecord` schema validator, `collectRecutGates` (live re-derivation of shape/ancestry/revert-proof/toolchain gates), `verifyFixtures` (positive control plus one negative control per `--require-*` flag), and a `--fixtures`/schema-only/strict-verified CLI split — built via a genuine RED (stubbed `collectRecutGates` throwing, confirmed `RED_EVIDENCE_OK` via `gsd_run check tdd-red-evidence`) then GREEN (full implementation, all tests passing) cycle.
- Re-cut `integration/v1.62-candidate` from milestone HEAD `8a3bdd60` (re-measured live immediately before cutting, not transcribed from CONTEXT.md's stale `030a3c6e`) merged `--no-ff` with `origin/main` `d30fc25d`, producing merge commit `85aed0629194be5409d3f3f8caa87cea8d584134`.
- Re-applied the toolchain pin (`31d19449`) and the config.ex disjoint-hunk coverage test (`bab50d92`) via `git cherry-pick -x`, landing the branch tip at `f524f2a6b16d3576829632ab6fa77d24b718e6f7`.
- Verified live: 2 parents, unique-commit-count of the merge object relative to `[milestoneHEAD, originMain]` = 1, all 4 closure commits + `v1.61` commit + `origin/main` ancestors of the candidate, a scratch-clone `git revert -m 1 --no-edit` reproduces the milestone parent's tree byte-identically (`78490c13...`), and the candidate tip's tracked `.tool-versions` is byte-identical to the superseded blob (sha256 `a3e578a5...`).
- Minted `.planning/phases/231-exact-sha-release-gate-proof/231-ROLLBACK-POINT.json` (mode `0600`) superseding `bab50d92` by reference, with a `cause` field naming both Phase 230 verifiers the superseded candidate lacked.

## Task Commits

Each task was committed atomically (TDD gate: RED then GREEN for Task 1):

1. **Task 1 RED:** `354fe92a` (test) — failing fixture test, `collectRecutGates` stubbed to throw; `RED_EVIDENCE_OK` confirmed via `gsd_run check tdd-red-evidence`.
2. **Task 1 GREEN:** `8a3bdd60` (feat) — full `collectRecutGates`/`applyRequire*` implementation; all fixtures and `--fixtures` CLI pass.
3. **Task 2:** `0cb6c16a` (feat) — re-cut candidate + `231-ROLLBACK-POINT.json`.

## Files Created/Modified

- `scripts/ci/verify_recut_candidate.mjs` — D-04 shape/ancestry/revert/toolchain verifier, 4th-generation `scripts/ci/` evidence module.
- `.planning/phases/231-exact-sha-release-gate-proof/231-ROLLBACK-POINT.json` — re-minted rollback point (mode 0600).

## Decisions Made

- `collectRecutGates` compares live-derived facts against RECORD-supplied expectations (`firstParent`/`secondParent`/`expectedRevertedTree`), not against values re-derived from the same candidate — a self-referential comparison (e.g. comparing a merge's own revert result against its own first parent's tree) is tautologically true for any 2-parent merge by git's construction, so it could never detect drift or a "second merge point." This surfaced during fixture-writing (Task 1) as an empirical discovery, not a design guess — see "Deviations" below.
- Shape identity (`single_first_parent_merge`) is judged solely on the candidate's own immediate parent count; the unique-commit-count gate (using recorded expected identity) is what actually catches D-05's advance-by-merging/merge-back-then-recut failure mode.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Revert-proof and toolchain-pin gates redesigned to avoid tautological self-comparison**
- **Found during:** Task 1, while writing the "second merge point" and "differing reverted tree" fixture negative controls.
- **Issue:** The plan's literal wording ("unique-commit count via `git rev-list --count <candidate> ^<first-parent> ^<second-parent>`" and "compare `HEAD^{tree}` against the first parent's tree") is ambiguous about whether "first-parent"/"second-parent" mean the candidate's own immediate parents (derived) or the recorded expected identity. Empirically: for ANY genuine 2-parent merge, `git rev-list M ^P0 ^P1` using M's own immediate parents always equals exactly 1, and `git revert -m 1 M` always reproduces parent 1's tree exactly — both by git's own construction. A design that derived the comparison target from the candidate's own live parents could never fail these gates under any real 2-parent-merge fixture, defeating the point of a negative control.
- **Fix:** `collectRecutGates` accepts `firstParent`/`secondParent`/`expectedRevertedTree` as caller-supplied values (sourced from `231-ROLLBACK-POINT.json`'s `parents`/`expected_reverted_tree` fields at real-invocation time) and compares LIVE git facts against those recorded values, not against values re-derived from the same live parents.
- **Files modified:** `scripts/ci/verify_recut_candidate.mjs`.
- **Verification:** Fixture negative controls for both gates (a `merge --no-ff` of the already-built candidate back into milestone, and a mismatched `expected_reverted_tree`) now genuinely fail with the expected/actual messages; positive controls still pass.
- **Committed in:** `8a3bdd60` (Task 1 GREEN commit).

**2. [Rule 3 - Blocking] Removed stale untracked root `.tool-versions` before cherry-picking**
- **Found during:** Task 2, cherry-picking the toolchain-pin commit.
- **Issue:** An untracked `.tool-versions` (containing only `nodejs 22.14.0`, per 231-RESEARCH.md Pitfall 2) already existed at the repo root and blocked `git cherry-pick -x 31d19449` with "untracked working tree files would be overwritten."
- **Fix:** Removed the untracked file (safe — it was never committed, and the cherry-pick immediately replaced it with the tracked three-line version).
- **Files modified:** none tracked (removed an untracked file).
- **Verification:** Cherry-pick succeeded; candidate tip's tracked `.tool-versions` contains all three lines (`nodejs 22.14.0`, `elixir 1.19.5-otp-28`, `erlang 28.5`).
- **Committed in:** `0cb6c16a` (Task 2 commit) — the file itself was untracked so nothing to commit for its removal; the commit captures the resulting tracked `.tool-versions`.

**3. [Rule 1 - Bug] Detached HEAD after returning to the milestone branch by SHA**
- **Found during:** Task 2, after repointing the candidate ref.
- **Issue:** `git checkout <captured-SHA>` (rather than the branch name) left the repository in detached HEAD state instead of back on `gsd/milestone-v1.62-release-integration-hygiene`.
- **Fix:** Immediately re-checked out the branch by name (`git checkout gsd/milestone-v1.62-release-integration-hygiene`); no commits had been made in the detached state, so nothing was lost.
- **Files modified:** none.
- **Verification:** `git rev-parse --abbrev-ref HEAD` confirmed the correct branch and matching SHA afterward.
- **Committed in:** n/a (working-tree/HEAD state fix, no file change).

---

**Total deviations:** 3 auto-fixed (1 bug in gate design caught during fixture-writing, 1 blocking untracked-file removal, 1 bug in branch navigation). **Impact:** All three were necessary corrections with no scope creep; deviation 1 is the most consequential — it changed the tautology-avoidance design of two gates before any fixture was even run against the real repository, catching what would otherwise have been a permanently-vacuous check.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

`integration/v1.62-candidate` now points at a new commit (`85aed0629194be5409d3f3f8caa87cea8d584134` merge / `f524f2a6b16d3576829632ab6fa77d24b718e6f7` tip) containing the Phase 230 verifiers, satisfying every D-04 gate under `scripts/ci/verify_recut_candidate.mjs`. The candidate ref was NOT pushed (Plan 231-04's separately authorized step, D-14). Plans 231-02 through 231-06 may now bind to this SHA for GATE-01 (local cohort execution), GATE-02 (GitHub proof), and GATE-03 (ship-window resolution) work.

## Self-Check: PASSED

- `scripts/ci/verify_recut_candidate.mjs` exists on disk.
- `.planning/phases/231-exact-sha-release-gate-proof/231-ROLLBACK-POINT.json` exists on disk.
- Commits `354fe92a`, `8a3bdd60`, `0cb6c16a` found in `git log --oneline --all`.
- Re-ran all task-level `<acceptance_criteria>` and the plan-level `<verification>` block: all pass (see plan verify commands above under Accomplishments).

---
*Phase: 231-exact-sha-release-gate-proof*
*Completed: 2026-09-15*
