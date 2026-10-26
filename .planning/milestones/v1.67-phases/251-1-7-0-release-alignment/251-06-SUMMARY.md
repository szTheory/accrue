---
phase: 251-1-7-0-release-alignment
plan: "06"
subsystem: release-automation
status: complete
completed: 2026-10-26
requirements-completed: []
tags: [release-please, merge-gate, hex-publish, hexdocs, rls-01, rls-02]
requires: [251-05]
provides:
  - fail-closed 1.7.0 release merge gate (checks 0-9) with six negative controls and a hook-without-control control
  - release PR 55 merged as merge commit M 20a3982c2b0fe834773efcd7be803d19981a2b26 (parents FREEZE_SHA, A)
  - accrue, accrue_admin and accrue_portal 1.7.0 tagged at M, released on GitHub, published to hex.pm with docs and live on hexdocs
affects: [251-07]
key-files:
  created:
    - .planning/phases/251-1-7-0-release-alignment/251-release-merge-gate.sh
    - .planning/phases/251-1-7-0-release-alignment/251-06-SUMMARY.md
  modified:
    - .planning/phases/251-1-7-0-release-alignment/251-RELEASE-LEDGER.md
    - .planning/phases/251-1-7-0-release-alignment/251-VERIFICATION.md
    - .planning/phases/251-1-7-0-release-alignment/251-UAT.md
decisions:
  - "The gate's test hooks (--ghrel-output, RELEASE_PLEASE_BIN) FAIL check 0 unless --control is also passed, so a leftover hook can never stand in for the real github-release dry run."
  - "Check 3 judges the release head with --pr-base origin/main (refreshed by fetch, live value proven by check 2), not local main, which is not kept as a mirror of origin."
  - "Check 9 also requires the 'Would tag 0 releases' completion line, beyond the plan's marker, exit 0, no pullNumber and no non-zero Would tag."
  - "Main push verdict at M accepted by orchestrator ruling: the two baseline-success live Stripe jobs skipped at M are recorded, not claimed (path-classifier skip, trigger_class=irrelevant; same jobs success at FREEZE_SHA run 40344886087). The helper and gates are unchanged."
actuals:
  tokens: 8500
  tasks: 3
  commits: 3
