---
phase: 251-1-7-0-release-alignment
plan: "07"
subsystem: release-automation
status: complete
completed: 2026-10-26
requirements-completed: [RLS-01, RLS-02]
tags: [phase-close, release-please, rls-01, rls-02, sl-g, sl-e, executable-uat]
requires: [251-06]
provides:
  - RLS-01 and RLS-02 Complete in the REQUIREMENTS checklist and traceability table, on the 251-05 and 251-06 evidence
  - 251-VERIFICATION.md at 3/3 success criteria (status passed, behavior_unverified 0) re-minted over all seven SUMMARYs and the released CHANGELOGs, READMEs and release notes
  - scratch-clone negative and positive controls over SL-E, SL-G and executable-UAT at the close commit
affects: [v1.67 milestone completion]
key-files:
  created:
    - .planning/phases/251-1-7-0-release-alignment/251-07-SUMMARY.md
  modified:
    - .planning/phases/251-1-7-0-release-alignment/251-VERIFICATION.md
    - .planning/phases/251-1-7-0-release-alignment/251-UAT.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "docs/251-close takes main's release merge M 20a3982c with a plain git merge --no-ff (no rebase, no reset); the covered set now includes the 1.7.0 CHANGELOGs, READMEs, release notes and mix.exs files changed since db1b6d85."
  - "RLS-01 and RLS-02 are marked Complete only at the close, after the 251-06 publication evidence exists."
  - "v1.67 milestone completion runs as a separate step after this phase; milestone tags stay local, and the archive-invariant sweep runs immediately after the archive."
coverage:
  - id: C1
    description: the close evidence passes SL-G, SL-E and executable-UAT on the closed tree, with RLS-01 and RLS-02 Complete in both the checklist and the traceability table and 251-VERIFICATION.md at 3/3 with behavior_unverified 0
    requirement: RLS-01
    verification:
      - kind: command
        ref: "node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --all-since 229 && node scripts/ci/verify_executable_uat_contract.mjs --phase 251"
        status: pass
    human_judgment: false
  - id: C2
    description: SC1 holds on the released tree; the curated 1.7.0 CHANGELOG sections of accrue, accrue_admin and accrue_portal contain zero raw phase-scoped lines after the release merge M, and RLS-02 publication facts from 251-06 are cited by the 3/3 verification
    requirement: RLS-02
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_changelog_curated.sh (OK (1.7.0): curated release sections; 0 raw lines for all three packages)"
        status: pass
    human_judgment: false
---

# Phase 251 Plan 07: Phase 251 Close Summary

Phase 251 is closed on the evidence. `docs/251-close` took main's release merge M `20a3982c` with a plain `--no-ff` merge. RLS-01 and RLS-02 are now Complete. 251-VERIFICATION.md reads 3/3 with `behavior_unverified: 0` and was re-minted, with the UAT, over all seven SUMMARYs. The covered set grew, as expected, to include the 1.7.0 CHANGELOGs, READMEs, release notes and `mix.exs` files that changed since `db1b6d85`.

## Close evidence

| Gate | Command | Result |
|------|---------|--------|
| SC1 on the released tree | `bash scripts/ci/verify_release_changelog_curated.sh` | `OK (1.7.0): curated release sections`, 0 raw lines in each package |
| SC2 at release head A | `node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 --event pull_request --pr-base origin/main` | rc 0, GREEN; ci.yml run 40353699704, browser run 40353699699, 20 success jobs (parked ratchet lane any-conclusion) |
| SC3 | 251-06 P3/P4 | tags at M, Release Please run 40361348296 all six jobs success, hex.pm 1.7.0 `has_docs: true` for all three packages |
| SL-G | `verify_artifact_fixed_point.mjs --require-acyclic --require-fixed-point --require-digest-match` | pass |
| SL-E | `verify_completion_evidence.mjs --require-completion-evidence --require-table-agreement` | pass |
| exec-UAT | `verify_executable_uat_contract.mjs --self-test`, `--all-opted-in`, `--all-since 229`, `--phase 251` | pass |

(The first SC2 run hit a transient GitHub `HTTP 502` from `gh api` and exited 3. A retry seconds later exited 0. The helper was unchanged.)

<!-- gsd:controls -->

## Deviations from Plan

None in Task 1 beyond those recorded above.

## Self-Check

Pending the controls commit.
