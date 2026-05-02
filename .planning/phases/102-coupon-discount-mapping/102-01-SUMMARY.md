---
phase: 102-coupon-discount-mapping
plan: 01
subsystem: payments
tags: [braintree, discounts, ecto, postgres, testing]
requires: []
provides:
  - local Braintree discount mapping schema and migration
  - billing facade wrappers for upsert/get/resolve mapping flows
  - BT-04 coverage for local validation, preview economics, and redemption mutation
affects: [phase-102-plan-02, braintree-subscribe, portal-checkout]
tech-stack:
  added: []
  patterns: [facade-first billing wrapper, local-canonical discount mapping, explicit validation atoms]
key-files:
  created:
    - accrue/lib/accrue/billing/discount_mapping.ex
    - accrue/lib/accrue/billing/discount_mapping_actions.ex
    - accrue/priv/repo/migrations/20260502190500_create_accrue_discount_mappings.exs
  modified:
    - accrue/lib/accrue/billing.ex
    - accrue/lib/accrue/errors.ex
    - accrue/test/accrue/billing/discount_mapping_actions_test.exs
    - .gitignore
key-decisions:
  - "Braintree discount mappings live in a dedicated local table instead of reusing Stripe promotion-code projections."
  - "Resolution returns explicit local validation atoms and reserves Accrue.Error.DiscountMappingInvalid for stored drift."
patterns-established:
  - "Local promotion-code resolution normalizes codes and queries only processor=braintree rows."
  - "Checkout preview math is derived from the stored mapping row before any processor call."
requirements-completed: [BT-04, BT-05]
duration: 8 min
completed: 2026-05-02
---

# Phase 102 Plan 01: Coupon / Discount Mapping Summary

**Dedicated local Braintree discount mappings with facade wrappers, typed drift failures, and BT-04 preview/redemption coverage**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-02T18:05:15Z
- **Completed:** 2026-05-02T18:13:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `accrue_discount_mappings` as the canonical local Braintree mapping store with optimistic locking and lookup indexes.
- Exposed `Accrue.Billing` wrappers for local mapping upsert/get/resolve flows and a typed `%Accrue.Error.DiscountMappingInvalid{}` drift contract.
- Expanded BT-04 coverage to prove local validation branches, preview economics, normalized idempotent upserts, and executable redemption-cap state.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the explicit local discount-mapping contract and persistence layer** - `a64d25c` (feat)
2. **Task 2: Implement local eligibility resolution and Wave 0 BT-04 coverage** - `9fd465c` (test)

## Files Created/Modified

- `accrue/lib/accrue/billing/discount_mapping.ex` - Canonical local discount-mapping schema and changeset.
- `accrue/lib/accrue/billing/discount_mapping_actions.ex` - Local upsert/get/resolve/redemption helpers for Braintree mappings.
- `accrue/priv/repo/migrations/20260502190500_create_accrue_discount_mappings.exs` - New persistence table plus uniqueness/lookup indexes.
- `accrue/lib/accrue/billing.ex` - Public facade wrappers for discount mapping operations.
- `accrue/lib/accrue/errors.ex` - Typed drift exception for invalid stored mappings.
- `accrue/test/accrue/billing/discount_mapping_actions_test.exs` - Wave 0 BT-04 coverage for local validation, preview math, and redemption behavior.
- `.gitignore` - Ignores repo-local `.tmp/` verification output.

## Decisions Made

- Used a new local `accrue_discount_mappings` table rather than overloading Stripe-oriented coupon/promotion-code projections.
- Kept user-path invalid-code handling as explicit atoms (`:not_found`, `:inactive`, `:expired`, `:max_redemptions_reached`) and treated malformed stored rows as operator drift via `%Accrue.Error.DiscountMappingInvalid{}`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Ignored repo-local temp output for Mix verification**
- **Found during:** Task 2 (Implement local eligibility resolution and Wave 0 BT-04 coverage)
- **Issue:** The phase verification workflow requires a repo-local `TMPDIR`, which created an untracked `.tmp/` directory in the main worktree.
- **Fix:** Added `.tmp/` to `.gitignore` so targeted Mix verification does not leave generated runtime output behind.
- **Files modified:** `.gitignore`
- **Verification:** `git status --short` no longer reports `.tmp/` as untracked plan output.
- **Committed in:** `9fd465c`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The auto-fix only cleaned up the verification environment required by the plan.

## Issues Encountered

- The RED test initially used invalid pattern pinning and a drift fixture that violated a DB not-null constraint; both were corrected during the TDD loop before final verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The local mapping domain is ready for subscribe-time Braintree discount attachment and portal checkout reuse in the next Phase 102 plans.
- The BT-04 validation lane now exists and is green with the repo-local `TMPDIR` workaround.

## Self-Check: PASSED

- Verified summary and implementation files exist on disk.
- Verified task commit hashes `5ef421e`, `a64d25c`, and `9fd465c` exist in git history.

---
*Phase: 102-coupon-discount-mapping*
*Completed: 2026-05-02*
