---
phase: 191-page-flow-interaction-pass-fixture-stress-microcopy
plan: 01
subsystem: testing
tags: [playwright, e2e, ax187, admin-ui, page-flow]

requires:
  - phase: 187-audit-baseline
    provides: AX187 defect ledger and baseline manifest contract
  - phase: 190-navigation-data-display-meta-component-cohesion
    provides: D-30 Phase 191 handoff categories and group-contract E2E style
provides:
  - Manifest-driven Phase 191 page-flow helper utilities
  - AX187-tagged Phase 191 Playwright regression target
  - Source-level owner-phase 191 AX187 coverage audit
affects: [phase-191, phase-192, admin-e2e, ax187-verification]

tech-stack:
  added: []
  patterns:
    - CommonJS Playwright helper modules consuming baseline-manifest.js as the page source of truth
    - Source coverage audit requiring direct AX187 high-severity citations

key-files:
  created:
    - accrue_admin/e2e/phase191-page-flow-helpers.js
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js
    - scripts/ci/verify_phase191_ax187_coverage.mjs
  modified:
    - accrue_admin/package.json

key-decisions:
  - "Phase 191 page-flow inventory derives from baseline-manifest.js, not a second route list."
  - "High-severity owner_phase 191 AX187 rows must be directly cited in the Phase 191 spec; medium rows may be covered by AX187 ID or normalized overlay tag."

patterns-established:
  - "phase191PageFlows() filters manifest SURFACES by surface_type === page-flow."
  - "verify_phase191_ax187_coverage.mjs supports PHASE191_SPEC_PATH for negative coverage checks."

requirements-completed: [IXN-01, IXN-02, IXN-03, IXN-04, IXN-05, PAGE-01, PAGE-02, PAGE-03, PAGE-04, CPY-01, CPY-02, CPY-03]

duration: 12 min
completed: 2026-06-19
status: complete
---

# Phase 191 Plan 01: Page-Flow Harness Summary

**Manifest-owned Playwright page-flow harness with AX187 owner-phase 191 source coverage enforcement.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-19T14:25:00Z
- **Completed:** 2026-06-19T14:37:03Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added shared Phase 191 Playwright helpers for manifest page-flow discovery, route resolution, theme switching, AX187 defect loading, and focus/pointer/scroll/clipping assertions.
- Added a Phase 191 Playwright spec carrying explicit AX187 IDs and tags for fixtures, copy, responsive, overlay, focus, scroll, and reconnect categories.
- Added a deterministic AX187 coverage audit that verifies 178 owner_phase 191 rows, including 70/70 direct high-severity citations and 108/108 medium ID/tag coverage.

## Task Commits

1. **Task 1: Create manifest-driven Phase 191 helper utilities** - `1e2f9581` (test)
2. **Task 2: Add the Phase 191 page-flow browser spec** - `271581c2` (test)
3. **Task 3: Add AX187 source coverage audit** - `fc857ee8` (test)

## Files Created/Modified

- `accrue_admin/e2e/phase191-page-flow-helpers.js` - Shared Phase 191 helper module and assertion utilities.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` - AX187-tagged Phase 191 Playwright regression target.
- `scripts/ci/verify_phase191_ax187_coverage.mjs` - Source audit for owner_phase 191 AX187 coverage.
- `accrue_admin/package.json` - Added `e2e:phase191` script only; the pre-existing unstaged `e2e:group-contracts` script remains outside these commits.

## Decisions Made

- Kept the Phase 191 page-flow inventory manifest-owned by consuming `baseline-manifest.js` through the helper module.
- Made high-severity coverage stricter than medium coverage: high rows must be direct AX187 IDs in the spec; medium rows can be direct IDs or normalized overlay tag markers.
- Kept the Phase 191 fixture endpoint optional in the spec because Plan 02 owns that endpoint; the spec already calls it when present.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed audit handoff category normalization**
- **Found during:** Task 3 (AX187 source coverage audit)
- **Issue:** The audit normalized the handoff prose category "LiveView patch focus" through the tag alias table, turning it into `live-focus` and falsely reporting that the handoff source lacked the category.
- **Fix:** Added plain text normalization for handoff prose while retaining tag aliasing for spec/helper marker checks.
- **Files modified:** `scripts/ci/verify_phase191_ax187_coverage.mjs`
- **Verification:** `node scripts/ci/verify_phase191_ax187_coverage.mjs` passed; the temporary-spec negative test still failed as expected when `AX187-049` was removed.
- **Committed in:** `fc857ee8`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fix corrected the audit without widening scope.

## Issues Encountered

- `accrue_admin/package.json` already had an unstaged `e2e:group-contracts` script. The Phase 191 commit staged only the new `e2e:phase191` hunk and left the existing hunk unstaged.

## Known Stubs

None. Stub scan only found intentional default empty object/array locals in helper/spec code paths, not UI-rendered placeholder data.

## Authentication Gates

None.

## Verification

- `cd accrue_admin && node --check e2e/phase191-page-flow-helpers.js`
- `cd accrue_admin && node --check e2e/admin-page-flow-phase191.spec.js`
- `node -e "const h=require('./accrue_admin/e2e/phase191-page-flow-helpers.js'); if (h.phase191PageFlows().length !== 21) throw new Error('page-flow count'); if (h.loadPhase191Defects().length !== 178) throw new Error('AX187 count'); console.log('phase191 helpers ok')"`
- `node -e "const pkg=require('./accrue_admin/package.json'); if (!pkg.scripts['e2e:phase191']) throw new Error('missing e2e:phase191'); if (/npm install|playwright install/.test(pkg.scripts['e2e:phase191'])) throw new Error('unexpected install in script'); console.log('phase191 script ok')"`
- `node scripts/ci/verify_phase191_ax187_coverage.mjs`
- Temporary copy negative check: removing `AX187-049` from the spec made `verify_phase191_ax187_coverage.mjs` exit non-zero with a missing high-severity citation report.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can add the Phase 191 fixture endpoint and seed/state forcing against the already-created `e2e:phase191` spec. Later implementation plans can make the corrected-behavior browser assertions green without inventing another page inventory or AX187 coverage map.

## Self-Check: PASSED

- Created files exist: helper, spec, AX187 audit, and summary.
- Task commits found: `1e2f9581`, `271581c2`, `fc857ee8`.
- Verification rerun passed: `node scripts/ci/verify_phase191_ax187_coverage.mjs`.

---
*Phase: 191-page-flow-interaction-pass-fixture-stress-microcopy*
*Completed: 2026-06-19*
