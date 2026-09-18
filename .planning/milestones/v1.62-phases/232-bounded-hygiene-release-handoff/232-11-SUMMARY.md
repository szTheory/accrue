---
phase: 232-bounded-hygiene-release-handoff
plan: 11
subsystem: infra
tags: [release, ci, node, verifier, pull-request]

requires:
  - phase: 232-bounded-hygiene-release-handoff (plan 10)
    provides: "232-WINDOW-DISPOSITIONS.json/.md at the re-cut SHA and the first real CI step verifying a committed window-disposition pair"
  - phase: 232-bounded-hygiene-release-handoff (plan 05)
    provides: "scripts/ci/verify_release_pr_readiness.sh and the archived 232-RELEASE-PR-DRYRUN.log"
provides:
  - "scripts/ci/verify_pr_body_contract.mjs -- a machine-checkable contract over the integration PR body (risk-first heading, provenance-versus-behavior sentence, inline rollback command, per-claim falsifiability, leak/density checks)"
  - "232-INTEGRATION-PR.md -- the committed source of truth for the integration pull-request body, passing the contract with all three strict flags"
affects: [232-11 (all three tasks run)]

actuals:
  tokens: 62000
  tasks: 2
  commits: 2
  plan_head_before: 32e4c1cf

tech-stack:
  added: []
  patterns:
    - "Reused collect_window_dispositions.mjs's UNSAFE_PATH_PATTERN verbatim (imported, not redefined) for the leak check, the same pattern collect_hygiene_dispositions.mjs already reuses -- exactly one of the two existing sanitization patterns, no third one defined."
    - "A claim line (a markdown bullet) is falsifiable if a code span or a markdown link appears on that line or the line immediately following it -- lets a long bullet wrap its prose onto one line and its evidence command onto the next without failing the check, while still catching a genuinely bare claim."
    - "The head SHA and head branch of a not-yet-final integration PR each get exactly one clearly-marked provenance line in the body, so a later re-cut is a two-line edit, not a body-wide find-and-replace."

key-files:
  created:
    - scripts/ci/verify_pr_body_contract.mjs
    - .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md

key-decisions:
  - "Task 2's body targets branch `integration/v1.62-candidate-recut` and head SHA `c1397fe9127a9b4b2b1d3a0758d57879b14f4604`, per the dispatch's corrected facts (232-09-SUMMARY.md's carry-forward): the originally-planned `integration/v1.62-candidate` branch still points at the OLD tip `f524f2a6` and is not the re-cut. Both values are deliberately confined to exactly one line each (the '**Head branch:**' line and the '**Head SHA:**' line under '## Provenance') so the maintainer's already-decided fresh re-cut, after phase 232's own closing plan lands, is a two-line edit rather than a body-wide search-and-replace. The same SHA also appears once more inside the rollback command (the `git revert` argument itself), which is unavoidable -- reverting a specific commit requires naming that commit -- and is called out explicitly here as the third line to re-point."
  - "During Task 2's own drafting, discovered (not fixed -- out of this plan's Task 1/2 scope) that `node scripts/ci/verify_hygiene_dispositions.mjs --require-completeness --require-soundness --require-determinism` now fails: `FAIL: 1 live item(s) have no corresponding row: remote_branch/origin/integration/v1.62-candidate-recut`. Plan 232-09 created this remote branch after 232-08's hygiene-dispositions record was captured (candidate_object 7e4fbce1), so the committed classification predates the branch that now exists live. This is reported plainly in the PR body's own risk section (as a real, currently-red, falsifiable claim, exactly matching the plan's 'anything still red' instruction) rather than silently worked around or omitted."
  - "The adopter-named remote branch (`origin/fix/adopter-app-1.5.1`) is referred to only generically in the PR body ('one adopter-named remote branch and its origin peer') -- the literal name was in an early draft, caught by this plan's own `grep -c adopter-app` leak check, and removed before the final commit. It is never spelled out in the committed, eventually-public body."

requirements-completed: []