plan_head_before: a3f39577075e358e98536096ff4ec48fe32900be
plan_head_after: 3c1a1db39e083f522525faea0e3cf86ae2acfe8d
coverage:
  - id: P1
    description: the merge gate, not a person, decided the merge; the real pre-merge run exited 0 with hooks off, and the RAW-head, moved-main, saved stale dry run, empty, missing and failing-command controls each fail the named check
    requirement: RLS-02
    verification:
      - kind: command
        ref: "env -u RELEASE_PLEASE_BIN bash .planning/phases/251-1-7-0-release-alignment/251-release-merge-gate.sh --pr 55 --sha 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 --freeze-sha 6e285bff6a6c10a1f79b19008cd679b16e4d8be6 --baseline-run 40281358498 (pre-merge, rc 0, 10 PASS)"
        status: pass
      - kind: command
        ref: "! bash 251-release-merge-gate.sh --sha 24f8a34220070ee7148ecc1b9f37d922386bf3c9 ... (FAIL 1, 3, 5) && ! bash 251-release-merge-gate.sh --freeze-sha db1b6d85b8ecb94d1d4d781591a6bf0ad88a2401 ... (FAIL 2) && ! bash 251-release-merge-gate.sh --ghrel-output .planning/251-evidence.local/251-04-ghrel-before.out ... (FAIL 9, pullNumber 50)"
        status: pass
      - kind: command
        ref: "! bash 251-release-merge-gate.sh --ghrel-output <empty> ... && ! bash 251-release-merge-gate.sh --ghrel-output <missing> ... && ! RELEASE_PLEASE_BIN=false bash 251-release-merge-gate.sh ... (each FAIL 9)"
        status: pass
    human_judgment: false
  - id: P2
    description: release PR 55 was merged with gh pr merge --merge --match-head-commit A into a two-parent merge commit M whose parents are FREEZE_SHA and A
    requirement: RLS-01
    verification:
      - kind: command
        ref: "test \"$(git rev-list --parents -n 1 20a3982c2b0fe834773efcd7be803d19981a2b26 | cut -d' ' -f2-)\" = \"6e285bff6a6c10a1f79b19008cd679b16e4d8be6 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2\""
        status: pass
    human_judgment: false
  - id: P3
    description: Release Please push run 40361348296 at M succeeded in all six jobs, and exactly three 1.7.0 tags point at M with three non-draft, non-prerelease GitHub releases
    requirement: RLS-02
    verification:
      - kind: command
        ref: "gh run view 40361348296 --repo szTheory/accrue --json jobs (Release Please, Release PR wedge check, Publish accrue, Publish accrue_admin, Publish accrue_portal, Linked release proof: success) && git ls-remote --tags origin 'refs/tags/accrue*-v1.7.0' (3 refs at 20a3982c) && gh release view <p>-v1.7.0 --json isDraft,isPrerelease ([false,false] x3)"
        status: pass
    human_judgment: false
  - id: P4
    description: hex.pm serves 1.7.0 with has_docs true and hexdocs serves the 1.7.0 readme with HTTP 200 for accrue, accrue_admin and accrue_portal
    requirement: RLS-02
    verification:
      - kind: command
        ref: "for p in accrue accrue_admin accrue_portal; do curl -fsS https://hex.pm/api/packages/$p/releases/1.7.0 | jq -r '[.version,.has_docs]|@tsv' (1.7.0 true) && curl -s -o /dev/null -w '%{http_code}' -L https://hexdocs.pm/$p/1.7.0/readme.html (200); done"
        status: pass
    human_judgment: false
  - id: P5
    description: main is green at M; ci.yml push run 40361348589 and browser run 40361348536 concluded success with 21 success jobs, and the two live Stripe jobs are recorded, not claimed (path-classifier skip, trigger_class=irrelevant; same jobs success at FREEZE_SHA run 40344886087)
    requirement: RLS-01
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 20a3982c2b0fe834773efcd7be803d19981a2b26 --event push --baseline-run 40281358498 (21 success jobs; only the two classifier-skipped Stripe jobs and the parked lane reported)"
        status: pass
      - kind: command
        ref: "node scripts/ci/provider_proof_automation.mjs --classify-trigger --event push --before 6e285bff6a6c10a1f79b19008cd679b16e4d8be6 --sha 20a3982c2b0fe834773efcd7be803d19981a2b26 --output <file> (should_run=false, trigger_class=irrelevant)"
        status: pass
    human_judgment: false
---

# Phase 251 Plan 06: Gated 1.7.0 Merge and Hex Publication Summary

A fail-closed merge gate decided the merge of release PR #55. The gate exited 0 at head A `2d3a4c62` with its test hooks off. #55 was then merged as a two-parent merge commit M = `20a3982c2b0fe834773efcd7be803d19981a2b26`. Release Please tagged, released and published `accrue`, `accrue_admin` and `accrue_portal` 1.7.0 to hex.pm with docs. I verified every publication fact read-only.

## Authorization (RLS-02 basis)

On 2026-10-26 the maintainer said, verbatim: "follow ur recs. i authorize release we want to release early and often at any natural stopping point that is release worthy". This is recorded in `.planning/STATE.md` (plan 01), `251-CONTEXT.md` and `251-VERIFICATION.md`.

## The gate

`251-release-merge-gate.sh --pr 55 --sha <A> --freeze-sha <FREEZE_SHA> --baseline-run 40281358498` runs every check and prints one `PASS:`/`FAIL:` line each. Every external command's exit status is captured before its output is matched.

