---
phase: 03-core-subscription-lifecycle
plan: 08
subsystem: test-scaffolding
tags: [test-factories, event-schemas, property-tests, upcaster, nyquist]
requires:
  - "Phase 03 Plan 01: Accrue.Clock, BillingCase, StripeFixtures"
  - "Phase 03 Plan 02: Subscription/Customer schemas with predicates"
  - "Phase 03 Plan 03: Accrue.Processor.Fake (create_customer, create_subscription, transition, retrieve_*)"
  - "Phase 03 Plan 04: Accrue.Billing.subscribe/cancel/cancel_at_period_end"
  - "Phase 03 Plan 07: reducer event emissions the Upcaster will eventually handle"
  - "Phase 01: Accrue.Events.record + Event schema"
provides:
  - "Accrue.Test.Factory: nine subscription-state factories routed through Fake"
  - "Accrue.Test.Generators: StreamData generators gated on Code.ensure_loaded?"
  - "Accrue.Events.Upcaster: @callback upcast/1 behaviour contract"
  - "Accrue.Events.Schemas: 24-entry event type registry"
  - "Seven typed schema modules + 17 stub modules with schema_version/0 == 1"
  - "Property tests locking money currency invariants and idempotency determinism"
affects:
  - "Wave 0 completion: property test artifact now landed (wave_0_complete: true)"
  - "Plan 03-VALIDATION.md: reality of Wave 0 items verified"
tech-stack:
  added: []
  patterns:
    - "StreamData gated modules via Code.ensure_loaded?/1 so lib/ compiles without :stream_data in prod"
    - "Factory helper reproject/1 round-trips state through Fake.retrieve_subscription + SubscriptionProjection.decompose"
    - "Stub event-schema modules emitted via a for-loop at module top-level (no Module.create runtime trick)"
    - "Upcaster behaviour keeps identity mapping for schema_version 1; real upcasters ship when the first breaking change lands"
key-files:
  created:
    - accrue/lib/accrue/test/factory.ex
    - accrue/lib/accrue/test/generators.ex
    - accrue/lib/accrue/events/upcaster.ex
    - accrue/lib/accrue/events/schemas.ex
    - accrue/lib/accrue/events/schemas/subscription_created.ex
    - accrue/lib/accrue/events/schemas/subscription_updated.ex
    - accrue/lib/accrue/events/schemas/subscription_canceled.ex
    - accrue/lib/accrue/events/schemas/subscription_plan_swapped.ex
    - accrue/lib/accrue/events/schemas/invoice_paid.ex
    - accrue/lib/accrue/events/schemas/refund_created.ex
    - accrue/lib/accrue/events/schemas/card_expiring_soon.ex
    - accrue/test/accrue/test/factory_test.exs
    - accrue/test/accrue/events/schemas_test.exs
    - accrue/test/accrue/billing/properties/proration_test.exs
    - accrue/test/accrue/billing/properties/idempotency_key_test.exs
  modified:
    - .planning/phases/03-core-subscription-lifecycle/03-VALIDATION.md
decisions:
  - "Factories insert Customer rows directly via Customer.changeset/Repo.insert instead of Accrue.Billing.create_customer, because the Billing context's create_customer accepts a billable struct (User/etc.) not a bare attrs map — matches the pattern existing Plan 04/05/06 tests use in their setup blocks"
  - "17 stub event schema modules live in schemas.ex (not separate files) via a top-level for-loop emitting defmodule, because the stubs carry no type information and expanding any one into a typed struct is a single file move"
  - "Test assertions for every-module-implements checks call Code.ensure_loaded!/1 explicitly so test ordering can't cause a stub module to be referenced before it's loaded"
  - "Factory's canceled_subscription/canceling_subscription/grace_period_subscription fork from active_subscription (not from subscribe directly) to exercise the real cancel/cancel_at_period_end code path"
metrics:
  duration: ~15m
  completed: 2026-04-14
---

# Phase 03 Plan 08: Test Factories + Event Schemas + Property Tests Summary

First-class test factories for every subscription state, canonical event
schema registry for all 24 Phase 3 event types, and property tests locking
money math and idempotency determinism under random inputs.

## What Shipped

### Task 1 — `Accrue.Test.Factory` (D3-79..85)

Nine subscription-state factories living in `lib/` (so Phase 8's
`mix accrue.seed` can reuse them in `:dev`) plus a primitive
`customer/1` constructor. Every factory:

- Routes through `Accrue.Processor.Fake` via `Billing.subscribe/3`
  or direct `Fake.transition/3` calls.
- Derives timestamps from `Accrue.Clock.utc_now/0` — never
  `DateTime.utc_now/0`. Advancing the Fake clock moves all factory
  timestamps in lockstep, so time-sensitive billing paths
  (trial ending, past-due, dunning) can be exercised without sleeping.
- Returns `%{customer:, subscription:, items:}` with
  `subscription_items` preloaded.

State coverage: `trialing`, `active`, `past_due`, `incomplete`,
`canceled`, `canceling` (active + cancel_at_period_end),
`grace_period` (canceled but future period end), `trial_ending`
(trial_end within 72h).

