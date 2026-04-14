---
phase: 03-core-subscription-lifecycle
reviewed: 2026-04-14T00:00:00Z
depth: standard
files_reviewed: 87
findings:
  critical: 3
  warning: 11
  info: 7
  total: 21
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-04-14
**Depth:** standard
**Files Reviewed:** 87 (source only — planning + lockfiles excluded)
**Status:** issues_found

## Summary

Phase 3 ships a broad subscription lifecycle surface with generally solid patterns: `Repo.transact` wraps most mutations, watermark-based skip-stale is consistent, custom typed errors propagate cleanly, and tests cover the happy paths well. The overall architecture matches D3-01..D3-86.

However, the review surfaced several meaningful issues concentrated in three areas: (1) idempotency-key routing between the billing context and the Stripe adapter is broken — the adapter silently overwrites the context's deterministic key, which defeats the PROC-02/D3-60/D3-61 invariant; (2) `charge/3` deliberately splits the Stripe call out of `Repo.transact`, creating a transactional-integrity gap explicitly flagged in the focus areas; (3) the `Accrue.Credo.NoRawStatusAccess` check has several concrete bypasses (`!=` operator, pattern matching, `get_in/Map.get`, string status) that would let BILL-05 violations land in review without tripping the gate.

Money-math correctness has a real bug: `merchant_loss = fee - fee_refunded` can be negative if Stripe's `fee_refunded` exceeds `fee` (e.g. re-refunds, fee adjustments), and neither the sync path nor the reconciler clamp. A few `String.to_existing_atom` calls are rescued in one place and not in another, producing inconsistent crash vs. tuple-error behavior on the same Stripe payload.

Webhook out-of-order handling (WH-09) is implemented correctly against D3-48/49 — the column+skip-stale+refetch triple is coherent and tested — though one reducer (`reduce_refund`) calls `Repo.get_by!` on `nil` charge id inside `Repo.transact`, which will raise instead of returning `{:error, _}`.

---

## Critical Issues

### CR-01: Stripe adapter silently overwrites the billing-context idempotency key

**File:** `accrue/lib/accrue/processor/stripe.ex:537-543` (plus every `stripe_opts(:op, subject, opts)` call site)

**Issue:** `SubscriptionActions.subscribe/3` (and siblings in `InvoiceActions`, `ChargeActions`, `RefundActions`, `PaymentMethodActions`) compute a deterministic idempotency key via `Accrue.Processor.Idempotency.key/4` and pass it to the processor as `[idempotency_key: idem_key] ++ opts`. But `Accrue.Processor.Stripe.stripe_opts/3` unconditionally **replaces** that key:

```elixir
defp stripe_opts(op, subject_id, opts) do
  idem_key = compute_idempotency_key(op, subject_id, opts)   # <-- overwrites!
  opts
  |> Keyword.put(:idempotency_key, idem_key)
  |> Keyword.put(:stripe_version, resolve_api_version(opts))
end
```

The SHA256 seed computed in `Idempotency.key/4` (D3-60, deterministic from `(op, subject_id, operation_id, sequence)`) is discarded and replaced with `compute_idempotency_key/3`'s own 22-char seed (D2-11). The two algorithms produce different keys for the same logical operation, so the D3-61 "retry of the same HTTP request converges to the same Stripe-side key" invariant is violated on the Stripe path. Only the Fake path (which uses the key as-passed) is retry-idempotent.

This also means the `Idempotency.subject_uuid/2` pre-generated row PK (used in `RefundActions.insert_refund/4` and `ChargeActions.insert_charge/4` via `force_change(:id, id)`) is computed using one seed while Stripe bills under a different seed — retries can create distinct Stripe charges backed by distinct local rows.

**Fix:** Make `stripe_opts` preserve an explicit caller key and only compute its own as a fallback:

