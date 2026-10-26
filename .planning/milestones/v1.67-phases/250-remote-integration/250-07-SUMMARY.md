---
phase: 250-remote-integration
plan: "07"
subsystem: post-merge-close
status: complete
completed: 2026-10-25
requirements-completed: [LAND-02, LAND-03]
tags: [close, covered-digest, executable-uat, sl-e, sl-g, negative-control, close-pr]
dependency-graph:
  requires: [250-06]
  provides: [Phase 250 complete, LAND-02 and LAND-03 Complete, VERIFICATION 3/3 re-minted over seven SUMMARYs, close evidence on main through a squash-merged PR]
  affects: [251]
tech-stack:
  added: []
  patterns: [completion marks follow the evidence, close commits through a follow-up PR from docs/250-close]
key-files:
  created:
    - .planning/phases/250-remote-integration/250-06-SUMMARY.md
    - .planning/phases/250-remote-integration/250-07-SUMMARY.md
  modified:
    - .planning/phases/250-remote-integration/250-ci-head-status.mjs
    - .planning/phases/250-remote-integration/250-VERIFICATION.md
    - .planning/phases/250-remote-integration/250-UAT.md
    - .planning/phases/250-remote-integration/250-CI-LEDGER.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - "Checkpoint option merge-close-pr: the close commits live on branch docs/250-close, created from main at M, and reach main only through a PR. Nothing is pushed to main directly. The maintainer authorized squash-merging that PR once every PR-path job is success on its exact head (parked ratchet lane excepted per D1)."
  - "The plan text says to commit on local main and push main:refs/heads/docs/250-close. The commits were made on the docs/250-close branch instead, so local main never runs ahead of origin/main; the pushed ref and its content are the same."
  - "LAND-02 and LAND-03 are marked Complete only now, after the 250-05 E/H verdicts and the 250-06 merge evidence exist."
plan_head_before: 3dd5f8746b34497d345cd4d03c44f3756a159bab
actuals:
  tokens: 12000
  tasks: 2
  commits: 5
coverage:
  - id: L2
    description: LAND-02 every PR-path job of ci.yml and accrue_admin_browser.yml is success on the exact evidence head E and on the body-only PR head H, with the D1 exclusions only
    requirement: LAND-02
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha ece41e51eb0e6ab4f030d33501cd811188542686 --event pull_request prints GREEN, rc 0, 20 jobs success (ci.yml run 40243045805, accrue_admin_browser.yml run 40243045812; parked lane failure allowed, job 121321049329)"
        status: pass
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 17a608ccdbc1512a31475e0804d46811d2059c4b --event pull_request prints GREEN, rc 0, 20 jobs success (ci.yml run 40245573325, accrue_admin_browser.yml run 40245573321; parked lane failure allowed, job 121328560720); git diff --name-only E H lists only 250-INTEGRATION-PR.md"
        status: pass
    human_judgment: false
  - id: L3
    description: LAND-03 PR #49 is a two-parent merge commit with full reachability, and the first post-merge main push run meets run 35374333981 job by job
    requirement: LAND-03
    verification:
      - kind: command
        ref: "git rev-list --parents -n 1 3dd5f8746b34497d345cd4d03c44f3756a159bab prints 3 SHAs (M, 7971753a, 17a608cc); git merge-base --is-ancestor 17a608cc 3dd5f874 exits 0; gh pr view 49 --json state,mergeCommit gives MERGED 3dd5f874...; git rev-list 3dd5f874 | grep -c -x -F -f .planning/250-premerge.local prints 993 of 993"
        status: pass
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 3dd5f8746b34497d345cd4d03c44f3756a159bab --event push --baseline-run 35374333981 prints GREEN, rc 0, 21 jobs success (ci.yml run 40247684345, accrue_admin_browser.yml run 40247684340); recorded, not claimed: Stripe provider-proof incident reconciliation and Stripe test-mode parity (baseline skipped), Admin UI ratchet guardrails [parked] (baseline failure)"
        status: pass
    human_judgment: false
  - id: C1
    description: Close gates pass on the close commit and the evidence is a fixed point
    requirement: LAND-03
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-mint-close-artifacts.mjs run twice gives the same covered_files and covered_digest and leaves the tracked tree clean"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --phase 250; node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in; node scripts/ci/verify_executable_uat_contract.mjs --all-since 229"
        status: pass
      - kind: command
        ref: "bash .planning/phases/250-remote-integration/250-prepush-guard.sh --close --remote-ref refs/heads/docs/250-close passes before the push of docs/250-close"
        status: pass
    human_judgment: false
  - id: F6
    description: The verdict helper's pull_request mode judges accrue_admin_browser.yml by its paths filter when --pr-base is given, as push mode already does; without --pr-base it still requires the browser run
    requirement: LAND-02
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --self-test prints PASS (41 checks), including: planning-only PR diff with no browser run rc 0 (not triggered (paths)); diff touching accrue_admin with no run rc 1; empty diff rc 1 (fails closed); existing browser run on a non-matching diff still judged (red Browser UAT rc 1); no --pr-base still rc 1; the workflow's pull_request and push path lists equal the pinned list"
        status: pass
      - kind: command
        ref: "negative controls in a scratch copy: browserRequired forced to true -> self-test FAIL (1 of 41) on the planning-only case; first pull_request path narrowed to accrue_admin/lib/** -> FAIL paths drifted; accrue/** removed from push -> FAIL paths drifted"
        status: pass
      - kind: command
        ref: "live: --sha 02682685b4f1ffbd5d87dceb1ad2e238d53acdc2 --event pull_request --pr-base origin/main prints GREEN, 19 success, 8 PR paths checked, 0 match; the same SHA without --pr-base still prints RED: no pull_request run exists; --sha 17a608cc --event pull_request --pr-base 7971753a prints GREEN with the browser run judged"
        status: pass
    human_judgment: false
  - id: C2
    description: SL-E table agreement fails when LAND-03's checkbox disagrees with its Complete traceability row
    requirement: LAND-03
    verification:
      - kind: command
        ref: "negative control in a git clone --no-local scratch clone: baseline verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement rc 0; baseline PASS (12 parsed, 10 complete, 10 evidenced); LAND-03 checkbox reverted to [ ] with the traceability row left Complete -> FAIL: disagreement for LAND-03: bullet on line 27 is \"- [ ]\" but traceability row on line 72 says \"Complete\", rc 1; clone removed afterwards"
        status: pass
    human_judgment: false
