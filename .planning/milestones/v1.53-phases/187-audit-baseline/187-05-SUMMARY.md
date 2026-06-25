---
phase: 187-audit-baseline
plan: "05"
subsystem: verification
tags: [audit-baseline, playwright, baseline-ledger, visual-audit, admin-ui]

requires:
  - phase: 187-audit-baseline
    provides: Static baseline capture, live interaction probes, rubric contract, and artifact schemas from Plans 187-01 through 187-04
provides:
  - Only-forward Phase 187 baseline summary
  - Canonical baseline cell JSON for Phase 192 comparison
  - Severity-ranked AX187 defect ledger routed to Phases 188-191
  - Artifact manifest with producer command status, evidence paths, and checksums
affects: [phase-187, phase-188, phase-189, phase-190, phase-191, phase-192, VER-01]

tech-stack:
  added: []
  patterns: [non-aborting-audit-wrapper, structured-baseline-contract, representative-defect-ledger]

key-files:
  created: []
  modified:
    - accrue_admin/e2e/baseline-artifacts.mjs
    - .planning/phases/187-audit-baseline/187-BASELINE.md
    - .planning/phases/187-audit-baseline/baseline.cells.json
    - .planning/phases/187-audit-baseline/defects.ndjson
    - .planning/phases/187-audit-baseline/artifacts.manifest.json

key-decisions:
  - "Playwright producer failures with trace/log evidence are baseline observations, not harness failures."
  - "Absent Anthropic vision credentials record vision scoring as unavailable instead of blocking artifact generation."
  - "baseline.cells.json keeps per-cell truth; defects.ndjson aggregates representative, routeable AX187 defect classes."

patterns-established:
  - "Phase 187 artifact generation stages producer evidence so Playwright output cleanup cannot erase prior producer results."
  - "baseline.cells.json is schema-contracted to the approved cell fields before write."
  - "defects.ndjson IDs are assigned after severity/owner sorting so the ledger stays stable and schema-valid."

requirements-completed: [VER-01]

duration: 44m
completed: 2026-06-15
---

# Phase 187 Plan 05: Audit Run and Canonical Baseline Ledger Summary

**Only-forward admin UI audit baseline with 21,276 scored cells, 800 AX187 defect rows, and a checksum-backed evidence manifest**

## Performance

- **Duration:** 44m
- **Started:** 2026-06-15T02:19:00Z
- **Completed:** 2026-06-15T03:10:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Ran the Phase 187 producer set and preserved evidence for all required commands: static baseline, live interactions, a11y, and optional visual scoring.
- Generated `.planning/phases/187-audit-baseline/baseline.cells.json` with 21,276 cells, including 200 targeted breakpoint rows and 100 live-interaction rows.
- Generated `.planning/phases/187-audit-baseline/defects.ndjson` with 800 schema-shaped AX187 rows, including 33 live-interaction defects and 31 rows with overlay tags.
- Generated `.planning/phases/187-audit-baseline/artifacts.manifest.json` with 4,250 evidence references and zero harness failures.
- Expanded `.planning/phases/187-audit-baseline/187-BASELINE.md` with maintainer-readable coverage, severity, owner-phase, and rerun-command summaries.

## Task Commits

Each task was committed atomically:

1. **Task 1: Run the static and interaction audit evidence** - `dc8a442f` (fix)
2. **Task 2: Finalize canonical baseline and defect ledger** - `251a41a0` (docs)

## Files Created/Modified

- `accrue_admin/e2e/baseline-artifacts.mjs` - Classifies non-aborting producer evidence, optional vision gaps, representative defect rows, and schema-contracted cell output.
- `.planning/phases/187-audit-baseline/artifacts.manifest.json` - Canonical evidence manifest with checksums, producer observations, and empty `harness_failures`.
- `.planning/phases/187-audit-baseline/baseline.cells.json` - Canonical Phase 192 comparison data.
- `.planning/phases/187-audit-baseline/defects.ndjson` - Severity-ranked AX187 defect ledger.
- `.planning/phases/187-audit-baseline/187-BASELINE.md` - Maintainer-readable only-forward baseline summary.

