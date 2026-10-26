# Phase 251 Release Ledger

This ledger is transcribed from `.planning/251-remote-writes.local`, which is git-ignored and was written at the moment of each write. It is excluded from `covered_files` because it records SHAs of commits it cannot be part of.

## Remote writes (CONTEXT A6)

| UTC timestamp | Action | Target | Result |
|---------------|--------|--------|--------|
| 2026-10-26T14:31:41Z | push | `refs/heads/ci/release-please-repair` (normal push, no force) | ok, head `8a9c1c99337b1b87dda6b02fc9f62d0803d5c744` |
| 2026-10-26T14:32:08Z | pr-create | szTheory/accrue#54 (base main) | ok |
| 2026-10-26T14:59:31Z | pr-merge | szTheory/accrue#54, `--squash --match-head-commit 8a9c1c99...` | rc 0, squash `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` |
| 2026-10-26T15:21:34Z | remove-label | szTheory/accrue#50, `autorelease: pending` | rc 0 (main freeze starts) |
| 2026-10-26T15:22:24Z | workflow-dispatch | `release-please.yml` on main | rc 0, run 40348672308 |
| 2026-10-26T15:53:00Z | push | `refs/heads/release-please--branches--main` (plain fast-forward from RAW, no force) | ok, `24f8a342..2d3a4c62`, A = `2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` |
| 2026-10-26T16:40:15Z | pr-merge | szTheory/accrue#55, `--merge --match-head-commit 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` (after the pre-merge gate exited 0 at 16:40:14Z, hooks off) | rc 0, merge commit M = `20a3982c2b0fe834773efcd7be803d19981a2b26` |

## Identifiers

