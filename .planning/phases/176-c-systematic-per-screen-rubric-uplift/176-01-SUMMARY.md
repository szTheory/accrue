---
phase: 176-c-systematic-per-screen-rubric-uplift
plan: "01"
subsystem: ui
tags: [phoenix-live-view, css, responsive, rubric, admin-ui, data-table]

requires: []
provides:
  - "176-SCORECARD.md: per-screen × 10-dimension before-scores for all 21 admin screens"
  - "data-table card/table swap breakpoint moved from --ax-bp-lg (1024px) to --ax-bp-md (768px)"
  - "overflow-x: auto defensive guard added to .ax-data-table-shell"
affects:
  - "176-02 (Wave 1 list screens): uses SCORECARD before-scores as anti-churn tokens"
  - "176-03 (Wave 2 catalog/specialist detail): uses SCORECARD before-scores"
  - "176-04 (Wave 3 dense financial detail): uses SCORECARD before-scores"
  - "176-05 (Wave 4 specialist screens): uses SCORECARD before-scores"
  - "179 (F — Screenshot Visual QA): uses SCORECARD as verification baseline"

tech-stack:
  added: []
  patterns:
    - "SCORECARD.md as anti-churn justification artifact: every wave task cites a before-score < 2 to justify its change"
    - "Breakpoint registry comment convention: every @media carries --ax-bp-* token comment for grep-ability"

key-files:
  created:
    - ".planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md"
  modified:
    - "accrue_admin/assets/css/app.css"
    - "accrue_admin/priv/static/accrue_admin.css"

key-decisions:
  - "600/640 breakpoint reconciliation: document, do not collapse — --ax-bp-sm (599.98px) hides chrome, --ax-bp-content (640px) promotes content; distinct intents; 40px gap is not visible at 360px"
  - "data-table collapse breakpoint: moved from --ax-bp-lg (1024px) to --ax-bp-md (768px) per CONTEXT locked decision D; tablets now see table, phones see cards"
  - "overflow-x: auto added proactively to .ax-data-table-shell to prevent horizontal scroll at 768px on widest tables (invoices, webhooks)"

patterns-established:
  - "Worst-first ordering from SCORECARD: CouponLive and EventLive are lowest-scoring (min 1, 4-5 dims failing)"
  - "List screens: all 9 already have card_fields/card_title wired; CSS fix is the entire Wave 1 story"
  - "Detail tail screens (coupon, event, promotion_code, campaign): need Detail.summary_card/detail_field_list DRY uplift in Wave 2"

requirements-completed: [SCR-01, SCR-02, SCR-03, SCR-04]

duration: 4min
completed: "2026-06-04"
---

# Phase 176 Plan 01: Wave 0 Baseline + CSS Breakpoint Fix Summary

**21-screen × 10-dimension baseline SCORECARD captured and data-table card/table swap moved from --ax-bp-lg (1024px) to --ax-bp-md (768px), simultaneously lifting rubric ⑤ for all 9 list screens**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T15:48:11Z
- **Completed:** 2026-06-04T15:52:02Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created 176-SCORECARD.md with before-scores for all 21 admin screens across 10 rubric dimensions, 600/640 reconciliation rationale, worst-first ordering, and empty after-scores stub for downstream waves
- Fixed data-table breakpoint: `.ax-data-table-shell`/`.ax-data-table-cards` swap now fires at `--ax-bp-md` (768px) not `--ax-bp-lg` (1024px); tablets (768-1023px) now see table view
- Added `overflow-x: auto` defensive guard to `.ax-data-table-shell` to prevent horizontal scroll at 768px on widest tables (invoices, webhooks) per RESEARCH §Pitfall 3
- Rebuilt `priv/static/accrue_admin.css` and committed; suite stays at 227 green

## Task Commits

1. **Task 1: Capture 176-SCORECARD.md baseline** - `83561979` (docs)
2. **Task 2: Fix data-table collapse breakpoint + asset rebuild** - `ebba5113` (fix)

## Files Created/Modified

- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` — 21-screen × 10-dim before-scores, 600/640 reconciliation, worst-first ordering, after-scores stub
- `accrue_admin/assets/css/app.css` — breakpoint moved 1024px→768px; overflow-x:auto added to .ax-data-table-shell
- `accrue_admin/priv/static/accrue_admin.css` — rebuilt bundle

## Decisions Made

- **600/640 breakpoint reconciliation:** Document, do not collapse. Both rungs serve distinct intents (`--ax-bp-sm ↓` hides chrome at 599.98px max-width; `--ax-bp-content ↑` promotes content at 640px min-width). The 40px gap is not observable at the 360px design target.
- **overflow-x: auto pre-emptively added:** Rather than wait to see if widest tables overflow at 768px (requiring a follow-up commit), added the guard in the same commit per RESEARCH §Pitfall 3 recommendation. This is correct-by-construction rather than detect-and-fix.

## Deviations from Plan

None — plan executed exactly as written. Both tasks executed in order. The `overflow-x: auto` addition was specified in the plan's Task 2 action and is not a deviation.

## Issues Encountered

None.

## Known Stubs

None — this plan creates a planning artifact (SCORECARD.md) and a CSS fix. No UI data sources or rendering stubs introduced.

## Threat Flags

No new routes, endpoints, auth paths, or schema changes introduced. CSS-only and planning-artifact-only changes. No threat surface expansion.

## Next Phase Readiness

- **Wave 0 complete:** SCORECARD.md is the anti-churn token source for all subsequent wave tasks
- **List screens (Wave 1):** All 9 now pass rubric ⑤ (breakpoint fixed). Wave 1 task is to audit card_fields quality and confirm card_title meaningfulness per the SCORECARD before-scores
- **Tail detail screens (Wave 2):** CouponLive (min 1, 5 dims), EventLive (min 1, 4 dims), PromotionCodeLive (min 1, 4 dims), CampaignLive (min 1, 4 dims) need structural/DRY uplift
- No blockers; suite is 227 green

## Self-Check: PASSED

- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` exists: FOUND
- `accrue_admin/assets/css/app.css` contains `min-width: 768px.*--ax-bp-md`: 3 instances FOUND
- `83561979` (Task 1 commit) exists: FOUND
- `ebba5113` (Task 2 commit) exists: FOUND
- Suite: 227 tests, 0 failures

---
*Phase: 176-c-systematic-per-screen-rubric-uplift*
*Completed: 2026-06-04*