```elixir
defp stripe_opts(op, subject_id, opts) do
  idem_key =
    Keyword.get(opts, :idempotency_key) ||
      compute_idempotency_key(op, subject_id, opts)

  opts
  |> Keyword.put(:idempotency_key, idem_key)
  |> Keyword.put(:stripe_version, resolve_api_version(opts))
end
```

Apply identically to `stripe_opts_no_idem/1` for defensive consistency.

---

### CR-02: `charge/3` runs the Stripe call outside `Repo.transact`

**File:** `accrue/lib/accrue/billing/charge_actions.ex:118-147`

**Issue:** The module deliberately lifts `Processor.__impl__().create_charge/2` out of `Repo.transact` (comment at line 118 explains: "so we can branch on SCA/3DS shape without persisting a half-baked Charge row"). This contradicts the Phase 3 focus-area invariant *"every Billing context function wraps Stripe call + DB write + Events.record_multi in a single Repo.transact/2"* (D3-18, D3-60). Concrete failure:

1. `Processor.create_charge` succeeds — Stripe has charged the card
2. Control returns, `Repo.transact` begins
3. `insert_or_fetch_charge` or `Events.record` fails (DB partition, unique constraint, changeset error, etc.)
4. The transaction rolls back — the customer is charged with no local row and no event

Because the UUID is derived deterministically from `(op, operation_id)`, a client retry will hit `insert_or_fetch_charge`'s `nil` branch again and Stripe replays with the cached idempotency key (assuming CR-01 is fixed) — eventually converging. But that requires (a) CR-01 fixed, (b) the caller retries, (c) the failure is transient. Any non-transient DB error silently leaves Stripe out of sync until the operator finds it.

**Fix:** Persist a pending row *before* branching on `requires_action`:

```elixir
Repo.transact(fn ->
  with {:ok, stripe_ch} <- Processor.__impl__().create_charge(params, stripe_opts),
       {:ok, charge_row} <- insert_or_fetch_charge(subject_uuid, customer, stripe_ch, amount),
       {:ok, _} <- record_event(charge_event_type(stripe_ch), charge_row, event_data) do
    case IntentResult.wrap({:ok, stripe_ch}) do
      {:ok, :requires_action, pi} -> {:ok, {:requires_action, pi, charge_row}}
      {:ok, _} -> {:ok, charge_row}
      {:error, _} = err -> err
    end
  end
end)
|> unwrap_result()
```

The Charge row persists even for `requires_action`; `charge.status` reflects `"requires_action"` and becomes terminal only after the webhook reconciles. Matches `InvoiceActions.run_action/4`, which already does the whole chain inside `Repo.transact`.

---

### CR-03: `default_handler.ex` `reduce_refund` crashes on unknown charge id

**File:** `accrue/lib/accrue/webhook/default_handler.ex:420-439`

**Issue:** When a `charge.refund.updated` event arrives for a refund whose parent charge hasn't been projected locally yet, `upsert_refund/4` on the `nil` row branch does `charge = Repo.get_by!(Charge, processor_id: charge_stripe_id)`. If `charge_stripe_id` is nil or the charge isn't in the local DB, this raises `Ecto.NoResultsError` inside `Repo.transact`. The transaction rolls back, Oban retries N times crashing each time, event lands in DLQ.

For WH-09 out-of-order handling this is the wrong default — Stripe can deliver `charge.refund.updated` before `charge.refunded` (D3-50). The handler should tolerate missing parents.

**Fix:** Use `Repo.get_by/2`:

```elixir
case row do
  nil ->
    case charge_stripe_id && Repo.get_by(Charge, processor_id: charge_stripe_id) do
      %Charge{} = charge -> # existing insert path
      _ ->
        :telemetry.execute([:accrue, :webhooks, :orphan_refund], %{}, %{...})
        {:ok, :deferred}
    end
  existing -> # existing update path
end
```

Same pattern applies to `upsert_charge/4` (line 329-340) and `upsert_subscription/3` (line 182-189), which both use `Repo.get_by!(Customer, ...)` and crash on webhook-first-for-unknown-customer scenarios.