---

# Phase 250 Plan 07: Post-merge Close Summary

Phase 250 is closed: LAND-02 and LAND-03 are Complete on the strength of the E/H verdicts and the PR #49 merge evidence, VERIFICATION is re-minted at 3/3 over seven SUMMARYs, and the close commits reach `main` through a squash-merged PR from `docs/250-close`.

## What was done

1. **250-06 SUMMARY** written from the orchestrator's verified facts, after re-running the 250-06 Task 3 verify (rc 0). Committed first on `docs/250-close`.
2. **Ledger**: iterations 10 (E) and 11 (H) and the post-merge main row (M, compared job by job with 35374333981).
3. **VERIFICATION**: SC2 gains the E and H helper verdicts; SC3 is verified with the parent count, the reachability count, the baseline helper and the recorded, not claimed list; `score: "3/3 success criteria verified"`; Gaps: none.
4. **Trackers**: REQUIREMENTS LAND-02 and LAND-03 `[x]` and `Complete`; ROADMAP ticks 250-06/07, Phase 250 `7/7 | Complete`; STATE records M, the backup ref, the checkpoint option, the carried D2 HIGH v1.68 deferral and the next step (Phase 251).
5. **Mint** twice (fixed point), the local close gates, the SL-E negative control, the pre-push guard.
6. **Close PR** from `docs/250-close`; squash-merged after every PR-path job was success on its exact head.

## Commit count

`actuals.commits: 5` is `git rev-list --count 3dd5f874..<close head>` on `docs/250-close`: the 250-06 SUMMARY commit, the 250-07 close commit, the control-record re-mint, the commit-count re-mint and the helper fix (which counts itself, by construction).

## Helper fix (found at the first close-PR head)

At the first close-PR head `02682685` (PR #51, ci.yml run 40251522630) every ci.yml job was `success` except the parked lane, and the Stripe trio was skipped as required. The helper still printed `RED: accrue_admin_browser.yml: no pull_request run exists`. That workflow's `pull_request.paths` (`accrue/**`, `accrue_admin/**`, its own file) match none of the 8 planning-only paths, so GitHub never creates the run; positive control: the same matcher counts 1 on `accrue_admin/x.ex`. The pull_request mode required that run unconditionally, a gap push mode does not have.

Fix at source in `250-ci-head-status.mjs`: an opt-in `--pr-base <ref>` computes the PR diff from `merge-base(<ref>, sha)` and lets the browser run be absent only when that diff is non-empty and matches none of the paths. A run that exists is judged in full. Without the flag the behaviour is unchanged. A self-test check reads the workflow file, so the pinned path list cannot drift silently. Controls: coverage F6.

## Close location

Checkpoint option **merge-close-pr**. The close commits are on `docs/250-close` (branched from `main` at M) and land on `main` only through the close PR, squash-merged with `--match-head-commit`. The close PR's own CI verdict postdates this commit and is recorded in the PR and the phase hand-off, not here (a commit cannot contain its own runs).

## Deviations from Plan

- **Branch instead of local main.** The plan has the close commit made on local `main` and pushed as `main:refs/heads/docs/250-close`. Per the orchestrator, it was committed on `docs/250-close` created from `main`; local `main` stays equal to `origin/main` until the PR merges. Same pushed content, no local-ahead `main`.
- **[Rule 1 - Bug] Verdict helper ignored the browser workflow's paths filter in pull_request mode.** Found at the first close-PR head; fixed at source with self-test and negative controls (coverage F6). The close PR head moved to carry the fix, and the helper is re-run there with `--pr-base origin/main`.
- **Close PR merged.** The plan put merging the close PR out of scope pending another yes; the maintainer gave that yes up front (squash, exact head, every PR-path job success except the parked lane).

## Known Stubs

None.

## Threat Flags

None. Planning documents only.

## Self-Check: PASSED

Seven SUMMARYs are tracked in the phase directory; the mint is a fixed point; SL-E, SL-G and the executable-UAT gates pass on the close commit.
