---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
plan: 03
subsystem: admin
tags: [phoenix-liveview, billing-catalog, coupons, promotion-codes]
requires:
  - phase: 238-01
    provides: Admin billing read-only surfaces and owner-scope navigation patterns.
provides:
  - Coupon detail distinguishes unavailable reads from missing records and retries local reads.
  - Promotion-code detail distinguishes unavailable reads from missing records and retries its parent-coupon projection.
affects: [admin-billing-inspection, coupons, promotion-codes]
actuals:
  tokens: 4231
  tasks: 2
  commits: 2
plan_head_before: 0abfc406f9ade847e2e7736fb6fa71c108679de9
plan_head_after: b01f3bc323da6e78854992e67f6523a57f623f16
tech-stack:
  added: []
  patterns:
    - Expected DBConnection read failures are generic unavailable states with retry; backend details remain private.
key-files:
  created: []
  modified:
    - .planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-03-PLAN.md
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
key-decisions:
  - Coupon and promotion-code catalog records are global platform projections; active organization context is preserved in navigation without implying tenant ownership.
  - Detail read recovery catches only DBConnection.ConnectionError and treats record facts as unknown until a retry succeeds.
requirements-completed: [ADM-08]
coverage:
  - id: D1
    description: Coupon details preserve terms and related promotion-code identity, and recover safely from unavailable local reads.
    requirement: ADM-08
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/coupons_live_test.exs and coupon_live_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Promotion-code details preserve restrictions and exact parent coupon identity, and recover safely from unavailable local reads.
    requirement: ADM-08
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs and promotion_code_live_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 5min
  completed: 2026-10-09
  commits: 2
  plan_head_before: 0abfc406f9ade847e2e7736fb6fa71c108679de9
  plan_head_after: b01f3bc323da6e78854992e67f6523a57f623f16
status: complete
---

# Phase 238 Plan 03: Coupon and promotion-code inspection summary

**Coupon and promotion-code detail pages now report failed local reads as unavailable and let operators retry without implying that the records are missing.**

## Performance

- **Duration:** 5 minutes
- **Started:** 2026-10-09T03:43:38Z
- **Completed:** 2026-10-09T03:48:38Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Coupon detail keeps coupon terms and related code evidence visible, with a generic unavailable state and retry for expected database connection failures.
- Promotion-code detail keeps code restrictions and its parent coupon distinct, with the same unavailable and retry behavior.
- Retry re-reads the local projection only. No provider calls, packages, create, or edit actions were added.
- Existing list queries already sort by timestamp and ID, and existing tests cover filtered no-match, true empty, navigation, and read-only action bands.

## Task Commits

1. **Task 1: Inspect exact coupon facts and related codes** - `ba0ee1e7` (`fix`)
2. **Task 2: Inspect exact promotion-code restrictions and parent coupon** - `b01f3bc3` (`fix`)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/coupon_live.ex` - Coupon unavailable state, retry, and safe local detail read.
- `accrue_admin/test/accrue_admin/live/coupon_live_test.exs` - Retry recovery regression.
- `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` - Promotion-code unavailable state, retry, and safe local detail read.
- `accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs` - Retry recovery regression.
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-03-PLAN.md` - Corrected ownership wording to match the global catalog schemas.

## Decisions Made

- Coupons and promotion codes are global platform records in the existing schema. The organization query parameter remains link context only; this plan does not invent tenant ownership or change schema.
- Only `DBConnection.ConnectionError` becomes an unavailable state. Other programming errors continue to surface.

## Deviations from Plan

### Plan correction

The original plan described coupon and promotion-code records as owner-scoped, but neither schema has an owner identity. Per the existing model, the plan was corrected to describe global catalog records and reciprocal exact links, with route context preserved. No schema or ownership model was introduced.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs` — passed (16 tests, 0 failures).
- `cd accrue_admin && mix test test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` — passed (15 tests, 0 failures).
- `git diff --check 0abfc406f9ade847e2e7736fb6fa71c108679de9..HEAD` — clean.

## User Setup Required

None. All reads and verification use the local test repository; no provider API calls or package changes were made.

## Self-Check: PASSED

- Summary and plan files exist at the expected phase path.
- Task commits `ba0ee1e7` and `b01f3bc3` are ancestors of the current HEAD.
- The commit count measured from `plan_head_before` is 2.
