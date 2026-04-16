---
phase: 03-core-subscription-lifecycle
plan: 06
subsystem: core-subscription-lifecycle
tags: [billing, charge, payment-intent, setup-intent, payment-method, refund, sca, fingerprint-dedup, fee-math]
dependency_graph:
  requires:
    - "03-01: Accrue.Actor.current_operation_id!, Accrue.Error.{NoDefaultPaymentMethod, NotAttached}, Accrue.ActionRequiredError, BillingCase, StripeFixtures"
    - "03-02: Charge/Refund/PaymentMethod/Customer schemas — amount_cents, stripe_fee_*, fingerprint, default_payment_method_id, partial unique index on (customer_id, fingerprint)"
    - "03-03: Accrue.Processor behaviour {create_charge, create_payment_intent, create_setup_intent, retrieve_payment_method, attach_payment_method, detach_payment_method, set_default_payment_method, create_refund} + Fake handlers + Idempotency.key/subject_uuid"
    - "03-04: Accrue.Billing.IntentResult.wrap/1 tagged-union wrapper"
  provides:
    - "Accrue.Billing.charge/3 + charge!/3 with SCA tagged returns (BILL-20, BILL-21)"
    - "Accrue.Billing.create_payment_intent/2 + create_setup_intent/2 with IntentResult wrapping (BILL-22)"
    - "Accrue.Billing.attach_payment_method/3 with fingerprint dedup + partial-unique-index race catch (BILL-23)"
    - "Accrue.Billing.detach_payment_method/2 delete-and-emit"
    - "Accrue.Billing.set_default_payment_method/3 with strict attachment check raising Accrue.Error.NotAttached (BILL-25)"
    - "Accrue.Billing.create_refund/2 with sync-best-effort fee math (stripe_fee_refunded_amount_minor + merchant_loss_amount_minor + fees_settled_at) (BILL-26)"
    - "Accrue.Repo facade extensions: get/get_by/get_by!/delete/aggregate"
  affects:
    - "Plan 07 webhook DefaultHandler reconcile path gains the .charge.succeeded / .refund.updated sinks (fee backstop when sync path returns unsettled)"
    - "Plan 08 telemetry ExDoc regen surfaces the three new Billing entry points"
tech_stack:
  added: []
  patterns:
    - "Pre-transact SCA check: Processor.create_charge runs BEFORE Repo.transact so requires_action PIs never persist a half-baked Charge row — IntentResult.wrap on the raw processor response branches to {:ok, :requires_action, pi} before any DB insert"
    - "Deterministic row id via Idempotency.subject_uuid(:create_charge/:create_refund, operation_id) → force_change(:id, subject_uuid) → Repo.get(Charge|Refund, id) returns the existing row on retry (atom conflict-safe retry without ON CONFLICT)"
    - "Fingerprint dedup shaped as: application-level SELECT first, attach-and-insert on miss, rescue Ecto.ConstraintError on concurrent race and detach the loser's Stripe PM before returning the winner row with existing?: true"
    - "Uniform {:ok, %Refund{}} return — fee settlement state is a property (fees_settled?/1 predicate), not a tagged-return branch. Webhook backstop in Plan 07 fills unsettled columns asynchronously."
    - "Strict customer-ownership assertion at set_default_payment_method entry (Accrue.Error.NotAttached) runs BEFORE any processor call — cannot silently wire a foreign PM as customer default"
key_files:
  created:
    - accrue/test/accrue/billing/charge_test.exs
    - accrue/test/accrue/billing/payment_intent_test.exs
    - accrue/test/accrue/billing/setup_intent_test.exs
    - accrue/test/accrue/billing/payment_method_dedup_test.exs
    - accrue/test/accrue/billing/default_payment_method_test.exs
    - accrue/test/accrue/billing/refund_test.exs
  modified:
    - accrue/lib/accrue/billing/charge_actions.ex
    - accrue/lib/accrue/billing/payment_method_actions.ex
    - accrue/lib/accrue/billing/refund_actions.ex
    - accrue/lib/accrue/repo.ex
