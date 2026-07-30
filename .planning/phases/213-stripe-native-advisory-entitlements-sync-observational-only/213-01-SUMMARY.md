---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
plan: "01"
subsystem: stripe-native-advisory-entitlements-sync
status: complete
tags:
  - stripe
  - entitlements
  - advisory-sync
  - fake-processor
dependency_graph:
  requires:
    - "Phase 212 green reconciliation baseline"
  provides:
    - "Processor/Fake active entitlement list seam"
    - "StripeSync.refresh/2 advisory pull primitive"
    - "Shared pull/webhook EntitlementSummary reconciler"
    - "D-11 pull/webhook monotonic ordering coverage"
  affects:
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/entitlements/stripe_sync.ex
    - accrue/lib/accrue/webhook/default_handler.ex
tech_stack:
  added:
    - "Accrue.Entitlements.Reconcile"
  patterns:
    - "optional Processor callback facade"
    - "Fake-backed deterministic processor list seam"
    - "Ecto upsert with strict synced_at conflict guard"
key_files:
  created:
    - accrue/lib/accrue/entitlements/reconcile.ex
    - accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs
  modified:
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/processor/fake/state.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/entitlements/stripe_sync.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/accrue/webhook/wr05_concurrency_test.exs
decisions:
  - "Pull and webhook entitlement-summary writes share Accrue.Entitlements.Reconcile so advisory cache ordering has one implementation."
  - "Pull writes use pull_started_at as synced_at and carry forward the greatest real webhook watermark."
  - "Identical pull snapshots short-circuit as :unchanged before DB upsert and do not duplicate the ledger."
metrics:
  completed_at: 2026-07-30T21:11:17Z
  duration: "approximately 6 minutes"
  tasks_completed: 2
  commits: 3
---

# Phase 213 Plan 01: Fake Advisory Refresh and Ordering Summary

Fake-backed advisory refresh now materializes a complete processor entitlement list into the diagnostic `EntitlementSummary` cache through a shared pull/webhook reconciler. Local grant authority remains unchanged and does not read this cache.

## Completed Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 RED | Add failing advisory refresh tracer test | 91cdd590 | `accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs` |
| 1 GREEN | Implement Fake advisory refresh tracer | e659579c | `processor.ex`, `fake.ex`, `fake/state.ex`, `stripe_sync.ex`, `reconcile.ex`, `default_handler.ex`, refresh test |
| 2 | Prove pull/webhook monotonic ordering | a44b2f3b | `stripe_sync_refresh_test.exs`, `wr05_concurrency_test.exs` |

## What Changed

- Added optional `Processor.list_active_entitlements/2` and `Processor.active_entitlement_list_metadata/0` facade support.
- Added Fake processor entitlement seeding/listing through `Fake.put_entitlements/2` and the shared call-count/script path.
- Added `StripeSync.refresh/2`, disabled by default and returning `{:ok, :disabled}` before Processor or Repo I/O.
- Extracted entitlement-summary writes into `Accrue.Entitlements.Reconcile` for both webhook and pull paths.
- Preserved webhook watermarks across pull refreshes while ordering all writes by `synced_at`.
- Added deterministic tests for stale pulls, newer pulls, equal webhook redelivery, timestamp-less webhook carry-forward, and concurrent pull/webhook execution.

## Verification

- `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs` — passed, 18 tests.
- `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs` — passed, 1 property and 23 tests.
- `cd accrue && mix compile --warnings-as-errors && mix test test/accrue/entitlements test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs` — passed, 1 property and 95 tests.
- `cd accrue && bash scripts/ci/verify_entitlement_sync_isolation.sh` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Identical pull refresh initially reported stale**
- **Found during:** Task 1 GREEN verification
- **Issue:** Fake clock timestamps can be equal across immediate pulls, so an identical second refresh reached the strict DB guard and returned `{:ok, :stale}` instead of the planned no-op `{:ok, :unchanged}`.
- **Fix:** Added material-change detection before pull upsert; unchanged pull snapshots emit bounded telemetry and skip the ledger.
- **Files modified:** `accrue/lib/accrue/entitlements/reconcile.ex`
- **Commit:** e659579c

**2. [Rule 1 - Bug] Existing nil-synced rows could reject valid summary writes**
- **Found during:** Task 1 GREEN verification against existing webhook tests
- **Issue:** Older tests seeded rows with `synced_at: nil`; a strict `synced_at < EXCLUDED.synced_at` guard rejected otherwise valid timestamp-less or newer writes.
- **Fix:** Made the upsert guard null-safe with `COALESCE(synced_at, last_stripe_event_ts)` and first-row allowance.
- **Files modified:** `accrue/lib/accrue/entitlements/reconcile.ex`
- **Commit:** e659579c

**3. [Rule 2 - Critical overlap] Task 2 production guard landed with the shared writer**
- **Found during:** Task 2 RED attempt
- **Issue:** Task 1 required extracting the webhook writer and adding pull support; implementing that shared writer necessarily introduced the D-11 monotonic guard before Task 2's tests were added.
- **Fix:** Added the D-11 ordering and concurrency tests as a task-scoped proof commit; no further production code was needed.
- **Files modified:** `accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs`, `accrue/test/accrue/webhook/wr05_concurrency_test.exs`
- **Commit:** a44b2f3b

## TDD Gate Compliance

- RED commit present: `91cdd590 test(213-01): add failing advisory refresh tracer test`.
- GREEN commit present after RED: `e659579c feat(213-01): implement Fake advisory refresh tracer`.
- Task 2 tests passed on first run because the shared reconciler implementation from Task 1 already included the required D-11 guard. This overlap is documented as a Rule 2 deviation above.

## Known Stubs

None.

## Threat Flags

None. The plan adds a processor read seam and diagnostic cache writer only; no new network endpoint, auth path, file access path, or grant-authority surface was introduced.

## Deferred Issues

None.

## Self-Check

PASSED.

- Found summary file and key created/modified files.
- Found task commits `91cdd590`, `e659579c`, and `a44b2f3b` in git history.
