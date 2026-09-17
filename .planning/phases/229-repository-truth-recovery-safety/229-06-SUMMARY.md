---
phase: 229-repository-truth-recovery-safety
plan: 06
subsystem: repository-safety
tags: [github-api, git-worktree, recovery, inventory, node-test]
requires:
  - phase: 229-05
    provides: Verified recovery manifest and capsule boundary
provides:
  - Bounded repository-bound GitHub observation adapter
  - Complete sanitized worktree and ship-window inventory facts
affects: [phase-229-verification, repository-synchronization]
tech-stack:
  added: [GitHub CLI API adapter, Node embedded tests]
  patterns: [GET-only allowlist, plural SHA normalization, porcelain parsing]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
key-decisions:
  - "Remote main is a singleton SHA while PRs, release branches, and Actions retain ordered SHA arrays, including confirmed empty arrays."
  - "Recovery manifest repository identity is validated against frozen context before bundle, artifact, worktree, planning, or remote reads."
metrics:
  duration: 13m
  completed: 2026-09-13
  tasks: 2
  files: 1
status: complete
plan_head_before: a2fe668cd6dfb5e10f8b72f92b8eeee0bdfc7e43
commits: 4
actuals:
  tokens: 7770
  tasks: 2
  commits: 4
requirements-completed: [REPO-01, REPO-02, REPO-03]
coverage:
  - id: D1
    description: Fixed GET-only GitHub observations preserve singleton and plural remote truth with explicit unavailable reasons.
    requirement: REPO-01
    verification:
      - kind: unit
        ref: node --test scripts/ci/collect_repository_inventory.mjs
        status: pass
    human_judgment: false
  - id: D2
    description: Recovery-gated local inventory captures all worktrees and validated ship-window facts without absolute paths.
    requirement: REPO-02
    verification:
      - kind: integration
        ref: node scripts/ci/verify_repository_inventory.mjs --fixtures
        status: pass
    human_judgment: false
  - id: D3
    description: Foreign recovery manifests are rejected before any dependent collection action.
    requirement: REPO-03
    verification:
      - kind: unit
        ref: node --test scripts/ci/collect_repository_inventory.mjs
        status: pass
    human_judgment: false
---

# Phase 229 Plan 06: Complete Repository Truth Summary

**A recovery-gated inventory collector that reads bounded GitHub truth, every worktree, and validated ship-window evidence.**

## Accomplishments

- Added a shell-disabled `gh api` adapter restricted to the four authorized, repository-bound GET endpoints with time, buffer, page-size, and item limits.
- Records remote main as a strict singleton and PRs, release branches, and Actions as deterministic complete SHA arrays, preserving confirmed empty results and honest unavailable reasons.
- Validates private manifest repository provenance before dependent reads, parses every `git worktree list --porcelain` entry without publishing paths, and reads count-checked window states from the ledger.

## Verification

- `node --check scripts/ci/collect_repository_inventory.mjs` — passed.
- `node --test scripts/ci/collect_repository_inventory.mjs` — passed (2 embedded fixture tests).
- `node scripts/ci/verify_repository_inventory.mjs --fixtures` — passed.
- Diff scope contains only `scripts/ci/collect_repository_inventory.mjs`; no GitHub mutation or ref-refresh command was introduced.

## Task Commits

1. **Task 1: Observe the complete authorized GitHub surface with zero/one/many semantics** — `6e4845b3` (RED), `600d46aa` (GREEN)
2. **Task 2: Collect every worktree and actual ship-window fact behind repository-bound recovery** — `a3254a9d` (RED), `610551ca` (GREEN)

## Files Created/Modified

- `scripts/ci/collect_repository_inventory.mjs` — bounded remote adapter, plural fact schemas, recovery repository binding, all-worktree parser, window ledger parser, and embedded tests.

## Decisions Made

- Remote data never falls back to local or cached evidence: failures become typed unavailable facts.
- Worktree paths stay inside the collector boundary; only branch/detached state, SHA, and dirty state enter the canonical record.

## TDD Gate Compliance

- RED: `6e4845b3` established the absent adapter contract, which failed because no adapter existed.
- GREEN: `600d46aa` implemented the bounded allowlisted adapter and made the remote fixtures pass.
- RED: `a3254a9d` established the absent worktree/window collector contract, which failed because neither collector existed.
- GREEN: `610551ca` implemented the sanitized collectors and made the complete fixture suite pass.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - GitHub authentication is only needed when a maintainer explicitly invokes `--observe-remote`.

## Next Phase Readiness

Downstream verification can consume real bounded remote facts and complete local truth without weakening the recovery-first boundary.

## Self-Check: PASSED

- `scripts/ci/collect_repository_inventory.mjs` exists.
- Task commits `6e4845b3`, `600d46aa`, `a3254a9d`, and `610551ca` exist in git history.
