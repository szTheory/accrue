---
phase: 104-connect-spike-decision
plan: 01
subsystem: docs
tags: [braintree, hyperwallet, connect, docs, exunit]
requires:
  - phase: 094-strategy-capability-matrix-target-lock
    provides: "Capability-explicit support wording and docs-verifier patterns"
provides:
  - "Canonical Hyperwallet no-go decision guide for Braintree Connect questions"
  - "Public Connect guide boundary note that redirects Braintree readers to the decision artifact"
  - "Literal docs-contract coverage for the verdict, reopen rule, provider split, and narrow if-go slice"
affects: [phase-104-plan-02, processor-support-matrix, strategy]
tech-stack:
  added: []
  patterns: [literal-docs-contract, provider-honest-connect-boundary]
key-files:
  created:
    - accrue/guides/connect-hyperwallet-decision.md
    - accrue/test/accrue/docs/connect_hyperwallet_decision_test.exs
  modified:
    - accrue/guides/connect.md
key-decisions:
  - "Recorded Hyperwallet as a hard no-go for the current strategy instead of a soft defer."
  - "Kept the only future reopen path narrow: minimal seller onboarding plus payouts with loud exclusions."
  - "Pinned exact wording in ExUnit so later docs edits cannot blur the Braintree and Hyperwallet boundary."
patterns-established:
  - "Decision spikes that change public support posture should ship with exact-string docs-contract tests."
  - "Connect guidance must keep Braintree pay-ins and Hyperwallet payouts as separate truths."
requirements-completed: [BT-08, BT-09]
duration: 11 min
completed: 2026-05-03
---

# Phase 104 Plan 01 Summary

**Accrue now carries a merge-blocking Hyperwallet decision guide and a public Connect warning that rejects Braintree marketplace parity for the current strategy.**

## Performance

- **Duration:** 11 min
- **Completed:** 2026-05-03T02:15:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `connect_hyperwallet_decision_test.exs` to pin the no-go verdict, reopen rule, provider split, spike evidence, and narrow if-go slice with exact substring assertions.
- Published `accrue/guides/connect-hyperwallet-decision.md` as the canonical Phase 104 decision artifact for maintainers and adopters.
- Updated `accrue/guides/connect.md` with a visible Braintree/Hyperwallet boundary note that links directly to the new guide.

## Task Commits

1. **Task 1: Add a docs-contract test for the Hyperwallet decision artifact** - `5533cc1` (`test`)
2. **Task 2: Publish the Hyperwallet decision guide and Connect boundary callout** - `480e8ee` (`docs`)

## Files Created/Modified

- `accrue/test/accrue/docs/connect_hyperwallet_decision_test.exs` - literal docs-contract coverage for the Phase 104 decision wording.
- `accrue/guides/connect-hyperwallet-decision.md` - canonical no-go artifact with the reopen rule and future boundary.
- `accrue/guides/connect.md` - Braintree marketplace warning and guide link near the top of the public Connect guide.

## Decisions Made

- Kept the verdict explicit: marketplace parity is strategically out of bounds unless the project boundary changes.
- Preserved one narrow future contract, `minimal seller onboarding + payouts only`, without implying current support.
- Reused the repo’s docs-test style instead of adding shell verifiers or runtime code for a docs-only phase slice.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the new docs test file helper and literal wrapping**
- **Found during:** Task 2 verification
- **Issue:** The first helper joined repo paths in the wrong order, and two required phrases were wrapped across Markdown line breaks, so the literal docs contract failed before validating the intended wording.
- **Fix:** Corrected the repo-root helper in the test file and rewrote the affected guide lines so the required strings remain contiguous.
- **Files modified:** `accrue/test/accrue/docs/connect_hyperwallet_decision_test.exs`, `accrue/guides/connect.md`, `accrue/guides/connect-hyperwallet-decision.md`
- **Commit:** `480e8ee`

## Issues Encountered

- The plan’s suggested `mix test ... -x` command is stale for the installed Mix version. Verification succeeded with the supported command: `mix test test/accrue/docs/connect_hyperwallet_decision_test.exs --warnings-as-errors`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 can now mirror the same wording into `.planning/processor-support-matrix.md`, `.planning/STRATEGY.md`, and the existing matrix verifier without redefining the boundary.

## Self-Check

PASSED

- Summary file exists at `.planning/phases/104-connect-spike-decision/104-01-SUMMARY.md`.
- Commit `5533cc1` exists for the docs-contract scaffold.
- Commit `480e8ee` exists for the published guide and Connect boundary note.
