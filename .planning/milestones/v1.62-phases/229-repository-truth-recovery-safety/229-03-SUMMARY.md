---
phase: 229-repository-truth-recovery-safety
plan: 03
subsystem: infra
tags: [git, github, ci, inventory, recovery, node]
requires:
  - phase: 229-01
    provides: recovery preservation refs and a verified external bundle manifest
provides:
  - Complete recovery-gated repository inventory collector with explicit remote provenance
  - Deterministic privacy-safe maintainer diagnostic and fixture verifier
affects: [230-reviewable-history-integration, 231-exact-sha-release-gate-proof]
actuals:
  tokens: 6794
  tasks: 2
  commits: 5
plan_head_before: 9841bbf2dc85a36a648688e65da2439919fe23cb
tech-stack:
  added: []
  patterns: [recovery-gated observation, allowlisted inventory schema, deterministic Markdown projection]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/render_repository_inventory.mjs
    - scripts/ci/verify_repository_inventory.mjs
key-decisions:
  - "Remote facts use fixed repository-bound GET provenance and explicit unavailable records; cached values are never substituted."
  - "A collection re-resolves every encoded preservation ref before it can enter live-remote observation."
patterns-established:
  - "Repository diagnostic sections retain named ref roles even when object IDs match."
requirements-completed: [REPO-01, REPO-02]
coverage:
  - id: D1
    description: Complete recovery-gated local and remote inventory model
    requirement: REPO-01
    verification:
      - kind: unit
        ref: node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories --require-edge-cases --require-all-ref-recovery --require-typed-artifacts
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic privacy-safe renderer and verifier controls
    requirement: REPO-02
    verification:
      - kind: unit
        ref: node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-privacy-controls --require-determinism
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 03: Complete Repository Truth Inventory Summary

**Recovery-gated repository facts, honest remote-unavailable evidence, and deterministic maintainer diagnostics.**

## Performance

- **Duration:** 16 min
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Expanded the inventory schema to model separately named ref roles, full local ref evidence, typed artifacts, worktrees, planning facts, and repository-bound remote categories.
- Added fail-closed recovery validation that verifies every encoded preservation target before collection, including any live-observation path.
- Rendered all inventory categories deterministically with explicit empty/unavailable states and no external paths, raw payloads, actors, secrets, or file/link contents.

## Task Commits

1. **Task 1: Collect complete repository and remote truth behind the recovery barrier** — `450430f5`, `d56ce7c0` (test, feat)
2. **Task 2: Render and verify the complete maintainer diagnostic** — `b9bf6cfe`, `0b677b86`, `be205c7c` (feat, fix)

## Decisions Made

- Live remote data is unavailable unless a repository-bound GET has supplied full-SHA evidence and observation provenance.
- The renderer uses only validated source fields and sorts independently of input order.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired recovery-barrier syntax before final verification**
- **Found during:** Task 2
- **Issue:** A missing parenthesis prevented the collector module from loading after adding preservation target checks.
- **Fix:** Corrected the expression and re-ran syntax and fixture verification.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`
- **Commit:** `be205c7c`

## Issues Encountered

None.

## Next Phase Readiness

Phase 230 can use the named, full-SHA inventory without treating divergent or equal refs as reconciled history.

## Self-Check: PASSED

- All three owned scripts exist and all five task commits are present.
- The complete fixture suite and Node syntax checks passed.
