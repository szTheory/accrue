---
phase: 250-remote-integration
plan: "05"
subsystem: pre-merge-close
status: complete
completed: 2026-10-25
requirements-completed: [LAND-01]
tags: [close, covered-digest, executable-uat, sl-e, sl-g, sl-f, evidence-head, negative-control]
dependency-graph:
  requires: [250-04]
  provides: [pre-merge close commit E with LAND-01 Complete, body-only commit H naming E as the evidence head]
  affects: [250-06, 250-07]
tech-stack:
  added: []
  patterns: [evidence head recorded by a body-only successor commit, scratch-clone negative and positive controls]
key-files:
  created:
    - .planning/phases/250-remote-integration/250-05-SUMMARY.md
  modified:
    - scripts/ci/verify_release_contract.sh
    - .planning/phases/250-remote-integration/250-VERIFICATION.md
    - .planning/phases/250-remote-integration/250-UAT.md
    - .planning/phases/250-remote-integration/250-INTEGRATION-PR.md
    - .planning/STATE.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
key-decisions:
  - "E is the pre-merge close. It carries this SUMMARY, the re-minted VERIFICATION and UAT, and LAND-01 Complete. The PR body in E says the evidence head is recorded by the following body-only commit H."
  - "LAND-02 and LAND-03 stay Pending. LAND-02 is claimed in VERIFICATION SC2 at the last measured head P = 5ad01dee and is marked Complete only by 250-07, after the merge."
  - "The first close commit 7b1b5862 was pushed and went red on one Release gate cell (a SIGPIPE race in verify_release_contract.sh). It was fixed at source in 5561a9a9, and the close was re-made as a new E on top of the fix. 7b1b5862 is superseded and is not the evidence head."
  - "The plan's commit count cannot be measured from inside E (a commit cannot count itself). It is 4 by construction: 7b1b5862 (first close, superseded), 5561a9a9 (fix), E and H. E and H are recorded in .planning/250-shas.local and in the H body."
plan_head_before: 6fe35302df0fcc309e28a4985a0fb5371a06f50d
actuals:
  tokens: 9000
  tasks: 2
  commits: 4