## Decisions Made

- Kept screenshots, traces, raw Playwright output, and logs under `accrue_admin/test-results`; no generated PNG or ZIP evidence was committed.
- Fixed the targeted-viewport restoration bug identified by review and reran the full producer set cleanly, so both desktop and mobile static baseline runs now exit 0.
- Aggregated cell-level gaps into representative defect classes so IDs remain schema-valid (`AX187-[0-9]{3}`) while the complete cell matrix remains canonical in `baseline.cells.json`.

## Deviations from Plan

### Auto-fixed Issues

**1. Artifact generator did not route no-key vision and raw gap evidence**
- **Found during:** Task 1 (Run the audit evidence)
- **Issue:** The generator treated absent `admin-visuals/findings.ndjson` as a harness failure and only produced defects from vision findings, which made the no-`ANTHROPIC_API_KEY` path block and left the ledger empty.
- **Fix:** Classified missing vision findings as `vision-scoring-unavailable`, routed nonzero producer exits with trace/log evidence into observations, generated representative AX187 defects from gap cells, and filtered `.DS_Store` from evidence inventory.
- **Files modified:** `accrue_admin/e2e/baseline-artifacts.mjs`, `artifacts.manifest.json`
- **Verification:** `npm run baseline:artifacts`, `npm run baseline:parse`, manifest harness check, command-status check.
- **Committed in:** `dc8a442f`

**2. Baseline cell output included fields outside the approved schema**
- **Found during:** Task 2 (Finalize canonical baseline and defect ledger)
- **Issue:** Manifest-derived cells carried `persona_job` and `owner_phase`, but `baseline-cell.schema.json` has `additionalProperties: false`.
- **Fix:** Contracted every baseline cell to schema-approved fields before writing JSON while keeping persona/owner metadata in defect rows.
- **Files modified:** `accrue_admin/e2e/baseline-artifacts.mjs`, `baseline.cells.json`
- **Verification:** Schema-key sanity check passed for all baseline cells and defect rows.
- **Committed in:** `dc8a442f` / `251a41a0`

---

**Total deviations:** 2 auto-fixed.
**Impact on plan:** Both fixes were required to satisfy the existing Phase 187 contract. No product UI, production auth, route, dependency, or generated binary evidence scope was added.

## Issues Encountered

- The initial `admin-baseline` run exited 1 on the mobile project because `page.screenshot` timed out after targeted probes left the shared page viewport mutated. The review fix restores the original project viewport after targeted probes; the refreshed producer run exits 0 for `admin-baseline`.
- `score-visuals` exited 0 through the intended no-key path because `ANTHROPIC_API_KEY` was not set.
- Earlier interrupted execution left partial artifacts; they were regenerated from the completed producer status and evidence before commit.

## Verification

- `cd accrue_admin && npm run baseline:artifacts && npm run baseline:parse` passed.
- Manifest check passed: `harness_failures` is empty and command status includes `admin-baseline`, `admin-interactions`, `admin-a11y`, and `score-visuals`.
- Baseline cell check passed: 21,276 cells, 200 targeted rows, 100 interaction rows, no legacy `targeted-*` mode values, and every gap/n/a row has notes.
- Defect ledger check passed: 800 rows, IDs `AX187-001` through `AX187-800`, owner phases limited to `188`-`191`, and required D-19 fields present.
- Schema-key sanity passed for `baseline.cells.json` and `defects.ndjson`.
- Git check passed: no `.png` or `.zip` generated evidence is staged or committed.

## User Setup Required

None - no external service configuration required. Setting `ANTHROPIC_API_KEY` remains optional for future vision scoring.

## Next Phase Readiness

Phases 188-191 can consume `defects.ndjson` by `owner_phase`, and Phase 192 can compare against `baseline.cells.json` as the canonical only-forward baseline.

---
*Phase: 187-audit-baseline*
*Completed: 2026-06-15*
