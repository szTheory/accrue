---
phase: 098-payment-method-crud-operator-admin
plan: 01
subsystem: payments
tags: [braintree, payment-methods, billing, ecto, testing]
requires:
  - phase: 096-chosen-second-provider-thin-slice
    provides: host-owned Braintree vault-acquisition seam and adapter baseline
  - phase: 097-advanced-subscription-lifecycle
    provides: projected Braintree subscription state used for delete guards
provides:
  - canonical billing payment-method CRUD verbs and explicit sync
  - Braintree payment-method adapter callbacks with provider-honest translation
  - projection-first local payment-method listing with write-through reprojection
affects: [098-02, accrue_admin, processor-support-matrix]
tech-stack:
  added: []
  patterns: [projection-first payment-method reads, write-through provider resync, guarded Braintree deletes]
key-files:
  created: [accrue/test/accrue/billing/payment_method_crud_braintree_test.exs, accrue/lib/accrue/processor/braintree.ex]
  modified: [accrue/lib/accrue/billing.ex, accrue/lib/accrue/billing/payment_method_actions.ex, accrue/lib/accrue/processor/capabilities.ex, accrue/test/accrue/billing/payment_method_actions_test.exs, .planning/processor-support-matrix.md]
key-decisions:
  - "Kept attach/detach as compatibility wrappers while making add/update/delete/sync canonical."
  - "Implemented list_payment_methods/2 as a local projection read and reserved provider access for sync/write-through flows."
  - "Used projected active Braintree subscriptions by payment_method_token to block unsafe deletes before provider mutation."
patterns-established:
  - "Payment-method writes now follow provider call -> explicit sync -> local projection lookup."
  - "Braintree adapter callbacks translate only narrow vault-acquisition and replacement inputs into gateway calls."
requirements-completed: [PROC-16]
duration: 10 min
completed: 2026-04-30
---

# Phase 098 Plan 01: Payment Method CRUD Backend Summary

**Canonical Braintree-safe payment-method CRUD shipped through `Accrue.Billing` with local projection reads, explicit sync, and guarded delete semantics.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-30T20:44:00Z
- **Completed:** 2026-04-30T20:54:12Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Added failing hermetic coverage for canonical CRUD verbs, replacement semantics, guarded deletes, sync behavior, and Braintree adapter callbacks.
- Implemented `add_payment_method/3`, `update_payment_method/3`, `delete_payment_method/2`, `list_payment_methods/2`, and `sync_payment_methods/2` on the billing facade while preserving attach/detach compatibility paths.
- Promoted Braintree payment-method CRUD support into the adapter capability map and public processor support matrix.

## Task Commits

1. **Task 1: Add hermetic proof coverage for canonical CRUD, replacement, delete guards, and sync** - `5d144cd` (`test`)
2. **Task 2: Implement canonical Billing CRUD verbs, Braintree adapter support, and write-through reprojection** - `717e7d7` (`feat`)

## Files Created/Modified
- `accrue/test/accrue/billing/payment_method_crud_braintree_test.exs` - facade-level CRUD and sync proof for Braintree flows
- `accrue/test/accrue/processor/braintree_test.exs` - adapter coverage for payment-method create/list/update/delete/default callbacks
- `accrue/test/accrue/billing/payment_method_actions_test.exs` - canonical export and local-projection expectations
- `accrue/lib/accrue/billing.ex` - canonical payment-method CRUD and sync facade wrappers
- `accrue/lib/accrue/billing/payment_method_actions.ex` - projection-first orchestration, sync, replacement, and delete guards
- `accrue/lib/accrue/processor/capabilities.ex` - payment-method CRUD support labels
- `accrue/lib/accrue/processor/braintree.ex` - Braintree payment-method gateway translation and callback implementations
- `.planning/processor-support-matrix.md` - public support truth for payment-method CRUD

## Decisions Made

- Kept `attach_payment_method/3` and `detach_payment_method/2` behaviorally intact for existing Fake/Stripe-style tests instead of silently rewriting those flows.
- Made `list_payment_methods/2` purely local-row-first so admin and host reads stay fast and deterministic.
- Used projected subscription rows, not provider passthrough behavior, to decide whether Braintree deletion is allowed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Ran the support-matrix verifier from the repo root**
- **Found during:** Task 2 verification
- **Issue:** `scripts/ci/verify_processor_support_matrix.sh` is repo-root relative, so invoking it from `accrue/` failed with `No such file or directory`.
- **Fix:** Re-ran the plan verification from `/Users/jon/projects/accrue` and kept `mix test` scoped under `cd accrue`.
- **Files modified:** None
- **Verification:** `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test ... --warnings-as-errors`
- **Committed in:** `717e7d7` (verified as part of task commit)

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope change. The deviation only corrected the verification working directory.

## Issues Encountered

- An unrelated existing compile warning remains in `accrue/lib/accrue/billing/subscription_projection.ex`. It did not block the targeted verification command from passing, and this plan did not modify that file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase `098-02` can build the admin/operator surface on top of the canonical facade and sync semantics implemented here.
- The payment-method support matrix, billing facade, and adapter behavior now agree on the shipped PROC-16 backend slice.
