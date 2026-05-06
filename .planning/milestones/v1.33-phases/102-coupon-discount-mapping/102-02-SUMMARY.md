---
phase: 102-coupon-discount-mapping
plan: 02
subsystem: payments
tags: [braintree, discounts, telemetry, ecto, testing]
requires:
  - phase: 102-01
    provides: local Braintree discount mapping persistence and resolver helpers
provides:
  - submit-time Braintree promotion-code revalidation in `Billing.subscribe/3`
  - Braintree `discounts.add[*].inherited_from_id` request translation
  - ops telemetry for invalid discount-mapping drift with allowlisted metadata
affects: [phase-102-plan-03, braintree-subscribe, portal-checkout, telemetry]
tech-stack:
  added: []
  patterns: [shared preview-submit resolver, fail-closed drift handling, allowlisted ops telemetry]
key-files:
  created:
    - accrue/test/accrue/billing/braintree_discount_mapping_subscribe_test.exs
    - accrue/test/accrue/telemetry/discount_mapping_invalid_test.exs
  modified:
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/lib/accrue/telemetry/ops.ex
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/guides/telemetry.md
    - accrue/test/accrue/processor/braintree_test.exs
    - accrue/test/support/telemetry_ops_inventory.ex
key-decisions:
  - "Braintree submit-time validation reuses `resolve_discount_mapping/3` in core and emits `%Accrue.Error.DiscountMappingInvalid{}` unchanged on drift."
  - "Drift is alertable through one canonical `[:accrue, :ops, :discount_mapping_invalid]` event carrying only mapping_id, code, discount_id, reason, and operation_id."
patterns-established:
  - "Braintree subscribe flows carry local mapping metadata alongside processor params, then consume redemption state only after the local subscription write succeeds."
  - "New ops tuples must be co-registered in `TelemetryOpsInventory`, default metrics, and `guides/telemetry.md` to satisfy contract parity gates."
requirements-completed: [BT-05]
duration: 5 min
completed: 2026-05-02
---

# Phase 102 Plan 02: Coupon / Discount Mapping Summary

**Create-time Braintree discount attachment with local promotion-code revalidation, persisted discount references, and drift ops telemetry**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-02T18:16:45Z
- **Completed:** 2026-05-02T18:21:30Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Wired `Billing.subscribe/3` to revalidate Braintree `promotion_code` values in core before processor create, hard-failing invalid local state instead of silently dropping discounts.
- Preserved applied Braintree discount references in local subscription projections and translated discount mappings into `discounts.add[*].inherited_from_id`.
- Added a dedicated ops telemetry lane for discount-mapping drift and registered the tuple in metrics, docs, and inventory parity tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Revalidate promotion codes inside the Braintree subscribe flow** - `448ce60` (test), `a74e931` (feat)
2. **Task 2: Translate Braintree discount payloads correctly and emit ops telemetry on drift** - `9ad403c` (test), `125151a` (feat)

## Files Created/Modified

- `accrue/lib/accrue/billing/subscription_actions.ex` - Revalidates `promotion_code` in the Braintree create path, carries mapping metadata, consumes redemptions, and emits drift telemetry.
- `accrue/lib/accrue/billing/subscription_projection.ex` - Persists returned Braintree discount references into local `discount_id`.
- `accrue/lib/accrue/processor/braintree.ex` - Translates resolved mappings into Braintree `discounts.add[*].inherited_from_id`.
- `accrue/lib/accrue/telemetry/ops.ex` - Documents the new canonical ops tuple.
- `accrue/lib/accrue/telemetry/metrics.ex` - Adds the default `accrue.ops.discount_mapping_invalid.count` counter.
- `accrue/guides/telemetry.md` - Publishes the new drift event contract and allowlisted metadata.
- `accrue/test/accrue/billing/braintree_discount_mapping_subscribe_test.exs` - Covers create-time validation, redemption mutation, drift hard-fail, and persisted `discount_id`.
- `accrue/test/accrue/processor/braintree_test.exs` - Locks the Braintree request shape to `discounts.add[*].inherited_from_id`.
- `accrue/test/accrue/telemetry/discount_mapping_invalid_test.exs` - Verifies one drift event with allowlisted metadata only.
- `accrue/test/support/telemetry_ops_inventory.ex` - Registers the canonical ops tuple for contract parity.

## Decisions Made

- Kept submit-time Braintree validation on the existing `resolve_discount_mapping/3` path so preview and create semantics stay aligned.
- Emitted drift telemetry before any processor call, keeping raw gateway payloads out of both the returned error and the ops metadata contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Moved Braintree request translation into the adapter during Task 1**
- **Found during:** Task 1 (Revalidate promotion codes inside the Braintree subscribe flow)
- **Issue:** The subscribe-path TDD slice could not verify end-to-end discount attachment while `Accrue.Processor.Braintree.build_request/1` still stripped discount data.
- **Fix:** Extended the adapter early to translate resolved local discount mappings into Braintree’s `discounts.add[*].inherited_from_id` shape so the real subscribe seam stayed testable.
- **Files modified:** `accrue/lib/accrue/processor/braintree.ex`
- **Verification:** `TMPDIR=/Users/jon/projects/accrue/.tmp/phase102 mix test test/accrue/billing/braintree_discount_mapping_subscribe_test.exs`
- **Committed in:** `a74e931`

**2. [Rule 3 - Blocking] Registered the new drift tuple in telemetry parity artifacts**
- **Found during:** Task 2 (Translate Braintree discount payloads correctly and emit ops telemetry on drift)
- **Issue:** Adding a new ops event without updating the inventory, metrics defaults, and public guide would fail the repo’s telemetry contract gates.
- **Fix:** Updated `TelemetryOpsInventory`, default metrics, and `guides/telemetry.md` alongside the new emit site.
- **Files modified:** `accrue/test/support/telemetry_ops_inventory.ex`, `accrue/lib/accrue/telemetry/metrics.ex`, `accrue/guides/telemetry.md`, `accrue/lib/accrue/telemetry/ops.ex`
- **Verification:** `TMPDIR=/Users/jon/projects/accrue/.tmp/phase102 mix test test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs`
- **Committed in:** `125151a`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both deviations were required to keep the planned subscribe and telemetry lanes executable end to end. No scope creep beyond the plan’s stated BT-05 contract.

## Issues Encountered

- The first implementation returned `{:ok, params}` one layer too early from `build_subscription_request/4`, which surfaced as a `FunctionClauseError` in `Accrue.Processor.Braintree.create_subscription/2`; the helper boundary was corrected in the same TDD loop before the final green run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The Braintree subscribe seam now enforces BT-05 at create time and exposes a stable drift-telemetry contract for portal and operator surfaces.
- Phase 102 Plan 03 can build on the shared core resolver without reintroducing Stripe coupon semantics into Braintree flows.

## Self-Check: PASSED

- Verified summary and implementation files exist on disk.
- Verified task commit hashes `448ce60`, `a74e931`, `9ad403c`, and `125151a` exist in git history.

---
*Phase: 102-coupon-discount-mapping*
*Completed: 2026-05-02*