---

## Warnings

### WR-01: `create_payment_intent/2` builds a colliding idempotency key

**File:** `accrue/lib/accrue/billing/charge_actions.ex:162-171`

`Idempotency.key(:create_payment_intent, op_id, op_id)` passes the same `op_id` for both `subject_id` and `operation_id`. Two different PaymentIntents in the same operation hash to the same key.

**Fix:** Pre-generate a `subject_uuid`:
```elixir
subject_uuid = Idempotency.subject_uuid(:create_payment_intent, op_id)
idem_key = Idempotency.key(:create_payment_intent, subject_uuid, op_id)
```

### WR-02: `IntentResult.wrap` can never surface `requires_action` for Invoice/Charge structs

**File:** `accrue/lib/accrue/billing/intent_result.ex:55`

The catch-all clause `def wrap({:ok, %{__struct__: _} = _struct} = ok), do: ok` intercepts `%Invoice{}` and `%Charge{}` before any introspection. `InvoiceActions.pay_invoice/2` calls `wrap` on `{:ok, %Invoice{}}`, and `data.latest_invoice.payment_intent` may carry `requires_action` — but wrap returns the plain tuple and never emits `{:ok, :requires_action, pi}`. D3-07 ("`pay_invoice/2` … return an `intent_result` tagged union") is silently broken.

**Fix:** Add schema-specific extractors before the struct pass-through:
```elixir
def wrap({:ok, %Subscription{} = sub} = ok), do: extract_sub_pi(sub, ok)
def wrap({:ok, %Invoice{data: data}} = ok) when is_map(data), do: extract_invoice_pi(data, ok)
def wrap({:ok, %Charge{data: data}} = ok) when is_map(data), do: extract_charge_pi(data, ok)
def wrap({:ok, %{__struct__: _} = _struct} = ok), do: ok
```

Also `Subscription.pending_intent/1` at `lib/accrue/billing/subscription.ex:180` uses string-key `get_in` only; normalize to dual-key.

### WR-03: Money math allows negative `merchant_loss_amount`

**Files:**
- `accrue/lib/accrue/billing/refund_actions.ex:117-123`
- `accrue/lib/accrue/webhook/default_handler.ex:390-397`
- `accrue/lib/accrue/jobs/reconcile_refund_fees.ex:77-80`

All three compute `merchant_loss = fee - fee_refunded` without clamping. Stripe's `fee_refunded` can exceed `fee` in fee-adjustment scenarios, producing a negative merchant_loss. The schema column is a plain integer with no CHECK constraint. This is the exact class of bug BILL-26 exists to prevent.

**Fix:**
```elixir
{fr, max(0, f - fr), Accrue.Clock.utc_now()}
```
Add `CHECK (merchant_loss_amount_minor >= 0)` to the migration. Add a property test.

### WR-04: `String.to_existing_atom` used without rescue in RefundActions

**File:** `accrue/lib/accrue/billing/refund_actions.ex:126-130`

`SubscriptionProjection.parse_status`, `InvoiceProjection.parse_status`, and `DefaultHandler.upsert_refund/4` all wrap the conversion in `try/rescue`. This one doesn't.

**Fix:** Mirror the `DefaultHandler` pattern.

### WR-05: `create_refund/2` crashes on non-Money `:amount` option

**File:** `accrue/lib/accrue/billing/refund_actions.ex:46-50`

The `case` has only `nil` and `%Money{}` clauses — integer/map/typo raises `CaseClauseError`. Also no currency cross-check against the parent charge.

**Fix:**
```elixir
amount_minor =
  case Keyword.get(opts, :amount) do
    nil -> charge.amount_cents
    %Money{currency: cur, amount_minor: n} when cur == String.to_existing_atom(charge.currency) -> n
    %Money{} = m ->
      raise Accrue.Money.MismatchedCurrencyError, left: String.to_atom(charge.currency), right: m.currency
    other ->
      raise ArgumentError, ":amount must be a %Accrue.Money{} or nil; got #{inspect(other)}"
  end
```

