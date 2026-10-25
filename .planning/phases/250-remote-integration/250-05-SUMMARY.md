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
    - .planning/phases/250-remote-integration/250-VERIFICATION.md
    - .planning/phases/250-remote-integration/250-UAT.md
    - .planning/phases/250-remote-integration/250-INTEGRATION-PR.md
    - .planning/STATE.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
key-decisions:
  - "E is the pre-merge close. It carries this SUMMARY, the re-minted VERIFICATION and UAT, and LAND-01 Complete. The PR body in E says the evidence head is recorded by the following body-only commit H."
  - "LAND-02 and LAND-03 stay Pending. LAND-02 is claimed in VERIFICATION SC2 at the last measured head P = 5ad01dee and is marked Complete only by 250-07, after the merge."
  - "The plan's commit count cannot be measured from inside E (a commit cannot count itself). It is 2 by construction, E and H, and both SHAs are recorded in .planning/250-shas.local and in the H body."
plan_head_before: 6fe35302df0fcc309e28a4985a0fb5371a06f50d
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
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
        ref: "negative (b): one byte appended to the covered 250-VISUAL-CLASSIFICATION.md; verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match prints FAIL: 250-VERIFICATION.md: covered_digest mismatch over 59 covered files, rc 1"
        status: pass
      - kind: command
        ref: "negative (c): the first 250-05-SUMMARY.md coverage entry set to human_judgment: true; verify_executable_uat_contract.mjs --all-since 229 prints FAIL: 250-05-SUMMARY.md coverage SC1: human_judgment must be false, rc 1"
        status: pass
      - kind: command
        ref: "positive (d): one byte appended to each of the excluded 250-INTEGRATION-PR.md and 250-CI-LEDGER.md; verify_artifact_fixed_point.mjs prints PASS (phase 250, artifacts: 2, edges: 59, digests checked: 1), rc 0"
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
7. **E**, then push, helper at E; then **H** (body-only), publish, push, helper at H.

## Controls at E (scratch clone, removed afterwards)

Clone: `git clone --no-local` of the working repo, E's tree in place; each control is reverted before the next; the clone is removed afterwards.

| Control | Mutation | Gate | Output | rc |
|---------|----------|------|--------|----|
| baseline | none | SL-E, SL-G, exec-UAT `--all-since 229` | PASS (8 complete, 8 evidenced); PASS (edges 59, digests checked 1); PASS (22 phases, 431 tests) | 0 each |
| (a) negative | VERIFICATION `status: gaps_found` | SL-E | `FAIL: LAND-01 is marked Complete but the verification in .planning/phases/250-remote-integration carries status "gaps_found" rather than passed` | 1 |
| (b) negative | 1 byte appended to covered `250-VISUAL-CLASSIFICATION.md` | SL-G | `FAIL: .../250-VERIFICATION.md: covered_digest mismatch over 59 covered files` | 1 |
| (c) negative | 250-05 coverage SC1 `human_judgment: true` | exec-UAT `--all-since 229` | `FAIL: 250-05-SUMMARY.md coverage SC1: human_judgment must be false` | 1 |
| (d) positive | 1 byte appended to each of excluded `250-INTEGRATION-PR.md` and `250-CI-LEDGER.md` | SL-G | `PASS (... edges: 59, ... digests checked: 1)` | 0 |

## Deviations from Plan

None in substance. The plan's commit count (`actuals.commits: 2`) is fixed by construction rather than measured, because E cannot count itself and H follows it. Both SHAs are in `.planning/250-shas.local`.

## Known Stubs

None.

## Threat Flags

None. No source, workflow or contract file changes in this plan; only planning artifacts and the PR body.

## Self-Check: PASSED

This SUMMARY, the re-minted VERIFICATION and UAT, and the trackers are in E. The guard `--close` passes at E.
