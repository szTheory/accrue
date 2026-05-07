---
phase: 118-admin-portal-change-flows
plan: 01
subsystem: payments
tags: [subscriptions, stripe, braintree, fake, support-contract, testing]
requires:
  - phase: 117-contract-promotion-preview-truth
    provides: swap-plan and preview-first active-subscription-change contract
provides:
  - official runtime and public support labels for quantity and subscription-item mutations
  - provider-honest Braintree swap-only bounds across support mirrors
  - deterministic Fake-first proof for quantity and item mutation semantics
affects: [118-02, 118-03, SCM-03, admin-flows, portal-flows]
tech-stack:
  added: []
  patterns: [support-contract co-update, Fake-first proof, provider-honest Braintree bounds]
key-files:
  created: [.planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-01-SUMMARY.md]
  modified:
    - accrue/lib/accrue/processor/capabilities.ex
    - .planning/processor-support-matrix.md
    - accrue/README.md
    - accrue/test/accrue/processor/capabilities_test.exs
    - accrue/test/accrue/billing/subscription_actions_test.exs
    - accrue/test/accrue/billing/subscription_items_test.exs
    - accrue/test/accrue/billing/upcoming_invoice_test.exs
    - accrue/test/accrue/billing/proration_roundtrip_test.exs
key-decisions:
  - "Promoted update_quantity/3 and the subscription-item mutation trio into the official active-subscription-change bundle for Stripe and Fake."
  - "Kept Braintree explicitly bounded to swap-only with preview, quantity, and subscription-item semantics documented and tested as unsupported."
  - "Used existing Fake-first billing tests as the merge-blocking proof lane instead of inventing a new provider abstraction."
patterns-established:
  - "Runtime labels, support-matrix docs, README wording, and proof tests move together for contract promotion."
  - "Braintree unsupported rows stay explicit in labels and tests rather than being described as partial parity."
requirements-completed: [SCM-03]
duration: 4 min
completed: 2026-05-07
---

# Phase 118 Plan 01: Quantity and Subscription-Item Contract Promotion Summary

**Official Stripe/Fake quantity and subscription-item support labels now match the support matrix, README contract, and Fake-first proof while Braintree remains explicitly swap-only.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-07T20:13:30Z
- **Completed:** 2026-05-07T20:17:27Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Promoted `update_quantity/3`, `add_item/3`, `remove_item/2`, and `update_item_quantity/3` into the official active-subscription-change support labels and provider labels.
- Updated the public support SSOT and package README so Stripe/Fake quantity and item mutations are official while Braintree stays explicitly preview/quantity/item unsupported.
- Extended the deterministic core proof bundle so Fake keeps proving the promoted mutation lane and Braintree keeps failing unsupported quantity semantics clearly.

## Verification

- `cd accrue && mix test test/accrue/processor/capabilities_test.exs`
  - PASS
- `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_items_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs`
  - PASS
- `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_items_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs`
  - PASS, 27 tests, 0 failures

## Task Commits

1. **Task 1: Promote quantity and subscription-item mutations into the official support contract** - `3cb03fc` (`feat`)
2. **Task 2: Extend the deterministic core proof for official quantity/item support and bounded Braintree failures** - `4825f70` (`test`)

## Files Created/Modified

- `accrue/lib/accrue/processor/capabilities.ex` - Added official support labels and provider labels for quantity and subscription-item mutation rows.
- `.planning/processor-support-matrix.md` - Promoted quantity and item mutations into the official matrix and restated Braintree as explicitly unsupported outside swap-only.
- `accrue/README.md` - Updated package-facing contract wording for the expanded active-subscription-change bundle.
- `accrue/test/accrue/processor/capabilities_test.exs` - Pinned the new runtime/provider label story.
- `accrue/test/accrue/billing/subscription_actions_test.exs` - Added Fake positive proof for `update_quantity/3` while preserving Braintree unsupported assertions.
- `accrue/test/accrue/billing/subscription_items_test.exs` - Added a combined Fake mutation-lane proof for quantity and subscription-item changes.
- `accrue/test/accrue/billing/upcoming_invoice_test.exs` - Kept preview proof attached to supported active-change subscriptions after quantity changes.
- `accrue/test/accrue/billing/proration_roundtrip_test.exs` - Reframed the preview round-trip proof around the official active-change bundle.

## Decisions Made

- Promoted only the rows current runtime truth already defends: Stripe/Fake quantity and item mutations became official, while Braintree stayed bounded.
- Kept preview wording narrow: preview remains the official path where supported, without implying Braintree parity or generic item-preview semantics.
- Reused the existing library-level proof files rather than adding new test surfaces, keeping the contract deterministic and merge-blocking.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

- Admin and portal work can now consume one explicit active-subscription-change contract for plan, preview, quantity, and item flows.
- Braintree remains clearly bounded to swap-only, so the next plans can reuse that constraint without re-litigating provider parity.

## Self-Check: PASSED

- Summary file exists at `.planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-01-SUMMARY.md`
- Commit `3cb03fc` exists
- Commit `4825f70` exists

---
*Phase: 118-admin-portal-change-flows*
*Completed: 2026-05-07*