coverage:
  - id: D1
    description: "scripts/ci/verify_pr_body_contract.mjs: every accepted strict flag (--require-sections/-density/-falsifiability) wired into a real comparison; --expected-repository wired against any github.com/OWNER/REPO reference in the body; the leak check reuses UNSAFE_PATH_PATTERN verbatim rather than defining a third sanitization pattern; seven negative-control behaviors from the plan's <behavior> block plus a mismatched-repository control plus one conforming positive control, all as named node:test scenarios."
    requirement: REL-04
    verification:
      - kind: unit
        ref: "node --check scripts/ci/verify_pr_body_contract.mjs && node --test --test-reporter=tap scripts/ci/verify_pr_body_contract.mjs -> 14/14 pass, 0 fail (9 of the 14 are this file's own named scenarios; the other 5 are main_module.mjs's own self-registering tests, fired because it is imported)"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_pr_body_contract.mjs --fixtures --expected-repository szTheory/accrue --require-sections --require-density --require-falsifiability -> `pr body contract: PASS (fixtures: require-density, require-falsifiability, require-sections)`"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor -> `ci script contract: PASS (verified: require-cohort-floor, require-guard-coverage, require-non-vacuity)`, on the commit that adds the new file"
        status: pass
    human_judgment: false
  - id: D2
    description: "232-INTEGRATION-PR.md: risk-first heading, the provenance-versus-behavior sentence naming both branches with the link-versus-diff instruction, an inline rollback command matching the recorded restore invocation verbatim, every outcome-asserting line falsifiable, a line count inside the declared density band, and both leak and adopter-name checks matching nothing."
    requirement: REL-04
    verification:
      - kind: other
        ref: "node scripts/ci/verify_pr_body_contract.mjs --body .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md --expected-repository szTheory/accrue --require-sections --require-density --require-falsifiability -> `pr body contract: PASS (verified: require-density, require-falsifiability, require-sections; 50 lines)`"
        status: pass
      - kind: other
        ref: "grep -nE '/Users/|/home/|\\$HOME' .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md; test $? -eq 1 -> no match (leak sweep clean)"
        status: pass
      - kind: other
        ref: "grep -c 'adopter-app' .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md -> 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Task 3 (checkpoint:decision): a reviewable integration pull request exists on szTheory/accrue, is open and unmerged against main, its live body is byte-identical to the committed 232-INTEGRATION-PR.md, that body satisfies the structural PR-body contract, and the published candidate tip only moved forward from the re-cut SHA. (Scope note: ref 3 establishes that the body carries falsifiable claims, not that each claim holds -- the claims themselves are evidenced by D1/D2 and by the phase's other coverage blocks.)"
    requirement: REL-04
    verification:
      - kind: other
        ref: "gh pr view 45 --json state,isDraft,mergedAt,mergeable,baseRefName,headRefOid -> state=OPEN, isDraft=false, mergedAt=null, mergeable=MERGEABLE, baseRefName=main, headRefOid=adef789f63b7c35585c9c2c8c118df887a7a9e03"
        status: pass
      - kind: other
        ref: "diff <(gh pr view 45 --json body -q .body) .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md -> identical but for one trailing newline"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_pr_body_contract.mjs --body .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md --expected-repository szTheory/accrue --require-sections --require-density --require-falsifiability -> `pr body contract: PASS (verified: require-density, require-falsifiability, require-sections; 58 lines)`"
        status: pass
      - kind: other
        ref: "git merge-base --is-ancestor c1397fe9127a9b4b2b1d3a0758d57879b14f4604 9b50ce6a080b684263de6c53d54e0726df077fa2 -> exit 0 (published tip only moved forward; no force-push)"
        status: pass
    human_judgment: false

duration: ~1h10min for Tasks 1-2, plus a later orchestrator-run session for Task 3 (the checkpoint) once the maintainer authorized it
completed: 2026-09-17
status: complete
---

# Phase 232 Plan 11: Open a Reviewable Integration Pull Request Summary

**Built a machine-checkable contract over the integration pull-request body (risk-first heading, the provenance-versus-behavior sentence, an inline rollback command, per-claim falsifiability, leak/density checks) via strict TDD, then wrote and committed `232-INTEGRATION-PR.md` against it -- 50 lines, all three strict checks passing, both leak sweeps clean. The plan's third task, a `checkpoint:decision` authorizing the actual `gh pr create`/`gh pr edit` call, was deliberately not attempted: this dispatch's scope was Tasks 1 and 2 only, and its hard limits forbid opening, updating, or touching any pull request under any circumstances -- that authorization belongs to the maintainer alone.**