decisions:
  - "charge/3 calls Processor.create_charge OUTSIDE Repo.transact so SCA/3DS responses never persist a half-baked Charge row for a PaymentIntent that still needs customer action. IntentResult.wrap runs on the processor response first; only the {:ok, map} happy path enters the transaction."
  - "Charge schema uses amount_cents + processor/processor_id (NOT amount_minor/stripe_id as the plan literal suggested). Plan 02 fixed those field names — followed schema, not plan example. Same for PaymentMethod (processor_id, not stripe_id)."
  - "Refund schema does use stripe_id + amount_minor (different convention, because it was the first Phase 3 schema rolled out under the new naming). Followed the actual schema not the plan example in RefundActions."
  - "Idempotent retry is handled via Repo.get(schema, subject_uuid) check before insert rather than ON CONFLICT DO NOTHING. This keeps the insert path single-statement and avoids needing a conflict_target for partial indexes that don't exist on the subject_uuid column."
  - "Accrue.Repo facade grew five new delegations (get/get_by/get_by!/delete/aggregate) — Plan 06 is the first plan that needs .get for subject_uuid retrieve-or-insert, .delete for PM detach, and .aggregate for test count assertions. D-10 host-owns-Repo preserved; these are pure facade pass-throughs like the existing preload/insert!/update!."
  - "Null fingerprint on a retrieved PM skips the dedup path entirely — we cannot de-duplicate without a key. Non-card PMs (ACH, sepa_debit, etc.) and fingerprint-less card responses always insert fresh rows. Documented in attach_payment_method/3 @doc."
  - "set_default_payment_method/3 raises Accrue.Error.NotAttached BEFORE any processor call. A mismatched pm.customer_id is a programmer error, not a runtime recoverable — loud, typed, no tuple return."
metrics:
  duration: "~25 minutes"
  completed: "2026-04-14"
  tasks_completed: 3
  files_created: 6
  files_modified: 4
  test_count: "340 tests, 20 properties, 0 failures (up from 296 baseline, +26 new across Tasks 1-3: 9 charge + 3 PI + 3 SI + 4 PM dedup + 3 default PM + 5 refund)"
requirements: [BILL-20, BILL-21, BILL-22, BILL-23, BILL-25, BILL-26]
---

# Phase 3 Plan 06: Charge + PaymentMethod + Refund write surface Summary

Plan 06 ships the Phase 3 third-rail surface: `Accrue.Billing.charge/3`
with SCA tagged returns (BILL-20/21), `create_setup_intent/2` parallel
for BILL-22 off-session card-on-file, `attach_payment_method/3` with
fingerprint dedup + partial-unique-index race catch (BILL-23),
`set_default_payment_method/3` with strict attachment check raising
`Accrue.Error.NotAttached` on mismatch (BILL-25), and
`create_refund/2` with sync-best-effort fee math (BILL-26). Every
mutation is wired through the existing Plan 01 `defdelegate` facade on
`Accrue.Billing` — Plan 06 only touches the three per-surface action
modules (`ChargeActions`, `PaymentMethodActions`, `RefundActions`)
plus a handful of new `Accrue.Repo` delegations needed for `get`,
`delete`, and `aggregate`.

All six requirements (BILL-20, BILL-21, BILL-22, BILL-23, BILL-25,
BILL-26) are covered by green tests (26 new tests across 6 new test
files). The full Phase 3 test suite grew from 296 to 340 tests, 0
failures. `mix credo --strict` clean.

## Work Completed

### Task 1 — Charge + PaymentIntent + SetupIntent actions (TDD)

**Commit:** `10a2205`

`Accrue.Billing.ChargeActions` replaces the Plan 01 stub with the full
Plan 06 surface:

- **`charge/3` (BILL-20, BILL-21)** — Resolves the `%Customer{}` from a
  billable struct or accepts a `%Customer{}` directly. Reads the
  payment method id from `opts[:payment_method]` or the customer's
  preloaded `:default_payment_method` association. When BOTH are nil,
  returns a typed `{:error, %Accrue.Error.NoDefaultPaymentMethod{
  customer_id: id}}` — never silently falls back to "first attached PM"
  (D3-58 Cashier footgun avoided). `charge!/3` raises
  `Accrue.Error.NoDefaultPaymentMethod` via the bang wrapper.

  The processor call (`Processor.__impl__().create_charge/2`) runs
  OUTSIDE the `Repo.transact/2` block so a requires_action
  PaymentIntent response never persists a half-baked Charge row.
  `IntentResult.wrap/1` runs on the raw processor response first —
  `{:ok, :requires_action, pi}` returns early; only the `{:ok, map}`
  happy path enters the DB transaction and creates the Charge + event
  row.

  Charge id is pre-allocated via `Idempotency.subject_uuid(
  :create_charge, operation_id)` and the insert path is retry-safe:
  `Repo.get(Charge, subject_uuid)` short-circuits to return the
  existing row on retry. `:balance_transaction.fee` → persists in
  `stripe_fee_amount_minor` + `fees_settled_at = Accrue.Clock.utc_now/0`
  (sync path). `charge.succeeded` / `charge.failed` event emitted
  inside the same transaction (EVT-04).

