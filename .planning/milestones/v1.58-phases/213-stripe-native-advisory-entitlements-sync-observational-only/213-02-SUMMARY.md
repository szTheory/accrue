---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
plan: "02"
subsystem: stripe-native-advisory-entitlements-sync
status: complete
tags:
  - stripe
  - entitlements
  - lattice_stripe
  - oban
dependency_graph:
  requires:
    - "213-01 Fake-backed refresh primitive and shared Reconcile writer"
    - "212 lattice_stripe 2.x bump"
  provides:
    - "Real Stripe ActiveEntitlement.stream!/3 adapter projection"
    - "SDK-owned active entitlement list path metadata"
    - "Existing-queue Oban RefreshWorker wrapper"
  affects:
    - accrue/lib/accrue/processor/stripe.ex
    - accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex
    - accrue/test/accrue/processor/stripe_entitlements_contract_test.exs
    - accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs
tech_stack:
  added: []
  patterns:
    - "LatticeStripe raw calls confined to Accrue.Processor.Stripe"
    - "Oban worker as inert host-owned wrapper on existing queue"
key_files:
  created:
    - accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex
    - accrue/test/accrue/processor/stripe_entitlements_contract_test.exs
    - accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs
  modified:
    - accrue/lib/accrue/processor/stripe.ex
key_decisions:
  - "The Stripe adapter drains ActiveEntitlement.stream!/3 through the processor facade and projects only bounded webhook-compatible fields."
  - "Active entitlement list metadata remains separate from list results so empty refresh payloads still carry the SDK-owned URL without raw SDK references outside stripe.ex."
  - "RefreshWorker uses the existing accrue_webhooks queue with scalar customer_id args and no scheduler."
requirements_completed:
  - SYNC-01
  - SYNC-02
  - SYNC-05
coverage:
  - id: D1
    description: "Real Stripe adapter fetches complete customer active-entitlement streams and returns plain webhook-compatible maps plus metadata."
    requirement: SYNC-01
    verification:
      - kind: unit
        ref: "mix test test/accrue/processor/stripe_entitlements_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hosts can run advisory refresh asynchronously through a thin existing-queue Oban worker."
    requirement: SYNC-02
    verification:
      - kind: unit
        ref: "mix test test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/stripe_sync_refresh_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Worker and adapter proof remains deterministic with Fake/Test seams and no live Stripe or Chrome calls."
    requirement: SYNC-05
    verification:
      - kind: unit
        ref: "mix test test/accrue/processor/stripe_entitlements_contract_test.exs test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/stripe_sync_refresh_test.exs"
        status: pass
    human_judgment: false
metrics:
  started_at: 2026-07-30T21:14:09Z
  completed_at: 2026-07-30T21:20:12Z
  duration: "6 min"
  tasks_completed: 2
  commits: 4
---

# Phase 213 Plan 02: LatticeStripe Adapter and Refresh Worker Summary

Real Stripe active-entitlement streams now flow through the processor facade, and hosts can enqueue advisory refreshes on the existing webhook queue without new runtime wiring.

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-30T21:14:09Z
- **Completed:** 2026-07-30T21:20:12Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Accrue.Processor.Stripe.list_active_entitlements/2`, draining `LatticeStripe.Entitlements.ActiveEntitlement.stream!/3` with customer filter and limit 100.
- Added `Accrue.Processor.Stripe.active_entitlement_list_metadata/0`, sourcing the canonical list path from `ActiveEntitlement.list_path/0`.
- Added `Accrue.Entitlements.StripeSync.RefreshWorker` on the existing `:accrue_webhooks` queue with scalar `customer_id` args and no scheduler.
- Added deterministic contract tests using local LatticeStripe transport and Fake processor seams only.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Stripe entitlement adapter contract** - `316387ec` (test)
2. **Task 1 GREEN: Stripe active entitlement adapter** - `8fdcea5b` (feat)
3. **Task 2 RED: refresh worker contract** - `d7fb466e` (test)
4. **Task 2 GREEN: refresh worker implementation** - `ffc8cfce` (feat)

## Files Created/Modified

- `accrue/lib/accrue/processor/stripe.ex` - Added the real LatticeStripe active-entitlement stream adapter, bounded projection, SDK-owned metadata, and client option pass-through for deterministic local transport tests.
- `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex` - Added the thin Oban worker that loads a customer and delegates to `StripeSync.refresh/1`.
- `accrue/test/accrue/processor/stripe_entitlements_contract_test.exs` - Added local transport contract tests for stream draining, metadata, and page failure mapping.
- `accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs` - Added worker tests for queue shape, success, disabled no-op, missing customer cancellation, and retryable errors.

## Decisions Made

- The adapter returns only the five D-01 webhook-compatible active-entitlement fields so downstream code never receives raw SDK structs or extra Stripe payload fields.
- `ActiveEntitlement.list_path/0` is exposed through processor metadata, not the list callback, preserving the public `{:ok, [map()]}` result shape.
- Worker success results collapse disabled/unchanged/stale non-row outcomes to `:ok`, while row writes return `{:ok, row}` and refresh errors return `{:error, reason}` for Oban retry semantics.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The plan adds a bounded Stripe adapter call behind the existing processor facade and an inert host-enqueued Oban worker on an existing queue; no new network endpoint, auth path, file access path, scheduler, or grant-authority surface was introduced.

## Verification

- `cd accrue && mix test test/accrue/processor/stripe_entitlements_contract_test.exs && mix compile --warnings-as-errors` — passed, 3 tests.
- `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/stripe_sync_refresh_test.exs` — passed, 10 tests.
- `cd accrue && mix test test/accrue/processor/stripe_entitlements_contract_test.exs test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/stripe_sync_refresh_test.exs && mix compile --warnings-as-errors` — passed, 13 tests.

## Next Phase Readiness

Ready for `213-03`: the adapter and worker surfaces exist, so the next plan can extend the isolation guard around `list_active_entitlements` / `Reconcile` and close the Stripe-backed predicate ambiguity.

## Self-Check: PASSED

- Found summary file and all key created/modified files.
- Found task commits `316387ec`, `8fdcea5b`, `d7fb466e`, and `ffc8cfce` in git history.
- No known stubs or skipped tests were left behind.

---
*Phase: 213-stripe-native-advisory-entitlements-sync-observational-only*
*Completed: 2026-07-30*