| Key | Value |
|-----|-------|
| N (fix PR) | 54 |
| F (fix PR exact head) | `8a9c1c99337b1b87dda6b02fc9f62d0803d5c744` |
| S (squash commit on main) | `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` (tree equal to F's tree; base was `db1b6d85`) |
| FREEZE_SHA | `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` (= S) |
| R (fresh release PR) | 55, `chore: release main`, head branch `release-please--branches--main` |
| RAW (R's raw release-please head) | `24f8a34220070ee7148ecc1b9f37d922386bf3c9` (parent = FREEZE_SHA) |
| WT_T1 (core alignment commit) | `3eb2beac10ee995c4b61f13fb8f2e14b9736fc74` |
| A (aligned release PR head = WT_T2) | `2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` (2 commits above RAW) |
| ci.yml pull_request run at A | 40353699704 (GREEN by `250-ci-head-status --pr-base origin/main`, 20 success jobs with browser UAT; parked ratchet lane failure allowed, also red at F and S) |
| Browser UAT pull_request run at A | 40353699699 (success) |
| ci.yml pull_request run at F | 40340488190 (GREEN, 19 success jobs) |
| ci.yml push run at S | 40344886087 (GREEN vs baseline run 40281358498, 22 success jobs) |
| Release Please push run at S | 40344886221 (`failure`: Release Please=success, Release PR wedge check=failure) |
| Release Please dispatch run at FREEZE_SHA | 40348672308 (`success`: Release Please=success, Release PR wedge check=success) |
| GHREL_MARKER | `✔ Building strategies by path` |
| M (release merge commit on main) | `20a3982c2b0fe834773efcd7be803d19981a2b26`, parents FREEZE_SHA `6e285bff...` and A `2d3a4c62...` |
| RP_RELEASE (Release Please push run at M) | 40361348296 (`success`) |

## Detector live positive control (run 40344886221)

```
##[error]merged release PR(s) still labelled autorelease: pending (50); release-please will not open a new release PR until the label is removed
```

## Stale-label hazard: before and after (read-only `release-please@17.6.0 github-release --dry-run`)

- Before removal (rc 0): `✔ Would tag 3 releases:` for `accrue-v1.7.0`, `accrue_admin-v1.7.0` and `accrue_portal-v1.7.0`, at sha `b4310a3937c5449ae5557c565d6403511ae715ad`, `pullNumber: 50`.
- After removal (rc 0): `✔ Would tag 0 releases:`, with no `pullNumber` line.
- Merged-pending query: `[50]` before, `[]` after. The negative control (`autorelease: nonexistent-251`) returned `[]`.

## 1.7.0 merge gate (plan 251-06)

Gate: `.planning/phases/251-1-7-0-release-alignment/251-release-merge-gate.sh` (checks 0-9). Outputs are in `.planning/251-evidence.local/251-06-gate-*.out` (git-ignored).

| Run (UTC) | Arguments | rc | Failing checks |
|-----------|-----------|----|----------------|
| 2026-10-26T16:34:00Z (control, completed) | `--sha RAW 24f8a342...` | 1 | 1 (head is A, not RAW), 3 (RAW is RED), 5 (notes contract, curated CHANGELOG 227 raw lines, package docs) |
| 2026-10-26T16:34:25Z (control, completed) | `--freeze-sha db1b6d85...` | 1 | 2 (live main is 6e285bff) |
| 2026-10-26T16:34:44Z (control, completed) | `--control --ghrel-output 251-04-ghrel-before.out` | 1 | 9 (`pullNumber: 50`, `Would tag 3 release`, no `Would tag 0 releases`) |
| 2026-10-26T16:35:02Z (control, completed) | `--control --ghrel-output <empty file>` | 1 | 9 (output empty) |
| 2026-10-26T16:35:21Z (control, completed) | `--control --ghrel-output <missing path>` | 1 | 9 (file does not exist) |
| 2026-10-26T16:35:40Z (control, completed) | `--control` + `RELEASE_PLEASE_BIN=false` | 1 | 9 (dry run exited 1, output empty) |
| 2026-10-26T16:36:01Z (control, completed) | `--ghrel-output 251-04-ghrel-after.out` without `--control` | 1 | 0 (test hook set without `--control`) |
| 2026-10-26T16:36:20Z (control, completed) | `--control --ghrel-output 251-04-ghrel-after.out` | 0 | none (the saved clean dry run parses as clean) |
| 2026-10-26T16:37:11Z-16:39:13Z (plan Task 1 verify) | the plan's six negatives without `--control`, then the real arguments | negatives 1, positive 0 | positive: 10 PASS, 0 FAIL |
| 2026-10-26T16:39:52Z-16:40:14Z (pre-merge) | `env -u RELEASE_PLEASE_BIN bash 251-release-merge-gate.sh --pr 55 --sha 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 --freeze-sha 6e285bff6a6c10a1f79b19008cd679b16e4d8be6 --baseline-run 40281358498` | 0 | none: 10 PASS (0-9), no `NOTE: test hook` |

Re-check at 16:40:15Z, immediately before the merge: PR 55 head `2d3a4c62...` OPEN, live origin main `6e285bff...`.

## Publication (Release Please run 40361348296 at M, event push, conclusion success)

| Job | Job ID | Conclusion |
|-----|--------|------------|
| Release Please | 121707323355 | success |
| Release PR wedge check | 121707729428 | success |
| Publish accrue | 121707729608 | success |
| Publish accrue_admin | 121709575900 | success |
| Publish accrue_portal | 121710904678 | success |
| Linked release proof | 121712107403 | success |

| Package | Tag -> commit | GitHub release (draft, prerelease) | hex.pm 1.7.0 `inserted_at` | `has_docs` | hexdocs `/1.7.0/readme.html` |
|---------|---------------|-------------------------------------|----------------------------|------------|------------------------------|
| accrue | `accrue-v1.7.0` -> `20a3982c...` | https://github.com/szTheory/accrue/releases/tag/accrue-v1.7.0 (false, false), published 16:40:43Z | 2026-10-26T16:44:19.763833Z | true | 200 |
| accrue_admin | `accrue_admin-v1.7.0` -> `20a3982c...` | https://github.com/szTheory/accrue/releases/tag/accrue_admin-v1.7.0 (false, false), published 16:40:44Z | 2026-10-26T16:46:39.952626Z | true | 200 |
| accrue_portal | `accrue_portal-v1.7.0` -> `20a3982c...` | https://github.com/szTheory/accrue/releases/tag/accrue_portal-v1.7.0 (false, false), published 16:40:46Z | 2026-10-26T16:48:50.271493Z | true | 200 |

- `git ls-remote --tags origin 'refs/tags/accrue*-v1.7.0'`: exactly three refs, all `20a3982c2b0fe834773efcd7be803d19981a2b26` (lightweight tags; no peeled `^{}` lines).
- PR 55 labels: `["autorelease: tagged"]`. Merged-pending query: `[]`. Its positive control (merged `autorelease: tagged`) returns `[55,46,42,39,30]`.
- Responses are saved in `.planning/251-evidence.local/251-06-publish/`.

## Main push CI at M

Judged after all three packages were verified on hex.pm (RESEARCH Pitfall 8):
`node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 20a3982c2b0fe834773efcd7be803d19981a2b26 --event push --baseline-run 40281358498 --wait-minutes 120` exited 1:

```
250-ci-head-status: RED at 20a3982c2b0fe834773efcd7be803d19981a2b26 (event push)
  note: ci.yml: recorded, not claimed (baseline failure): Admin UI ratchet guardrails [parked]
  note: ci.yml: run 40361348589 attempt 1 head_sha 20a3982c2b0fe834773efcd7be803d19981a2b26
  note: accrue_admin_browser.yml: run 40361348536 attempt 1 head_sha 20a3982c2b0fe834773efcd7be803d19981a2b26
  RED: ci.yml: baseline success job regressed: Stripe test-mode parity (mandatory periodic): skipped (job 121707457058)
  RED: ci.yml: baseline success job regressed: Stripe provider-proof incident reconciliation: skipped (job 121707459139)
  success jobs: 21
```

- ci.yml push run 40361348589 concluded `success`; its only `failure` is the parked ratchet lane (also red at F, S and A). Browser UAT push run 40361348536 concluded `success`.
- The two RED rows are `skipped`, not failed. `Stripe provider-proof trigger classifier` succeeded and classified the push as `should_run=false`, `trigger_class=irrelevant`: the M diff against FREEZE_SHA is the 11 release files (manifest, 3x mix.exs, 3x CHANGELOG, 2 READMEs, first_hour.md, release-notes.md), none of which matches `RELEVANT_PATHS` in `scripts/ci/provider_proof_automation.mjs`. Replaying the classifier locally with `--before 6e285bff... --sha 20a3982c...` gives the same output. At the baseline (db1b6d85) and at S both jobs ran and succeeded.
- The helper's rule "a baseline-success job now skipped is RED" is a deliberate strictness and was not changed.
- The one permitted `gh run rerun --failed` was **not** used. No required job failed, and a failed-job re-run reruns only the parked lane; it cannot turn a classifier skip into a run. No re-run of any workflow was made.
- Verdict: **stopped and reported**. The publication is complete and verified; the main push verdict at M is RED under the helper's push rules for a reason that a re-run cannot change. That needs an orchestrator or maintainer decision.
