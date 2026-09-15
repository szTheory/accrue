---
phase: 230-reviewable-history-integration
plan: 07
subsystem: infra
tags: [git, integration, evidence, ci, pr-closure, capsule, rollback-proof]

requires:
  - phase: 230-reviewable-history-integration
    plan: 04
    provides: 230-DISPOSITIONS.{json,md} excluded-commit ledger and the pr_44 row this plan closes and corrects
  - phase: 230-reviewable-history-integration
    plan: 06
    provides: the recomputed live-tip scope and code-only review branch this plan's final capsule and ledger review build on
provides:
  - "PR #44 closed unmerged, no comment posted (maintainer-authorized privacy deviation from D-10's default), origin/main unchanged at d30fc25d, remote branch fix/release-boot-env-resolver preserved for Phase 232's HYG-01"
  - "230-DISPOSITIONS.json pr_44 row schema extended: an honest close-unmerged-no-comment disposition value (alongside the pre-existing close-unmerged-cite-superseding), and two OPTIONAL post-execution evidence fields (command argv array, exit_code) on scripts/ci/collect_integration_disposition.mjs"
  - "Corrected .planning/STATE.md PR #44 account (D-10) and a new Phase 230 outcome section in both .planning/STATE.md and .planning/MILESTONES.md, committed and settled before the capsule mint"
  - "Final Phase-230 recovery capsule (bundle + 0600 private manifest, preservation-phase 230.7, out-of-repo, never committed) minted last, covering the candidate and milestone tips"
  - "230-ROLLBACK-POINT.json capsule field updated with the final capsule's digests; rollback point re-proved by execution via a fresh scratch git clone + git revert -m1"
affects: [231-exact-sha-release-gate-proof, 232-bounded-hygiene-release-handoff]

actuals:
  tokens: 24000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Schema extension over false-value coercion: when the maintainer's checkpoint resolution changed the executed action (close with no comment, not close-with-citation), the PR_44 disposition enumeration was extended with an honest new literal (close-unmerged-no-comment) rather than forcing the pre-existing close-unmerged-cite-superseding value onto an action that posted no citation."
    - "Required-vs-optional field split (PR_REQUIRED_FIELDS vs PR_FIELDS): two new evidence fields (command, exit_code) were added to the allowed set but deliberately excluded from the required-fields loop, so pre-closure ledger rows (recorded before the action ran, as Plan 230-04 did) remain valid without retroactive backfill."
    - "Preservation-phase namespacing for a second same-phase mint: a Phase-230 capsule was already minted once (Plan 230-01's safety capsule, --preservation-phase 230). Re-minting a second, later capsule under that identical phase value collides on already-claimed preservation ref names (git update-ref: reference already exists); this plan used a distinct sub-identifier (--preservation-phase 230.7, valid per the script's ^[0-9]+(\\.[0-9]+)?$ pattern) so the final capsule's preservation refs occupy their own namespace alongside, not instead of, the earlier safety capsule's."

key-files:
  created: []
  modified:
    - scripts/ci/collect_integration_disposition.mjs
    - .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json
    - .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md
    - .planning/STATE.md
    - .planning/MILESTONES.md
    - .planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json

