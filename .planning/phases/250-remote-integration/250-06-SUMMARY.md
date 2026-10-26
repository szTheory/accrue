---
phase: 250-remote-integration
plan: "06"
subsystem: remote-landing
status: complete
completed: 2026-10-25
requirements-completed: []
tags: [merge, merge-commit, reachability, post-merge-ci, baseline-comparison, local-main-reconcile]
dependency-graph:
  requires: [250-05]
  provides: [merge commit M on origin/main with history intact, post-merge main push run measured against 35374333981, local main reconciled with a backup ref]
  affects: [250-07]
tech-stack:
  added: []
  patterns: [match-head-commit merge, pre-merge SHA list reachability count, baseline-run job-by-job comparison]
key-files:
  created:
    - .planning/phases/250-remote-integration/250-06-SUMMARY.md
  modified: []
key-decisions:
  - "Checkpoint option chosen: merge-close-pr. The maintainer said \"i like squash merge but whatever works i authorize u\", then approved the follow-up plan (\"yes\" / \"yes that's right\"). PR #49 is a merge commit (history preservation is LAND-03's requirement); the follow-up close PR from docs/250-close is squash-merged, as the maintainer prefers."
  - "LAND-03 evidence exists after this plan, but LAND-02 and LAND-03 are marked Complete only by 250-07, together with the 3/3 VERIFICATION re-mint."
  - "The three jobs the helper lists as recorded, not claimed are not counted as passed, whatever their conclusion on M."
plan_head_before: 17a608ccdbc1512a31475e0804d46811d2059c4b
plan_head_after: 3dd5f8746b34497d345cd4d03c44f3756a159bab
actuals:
  tokens: 4000
  tasks: 3
  commits: 1
coverage:
  - id: R1
    description: Pre-merge readiness at the exact head H, immediately before the merge
    requirement: LAND-03
    verification:
      - kind: command
        ref: "gh pr view 49 --json headRefOid,mergeable,state reported headRefOid 17a608ccdbc1512a31475e0804d46811d2059c4b, OPEN, MERGEABLE; git merge-base --is-ancestor 7971753a2672383ecec18ccba274ef0ffd823a0d 17a608cc exited 0; node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 17a608ccdbc1512a31475e0804d46811d2059c4b --event pull_request printed GREEN, 20 jobs success (ci.yml run 40245573325, accrue_admin_browser.yml run 40245573321); git ls-remote --tags origin listed no v1.63-v1.66 tag; git rev-list 7971753a..17a608cc wrote 993 SHAs to .planning/250-premerge.local"
        status: pass
    human_judgment: false
  - id: SC3
    description: LAND-03 PR #49 is merged with a two-parent merge commit M, every pre-merge SHA is reachable from main, and the first post-merge push run on main meets run 35374333981 job by job
    requirement: LAND-03
    verification:
      - kind: command
        ref: "gh pr merge 49 --merge --match-head-commit 17a608ccdbc1512a31475e0804d46811d2059c4b produced M = 3dd5f8746b34497d345cd4d03c44f3756a159bab; git rev-list --parents -n 1 M prints M 7971753a2672383ecec18ccba274ef0ffd823a0d 17a608ccdbc1512a31475e0804d46811d2059c4b (3 SHAs); git merge-base --is-ancestor H M exits 0; gh pr view 49 --json state,mergeCommit gives MERGED M"
        status: pass
      - kind: command
        ref: "git rev-list M | grep -c -x -F -f .planning/250-premerge.local prints 993, equal to wc -l of the list (0 of 993 pre-merge SHAs missing)"
        status: pass
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 3dd5f8746b34497d345cd4d03c44f3756a159bab --event push --baseline-run 35374333981 prints GREEN, rc 0, 21 jobs success (ci.yml run 40247684345, accrue_admin_browser.yml run 40247684340); recorded, not claimed: Stripe provider-proof incident reconciliation (baseline skipped), Stripe test-mode parity (mandatory periodic) (baseline skipped), Admin UI ratchet guardrails [parked] (baseline failure). Release Please push run 40247684348 success"
        status: pass
      - kind: command
        ref: "git rev-parse -q --verify refs/backup/main-pre-250-merge gives 1cc8322e7b1528d2a14e2a592b1e89999de7828b; git merge-base --is-ancestor main origin/main exited 0 before the fast-forward; git rev-list --left-right --count main...origin/main prints 0 0"
        status: pass
    human_judgment: false
---

# Phase 250 Plan 06: Merge PR #49 Summary

PR #49 (`integration/v1.63-v1.66`) landed on `main` as the two-parent merge commit `3dd5f874`. All 993 pre-merge commits are reachable from `main`, the first push run on `main` is GREEN against the bar of run 35374333981, and local `main` was fast-forwarded behind a backup ref.

This plan was executed inline by the phase orchestrator; this SUMMARY records its verified facts and is committed by 250-07.

## Readiness (Task 1)

