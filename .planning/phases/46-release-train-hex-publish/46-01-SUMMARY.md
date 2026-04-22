---
phase: 46-release-train-hex-publish
plan: "01"
subsystem: infra
tags: [github-actions, releasing, rel-01]

requires: []
provides:
  - Dispatch-only Release PR automation aligned with REL-01 human gate
  - RELEASING.md narrative matching workflow + partial Hex recovery bullets
affects: [release-train, hex-publish]

tech-stack:
  added: []
  patterns:
    - "Explicit workflow_dispatch before gh pr merge --auto for release PRs"

key-files:
  created: []
  modified:
    - ".github/workflows/release-pr-automation.yml"
    - "RELEASING.md"

key-decisions:
  - "Removed pull_request trigger entirely so Release Please branches never auto-queue merge without maintainer dispatch."

patterns-established:
  - "Concurrency key scopes only github.event.inputs.pr_number for dispatch runs."

requirements-completed: [REL-01]

duration: 12min
completed: 2026-04-22
---

# Phase 46 — Plan 01 summary

**Release PR merge queueing is maintainer-intent only (`workflow_dispatch`), with RELEASING.md and a partial-Hex recovery runbook aligned to the same contract.**

## Performance

- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Rewrote `release-pr-automation.yml` to dispatch-only: simplified PR resolution, concurrency, and job `if`.
- Updated `RELEASING.md` bootstrap step 4, renamed the auto-merge subsection, and added **Partial Hex publish recovery** with Hex FAQ links.

## Task commits

1. **Task 1: Human-gate Release PR automation** — `6885444` (feat)
2. **Task 2: Align RELEASING.md with human-gate policy** — `ceea2cc` (docs)

## Deviations from plan

None — plan executed as written.

## Issues encountered

None.

## Self-Check: PASSED

- `rg -n 'pull_request' .github/workflows/release-pr-automation.yml` → no output
- `rg -ni 'partial.*hex|hex.*partial' RELEASING.md` → matches