key-decisions:
  - "Task 1's checkpoint:decision was pre-resolved by the maintainer before this executor ran, MODIFIED from the plan's recorded close-unmerged option: close PR #44 unmerged with NO comment posted at all (not even a shortened or SHA-only one), to eliminate any possibility of leaking identifiers in public GitHub content. Honored exactly: zero comments exist on the closed PR (verified via gh pr view --json comments)."
  - "Because no comment was posted, Task 2's literal acceptance criteria ('the comment posted on PR #44 contains all four superseding SHAs verbatim', 'the comment contains no adopter identifier...') are WAIVED by maintainer decision -- there is no comment to contain anything. The superseding-SHA evidence instead lives only in the committed 230-DISPOSITIONS.json/.md ledger (pr_44.matched_commits) and in scripts/ci/README.md, never in public GitHub content."
  - "The 230-DISPOSITIONS.json pr_44 row's disposition field was changed from close-unmerged-cite-superseding (Plan 230-04's recorded pre-execution default, which literally means 'closed, citing the superseding SHAs in a comment') to a new close-unmerged-no-comment value, because the schema (scripts/ci/collect_integration_disposition.mjs's PR_DISPOSITIONS closed enumeration) forced an exact-match choice and forcing the old value onto an action that posted no citation would have been a recorded-but-false claim. Extended the enumeration deliberately rather than lying to satisfy the schema, per the checkpoint resolution's explicit instruction."
  - "pr_44.state was set to 'closed' using the PRE-EXISTING open/closed/merged lifecycle enum (unchanged schema), NOT a new/overloaded 'proved' state as the plan's literal Task 2 prose suggested ('state: \"proved\"'). Introducing a second, differently-typed 'state' semantic onto the same field name would have conflicted with the field's existing, already-load-bearing contract (used by --require-ancestry/--require-scope live re-measurement elsewhere in this file). Instead, two NEW optional fields (command, exit_code) were added to carry the argv+exit_code evidence pattern used elsewhere in this ledger (ancestry/hazard rows), without touching pr_44.state's existing semantics."
  - "Reviewed all 8 rows in 230-REF-EXCEPTIONS.json against their retirement_trigger prose before minting the final capsule (D-28's empty-after-retirement assertion, which has no automated code-level check and is a task-level judgment call). None has fired: the PR #44 branch row's trigger requires BOTH the PR closed AND the local branch refs/heads/fix/release-boot-env-resolver to no longer exist -- the PR is now closed but the local branch still exists (its removal is Phase 232's HYG-01, out of this plan's authorized scope), so that row stays. The two Release-Please-tag rows and the two remote-tracking rows require a Phase-229-inventory recapture that has not happened. The candidate/review-branch rows require the Phase 232 integration PR to merge. Ledger stays at row_count: 8, unchanged."
  - "A second Phase-230 capsule mint under the identical --preservation-phase 230 value used by Plan 230-01's earlier safety capsule collided with an already-claimed preservation ref (git update-ref: reference already exists), since preservation ref names are deterministic hex encodings of the original ref name, not per-invocation. Resolved by minting under --preservation-phase 230.7 instead (a distinct, valid decimal sub-identifier per the script's own phase-identifier regex), giving the final capsule its own preservation namespace rather than attempting to reuse or overwrite the safety capsule's."

requirements-completed: [INTG-01, INTG-03]

coverage:
  - id: T1
    description: "PR #44 is closed, unmerged, with origin/main unchanged and the excluded-commit ledger's pr_44 row updated with the executed action (command argv, exit_code, resulting state) using an honestly-extended disposition value rather than a forced false one."
    requirement: "INTG-03"
    verification:
      - kind: other
        ref: "gh pr view 44 --repo szTheory/accrue --json state,mergedAt,comments -- {\"state\":\"CLOSED\",\"mergedAt\":null,\"comments\":[]}"
        status: pass
      - kind: other
        ref: "git ls-remote origin refs/heads/main -- d30fc25dbf6ba551792c66ff451b4b93c0af4bf1 (unchanged before and after the close)"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/collect_integration_disposition.mjs (15/15 pass after the PR_44 schema extension)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --records ... --rendered ... --dispositions ... --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-excluded-ledger --require-determinism -- PASS"
        status: pass
    human_judgment: false
  - id: T2
    description: ".planning/STATE.md's PR #44 account is corrected (no longer describes the pushed branch as four commits cherry-picked off/from main) and both .planning/STATE.md and .planning/MILESTONES.md record the Phase 230 outcome and the D-34 dirty-boolean handoff, committed and settled before the capsule mint."
    requirement: "INTG-01"
    verification:
      - kind: other
        ref: "! grep -q 'cherry-picked off main' .planning/STATE.md && grep -q 'integration/v1.62-candidate' .planning/STATE.md && grep -q 'integration/v1.62-candidate' .planning/MILESTONES.md -- exit 0"
        status: pass
      - kind: other
        ref: "git diff --quiet -- .planning/STATE.md .planning/MILESTONES.md -- exit 0 (both settled/committed before Task 4)"
        status: pass
    human_judgment: false
  - id: T3
    description: "A final 0600 capsule outside the repository was minted last, covering the candidate and milestone tips; the rollback point re-proves by execution in a fresh scratch clone (never a worktree) and 230-ROLLBACK-POINT.json's capsule field names the final digests; nothing was pushed."
    requirement: "INTG-01"
    verification:
      - kind: integration
        ref: "bash scripts/ci/preserve_repository_state.sh --self-test -- preserve repository state self-test: PASS"
        status: pass
      - kind: other
        ref: "stat -f '%OLp' on both final bundle and final private manifest -- 600, 600"
        status: pass
      - kind: other
        ref: "git bundle verify <final bundle> && git bundle list-heads includes both integration/v1.62-candidate tip and the milestone branch tip -- both present"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs ... --require-ancestry --require-scope --require-hazard-universe --require-excluded-ledger --require-post-merge-scope --require-rollback-proof --require-determinism --rollback-point .../230-ROLLBACK-POINT.json -- PASS (rollback proof re-executed in a fresh scratch clone)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-typed-ref-continuity --require-recovery --require-all-ref-recovery --require-typed-artifacts -- repository inventory fixtures: PASS"
        status: pass
    human_judgment: false

