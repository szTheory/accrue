---
phase: 176-c-systematic-per-screen-rubric-uplift
plan: "02"
subsystem: ui
tags: [liveview, admin-ui, rubric, card_fields, card_title, mobile, data_table]

requires:
  - phase: 176-01
    provides: CSS breakpoint fix that moved all 9 list screens from ⑤=1 to ⑤=2

provides:
  - "All 9 list screens passing all rubric dimensions (min score ≥2)"
  - "SCORECARD Wave 1 after-scores for all 9 list screens documented"
  - "webhooks_live card_fields status-first order for developer triage persona"

affects:
  - 176-03
  - 176-04

tech-stack:
  added: []
  patterns:
    - "Anti-churn rule: only edit list screens where SCORECARD before-score < 2 or confirmed persona-job miss"
    - "Webhooks mobile card: status before type — triage field surfaces first on narrow viewports"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md

key-decisions:
  - "chargesLive 5-field card_fields retained: billing_signals (ownership+tax health) is decision-critical for payment-support persona, not a verbose extra column"
  - "webhooksLive card_fields reordered status-first: developer debugging needs failure-triage on mobile before type context"
  - "7 of 9 list screens needed zero code changes: Wave 0 CSS fix alone lifted all to ⑤=2"

patterns-established:
  - "SCORECARD anti-churn: copy before-score ≥2 as after-score with no-change annotation rather than leaving blanks"

requirements-completed:
  - SCR-01
  - SCR-02
  - SCR-03
  - SCR-04

duration: 10min
completed: "2026-06-04"
---

# Phase 176 Plan 02: Wave 1 List Screens Card Quality Audit Summary

**All 9 list screens confirmed passing all rubric dimensions: Wave 0 CSS fix resolved ⑤ for every list screen; webhooks card_fields reordered status-first for developer triage persona.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-04T11:50:00Z
- **Completed:** 2026-06-04T11:57:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Audited all 9 list screens against SCORECARD before-scores and persona-job criteria
- Confirmed 7 of 9 screens needed zero code changes (anti-churn rule held)
- Fixed webhooks_live card_fields ordering: status before type for developer debugging persona
- Documented Wave 1 after-scores in SCORECARD for all 9 list screens with per-screen rationale
- Full suite remains green at 227 tests, 0 failures

## Task Commits

1. **Task 1: Audit and fix tail list screens card_title/card_fields quality** - `e736fa9a` (feat)
2. **Task 2: Audit polished list screens + update SCORECARD Wave 1 after-scores** - `a325df10` (docs)

**Plan metadata:** to be committed with this SUMMARY

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` — card_fields reordered: status first, type second (developer triage persona)
- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` — Wave 1 after-scores populated for all 9 list screens

## Decisions Made

- **ChargesLive 5-field card_fields retained**: Billing signals column is a compound "ownership + tax health" pair, both fields genuinely decision-critical for the payment-support/finance-ops persona working the failed-payment queue. Not a verbose extra column. No change made.
- **WebhooksLive card_fields reordered**: Status (delivered/failed/dead-letter) surfaces before Type on mobile card. Developer debugging persona needs to see failure state first to decide triage action; type provides secondary context only. One-line reorder in card_fields, no schema or data change.
- **All other 7 list screens**: Confirmed all dimensions ≥2 with no persona-job misses. SCORECARD before-scores of 2+ copy-forwarded as after-scores with "no changes" annotations per anti-churn protocol.

## Deviations from Plan

None — plan executed exactly as written. The anti-churn analysis confirmed the expected result: CSS breakpoint fix from Wave 0 was sufficient for 8 of 9 screens; webhooks needed only a 1-line card_fields reorder as explicitly called out in the plan.

## Issues Encountered

None.

## Known Stubs

None — all list screen card_fields render live data from the shared query layer. No placeholder values.

## Threat Surface Scan

No new routes, endpoints, user inputs, or trust-boundary surface introduced. Only a card_fields field order change in webhooks_live.ex and a planning doc update.

## Next Phase Readiness

- All 9 list screens now have SCORECARD after-scores confirming min ≥2 on all dimensions
- SCORECARD Wave 2 targets remain: CouponLive, PromotionCodeLive, EventLive, CampaignLive (detail screens)
- Plan 176-03 (Wave 2 detail screen uplift) can proceed immediately

---
*Phase: 176-c-systematic-per-screen-rubric-uplift*
*Completed: 2026-06-04*
