---
phase: 251-1-7-0-release-alignment
plan: "02"
subsystem: release-automation
status: complete
completed: 2026-10-26
requirements-completed: []
tags: [release-please, ci, wedge-detector, negative-controls, rls-01]
requires: [251-01]
provides:
  - release-please.yml without the stale-base reset/force push
  - release-pr-wedge-check job (merged-but-pending detector)
  - scripts/ci/verify_release_branch_repair_safety.sh (static rule + self-test), merge-blocking in release-manifest-ssot
affects: [251-03, 251-04]
key-files:
  created:
    - scripts/ci/verify_release_branch_repair_safety.sh
    - .planning/phases/251-1-7-0-release-alignment/251-02-SUMMARY.md
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/ci.yml
    - scripts/ci/verify_release_contract.sh
    - RELEASING.md
    - scripts/ci/README.md
    - .planning/phases/251-1-7-0-release-alignment/251-VERIFICATION.md
    - .planning/phases/251-1-7-0-release-alignment/251-UAT.md
decisions:
  - "Automation never writes the release branch with a forced push; a stale or empty release PR is a maintainer remedy (close, delete remote branch, dispatch)."
  - "The wedge detector is its own job (needs release, !cancelled()) that no publish or proof job needs."
  - "The static rule bans any forced git push in release-please.yml, not only pushes whose line names the release branch."
actuals:
  tokens: 8200
  tasks: 3
  commits: 5
plan_head_before: 69ecb53d1e2a668b6d2d99c04bb0dc4cd0f2a209
plan_head_after: 206e3242
coverage:
  - id: W1
    description: release-please.yml no longer force-resets the release branch; the legacy algorithm is proven to empty a release PR and the fixed one keeps all seven release files
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_branch_repair_safety.sh --self-test"
        status: pass
      - kind: command
        ref: "bash scripts/ci/verify_release_branch_repair_safety.sh --repo ."
        status: pass
    human_judgment: false
  - id: W2
    description: a merged release PR still labelled autorelease pending turns the Release Please workflow red via the release-pr-wedge-check job, which no publish job needs
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_contract.sh"
        status: pass
      - kind: command
        ref: "bash scripts/ci/verify_release_branch_repair_safety.sh --repo ."
        status: pass
    human_judgment: false
  - id: W3
    description: RELEASING.md and scripts/ci/README.md give the correct stale-PR and pending-label remedies and the legacy reset remedy is rejected
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_contract.sh"
        status: pass
    human_judgment: false
---

# Phase 251 Plan 02: Release-Please Workflow Fix Summary

The stale-base reset that emptied release PR #50 is deleted from `release-please.yml`, a separate `Release PR wedge check` job fails the workflow while a merged release PR is still labelled `autorelease: pending`, and a new merge-blocking verifier replays the legacy algorithm on a hermetic git fixture to prove it empties a release PR (and that the fix does not).

## What was built

- `scripts/ci/verify_release_branch_repair_safety.sh`. Static mode (`--repo <root>`, `--workflow <file>`) blanks comment lines and then rejects any forced `git push` (`--force`, `--force-with-lease`, `-f`, `+refspec`) and `git checkout -B "$release_branch" "$expected_base"`. It requires the detector query with an `exit 1` in a job that is not `release` and that no `needs:` names (inline, flow-list and block-list forms are parsed), and it requires the `verify_release_pr_scope.sh --pr` canary. All violations are reported, not only the first. `--self-test` embeds the verbatim db1b6d85 lines 177-195 and, when that object is in history, checks the embedded text is byte-identical to it. Fixture git runs with `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1`, identity is set locally inside the fixture only, and cleanup is an EXIT trap on the global `SELFTEST_TMP`.
- `release-please.yml`: the block from `expected_base=` to its closing `fi` is gone (reset, force push, second `release-pr`, re-fetch). The fetch, the release-branch checkout, the portal-lag repair and the scope canary stay. New job `release-pr-wedge-check` (`name: Release PR wedge check`, `needs: release`, `if: ${{ !cancelled() }}`, `ubuntu-24.04`, `timeout-minutes: 10`, `permissions: pull-requests: read`, `GH_TOKEN: secrets.RELEASE_PLEASE_TOKEN`, no checkout).
- `verify_release_contract.sh`: new `reject_fixed` (`<file> must not contain: <needle>`), plus N1-N6. The one legacy `require_fixed` force-push line became a `reject_fixed`. Every other assertion is unchanged.
- `ci.yml` `release-manifest-ssot`: new step `Release branch is never force-reset by automation (Phase 251)` right after "Verify linked release contract".
- `RELEASING.md` step 3 and `scripts/ci/README.md`: the correct remedies, plus a `Triage: verify_release_branch_repair_safety.sh` section.