duration: ~65 min
completed: 2026-09-15
status: complete
commits: 3
plan_head_before: 2d9d8f4749064cab38cfc68246f2370d025c0cc4
---

# Phase 230 Plan 7: PR #44 Closure, Corrected STATE.md, and Final Capsule Summary

**Closed the superseded PR #44 unmerged with NO public comment (maintainer-authorized privacy deviation), corrected `.planning/STATE.md`'s factually wrong PR #44 account and recorded the Phase 230 outcome in both planning documents, then minted the final 0600 out-of-repo capsule last with an executably re-proved rollback point.**

## Performance

- **Duration:** ~65 min
- **Started:** 2026-09-15
- **Completed:** 2026-09-15
- **Tasks:** 3 (Task 1's checkpoint:decision was pre-resolved by the maintainer before dispatch)
- **Files modified:** 6

## Accomplishments

- **PR #44 closed unmerged, zero comments.** Re-measured immediately before acting: `git merge-base --is-ancestor main 3f8338cd` → YES, `main...3f8338cd` → `0 4` (head is local `main` plus 4 commits, unchanged from Plan 230-04's recorded facts), all four superseding SHAs (`2de4389b`, `9eae363a`, `173607d9`, `5653216c`) re-verified as patch-id matches on `integration/v1.62-candidate`. `gh pr close 44 --repo szTheory/accrue` succeeded; `gh pr view 44` confirms `state: CLOSED`, `mergedAt: null`, `comments: []`. `origin/main` re-measured unchanged at `d30fc25d` before and after. The remote branch `fix/release-boot-env-resolver` still exists (Phase 232's HYG-01 owns its removal).
- **`230-DISPOSITIONS.json`/`.md` pr_44 row honestly updated, schema extended rather than forced.** `scripts/ci/collect_integration_disposition.mjs`'s `PR_DISPOSITIONS` enumeration gained `close-unmerged-no-comment` alongside the pre-existing `close-unmerged-cite-superseding` (which described an action — posting a citation comment — that never happened here), and `PR_FIELDS` gained two OPTIONAL evidence fields (`command` argv array, `exit_code`) split out from a new `PR_REQUIRED_FIELDS` set so pre-closure ledger rows stay valid without retroactive backfill. `pr_44.state` was set to `closed` using the pre-existing open/closed/merged enum — no redundant `proved` state was introduced onto that field. The ledger's `note` records the maintainer-authorized no-comment deviation and its privacy rationale.
- **`.planning/STATE.md` corrected (D-10).** The "Adopter boot fix: SHIPPED as PR #44" section previously described the PR's four commits as "cherry-picked from the milestone branch" — describing intent, not the pushed branch. Replaced with the measured truth (head was local `main` plus 4 commits; merging would have published all 80 excluded Phase-226 commits onto `main`) and the actual outcome (closed unmerged, no comment, `origin/main` unchanged).
- **Phase 230 outcome recorded in both `.planning/STATE.md` and `.planning/MILESTONES.md`.** Candidate ref and both SHAs (identity-pinned merge commit `4d45002c...` and live tip `bab50d92...`), recomputed scope (337/223/114 files, 527/265 commits), the 80-row excluded-commit ledger breakdown (27 rejected / 53 superseded / 1 carried / 1 published-elsewhere), the 8-row ref-exceptions ledger, and the D-34 handoff (worktree `dirty` pinned `true`; Phase 232 flipping it `false` will fail strict re-verification of a capsule minted before that transition). Both documents committed and settled before Task 4's mint, satisfying D-32's hard ordering constraint.
- **Final Phase-230 capsule minted last.** `scripts/ci/preserve_repository_state.sh --preservation-phase 230.7` (a distinct sub-identifier from Plan 230-01's earlier safety capsule under bare `230`, avoiding a preservation-ref collision) wrote the bundle and 0600 private manifest to the session scratchpad, never committed. Bundle heads include both `integration/v1.62-candidate`'s live tip and the milestone branch tip; the artifact manifest's untracked-file sweep automatically recorded sha256 for `scripts/ci/stripe_test_fixtures.mjs` and `scripts/ci/verify_stripe_test_fixtures.mjs` (D-33) without classifying, moving, or deleting either.
- **Rollback point re-proved by execution, not trusted from the earlier proof.** `verify_integration_disposition.mjs --require-rollback-proof --rollback-point 230-ROLLBACK-POINT.json` internally clones the repository into a fresh scratch directory (never `git worktree add`, per D-30), checks out the recorded `candidate_object`, runs `git revert -m 1`, and asserts the resulting tree equals `expected_reverted_tree` — passed. `230-ROLLBACK-POINT.json`'s `capsule` field now names the FINAL capsule's `bundle_sha256`/`manifest_sha256`; `restore_argv` remains an argv array of argv arrays.
- **230-REF-EXCEPTIONS.json ledger reviewed for fired retirement triggers, none found.** All 8 rows' `retirement_trigger` prose evaluated by hand (no automated code-level check exists for this): the PR #44 branch row requires both the PR closed AND the local branch gone (only the first is now true — local `refs/heads/fix/release-boot-env-resolver` still exists, its removal being out of this plan's authorized scope); the tag and remote-tracking rows require a Phase-229 inventory recapture that has not happened; the candidate/review-branch rows are Phase-232 events. Ledger `row_count` stays `8`, unchanged.

## Task Commits

1. **Task 2: Close PR #44 unmerged with a superseding-SHA comment** (executed WITHOUT the comment per maintainer's checkpoint resolution) — `a28bc9b7` (feat)
2. **Task 3: Correct the STATE.md record and settle the planning documents** — `7dec9887` (docs)
3. **Task 4: Mint the final Phase-230 capsule last and re-prove the rollback point** — `145e71ab` (feat)

## Files Created/Modified

- `scripts/ci/collect_integration_disposition.mjs` — `PR_DISPOSITIONS` extended with `close-unmerged-no-comment`; `PR_FIELDS`/`PR_REQUIRED_FIELDS` split to add optional `command`/`exit_code` evidence fields; `validatePr44` validates them when present
- `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json` — `pr_44` row updated: `state: "closed"`, `disposition: "close-unmerged-no-comment"`, corrected `note`, `command`/`exit_code` recorded
- `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md` — re-rendered byte-identically from the updated JSON
- `.planning/STATE.md` — corrected PR #44 account; new Phase 230 outcome section; D-34 handoff
- `.planning/MILESTONES.md` — new v1.62 in-progress entry recording the Phase 230 outcome
- `.planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json` — `capsule.bundle_sha256`/`capsule.manifest_sha256` updated to the final capsule's digests

## Decisions Made

See `key-decisions` in frontmatter for full detail. Summarized: (1) Task 1's checkpoint was pre-resolved by the maintainer as close-unmerged with NO comment, honored exactly (zero comments posted, verified); (2) Task 2's comment-content acceptance criteria are waived by that maintainer decision since no comment exists; (3) the ledger's `disposition` enumeration was extended with an honest new value rather than forcing the old "cite-superseding" literal onto an action that cited nothing; (4) `pr_44.state` stayed in its pre-existing open/closed/merged contract rather than absorbing a redundant "proved" semantic — two new optional fields carry the argv+exit_code evidence instead; (5) the ref-exceptions ledger was reviewed by hand and no row's retirement trigger has fired, so it stays at 8 rows; (6) the final capsule was minted under a distinct `--preservation-phase 230.7` to avoid colliding with Plan 230-01's earlier same-phase safety capsule.

## Deviations from Plan

### Maintainer-Authorized Deviations

**1. [Maintainer decision, pre-resolved before dispatch] PR #44 closed with NO comment, not the D-10-default superseding-SHA comment**
- **Found during:** Task 1 (checkpoint already resolved by the orchestrator/maintainer before this executor was dispatched)
- **What changed from the plan:** Plan 230-07's Task 2 literally specified posting one comment on PR #44 naming the four superseding SHAs, the ahead/behind facts, and where the evidence lives, before closing. The maintainer's resolution for this specific checkpoint authorized option `close-unmerged`, MODIFIED: close PR #44 unmerged WITHOUT posting any comment at all — not a shortened one, not a SHA-only one, not a link. The maintainer's stated reasoning: avoiding any possibility of leaking identifiers in public GitHub content.
- **What was honored:** No comment of any kind was posted. Verified: `gh pr view 44 --json comments` returns `[]`.
- **Consequence for Task 2's acceptance criteria:** "The comment posted on PR #44 contains all four superseding SHAs verbatim" and "The comment contains no adopter, customer, or personal identifier, no absolute path, and no `$HOME`" are **WAIVED** — there is no comment for either criterion to apply to. All other Task 2 acceptance criteria (closed/unmerged state, origin/main unchanged, remote branch preserved, ledger row updated with `command`/`exit_code`, byte-identical re-render) were met and verified.
- **Ledger correction:** the `230-DISPOSITIONS.json` pr_44 row's `disposition` field, which previously carried the literal value `close-unmerged-cite-superseding` (Plan 230-04's recorded pre-execution default), now reads `close-unmerged-no-comment` — a schema extension, not a forced false value, since the executed action never cited anything publicly.
- **Files modified:** `scripts/ci/collect_integration_disposition.mjs`, `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.{json,md}`
- **Verification:** `gh pr view 44 --json state,mergedAt,comments`; `node --test scripts/ci/collect_integration_disposition.mjs` (15/15); `verify_integration_disposition.mjs --require-excluded-ledger --require-determinism` PASS.
- **Commit:** `a28bc9b7`

