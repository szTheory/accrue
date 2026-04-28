---
phase: 091-pre-publish-prep
plan: 02
subsystem: docs
tags: [readme, stability, public-surface]

key-files:
  modified:
    - README.md
    - accrue/README.md

requirements-completed: [DOC-03]
---

# Phase 91 Plan 02: Public 1.0.x posture flip

## Accomplishments

- Rewrote the root `README.md` maintenance posture in commitment-level `1.0.x` language.
- Preserved the explicit `PROC-08` / `FIN-03` later-milestone warning in the root README.
- Reframed `accrue/README.md` around the `1.0.x` stability contract without changing the `{:accrue, "~> 0.3.1"}` install literal.

## Task Commits

1. **Task 1: Flip the root README maintenance posture without weakening the non-goal warning** — `f4ac0a5`
2. **Task 2: Flip the package README stability section while preserving the current install pin** — `f4ac0a5`

**Plan metadata:** `f4ac0a5` (`docs(091-02): flip public 1.0.x posture`)

## Verification

- `rg -Fq 'The **\`1.0.x\`** line treats the public facade, Fake-backed proofs, and merge-blocking CI contracts as the stability boundary' README.md`
- `rg -Fq 'PROC-08' README.md`
- `rg -Fq 'FIN-03' README.md`
- `rg -Fq 'later milestone' README.md`
- `rg -Fq 'done enough for the **\`1.0.x\`** line' accrue/README.md`
- `rg -Fq 'breaking changes on the documented surface go through deprecation, not silent reshuffles' accrue/README.md`
- `rg -Fq '{:accrue, "~> 0.3.1"}' accrue/README.md`

## Deviations from Plan

- The two plan tasks landed in a single commit (`f4ac0a5`) instead of one commit per task. The user-facing docs and all plan verifications still landed as specified.

## Issues Encountered

None.

## Self-Check: PASSED
