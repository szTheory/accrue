---
phase: 176-c-systematic-per-screen-rubric-uplift
plan: 05
subsystem: ui
tags: [accrue_admin, liveview, accessibility, typography, reading-measure, ax-measure, rubric, scorecard]

requires:
  - phase: 176-04
    provides: "fetch_live_flash pipeline fix enabling put_flash on nil redirects"
  - phase: 176-03
    provides: "Wave 2a uplift for CouponLive/EventLive dims ②③⑦⑩; ④ left at 1 pending pipeline fix"

provides:
  - "ax-measure on all 4 invoice_live prose regions (SCR-04 satisfied; dim ③ 2→3)"
  - "ax-measure on all 3 charge_live prose regions (gold standard confirmed)"
  - "put_flash not-found on coupon_live and event_live (dim ④ 1→2 for both)"
  - "coupon_not_found/0 and billing_event_not_found/0 copy keys"
  - "SCORECARD fully populated: all 21 screens have after-scores; Phase 176 Final Summary section"
  - "20 of 21 screens at all dims ≥2; 1 deferred (CampaignLive)"

affects:
  - 176-06
  - phase-179-visual-qa

tech-stack:
  added: []
  patterns:
    - "ax-measure applied at prose-paragraph level (class='ax-body ax-measure'), never to field-lists or data grids"
    - "put_flash(:error, Copy.not_found_key()) before redirect on nil-case mount — requires fetch_live_flash in router pipeline"

key-files:
  created:
    - ".planning/phases/176-c-systematic-per-screen-rubric-uplift/176-05-SUMMARY.md"
  modified:
    - "accrue_admin/lib/accrue_admin/live/invoice_live.ex"
    - "accrue_admin/lib/accrue_admin/live/charge_live.ex"
    - "accrue_admin/lib/accrue_admin/live/event_live.ex"
    - "accrue_admin/lib/accrue_admin/live/coupon_live.ex"
    - "accrue_admin/lib/accrue_admin/copy/coupon.ex"
    - "accrue_admin/lib/accrue_admin/copy/billing_event.ex"
    - "accrue_admin/lib/accrue_admin/copy.ex"
    - "accrue_admin/test/accrue_admin/live/invoice_live_test.exs"
    - "accrue_admin/test/accrue_admin/live/charge_live_test.exs"
    - "accrue_admin/test/accrue_admin/live/coupon_live_test.exs"
    - "accrue_admin/test/accrue_admin/live/event_live_test.exs"
    - ".planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md"

key-decisions:
  - "ax-measure applied to prose <p> elements only — not to form-description text inside action panels (subscription_live prose left at ③=2, consistent with anti-churn policy)"
  - "subscription_live confirmed all dims ≥2 with no changes needed (audit-only outcome)"
  - "CampaignLive deferred to Phase 179 — thin specialist screen (63 lines), 4 failing dims (②④⑦⑧), out of scope for Phase 176 code-review gate"
  - "dim ④ reconciliation: CouponLive and EventLive now have put_flash on nil-case redirects, making not-found state genuinely user-visible"

patterns-established:
  - "dim ④ upgrade pattern: add put_flash(:error, Copy.X_not_found()) + copy key + delegator + flash-redirect test"
  - "SCORECARD completion: Wave 3/4 rationale sections document each dim change with before→after notation"

requirements-completed: [SCR-01, SCR-02, SCR-03, SCR-04]

duration: 25min
completed: 2026-06-04
---

# Phase 176 Plan 05: Wave 4 Dense-Prose Reading-Measure + SCORECARD Completion Summary

**Reading-measure (ax-measure) applied to invoice_live and charge_live prose; CouponLive and EventLive dim ④ lifted from 1 to 2 via put_flash not-found redirects; SCORECARD fully populated with 20/21 screens at all dims ≥2**

## Performance

- **Duration:** 25 min
- **Started:** 2026-06-04T12:15:00Z
- **Completed:** 2026-06-04T12:40:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- invoice_live: added `ax-measure` to all 4 target prose paragraphs (tax-disabled-reason, finalization-failure, tax-recovery-body, actions-body), lifting dim ③ from 2 to 3
- charge_live: added `ax-measure` to all 3 target prose paragraphs (Braintree eligibility x2, refund-confirm), confirming gold-standard status with no dim score changes
- coupon_live and event_live: added `put_flash(:error, ...)` on nil-case redirects — dim ④ lifted 1→2 for both screens; `coupon_not_found/0` and `billing_event_not_found/0` copy keys added
- subscription_live: audited all 10 dimensions, confirmed all ≥2, no code changes made (anti-churn)
- SCORECARD completed: after-scores for all 21 screens, Wave 3/4 rationale sections, Phase 176 Final Summary section
- Suite grew from 239 to 245 tests with 0 failures

