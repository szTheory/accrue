---
phase: 229-repository-truth-recovery-safety
plan: 04
subsystem: infra
tags: [git, recovery, repository-inventory, ci-observation]
requires:
  - phase: 229-02
    provides: read-only CI monitor contract
  - phase: 229-03
    provides: preservation manifest, verified bundle, and inventory tools
provides:
  - Recovery-backed final repository inventory and deterministic diagnostic
  - Exact-path evidence for authorized GSD workflow metadata refreshes
affects: [230-reviewable-history-integration]
tech-stack:
  added: []
  patterns: [exact-path hash authorization, deterministic JSON-to-Markdown inventory]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/render_repository_inventory.mjs
    - scripts/ci/verify_repository_inventory.mjs
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
key-decisions:
  - "Authorize only .planning/milestone.lock and .planning/state.json through exact before/after SHA-256 evidence."
  - "Record unavailable remote observations explicitly instead of replacing them with local or cached claims."
patterns-established:
  - "Recovery inventory accepts workflow metadata drift only from a restrictive supplemental authorization record outside the repository."
requirements-completed: [REPO-01, REPO-02, REPO-03]
actuals:
  tokens: 28524
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 215ff3afc67e7a3610eaa227c25eb8478cb1b402
duration: 35min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 04: Final Recovery-backed Repository Truth Summary

**A deterministic repository and CI evidence snapshot with all 109 frozen refs recoverable and only two exact, hash-proven GSD metadata refreshes authorized.**

## Performance

- **Duration:** 35 min
- **Tasks:** 2/2
- **Files modified:** 7
- **Verification:** Inventory fixtures, final independent verifier, and CI monitor documentation self-test passed.

## Accomplishments

- Documented the read-only, exact-repository CI list, inspect, and bounded watch commands.
- Revalidated the original bundle digest, bundle structure, every one of 109 frozen refs, preservation mappings, v1.61 tag object, and typed artifact snapshot before collection.
- Captured a schema-v2 JSON authority and byte-reproducible Markdown projection; all remote facts are explicit unavailable records rather than substituted local facts.
- Restricted the authorized artifact delta to `.planning/milestone.lock` and `.planning/state.json`, each with a fixed path, type, before SHA-256, after SHA-256, and workflow-owned state.

## Task Commits

1. **Task 1: Document the supported inventory and CI observation commands** — `f40f9a92` (docs)
2. **Task 2: Capture and independently verify the final repository truth snapshot** — `024063f1`, `ed1ff4d9` (feat, fix)

## Decisions Made

- The original private manifest and bundle remain unchanged; restrictive supplemental authorization records live beside them with mode `0600`, including one final record after required GSD state tracking republished its metadata.
- The verifier requires repository-bound GET provenance and can require the two exact workflow metadata authorization records.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allowed valid slash-delimited Git branch names in worktree evidence**
- **Found during:** Task 2
- **Issue:** The inventory validator rejected the active `gsd/...` milestone branch despite it being a valid, safe Git branch name.
- **Fix:** Retained control-character, backslash, absolute-path, and repeated-separator rejection while allowing normal Git branch separators.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/verify_repository_inventory.mjs`
- **Verification:** Fixture suite and final inventory verification passed.
- **Commit:** `024063f1`

**Total deviations:** 1 auto-fixed (Rule 1).

### Authorized Workflow Metadata Follow-up

Required GSD closeout republished `.planning/state.json`. Rather than accepting the changed hash, the final snapshot was regenerated from a new additive authorization record that pins the original and final SHA-256 values for the same two authorized paths. The original recovery manifest and prior supplemental record were not modified.

## Remote Observation

The collector ran with `--observe-remote`; no live adapter was available, so each remote category is recorded as `unavailable` with its repository-bound GET request. No CI run, ref, PR, issue, provider, or publication action was performed.

## Known Stubs

None.

## Next Phase Readiness

Phase 230 may consume the committed inventory and verified recovery barrier for history review. It alone owns any reconciliation or main synchronization.

## Self-Check: PASSED

- `ed1ff4d9`, `024063f1`, and `f40f9a92` exist in repository history.
- Final JSON and Markdown inventory files exist and passed deterministic verification.
