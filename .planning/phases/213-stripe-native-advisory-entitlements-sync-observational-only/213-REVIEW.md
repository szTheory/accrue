---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
reviewed: 2026-07-30T21:35:00Z
depth: standard
files_reviewed: 19
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
  - accrue/test/accrue/processor/stripe_entitlements_contract_test.exs
  - accrue/test/accrue/webhook/wr05_concurrency_test.exs
  - scripts/ci/verify_entitlement_sync_isolation.sh
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 213: Code Review Report

**Reviewed:** 2026-07-30T21:35:00Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Reviewed the advisory entitlement pull refresh, shared webhook/pull reducer, processor adapter seam, worker, guard scripts, docs, and related tests. The implementation still has a correctness bug in the monotonic upsert guard: legitimate same-second Stripe updates are dropped even though the in-memory reducer treats equal timestamps as processable. There is also an optional-callback mismatch that can turn a misconfigured or non-Stripe advisory refresh into an `UndefinedFunctionError` crash instead of a typed unsupported result.

Verification note: targeted tests `mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/wr05_concurrency_test.exs` pass, but they only exercise strictly older/newer timestamps and do not cover equal-second events.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Equal-second summary updates are incorrectly discarded by the DB guard

**Classification:** BLOCKER
**File:** `accrue/lib/accrue/entitlements/reconcile.ex:242`

**Issue:** `check_stale/2` allows equal event timestamps (`:eq` falls through to `:ok` at lines 299-303), matching the existing webhook reducer convention that only strictly older events are stale. The DB-level `ON CONFLICT ... WHERE` guard then rejects the same update because it uses `COALESCE(e.synced_at, e.last_stripe_event_ts) < EXCLUDED.synced_at`. Stripe event `created` values are second-granularity, so two distinct `entitlements.active_entitlement_summary.updated` events for the same customer can share the same timestamp. The second event passes the in-memory stale check, hits the conflict path, returns `{:ok, :stale}`, and never writes its newer payload or ledger row. That leaves the advisory cache permanently behind until a later-second event or pull refresh occurs.

**Fix:**
```elixir
conflict_query =
  from(e in EntitlementSummary,
    where:
      (is_nil(e.synced_at) and is_nil(e.last_stripe_event_ts)) or
        fragment("COALESCE(?, ?) <= EXCLUDED.synced_at", e.synced_at, e.last_stripe_event_ts),
    update: [
      set: [
        processor: fragment("EXCLUDED.processor"),
        stripe_customer_id: fragment("EXCLUDED.stripe_customer_id"),
        livemode: fragment("EXCLUDED.livemode"),
        entitlement_count: fragment("EXCLUDED.entitlement_count"),
        truncated: fragment("EXCLUDED.truncated"),
        data: fragment("EXCLUDED.data"),
        synced_at: fragment("EXCLUDED.synced_at"),
        last_stripe_event_ts: fragment("EXCLUDED.last_stripe_event_ts"),
        last_stripe_event_id: fragment("EXCLUDED.last_stripe_event_id"),
        updated_at: fragment("EXCLUDED.updated_at")
      ]
    ]
  )
```

Also add a regression test that sends two different summary events for the same customer with the same `created` second and asserts the second payload and `last_stripe_event_id` persist.

## Warnings

### WR-01: Optional entitlement callback is invoked unconditionally

**Classification:** WARNING
**File:** `accrue/lib/accrue/processor.ex:386`

**Issue:** `list_active_entitlements/2` is declared optional in `@optional_callbacks` at line 310, but the facade blindly calls `__impl__().list_active_entitlements(id, opts)`. Any configured adapter that does not implement the optional callback, including the first-party Braintree adapter, will raise `UndefinedFunctionError` when `StripeSync.refresh/2` is called with advisory sync enabled. That bypasses the typed `{:error, Accrue.Error.t()}` contract and turns an unsupported advisory read into a crash/retry path.

**Fix:** Guard the optional callback in the facade and return a typed unsupported-operation error when absent.

```elixir
def list_active_entitlements(id, opts \\ []) when is_binary(id) and is_list(opts) do
  adapter = __impl__()

  if function_exported?(adapter, :list_active_entitlements, 2) do
    adapter.list_active_entitlements(id, opts)
  else
    {:error,
     %Accrue.APIError{
       code: "unsupported_operation",
       http_status: 501,
       message: "#{inspect(adapter)} does not support active entitlement listing"
     }}
  end
end
```

Add a test with `processor: Accrue.Processor.Braintree` or a minimal custom adapter lacking the callback to assert `StripeSync.refresh/2` returns `{:error, %Accrue.APIError{code: "unsupported_operation"}}` instead of raising.

---

_Reviewed: 2026-07-30T21:35:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