- **`create_payment_intent/2`** — Thin wrapper over
  `Processor.create_payment_intent/2` with `IntentResult.wrap/1` on the
  result so SCA paths surface `{:ok, :requires_action, pi}`. Seeds
  a deterministic idempotency key via
  `Idempotency.key(:create_payment_intent, op_id, op_id)`.

- **`create_setup_intent/2` (BILL-22)** — Off-session card-on-file
  parallel. Forces `usage: "off_session"` in the params and routes the
  Fake/Stripe response through `IntentResult.wrap/1`. Same dual-API
  pair as charge (`create_setup_intent!/2` raises
  `Accrue.ActionRequiredError` on `{:ok, :requires_action, si}`).

- **Dual-API discipline** — every entry point ships as `foo/n` +
  `foo!/n`. The bang variants raise `Accrue.ActionRequiredError` on
  SCA, `is_exception/1` errors pass through `raise`, non-exception
  errors become a raw `RuntimeError` with `inspect/1` payload.

**Tests (14 new):**

- `charge_test.exs` (8): explicit `:payment_method` happy path,
  `default_payment_method_id` resolution, `{:error,
  %NoDefaultPaymentMethod{}}` tuple, `charge!/3` raises same, scripted
  3DS tagged return, `stripe_fee_amount_minor` projection from
  balance_transaction, deterministic `operation_id` → same charge row
  on retry (idempotency proof), `charge.succeeded` event row emitted.
- `payment_intent_test.exs` (3): default succeeded return, scripted
  `requires_action_test` → tagged return, `create_payment_intent!/2`
  raises `ActionRequiredError`.
- `setup_intent_test.exs` (3): off-session default happy path,
  scripted SCA → tagged return, `create_setup_intent!/2` raises.

### Task 2 — PaymentMethod attach/detach/set_default (TDD)

**Commit:** `65204b1`

`Accrue.Billing.PaymentMethodActions` replaces the Plan 01 stub:

- **`attach_payment_method/3` (BILL-23)** — Retrieves the canonical
  PaymentMethod from the processor (`retrieve_payment_method/2`).
  Extracts the `card.fingerprint`. If fingerprint is nil (non-card PM
  or fingerprint-less response), inserts fresh — cannot dedup without
  a key. Otherwise:

  1. Application-level SELECT: `from p in PaymentMethod, where:
     p.customer_id == ^c.id and p.fingerprint == ^fp`.
  2. **Miss path**: call `Processor.attach_payment_method/3` + insert
     new row. If a concurrent attach races past the SELECT and wins
     the insert, our insert crashes into the
     `accrue_payment_methods_customer_fingerprint_idx` partial unique
     index. Rescue `Ecto.ConstraintError` → call
     `Processor.detach_payment_method/2` on the loser's Stripe PM →
     re-fetch the winner row via `Repo.get_by!/2` → return with
     `existing?: true`.
  3. **Hit path**: detach the new Stripe PM (idempotent no-op on
     already-detached) → return the existing row with `existing?:
     true`.

  Event emitted: `payment_method.attached` with `%{deduped: boolean,
  fingerprint: binary | nil}` inside the same transaction.

- **`detach_payment_method/2`** — Calls the processor detach then
  `Repo.delete(pm)` and emits `payment_method.detached` — all in the
  same `Repo.transact/2`. Cascading the delete (not just flagging) is
  intentional: a detached PM is no longer usable for charges, and the
  customer's `default_payment_method_id` auto-nilifies via the
  migration's `on_delete: :nilify_all` FK.

- **`set_default_payment_method/3` (BILL-25)** — Asserts
  `pm.customer_id == customer.id` BEFORE any processor call and raises
  `Accrue.Error.NotAttached` with an explicit cross-pointer message
  when mismatched. This is a programmer error, not runtime recoverable
  — loud, typed, no tuple return. Then: calls
  `Processor.set_default_payment_method/3` with `%{invoice_settings:
  %{default_payment_method: pm.processor_id}}`, updates the local
  `customer.default_payment_method_id` column, emits
  `customer.default_payment_method_changed`.