coverage:
  - id: SC1
    description: LAND-01 publication hygiene holds across every commit pushed to integration/v1.63-v1.66 since the first push at 23bee494, on top of the 850-commit full-history scan and the 91-commit scan recorded in 250-CONTEXT
    requirement: LAND-01
    verification:
      - kind: command
        ref: "bash .planning/phases/250-remote-integration/250-prepush-guard.sh --hygiene-only --range 23bee4949045b7ac9361d954b24497bb749e771b..6fe35302df0fcc309e28a4985a0fb5371a06f50d prints guard: all checks passed (48 commits; secret/PII patterns, large-blob scan and milestone-tag pattern each fire on a positive control first; 0 home paths; census strict pass; 0 secret/e-mail/username hits; 0 blobs over 1 MiB outside the screenshot prefix; 0 v1.63-v1.66 tags on origin). The same command over 23bee494..E is re-run after E is committed and recorded in the H body"
        status: pass
      - kind: command
        ref: "bash .planning/phases/250-remote-integration/250-prepush-guard.sh --close passes before the push of E (fast-forward ancestry, current_phase 250, SL-G, SL-E, executable UAT, archive sweep, D-32, Phase 249 artifacts byte-unchanged, covered_files, hygiene, clean tracked tree, executable UAT for phase 250)"
        status: pass
    human_judgment: false
  - id: SC2
    description: LAND-02 every PR-path job of ci.yml and accrue_admin_browser.yml concludes success on the exact head SHA, without the visual-pending allowance, with the D1 exclusions only
    requirement: LAND-02
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 5ad01dee2c70087aa89fafdfb154f6e9d8068277 --event pull_request prints GREEN, rc 0, 20 jobs success (ci.yml run 40236926623, accrue_admin_browser.yml run 40236926603; 250-CI-LEDGER.md iteration 8). The parked ratchet lane fails by design; the Stripe trio and Mint visual baselines are skipped as required"
        status: pass
    human_judgment: false
  - id: F5
    description: verify_release_contract.sh v1.59 runbook checks no longer race SIGPIPE under pipefail (CI run 40241001658, job 121312543518, Release gate opentelemetry=on, V159ReleaseContractTest:49 reported a present needle as missing after printf write error Broken pipe)
    requirement: LAND-02
    verification:
      - kind: command
        ref: "mechanism control: bash with set -o pipefail on a 200000-line section; printf | grep -Fq needle reports the present needle missing 20/20, grep -Fq needle <<< section 0/20; an absent needle via the here-string still returns rc 1"
        status: pass
      - kind: command
        ref: "cd accrue && mix test test/accrue/docs/v159_release_contract_test.exs --repeat-until-failure 30: 30 consecutive rounds, 6 tests, 0 failures; bash scripts/ci/verify_release_contract.sh on the repo prints verify_release_contract: v1.59 OK"
        status: pass
      - kind: command
        ref: "negative controls on the V159ReleaseContractTest fixture set (ROOT_DIR copy): baseline rc 0 v1.59 OK; literal next action removed -> rc 1 missing job/next-action structure; bounded diagnostic removed -> rc 1 missing job-oriented bounded diagnostic entry point; Inspect the worker queue added under the v1.59 heading -> rc 1 has backend-first procedure wording"
        status: pass
    human_judgment: false
  - id: C1
    description: Close gates pass at E and the evidence is a fixed point
    requirement: LAND-01
    verification:
      - kind: command
        ref: "node .planning/phases/250-remote-integration/250-mint-close-artifacts.mjs run twice gives the same covered_files and covered_digest, and leaves the tree clean"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in; node scripts/ci/verify_executable_uat_contract.mjs --all-since 229; node scripts/ci/verify_executable_uat_contract.mjs --phase 250"
        status: pass
    human_judgment: false
  - id: C2
    description: Scratch-clone controls at E prove the close gates can fail on exactly the inputs they guard, and that the two SHA-recording files are the only digest exclusions that matter here
    requirement: LAND-01
    verification:
      - kind: command
        ref: "negative (a): 250-VERIFICATION.md status set to gaps_found; verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement prints FAIL: LAND-01 is marked Complete but the verification in .planning/phases/250-remote-integration carries status gaps_found rather than passed, rc 1 (baseline in the same clone PASS, 8 complete, 8 evidenced)"
        status: pass
      - kind: command
        ref: "negative (b): one byte appended to the covered 250-VISUAL-CLASSIFICATION.md; verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match prints FAIL: 250-VERIFICATION.md: covered_digest mismatch over 60 covered files, rc 1"
        status: pass
      - kind: command
        ref: "negative (c): the first 250-05-SUMMARY.md coverage entry set to human_judgment: true; verify_executable_uat_contract.mjs --all-since 229 prints FAIL: 250-05-SUMMARY.md coverage SC1: human_judgment must be false, rc 1"
        status: pass
      - kind: command
        ref: "positive (d): one byte appended to each of the excluded 250-INTEGRATION-PR.md and 250-CI-LEDGER.md; verify_artifact_fixed_point.mjs prints PASS (phase 250, artifacts: 2, edges: 60, digests checked: 1), rc 0"
        status: pass
    human_judgment: false
---

# Phase 250 Plan 05: Pre-merge Close Summary

Commit E closes the pre-merge half of Phase 250: VERIFICATION and UAT are re-minted over all five pre-merge SUMMARYs, SC1 (LAND-01) and SC2 (LAND-02) are claimed with re-runnable commands, LAND-01 is Complete, and a body-only commit H names E as the evidence head.

## What was done

1. **SUMMARY first**, so the generated UAT reads its coverage.
2. **VERIFICATION**: score `2/3`; SC1 and SC2 verified with commands, run IDs and the ledger row; SC3 not yet claimed (post-merge, 250-07).
3. **Trackers**: REQUIREMENTS marks LAND-01 `[x]` and `Complete`; LAND-02 and LAND-03 stay Pending. STATE records E as the pre-merge close; ROADMAP ticks 250-01..05.
4. **Body**: Provenance in E says the evidence head is recorded by the following body-only commit.
5. **Mint** twice (fixed point) and the guard in `--close` mode.
6. **Controls (a)-(d)** in a `git clone --no-local` scratch clone, then removed.
7. **First close `7b1b5862`** pushed; one Release gate cell went red (CI run 40241001658). Fixed at source in `5561a9a9`; this SUMMARY, the VERIFICATION and the UAT were re-minted and the close re-made as **E** on top of the fix.
8. Push E, helper at E; then **H** (body-only), publish, push, helper at H.

## Controls at E (scratch clone, removed afterwards)