### Auto-fixed Issues

**2. [Rule 3 - Blocking] Task 4's plan-level `<verify>` command for `--require-rollback-proof` omitted the required `--rollback-point` flag**
- **Found during:** Task 4, first run of the plan-specified verify command
- **Issue:** `verify_integration_disposition.mjs --require-rollback-proof` fails with `--rollback-point is required with --require-rollback-proof` when the flag is absent — the plan's own literal `<verify>` command text for Task 4 did not include `--rollback-point`.
- **Fix:** Added `--rollback-point .planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json` to the invocation. This is the file the same task's action already required updating with the final capsule's digests, so the fix uses evidence already produced by this task, not a new artifact.
- **Verification:** the corrected command passes end-to-end, including the fresh-scratch-clone rollback re-proof.
- **Committed in:** `145e71ab` (Task 4 commit; the fix is in how the verify command was invoked, not in any file)

**3. [Rule 3 - Blocking] A second Phase-230 capsule mint under `--preservation-phase 230` collided with Plan 230-01's earlier safety-capsule preservation refs**
- **Found during:** Task 4, first mint attempt
- **Issue:** `git update-ref` failed with `reference already exists` for a preservation ref whose hex-encoded name was already claimed by Plan 230-01's earlier safety-capsule mint under the identical `--preservation-phase 230` value.
- **Fix:** Minted the final capsule under `--preservation-phase 230.7` instead (valid per the script's own `^[0-9]+(\.[0-9]+)?$` phase-identifier pattern), giving it a distinct preservation namespace alongside, not overwriting, the earlier safety capsule.
- **Verification:** the mint succeeded, `preserve_repository_state.sh --self-test` passed, and both preservation namespaces (`refs/accrue-preserve/phase-230/` and `refs/accrue-preserve/phase-230.7/`) coexist without collision.
- **Committed in:** `145e71ab` (Task 4 commit; the fix is in the mint invocation, not a file change)

---

**Total deviations:** 1 maintainer-authorized (the no-comment closure), 2 auto-fixed (both Rule 3 blocking issues, both in how commands were invoked rather than in file content).
**Impact:** None reduced the plan's actual evidentiary guarantees — the missing `--rollback-point` flag was the one omission that would have silently skipped the rollback re-proof entirely had it not been caught and fixed; the preservation-phase collision was purely a naming collision with a prior mint, resolved without touching any already-published evidence.

## Issues Encountered

None beyond the three items documented above (all resolved and verified).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 230 (Reviewable History Integration) is now complete: all 7 plans executed and summarized. `integration/v1.62-candidate` exists, is fully evidence-backed, and was never pushed. PR #44 is closed unmerged. `origin/main` is unchanged at `d30fc25d`; the `v1.61` tag is unmoved.
- Phase 231 (Exact-SHA Release Gate Proof) can proceed against `integration/v1.62-candidate`'s live tip; the excluded-commit ledger, hazard universe, and Phase-232 handoffs recorded in `230-INTEGRATION-DISPOSITION.md` are its starting context.
- **D-34 reminder for Phase 232:** the worktree `dirty` boolean is currently pinned `true` in every capsule/inventory minted through this phase. The first action that makes the tree fully clean will flip that boolean to `false` and fail strict re-verification of any capsule minted before that point — expected, not a defect. Phase 232 should recapture after the tree goes clean, following the same "mint last" discipline this plan just followed.
- **HYG-01 reminder for Phase 232:** the local and remote `fix/release-boot-env-resolver` branches still exist (its useful commits are all on the candidate as patch-id matches); their removal is explicitly Phase 232's, not this plan's, authorized scope.
- Strict re-verification of this plan's final capsule is a point-in-time claim, valid as of capture commit `145e71ab` — the same lesson Phase 229's STATE.md already documents. The next recapture must again be the LAST action after planning documents settle.

---
*Phase: 230-reviewable-history-integration*
*Completed: 2026-09-15*

## Self-Check: PASSED

- FOUND: scripts/ci/collect_integration_disposition.mjs (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.json (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.md (modified)
- FOUND: .planning/STATE.md (modified)
- FOUND: .planning/MILESTONES.md (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json (modified)
- FOUND commit: a28bc9b7 (Task 2)
- FOUND commit: 7dec9887 (Task 3)
- FOUND commit: 145e71ab (Task 4)
- Re-ran the plan-level `<verification>` items: (1) `gh pr view 44` -- CLOSED, mergedAt null, comments []; (2) `git ls-remote origin refs/heads/main` -- `d30fc25d...`, unchanged; (3) `git diff --quiet -- .planning/STATE.md .planning/MILESTONES.md` -- exit 0, both settled before the mint; (4) `git bundle list-heads` on the final capsule includes both the candidate tip and the milestone tip, both files mode 600; (5) `verify_integration_disposition.mjs` with the full `--require-*` flag set including `--require-rollback-proof --rollback-point ...` -- PASS; (6) `verify_repository_inventory.mjs --fixtures --require-typed-ref-continuity --require-recovery --require-all-ref-recovery --require-typed-artifacts` -- PASS.
