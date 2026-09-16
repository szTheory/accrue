---
phase: quick-260916-gda
plan: 01
subsystem: ci
tags: [ci, verification, node-test, tap, ci-scripts, planning-docs]

requires:
  - phase: 231-exact-sha-release-gate-proof
    provides: window-disposition collector/verifier, verify_recut_candidate.mjs, 231-REVIEW.md code-review findings
provides:
  - Restored STATE.md standing sections (Deferred Items, Post-v1.48 Pause Rule, Historical Research Assets)
  - Two previously-red merge-blocking CI contracts now green (verify_roadmap_hygiene.sh, verify_v1_17_friction_research_contract.sh)
  - Regenerated 229-UAT.md, plus previously-uncommitted 230-UAT.md/231-UAT.md needed for --all-since 229 to pass on a fresh checkout
  - Reworded GATE-01/GATE-02 in REQUIREMENTS.md to describe honest per-lane gate proof instead of an implied green/passing aggregate
  - CR-01 fixed: disposition "fixed" now requires state "proved" at both the collector and verifier layer
  - WR-01 fixed: verify_recut_candidate.mjs --expected-repository is checked against the live git origin remote identity
  - phase229_gap_closure.test.mjs's runIsolatedNodeTest now forces --test-reporter=tap so its TAP assertions pass under Node 22+
  - Repaired render_window_dispositions.mjs test fixture that CR-01 correctly broke (rows 3/4 were a schema-invalid fixed/non-proved pairing)
affects: [232-bounded-hygiene, release-integration-hygiene-milestone-closeout]

actuals:
  tokens: 12700
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Cross-field schema invariant enforced at both collection time (validateWindowRow) and verification time (a sibling assertFixedRowsProved next to assertWaiverCompleteness), so a hand-edited committed record that never went through the collector is still caught."
    - "Live identity checks (git remote get-url origin) preferred over comparing a CLI flag to a field baked into the record itself, when the record has no such field and adding one would change a frozen schema."

key-files:
  created: []
  modified:
    - .planning/STATE.md
    - .planning/REQUIREMENTS.md
    - .planning/phases/229-repository-truth-recovery-safety/229-UAT.md
    - .planning/phases/230-reviewable-history-integration/230-UAT.md
    - .planning/phases/231-exact-sha-release-gate-proof/231-UAT.md
    - scripts/ci/collect_window_dispositions.mjs
    - scripts/ci/verify_window_dispositions.mjs
    - scripts/ci/verify_recut_candidate.mjs
    - scripts/ci/phase229_gap_closure.test.mjs
    - scripts/ci/render_window_dispositions.mjs

key-decisions:
  - "Restored STATE.md's three standing sections verbatim from commit f7889d99 rather than minimally patching to the CI grep needles, per the plan's explicit instruction and to avoid a second round of drift."
  - "Committed 230-UAT.md and 231-UAT.md (previously generated on disk but never committed) alongside the 229-UAT.md regeneration, because verify_executable_uat_contract.mjs --all-since 229 fails on a fresh checkout without them (Rule 2 — missing critical functionality for a merge-blocking contract the plan's own verify block depends on)."
  - "Tied the new assertFixedRowsProved strict check to the --require-waiver-completeness flag (same invocation site as assertWaiverCompleteness), per the plan's explicit placement instruction, rather than adding a new standalone flag."
  - "For WR-01, derived live repository identity from git remote get-url origin (handling both https://github.com/OWNER/NAME.git and git@github.com:OWNER/NAME.git forms) instead of adding a repository field to the frozen 231-ROLLBACK-POINT.json schema."
  - "When CR-01 broke render_window_dispositions.mjs's own test fixture (rows 3/4 were a schema-invalid fixed/non-proved pairing that had never been caught before), fixed the test data rather than weakening CR-01 — the invariant was correct, the fixture was always wrong."
  - "Kept bucketOf's now-unreachable failed/not_run branches as defensive fail-safety rather than deleting them, and did not re-render the committed 231-WINDOW-DISPOSITIONS.md (that artifact is frozen phase-231 evidence, out of scope for this quick task); documented the reachability gap as a Phase 232 deferred item instead."

requirements-completed: [QT-260916-GDA]

