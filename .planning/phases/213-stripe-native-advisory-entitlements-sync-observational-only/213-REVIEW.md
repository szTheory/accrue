---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
reviewed: 2026-07-31T01:21:16Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - accrue/guides/entitlements.md
  - accrue/lib/accrue/entitlements/admin.ex
  - accrue/lib/accrue/entitlements/reconcile.ex
  - accrue/lib/accrue/entitlements/stripe_sync.ex
  - accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex
  - accrue/lib/accrue/processor.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/processor/fake/state.ex
  - accrue/lib/accrue/processor/stripe.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs
  - accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs
  - accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs
  - accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs
  - accrue/test/accrue/processor/optional_entitlements_callback_test.exs
  - accrue/test/accrue/processor/stripe_entitlements_contract_test.exs
  - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
  - accrue/test/accrue/webhook/wr05_concurrency_test.exs
  - scripts/ci/verify_entitlement_sync_isolation.sh
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 213: Code Review Report

**Reviewed:** 2026-07-31T01:21:16Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Reviewed the Phase 213 advisory Stripe-native entitlement sync path, including the cache writer, webhook reducer, refresh seam, worker wrapper, processor callbacks, Fake/Stripe adapter implementations, regression tests, and CI guard scripts. No critical authorization or data-loss blocker was proven in the always-on entitlement gate path; the advisory cache remains separated from grant decisions in the reviewed implementation. Two warning-level defects remain in the public capability contract and worker robustness.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Stripe Native Sync Is Implemented But Not Advertised By Processor Capabilities

**File:** `accrue/lib/accrue/processor/stripe.ex:99`

**Issue:** `Accrue.Processor.Stripe` implements `list_active_entitlements/2` at `stripe.ex:555` and the public capability label table defines `[:entitlements, :stripe_native_sync]` as Stripe-native advisory support, but the Stripe adapter's `capabilities/0` map only returns `entitlements: %{local_mapping: true}`. Because `Accrue.Processor.supports?/1` delegates to the adapter map through `Accrue.Processor.Capabilities.supports?/2`, callers asking `Accrue.Processor.supports?([:entitlements, :stripe_native_sync])` will incorrectly get `false` while the Stripe adapter actually supports the feature. That makes the machine-readable capability surface contradict the implemented callback and the processor support matrix.

**Fix:** Add the advisory capability to the Stripe adapter map and cover the public predicate.

```elixir
# accrue/lib/accrue/processor/stripe.ex
entitlements: %{local_mapping: true, stripe_native_sync: true},
```

Add a regression assertion with the Stripe processor configured:

```elixir
Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)
assert Accrue.Processor.supports?([:entitlements, :stripe_native_sync])
```

### WR-02: Malformed RefreshWorker Args Crash And Retry Instead Of Cancelling Deterministically

**File:** `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex:18`

**Issue:** `perform/1` only matches `%Oban.Job{args: %{"customer_id" => customer_id}}` when `customer_id` is binary. Any malformed persisted job, hand-enqueued job, or schema-drifted payload with a missing/non-binary `customer_id` raises `FunctionClauseError`. Oban will treat that as an exception and retry up to `max_attempts: 25`, even though the payload can never succeed. The existing tests cover missing customer rows, but not malformed args.

**Fix:** Add a catch-all `perform/1` clause that cancels invalid payloads before they enter retry semantics, and test missing/non-binary `customer_id`.

```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: %{"customer_id" => customer_id}} = job)
    when is_binary(customer_id) do
  # existing implementation
end

def perform(%Oban.Job{}), do: {:cancel, :invalid_customer_id}
```

---

_Reviewed: 2026-07-31T01:21:16Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