### WR-06: `Accrue.Credo.NoRawStatusAccess` has at least four real bypasses

**File:** `accrue/lib/accrue/credo/no_raw_status_access.ex`

The check scans for `{:==, _, [...]}` and `{:in, _, [...]}` only. These patterns pass the lint gate:

1. **`!=` comparison** — `if sub.status != :canceled`
2. **Pattern match in function head or case** — `def do_thing(%Subscription{status: :active})`
3. **`Map.get` / `get_in`** — passed to a helper that compares outside the grep window
4. **String status** — `Charge.status` is `:string`, so `charge.status == "succeeded"` slips through

Also `exempt_file?/1` exempts anything containing `/test/`, which inadvertently exempts `lib/accrue/test/factory.ex` and `lib/accrue/test/generators.ex` — production modules.

**Fix:** Add clauses for `:!=`, pattern-match (case/def/defp), and tighten `exempt_file?` to `test/**` only.

### WR-07: `Accrue.Plug.PutOperationId` trusts attacker-controlled header without validation

**File:** `accrue/lib/accrue/plug/put_operation_id.ex:41-55`

The moduledoc acknowledges `x-request-id` is untrusted but only mitigates the authorization concern. Remaining issues: no length validation (attacker can submit 8KB), no charset validation (newlines/null bytes/Unicode). The value propagates into SHA256 input, Oban pdict, `accrue_events.data.operation_id`, and Stripe idempotency keys.

**Fix:**
```elixir
defp sanitize_header_id(nil), do: nil
defp sanitize_header_id(id) when is_binary(id) do
  sanitized = String.replace(id, ~r/[^a-zA-Z0-9_\-]/, "")
  if byte_size(sanitized) in 1..128, do: "untrusted-" <> sanitized
end
```

### WR-08: `Repo.transact` not used where `Ecto.Multi` still lives

**File:** `accrue/lib/accrue/billing.ex:211-248, 280-297`

`create_customer/1` and `update_customer/2` still use `Ecto.Multi.new() + Repo.transaction/1` (Phase 1/2 pattern). D3-18 standardizes on `Repo.transact/2`. Every other Phase 3 action module migrated; these two didn't.

**Fix:** Migrate both to `Repo.transact/2`, or document the grandfathering in the moduledoc.

### WR-09: `upsert_items` uses `Repo.insert!` / `update!` inside `Repo.transact`

**Files:**
- `accrue/lib/accrue/billing/subscription_actions.ex:697-707`
- `accrue/lib/accrue/webhook/default_handler.ex:233-238, 283-290`
- `accrue/lib/accrue/billing/invoice_actions.ex:158-178`

Bang variants raise `Ecto.InvalidChangesetError` on failure instead of returning `{:error, changeset}`. Enclosing `with`-chain's error handler is bypassed. The code papers over this by always returning `{:ok, :upserted}`.

**Fix:** Use non-bang variants with `Enum.reduce_while`:
```elixir
defp upsert_items(sub, stripe_sub) do
  items = extract_items(stripe_sub)
  Enum.reduce_while(items, {:ok, []}, fn si, {:ok, acc} ->
    case upsert_item(sub, si) do
      {:ok, item} -> {:cont, {:ok, [item | acc]}}
      {:error, cs} -> {:halt, {:error, cs}}
    end
  end)
end
```

### WR-10: Webhook reducer silently passes stub object to refetch without checking id

**File:** `accrue/lib/accrue/webhook/default_handler.ex:86-91`

`handle_event/3` dispatches with `%{"id" => event.object_id}`. If nil, reducer calls `Processor.fetch(:subscription, nil)` → `FunctionClauseError` in the Stripe adapter.

**Fix:**
```elixir
def handle_event(type, %Accrue.Webhook.Event{object_id: nil} = event, _ctx) do
  :telemetry.execute([:accrue, :webhooks, :missing_object_id], %{}, %{type: type})
  :ok
end
```