coverage:
  - id: D1
    description: "Restore STATE.md standing sections (Deferred Items, Post-v1.48 Pause Rule, Historical Research Assets) so verify_roadmap_hygiene.sh and verify_v1_17_friction_research_contract.sh exit 0"
    requirement: QT-260916-GDA
    verification:
      - kind: other
        ref: "bash scripts/ci/verify_roadmap_hygiene.sh"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_v1_17_friction_research_contract.sh"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_stable_core_posture.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Regenerate 229-UAT.md via the script's own writer (never hand-edited) and commit the previously-missing 230-UAT.md/231-UAT.md so --all-since 229 passes without --write"
    requirement: QT-260916-GDA
    verification:
      - kind: other
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --self-test"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --all-since 229"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reword GATE-01/GATE-02 in REQUIREMENTS.md to describe honest per-lane gate proof (D-29) without changing IDs, completion marks, or coverage rows"
    requirement: QT-260916-GDA
    verification:
      - kind: other
        ref: "git diff .planning/REQUIREMENTS.md (manual inspection: only GATE-01/GATE-02 body text changed)"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_stable_core_posture.sh"
        status: pass
    human_judgment: false
  - id: D4
    description: "CR-01: disposition fixed requires state proved, enforced at both collector and verifier layers with negative controls, zero changes to committed evidence"
    requirement: QT-260916-GDA
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_window_dispositions.mjs — 'validateWindowRow rejects disposition fixed paired with any state other than proved (CR-01)'"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/verify_window_dispositions.mjs — 'window dispositions fixtures pass every negative control' (includes 10a: assertFixedRowsProved)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_window_dispositions.mjs --repo . --records .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json --rendered .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism"
        status: pass
    human_judgment: false
  - id: D5
    description: "WR-01/Part A: verify_recut_candidate.mjs --expected-repository checked against live origin remote identity; phase229_gap_closure.test.mjs's runIsolatedNodeTest emits TAP"
    requirement: QT-260916-GDA
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/phase229_gap_closure.test.mjs — '# fail 0'"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/verify_recut_candidate.mjs — 'recut candidate fixtures pass every negative control' (includes scenario 9a)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_recut_candidate.mjs --repo . --expected-repository szTheory/accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_recut_candidate.mjs --repo . --expected-repository someone-else/not-accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain (expected non-zero exit)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Repair render_window_dispositions.mjs's own test fixture, which CR-01 correctly broke (rows 3/4 were the exact schema-invalid disposition-fixed/state-not-proved pairing CR-01 now bans); keep the ordering assertion load-bearing; document bucketOf's now-unreachable branches as defensive-only; defer the waived-rows-bucket-by-state design question to Phase 232"
    requirement: QT-260916-GDA
    verification:
      - kind: unit
        ref: "node --test scripts/ci/render_window_dispositions.mjs — 9/9 pass, including 'leads with waived, then failed, then skipped/advisory/non_run, then fixed collapsed last'"
        status: pass
      - kind: integration
        ref: "node --test scripts/ci/collect_window_dispositions.mjs && node --test scripts/ci/render_window_dispositions.mjs && node --test scripts/ci/verify_window_dispositions.mjs && node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism (full CI triad, ci.yml:222-226)"
        status: pass
    human_judgment: false

duration: 65min
completed: 2026-09-16
status: complete
---

# Quick Task 260916-gda: Close Phase 231 loose ends Summary

**Restored two skeletonized STATE.md standing sections (closing two red merge-blocking CI contracts), reworded GATE-01/GATE-02 for honest per-lane proof, closed the CR-01 window-disposition schema hole and the WR-01 vacuous-flag hole from Phase 231's code review, and fixed a Node 22 TAP-reporter regression in the Phase-229 gap-closure suite.**

## Performance

- **Duration:** ~65 min
- **Started:** 2026-09-16T15:XX:XXZ (session start)
- **Completed:** 2026-09-16T16:XX:XXZ (post-coordinator-review fix)
- **Tasks:** 3 (plus 1 coordinator-flagged regression fix)
- **Files modified:** 10 (across 5 commits)

## Accomplishments

