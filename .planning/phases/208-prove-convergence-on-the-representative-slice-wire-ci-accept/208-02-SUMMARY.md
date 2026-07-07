---
phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept
plan: 02
subsystem: testing
tags: [admin-ui-ratchet, signoff, verifier, ci, node]
requires:
  - phase: 200-idempotent-verification-sign-off
    provides: Markdown sign-off verifier pattern and fixture self-tests
  - phase: 208-plan-01
    provides: read-only frozen ratchet ledger verifier and acceptance evidence contract
provides:
  - Deterministic UI ratchet sign-off verifier
  - UI-SPEC section, status, runbook, evidence reference, and final ACCEPT enforcement
  - Fixture red paths for missing evidence, invalid refs, frozen-ledger failures, and broad-sweep wording
affects: [phase-208, admin-ui-ratchet, ci-guardrails, signoff]
tech-stack:
  added: []
  patterns:
    - Node-only Markdown verifier mirroring the Phase 200 sign-off pattern
    - fs.mkdtempSync scratch fixtures for acceptance and red-path proof
key-files:
  created:
    - scripts/ci/verify_ui_ratchet_signoff.mjs
  modified: []
key-decisions:
  - "The Phase 208 sign-off verifier imports only the read-only frozen ledger verifier, never the mutating reducer or freeze path."
  - "Final ACCEPT requires the zero-open row to cite scripts/ci/verify_ratchet_ledger.mjs --verify-frozen, so Markdown copy alone cannot approve the package."
  - "Evidence references are constrained to the Phase 208 directory, ratchet artifacts, CI scripts, the CI workflow, and test-results outputs."
patterns-established:
  - "ACCEPT evidence rows are validated both as Markdown contract copy and as live frozen-ledger verifier output."
  - "Runbook scope validation rejects Phase 208 full-admin-sweep mandates while allowing bounded follow-on surface/slice graduation."
requirements-completed: [CONV-01, CONV-02, CONV-05, CONV-06, CONV-07]
duration: 45 min
completed: 2026-07-07
status: complete
---

# Phase 208 Plan 02: UI Ratchet Sign-Off Verifier Summary

**Deterministic maintainer sign-off verifier for Phase 208 ACCEPT and bounded runbook evidence**

## Performance

- **Duration:** 45 min
- **Started:** 2026-07-07T20:41:00Z
- **Completed:** 2026-07-07T21:26:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `scripts/ci/verify_ui_ratchet_signoff.mjs`, a deterministic Phase-200-style verifier for `UI-RATCHET-SIGN-OFF.md`.
- Enforced required UI-SPEC sections, closed `Status` values, required runbook headings, the exact final ACCEPT line format, and concrete repo-relative evidence refs.
- Enforced ACCEPT evidence for no-key CI, deterministic guardrails, zero folded open findings, empty regression files, independent recompute, synthetic count-increase proof, persona regression proof, existing UI gates, and bundle freshness.
- Backed final ACCEPT with `verifyFrozenRatchetLedger()` so unfrozen placeholders, nonzero folded open findings, non-empty regression files, missing dry rounds, and score-floor failures block approval.
- Added self-tests for valid ACCEPT plus missing final line, duplicate final line, invalid status token, missing section, missing runbook heading, missing zero-open evidence, nonzero folded-open evidence, non-empty regression files, unfrozen/all-zero baselines, missing synthetic proof, missing existing gate evidence, pending existing gates, invalid refs, broad sweep language, and missing sign-off file.

## Task Commits

Each task was committed atomically:

1. **Tasks 1-2: Add Phase 208 sign-off verifier and ACCEPT red paths** - `7bf6ec8d` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `scripts/ci/verify_ui_ratchet_signoff.mjs` - New verifier, CLI, exports, fixture writer, and self-test suite.

## Decisions Made

- The verifier allows only `PASS`, `BLOCKED`, `PENDING`, and `N/A` in Markdown `Status` cells.
- Evidence refs reject absolute paths, backslashes, parent traversal, and paths outside the allowlisted evidence roots.
- Under final ACCEPT, existing UI gate and bundle freshness rows must be `PASS`; `PENDING`, `N/A`, or `BLOCKED` are verifier failures.
- The real sign-off file remains absent until Plan 05; the verifier now fails that path cleanly with the missing artifact instead of crashing.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The real `--require-accept` path correctly fails before Plan 05 because `UI-RATCHET-SIGN-OFF.md` does not exist yet. This is expected and is now reported as a normal verifier failure.
- Live frozen evidence, existing UI gate PASS rows, and the maintainer ACCEPT line remain owned by Plans 04 and 05.

## Verification

- `node scripts/ci/verify_ui_ratchet_signoff.mjs --self-test` - passed.
- `node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept` - failed as expected pre-sign-off with a missing `UI-RATCHET-SIGN-OFF.md` path and no crash.

## Self-Check: PASSED

- Required sections, statuses, runbook headings, final-line parsing, evidence refs, ACCEPT evidence rows, and frozen-ledger red paths are all covered by fixture self-tests.
- Fixtures write only under `fs.mkdtempSync` roots and do not touch real ratchet artifacts.

## User Setup Required

None - no external service configuration required for this verifier foundation.

## Next Phase Readiness

Plan 03 can wire the deterministic CI job to run the new sign-off verifier. Plans 04 and 05 remain responsible for producing the real frozen evidence and final maintainer ACCEPT artifact.

---
*Phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept*
*Completed: 2026-07-07*