| # | Check |
|---|-------|
| 0 | No test hook is active, or `--control` is passed |
| 1 | PR 55 is OPEN, not a draft, base `main`, title `chore: release main`, live head == `--sha` |
| 2 | Live `git ls-remote origin refs/heads/main` == FREEZE_SHA |
| 3 | `250-ci-head-status --event pull_request --pr-base origin/main` GREEN at the head |
| 4 | `250-ci-head-status --event push --baseline-run 40281358498` GREEN at FREEZE_SHA |
| 5 | The notes contract, manifest alignment, curated CHANGELOG and package docs (`RELEASE_PLEASE_PR` unset) pass on a `git archive` of the head |
| 6 | `verify_release_pr_scope.sh --pr 55 --version 1.7.0` |
| 7 | Merged `autorelease: pending` is `[]`; the open query returns `[55]` (positive control) |
| 8 | Controls first: three v1.6.0 tags, the three v1.6.0 releases, and Hex 200 for 1.6.0. Then for 1.7.0: no tags, release not-found, Hex exactly 404 |
| 9 | `release-please@17.6.0 github-release --dry-run` exits 0 and its non-empty output carries GHREL_MARKER and `Would tag 0 releases`, with no `pullNumber:` and no non-zero `Would tag`. The PR body has exactly the components `accrue: 1.7.0`, `accrue_admin: 1.7.0` and `accrue_portal: 1.7.0` |

GHREL_MARKER (`✔ Building strategies by path`) only shows that a dry run started building releases. Exit 0 plus the `Would tag 0 releases` line is the proof that it completed.

**Control outcomes** (outputs in `.planning/251-evidence.local/251-06-gate-*.out`):

| Control | rc | Failing checks |
|---------|----|----------------|
| `--sha RAW 24f8a342` | 1 | 1 (head is A), 3 (RAW RED), 5 (notes contract, 227 raw CHANGELOG lines, package docs) |
| `--freeze-sha db1b6d85` | 1 | 2 |
| `--ghrel-output 251-04-ghrel-before.out` | 1 | 9 (`pullNumber: 50`, `Would tag 3`) |
| `--ghrel-output` on an empty file | 1 | 9 (output empty) |
| `--ghrel-output` on a missing path | 1 | 9 (file does not exist) |
| `RELEASE_PLEASE_BIN=false` | 1 | 9 (dry run exited 1, output empty) |
| a hook without `--control` | 1 | 0 |
| real arguments (plan Task 1 verify) | 0 | none (10 PASS) |
| **pre-merge, `env -u RELEASE_PLEASE_BIN`, no `--ghrel-output`** (16:39:52Z to 16:40:14Z) | **0** | none (10 PASS, no hook note) |

The negatives ran twice: once with `--control` (so each fails on the check it targets) and once exactly as the plan's Task 1 verify, which passed in full.

## Merge and publication

- Re-check at 16:40:15Z: the PR 55 head was still A and OPEN, and live main was still FREEZE_SHA. Then the merge: `gh pr merge 55 --repo szTheory/accrue --merge --match-head-commit 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` returned rc 0.
- M = `20a3982c2b0fe834773efcd7be803d19981a2b26`. Its parents are `6e285bff…` (FREEZE_SHA) and `2d3a4c62…` (A).
- Release Please push run **40361348296** concluded `success`. Release Please, Release PR wedge check, Publish accrue, Publish accrue_admin, Publish accrue_portal and Linked release proof are all `success`.

| Package | Tag at M | GitHub release | hex.pm 1.7.0 `inserted_at` | has_docs | hexdocs |
|---------|----------|----------------|----------------------------|----------|---------|
| accrue | `accrue-v1.7.0` | https://github.com/szTheory/accrue/releases/tag/accrue-v1.7.0 | 2026-10-26T16:44:19Z | true | https://hexdocs.pm/accrue/1.7.0/readme.html 200 |
| accrue_admin | `accrue_admin-v1.7.0` | https://github.com/szTheory/accrue/releases/tag/accrue_admin-v1.7.0 | 2026-10-26T16:46:39Z | true | https://hexdocs.pm/accrue_admin/1.7.0/readme.html 200 |
| accrue_portal | `accrue_portal-v1.7.0` | https://github.com/szTheory/accrue/releases/tag/accrue_portal-v1.7.0 | 2026-10-26T16:48:50Z | true | https://hexdocs.pm/accrue_portal/1.7.0/readme.html 200 |

