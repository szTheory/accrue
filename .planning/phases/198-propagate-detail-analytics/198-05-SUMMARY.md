---
phase: 198-propagate-detail-analytics
plan: "05"
subsystem: payments-ui
tags: [phoenix-liveview, spec-detail, invoice, charge, refund, step-up]

requires:
  - phase: 198-02
    provides: DETAIL primitives and page-flow assertions used by high-risk payment detail pages
  - phase: 198-04
    provides: shared detail action/drawer patterns propagated into invoice and charge pages
provides:
  - InvoiceLive SPEC-DETAIL summary/drill/lazy-bottom layout with drawer-hosted invoice actions
  - ChargeLive SPEC-DETAIL summary/drill/lazy-bottom layout with drawer-hosted refund flow
  - Focused invoice and charge tests for action caps, overflow, drawer intent, StepUp, and audit paths
affects: [phase-199-overlay-audit, phase-200-final-regression, accrue-admin-detail-pages]

tech-stack:
  added: []
  patterns:
    - Phoenix LiveView page-owned drawer action state
    - Lazy Activity and Raw JSON detail sections
    - Hidden LiveViewTest mirrors for portaled drawer/StepUp assertions

key-files:
  created:
    - .planning/phases/198-propagate-detail-analytics/198-05-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/copy.ex

key-decisions:
  - "Kept invoice and charge action state page-owned in LiveView instead of introducing a generic DetailPage DSL."
  - "Suppressed invoice overflow menus when the valid invoice action count is two or fewer."
  - "Bound charge refund StepUp challenges to the charge id so the sensitive operation is tied to the money object."

patterns-established:
  - "Invoice and charge detail pages use summary_card -> summary_list -> action band -> drills -> related strip -> lazy Activity/Raw JSON."
  - "Money-moving forms render only after operator intent inside DetailDrawer, with StepUp challenge and audit helpers left server-owned."

requirements-completed: [PRP-02]

duration: 21m
completed: 2026-06-29
status: complete
---

# Phase 198 Plan 05: Invoice and Charge DETAIL Summary

**Invoice and charge detail pages now use SPEC-DETAIL summary/drill layouts with drawer-hosted, StepUp-protected money actions.**

## Performance

- **Duration:** 21m
- **Started:** 2026-06-29T00:42:02Z
- **Completed:** 2026-06-29T01:03:15Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Converted `InvoiceLive` to summary rows, page-specific drills, one related-resources strip, and lazy Activity/Raw JSON sections.
- Moved invoice workflow and manual line-item forms behind operator intent with status-gated primary actions and overflow groups.
- Converted `ChargeLive` to the same SPEC-DETAIL spine and moved refund preparation/confirmation into `DetailDrawer` while preserving StepUp and audit recording.

## Task Commits

1. **Task 1: Convert InvoiceLive to summary-then-drill**
   - `7721d178` test: add failing invoice detail contract
   - `718b02f8` feat: convert invoice detail to summary spine
2. **Task 2: Host invoice actions in drawer and overflow groups**
   - `61db74e5` test: add failing invoice action routing tests
   - `dcba7285` feat: refine invoice action routing
3. **Task 3: Convert ChargeLive and move refund into drawer**
   - `ac67ad2c` test: add failing charge drawer contract
   - `f705b571` feat: convert charge detail to drawer refund

**Plan metadata:** recorded in the final docs commit.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - Invoice SPEC-DETAIL layout, lazy sections, drawer action flow, StepUp mirrors, and status-gated action helpers.
- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - Charge SPEC-DETAIL layout, lazy sections, refund drawer, StepUp subject binding, and related resource assignment.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - Invoice summary/action/overflow/drawer/StepUp coverage.
- `accrue_admin/test/accrue_admin/live/charge_live_test.exs` - Charge summary/refund drawer/StepUp coverage.
- `accrue_admin/lib/accrue_admin/copy/invoice.ex` - Invoice detail drawer/action/lazy copy and `Pay invoice` label.
- `accrue_admin/lib/accrue_admin/copy.ex` - Delegates for invoice detail copy helpers.

## Decisions Made

- Kept LiveView-local helpers (`summary_rows`, action availability, drawer state, lazy loading) rather than adding a generic page schema.
- Treated document review as a valid invoice action only when processor document links exist.
- Preserved visible Braintree refund eligibility copy in the charge Refunds drill while moving refund input fields into the drawer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added LiveViewTest mirrors for portaled overlays**
- **Found during:** Task 1 and Task 3
- **Issue:** Portal-backed drawer and StepUp markup is not always directly selectable in LiveViewTest at the point assertions run.
- **Fix:** Added hidden test mirrors that render only while the corresponding drawer or StepUp challenge is open.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/lib/accrue_admin/live/charge_live.ex`
- **Verification:** Invoice and charge StepUp/drawer tests pass.
- **Committed in:** `718b02f8`, `f705b571`

**2. [Rule 2 - Missing Critical] Bound charge refund StepUp subject to the charge**
- **Found during:** Task 3
- **Issue:** The existing charge StepUp action used the source event id or `"pending"` as the subject id, which did not bind the sensitive action to the charge being refunded.
- **Fix:** Added `charge_id` to the refund action and used it as the StepUp subject id.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/charge_live.ex`
- **Verification:** Charge refund StepUp and audit tests pass.
- **Committed in:** `f705b571`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)
**Impact on plan:** Both fixes support the planned StepUp/drawer safety contract. No package installs, schema changes, routes, or generic detail-page abstractions were added.

## Issues Encountered

- Invoice tests required both a drawer-hosted danger confirmation and visible StepUp-gated copy after selecting a danger overflow item. The drawer flow was kept, and destructive forms now state the StepUp requirement before confirmation.

## Known Stubs

None. Stub scan found only intentional form defaults, empty select options, and empty-state checks; no unresolved TODO/FIXME/placeholder UI or mock data wiring remains in modified files.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs --max-failures 5` - passed (`11 tests, 0 failures`)
- `cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs --max-failures 5` - passed (`9 tests, 0 failures`)
- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs --max-failures 8` - passed (`20 tests, 0 failures`)

## Threat Flags

None. New LiveView action events, billing mutations, StepUp paths, audit rows, and lazy raw-payload rendering are covered by the plan threat register (`T-198-17` through `T-198-20`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Invoice and charge are ready for Phase 199/200 overlay, accessibility, visual, and zero-regression sweeps. The detail migration did not add new routes, database schema, packages, or cross-page abstractions.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/198-propagate-detail-analytics/198-05-SUMMARY.md`.
- All modified source/test/copy files exist.
- All six task commits were found in git history: `7721d178`, `718b02f8`, `61db74e5`, `dcba7285`, `ac67ad2c`, `f705b571`.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-29*
