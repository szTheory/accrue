---
phase: 102-coupon-discount-mapping
plan: 03
subsystem: payments
tags: [braintree, liveview, discounts, accessibility, docs]
requires:
  - phase: 102-01
    provides: local Braintree discount mapping persistence and preview math
  - phase: 102-02
    provides: submit-time promotion-code revalidation and drift telemetry
provides:
  - portal promo-code preview UX with accessible status messaging
  - submit-time checkout revalidation that reuses `Billing.subscribe/3`
  - adopter docs for local Braintree mappings versus Stripe promotions
affects: [portal-checkout, phase-103, adopter-docs]
tech-stack:
  added: []
  patterns: [server-side promo preview in LiveView, preview-submit resolver reuse, safe drift copy]
key-files:
  created:
    - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
    - accrue/guides/stripe-vs-braintree-promotions.md
  modified:
    - accrue_portal/lib/accrue_portal/live/checkout_live.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue/guides/braintree-local-portal.md
key-decisions:
  - "Checkout preview resolves promo codes on the server through `Accrue.Billing.resolve_discount_mapping/3` so the portal does not duplicate discount logic."
  - "Submit keeps the selected `promotion_code` in LiveView state and relies on `Billing.subscribe/3` to revalidate and fail closed on drift."
patterns-established:
  - "Portal promo flows keep only provisional preview state in the socket and recalculate displayed totals from core minor-unit math."
  - "Customer-visible drift handling uses a dedicated `aria-live` status region with generic copy instead of exposing operator details."
requirements-completed: [BT-05]
duration: 4 min
completed: 2026-05-02
---

# Phase 102 Plan 03: Coupon / Discount Mapping Summary

**Portal promo preview with accessible status copy, submit-time Braintree revalidation, and adopter docs for local discount mappings**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-02T14:26:29-04:00
- **Completed:** 2026-05-02T14:29:50-04:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a promo-code input flow to `CheckoutLive` that previews savings before submit, updates the pay CTA total, and announces changes through an `aria-live` status region.
- Kept final submit on the existing `Billing.subscribe/3` seam, passing the selected `promotion_code` back into core revalidation and translating drift into safe customer copy.
- Documented the supported Braintree local-mapping setup path, the Stripe/Braintree promotions distinction, and the operator remediation story for discount drift.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add promo-code preview UX and final submit revalidation to the portal checkout** - `89feb00` (test), `60111cf` (feat)
2. **Task 2: Document the local mapping model and processor distinction for adopters** - `9d04e4e` (docs)

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` - Adds server-side promo preview state, `validate_promo`, CTA total updates, and submit-time promotion-code forwarding.
- `accrue_portal/lib/accrue_portal/copy.ex` - Adds provisional preview copy, generic invalid-code copy, and safe drift copy.
- `accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs` - Covers preview totals, `aria-live` status updates, valid submit wiring, and drift revalidation.
- `accrue/guides/braintree-local-portal.md` - Documents local discount mapping setup and the operator remediation path.
- `accrue/guides/stripe-vs-braintree-promotions.md` - Explains the processor distinction and the local redemption-state model.

## Decisions Made

- Reused `Accrue.Billing.resolve_discount_mapping/3` for preview rather than introducing portal-only validation logic, keeping preview and submit semantics aligned.
- Kept promo failures in the checkout status region so drift and invalid-code messaging stay safe for customers without implying a successful gateway-side discount confirmation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first draft of the submit assertion sent gateway messages to the LiveView process instead of the test process. The task test seam was corrected by routing the stub notification to a configured test pid before the final green run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Portal checkout now exposes the Phase 102 discount-mapping semantics directly and can serve as the customer-facing reference for later Braintree maturity work.
- The docs and tests now pin the local mapping posture so Phase 103 can build on it without backsliding into Stripe-shaped promotion assumptions.

## Self-Check: PASSED

- Verified summary, test, and guide files exist on disk.
- Verified task commit hashes `89feb00`, `60111cf`, and `9d04e4e` exist in git history.

---
*Phase: 102-coupon-discount-mapping*
*Completed: 2026-05-02*