### WR-11: `InvoiceProjection.decompose/1` stores atom-keyed Fake data into `data` jsonb

**File:** `accrue/lib/accrue/billing/invoice_projection.ex:70`

`data: stripe_inv` assigns the raw map directly. Contrast with `SubscriptionProjection.normalize_data/1` (line 73-87), which recursively stringifies keys. On PG round-trip atom keys come back as strings, so a second pass through `InvoiceProjection.decompose/1` on reload sees a different key shape.

**Fix:** Reuse `SubscriptionProjection.to_string_keys/1`.

---

## Info

### IN-01: `Accrue.Clock.utc_now/0` does `Application.get_env` on every call
**File:** `accrue/lib/accrue/clock.ex:25-30` — persistent env caching or `compile_env + runtime override`.

### IN-02: `IntentResult` suppresses unused-alias warning via hack
**File:** `accrue/lib/accrue/billing/intent_result.ex:140` — `_ = SubscriptionItem` is dead-alias suppression; remove the `alias` instead.

### IN-03: `Accrue.Billing.Coupon` has duplicate `amount_off_cents` and `amount_off_minor`
**File:** `accrue/lib/accrue/billing/coupon.ex:24-25` — two fields hold same data; pick one in Phase 4 (prefer `_minor`).

### IN-04: `DetectExpiringCards` threshold equality is exact-match
**File:** `accrue/lib/accrue/jobs/detect_expiring_cards.ex:62` — `days_until == threshold` misses if cron runs late or tz shifts; use `days_until <= threshold and days_until > 0 and not already_warned?`.

### IN-05: `ReconcileChargeFees.reconcile/1` silently swallows API errors
**File:** `accrue/lib/accrue/jobs/reconcile_charge_fees.ex:74-76` — `with`-else returns `:skip` for `{:error, %APIError{}}`; add telemetry + log.

### IN-06: `charge.fees_settled` emitted but not in canonical 24-event list
**Files:** `reconcile_charge_fees.ex:66-71`, `reconcile_refund_fees.ex:90-97` — add to `Accrue.Events.Schemas.all/0` or stop emitting.

### IN-07: `sanitize_opts` drop-lists are brittle
**Files:** `subscription_actions.ex:626-645`, `charge_actions.ex:320-322`, `refund_actions.ex:177`, `invoice_actions.ex:194-196` — extract shared `Accrue.Billing.Options` helper.

---

## Positive Observations

- **WH-09 skip-stale implementation is clean and testable.** `reduce_row/5`'s skip-stale gate is centralized, handles nil-row and nil-watermark correctly, `:eq` tie-break matches D3-49. Tests in `default_handler_out_of_order_test.exs` lock the behavior.
- **Dual-keyed `get/2` everywhere** is a pragmatic response to Fake-atom vs. Stripe-string shape differences.
- **`IntentResult` correctly distinguishes `requires_action` from `requires_confirmation`/`requires_payment_method`** per D3-08.
- **Deterministic `subject_uuid/2`** with RFC 4122 version/variant bits is well-constructed; locked by property test.
- **Trial normalization** rejects unix integers and `:trial_period_days` with loud error messages (D3-38).
- **No PII logging detected** in Stripe adapter or Billing actions.

---

## Files of Note

**Critical:**
- `accrue/lib/accrue/processor/stripe.ex` — CR-01
- `accrue/lib/accrue/billing/charge_actions.ex` — CR-02, WR-01
- `accrue/lib/accrue/webhook/default_handler.ex` — CR-03, WR-10

**High-value warnings:**
- `accrue/lib/accrue/billing/intent_result.ex` — WR-02
- `accrue/lib/accrue/billing/refund_actions.ex` — WR-03, WR-04, WR-05
- `accrue/lib/accrue/credo/no_raw_status_access.ex` — WR-06
- `accrue/lib/accrue/plug/put_operation_id.ex` — WR-07
