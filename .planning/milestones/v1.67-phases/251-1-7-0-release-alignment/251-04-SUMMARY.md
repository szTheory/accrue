---
phase: 251-1-7-0-release-alignment
plan: "04"
subsystem: release-automation
status: complete
completed: 2026-10-26
requirements-completed: []
tags: [release-please, recovery, wedge-detector, positive-control, freeze, rls-01, rls-02]
requires: [251-03]
provides:
  - workflow fix on main as squash 6e285bff (PR #54)
  - PR #50 stale autorelease pending label removed, hazard proven before and gone after
  - main frozen at FREEZE_SHA 6e285bff6a6c10a1f79b19008cd679b16e4d8be6
  - fresh 1.7.0 release PR #55, raw head 24f8a342 (parent FREEZE_SHA)
affects: [251-05, 251-06]
key-files:
  created:
    - .planning/phases/251-1-7-0-release-alignment/251-RELEASE-LEDGER.md
    - .planning/phases/251-1-7-0-release-alignment/251-04-SUMMARY.md
  modified:
    - .planning/phases/251-1-7-0-release-alignment/251-VERIFICATION.md
    - .planning/phases/251-1-7-0-release-alignment/251-UAT.md
decisions:
  - "The #50 label is removed, not relabelled autorelease: tagged, because nothing was tagged (RESEARCH Q2)."
  - "GHREL_MARKER is the last success-prefixed status line common to both completed dry runs ('✔ Building strategies by path'), because the true last line embeds the candidate count (3 before, 0 after). 251-06 treats it as a dry-run-started marker; the completion proof is exit 0 plus 'Would tag 0 releases'."
  - "The plan's Task 2 label check compared gh --jq output to the string null, but gh renders null as an empty string. It was run as |tostring, with PR #55 (which carries the label) as the positive control."
actuals:
  tokens: 7000
  tasks: 3
  commits: 0
plan_head_before: 6e285bff6a6c10a1f79b19008cd679b16e4d8be6
plan_head_after: 6e285bff6a6c10a1f79b19008cd679b16e4d8be6
coverage:
  - id: L1
    description: the workflow-fix PR #54 exact head F is green by the exact-head helper and is squash-merged with --match-head-commit as S, whose push CI is green against the db1b6d85 baseline
    requirement: RLS-01
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 8a9c1c99337b1b87dda6b02fc9f62d0803d5c744 --event pull_request --pr-base origin/main"
        status: pass
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 6e285bff6a6c10a1f79b19008cd679b16e4d8be6 --event push --baseline-run 40281358498"
        status: pass
    human_judgment: false
  - id: L2
    description: the new wedge detector fired in its first production run at S, turning Release Please run 40344886221 red through the separate Release PR wedge check job naming PR 50, while the Release Please job itself succeeded
    requirement: RLS-01
    verification:
      - kind: command
        ref: "gh run view 40344886221 --repo szTheory/accrue --json jobs --jq '[.jobs[]|select(.name==\"Release Please\" or .name==\"Release PR wedge check\")|.name+\"=\"+.conclusion]|sort|join(\",\")'"
        status: pass
      - kind: command
        ref: "gh run view 40344886221 --repo szTheory/accrue --log-failed | grep -F 'still labelled autorelease: pending (50)'"
        status: pass
    human_judgment: false
  - id: L3
    description: the PR 50 stale-label tagging hazard was proven present (would tag 3 1.7.0 releases at b4310a39, pullNumber 50) and then removed (merged-pending query [], dry run would tag 0 releases), and the dispatched Release Please run at FREEZE_SHA succeeded with the detector silent
    requirement: RLS-01
    verification:
      - kind: command
        ref: "gh pr list --repo szTheory/accrue --state merged --label 'autorelease: pending' --json number --jq '[.[].number]|tostring'"
        status: pass
      - kind: command
        ref: "npx release-please@17.6.0 github-release --dry-run (before: Would tag 3 releases, pullNumber: 50; after: Would tag 0 releases)"
        status: pass
      - kind: command
        ref: "gh run view 40348672308 --repo szTheory/accrue --json conclusion,headSha,event"
        status: pass
    human_judgment: false
  - id: L4
    description: the fresh release PR 55 has exactly the seven release files at 1.7.0, exactly three 1.7.0 component blocks, its raw head's parent is FREEZE_SHA, and no 1.7.0 tag, GitHub release or Hex release exists
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_pr_scope.sh --pr 55 --version 1.7.0"
        status: pass
    human_judgment: false
---

# Phase 251 Plan 04: Fix Landing, #50 Recovery and Fresh Release PR Summary

The release-please fix landed on main as squash `6e285bff` (PR #54), merged on an exact-head-green PR head. In its first production run the new wedge detector turned Release Please red, naming #50. #50's stale `autorelease: pending` label was removed after a dry run proved it would have tagged all three 1.7.0 releases at the empty merge commit `b4310a39`. A dispatched Release Please run then opened release PR #55 at 1.7.0 for all three packages, on top of a frozen main.

## Remote writes (CONTEXT A6)

| UTC timestamp | Action | Target | Result |
|---------------|--------|--------|--------|
| 2026-10-26T14:31:41Z | push | `refs/heads/ci/release-please-repair` (normal, no force) | ok, head `8a9c1c99` |
| 2026-10-26T14:32:08Z | pr-create | szTheory/accrue#54 | ok |
| 2026-10-26T14:59:31Z | pr-merge | #54 `--squash --match-head-commit 8a9c1c99...` | squash `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` |
| 2026-10-26T15:21:34Z | remove-label | #50 `autorelease: pending` | rc 0; main frozen at `6e285bff` |
| 2026-10-26T15:22:24Z | workflow-dispatch | `release-please.yml` on main | run 40348672308, success |

No force-push, no push to main, no tag push. Neither remote branch `release-please--branches--main` nor `integration/v1.62-candidate-recut` was touched. The full identifier table is in `251-RELEASE-LEDGER.md`.

## Evidence

- **Pre-push:** `250-prepush-guard.sh --hygiene-only` over `db1b6d85..8a9c1c99` passed with rc 0 (8 PASS, including its own controls). The diff touches no `accrue/`, `accrue_admin/` or `accrue_portal/` path.
- **L1:** at F, `250-ci-head-status` reported `GREEN at 8a9c1c99... (event pull_request)`: 19 success jobs, the browser workflow not triggered (0 of 25 PR paths match), and the parked ratchet lane recorded as any-conclusion. Immediately before the merge, origin/main was `db1b6d85` and the live head was F. S's tree equals F's tree. At S, `GREEN at 6e285bff... (event push)`: ci.yml run 40344886087 with 22 success jobs.
- **L2:** Release Please run 40344886221 at S concluded `failure`, with `Release Please=success` and `Release PR wedge check=failure`. No other job failed (the publish and linked-proof jobs were skipped). Log line: `##[error]merged release PR(s) still labelled autorelease: pending (50); release-please will not open a new release PR until the label is removed`. No release PR opened in that run.
- **L3:** the merged-pending query returned `[50]` before and `[]` after. Its negative control, `autorelease: nonexistent-251`, returned `[]`. The before dry run (rc 0, 211 lines) printed `✔ Would tag 3 releases:` with `accrue-v1.7.0` / `accrue_admin-v1.7.0` / `accrue_portal-v1.7.0` at sha `b4310a39...` and `pullNumber: 50`. The after dry run (rc 0, 8 lines) ended `✔ Would tag 0 releases:`. Neither output contains a token-shaped string. The dispatch run 40348672308 at `6e285bff`, event `workflow_dispatch`, concluded success, with the wedge check also success.
- **L4:** `verify_release_pr_scope.sh --pr 55 --version 1.7.0` printed `OK ... Target version: 1.7.0`. The PR's files are exactly the manifest plus the mix.exs and CHANGELOG of each of the three packages. The body holds exactly three `<details><summary>` blocks: `accrue: 1.7.0`, `accrue_admin: 1.7.0` and `accrue_portal: 1.7.0`. `git rev-parse 24f8a342^` = FREEZE_SHA. There are 0 `accrue*-v1.7.0` tags against 3 for v1.6.0 (the positive control). `gh release view accrue-v1.7.0` fails. hex.pm returns 404 for 1.7.0 and 200 for 1.6.0 for all three packages.

Raw outputs are in `.planning/251-evidence.local/` (git-ignored): `251-04-detector.log`, `251-04-ghrel-before.{out,rc}` and `251-04-ghrel-after.{out,rc}`.

## Deviations from Plan

**1. [Rule 1 - Bug, verify script] The `gh --jq` null comparison**
- **Found during:** Task 2 verify
- **Issue:** `gh pr view 50 --json labels --jq '[...]|index("autorelease: pending")'` prints an empty string for null, so `= "null"` can never pass, even with the label absent.
- **Fix:** the check was run as `|tostring` (yields `null`). As a positive control, the same check against #55, which carries the label, does not yield `null`. The full Task 2 verify then passed. The plan file is unchanged; 251-05/06 gates should use `|tostring` for any null comparison.

**2. [Plan fallback] GHREL_MARKER**
- No full line is common to the completed before and after dry runs, because the last line embeds the count. As the plan directs, the marker is the last common success-prefixed status line: `✔ Building strategies by path`.

**3. `--pr-base origin/main`, not `main`**
- The judgement used `--pr-base origin/main`, because local `main` is not maintained as a mirror of origin. At judge time both refs were `db1b6d85`.

**4. Commits: 0**
- This plan's work is remote writes. The only commit is the bookkeeping commit that carries this SUMMARY on the unpushed `docs/251-close`, so it is not counted.

## Notes for 251-05

- Release PR **#55**, raw head `24f8a34220070ee7148ecc1b9f37d922386bf3c9`, FREEZE_SHA `6e285bff6a6c10a1f79b19008cd679b16e4d8be6`. It opens red by design: CI was pending at write time, and the curated-CHANGELOG gate, README pins and companion notes still need alignment on `release-please--branches--main`. #55 carries `autorelease: pending`, as a real release PR should.
- The local branch `docs/251-close` (based at FREEZE_SHA, unpushed) holds this SUMMARY and the ledger. Main stays frozen: no merges until #55 merges.
- `ci/release-please-repair` remains on origin (`--delete-branch=false`). Deleting it is safe, but this plan did not authorize it.

## Self-Check: PASSED

- FOUND: 251-RELEASE-LEDGER.md and 251-04-SUMMARY.md
- FOUND: S `6e285bff` = origin/main; PR #54 MERGED with mergeCommit S; PR #55 OPEN with head RAW
