---
phase: 241-billing-operator-journeys
plan: "02"
subsystem: billing-ui
tags: [phoenix-liveview, scoped-navigation, invoices, owner-scope]

requires:
  - phase: 240
    provides: Shared Admin detail patterns, route owners, and scoped navigation contract
provides:
  - ScopedPath return destinations with a path and a label derived from one validated local meaning
  - Invoice detail links that name and restore supported invoice list context
affects: [241-03, 241-04, 241-07]

actuals:
  tokens: 4839
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - Preserve only parameters consumed by the destination decoder and rebuild with the current owner.
    - Accept recognized query-free origins; reject malformed, duplicate, cross-mount, external, and wrong-customer origins.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/test/accrue_admin/scoped_path_test.exs
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs

key-decisions:
  - "Return labels identify the destination family and customer context from the validated path and retained filters."
  - "Unsupported sort and cursor state is discarded; invoice status, search, customer, collection method, and all-invoices lens are retained."

requirements-completed: [JRN-02]

coverage:
  - id: D1
    description: Scoped return destinations validate supported route meaning, rebuild the current owner, and pair the destination with an accurate label.
    requirement: JRN-02
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/scoped_path_test.exs#return destination labels and paths share supported invoice meaning in both mounts
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/scoped_path_test.exs#ambiguous malformed external scheme-relative and cross-mount origins use fallback
        status: pass
    human_judgment: false
  - id: D2
    description: Invoice detail returns restore supported list filters and exact authorized invoice membership with an accurate label.
    requirement: JRN-02
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/invoice_live_test.exs#invoice return restores supported list filters exact authorized results and query-free routes
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/invoice_live_test.exs#invoice contextual return rebuilds active owner scope and rejects foreign customer origin
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-10-10
status: complete
plan_head_before: 4979d2c9b698ebdabdd492ee65156369b0c97ea8
plan_head_after: 2416961fecd9397829114b99cd32ca632e6e85b3
---

# Phase 241 Plan 02: Validated Invoice Return Journeys Summary

**Invoice detail now returns to supported invoice or customer contexts with the current owner and a link label that matches the validated destination.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-10T01:26:36Z
- **Completed:** 2026-10-10T01:31:36Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `ScopedPath.return_destination/5` as the shared source for validated local destination paths and contextual labels while retaining the existing `return_path` arities.
- Expanded supported return meanings to match existing invoice, payment, subscription, customer-tab, and Recovery decoders; dropped unsupported sorting/cursor parameters and rejected ambiguous or unsafe origins.
- Updated invoice detail to render the paired destination label and path, with integration coverage for restored filters, query-free invoice origins, same-mount customer tabs, malformed input, and owner isolation.

## Task Commits

1. **Task 1: Make ScopedPath decode only supported local return meanings** - `99b071c9` (feat)
2. **Task 2: Give invoice detail an accurate contextual return** - `2416961f` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/scoped_path.ex` - Validates and rebuilds supported local return meanings and supplies destination labels.
- `accrue_admin/test/accrue_admin/scoped_path_test.exs` - Covers supported values, query-free destinations, both Admin mounts, owner rebuilding, and hostile origins.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - Uses the validated path/label pair for the explicit invoice return.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - Verifies link agreement, exact authorized invoice membership, query-free paths, and safe fallback.

## Decisions Made

- Destination labels use the validated route family and customer context; caller-provided labels and owner values do not influence the result.
- Invoice lists preserve only the existing decoder's search, status, customer, collection-method, and `view=all` meanings. Unsupported sort and cursor keys are omitted.

## Deviations from Plan

**1. [Rule 1 - Bug] Reject malformed percent escapes in return queries**
- **Found during:** Task 1
- **Issue:** The URI query decoder accepted an invalid percent escape as literal text instead of rejecting the ambiguous input.
- **Fix:** Added explicit percent-escape validation and a focused fallback assertion.
- **Files modified:** `accrue_admin/lib/accrue_admin/scoped_path.ex`, `accrue_admin/test/accrue_admin/scoped_path_test.exs`
- **Verification:** ScopedPath suite passed (12 tests, 0 failures).
- **Committed in:** `99b071c9`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Necessary boundary hardening; no scope change.

## Issues Encountered

- The first multi-owner fixture used the same processor/owner uniqueness key as the initial customer. Giving the second authorized fixture a different processor resolved the collision without changing production behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 241-02 is complete. JRN-02 remains pending globally until the other plans that declare it are complete. Plan 241-07 owns the combined browser and served-asset checks.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Evaluation scope resolved this plan and found both task commits on the current branch.
- Both summary files' listed source and test files exist; the planned focused suite passed (36 tests, 0 failures).
- Coverage assertions record passing unit and integration tests with `human_judgment: false`.