The remote has exactly three `accrue*-v1.7.0` tags. All three releases have isDraft false and isPrerelease false. PR 55 carries `autorelease: tagged`. The merged-pending query returns `[]`; its positive control, merged with `autorelease: tagged`, includes 55.

## Main push CI at M

I judged this only after all three packages were live on hex.pm (RESEARCH Pitfall 8).
- ci.yml push run 40361348589 concluded `success`, with 21 success jobs. Its only failure is the parked ratchet lane.
- Browser UAT run 40361348536 concluded `success`.
- The helper flagged two jobs that succeeded at the baseline and were skipped at M: `Stripe test-mode parity (mandatory periodic)` and `Stripe provider-proof incident reconciliation`. Both are **recorded, not claimed (path-classifier skip, trigger_class=irrelevant; same jobs success at FREEZE_SHA run 40344886087)**.
- Why they skipped: the M-vs-FREEZE_SHA diff is 11 release, doc and version files, and none of them is in the classifier's `RELEVANT_PATHS`. Replaying the classifier locally gives the same `should_run=false`.
- The orchestrator accepted this under the maintainer's "follow ur recs" authority. The helper and gates are unchanged.
- I did not use the one permitted `gh run rerun --failed`. No required job had failed, and a re-run cannot turn a classifier skip into a run.

## Remote writes (CONTEXT A6)

| UTC timestamp | Action | Target | Result |
|---------------|--------|--------|--------|
| 2026-10-26T16:40:15Z | pr-merge | szTheory/accrue#55, `--merge --match-head-commit 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2`, after the pre-merge gate exited 0 | rc 0, M = `20a3982c2b0fe834773efcd7be803d19981a2b26` |

There were no other remote writes: no re-run, no dispatch, no push, and no tag or release edit.

## Deviations from Plan

**1. [Rule 2 - fail-closed] Check 0 for test hooks.** The gate FAILs when a hook is set without `--control`, as Task 2 step 1 requires. Controls that use hooks therefore pass `--control`. The plan's exact verify, which passes no `--control`, still passes because each of its negatives still fails on check 9 or check 2.

**2. `--pr-base origin/main` in check 3.** Local `main` is not kept as a mirror of origin (251-04 deviation 3). The gate fetches first, and check 2 proves the live value.

**3. Stricter check 9.** It also requires the `Would tag 0 releases` line.

**4. Main push verdict.** The helper exited 1 at M because of the classifier skip. I stopped and reported. The orchestrator ruled to accept it as recorded, not claimed (see above).

**5. zsh word splitting.** My first pre-merge attempt built the command as a string, and zsh did not split it, so the gate never ran (rc 127). The merge was not attempted. I re-ran the gate and merge from a bash script that uses an argv array.

## Deferred Issues

- **v1.68 follow-up:** the 250 helper's push-mode baseline comparison (`250-ci-head-status.mjs`) should read the provider-proof classifier's `should_run=false` / `trigger_class=irrelevant` output. That way a baseline-success job skipped by the classifier is recognized automatically as "recorded, not claimed" instead of judged by hand.

## Self-Check: PASSED

- FOUND: `251-release-merge-gate.sh`, `251-RELEASE-LEDGER.md` and this SUMMARY.
- FOUND commits on docs/251-close: `57846fc2`, `3317cf93`, `3c1a1db3`.
- FOUND on the remote: M `20a3982c` on origin/main, and the three `*-v1.7.0` tags at M.
