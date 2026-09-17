## What a reviewer would reject this for

- Two required lanes are waived, not green, at the frozen head SHA: `docs-contracts-shift-left` and `release-gate` (all three required matrix cells: Floor, Primary, Primary+OpenTelemetry).
  Both failed on a real GitHub Actions dispatch, [run 35232417814](https://github.com/szTheory/accrue/actions/runs/35232417814/jobs).
- Both root causes are real, root-caused, and already fixed and verified on the milestone line at commit `11d42183` -- but that fix was never pushed to the frozen candidate SHA.
  Re-verify against the milestone line, not the frozen SHA: `mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0` (46/46).
- The full per-lane disposition, including these two waived rows, is committed and joined 1:1 against the live ledger.
  Verify: `node scripts/ci/verify_window_dispositions.mjs --records .planning/phases/232-bounded-hygiene-release-handoff/232-WINDOW-DISPOSITIONS.json --rendered .planning/phases/232-bounded-hygiene-release-handoff/232-WINDOW-DISPOSITIONS.md --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism`.
- The `admin-ui-ratchet-guardrails` lane stays parked and waived on the merits, not fixed -- `ledger.baseline.json` reports `frozen: false`.
  See `.planning/WINDOWS.md` row 11.
- Deliberately not in this cleanup: no remote branch or tag is deleted or renamed, classification-only, per the maintainer's decision.
  See [`232-HYGIENE-DISPOSITIONS.md`](https://github.com/szTheory/accrue/blob/gsd/milestone-v1.62-release-integration-hygiene/.planning/phases/232-bounded-hygiene-release-handoff/232-HYGIENE-DISPOSITIONS.md); one adopter-named remote branch and its origin peer keep their current names, rename deferred to a future capsule mint.

## Provenance

Link `integration/v1.62-candidate-recut` to see how this got here; diff `review/v1.62-candidate-code-only` to see what source behavior changed -- the former is a merge-plus-cherry-picks reconstruction with no independent review value of its own, the latter is the code-only line worth reading line by line.

- **Head branch:** `integration/v1.62-candidate-recut`.
- **Head SHA:** `c1397fe9127a9b4b2b1d3a0758d57879b14f4604` -- captured while drafting this body.
  The maintainer re-cuts a fresh candidate after phase 232's own closing plan lands, and this PR is opened from that later SHA; re-point only these two lines and the `git revert` line below, per `232-11-SUMMARY.md`.

## What changed, and how to check it

- The re-cut unions the milestone line with the published 1.5.1 release state, proved lossless by blob identity (single-touched paths) and hunk union (co-touched paths), never diffstat.
  Verify: `node scripts/ci/verify_recut_candidate.mjs --record .planning/phases/232-bounded-hygiene-release-handoff/232-ROLLBACK-POINT.json --expected-repository szTheory/accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain --require-supersession --require-union-hunks` -- `inspected=447 co_touched=7 drifted=0`.
- The declared 13-job merge-blocking cohort was re-derived live at the frozen SHA and matched the previously-declared set with zero drift.
  Every lane's disposition is fixed-and-proved or waived-with-owner-and-cause, never silently red; `.planning/WINDOWS.md` reports `open_count: 0`.
- Release Please is proven ready to produce a version-and-changelog-consistent release PR by a side-effect-free dry run: 1.5.1 -> 1.6.0 lockstep across all three packages, 7 planned updates, zero truncation.
  Archived at [`232-RELEASE-PR-DRYRUN.log`](https://github.com/szTheory/accrue/blob/gsd/milestone-v1.62-release-integration-hygiene/.planning/phases/232-bounded-hygiene-release-handoff/232-RELEASE-PR-DRYRUN.log); re-run with `bash scripts/ci/verify_release_pr_readiness.sh`.
- The untracked-path/worktree/debug-session/remote-branch classification that gated this cleanup is committed and fails closed both ways (completeness and soundness).
  It structurally cannot express deleting a remote branch -- every `remote_branch` row carries `retained` or `superseded`, never a deletion.
  Re-minted at the end of this phase so it also covers the re-cut branch the phase itself published: 25 rows, joined 1:1 against live repository state.
  Verify: `node scripts/ci/verify_hygiene_dispositions.mjs --records .planning/phases/232-bounded-hygiene-release-handoff/232-HYGIENE-DISPOSITIONS.json --rendered .planning/phases/232-bounded-hygiene-release-handoff/232-HYGIENE-DISPOSITIONS.md --expected-repository szTheory/accrue --require-completeness --require-soundness --require-determinism` -- exits 0.
- The bounded cleanup pass is command-backed and capped, never open-ended: 8 numbered findings across 2 passes, one commit per finding.
  Verify: `python3 -c "import json; d=json.load(open('.planning/phases/232-bounded-hygiene-release-handoff/232-CLEANUP-FINDINGS.json')); print(len(d['rows']), d['passes_taken'])"` -> `8 2`.
- Two known transitions, both recorded rather than silently flipped: the never-git-tracked `.tool-versions` is now tracked on this line.
  Verify: `git ls-files -- .tool-versions`; and the degraded `phase-200` shadow directory is gone -- verify: `ls .planning/phases/200-idempotent-verification-sign-off` exits non-zero, leaving only the good, committed archive copy under `.planning/milestones/v1.54-phases/`.

## Rollback

One command, reverting the re-cut merge itself: `git revert -m 1 --no-edit 3f42158d5cd3ffb7134685ae2856074cf544e008`.

## Scope

- Every referenced change maps to `REL-04`, `REL-05`, `HYG-01`, `HYG-02`, or `HYG-03`, or to a numbered row in `232-CLEANUP-FINDINGS.json`.
  See [the findings file](https://github.com/szTheory/accrue/blob/gsd/milestone-v1.62-release-integration-hygiene/.planning/phases/232-bounded-hygiene-release-handoff/232-CLEANUP-FINDINGS.json). Nothing else is in this PR.
- No remote branch or tag is deleted, moved, force-pushed, or rewritten by anything in this PR.
  Every disposition is `retained` or `superseded`, per the structural invariant `232-HYGIENE-DISPOSITIONS.md` enforces (D-47).
- This PR does not merge a Release Please PR, publish to Hex, or move a tag; it only opens (or updates) one integration pull request for review.
  Unchanged before and after: `gh pr list --state open --search "chore: release"` and `git ls-remote --tags origin | wc -l`.