## Performance

- **Duration:** ~1h10min active work across Tasks 1-2.
- **Tasks:** 2/3 completed (Task 3, the checkpoint, intentionally not attempted -- see below).
- **Commits:** 2 (`96dac0c0` Task 1, `14a212c8` Task 2). `plan_head_before`: `32e4c1cf` (232-10's completion commit). Measured via `git rev-list --count 32e4c1cf..HEAD`.
- **Files created:** 2 (`scripts/ci/verify_pr_body_contract.mjs`, `232-INTEGRATION-PR.md`).

## Accomplishments

### Task 1: `scripts/ci/verify_pr_body_contract.mjs`

Built via strict TDD (fixtures/scenarios written and confirmed failing against not-yet-implemented assertion functions before the implementation commit). Accepts `--body`, `--fixtures`, `--require-sections`, `--require-density`, `--require-falsifiability`, and `--expected-repository`; every strict flag is wired into a real comparison rather than parsed-and-ignored:

- **Sections check** (`--require-sections`): the first markdown heading must match a risk-naming pattern (`RISK_HEADING_PATTERN`); two required section headings (`## Rollback`, `## Scope`) must both be present; a provenance-versus-behavior sentence (one line naming "link" and "diff" alongside at least two inline code spans) must exist; the Rollback section must contain a code span (inline or fenced) naming `git`, not only a markdown link.
- **Density check** (`--require-density`): line count must fall inside `DENSITY_BAND` (50-80 lines, per D-59).
- **Falsifiability check** (`--require-falsifiability`): every markdown-bullet line must carry a code span or a link on that line or the line immediately following it; fails on the first offending line, naming its 1-indexed line number.
- **Leak check** (always run, not flag-gated): reuses `collect_window_dispositions.mjs`'s `UNSAFE_PATH_PATTERN` **verbatim** via import -- the same pattern `collect_hygiene_dispositions.mjs` already reuses -- rather than defining a third sanitization pattern, satisfying the plan's explicit instruction.
- **`--expected-repository`** (when supplied): any `github.com/OWNER/REPO` reference in the body must match; proved wired via its own negative-control scenario, not merely accepted and ignored.

Nine `node:test` scenarios (seven negative controls exactly matching the plan's `<behavior>` block, one mismatched-repository negative control proving `--expected-repository` is wired, and one conforming positive control exercising all three strict checks plus the repository check together) are registered as top-level named tests, satisfying the `<verify>` block's "fewer than 7 `ok` lines whose names are prose" fail condition with margin (9, not counting `main_module.mjs`'s own 5 self-registering tests that also fire because this file imports it).

### Task 2: `232-INTEGRATION-PR.md`

Wrote the pull-request body against the new contract, iterating until all three strict checks passed simultaneously:

- **Leads with risk**, not accomplishments: two required lanes waived (not green) at the frozen head SHA (`docs-contracts-shift-left`, `release-gate`), both real GitHub Actions failures (run 35232417814) with root causes already fixed on the milestone line (`11d42183`) but not yet incorporated into the frozen candidate SHA; the parked, waived `admin-ui-ratchet-guardrails` lane; and a real, currently-red gap discovered while drafting this body (see Deviations below).
- **States the provenance-versus-behavior split** in one explicit, single-line sentence naming both `integration/v1.62-candidate-recut` (link it) and `review/v1.62-candidate-code-only` (diff it) -- the highest-leverage sentence in the body per D-60.
- **Rollback is one inline command**, quoted verbatim from `232-ROLLBACK-POINT.json`'s `restore_argv`: `git revert -m 1 --no-edit 3f42158d5cd3ffb7134685ae2856074cf544e008`.
- **Every claim is falsifiable**: each substantive bullet pairs a one-line assertion with a `Verify:`/`Reproduce:`/`Re-verify:` continuation line carrying a real, re-runnable command or a permalink -- the contract's falsifiability check passes with zero offending lines.
- **Density**: 50 lines, inside the declared 50-80 band.
- **Scope**: every referenced change maps to `REL-04`, `REL-05`, `HYG-01`, `HYG-02`, or `HYG-03`, or to a numbered row in `232-CLEANUP-FINDINGS.json`; nothing else is referenced.
- **Leak and adopter-name sweeps both clean**: `grep -nE '/Users/|/home/|\$HOME'` matches nothing; `grep -c adopter-app` returns `0`.

## Requirement-to-Change Mapping (D-59 Scope rule)

| Body claim | Requirement / finding |
|---|---|
| Two waived required lanes, root cause fix on milestone line | HYG-02 (232-10) |
| Open hygiene-dispositions gap (this plan's own discovery) | HYG-01 (232-06/232-08), not yet remediated |
| Parked `admin-ui-ratchet-guardrails` | `.planning/WINDOWS.md` row 11 |
| Re-cut losslessness proof | REL-04 (232-09) |
| 13-job cohort re-derivation, zero drift | HYG-02 (232-10) |
| Release Please readiness dry run | REL-05 (232-05) |
| Hygiene-dispositions triad, no-deletion invariant | HYG-01 (232-06/232-08) |
| Bounded cleanup, 8 findings / 2 passes | HYG-03 (232-06/232-08) |
| `.tool-versions` tracking reversal, phase-200 shadow removal | HYG-01 findings 2-3 (`232-CLEANUP-FINDINGS.json`) |
| Rollback command | REL-04 (232-09's `232-ROLLBACK-POINT.json`) |
| No merge / no publish / no tag move | REL-04 (this plan's own prohibitions) |

## Task Commits

1. **Task 1: An automated contract over the pull-request body** (`tdd="true"`) -- `96dac0c0` (test)
2. **Task 2: Write the body, risk first, every claim falsifiable** -- `14a212c8` (docs)

No plan-metadata commit follows: per the `<output>` instruction, `232-11-SUMMARY.md` is written "when done" -- this plan is not done. The checkpoint task (Task 3) has not run, so `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` are deliberately left untouched by this dispatch; updating them now would record the plan as further along than it actually is.

## Files Created/Modified

- `scripts/ci/verify_pr_body_contract.mjs` -- new file, Task 1.
- `.planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md` -- new file, Task 2.

## Decisions Made

See `key-decisions` in frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking, caught before commit] Draft PR body named the adopter branch literally, tripping this plan's own leak check**
- **Found during:** Task 2, first full run of the plan's own `<verify>` block.
- **Issue:** An early draft of the "Deliberately not in this cleanup" bullet spelled out `origin/fix/adopter-app-1.5.1` by name (copied from `232-HYGIENE-DISPOSITIONS.md`'s own committed row, which already names it in a non-public-facing evidence artifact). `grep -c adopter-app .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md` returned `1`, tripping the exact adopter-name leak check the plan's own `<verify>` block runs.
- **Fix:** Rewrote the bullet to refer to it generically ("one adopter-named remote branch and its origin peer keep their current names"), preserving the factual claim (rename deferred to a future capsule mint, per `232-CONTEXT.md`'s deferred list) without publishing the name.
- **Files modified:** `.planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md`.
- **Verification:** Re-ran `grep -c adopter-app` -> `0`. Full `<verify>` block re-run clean afterward.
- **Committed in:** `14a212c8` (caught and fixed before the commit; no separate "leaked" commit exists).

**2. [Not fixed in this dispatch -- out of its Task 1/2 scope; reported honestly in the PR body, then closed by the orchestrator in `7c3a2d3a`] The committed hygiene-dispositions record did not cover the remote branch plan 232-09 created**
- **Found during:** Task 2, while gathering falsifiable evidence for the "What changed" section.
- **Issue:** `node scripts/ci/verify_hygiene_dispositions.mjs --records .../232-HYGIENE-DISPOSITIONS.json --rendered .../232-HYGIENE-DISPOSITIONS.md --expected-repository szTheory/accrue --require-completeness --require-soundness --require-determinism` fails: `FAIL: 1 live item(s) have no corresponding row: remote_branch/origin/integration/v1.62-candidate-recut`. The hygiene-dispositions record was captured (`candidate_object 7e4fbce1...`) before plan 232-09 pushed the re-cut candidate to a new remote branch, so the classification is now stale by one live item.
- **Why not fixed here:** This dispatch's assigned scope was strictly Task 1 (the contract script) and Task 2 (the PR body text). Regenerating `232-HYGIENE-DISPOSITIONS.json`/`.md` is a `collect`/`render` change to a different artifact pair, outside both tasks' declared `<files>` lists, and re-running the hygiene-dispositions collector was not authorized by this dispatch.
- **Handling:** Reported plainly, as a real, currently-red, falsifiable claim, in the PR body's own risk-first section -- exactly the "anything still red" content the plan's `<action>` instructs the body to lead with, rather than silently omitted or worked around.
- **Files modified:** none (verification-methodology finding only).
- **Carry-forward: CLOSED by the orchestrator in `7c3a2d3a`, after this dispatch handed back.** The record was re-minted through the `collect`/`render` triad with one appended decision row (`remote_branch/origin/integration/v1.62-candidate-recut`, disposition `retained`, forced by the phase-wide classification-only decision -- no remote ref is deleted, renamed, or force-pushed). The regeneration diff is exactly that one row plus `candidate_object`/`observed_at`; no other row drifted. Both verifier modes now pass (`--records`/`--rendered` live, and `--fixtures`). The PR body bullet that disclosed this as an open red was replaced with the closed, re-verifiable statement; the body contract still passes at 50 lines.

---

**Total deviations:** 2 (1 auto-fixed per Rule 3, caught and fixed before any commit; 1 genuine out-of-scope finding, reported honestly in the committed body rather than fixed or hidden). **Impact:** Neither weakens any check. The leak-check catch worked exactly as designed. The hygiene-dispositions gap was a real, pre-existing-as-of-this-plan finding that the PR body surfaced rather than concealed, and that the orchestrator then closed in `7c3a2d3a` before the phase tail gates.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None -- no external service configuration required for Tasks 1-2.

## Checkpoint Not Run (Task 3) -- Why, and What Remains

The plan's third task, `checkpoint:decision` ("authorize opening the integration pull request"), was **deliberately not attempted** in this dispatch. This is not a blocker discovered mid-execution -- it is this dispatch's explicit, stated scope boundary:

- The dispatch instructions name Tasks 1 and 2 as the entire assignment and state, verbatim: "You must **STOP** before the `checkpoint:decision` task at line 178. Do not open, update, or even draft-open a pull request. Do not run `gh pr create` or `gh pr edit` under any circumstances."
- The hard limits additionally prohibit any PR open/update/close/merge, any push to any remote, and any move of `integration/v1.62-candidate` or `integration/v1.62-candidate-recut`, "under any circumstances," reserving that authorization for the maintainer alone.

**What remains before Task 3 can run:**

1. The maintainer decides when to cut the fresh `integration/v1.62-candidate-recut` re-cut (after phase 232's own closing plan lands, per the dispatch's stated facts).
2. Whoever runs Task 3 re-points exactly three lines in `232-INTEGRATION-PR.md` to the fresh SHA: the `**Head SHA:**` line, the `git revert -m 1 --no-edit <sha>` line under `## Rollback`, and (only if the branch name itself changes) the `**Head branch:**` line and the `Link \`...\`` clause of the provenance sentence.
3. Re-run `node scripts/ci/verify_pr_body_contract.mjs --body .../232-INTEGRATION-PR.md --expected-repository szTheory/accrue --require-sections --require-density --require-falsifiability` after any edit -- it must still print `PASS` before anything is published.
4. Present the full body text, the passing contract output, and the leak/adopter-name check results to the maintainer per Task 3's own `<action>`, and obtain an explicit A/B/C decision before running `gh pr create` or `gh pr edit`.
5. Separately (not blocking Task 3, but noted for completeness): the hygiene-dispositions gap in Deviation 2 above should be closed -- either by regenerating the disposition record to add the missing row, or by a maintainer decision that the gap is acceptable to leave open through this PR.

## Next Phase Readiness

Tasks 1 and 2 are complete, committed, and independently re-verifiable (`scripts/ci/verify_pr_body_contract.mjs` and `232-INTEGRATION-PR.md` both exist on disk and pass every command in this SUMMARY, re-run fresh at write time). Task 3 (the checkpoint) is open and requires the maintainer's own authorization plus the fresh-re-cut re-pointing described above -- it was not started, attempted, or drafted by this dispatch.

## Self-Check: PASSED

- FOUND: `scripts/ci/verify_pr_body_contract.mjs` and `.planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md`, both on disk.
- Both task commits (`96dac0c0`, `14a212c8`) confirmed via `git log --oneline -5`.
- Re-ran every command cited in `coverage` above, fresh, immediately before writing this SUMMARY: all pass with the exact output quoted.
- Confirmed no pull request was opened, updated, or drafted: no `gh pr create`/`gh pr edit` invocation appears anywhere in this dispatch's tool history.
- Confirmed `git status --short` shows no changes to `integration/v1.62-candidate` or `integration/v1.62-candidate-recut`, and no push of any kind occurred.

## Task 3 (checkpoint:decision) -- run later, by the orchestrator, with maintainer authorization

The maintainer authorized both outward-facing actions explicitly ("yes i authorize u auto follow ur recs", in direct reply to a message naming exactly two: advancing the published candidate, and opening the integration PR). **PR #45 is open** -- https://github.com/szTheory/accrue/pull/45, base `main`, head `integration/v1.62-candidate-recut` @ `adef789f`, MERGEABLE, not draft, **not merged**. Merging it remains the maintainer's alone.

The "re-point exactly three lines" instruction above turned out to understate the work. Four separate claims in the body had gone stale or were wrong, and each was caught by running the body's own verification commands rather than by reading it:

1. **Head SHA.** The candidate advanced past `c1397fe9` by ordinary non-force merges. Rather than name a literal head SHA -- which every subsequent merge falsifies, including the merge carrying the correction itself -- the line was reworded to an **evidence SHA** (`9b50ce6a`, where the cited CI actually ran) plus a stable, checkable statement of how the head differs from it.
2. **Union-proof window.** `verify_recut_candidate.mjs` proves the union at the re-cut point, not at the advanced head. Rather than let `inspected=447 co_touched=7 drifted=0` imply coverage it no longer has, the body now states the limit outright and gives the one `git log` invocation that reads the uncovered delta.
3. **Rollback.** The original single-revert-of-the-re-cut-merge instruction *would not have rolled back* once the branch carried further merges. Corrected to revert the merge GitHub creates when the PR lands, which is sufficient because the candidate reaches `main` through exactly one merge.
4. **A falsifiable claim that failed its own check, twice.** The replacement rollback text asserted a merge count verifiable by `git log --merges | wc -l`. The first number (`3`) was simply wrong. The second (`9`) was right only against this checkout's 4-commit-stale local `main`; a reviewer on a fresh clone gets `4`. Caught by the re-verification pass. Any hardcoded count is also invalidated by the very merge that lands the correction, so the count was dropped: the line now names `origin/main` explicitly and asserts only the property the rollback depends on.

**Deviation from the plan's step 4.** The plan directs presenting the body and contract output to the maintainer for an explicit A/B/C decision before `gh pr create`. The maintainer had already given standing authorization to proceed autonomously on exactly this action, so the A/B/C prompt was not re-issued; the body, the passing contract output, and both clean sweeps were reported to them instead.

**`.planning/WINDOWS.md` rows 13 and 14 were deliberately left reading `waived`,** though their stated causes are discharged at the current head (release-gate and Annotation sweep are green in run 35256500599). `gsd-tools windows fixed` refuses waived -> fixed by design, and `232-WINDOW-DISPOSITIONS.json` is joined 1:1 against the ledger under `--require-row-join`, so flipping them in place would falsify a committed ship-window record and risk breaking the join. The discharge is stated in the PR body, pointing at the live run. Re-verification assessed this as "defensible, but only just," with the residual harm that a reader of `WINDOWS.md` alone gets a pessimistic picture, and recommended a `waived -> superseded` affordance as the real fix. Recorded as follow-up debt, not closed here.

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-17*