- `bash scripts/ci/verify_roadmap_hygiene.sh` and `bash scripts/ci/verify_v1_17_friction_research_contract.sh` now exit 0 (both exited 1 before this task) — STATE.md's `## Deferred Items`, `## Post-v1.48 Pause Rule`, and `### Historical Research Assets` sections were restored verbatim from commit `f7889d99`, additively, with no existing line removed or reordered.
- `229-UAT.md` regenerated via `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229 --write` (never hand-edited); the previously-uncommitted `230-UAT.md`/`231-UAT.md` companions were also committed, since the `--all-since 229` contract fails on a fresh checkout without them.
- `GATE-01`/`GATE-02` in `.planning/REQUIREMENTS.md` reworded to describe honest, re-verifiable, per-lane gate proof (recorded argv/exit-code evidence, closed `proved`/`failed`/`skipped`/`advisory`/`non_run` lexicon, no aggregate boolean) rather than an implied green/passing aggregate — IDs, `- [x]` marks, and coverage-table rows left untouched.
- CR-01 closed: a ship-window row claiming `disposition: "fixed"` while its `state` is anything other than `"proved"` is now rejected by both `validateWindowRow` (collection time) and a new `assertFixedRowsProved` strict check (verifier time, independent of the collector, catching hand-edited records) — with negative controls in both files' self-tests. Zero changes to the committed `231-WINDOW-DISPOSITIONS.json`/`.md` or `.planning/WINDOWS.md`.
- WR-01 closed: `verify_recut_candidate.mjs --expected-repository` is now checked against the live `git remote get-url origin` identity (handling both `https://github.com/OWNER/NAME.git` and `git@github.com:OWNER/NAME.git` forms), failing closed on a mismatch or an unresolvable origin, with `--fixtures` behavior unaffected.
- `phase229_gap_closure.test.mjs`'s `runIsolatedNodeTest` now spawns its child with `--test-reporter=tap`, fixing two previously-failing TAP-format assertions under Node 22+'s spec-reporter default — the gap-closure suite now reports `# fail 0` (was `# fail 2`).
- **Post-hoc coordinator review** caught that CR-01 correctly broke a pre-existing schema-invalid test fixture in `render_window_dispositions.mjs` (the third member of the window-dispositions CI triad, which the plan's own verify block did not cover). Fixed the fixture (not the invariant), documented `bucketOf`'s two branches that CR-01 makes unreachable as defensive-only, and recorded a Phase 232 deferred item about whether waived rows should bucket by their own state.

## Task Commits

Each task was committed atomically:

1. **Task 1: Restore STATE.md standing sections, regenerate 229-UAT.md, reword GATE-01/GATE-02** - `06a7c863` (docs)
2. **Task 2: Enforce the CR-01 invariant** - `398baee7` (fix, tdd)
3. (unplanned, Rule 2) **Commit missing 230-UAT.md/231-UAT.md** - `6a03ea6e` (docs)
4. **Task 3: Fix isolated-test TAP reporter and make --expected-repository non-vacuous** - `df6847b8` (fix, tdd)
5. (coordinator-flagged regression fix, Rule 1) **Repair render_window_dispositions.mjs fixture broken by CR-01** - `f5b6d390` (fix)

No separate plan-metadata commit — the orchestrator handles the docs commit for PLAN.md/SUMMARY.md per this quick task's constraints.

## Files Created/Modified

- `.planning/STATE.md` - Restored `## Deferred Items`, `## Post-v1.48 Pause Rule`, `### Historical Research Assets` (additive only)
- `.planning/REQUIREMENTS.md` - Reworded GATE-01/GATE-02 body text
- `.planning/phases/229-repository-truth-recovery-safety/229-UAT.md` - Regenerated timestamps via `--write`
- `.planning/phases/230-reviewable-history-integration/230-UAT.md` - Committed (previously generated on disk, untracked)
- `.planning/phases/231-exact-sha-release-gate-proof/231-UAT.md` - Committed (previously generated on disk, untracked)
- `scripts/ci/collect_window_dispositions.mjs` - CR-01 `validateWindowRow` invariant + negative/positive test controls
- `scripts/ci/verify_window_dispositions.mjs` - CR-01 `assertFixedRowsProved` strict check + negative/positive test controls
- `scripts/ci/verify_recut_candidate.mjs` - WR-01 `assertExpectedRepositoryIdentity` live-identity check + test controls
- `scripts/ci/phase229_gap_closure.test.mjs` - `runIsolatedNodeTest` now passes `--test-reporter=tap`
- `scripts/ci/render_window_dispositions.mjs` - Repaired the schema-invalid test fixture CR-01 broke; documented `bucketOf`'s now-defensive-only branches

## Decisions Made

- Restored STATE.md's full standing sections verbatim from `f7889d99` rather than a minimal needle-patch, per the plan's explicit instruction, to avoid re-drifting on the next regen.
- Committed `230-UAT.md`/`231-UAT.md` even though they weren't in the plan's declared `files_modified` list, because `verify_executable_uat_contract.mjs --all-since 229` — one of Task 1's own required verification commands — fails on a fresh checkout without them (Rule 2: missing critical functionality for a merge-blocking contract).
- Placed `assertFixedRowsProved` under the same `--require-waiver-completeness` flag invocation as `assertWaiverCompleteness`, per the plan's explicit placement instruction, rather than introducing a new flag.
- For WR-01, compared live `git remote get-url origin` identity rather than adding a `repository` field to `RECUT_RECORD_FIELDS`/`231-ROLLBACK-POINT.json`'s frozen schema, per the plan's explicit constraint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Committed previously-untracked 230-UAT.md/231-UAT.md**
- **Found during:** Task 1 (verifying `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229`)
- **Issue:** The `--write` regeneration required by the plan also (re)generated `230-UAT.md` and `231-UAT.md` on disk as part of the same `--all-since 229` run, but these files had never been committed. Verified by temporarily removing them: `--all-since 229` then failed with "missing automated UAT artifact" for Phase 230. A fresh checkout of this branch would fail the same contract.
- **Fix:** Committed both files as-generated (byte-identical to the writer's output; diffed against the freshly-regenerated copies to confirm).
- **Files modified:** `.planning/phases/230-reviewable-history-integration/230-UAT.md`, `.planning/phases/231-exact-sha-release-gate-proof/231-UAT.md`
- **Verification:** `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229` exits 0 with the files present; re-confirmed by deleting and restoring them.
- **Committed in:** `6a03ea6e`

**2. [Rule 1 - Bug, coordinator-flagged] Repaired a schema-invalid test fixture in render_window_dispositions.mjs that CR-01 correctly broke**
- **Found during:** post-hoc coordinator review, after this task's own execution had already reported complete. The plan's `<verify>` block for Task 2 covered `collect_window_dispositions.mjs` and `verify_window_dispositions.mjs` but not the third member of the same CI triad, `render_window_dispositions.mjs` (`ci.yml:222-226`'s "Window dispositions triad units and fixture contract" step runs all three).
- **Issue:** `node --test --test-reporter=tap scripts/ci/render_window_dispositions.mjs` reported `# fail 1`. The test `"leads with waived, then failed, then skipped/advisory/non_run, then fixed collapsed last"` constructed rows 3 and 4 as `{disposition: "fixed", state: "failed"}` and `{disposition: "fixed", state: "skipped"}` — exactly the incoherent pairing CR-01 now bans at `validateWindowRow`, which `renderWindowDispositions` calls internally via `validateWindowDispositions`. The fixture was always schema-invalid; nothing had previously exercised full row validation from this test.
- **Fix:** Did NOT weaken CR-01. Replaced rows 3/4 with legal rows (an additional waived row with `state: "skipped"` and an additional fixed/proved row) so the test's real assertion — waived rows rendering before fixed rows, and intra-bucket id ordering — stayed load-bearing. The four-heading assertion was already vacuous (`sections` in `renderWindowDispositions` prints every bucket heading unconditionally, including "0 rows in this section." for empty ones), so it is unaffected by which buckets actually receive rows.
- **Design note (recorded, not fixed):** `ROW_DISPOSITIONS` is the closed `{fixed, waived}` set, and CR-01 forces every non-waived row to `state: "proved"`. That makes `bucketOf`'s `"failed"` and `"not_run"` branches unreachable for any row that has passed validation — a waived row always short-circuits to the `"waived"` bucket regardless of its own state, so a maintainer currently cannot distinguish a waived-but-failed row from a waived-but-merely-skipped one (the committed `231-WINDOW-DISPOSITIONS.md` has exactly this: row 3 is waived/non_run and row 10 is waived/failed, both rendering in the same "Waived" section). Added a comment at `bucketOf` documenting this as defensive-only fail-safety (kept, not deleted). **Deferred to Phase 232:** should waived rows bucket by their own state instead of collapsing into one "Waived" section? Not decided here — re-rendering `231-WINDOW-DISPOSITIONS.md` is out of scope for this quick task (it is frozen Phase-231 evidence).
- **Files modified:** `scripts/ci/render_window_dispositions.mjs`
- **Verification:** RED confirmed first (`node --test --test-reporter=tap scripts/ci/render_window_dispositions.mjs` → `# fail 1`); GREEN after (`# fail 0`, 9/9 pass). Full CI triad re-run exactly as `ci.yml` invokes it — see quoted output below.
- **Committed in:** `f5b6d390`

---

**Total deviations:** 2 auto-fixed (1 missing critical functionality, 1 bug — the second caught by coordinator review, not by this task's own verify block)
**Impact on plan:** Both necessary for the plan's stated CI contracts to actually pass on a fresh checkout / in CI. No scope creep — CR-01 itself was not weakened, and the committed disposition evidence was not touched.

### Full CI triad, re-run exactly as ci.yml invokes it (post-fix)

```
$ node --test scripts/ci/collect_window_dispositions.mjs && node --test scripts/ci/render_window_dispositions.mjs && node --test scripts/ci/verify_window_dispositions.mjs && node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism
...
ℹ tests 19
ℹ pass 19
ℹ fail 0
...
ℹ tests 9
ℹ pass 9
ℹ fail 0
...
ℹ tests 1
ℹ pass 1
ℹ fail 0
...
window dispositions fixtures: PASS
```

## Issues Encountered

None beyond the deviation above — all three tasks' RED→GREEN cycles (Tasks 2 and 3, both `tdd="true"`) confirmed failing negative controls before the production fix landed:
- Task 2: `node --test --test-reporter=tap scripts/ci/collect_window_dispositions.mjs` showed `# fail 1` before the `validateWindowRow` fix, `# fail 0` after.
- Task 3 Part A: `node --test --test-reporter=tap --test-name-pattern="CR-09|WR-02" scripts/ci/phase229_gap_closure.test.mjs` showed `# fail 2` before adding `--test-reporter=tap` to the spawned child, `# fail 0` after.
- Task 3 Part B: `node --test --test-reporter=tap scripts/ci/verify_recut_candidate.mjs` failed with `ReferenceError: assertExpectedRepositoryIdentity is not defined` before the function existed, passed after.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 12 commands in the plan's `<verification>` block, PLUS the third `render_window_dispositions.mjs` triad member CI actually runs (`ci.yml:222-226`), exit 0 (or non-zero as expected for the negative-repository case) as run from `gsd/milestone-v1.62-release-integration-hygiene` at HEAD.
- Two previously-red merge-blocking CI contracts (`verify_roadmap_hygiene.sh`, `verify_v1_17_friction_research_contract.sh`) are green again — Phase 232 (Bounded Hygiene) is unblocked from that angle.
- Both Phase 231 code-review findings (CR-01, WR-01) are closed with negative-test coverage; no known open findings remain from `231-REVIEW.md`.
- `git diff` scope across all five commits touches exactly the files declared in the plan (plus the two UAT companions and the one triad-fixture repair documented above as deviations) — no unrelated files modified.
- **Deferred to Phase 232:** whether `bucketOf` in `render_window_dispositions.mjs` should bucket waived rows by their own state (rather than collapsing every waived row into one "Waived" section), now that CR-01 has made the `"failed"`/`"not_run"` branches unreachable for non-waived rows. Re-rendering the committed `231-WINDOW-DISPOSITIONS.md` was explicitly out of scope for this quick task.

---
*Phase: quick-260916-gda*
*Completed: 2026-09-16*

## Self-Check: PASSED

All 10 claimed files found on disk; all 5 claimed commit hashes (`06a7c863`, `398baee7`, `6a03ea6e`, `df6847b8`, `f5b6d390`) found in `git log --oneline --all`.