Clone: `git clone --no-local` of the working repo, E's tree in place; each control is reverted before the next; the clone is removed afterwards.

| Control | Mutation | Gate | Output | rc |
|---------|----------|------|--------|----|
| baseline | none | SL-E, SL-G, exec-UAT `--all-since 229` | PASS (8 complete, 8 evidenced); PASS (edges 59, digests checked 1); PASS (22 phases, 431 tests) | 0 each |
| (a) negative | VERIFICATION `status: gaps_found` | SL-E | `FAIL: LAND-01 is marked Complete but the verification in .planning/phases/250-remote-integration carries status "gaps_found" rather than passed` | 1 |
| (b) negative | 1 byte appended to covered `250-VISUAL-CLASSIFICATION.md` | SL-G | `FAIL: .../250-VERIFICATION.md: covered_digest mismatch over 60 covered files` | 1 |
| (c) negative | 250-05 coverage SC1 `human_judgment: true` | exec-UAT `--all-since 229` | `FAIL: 250-05-SUMMARY.md coverage SC1: human_judgment must be false` | 1 |
| (d) positive | 1 byte appended to each of excluded `250-INTEGRATION-PR.md` and `250-CI-LEDGER.md` | SL-G | `PASS (... edges: 60, ... digests checked: 1)` | 0 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SIGPIPE race in the v1.59 runbook checks of `verify_release_contract.sh`**
- **Found during:** Task 2, CI at the first close commit `7b1b5862` (ci.yml run 40241001658, job 121312543518, `Release gate (Primary dev target; ... opentelemetry=on)`, 2081 tests, 1 failure: `V159ReleaseContractTest` "rejects backend-first wording", `printf: write error: Broken pipe`, then the wrong failure "missing job/next-action structure"). The same code passed at `5ad01dee`.
- **Issue:** under `set -euo pipefail`, `printf '%s\n' "$v159_section" | grep -Fq ...` lets grep exit on its first match; a printf still writing gets EPIPE and the pipeline fails, so a present needle reads as missing. In the `if` form the same race hides a real backend-first match.
- **Fix:** all three checks read a here-string (`grep -Fq ... <<<"$v159_section"`). No needle, pattern or message changed.
- **Controls:** coverage F5 (mechanism 20/20 vs 0/20; 30 consecutive rounds of the test file; each of the three checks still fails on a genuinely bad fixture).
- **Commit:** `5561a9a9`

### Process adaptations

- The plan's commit count (`actuals.commits: 4`) is fixed by construction rather than measured, because E cannot count itself and H follows it. `7b1b5862` is superseded as the close; the new E and H are in `.planning/250-shas.local`.

## Deferred Issues

- The same `printf|echo ... | grep -q` pattern under `pipefail` remains on 30 non-comment lines in 6 shell scripts of `scripts/ci`: `verify_ci_setup_diagnostics.sh`, `verify_admin_ui_ratchet_ci_contract.sh`, `verify_phase192_ci_contract.sh`, `verify_phase192_guardrail_contract.sh`, `verify_phase200_ci_contract.sh` and `verify_phase200_guardrail_contract.sh` (`git grep -nIE -e '(printf|echo)[^|]*\| *grep -[A-Za-z]*q' -- 'scripts/ci/*.sh'`, comment lines dropped; the same pattern finds the 3 fixed sites in `5561a9a9^`). Each is a latent flaky gate: a present needle can read as missing, or a forbidden match can be hidden. Only `verify_release_contract.sh` is fixed here, to keep this PR minimal. The sweep is a follow-up for the maintainer; sha256-pinned scripts need their pins re-derived when touched.
- SL-D (`verify_pipefail_grep_idiom.mjs`) exempts `printf`/`echo` producers on the premise that a builtin makes one write below the pipe buffer, so it cannot lose the race. That premise does not hold. The v1.59 section is 7551 bytes, and bash's `printf` can write it in several chunks; CI run 40241001658 lost the race (locally 0/200, a narrow window). Narrowing the exemption, for example to producers of bounded size, belongs to the same follow-up. SL-D passes at E (0 offenders).

## Known Stubs

None.

## Threat Flags

None. The only non-planning change is the three-line here-string fix in `scripts/ci/verify_release_contract.sh`; it adds no surface.

## Self-Check: PASSED

This SUMMARY, the re-minted VERIFICATION and UAT, and the trackers are in E. `5561a9a9` is an ancestor of E. The guard `--close` passes at E.
