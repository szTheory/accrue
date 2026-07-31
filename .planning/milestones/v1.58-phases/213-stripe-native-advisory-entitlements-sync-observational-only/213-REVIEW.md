---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
reviewed: 2026-07-31T01:56:29Z
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
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 213: Code Review Report

**Reviewed:** 2026-07-31T01:56:29Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Reviewed the Phase 213 advisory Stripe-native entitlement sync path, including the cache writer, webhook reducer, refresh seam, worker wrapper, processor callbacks, Fake/Stripe adapter implementations, regression tests, docs, and CI guard scripts. No critical always-on authorization defect was proven; the reviewed gate path remains separated from the advisory cache. Four warning-level defects remain in the advisory sync contract, processor scoping, documentation, and worker robustness.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Stripe Native Sync Is Implemented But Not Advertised By Processor Capabilities

**File:** `accrue/lib/accrue/processor/stripe.ex:99`

**Issue:** `Accrue.Processor.Stripe` implements `list_active_entitlements/2` at `stripe.ex:555` and `Accrue.Processor.Capabilities` defines `[:entitlements, :stripe_native_sync]` as the Stripe-native advisory capability, but the Stripe adapter's `capabilities/0` map only returns `entitlements: %{local_mapping: true}`. `Accrue.Processor.supports?([:entitlements, :stripe_native_sync])` therefore returns `false` for Stripe even though the adapter supports the callback, making capability-driven hosts skip or hide the feature incorrectly.

**Fix:** Advertise the advisory capability on the Stripe adapter and add a regression assertion for the public predicate.

```elixir
# accrue/lib/accrue/processor/stripe.ex
entitlements: %{local_mapping: true, stripe_native_sync: true}
```

```elixir
Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)
assert Accrue.Processor.supports?([:entitlements, :stripe_native_sync])
```

### WR-02: Pull Refresh Accepts Non-Stripe Customers For A Stripe-Native Cache

**File:** `accrue/lib/accrue/entitlements/stripe_sync.ex:55`

**Issue:** `StripeSync.refresh/2` accepts any `%Customer{}` as long as `stripe_native_sync?: true`, then calls the globally configured processor with `customer.processor_id` at line 73 and writes the result back through `Reconcile.write_pull/4`. Unlike the webhook path, which scopes customer lookup by both processor id and processor, the pull path has no `customer.processor == "stripe"` guard. A host or worker can enqueue a Braintree/Fake customer and poll the wrong adapter/customer id, then persist an advisory entitlement summary against a non-Stripe customer. That pollutes the diagnostic cache and breaks the documented Stripe-only advisory boundary.

**Fix:** Fail closed before processor I/O unless the row is a Stripe customer; cover Braintree/Fake customer refreshes in tests.

```elixir
def refresh(%Customer{processor: "stripe"} = customer, opts) when is_list(opts) do
  if Accrue.Config.stripe_native_sync?(), do: do_refresh(customer, opts), else: {:ok, :disabled}
end

def refresh(%Customer{}, _opts), do: {:ok, :unsupported_processor}
```

### WR-03: Entitlements Guide Says The Full Paginated Read Is Deferred Though It Now Ships

**File:** `accrue/guides/entitlements.md:345`

**Issue:** The guide still says the complete full paginated read of `GET /v1/entitlements/active_entitlements` is deferred until a future `lattice_stripe >= 1.2` follow-up. The reviewed code now ships `Accrue.Entitlements.StripeSync.refresh/2`, `RefreshWorker`, and `Accrue.Processor.Stripe.list_active_entitlements/2`, which drains `ActiveEntitlement.stream!/3`. Operators following the guide will believe missed webhook reconciliation and the full >10-entitlement pull path do not exist, while the API and worker are already available.

**Fix:** Replace the deferred section with current operational guidance: document `StripeSync.refresh/2`, `RefreshWorker.new(%{"customer_id" => customer.id})`, disabled-mode behavior, retry/error semantics, and when hosts should enqueue refreshes after missed webhook delivery or startup reconciliation.

### WR-04: Malformed RefreshWorker Args Crash And Retry Instead Of Cancelling Deterministically

**File:** `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex:18`

**Issue:** `perform/1` only matches `%Oban.Job{args: %{"customer_id" => customer_id}}` when `customer_id` is binary. Any malformed persisted job, hand-enqueued job, or schema-drifted payload with a missing/non-binary `customer_id` raises `FunctionClauseError`. Oban will treat that as an exception and retry up to `max_attempts: 25`, even though the payload can never succeed. The tests cover missing customer rows, but not malformed args.

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

_Reviewed: 2026-07-31T01:56:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
