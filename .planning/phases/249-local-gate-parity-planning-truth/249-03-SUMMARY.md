---
phase: 249-local-gate-parity-planning-truth
plan: "03"
subsystem: ci-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-01, GREEN-04]
tags: [sl-g, archived-digest, phase190-contract, executable-uat, recorded-deviations]
key-files:
  modified:
    - scripts/ci/verify_artifact_fixed_point.mjs
    - scripts/ci/verify_phase190_automation_contract.sh
    - scripts/ci/verify_executable_uat_contract.mjs
key-decisions:
  - "Archived 232 covered_digest is checked at the commit that introduced it (da45b614), not live files"
  - "Archived v1.66 deviations are recorded in a typed sha256-pinned list, never by editing archived files"
commits: 3
plan_head_before: cd04c4767b5aa596a9a817a959740747d3fd2168
plan_head_after: a1a7a95e6dcec6e2e05108f00e00d1afbd5c974a
actuals:
  tokens: 60000
  tasks: 3
  commits: 3
coverage:
  - id: C1
    description: Archived 232 digest verified at its minting tree with a negative control at the preceding commit
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node --test --test-reporter=tap scripts/ci/verify_artifact_fixed_point.mjs"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_artifact_fixed_point.mjs --fixtures --require-acyclic --require-fixed-point --require-digest-match"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_phase230_archive_invariants.mjs --repo ."
        status: pass
    human_judgment: false
  - id: C2
    description: Phase 190 contract accepts canonical status passed and rejects human_needed and stale complete
    requirement: GREEN-04
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_phase190_automation_contract.sh"
        status: pass
    human_judgment: false
  - id: C3
    description: Executable UAT contract passes 229-248 via pinned recorded deviations with negative controls in self-test
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --self-test"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in"
        status: pass
      - kind: command
        ref: "node --test --test-reporter=tap scripts/ci/verify_executable_uat_contract.mjs"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 03: Verifier-vs-artifact reconciliation Summary

Three verifiers fixed in scope with every assertion kept: SL-G test 18 now checks the archived 232 digest at the tree it was minted at, the Phase 190 contract accepts the canonical `status: passed`, and the executable UAT contract passes archived 229-248 through a typed, sha256-pinned deviation list.

## Task outcomes

1. **SL-G (R3a), commit 1f83a5a8.** Positive control: test 18 failed with `covered_digest mismatch over 52 covered files`. Added `computeDigestAtCommit` (git blobs, no shell, archive-aware for phase dirs already moved). Disk `computeDigest` output is byte-identical. The minting commit is derived as the commit that introduced the archived covered_digest string (`git log -S`). Negative control: the tree one commit earlier does not reproduce the digest.
2. **Phase 190 (R9), commit 30aae20f.** Only the VERIFICATION status regex changed to `^status: passed$` (vocabulary from 2219292b). In a scratch copy, `status: human_needed` and `status: complete` both fail.
3. **Executable UAT (A3), commit a1a7a95e.** `RECORDED_DEVIATIONS` with closed kinds, archived-only paths, mandatory reason, sha256 pin, and per-phase stale-entry failure. The list is injectable into `validatePhaseDirectory` for tests; the CLI always uses the committed list.

## Measured offender set (18 entries, equals the planner probe exactly)

| Phase | Kind | Artifact |
|---|---|---|
| 245 | human_judgment_true | 245-02-SUMMARY.md D2 |
| 245 | uat_missing | 245-VERIFICATION.md |
| 246 | human_judgment_true | 246-04-SUMMARY.md D3; 246-05-SUMMARY.md D2 |
| 246 | summary_frontmatter_missing | 246-IDENTITY-GAP-SUMMARY.md |
| 246 | uat_missing | 246-VERIFICATION.md |
| 247 | coverage_missing | 247-02, 247-05, 247-06 SUMMARY |
| 247 | human_judgment_true | 247-03 D1, D2, D3; 247-04 D1, D2 |
| 247 | uat_missing | 247-VERIFICATION.md |
| 248 | human_judgment_true | 248-01 D2; 248-02 D2 |
| 248 | uat_missing | 248-VERIFICATION.md |

No offenders in 229-244. All 20 archived phases at or after 229 validate (checked directly).

## A3 extension

CONTEXT A3 lists only human_judgment entries. Three more kinds are recorded, each the same class of honest historical deviation (v1.66 predates the executable-UAT contract; editing would falsify archived v3 covered_digests):

- `uat_missing` (245, 246, 247, 248): no UAT was ever generated. The entry pins the phase VERIFICATION.md; the waiver skips only the UAT block, and VERIFICATION status, behavior_unverified and human-language checks still run (proved in self-test with a human_needed VERIFICATION).
- `coverage_missing` (247-02, 247-05, 247-06): summaries with no `coverage:` block.
- `summary_frontmatter_missing` (246-IDENTITY-GAP-SUMMARY.md): a gap note that matches the `-SUMMARY.md` suffix but is not a SUMMARY.

## Deviations from Plan

**1. [Rule 1 - Bug in plan assumption] Minting commit.** The plan said the minting commit is 9f256a7e (last commit touching the active path). Measured: the digest at 9f256a7e is the earlier `1ddf06f1`; the current archived `726a260f` was re-minted by da45b614 after the milestone archive. Used `git log -S <digest>` to derive the introducing commit instead of a path-based pathspec, which also removed the need for any archive-sweep-exempt marker. Sweep still passes. (Sweep positive control was not run; it reads tracked files only.)

## Deferred / out-of-scope

- `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229` currently fails at `249-01-SUMMARY.md coverage C1: missing verification ref`, not at the expected missing-249-UAT. Cause: 249-01-SUMMARY.md writes coverage verification as flow-style inline maps (`- {kind: command, ref: ..., status: pass}`), which the validator's block-style regexes do not parse. Outside this plan's files; 249-17 (UAT mint) must rewrite 249-01's coverage in block style (as this summary does) or the validator must learn flow style.

## Known Stubs

None.

## Self-Check: PASSED

Files and commits 1f83a5a8, 30aae20f, a1a7a95e verified present; no archived file edited (`git diff --stat -- .planning/milestones` empty).
