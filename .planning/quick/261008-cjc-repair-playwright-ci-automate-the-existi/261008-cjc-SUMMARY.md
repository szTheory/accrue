---
quick_id: 261008-cjc
subsystem: testing
tags: [playwright, ci, evidence]
provides:
  - Replay step-up completion in the canonical host browser journey
  - Read-only verification of saved Phase 234 post-layout evidence during normal runs
affects: [host-e2e, playwright-ci, phase234-evidence]
key-files:
  created:
    - .planning/quick/261008-cjc-repair-playwright-ci-automate-the-existi/261008-cjc-SUMMARY.md
  modified:
    - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
    - examples/accrue_host/e2e/phase234-post-layout.spec.js
key-decisions:
  - "Keep evidence writes behind PHASE234_CAPTURE_POST_LAYOUT=1 and refuse populated destinations."
metrics:
  duration: 3m
  completed: 2026-10-08
status: complete
---

# Quick Task 261008-cjc Summary

The canonical replay journey now completes the real test-only step-up challenge, while ordinary Phase 234 post-layout runs verify live layout and saved capture integrity without writing evidence.

## Accomplishments

- Submitted the test host's `123456` verification code in the replay step-up dialog, waited for the dialog to close, and retained replay confirmation and audit-event assertions.
- Added read-only checks for the post-layout manifest phase, image byte counts, and SHA-256 digests. Normal mode still navigates the served customer and subscription pages and verifies responsive layout, hierarchy, controls, and stylesheet availability.
- Gated screenshots and exclusive evidence writes behind `PHASE234_CAPTURE_POST_LAYOUT=1`; populated destinations are refused before browser work.

## Task Commits

1. **Task 1: Complete the replay step-up in the canonical journey** - `748751c7` (`fix`)
2. **Task 2: Make saved Phase 234 post-layout evidence read-only in normal runs** - `519ef895` (`fix`)

## Verification

- `npm run e2e -- e2e/phase13-canonical-demo.spec.js --workers=1` — passed.
- `npm run e2e -- e2e/phase234-post-layout.spec.js --workers=1` — passed.
- Explicit capture-refusal check — passed; capture mode reported `post-layout evidence is write-once`, and all 12 files in the populated destination had identical SHA-256 digests before and after.
- Combined affected specs — 2 passed.
- Full host discovery (`npx playwright test --workers=1`) — 33 passed, 2 expected desktop-project skips; mobile-project counterparts passed.
- `git diff --check` — passed. Execution source changes were limited to the two planned specs; unrelated pre-existing working-tree changes remain unstaged.

## Deviations from Plan

The full host suite includes `phase233-baseline.spec.js`, which writes its five baseline PNGs during a normal run. Verification regenerated those tracked PNGs, so they were restored to their committed bytes afterward. The unrelated pre-existing `.planning/config.json` modification and untracked `.planning/milestone.lock` remain untouched. The initial sandboxed browser launch and Git index write were denied by environment permissions; the requested browser runs and per-task commits succeeded with elevated execution.

## User Setup Required

None.

---
*Quick task: 261008-cjc*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Summary file exists at the planned path.
- Task commits `748751c7` and `519ef895` are ancestors of HEAD.
- The two planned source files have no uncommitted diff, and `git diff --check` passes.
