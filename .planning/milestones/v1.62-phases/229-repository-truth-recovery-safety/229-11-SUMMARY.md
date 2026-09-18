---
phase: 229-repository-truth-recovery-safety
plan: 11
subsystem: repository-safety
tags: [github-api, pagination, provenance, node-test]
requires:
  - phase: 229-06
    provides: Recovery-gated fixed GitHub GET adapter and typed remote facts
provides:
  - Terminal-page proof for open pull requests, release refs, and Actions runs
  - Ordered producing-request provenance with bounded overflow semantics
affects: [229-13, 229-14, repository-inventory-verification]
actuals:
  tokens: 8789
  tasks: 2
  commits: 4
plan_head_before: 96da9f282e5115f5ecd29ba2c54829d757a38f2c
commits: 4
tech-stack:
  added: []
  patterns: [bounded plural-page collector, terminal-page proof, fail-closed partial-result disposal]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/phase229_gap_closure.test.mjs
key-decisions:
  - "A plural fact is available only after a page shorter than the explicit page size proves termination; a full page at the configured page/item bound is overflow."
  - "Plural evidence stores the complete ordered request sequence, while remote main retains its fixed singleton request contract."
patterns-established:
  - "Bounded pagination: every plural category shares page, item, process-time, and response-buffer bounds."
  - "No partial truth: any later-page failure emits only typed unavailable evidence and the attempted request sequence."
requirements-completed: [REPO-01]
coverage:
  - id: D1
    description: Open pull requests require terminal-page proof and retain every producing request in order.
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/collect_repository_inventory.mjs#open pull requests require terminal page proof"
        status: pass
    human_judgment: false
  - id: D2
    description: Release refs and Actions aggregate all terminal-proven pages in stable order.
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/collect_repository_inventory.mjs#release refs and Actions require terminal page proof"
        status: pass
    human_judgment: false
  - id: D3
    description: Page, item, response, and later-page failures expose no partial SHA claims or non-allowlisted API capability.
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/collect_repository_inventory.mjs#plural pagination failures discard partial remote values"
        status: pass
      - kind: unit
        ref: "scripts/ci/collect_repository_inventory.mjs#GitHub plural endpoint allowlist enforces normalized contiguous pages"
        status: pass
    human_judgment: false
duration: 10 min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 11: Bounded Plural GitHub Inventory Summary

**Open PRs, release refs, and Actions now require bounded terminal-page proof with exact ordered GET provenance before becoming available repository truth.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-13T18:56:57Z
- **Completed:** 2026-09-13T19:06:53Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added a shared bounded plural-page collector that continues after every full page and accepts evidence only after a short terminal page.
- Applied exact `per_page`/`page` sequencing to open PRs, matching `release/*` refs, and Actions runs while preserving deterministic category-specific ordering.
- Preserved all six remote failure classes and converted page/item/buffer overflow or later-page failure into unavailable facts with no partial SHA array.
- Kept the adapter restricted to remote main plus the three plural repository-bound GET capabilities in `COVERAGE.md`.

## Task Commits

Each task was committed through its RED and GREEN TDD gates:

1. **Task 1: Prove a two-page open-PR observation end to end** — `22c5cb7f` (RED), `fd90cfdd` (GREEN)
2. **Task 2: Apply terminal-page proof to release refs and Actions** — `76b98852` (RED), `c975df81` (GREEN)

## Files Created/Modified

- `scripts/ci/collect_repository_inventory.mjs` — bounded plural collection, exact endpoint/page sequencing, ordered request provenance, fail-closed overflow, and embedded fixtures.
- `scripts/ci/phase229_gap_closure.test.mjs` — existing unavailable-provenance assertion updated for plural request sequences.

## Decisions Made

- A short page is the sole success terminal rule; a full page requires another read and cannot be accepted at the configured bound.
- Remote main remains a singleton with one `request`; every plural fact uses an ordered `requests` array.
- A category retains one observation timestamp across all pages and persists only normalized SHA/request evidence, never payloads or headers.

## TDD Gate Compliance

- RED `22c5cb7f`: the named 100-item PR fixture failed because no page-2 request was made.
- GREEN `fd90cfdd`: PR collection followed the full page, retained page-2 evidence, and passed short, empty, and overflow cases.
- RED `76b98852`: the named release-ref/Actions fixture failed because both categories still used one unpaginated request.
- GREEN `c975df81`: all three plural categories use the shared terminal-page helper and the full embedded and gap-closure suites pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated the existing unavailable-provenance regression for the new plural schema**

- **Found during:** Task 2 verification
- **Issue:** `phase229_gap_closure.test.mjs` assumed every remote fact had a singleton `request`, so the required plural `requests` schema caused a directly related regression.
- **Fix:** Assert one or more repository-bound GETs across either the singleton or plural provenance form.
- **Files modified:** `scripts/ci/phase229_gap_closure.test.mjs`
- **Verification:** `node --test scripts/ci/phase229_gap_closure.test.mjs` passes 10/10 tests.
- **Committed in:** `c975df81`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The adjustment keeps the pre-existing regression aligned with the intentionally changed schema; no production scope or API capability was added.

## Issues Encountered

None.

## Authentication Gates

None.

## User Setup Required

None - live GitHub authentication is required only when a maintainer explicitly invokes remote observation.

## Next Phase Readiness

- Plan 229-13 can independently verify exact category-specific request sequences and terminal-page proof.
- Plan 229-14 can recapture the canonical JSON/Markdown pair using complete bounded remote evidence or explicit unavailable facts.

## Self-Check: PASSED

- `scripts/ci/collect_repository_inventory.mjs` exists and passes syntax plus six embedded tests.
- `scripts/ci/phase229_gap_closure.test.mjs` passes all ten current tests.
- Task commits `22c5cb7f`, `fd90cfdd`, `76b98852`, and `c975df81` exist in git history.
- No tracked recovery-capsule location or external recovery artifact was modified.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