`Accrue.Test.Generators` lives alongside the factory and provides
StreamData generators for money amounts, currencies, proration
behaviors, Stripe status atoms, operation IDs, and subject IDs.
The module is gated on `Code.ensure_loaded?(StreamData)` so it
only exists in `:dev`/`:test` where `:stream_data` is present.

Async-safety is proven by a 100-concurrent regression test that
spawns 100 tasks each calling `trialing_subscription/0`, asserts
all 100 row IDs AND all 100 `processor_id` counter values are
unique, and completes within 30s. Uses `Ecto.Adapters.SQL.Sandbox.allow/3`
explicitly so each Task child checks out its own connection.

### Task 2 — Event schemas + Upcaster (D3-65..70)

`Accrue.Events.Upcaster` is a one-callback behaviour
(`@callback upcast(map()) :: {:ok, map()} | {:error, term()}`)
establishing the contract for schema_version evolution. Phase 3
ships every event at `schema_version: 1` with identity upcasters;
the behaviour exists so future breaking changes have a place to
live without touching `Accrue.Events.record/1` callers.

Seven fully-typed schema modules ship with explicit struct fields,
`@derive Jason.Encoder`, `@type t :: %__MODULE__{...}`, and
`schema_version/0` + `upcast/1` implementations:

| Module | Event type |
|---|---|
| `SubscriptionCreated` | `:"subscription.created"` |
| `SubscriptionUpdated` | `:"subscription.updated"` |
| `SubscriptionCanceled` | `:"subscription.canceled"` |
| `SubscriptionPlanSwapped` | `:"subscription.plan_swapped"` |
| `InvoicePaid` | `:"invoice.paid"` |
| `RefundCreated` | `:"refund.created"` |
| `CardExpiringSoon` | `:"card.expiring_soon"` |

Seventeen additional stub modules cover the remaining event types
(trial_started, trial_ended, resumed, paused, invoice.created,
invoice.finalized, invoice.payment_failed, invoice.voided,
invoice.marked_uncollectible, charge.succeeded/failed/refunded,
refund.fees_settled, payment_method.attached/detached/updated,
customer.default_payment_method_changed) with minimal
`defstruct [data: %{}, source: :api]` shapes. They implement the
Upcaster contract and register at `schema_version: 1`, so the
read-path machinery can dispatch through them identically to the
typed modules. Expanding any stub into a typed struct is a
non-breaking file move.

`Accrue.Events.Schemas.for/1` looks up the module for an event
atom (returns `nil` for unknown). `all/0` returns the full map.
`count/0` returns exactly 24.

### Task 3 — Property tests + VALIDATION verification

**`Accrue.Billing.Properties.IdempotencyKeyTest`** (6 properties):

- `key/3` deterministic for any `(op, subject, operation_id)`
- different `subject_id` → different key
- different `operation_id` → different key
- sequence suffix changes the key
- `subject_uuid/2` is a valid Ecto.UUID
- `subject_uuid/2` is deterministic

**`Accrue.Billing.Properties.ProrationTest`** (8 properties):

- `Money.add` preserves currency and sums minor units
- `Money.subtract` preserves currency
- mixed-currency `add` raises `MismatchedCurrencyError` (D-04)
- mixed-currency `subtract` raises `MismatchedCurrencyError`
- JPY zero-decimal round-trips arbitrary integers
- `Money.new/2` rejects float amounts (no float money math, D-03)
- `Money.equal?/2` is reflexive
- `Money.add` is commutative within a currency

All 14 properties run 100+ random inputs per StreamData default and
execute in ~200ms.

**VALIDATION.md verification:**

- `nyquist_compliant: true` ✓ (unchanged — set during planning revision)
- `wave_0_complete: true` ✓ (flipped this plan, see Deviations)
- Per-Task Verification Map: 24 rows across Plans 01–08 ✓
  (`grep -cE '^\| 0[1-8]-T[1-4]'` returns 24)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan pseudocode used wrong `Billing.create_customer/1` API**

- **Found during:** Task 1
- **Issue:** The plan's factory pseudocode called
  `Billing.create_customer(map)` and referenced
  `sub.stripe_id`, but the actual Phase 02/04 API requires a
  billable struct (`%User{}`) for `create_customer/1` and uses
  `sub.processor_id` (not `stripe_id`) throughout. The project
  dropped the `stripe_id` field in Plan 02 in favor of the
  processor-agnostic `processor_id`.
- **Fix:** Factories insert `Customer` rows directly via
  `Customer.changeset/2 |> Repo.insert/1`, matching the setup
  block pattern in `subscription_test.exs`,
  `subscription_cancel_test.exs`, and
  `subscription_state_machine_test.exs`. Also references `processor_id`
  everywhere, and `reproject/1` uses
  `Fake.retrieve_subscription(sub.processor_id, [])`.
- **Files modified:** accrue/lib/accrue/test/factory.ex
- **Commit:** d5e809b

**2. [Rule 1 - Bug] Plan property tests used `Decimal.to_integer(sum.amount)` but Money stores `amount_minor`**