Wedge-job placement: `grep -n -E '^ +needs:.*release-pr-wedge-check' .github/workflows/release-please.yml` is empty. The `needs:` lists are `publish-accrue: release`, `publish-accrue-admin: [release, publish-accrue]`, `publish-accrue-portal: [release, publish-accrue, publish-accrue-admin]` and `linked-release-proof: [release, publish-accrue, publish-accrue-admin, publish-accrue-portal]`. The verifier's placement control proves the rule would catch the job being added to one of them.

No path under `accrue/`, `accrue_admin/` or `accrue_portal/` changed (`git diff --name-only db1b6d85..HEAD` filtered for those prefixes is empty).

## Control evidence

Raw outputs are in `.planning/251-evidence.local/` (git-ignored): `251-02-selftest.out`, `251-02-live-neg.out`, `251-02-live-pos.out`, `251-02-pos-N0.out`, `251-02-pos-N0b.out` and `251-02-neg-N{1..6}.out`. The N-control copies were scratch directories; their paths are shown as `<copy>`.

### Verifier self-test (all controls in one run, rc 0)

- Provenance: `OK: embedded legacy fixture is byte-identical to db1b6d85 release-please.yml lines 177-195`
- Control A (FAIL, required):
  - `[verify_release_branch_repair_safety] FAIL: legacy.yml:21: forbidden reset of the release branch to the target-branch tip: git checkout -B "$release_branch" "$expected_base"`
  - `[verify_release_branch_repair_safety] FAIL: legacy.yml:22: forbidden force push (automation must never force-write the release branch): git push --force-with-lease origin HEAD:"$release_branch"`
- Control B (behavioral, bare-origin fixture with a docs-only commit on main): `negative control OK: legacy repair leaves 0 changed files (reproduces PR #50)`
- Positive (behavioral): `OK: positive control: fixed algorithm keeps all 7 release files in main...release`
- Positive (static): `OK: fixed.yml has no release-branch force write; wedge detector in job 'release-pr-wedge-check'; scope canary present`
- Missing detector: `FAIL: nodetector.yml: missing merged-but-pending wedge detector: --state merged --label 'autorelease: pending'`
- Comment-only detector: `FAIL: comment.yml: missing merged-but-pending wedge detector: --state merged --label 'autorelease: pending'`
- Placement (needs): `FAIL: needed.yml: wedge detector job 'release-pr-wedge-check' is named in a needs: list (a false positive could skip a publish job)`
- Placement (release job): `FAIL: inrelease.yml: wedge detector sits in the release job (it must be its own job so it cannot block publish outputs)`
- Missing canary: `FAIL: nocanary.yml: missing release-PR scope canary: bash scripts/ci/verify_release_pr_scope.sh --pr "$release_pr_number"`
- Forced-push shapes `--force`, `-f` and `+HEAD:` each fail with `forbidden force push`.
- Final line: `verify_release_branch_repair_safety: self-test PASS (control A, control B, positive, missing detector, comment, placement x2, missing canary, forced-push shapes x3)`

### Live tree

- Before the workflow edit (commit c2c51363, rc 1):
  - `[verify_release_branch_repair_safety] FAIL: .github/workflows/release-please.yml:183: forbidden reset of the release branch to the target-branch tip: git checkout -B "$release_branch" "$expected_base"`
  - `[verify_release_branch_repair_safety] FAIL: .github/workflows/release-please.yml:184: forbidden force push (automation must never force-write the release branch): git push --force-with-lease origin HEAD:"$release_branch"`
  - `[verify_release_branch_repair_safety] FAIL: .github/workflows/release-please.yml: missing merged-but-pending wedge detector: --state merged --label 'autorelease: pending'`
- After (rc 0): `[verify_release_branch_repair_safety] OK: .github/workflows/release-please.yml has no release-branch force write; wedge detector in job 'release-pr-wedge-check'; scope canary present`

### Contract needles N1-N6 (single-violation archive copies of the committed HEAD)

The unmodified copy PASSED first each time (`verify_release_contract: v1.59 OK`, `251-02-pos-N0.out` for N1-N3 and `251-02-pos-N0b.out` for N4-N6). Each copy then changes one thing:

| Needle | Single violation | FAIL output (rc 1) |
|--------|------------------|--------------------|
| N1 | append the force-push line to release-please.yml | `[verify_release_contract] <copy>/.github/workflows/release-please.yml must not contain: git push --force-with-lease origin HEAD:"$release_branch"` |
| N2 | append the `checkout -B` reset line | `[verify_release_contract] <copy>/.github/workflows/release-please.yml must not contain: git checkout -B "$release_branch" "$expected_base"` |
| N3 | delete only the detector-query line (diff shows exactly 1 removed line) | `[verify_release_contract] <copy>/.github/workflows/release-please.yml is missing: --state merged --label 'autorelease: pending'` |
| N4 | delete only the RELEASING.md line holding the label remedy | `[verify_release_contract] <copy>/RELEASING.md is missing: remove the label before the next release PR merges` |
| N5 | append ``reset it back to `main`, rerun Release Please.`` to RELEASING.md | ``[verify_release_contract] <copy>/RELEASING.md must not contain: back to `main`, rerun Release Please`` |
| N6 | append `- force-sync the branch.` to scripts/ci/README.md | `[verify_release_contract] <copy>/scripts/ci/README.md must not contain: force-sync` |

Other gates run: `verify_pipefail_grep_idiom.mjs --require-idiom-ban` PASS (0 offenders), `verify_no_home_paths.sh --repo` OK, `verify_ci_efficiency_contract.mjs --repo .` PASS, `verify_package_docs.sh` OK, and `actionlint` on both workflows clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `require_fixed` parsed a needle starting with `--` as a grep option**
- **Found during:** Task 2
- **Issue:** `grep -Fq "$needle"` with the needle `--state merged --label 'autorelease: pending'` made grep print its usage and exit non-zero, so the contract reported the needle missing even though it was present. This failed closed, so it never masked anything.
- **Fix:** `grep -Fq -e "$needle"` in `require_fixed`, and `reject_fixed` uses `-e` too. The pattern semantics are unchanged for every existing needle, and N0 (unmodified copy passes) plus N3 (needle deleted, so it fails) show that the needle is now matched correctly.
- **Commit:** 7698974f

**2. [Rule 3 - Blocking] N-control archive copies had no `accrue/deps`**
- **Found during:** Task 2 verify
- **Issue:** `verify_release_contract.sh` runs `verify_reference_scenario_contract.sh`, which runs `mix accrue.entitlements.reference_scenarios --check` inside the copy. A bare `git archive` copy has no deps, so the plan's "unmodified copy must PASS" step failed (`generated matrix drift`) for an unrelated reason.
- **Fix:** each copy is a clone of one base built from `git archive HEAD` plus copies of the live `accrue/deps` and `accrue/_build`. These are `cp -cR` copies, not symlinks (per the scratch-worktree footgun). Each control's single edit is applied after that clone, and `cmp` confirms the base workflow equals `HEAD`.
- **Files modified:** none (verification harness only)

**3. Strengthening, not a weakening:** the static force-push rule bans any forced `git push` anywhere in release-please.yml, not only on lines naming the release branch. This closes evasion through a renamed variable. The detector step reads the repository from `env: REPO: ${{ github.repository }}` rather than interpolating `${{ }}` inline in the script (the usual Actions hygiene). The contract needle (the query flags) is unaffected.

## Notes for 251-03 / 251-04

- Once this lands on `main`, every Release Please run there goes RED at `Release PR wedge check` until the `autorelease: pending` label is removed from merged PR #50. This is the intended signal, not a regression. The `release` job and publish jobs are unaffected, because nothing `needs` the wedge job. 251-03's label removal on #50 must come after this PR merges (CONTEXT A6), and the next dispatched run should then show the wedge check green.
- The wedge check uses `secrets.RELEASE_PLEASE_TOKEN`. If that secret is missing or expired, `gh` fails, and so does the job (fail-closed).
- The new CI step runs inside `release-manifest-ssot`, so the workflow-fix PR's exact head needs that job `success`. Its self-test needs only `git` and `mktemp` (no network). The provenance compare prints a `note:` line under the shallow CI checkout, which is expected.
- `RELEASING.md` step 3 now carries the remedy 251-03 follows: close a stale or empty PR, delete the remote `release-please--branches--main` and dispatch, and remove a stale pending label before the next release PR merges, never `github-release`.

## Self-Check: PASSED

- FOUND: scripts/ci/verify_release_branch_repair_safety.sh
- FOUND: c2c51363, 8fe1191a, 7698974f, be0d1e0c, 206e3242 (ancestors of HEAD)
