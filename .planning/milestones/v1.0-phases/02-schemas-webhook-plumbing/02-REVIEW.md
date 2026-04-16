---
phase: 02-schemas-webhook-plumbing
reviewed: 2026-04-12T19:45:00Z
depth: deep
files_reviewed: 27
files_reviewed_list:
  - accrue/lib/accrue/billing/customer.ex
  - accrue/lib/accrue/billing/payment_method.ex
  - accrue/lib/accrue/billing/subscription.ex
  - accrue/lib/accrue/billing/subscription_item.ex
  - accrue/lib/accrue/billing/charge.ex
  - accrue/lib/accrue/billing/invoice.ex
  - accrue/lib/accrue/billing/coupon.ex
  - accrue/lib/accrue/billing/metadata.ex
  - accrue/lib/accrue/webhook/webhook_event.ex
  - accrue/lib/accrue/webhook/caching_body_reader.ex
  - accrue/lib/accrue/webhook/plug.ex
  - accrue/lib/accrue/webhook/signature.ex
  - accrue/lib/accrue/webhook/event.ex
  - accrue/lib/accrue/webhook/ingest.ex
  - accrue/lib/accrue/webhook/dispatch_worker.ex
  - accrue/lib/accrue/webhook/handler.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/lib/accrue/webhook/pruner.ex
  - accrue/lib/accrue/billable.ex
  - accrue/lib/accrue/billing.ex
  - accrue/lib/accrue/router.ex
  - accrue/lib/accrue/processor/stripe.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/stripe.ex
  - accrue/lib/accrue/actor.ex
  - accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs
  - accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs
  - accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs
  - accrue/test/accrue/webhook/plug_test.exs
  - accrue/test/accrue/webhook/ingest_test.exs
  - accrue/test/accrue/webhook/dispatch_worker_test.exs
  - accrue/test/accrue/billable_test.exs
  - accrue/test/accrue/billing/events_transaction_test.exs
  - accrue/test/support/webhook_fixtures.ex
findings:
  critical: 1
  warning: 6
  info: 3
  total: 10
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-04-12T19:45:00Z
**Depth:** deep
**Files Reviewed:** 27 source files + 6 test files
**Status:** issues_found

## Summary

Phase 2 delivers a well-structured set of Ecto schemas, a complete webhook ingestion pipeline, and the Billing context with transactional event guarantees. The architecture is sound -- schemas are consistent, the Multi-based transaction pattern correctly ensures atomicity, webhook signature verification delegates to lattice_stripe (no homebrew crypto), and the idempotent ingestion pattern handles duplicates correctly.

Key concerns: one security issue around atom exhaustion via `String.to_existing_atom/1` on untrusted processor strings, several correctness issues in the metadata validation helper, a stale-read risk in the dispatch worker's status update path, and a missing `processor_id` uniqueness index on billing tables.

## Critical Issues

### CR-01: Atom Exhaustion via `String.to_existing_atom` on Untrusted Processor String

**File:** `accrue/lib/accrue/webhook/event.ex:77`
**Issue:** `from_webhook_event/1` calls `String.to_existing_atom(row.processor)` where `row.processor` is a string stored in the database. If the atom has not been previously created at compile time (e.g., a corrupted or unexpected processor string in the DB), this raises `ArgumentError`. More critically, if this were `String.to_atom/1` instead (a common "fix"), it would enable atom table exhaustion from attacker-controlled webhook payloads that get persisted with novel processor strings. The current code raises on unknown strings, which is a crash-path denial-of-service: any corrupted `processor` value in `accrue_webhook_events` will crash every dispatch attempt for that row, burning through all 25 Oban retries and producing noise.
**Fix:** Use a bounded allow-list mapping instead of atom conversion:
```elixir
@processor_atoms %{
  "stripe" => :stripe,
  "stripe_connect" => :stripe_connect
}

defp processor_to_atom(processor_str) do
  case Map.fetch(@processor_atoms, processor_str) do
    {:ok, atom} -> atom
    :error -> raise ArgumentError, "unknown processor: #{inspect(processor_str)}"
  end
end
```
This makes the failure mode explicit and documented rather than relying on the BEAM atom table state.

## Warnings

### WR-01: Metadata `validate_value_lengths` Filter Logic Bug

