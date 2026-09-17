---
phase: 232-bounded-hygiene-release-handoff
plan: 09
subsystem: infra
tags: [git, release, ci, node, verifier]

requires:
  - phase: 232-bounded-hygiene-release-handoff (plan 08)
    provides: "the bounded hygiene cleanup and the maintainer-aligned .tool-versions this re-cut's merge parents both already carry"
provides:
  - "A re-cut merge (3f42158d5cd3ffb7134685ae2856074cf544e008, parents 47c75bfd milestone-tip + d30fc25d origin/main) plus its two re-applied post-merge commits, tip c1397fe9127a9b4b2b1d3a0758d57879b14f4604, pushed to the NEW remote branch integration/v1.62-candidate-recut -- the published integration/v1.62-candidate ref is untouched"
  - "scripts/ci/verify_recut_candidate.mjs --require-union-hunks: a generic, live-derived co-touched-path losslessness proof (blob identity for single-touched paths, hunk union for co-touched paths), replacing the disjoint-union assumption that no longer holds"
  - "scripts/ci/verify_recut_candidate.mjs's supersedes.artifact check generalized from a hardcoded '230-ROLLBACK-POINT.json' literal to a <phase-number>-ROLLBACK-POINT.json pattern"
  - "232-ROLLBACK-POINT.json: the committed, schema-compliant rollback record for the re-cut, with both local-only rollback refs and a proven restore invocation"
affects: [232-10, 232-11]

actuals:
  tokens: 4592
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "A re-cut built via a discarded scratch clone (git clone --no-hardlinks, merge + cherry-picks performed there, resulting objects fetched back by SHA, scratch directory removed) rather than checking out the target branch in the working repository -- keeps the executing agent's own HEAD and working tree completely undisturbed during construction."
    - "candidate_object in the RECUT_RECORD_FIELDS schema is the MERGE commit itself (the 2-parent shape-gate target), never the branch tip after post-merge commits; candidate_ref (the branch name) is the separate field used to resolve the live tip for the toolchain-pin check. Conflating the two produces a misleading 'observed parent count=1' shape-gate failure."
    - "A generalized co-touched-path losslessness check: derive the merge base and both sides' changed-path sets LIVE via git plumbing every time (never a stored/hardcoded value); partition into single-touched (checked by whole-blob identity -- this is what catches a same-file-count silent revert) and co-touched (checked by hunk union -- every line either side added relative to the merge base must appear in the result, since whole-blob identity to either parent is structurally impossible for a genuine union)."
    - "When a re-cut is a genuine supersession (built fresh from two parents) rather than an extension of the branch being replaced, the old tip is provably not an ancestor of the new tip, and updating the published ref requires a non-fast-forward. If a plan's checkpoint authorizes only the published ref and prohibits force-push in the same breath, that combination is unexecutable for a fresh-supersession re-cut -- pushing the new tip to a NEW branch name resolves the contradiction without relaxing the prohibition."

key-files:
  created:
    - .planning/phases/232-bounded-hygiene-release-handoff/232-ROLLBACK-POINT.json
  modified:
    - scripts/ci/verify_recut_candidate.mjs

key-decisions:
  - "Maintainer's checkpoint decision (verbatim, relayed by the orchestrator, not a paraphrase): \"B: New branch, leave published ref alone (Recommended) — Push c1397fe9 to a new branch name (e.g. integration/v1.62-candidate-recut) and open the integration PR from it. No force-push, nothing destroyed, the existing published ref and its history stay exactly as they are. Resolves the plan's internal contradiction without needing to relax any prohibition.\" The orchestrator performed the push (git push origin c1397fe9127a9b4b2b1d3a0758d57879b14f4604:refs/heads/integration/v1.62-candidate-recut) under this authorization; I did not perform the push myself and did not push anything in this plan."
  - "The three Task 3 in-flight deviations (see Deviations) were each fixed inline rather than deferred: candidate_object corrected to the merge commit before any commit was made; the hardcoded supersession-artifact literal generalized with both a positive and a negative fixture control; the plan's own unrunnable literal one-merge-point verify command replaced with the scoped computation the file's own exactly_one_new_commit gate already uses for the identical reason."