## Task Commits

1. **TDD RED: failing tests for ax-measure on invoice/charge prose** - `b497f96e` (test)
2. **Task 1: ax-measure + put_flash dim ④ uplift** - `b7482f28` (feat)
3. **Task 2: subscription_live audit + SCORECARD completion** - `ca88f665` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - ax-measure on 4 prose paragraphs (lines 263, 266, 269, 277)
- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - ax-measure on 3 prose paragraphs (lines 218, 219, 242)
- `accrue_admin/lib/accrue_admin/live/coupon_live.ex` - put_flash(:error, coupon_not_found()) on nil redirect
- `accrue_admin/lib/accrue_admin/live/event_live.ex` - put_flash(:error, billing_event_not_found()) on nil redirect
- `accrue_admin/lib/accrue_admin/copy/coupon.ex` - added `coupon_not_found/0`
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex` - added `billing_event_not_found/0`
- `accrue_admin/lib/accrue_admin/copy.ex` - added delegators for both new copy keys
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - 3 new tests (ax-measure on tax-risk prose, actions prose, NOT on field-lists)
- `accrue_admin/test/accrue_admin/live/charge_live_test.exs` - 2 new tests (ax-measure on Braintree prose, refund-confirm prose)
- `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` - 1 new test (redirects with flash when coupon not found)
- `accrue_admin/test/accrue_admin/live/event_live_test.exs` - updated existing redirect test to assert flash["error"] != nil
- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` - after-scores for all 21 screens + Wave 3/4 rationale + Phase 176 Final Summary

## Decisions Made

- subscription_live prose paragraphs in admin-actions section lack ax-measure but are form description text inside action panels — leaving ③=2 is correct per anti-churn (no dim below 2, no touch)
- CampaignLive deferred to Phase 179: was Wave 2 scope but never addressed in 176-03 or 176-04; 4 failing dims require structural changes (not CSS-only); out of scope for this wave
- ax-measure is NOT applied to `ax-empty-copy` (has its own `max-width: 28rem`), `ax-field-list` (columnar), or KPI/data grids (structured data)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added put_flash to coupon_live and event_live (dim ④ reconciliation)**

- **Found during:** Task 1 (project_specifics block stated this requirement explicitly)
- **Issue:** The project execution context required verifying that coupon_live and event_live actually have `put_flash(:error, ...)` on their not-found redirects. Both had silent redirects (`put_flash` never added during Wave 2a because the pipeline wasn't ready). Now that Wave 2b added `fetch_live_flash`, the dim ④ = 1 scores were genuinely fixable.
- **Fix:** Added `put_flash(:error, Copy.coupon_not_found())` / `put_flash(:error, Copy.billing_event_not_found())` to each nil-case redirect; added copy keys + delegators; added flash-redirect tests
- **Files modified:** coupon_live.ex, event_live.ex, copy/coupon.ex, copy/billing_event.ex, copy.ex, coupon_live_test.exs, event_live_test.exs
- **Verification:** All 245 tests pass; flash["error"] assertions verified
- **Committed in:** b7482f28 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing critical functionality, dim ④ uplift)
**Impact on plan:** Required by project_specifics; these were explicitly listed as a precondition for the SCORECARD final after-scores to be accurate. No scope creep.

## Issues Encountered

- DB "too_many_connections" error after several rapid sequential test runs. Resolved by waiting for connections to drain (transient, no code issue).

## Known Stubs

None — all prose regions wired to real Copy module functions, all ax-measure applied to actual template content.

## Threat Flags

None — only CSS class additions to existing `<p>` elements and `put_flash` calls on error paths. No new routes, network endpoints, user inputs, or schema changes.

## Self-Check: PASSED

Files exist:
- FOUND: .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md
- FOUND: accrue_admin/lib/accrue_admin/live/invoice_live.ex
- FOUND: accrue_admin/lib/accrue_admin/live/charge_live.ex

Commits verified:
- b497f96e: test(176-05): add failing tests for ax-measure
- b7482f28: feat(176-05): apply ax-measure + put_flash dim ④ uplift
- ca88f665: feat(176-05): subscription_live audit + SCORECARD completion

ax-measure counts:
- invoice_live.ex: 4 occurrences
- charge_live.ex: 3 occurrences

Suite: 245 tests, 0 failures

## Next Phase Readiness

- Phase 176-06 (SCORECARD assertion gate) is now unblocked: "Phase 176 Final Summary" section exists in 176-SCORECARD.md with all after-scores populated
- 20/21 screens at all dims ≥2; CampaignLive is the only exception (deferred to Phase 179)
- Phase 177 (motion audit) and Phase 179 (visual QA) can proceed with the complete scorecard as baseline

---
*Phase: 176-c-systematic-per-screen-rubric-uplift*
*Completed: 2026-06-04*