**File:** `accrue/lib/accrue/billing/metadata.ex:127-131`
**Issue:** The `Enum.filter` predicate on line 128 uses `String.length(value) > @max_value_length && key` as its return value. When the length check is true, this returns the key (a truthy string), which is correct for the filter. But when `value` is `nil` (which `validate_flat_map` allows through -- nil values are valid per Stripe's delete semantics), the `is_binary(value)` guard means nil values are silently skipped. The actual bug is that the filter returns `key` (a string) as the truthy value, then `Enum.map(fn {key, _} -> key end)` tries to destructure that string as a tuple, which will raise `MatchError` if any values actually exceed the limit. The filter returns `{key, value}` tuples from `Enum.filter` on the metadata map, but when the predicate returns `key` (a string), the filtered result is the original `{key, value}` tuple (because `Enum.filter` returns elements where predicate is truthy, not the predicate result). So the logic works by accident, but the predicate is misleading.
**Fix:** Use a clearer predicate that returns a boolean:
```elixir
defp validate_value_lengths(changeset, field, metadata) do
  long_value_keys =
    metadata
    |> Enum.filter(fn {_key, value} ->
      is_binary(value) and String.length(value) > @max_value_length
    end)
    |> Enum.map(fn {key, _} -> key end)

  if long_value_keys != [] do
    add_error(changeset, field,
      "values must be at most #{@max_value_length} characters (violations: #{inspect(long_value_keys)})",
      validation: :metadata_value_length
    )
  else
    changeset
  end
end
```

### WR-02: DispatchWorker Updates Status Without Re-fetching Row After Handler Execution

**File:** `accrue/lib/accrue/webhook/dispatch_worker.ex:44-47,93-104`
**Issue:** The worker fetches the `WebhookEvent` row on line 42, updates it to `:processing` on lines 45-47, then after handler execution (which may take significant time), calls `mark_succeeded` or `mark_failed_or_dead` using the original `row` variable (not re-fetched). Since `repo.update!()` on line 47 returns the updated struct but the code discards it (using the pipe operator for side-effect), `row` still holds the `:received` status version. The `status_changeset` on lines 94-95 and 101-103 builds a changeset from the stale `row`. This works because `status_changeset/2` uses `change/2` which sets the status regardless of the current value, and there is no optimistic lock on `WebhookEvent`. However, if optimistic locking is ever added to `WebhookEvent` (as it is on all billing schemas), this will break.
**Fix:** Capture the updated row from the `:processing` transition:
```elixir
row = repo.get!(WebhookEvent, id)

# Capture the updated row
row =
  row
  |> WebhookEvent.status_changeset(:processing)
  |> repo.update!()
```

### WR-03: Missing `processor_id` Unique Indexes on Billing Tables

**File:** `accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs`
**Issue:** All billing tables have a non-unique index on `processor_id`, but none have a unique composite index on `(processor, processor_id)`. This means the same Stripe `sub_xxx` or `in_xxx` could be inserted multiple times if a webhook reconciliation races with a direct API call. The `accrue_customers` table correctly has `UNIQUE(owner_type, owner_id, processor)`, and `accrue_webhook_events` has `UNIQUE(processor, processor_event_id)`, but the billing tables lack equivalent dedup protection at the DB level.
**Fix:** Add unique composite indexes for tables that represent processor-side resources:
```elixir
create unique_index(:accrue_payment_methods, [:processor, :processor_id],
  where: "processor_id IS NOT NULL",
  name: :accrue_payment_methods_processor_processor_id_index
)
# Same pattern for subscriptions, charges, invoices, coupons
```
The `WHERE processor_id IS NOT NULL` partial index allows rows without a processor_id (local-only records) while preventing duplicates for processor-synced records.

### WR-04: `Billing.customer/1` Has a TOCTOU Race Between SELECT and `create_customer`

**File:** `accrue/lib/accrue/billing.ex:48-62`
**Issue:** `customer/1` does a SELECT, and if nil, calls `create_customer/1`. Two concurrent calls for the same billable can both see nil and both attempt to create. The `create_customer` Multi will hit the unique constraint on `(owner_type, owner_id, processor)` and one will fail with a changeset error. The caller gets `{:error, changeset}` rather than the expected `{:ok, customer}`. This is a classic TOCTOU (time-of-check-time-of-use) race.
**Fix:** Catch the unique constraint violation and retry the fetch:
```elixir
def customer(%{__struct__: mod, id: id} = billable) do
  billable_type = mod.__accrue__(:billable_type)
  owner_id = to_string(id)

  case fetch_customer(billable_type, owner_id) do
    %Customer{} = existing -> {:ok, existing}
    nil ->
      case create_customer(billable) do
        {:ok, customer} -> {:ok, customer}
        {:error, %Ecto.Changeset{} = cs} ->
          # Unique constraint race -- retry fetch
          if cs.errors[:owner_id], do: customer(billable), else: {:error, cs}
        {:error, reason} -> {:error, reason}
      end
  end
end
```

### WR-05: `Billing.create_customer/1` Stores Entire Processor Response in `data` Column

**File:** `accrue/lib/accrue/billing.ex:119`
**Issue:** Line 119 stores `data: processor_result` where `processor_result` is the full map from `customer_to_map/1` (Stripe adapter) or the Fake response. For Stripe, this includes PII fields like `email`, `name`, `address`, `phone`, `shipping` from the Stripe Customer object. The CLAUDE.md constraint states "Payment method details stored as Stripe references, never as PII" and the Events module warns about not putting PII in `data`. While the `data` column on `accrue_customers` is intended to store the full processor snapshot (different from the events ledger), storing unfiltered Stripe response data means PII is persisted in a queryable JSON column. This should be documented as intentional or filtered.
**Fix:** Either document this as intentional (the customer table IS the local projection of the processor customer, PII is expected here) or filter sensitive fields:
```elixir
data: processor_result |> Map.drop([:address, :phone, :shipping])
```

### WR-06: Ingest Uses `Accrue.Repo.transaction` Directly Instead of Host Repo

**File:** `accrue/lib/accrue/webhook/ingest.ex:114`
**Issue:** Line 114 calls `Accrue.Repo.transaction(multi)` which delegates to the host Repo. However, the `Ecto.Multi.run` steps on lines 43-82 use the `repo` variable provided by `Multi.run`'s callback, which is the same host repo. This is correct. BUT the `Oban.insert(job_changeset)` call on line 88 uses Oban's default repo configuration, which may differ from `Accrue.Repo.repo()` in a multi-database setup. If the host app's Oban is configured with a different repo than `config :accrue, :repo`, the Oban insert will run outside the Multi's transaction, breaking the atomicity guarantee.
**Fix:** Use `Oban.insert(repo, job_changeset)` to ensure the Oban job insert uses the same repo/connection as the surrounding transaction. Check if Oban 2.21 supports this -- if not, document the constraint that the host's Oban repo must match `config :accrue, :repo`.

## Info

### IN-01: Double Telemetry Spans on Processor Calls via Stripe Adapter

**File:** `accrue/lib/accrue/processor/stripe.ex:62-78` and `accrue/lib/accrue/processor.ex:72-76`
**Issue:** When using `Accrue.Processor.Stripe`, a call to `Accrue.Processor.create_customer/2` wraps the call in a telemetry span (processor.ex:72-76), and then `Stripe.create_customer/2` wraps it again in another span (stripe.ex:62-78). Both emit `[:accrue, :processor, :customer, :create]` events. This produces duplicate start/stop telemetry events for each processor call. The Fake adapter does not have this issue because it does not wrap in telemetry spans.
**Fix:** Remove the telemetry span from either the facade (`Accrue.Processor`) or the Stripe adapter, not both. The facade is the better location since it applies uniformly to all adapters.

### IN-02: `Billable.__before_compile__` Injects Association Outside Schema Block

**File:** `accrue/lib/accrue/billable.ex:75`
**Issue:** The `__before_compile__` macro calls `Ecto.Schema.has_one/3` at compile time. This works because Ecto's schema macros accumulate associations into module attributes during compilation. However, calling `has_one` outside the `schema` block is undocumented behavior in Ecto. It works today but could break in a future Ecto version that changes how schema compilation works. The `use Accrue.Billable` must appear AFTER `use Ecto.Schema` and before the module is compiled, which is fragile.
**Fix:** Document this constraint clearly in the `@moduledoc` (which it does) and add a compile-time check:
```elixir
defmacro __before_compile__(env) do
  unless Module.has_attribute?(env.module, :ecto_fields) do
    raise CompileError,
      description: "use Accrue.Billable requires `use Ecto.Schema` to appear first"
  end
  # ... rest of macro
end
```

### IN-03: `WebhookEvent` Custom Inspect Replaces `raw_body` with String, Not Redacted Marker

**File:** `accrue/lib/accrue/webhook/webhook_event.ex:105`
**Issue:** The custom `Inspect` implementation sets `raw_body: "<<redacted>>"` (a string), but the field type is `:binary`. While this is only for inspect output and never persisted, it means the inspected struct shows a string where a binary is expected. The `redact: true` option on line 44 already tells Ecto's built-in inspect to redact the field. The custom `Inspect` implementation is redundant with Ecto's `redact: true` feature (available since Ecto 3.9).
**Fix:** The `redact: true` on the field definition (line 44) already handles this. The custom `Inspect` protocol implementation can be removed entirely, simplifying the code. If kept for extra safety, use `raw_body: :redacted` (atom) to distinguish from the binary type.

---

_Reviewed: 2026-04-12T19:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