requirements-completed: [REL-04]

coverage:
  - id: D1
    description: "Local rollback refs (rollback/232-pre-recut-milestone, rollback/232-pre-recut-candidate) created before any other ref write, plus a live re-measurement of the merge base, changed-path counts, co-touched set, ancestry, and version values on each side -- nothing transcribed from CONTEXT.md/RESEARCH.md."
    requirement: REL-04
    verification:
      - kind: other
        ref: "git rev-parse --verify rollback/232-pre-recut-milestone && git rev-parse --verify rollback/232-pre-recut-candidate"
        status: pass
      - kind: other
        ref: "git ls-remote --heads origin 'rollback/*' | wc -l -> 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "scripts/ci/verify_recut_candidate.mjs --require-union-hunks: generalized losslessness proof handling any number of co-touched paths via live-derived blob-identity (single-touched) plus hunk-union (co-touched) checks, built via strict RED-GREEN TDD."
    requirement: REL-04
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/verify_recut_candidate.mjs (7/7 pass, including a top-level test named for the hunk-union rule)"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_recut_candidate.mjs --fixtures --expected-repository szTheory/accrue -> PASS (fixtures: ..., union-hunks)"
        status: pass
      - kind: other
        ref: "grep -c 'accrue_portal/mix.exs' scripts/ci/verify_recut_candidate.mjs -> 0 (no co-touched path ever hardcoded by name)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The re-cut itself: merge(milestone-tip, origin/main) plus the two re-applied 230-05 post-merge commits, proven lossless (zero drift across 447 inspected paths, 7 genuinely co-touched) and correctly shaped (one merge point, 3 new commits matching the declared count, origin/main an ancestor, manifest+mix.exs at 1.5.1 everywhere) via full strict verification including --require-union-hunks."
    requirement: REL-04
    verification:
      - kind: other
        ref: "node scripts/ci/verify_recut_candidate.mjs --repo . --record .../232-ROLLBACK-POINT.json --expected-repository szTheory/accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain --require-supersession --require-union-hunks -> PASS, losslessness sweep inspected=447 co_touched=7 drifted=0"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_release_manifest_alignment.sh (run against the new tip's content via a scratch dir populated from git show <sha>:path) -> OK, 1.5.1 aligned, D-42's sibling-dependency check survives the re-cut"
        status: pass
      - kind: other
        ref: "git rev-list --merges c1397fe9... ^47c75bfd... ^d30fc25d... | wc -l -> 1; git rev-list --count c1397fe9... ^47c75bfd... ^d30fc25d... -> 3"
        status: pass
    human_judgment: false
  - id: D4
    description: "Checkpoint: the maintainer authorized publishing the re-cut. Given the non-fast-forward finding (Deviations), the maintainer chose Option B -- push the re-cut tip to a NEW remote branch (integration/v1.62-candidate-recut) rather than moving the published integration/v1.62-candidate ref -- resolving the plan's internal contradiction (Option A required a force-push the plan itself prohibits) without relaxing any prohibition."
    requirement: REL-04
    verification:
      - kind: other
        ref: "git ls-remote origin 'refs/heads/integration/v1.62-candidate*' -> integration/v1.62-candidate still f524f2a6 (unchanged); integration/v1.62-candidate-recut now c1397fe9 (new)"
        status: pass
    human_judgment: true
    rationale: "A remote ref write on a published branch is, by design, gated behind explicit maintainer authorization -- not something an executor decides or automates. The maintainer's verbatim reply is recorded below; the resulting remote state was independently verified (by both the orchestrator and by me, post-hoc) rather than assumed."

duration: ~25min of active task execution (Tasks 1-3 commits span 09:34-09:54 ET); additional elapsed time was spent paused at the checkpoint awaiting the maintainer's authorization, not executing
completed: 2026-09-17
status: complete
---

# Phase 232 Plan 09: Re-cut the v1.62 integration candidate Summary

**Re-cut `integration/v1.62-candidate` as a clean union of the milestone and published-release lines via merge+two-cherry-picks, proved lossless by a newly-generalized live blob-identity/hunk-union check (447 inspected, 7 co-touched, 0 drifted), then published to a new branch (`integration/v1.62-candidate-recut`) on the maintainer's explicit authorization after the published branch turned out to require an off-limits force-push.**

## Performance

- **Duration:** ~25 min of active task execution (commit timestamps `dca63fdd` 09:34:16 → `2b8d9d2d` 09:54:54 ET); the plan also paused twice at a checkpoint awaiting orchestrator/maintainer input, which is not counted as execution time.
- **Tasks:** 3 (plus the checkpoint, resolved by the maintainer's explicit authorization, relayed verbatim by the orchestrator)
- **Commits:** 5 (4 task commits + this metadata commit)
- **Files modified:** 2 (`232-ROLLBACK-POINT.json` created, `scripts/ci/verify_recut_candidate.mjs` modified)

## Accomplishments

- Created both local rollback refs (`rollback/232-pre-recut-milestone` @ `47c75bfd`, `rollback/232-pre-recut-candidate` @ `f524f2a6`) **before any other ref write**, and re-measured every fact the re-cut depends on live rather than trusting CONTEXT.md/RESEARCH.md: merge base `8a3bdd60`, per-side changed-path counts (112 milestone / 46 candidate), a 2-path co-touched set between milestone and the *old* candidate (`.tool-versions` — byte-identical, non-conflicting; `accrue_portal/mix.exs` — genuinely divergent), full ancestry and version-value confirmation, and a clean `git merge-tree --write-tree` probe.
- Generalized `scripts/ci/verify_recut_candidate.mjs`'s losslessness proof via strict RED→GREEN TDD: added `--require-union-hunks`, which derives the merge base and both sides' changed-path sets **live** every run (never a hardcoded value), checks single-touched paths by whole-blob identity (catches a same-file-count silent revert) and co-touched paths by hunk union (every line either side added must survive into the result — whole-blob identity is structurally impossible for a genuine union). No co-touched path is ever named literally in the verifier's own source.
- Performed the actual re-cut: merged `origin/main` (the published 1.5.1 release state) into the milestone tip via a scratch clone (discarded afterward), first parent = milestone, second parent = origin/main, then cherry-picked the two declared 230-05 post-merge commits in order — zero conflicts on either cherry-pick. New tip `c1397fe9127a9b4b2b1d3a0758d57879b14f4604`. Full strict verification (all six gates, including the new `--require-union-hunks`) passes at the new SHA: **inspected=447, co_touched=7, drifted=0**. Three corroborating fail-closed assertions all pass: `origin/main` is an ancestor of the new tip; the manifest and all three `mix.exs` read `1.5.1`; the new tip has exactly 3 commits relative to both pre-re-cut parents (1 merge + 2 cherry-picks, no duplicated commit). `scripts/ci/verify_release_manifest_alignment.sh`, run against the new tip's content, confirms D-42's sibling-dependency assertion survived the re-cut unchanged.
- **Discovered and reported, rather than worked around, a genuine plan defect:** updating the published `integration/v1.62-candidate` branch to the new tip is **not a fast-forward** (`f524f2a6` is provably not an ancestor of `c1397fe9`, because this re-cut rebuilds fresh from `(milestone, origin/main)` rather than extending the old candidate's own history) — so the plan's Option A ("authorize the update") was unexecutable as written without relaxing the force-push prohibition. Stopped at the checkpoint and presented this finding plainly, per the plan's own instruction and the dispatch's hard limit, rather than guessing or forcing.
- **Checkpoint resolved by the maintainer**, verbatim (relayed by the orchestrator, not my paraphrase and not another agent's words):

  > "B: New branch, leave published ref alone (Recommended) — Push c1397fe9 to a new branch name (e.g. integration/v1.62-candidate-recut) and open the integration PR from it. No force-push, nothing destroyed, the existing published ref and its history stay exactly as they are. Resolves the plan's internal contradiction without needing to relax any prohibition."

  The orchestrator performed `git push origin c1397fe9127a9b4b2b1d3a0758d57879b14f4604:refs/heads/integration/v1.62-candidate-recut` under this authorization (result: `* [new branch]`, exit 0). **I did not perform this push myself** — it was executed by the orchestrator on the maintainer's explicit authorization, outside my own tool calls, consistent with the dispatch's hard limit that only local work (up to and including presenting the checkpoint) was mine to do. Post-push remote state, independently re-verified by me: `integration/v1.62-candidate` still resolves to `f524f2a6` (**unchanged**); `integration/v1.62-candidate-recut` now resolves to `c1397fe9` (new). `refs/heads/rollback/*` on origin: still 0. No force-push occurred; the published ref was not moved, deleted, or rewritten; no tag was moved; no PR was merged; nothing was published to Hex.

## Task Commits

1. **Task 1: Rollback refs and a live re-measurement of the two lines, before any ref write** — `dca63fdd` (feat)
2. **Task 2: Generalize the losslessness proof to handle co-touched paths by hunk union** (tdd="true")
   - `91e83ad6` (test) — RED: fixtures calling not-yet-defined `collectLosslessnessProof`/`applyRequireUnionHunks`, confirmed failing (`ReferenceError`, 1 fail / 5 pass) before commit
   - `dee6be37` (feat) — GREEN: implementation + CLI wiring, confirmed 7/7 pass before commit
3. **Task 3: Perform the re-cut and prove it** — `2b8d9d2d` (feat)
4. **Checkpoint follow-through:** the remote push itself (`integration/v1.62-candidate-recut`) was performed by the orchestrator on the maintainer's authorization, not by me, and is not one of my commits.

**Plan metadata:** this commit (SUMMARY + STATE + ROADMAP + REQUIREMENTS).

## Files Created/Modified

- `.planning/phases/232-bounded-hygiene-release-handoff/232-ROLLBACK-POINT.json` — created in Task 1 (pre-re-cut capture: rollback refs, live re-measurement), then rewritten in Task 3 to the full `RECUT_RECORD_FIELDS` schema once the actual re-cut SHA existed (`candidate_object` = the merge commit `3f42158d5cd3ffb7134685ae2856074cf544e008`; `supersedes.artifact` = `"231-ROLLBACK-POINT.json"`, the artifact that actually recorded the superseded candidate `f524f2a6`).
- `scripts/ci/verify_recut_candidate.mjs` — added `collectLosslessnessProof`/`applyRequireUnionHunks` and the `--require-union-hunks` CLI flag (Task 2); generalized the `supersedes.artifact` schema check from a hardcoded literal to a `<phase-number>-ROLLBACK-POINT.json` pattern, with new positive/negative fixture controls (Task 3, deviation).

## Decisions Made

See `key-decisions` in frontmatter. The load-bearing one is the maintainer's verbatim checkpoint reply (Option B), quoted in full above and in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, caught before any commit] `candidate_object` must be the merge commit, not the branch tip**
- **Found during:** Task 3
- **Issue:** My first draft of the finalized `232-ROLLBACK-POINT.json` set `candidate_object` to `c1397fe9` (the branch tip, after both post-merge cherry-picks). Running the plan's own strict verification against it failed immediately: `recut candidate verify: FAIL: recut candidate shape check failed: observed parent count=1 (expected 2)` — because `collectRecutGates`'s shape gate inspects `candidate_object`'s own immediate parents, and a single-parent cherry-pick commit will never have 2 parents.
- **Fix:** Corrected `candidate_object` to `3f42158d5cd3ffb7134685ae2856074cf544e008` (the actual merge commit, parents `47c75bfd` + `d30fc25d`) and `restore_argv` to revert that same SHA, matching 231-ROLLBACK-POINT.json's own precedent exactly (its `candidate_object` is likewise the merge, not the tip; `candidate_ref` is the separate field used to resolve the live tip for the toolchain-pin check).
- **Files modified:** `.planning/phases/232-bounded-hygiene-release-handoff/232-ROLLBACK-POINT.json`
- **Verification:** Full strict verification re-run and passed cleanly after the fix (see `## Accomplishments`).
- **Committed in:** `2b8d9d2d` (the bug was caught and fixed before any commit was made — no separate "broken" commit exists)

**2. [Rule 3 - Blocking] `validateRecutRecord`'s `supersedes.artifact` check hardcoded `"230-ROLLBACK-POINT.json"` as a literal**
- **Found during:** Task 3
- **Issue:** The unmodified check was `if (record.supersedes.artifact !== "230-ROLLBACK-POINT.json") fail(...)`. This is correct only for 231's own act of superseding 230's candidate; it would wrongly reject `232-ROLLBACK-POINT.json`'s true value, `"231-ROLLBACK-POINT.json"` (the artifact that actually recorded the candidate `f524f2a6` this phase supersedes), blocking Task 3's own `--require-supersession` gate from ever passing.
- **Fix:** Generalized the check to a `/^[0-9]+-ROLLBACK-POINT\.json$/` pattern. Added a positive control (a differently-numbered artifact name, `"231-ROLLBACK-POINT.json"`) and a negative control (a malformed filename) to the existing schema-controls fixture scenario in `verify_recut_candidate.mjs`.
- **Files modified:** `scripts/ci/verify_recut_candidate.mjs`
- **Verification:** `node --test --test-reporter=tap scripts/ci/verify_recut_candidate.mjs` → 7/7 pass (unchanged count — the new assertions extend an existing scenario, not a new top-level test). Full `scripts/ci/*.mjs` suite re-confirmed 453/453.
- **Committed in:** `2b8d9d2d`

**3. [Rule 1 - Bug] The plan's own literal Task 3 verify command 2 (`git log --merges <merge_base>..HEAD`) is unrunnable/misleading as written**
- **Found during:** Task 3
- **Issue:** `merge_base` is not a field in the finalized `RECUT_RECORD_FIELDS`-compliant JSON (a literal re-run of the command as written would `KeyError` in the Python substitution step), and bare `HEAD` was never the candidate at any point in this task — I built the re-cut in a discarded scratch clone and only ever moved the local `integration/v1.62-candidate` ref via `git update-ref`, so `HEAD` stayed on `gsd/milestone-v1.62-release-integration-hygiene` throughout. I confirmed this concretely: running a variant of the literal command (substituting `candidate_object` for the nonexistent `merge_base` field, since the real field doesn't exist) returned 36 unrelated merge SHAs from `origin/main`'s own PR-merge history against my current milestone branch — meaningless for checking the candidate's own shape.
- **Fix:** Substituted the scoped, correct computation the plan's own three corroborating assertions already use, and the same one `collectRecutGates`'s `exactly_one_new_commit` gate uses for the identical reason (per its own D-30 comment): `git rev-list --merges <new-tip> ^<first_parent> ^<second_parent>`, which counts merge commits only among the commits this re-cut newly introduced. Result: `1`.
- **Files modified:** none (verification-methodology substitution only)
- **Verification:** Command ran and returned `1`, matching the shape contract's own single-merge-point invariant; corroborated by the identical-in-spirit `exactly_one_new_commit` gate inside `--require-shape`, which also passed.
- **Committed in:** N/A (verification methodology, not a code/artifact change)

**4. [Not a deviation from my own work, but a first-class plan defect this plan surfaced] The plan's checkpoint Option A was unexecutable as written**
- **Found during:** the checkpoint (after Task 3)
- **Issue:** The plan's checkpoint presents "Authorize the update [to the published branch]" as the default option (A), and separately prohibits force-push in its own `<prohibitions>` list. But this re-cut is a genuine fresh supersession (built from `(milestone, origin/main)`, not extending the old candidate's own commit chain), so `f524f2a6` (the old published tip) is provably not an ancestor of `c1397fe9` (the new tip) — `git merge-base --is-ancestor origin/integration/v1.62-candidate refs/heads/integration/v1.62-candidate` returns `1` (false). Updating the published branch to the new tip would therefore require a force-push, which the plan itself prohibits in the same breath it offers Option A as the default. This is an internal contradiction in the plan, not a mistake in my own execution.
- **Fix:** Reported the finding plainly at the checkpoint rather than guessing or forcing (per the plan's own "if not a fast-forward, stop and present that fact" instruction and this dispatch's hard limit). The maintainer resolved it by selecting Option B — publish to a new branch name instead, leaving the published ref, the force-push prohibition, and the plan's other prohibitions all intact.
- **Carry-forward for 232-10/232-11:** **any downstream step that assumes `integration/v1.62-candidate` points at the re-cut is wrong.** The re-cut lives at `integration/v1.62-candidate-recut` (`c1397fe9127a9b4b2b1d3a0758d57879b14f4604`). 232-11's integration PR must be opened from `integration/v1.62-candidate-recut`, not from `integration/v1.62-candidate`. The original `integration/v1.62-candidate` still resolves to `f524f2a6` and was never moved.

---

**Total deviations:** 4 (3 auto-fixed per Rules 1/3 in my own Task 3 work; 1 first-class plan defect discovered and correctly escalated to the maintainer rather than worked around). **Impact:** None of the three auto-fixes changed the re-cut's semantics or weakened any check — they made the plan's own literal instructions/schema match what the plan's design already required. The plan-defect finding materially changes downstream references (232-10/232-11 must target `integration/v1.62-candidate-recut`, not the originally-named branch) and is called out explicitly above and in `## Next Phase Readiness` so it is not silently lost.

## Issues Encountered

None beyond the deviations above, all resolved within this plan's own commits or by the maintainer's explicit checkpoint decision.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **The re-cut candidate lives at branch `integration/v1.62-candidate-recut` (`c1397fe9127a9b4b2b1d3a0758d57879b14f4604`), NOT at `integration/v1.62-candidate` (still `f524f2a6`, unchanged).** 232-10 and 232-11 (and any other downstream reference to "the re-cut candidate branch") must target `integration/v1.62-candidate-recut` explicitly. This is the single most important fact to carry forward from this plan.
- Both local rollback refs remain in place and local-only: `rollback/232-pre-recut-milestone` → `47c75bfd9975063e6804fb636d9f5c3bf4d156bf`, `rollback/232-pre-recut-candidate` → `f524f2a6b16d3576829632ab6fa77d24b718e6f7`. Neither exists on the remote (`git ls-remote --heads origin 'rollback/*'` → 0).
- The committed restore invocation, should the re-cut merge need to be undone once it is live on a branch that gets integrated: `git revert -m 1 --no-edit 3f42158d5cd3ffb7134685ae2856074cf544e008`.
- `scripts/ci/verify_recut_candidate.mjs --require-union-hunks` is now available for any future re-cut with co-touched paths (this was previously impossible — the check assumed a disjoint union).
- No blockers beyond the branch-name carry-forward noted above. `git status --porcelain` shows the same 3 already-classified untracked paths (`.planning/milestone.lock`, `.planning/state.json`, `.planning/v1.61-v1.61-MILESTONE-AUDIT.md`) this plan started with — unaffected by this plan's work.

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-17*

## Self-Check: PASSED

- `.planning/phases/232-bounded-hygiene-release-handoff/232-ROLLBACK-POINT.json` exists on disk (`[ -f ]` confirmed) and validates against `validateRecutRecord`.
- All 4 task commit hashes (`dca63fdd`, `91e83ad6`, `dee6be37`, `2b8d9d2d`) verified present via `git log --oneline --all`.
- Re-ran the plan-level `<verification>` block at final HEAD (`2b8d9d2d`):
  - Strict verification at the new SHA exits 0 with `drifted=0` (re-confirmed).
  - `git rev-list --merges c1397fe9... ^47c75bfd... ^d30fc25d... | wc -l` → `1`.
  - `bash scripts/ci/verify_release_manifest_alignment.sh` against the new tip's content → `OK`.
  - Both rollback refs resolve locally; neither exists on the remote.
  - Maintainer authorization quoted verbatim above, before any remote-ref-related fact in this SUMMARY.
- Mandatory exit verification, re-run serially at final HEAD:
  - `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` → PASS, exit 0.
  - `env -u NODE_TEST_CONTEXT node --test --test-reporter=tap $(git ls-files 'scripts/ci/*.mjs')` → `# tests 453`, `# pass 453`, `# fail 0`, `# skipped 0`.
  - `git status --porcelain` → exactly the 3 already-classified untracked paths.
  - Zero NUL bytes confirmed in `scripts/ci/verify_recut_candidate.mjs`.
  - Remote state independently re-verified: `integration/v1.62-candidate` → `f524f2a6` (unchanged); `integration/v1.62-candidate-recut` → `c1397fe9` (new); `refs/heads/rollback/*` on origin → 0.