- **Found during:** Task 3
- **Issue:** Plan pseudocode asserted
  `Decimal.to_integer(sum.amount) == a + b` and expected
  `ArgumentError` on mixed-currency `add`. The real `Accrue.Money`
  struct exposes `amount_minor` as a plain integer and raises
  `Accrue.Money.MismatchedCurrencyError` (not `ArgumentError`) on
  currency mismatch.
- **Fix:** Assertions rewritten against the real Money API: check
  `sum.amount_minor == a + b`, and `assert_raise MismatchedCurrencyError`
  for currency-mismatch paths. Added three bonus properties
  (`subtract` currency preservation, `equal?` reflexivity, `add`
  commutativity) to make the test module a proper invariant lock.
- **Files modified:** accrue/test/accrue/billing/properties/proration_test.exs
- **Commit:** 77bfbca

**3. [Rule 1 - Bug] `wave_0_complete: false` in VALIDATION.md contradicted reality once the property test module landed**

- **Found during:** Task 3
- **Issue:** The plan's VALIDATION file had `wave_0_complete: false`
  and `- [ ] Property test module for money/proration math`
  because Wave 0 item #4 was explicitly the property test module
  that Plan 08 Task 3 creates. The file tracked this as incomplete
  while instructing Task 3 to "verify it without editing". But
  Task 3's acceptance criteria required `wave_0_complete: true`.
  Interpreting the contradiction: "don't touch the Per-Task
  Verification Map" was the real constraint; flipping the Wave 0
  completion flag to match the reality that the artifact now
  exists is correctness-bookkeeping, not map repopulation.
- **Fix:** Flipped `wave_0_complete: false` → `true` and checked the
  `[ ]` → `[x]` box for the property test module. Per-Task
  Verification Map untouched.
- **Files modified:** .planning/phases/03-core-subscription-lifecycle/03-VALIDATION.md
- **Commit:** 77bfbca

**4. [Rule 1 - Bug] Stub schema modules not auto-loaded before `function_exported?` check**

- **Found during:** Full Plan 08 suite run after Task 3 commit
- **Issue:** Test ordering-dependent failure: running
  `schemas_test.exs` alone passed (the module load order put the
  stubs in the VM), but running with factory_test first caused
  `function_exported?(mod, :schema_version, 0)` to return false
  for stub modules because they had only been compiled, never
  loaded. The stubs are defined via a top-level for-loop in
  `schemas.ex` so they're on the codepath but aren't auto-loaded
  by an atom reference in a map.
- **Fix:** Added `Code.ensure_loaded!(mod)` before each
  `function_exported?` assertion in the two
  "every registered module..." tests.
- **Files modified:** accrue/test/accrue/events/schemas_test.exs
- **Commit:** 7f0e107

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 7a6d69c | test(03-08): add failing tests for Accrue.Test.Factory (Task 1 RED) |
| 2 | d5e809b | feat(03-08): Accrue.Test.Factory nine subscription-state factories (Task 1) |
| 3 | 7b5ca20 | test(03-08): add failing tests for event schemas registry (Task 2 RED) |
| 4 | a89aacf | feat(03-08): canonical event schemas + Upcaster behaviour (Task 2) |
| 5 | 77bfbca | test(03-08): property tests for money math + idempotency determinism (Task 3) |
| 6 | 7f0e107 | fix(03-08): ensure_loaded stub schema modules before function_exported? check |

## Test Results

- `mix test test/accrue/test/factory_test.exs` — 12/12 green
- `mix test test/accrue/events/schemas_test.exs` — 7/7 green
- `mix test test/accrue/billing/properties/` — 14/14 properties green
- Full Plan 08 suite: 19 tests + 14 properties, 0 failures (~500ms)

## Self-Check: PASSED

**Files:**

- FOUND: accrue/lib/accrue/test/factory.ex
- FOUND: accrue/lib/accrue/test/generators.ex
- FOUND: accrue/lib/accrue/events/upcaster.ex
- FOUND: accrue/lib/accrue/events/schemas.ex
- FOUND: accrue/lib/accrue/events/schemas/subscription_created.ex
- FOUND: accrue/lib/accrue/events/schemas/subscription_updated.ex
- FOUND: accrue/lib/accrue/events/schemas/subscription_canceled.ex
- FOUND: accrue/lib/accrue/events/schemas/subscription_plan_swapped.ex
- FOUND: accrue/lib/accrue/events/schemas/invoice_paid.ex
- FOUND: accrue/lib/accrue/events/schemas/refund_created.ex
- FOUND: accrue/lib/accrue/events/schemas/card_expiring_soon.ex
- FOUND: accrue/test/accrue/test/factory_test.exs
- FOUND: accrue/test/accrue/events/schemas_test.exs
- FOUND: accrue/test/accrue/billing/properties/proration_test.exs
- FOUND: accrue/test/accrue/billing/properties/idempotency_key_test.exs

**Commits:**

- FOUND: 7a6d69c
- FOUND: d5e809b
- FOUND: 7b5ca20
- FOUND: a89aacf
- FOUND: 77bfbca
- FOUND: 7f0e107
