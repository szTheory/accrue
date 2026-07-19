---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 07
subsystem: testing
tags: [ui-ratchet, digest, html, ledger, node]

# Dependency graph
requires:
  - phase: 207-04
    provides: ratchet-digest.mjs offline HTML digest renderer and decisions.json contract
  - phase: 207-05
    provides: mix accrue_admin.ui.round digest subprocess sequencing
provides:
  - "ratchet-digest.mjs accepts proposer rows where suggested_fix is null"
  - "Digest rendering omits absent optional suggested-fix prose without printing null/undefined"
  - "Self-test coverage for CR-01 null suggested_fix and unchanged required-field strictness"
affects: [207-08, 208-convergence, ui-ratchet-round]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Optional LLM prose fields are rendered only when present and always through escapeHtml"
    - "Required ledger row identity/location/defect fields remain validated before digest rendering"

key-files:
  created: []
  modified:
    - accrue_admin/e2e/ratchet/ratchet-digest.mjs

key-decisions:
  - "Treated suggested_fix as optional at the digest boundary rather than changing proposer output, preserving the existing candidate schema contract."
  - "Omitted the suggested-fix paragraph when optional prose is absent instead of inventing fallback copy from defect prose."

patterns-established:
  - "CR-01 regression fixture: validateDigestRows accepts suggested_fix:null while still rejecting missing defect."

requirements-completed: [ORCH-01, ORCH-02]

# Metrics
duration: 9 min
completed: 2026-07-07
status: complete
---

# Phase 207 Plan 07: Optional Digest Suggested Fix Summary

**The round digest now renders ordinary proposer output where `suggested_fix` is null while preserving strict validation for required identity, location, severity, frequency, and defect fields.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-07T12:07:00Z
- **Completed:** 2026-07-07T12:16:45Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Removed `suggested_fix` from `REQUIRED_ROW_FIELDS` so valid ledger rows from `ratchet-propose.mjs` no longer abort digest generation.
- Updated `renderFindingRow()` to render optional suggested-fix prose only when present, with all present prose still routed through `escapeHtml()`.
- Extended `ratchet-digest.mjs --self-test` to prove null optional prose renders safely, decisions rows still summarize from `defect`, required `defect` remains strict, and present optional prose is escaped.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make `suggested_fix` optional in digest validation and rendering** - `51d9ea70` (fix)

## Files Created/Modified
- `accrue_admin/e2e/ratchet/ratchet-digest.mjs` - Optional `suggested_fix` validation/rendering plus CR-01 regression self-tests.

## Decisions Made
- Keep proposer output unchanged; digest adapts to the existing optional field contract.
- Omit absent optional prose instead of rendering placeholder copy, avoiding invented fixes and literal `null`/`undefined`.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** CR-01 is closed without broadening required-field acceptance beyond the optional field identified by verification.

## Issues Encountered
None.

## Verification
- `cd accrue_admin && node e2e/ratchet/ratchet-digest.mjs --self-test` — passed.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
The `ui.round` digest step can now complete when the proposer emits `suggested_fix:null`; Phase 207 can proceed to the remaining guard-mint and `ui.fix` commit-scope gap.

---
*Phase: 207-orchestration-digest-one-command-round-fix-loop*
*Completed: 2026-07-07*

## Self-Check: PASSED
- Modified file exists on disk.
- Task commit `51d9ea70` found in git history.
- Self-test covers the null optional field and required-field failure paths.
