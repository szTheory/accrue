---
phase: 229-repository-truth-recovery-safety
plan: 01
subsystem: infra
tags: [git, recovery, inventory, ci, node, bash]
requires: []
provides:
  - All-ref preservation refs and integrity-verified external bundle recovery
  - Sanitized deterministic local-only repository inventory evidence
affects: [230-reviewable-history-integration, 231-exact-sha-release-gate-proof]
actuals:
  tokens: 18150
  tasks: 2
  commits: 2
plan_head_before: f55985c7d9246b985a67e2f34e4df3096370ee07
tech-stack:
  added: [Node.js ESM, Bash, git bundle]
  patterns: [allowlisted evidence schema, deterministic Markdown projection, external recovery capsule]
key-files:
  created:
    - scripts/ci/preserve_repository_state.sh
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/render_repository_inventory.mjs
    - scripts/ci/verify_repository_inventory.mjs
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
  modified: []
key-decisions:
  - "Freeze every refs/** row before creating Phase 229 preservation refs, then verify both named refs and bundle membership."
  - "Persist only allowlisted, relative typed artifact evidence; external recovery locations and content remain private."
patterns-established:
  - "Machine-readable local inventory is authoritative; Markdown is a byte-reproducible projection."
requirements-completed: [REPO-01, REPO-02]
coverage:
  - id: D1
    description: All-ref preservation and typed artifact handling
    requirement: REPO-01
    verification:
      - kind: integration
        ref: bash scripts/ci/preserve_repository_state.sh --self-test
        status: pass
      - kind: unit
        ref: node scripts/ci/verify_repository_inventory.mjs --fixtures
        status: pass
    human_judgment: false
  - id: D2
    description: Current sanitized local-only recovery inventory
    requirement: REPO-02
    verification:
      - kind: integration
        ref: node scripts/ci/verify_repository_inventory.mjs --records ... --require-recovery --require-local-only
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 01: Recovery-Protected Inventory Summary

**Verified external all-ref recovery capsule and deterministic, privacy-safe local repository inventory.**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-09-13T04:10:52Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added a fail-closed preservation command that freezes all existing `refs/**`, creates reversible Phase 229 refs, verifies an external bundle, and records non-dereferenced typed untracked artifacts.
- Added dependency-free collect, render, and verify commands that enforce an allowlisted local-only schema and byte-identical Markdown projection.
- Created a real repository inventory that distinguishes local `main`, cached `origin/main`, the milestone branch, and immutable `v1.61` by full SHA while reporting remote observation as unavailable.

## Task Commits

1. **Task 1: Prove one recovery-protected local inventory path end to end** — `dc4f6b91` (feat)
2. **Task 2: Seal the current repository recovery capsule and local inventory** — `41326d2e` (docs)

## Decisions Made

- The external bundle and private manifest are deliberately excluded from committed evidence; the renderer exposes only bundle digest, ref identities, and restoration-safe preservation refs.
- Empty untracked directories use the explicit `not_surfaced_by_git` policy because Git's exact untracked enumeration does not surface them.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

Phase 230 can begin history integration from the committed local ref truth and the verified recovery barrier. No remote observation or reconciliation was performed.

## Self-Check: PASSED

- All six planned artifacts exist and both task commits are present.
- Fresh verification passed: preservation self-test, inventory fixtures, real inventory byte-reproducibility, and `git diff --check`.