| Item | Value |
|------|-------|
| PR head H | `17a608ccdbc1512a31475e0804d46811d2059c4b` (body-only successor of E) |
| Evidence head E | `ece41e51eb0e6ab4f030d33501cd811188542686` |
| Old origin/main | `7971753a2672383ecec18ccba274ef0ffd823a0d` |
| Pre-merge commits | 993 (`git rev-list 7971753a..H`, in untracked `.planning/250-premerge.local`) |
| Helper at E | GREEN, 20 success (ci.yml 40243045805, browser 40243045812) |
| Helper at H | GREEN, 20 success (ci.yml 40245573325, browser 40245573321) |
| Base ancestry | `git merge-base --is-ancestor 7971753a H` exit 0 |
| Milestone tags on origin | none for v1.63-v1.66 |
| Rollback | `git revert -m 1 3dd5f874` (from the PR body) |

## Decision (checkpoint)

**merge-close-pr.** The maintainer: "i like squash merge but whatever works i authorize u", then "yes" / "yes that's right" to the follow-up plan. This is an authorization of an irreversible external operation, not an acceptance judgment.

## Merge and post-merge run (Task 3)

- `gh pr merge 49 --merge --match-head-commit 17a608cc...` produced **M = `3dd5f8746b34497d345cd4d03c44f3756a159bab`**, parents `7971753a` and `17a608cc`. No `--delete-branch`, so the evidence links in the body still resolve.
- Reachability: 993 of 993 pre-merge SHAs are in `git rev-list M`.
- Push runs on M: CI `40247684345` success, AccrueAdmin Browser UAT `40247684340` success, Release Please `40247684348` success.

Job-by-job comparison, M against baseline 35374333981 (helper `--event push --baseline-run 35374333981`):

| Job | Baseline 35374333981 | M (40247684345) | Verdict |
|-----|----------------------|-----------------|---------|
| Docs and bash contracts (shift-left) | success | success | success |
| Release gate (Floor; 1.19.0/28.0) | success | success | success |
| Release gate (Primary; otel off) | success | success | success |
| Release gate (Primary; otel on) | success | success | success |
| Release gate (Primary; sigra on) [advisory] | success | success | success |
| Release manifest SSOT (REL-02) | success | success | success |
| iOS offline client package compatibility | success | success | success |
| Phase 18 Stripe Tax gate | success | success | success |
| Stripe provider-proof trigger classifier | success | success | success |
| Admin group contracts (Phase 190) | success | success | success |
| Admin hardening guardrails (Phase 192) | success | success | success |
| Admin Phase 200 deterministic guardrails | success | success | success |
| Admin UI ratchet self-tests | success | success | success |
| Host integration (required deterministic gate) | success | success | success |
| Host Docker boot smoke | success | success | success |
| Playwright E2E shard 1/3, 2/3, 3/3 | success | success | success |
| Admin drift and docs | success | success | success |
| Annotation sweep | success | success | success |
| Browser UAT (accrue_admin_browser.yml 40247684340) | - | success | success |
| Stripe provider-proof incident reconciliation | skipped | success | recorded, not claimed (baseline skipped) |
| Stripe test-mode parity (mandatory periodic) | skipped | success | recorded, not claimed (baseline skipped) |
| Admin UI ratchet guardrails [parked] | failure | failure | recorded, not claimed (parked, D1) |

## Local main reconcile

`refs/backup/main-pre-250-merge` = `1cc8322e` was written first; `main` was an ancestor of `origin/main` and was fast-forwarded. `main...origin/main` = `0 0`.

## Task 3 verify (re-run by 250-07 on 2026-10-25)

```
250-ci-head-status: GREEN at 3dd5f8746b34497d345cd4d03c44f3756a159bab (event push)
  note: ci.yml: recorded, not claimed (baseline skipped): Stripe provider-proof incident reconciliation
  note: ci.yml: recorded, not claimed (baseline skipped): Stripe test-mode parity (mandatory periodic)
  note: ci.yml: recorded, not claimed (baseline failure): Admin UI ratchet guardrails [parked]
  note: ci.yml: run 40247684345 attempt 1 head_sha 3dd5f8746b34497d345cd4d03c44f3756a159bab
  note: accrue_admin_browser.yml: run 40247684340 attempt 1 head_sha 3dd5f8746b34497d345cd4d03c44f3756a159bab
  success jobs: 21
1cc8322e7b1528d2a14e2a592b1e89999de7828b
rc=0
```

Parents `3dd5f874 7971753a 17a608cc`; pre-merge list 993 lines, 993 found in `git rev-list M`.

## Deviations from Plan

- Executed inline by the orchestrator rather than by a spawned executor; the SUMMARY is written afterwards from the verified facts, and its Task 3 verify was re-run before writing.
- `actuals.commits: 1` is `git rev-list --count H..M`: the GitHub-authored merge commit M. This plan made no local commits; its SUMMARY is committed in 250-07.

## Known Stubs

None.

## Threat Flags

None. No source change.

## Self-Check: PASSED

M exists on origin/main with parents 7971753a and 17a608cc; `refs/backup/main-pre-250-merge` resolves; the Task 3 verify exits 0.