**Tests (7 new):**

- `payment_method_dedup_test.exs` (4): unique fingerprint insert with
  `existing?: false`, same-fingerprint dedup → `existing?: true` +
  DB count 1, nil fingerprint → N calls → N rows, detach removes DB
  row.
- `default_payment_method_test.exs` (3): set_default happy path
  updates `default_payment_method_id`, NotAttached on foreign PM,
  charge/3 uses customer.default_payment_method after set_default
  (end-to-end flow).

### Task 3 — Refund with sync-best-effort fee math (TDD)

**Commit:** `af95d5f`

`Accrue.Billing.RefundActions` replaces the Plan 01 stub:

- **`create_refund/2` (BILL-26, D3-45..47)** — Accepts `:amount
  (%Money{} | nil — full refund if nil)`, `:reason`, `:operation_id`.
  Calls `Processor.create_refund/2` with forced `expand:
  ["balance_transaction", "charge.balance_transaction"]` (Plan 03
  already pre-seeded this on the Stripe adapter). Projects fee math
  from the expanded response:

  ```
  fee = stripe_refund.charge.balance_transaction.fee
  fee_refunded = stripe_refund.charge.balance_transaction.fee_refunded

  stripe_fee_refunded_amount_minor = fee_refunded
  merchant_loss_amount_minor       = fee - fee_refunded
  fees_settled_at                  = Accrue.Clock.utc_now() (when both integers)
  ```

  When either field is nil (Stripe hasn't finalized the fee yet), the
  columns stay nil and `fees_settled_at` is nil — the webhook backstop
  in Plan 07 (`charge.refund.updated` handler) fills them
  asynchronously. Predicate `Refund.fees_settled?/1` (Plan 02)
  reflects the `fees_settled_at` column so downstream reconcilers can
  skip already-settled rows.

  Refund id is pre-allocated via `Idempotency.subject_uuid(
  :create_refund, operation_id)` and the retry-safe
  `Repo.get(Refund, id)` short-circuit is in place.

  **Uniform return shape**: `{:ok, %Refund{}}` — NO tagged variant
  like `{:ok, :pending_fees, _}` (D3-47). Settlement state is a
  property of the row, not a branch in the caller's control flow.

- **`create_refund!/2`** — Dual-API raising variant. `is_exception/1`
  errors pass through `raise`, non-exception errors become
  `RuntimeError` with `inspect/1`.

**Tests (5 new):**

- Populated `fee_refunded` → `stripe_fee_refunded_amount_minor = 310`,
  `merchant_loss_amount_minor = 10`, `fees_settled_at != nil`,
  `Refund.fees_settled?/1 == true`.
- Nil `fee_refunded` → both columns nil, `fees_settled_at == nil`,
  `fees_settled?/1 == false`.
- Partial `:amount` via `Accrue.Money.new(5000, :usd)` → `amount_minor
  == 5000`.
- `refund.created` event row emitted with `subject_id = refund.id`.
- Uniform `{:ok, %Refund{}}` return — no `:pending_fees` tag, no
  `:requires_action` tag.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan literal used wrong Money field (`amount.amount`) + wrong Charge schema fields (`stripe_id`, `amount_minor`)**

- **Found during:** Task 1 implementation
- **Issue:** The plan's example code reads `amount.amount |>
  Decimal.to_integer()` (treats Money as if it had a Decimal `:amount`
  field) and inserts Charge rows with `stripe_id:` and `amount_minor:`
  — fields that don't exist on the Plan 02 Charge schema. The actual
  `%Accrue.Money{}` struct stores `:amount_minor` (integer) and the
  Charge schema uses `:processor_id` (not `:stripe_id`) + `:amount_cents`
  (not `:amount_minor`). Both are legacy-naming artifacts from Phase 2
  schemas that predate the bigint migration.
- **Fix:** Use `amount.amount_minor` directly; insert Charge with
  `processor_id: stripe_ch.id` and `amount_cents: amount.amount_minor`.
  Uses `processor/processor_id` pattern consistent with Phase 2
  Customer/Subscription schemas.
- **Files modified:** `accrue/lib/accrue/billing/charge_actions.ex`
- **Commit:** `10a2205`

**2. [Rule 1 — Bug] Plan example persists Charge inside Repo.transact even for requires_action shape**

- **Found during:** Task 1 scripted 3DS test run
- **Issue:** The plan's example wraps `Processor.create_charge` +
  `insert_charge` + `Events.record` all inside a single
  `Repo.transact/2` block, then pipes the whole result through
  `IntentResult.wrap/1`. But `IntentResult.wrap({:ok, %Charge{}})`
  inspects Charge structs for embedded PIs (via
  `sub_pending_intent/1`) and returns the Charge unwrapped — it has
  no branch that surfaces a SCA tag from inside a committed Charge
  row. So a scripted-3DS test that returns a PaymentIntent shape
  would (a) persist a half-baked Charge row with
  `status: "requires_action"`, and (b) return `{:ok, %Charge{}}` to
  the caller instead of the expected `{:ok, :requires_action, pi}`.
- **Fix:** Moved `Processor.create_charge/2` OUTSIDE the
  `Repo.transact/2` block. `IntentResult.wrap/1` runs on the raw
  processor response first — if it's `{:ok, :requires_action, pi}`,
  we return immediately without persisting anything. Only the
  `{:ok, map}` happy path enters the transaction. This matches the
  plan's stated intent (SCA never persists half-baked rows) and makes
  the scripted-3DS test pass.
- **Files modified:** `accrue/lib/accrue/billing/charge_actions.ex`
- **Commit:** `10a2205`

**3. [Rule 3 — Blocking] Accrue.Repo facade missing get/get_by/get_by!/delete/aggregate**

- **Found during:** Task 1 first compile (`Accrue.Repo.get/2 is
  undefined or private`)
- **Issue:** Plan 06 is the first plan that needs:
  * `Repo.get(Charge | Refund, subject_uuid)` for retry-safe insert
    (idempotent re-runs return the existing row).
  * `Repo.get_by!/2` for fingerprint dedup race catch.
  * `Repo.delete/1` for PM detach.
  * `Repo.aggregate/4` for test count assertions against
    `"accrue_events"` and `PaymentMethod`.
  Prior plans used `Repo.one` + changesets only. Plumbing
  `Accrue.Repo.repo().get(...)` at every call site breaks the facade
  lockdown and is noisy.
- **Fix:** Added five new delegations to `Accrue.Repo` matching the
  existing `insert/update/preload/insert!/update!` pass-through
  pattern. D-10 host-owns-Repo is unchanged; these are pure facade
  extensions.
- **Files modified:** `accrue/lib/accrue/repo.ex`
- **Commit:** `10a2205`

**4. [Rule 1 — Bug] Plan's event `subject_id` query used `type(^id, :binary_id)` cast**

- **Found during:** Task 1 event-row test run
  (`operator does not exist: character varying = uuid`)
- **Issue:** Plan's test literal queries
  `where: e.subject_id == type(^charge_id, :binary_id)`. But the
  `accrue_events.subject_id` column is a `:string` (varchar), not a
  `binary_id`, so the cast fails at Postgres level with SQLSTATE
  42883.
- **Fix:** Removed the cast; UUID strings compare fine against varchar.
- **Files modified:** `accrue/test/accrue/billing/charge_test.exs`
- **Commit:** `10a2205`

**5. [Rule 1 — Bug] Plan literal used `stripe_id` field on Refund (is correct for Refund but not Charge)**

- **Found during:** Task 3 cross-check against schemas
- **Issue:** Refund schema (Plan 02) uses `:stripe_id`, `:amount_minor`
  — different convention than Charge (which uses `:processor_id`,
  `:amount_cents`). Easy to mix them up in a parallel write across
  three action modules.
- **Fix:** RefundActions follows the Refund schema verbatim
  (`stripe_id`, `amount_minor`). ChargeActions follows Charge schema
  (`processor_id`, `amount_cents`). Both are correct; they simply
  follow different conventions inherited from when the tables were
  first migrated. Documented in decisions for future parallel-plan
  agents.
- **Files modified:** none (informational — followed the actual
  schemas, not the plan example)

### Pre-existing warnings (noted, out of scope)

`test/accrue/webhook/dispatch_worker_test.exs:181` unused variable
`processed_at` and line 6 unused alias `Event` remain. These are
pre-existing from Phase 2 (commit `b86239d`) and already logged in
`deferred-items.md` from 03-02 — same scope-boundary decision as
prior plans. `mix test` runs pass 340/340; only
`mix test --warnings-as-errors` surfaces them.

## Verification Results

- `mix compile --warnings-as-errors --force` — clean (0 warnings,
  77 source files)
- `mix test --seed 0` — **340 tests, 20 properties, 0 failures** (up
  from 296 baseline in 03-05, +26 new across 6 new test files)
- `mix test test/accrue/billing/charge_test.exs` — 8/8
- `mix test test/accrue/billing/payment_intent_test.exs` — 3/3
- `mix test test/accrue/billing/setup_intent_test.exs` — 3/3
- `mix test test/accrue/billing/payment_method_dedup_test.exs` — 4/4
- `mix test test/accrue/billing/default_payment_method_test.exs` — 3/3
- `mix test test/accrue/billing/refund_test.exs` — 5/5
- `mix credo --strict` — **0 issues** across 124 source files (886
  mods/funs analyzed)

## Success Criteria

- [x] `charge/3` returns intent_result; 3DS path proven with scripted
      Fake response
- [x] `charge/3` returns `{:error, %NoDefaultPaymentMethod{}}` when PM
      resolution fails
- [x] `charge!/3` raises `NoDefaultPaymentMethod` when PM resolution
      fails
- [x] `attach_payment_method/3` dedupes by fingerprint and returns
      `existing?: true`
- [x] Partial unique index backstop rescues `Ecto.ConstraintError` on
      concurrent race path
- [x] `set_default_payment_method/3` raises `NotAttached` for foreign
      PM BEFORE any processor call
- [x] `create_refund/2` populates `merchant_loss_amount_minor` when
      `balance_transaction.fee_refunded` is present
- [x] `create_refund/2` returns uniform `{:ok, %Refund{}}` — no
      `:pending_fees` tag

## Acceptance Criteria Checklist

Task 1:

- [x] `defmodule Accrue.Billing.ChargeActions` — present
- [x] `def charge` — present
- [x] `{:error, %Accrue.Error.NoDefaultPaymentMethod{` — present
- [x] `assert_raise Accrue.Error.NoDefaultPaymentMethod` — present in
      `charge_test.exs`
- [x] `def create_setup_intent` — present
- [x] `usage.*off_session` — present
- [x] `expand.*balance_transaction` — present
- [x] 14 tests passing (plan specified ≥11)

Task 2:

- [x] `defmodule Accrue.Billing.PaymentMethodActions` — present
- [x] `def attach_payment_method` — present
- [x] `Ecto.ConstraintError` — present (race catch)
- [x] `dedup_or_attach` — present
- [x] `existing?: true` — present
- [x] `Accrue.Error.NotAttached` — present
- [x] `def set_default_payment_method` — present
- [x] 4 dedup tests passing (plan specified ≥4)
- [x] 3 default-PM tests passing (plan specified ≥3)

Task 3:

- [x] `defmodule Accrue.Billing.RefundActions` — present
- [x] `def create_refund` — present
- [x] `charge.balance_transaction` expand path — present
- [x] `merchant_loss` — present
- [x] `fees_settled_at` — present
- [x] 5 refund tests passing (plan specified 5)

## Self-Check: PASSED

All created files exist, all commits are in the log:

- `accrue/lib/accrue/billing/charge_actions.ex` — MODIFIED (full
  Plan 06 implementation)
- `accrue/lib/accrue/billing/payment_method_actions.ex` — MODIFIED
- `accrue/lib/accrue/billing/refund_actions.ex` — MODIFIED
- `accrue/lib/accrue/repo.ex` — MODIFIED (get/get_by/get_by!/delete/aggregate)
- `accrue/test/accrue/billing/charge_test.exs` — FOUND (8 tests)
- `accrue/test/accrue/billing/payment_intent_test.exs` — FOUND (3 tests)
- `accrue/test/accrue/billing/setup_intent_test.exs` — FOUND (3 tests)
- `accrue/test/accrue/billing/payment_method_dedup_test.exs` — FOUND (4 tests)
- `accrue/test/accrue/billing/default_payment_method_test.exs` — FOUND (3 tests)
- `accrue/test/accrue/billing/refund_test.exs` — FOUND (5 tests)
- Commit `10a2205` (Task 1) — FOUND
- Commit `65204b1` (Task 2) — FOUND
- Commit `af95d5f` (Task 3) — FOUND
