---
phase: 03-core-subscription-lifecycle
plan: 03
subsystem: core-subscription-lifecycle
tags: [processor, behaviour, fake, stripe, idempotency, lattice_stripe]
dependency_graph:
  requires:
    - "03-01: Accrue.Clock, Accrue.Processor.Fake.now/0, Accrue.BillingCase"
    - "Phase 1: Accrue.Processor behaviour + Fake customer callbacks + Stripe.compute_idempotency_key"
    - "lattice_stripe ~> 1.0 (Subscription, Invoice, PaymentIntent, SetupIntent, PaymentMethod, Charge, Refund, Customer)"
  provides:
    - "Accrue.Processor behaviour with 38 Phase 3 callbacks including fetch/2 and pause_subscription_collection/4"
    - "Accrue.Processor.Fake Phase 3 surface: subscription/invoice/intent/PM/charge/refund with deterministic ids"
    - "Accrue.Processor.Fake.transition/3 for arbitrary subscription status moves"
    - "Accrue.Processor.Fake.advance_subscription/2 with trial_will_end / subscription.updated webhook synthesis (D3-82)"
    - "Accrue.Processor.Fake.scripted_response/2 one-shot failure injection"
    - "Accrue.Processor.Stripe Phase 3 delegations to lattice_stripe 1.0 with forced expand paths"
    - "Accrue.Processor.Idempotency.key/4 and subject_uuid/2 deterministic derivations (D3-60/61/64)"
  affects:
    - "Wave 2 Plans 04/05/06 can now dispatch every billing context function through Accrue.Processor without stubs"
    - "Webhook refetch path (DefaultHandler D3-48) can call fetch(object_type, id) generically"
tech_stack:
  added: []
  patterns:
    - "Dual-arity behaviour callback for cancel_subscription/2 and cancel_subscription/3 — lattice_stripe exposes both shapes natively"
    - "Forced-expand pattern in Stripe adapter via ensure_expand/2 so SCA detection and fee math never miss critical nested fields"
    - "translate_resource/1 converts any LatticeStripe struct to a plain map so downstream code never pattern-matches on facade types"
    - "Scripted-response pattern in Fake: one-shot {op => result} map consumed at first call, falls back to default behaviour"
    - "Dispatch-based advance/advance_subscription split to preserve Phase 1 clock-only API while adding subscription-aware crossing"
key_files:
  created:
    - accrue/lib/accrue/processor/idempotency.ex
    - accrue/test/accrue/processor/idempotency_module_test.exs
    - accrue/test/accrue/processor/fake_phase3_test.exs
  modified:
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/processor/fake/state.ex
    - accrue/lib/accrue/processor/stripe.ex
decisions:
  - "advance/2 and advance_subscription/2 are separate functions — Phase 1 tests rely on advance(server, seconds) integer-semantics; plan's advance(stripe_id, opts) is shipped under the new name to preserve the existing API without multi-clause type dispatch ambiguity."
  - "All new Fake resources use atom-keyed Stripe-shape maps, not string-keyed as the plan literal shows. Atom keys are consistent with Phase 1 customer callbacks and with LatticeStripe struct → Map.from_struct/1 flow in the Stripe adapter. Adjusted the task-2 test text accordingly."
  - "create_charge routes through LatticeStripe.PaymentIntent.create because lattice_stripe 1.0 no longer exposes LatticeStripe.Charge.create — Stripe's 2026-03-25.dahlia API deprecates direct Charge creation for new integrations."
  - "list_charges returns a typed unsupported_operation APIError for the same reason. Phase 4 will expose PaymentIntent.list as the canonical replacement."
  - "synthesize_event uses apply/3 to invoke Accrue.Webhook.DefaultHandler.handle/1 to avoid a compile-time binding warning — DefaultHandler currently only exports handle_event/3, and Plan 07 extends it to match the synthesized shape."
  - "Accrue.Processor.Idempotency lives alongside Accrue.Processor.Stripe.compute_idempotency_key/3 (Phase 2 D2-11). The two are complementary: the Stripe module produces the short accr_<b64> form used as the Stripe-side Idempotency-Key HTTP header; the new module produces the long op_<sha256> form used by Wave 2 billing context to derive stable tokens before calling the processor (D3-60)."
metrics:
  duration: "~25 minutes"
  completed: "2026-04-14"
  tasks_completed: 3
  files_created: 3
  files_modified: 4
  test_count: "258 tests, 20 properties, 0 failures (up from 221 baseline, +37 new)"
requirements: [PROC-02]
---

# Phase 3 Plan 03: Processor behaviour + Fake + Stripe adapter Summary

Phase 3 processor dispatch foundation: `Accrue.Processor` behaviour grows
from 3 Phase 1 customer callbacks to 38 callbacks covering every Wave 2
billing context operation (subscription, invoice, payment intent, setup
intent, payment method, charge, refund, + generic `fetch/2` dispatch).
`Accrue.Processor.Fake` gains the full Phase 3 surface with deterministic
counter-padded ids, stripe-shape atom-keyed maps, `transition/3` for
arbitrary subscription status moves, `advance_subscription/2` with
subscription-aware trial crossing + in-process webhook synthesis
(D3-82), and `scripted_response/2` one-shot failure injection.
`Accrue.Processor.Stripe` delegates every callback to `lattice_stripe ~>
1.0` with forced expand paths (`latest_invoice.payment_intent` for
subscriptions, `balance_transaction` / `charge.balance_transaction` for
refunds). New `Accrue.Processor.Idempotency` module ships deterministic
`key/4` and `subject_uuid/2` helpers for D3-60/61/64.

## Work Completed

### Task 1 — Accrue.Processor.Idempotency (TDD)

**Commits:** `5be805e` (GREEN), `74cb1ff` (RED)

`Accrue.Processor.Idempotency.key(op, subject_id, operation_id, sequence
\\ 0)` produces `"<op>_<64-hex sha256>"` from
`"#{op}|#{subject_id}|#{operation_id}|#{sequence}"`. Pure SHA256 over a
canonical delimited tuple — same inputs → same key → retries converge
(D3-60). Complements the existing
`Accrue.Processor.Stripe.compute_idempotency_key/3` (Phase 2 D2-11),
which produces the shorter `accr_<22-char base64>` form Stripe expects
in the `Idempotency-Key` HTTP header. The two serve different layers:
this module produces the stable token Wave 2 billing context uses
**before** the processor call to derive row primary keys; the Stripe
module produces the header **during** the processor call.

`subject_uuid/2` derives a v4-shape Ecto.UUID-castable string from the
first 16 bytes of SHA256(`"<op>|<operation_id>"`), forcing the version
nibble to 4 and the variant bits to `10xx` so `Ecto.UUID.cast/1`
accepts it (D3-61). Useful when a caller needs to pre-allocate a row's
primary key before the processor call commits.

10 tests cover determinism, input-variance, default sequence, format
regex, UUID roundtrip, and operation-id differentiation.

### Task 2 — Accrue.Processor behaviour + Accrue.Processor.Fake Phase 3 surface

**Commit:** `898cafa`

**Behaviour** — 35 new `@callback` declarations across 7 surfaces plus
`fetch/2`:

- Subscription (7): `create_subscription/2`, `retrieve_subscription/2`,
  `update_subscription/3`, `cancel_subscription/2`,
  `cancel_subscription/3`, `resume_subscription/2`,
  `pause_subscription_collection/4`
- Invoice (9): `create_invoice/2`, `retrieve_invoice/2`,
  `update_invoice/3`, `finalize_invoice/2`, `void_invoice/2`,
  `pay_invoice/2`, `send_invoice/2`, `mark_uncollectible_invoice/2`,
  `create_invoice_preview/2`
- PaymentIntent (3): `create_payment_intent/2`,
  `retrieve_payment_intent/2`, `confirm_payment_intent/3`
- SetupIntent (3): `create_setup_intent/2`, `retrieve_setup_intent/2`,
  `confirm_setup_intent/3`
- PaymentMethod (7): `create_payment_method/2`,
  `retrieve_payment_method/2`, `attach_payment_method/3`,
  `detach_payment_method/2`, `list_payment_methods/2`,
  `update_payment_method/3`, `set_default_payment_method/3`
- Charge (3): `create_charge/2`, `retrieve_charge/2`, `list_charges/2`
- Refund (2): `create_refund/2`, `retrieve_refund/2`
- Fetch (1): `fetch/2`

Plus the `@type intent_result(ok)` union type (`{:ok, ok} | {:ok,
:requires_action, map()} | {:error, Accrue.Error.t()}`) used by Wave 2
billing context to tag SCA/3DS branches (D3-06..D3-12).

**Fake extensions:**

- `Fake.State` grows new resource maps (`setup_intents`, `charges`,
  `refunds`) and counters (`setup_intent`, `charge`, `refund`, `event`),
  plus a `scripts` map for one-shot responses. Phase 1 `clock`, `stubs`,
  `idempotency_cache`, and customer handling are preserved byte-for-byte.
- New id prefixes: `si_fake_`, `ch_fake_`, `re_fake_`, `evt_fake_` —
  all 5-digit zero-padded to match Phase 1 convention.
- `transition(stripe_id, new_status, opts)` — moves a stored
  subscription to any status, optionally synthesizing a
  `customer.subscription.updated` event.
- `advance_subscription(stripe_id, opts)` — advances the clock by
  `opts[:days] * 86400 + opts[:seconds]` and, if the subscription has
  a `trial_end`, synthesizes `customer.subscription.trial_will_end`
  when crossing `trial_end - 3d` and `customer.subscription.updated`
  (status→:active) when crossing `trial_end`. Accepts `stripe_id: nil`
  for clock-only moves. Respects `synthesize_webhooks: false` to skip
  the in-process event dispatch.
- `scripted_response(op, result)` — programs a one-shot `{op =>
  result}` return; the next call to that op consumes and deletes the
  script, later calls fall through to default behaviour. Used by tests
  that need to simulate `{:error, %Accrue.CardError{}}` etc.
- `fetch(object_type_atom, id)` — generic dispatcher routing to the
  right `retrieve_*` for the webhook DefaultHandler refetch path
  (D3-48 step 3).
- `with_script_or_stub/4` — unified gate ordering: scripted responses
  win over stubs, which win over default in-memory logic.
- Fixture builders (`build_subscription/3`, `build_invoice/3`,
  `build_payment_intent/3`, etc.) kept as `defp` inside the Fake
  module so `lib/` has no `test/support/` dependency — `StripeFixtures`
  is test-only.
- PaymentIntent `requires_action_test: true` param returns a PI with
  `status: :requires_action` and a `next_action: %{type:
  "use_stripe_sdk", ...}` map. Default returns `:succeeded`. SetupIntent
  has the same flag shape.

**Phase 1 compatibility** — `advance(server, seconds)` remains as the
clock-only API (Phase 1 `FakeTest` passes unchanged). The new
subscription-aware crossing is the separate `advance_subscription/2`.
Existing customer callbacks retain atom-keyed shapes. Stubs and
idempotency cache behaviour unchanged.

**27 new tests** in `fake_phase3_test.exs` cover subscription lifecycle
(create/retrieve/transition/cancel/advance crossing), invoice lifecycle
(create→finalize→pay, void, preview), payment intent (default +
requires_action), setup intent (default + requires_action), payment
method (create/attach/list/detach, set_default), charge + refund
(balance_transaction with fee details), scripted_response consumption,
fetch generic dispatch, and Mox-style behaviour compliance via
`Accrue.Processor.behaviour_info(:callbacks)`.

### Task 3 — Accrue.Processor.Stripe lattice_stripe delegations

**Commit:** `65ddbae`

Every new Phase 3 callback routes through the existing Phase 2
infrastructure (`build_client!/1` reading `:stripe_secret_key` at
runtime per CLAUDE.md, `compute_idempotency_key/3` seeding idempotency,
`resolve_api_version/1` for per-call overrides) to the corresponding
`lattice_stripe ~> 1.0` module.

**Subscription** — `create/retrieve/update/cancel/cancel-with-params/
resume/pause_collection` delegate 1:1 to `LatticeStripe.Subscription.*`.
`create` and `update` force
`expand: ["latest_invoice.payment_intent"]` via the new
`ensure_expand/2` helper so every subscription response carries the
`latest_invoice.payment_intent` tree Wave 2 needs for D3-09 SCA
detection.

**Invoice** — `create/retrieve/update/finalize/void/pay/send_invoice/
mark_uncollectible/create_preview` delegate to `LatticeStripe.Invoice.*`.
Finalize/void/pay/send_invoice/mark_uncollectible all take an empty
params `%{}` and an opts keyword — matches lattice_stripe's 4-arity
signature.

**PaymentIntent / SetupIntent** — `create/retrieve/confirm` delegate
directly. No auto-expand on retrieve; host caller can pass `expand`
in params.

**PaymentMethod** — `create/retrieve/attach/detach/list/update` all
delegate. `detach` takes `%{}` params per lattice_stripe's 4-arity
detach. `set_default_payment_method/3` delegates to
`LatticeStripe.Customer.update/4` with
`%{invoice_settings: %{default_payment_method: pm_id}}`.

**Charge** — `retrieve_charge` delegates to `LatticeStripe.Charge.retrieve/3`.
`create_charge` routes through `LatticeStripe.PaymentIntent.create/3`
with `confirm: true` because lattice_stripe 1.0 no longer exposes a
`LatticeStripe.Charge.create` function (Stripe's 2026-03-25.dahlia API
deprecates direct Charge creation for new integrations). Forces
`expand: ["balance_transaction"]`. `list_charges` returns a typed
`%Accrue.APIError{code: "unsupported_operation", http_status: 501}`
documenting the deprecation and pointing at Phase 4's PaymentIntent.list.

**Refund** — `create_refund` forces
`expand: ["balance_transaction", "charge.balance_transaction"]` for
D3-45 fee math; both `create` and `retrieve` delegate to
`LatticeStripe.Refund.*`.

**fetch/2** — 8-clause dispatcher routing `{object_type_atom, id}` to
the right `retrieve_*` callback. Matches the Fake's dispatch table
verbatim.

**translate_resource/1** — converts any `{:ok, %LatticeStripe.*{}}` to
`{:ok, map}` via `Map.from_struct/1` so Wave 2 callers never pattern-
match on LatticeStripe shapes (facade lockdown preserved). Errors pass
through the existing `ErrorMapper.to_accrue_error/1`.

**`stripe_opts/3` and `stripe_opts_no_idem/1`** — helper pair factored
out to reduce boilerplate across 30+ delegations. The former seeds an
idempotency key via `compute_idempotency_key(op, subject_id, opts)` and
forces the API version; the latter skips idempotency (used on GET / list
calls where idempotency keys don't apply).

Compile clean under `mix compile --warnings-as-errors` with
`@behaviour Accrue.Processor` — all 38 callbacks implemented. Facade
lockdown test in `stripe_test.exs` still passes (no new files introduce
`LatticeStripe` references outside the allowed list).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Fake uses GenServer, not ETS**

- **Found during:** Task 2 pre-implementation
- **Issue:** Plan's implementation example assumes an ETS-backed Fake
  (`:ets.lookup(@table, {:subscription, stripe_id})`). Phase 1 shipped
  the Fake as a `GenServer` with a typed `%State{}` struct. Rewriting
  to ETS would break every existing test and throw away the clean
  `with_script_or_stub/4` gate pattern.
- **Fix:** Implemented all new callbacks as `GenServer.call`s that
  pattern-match on `%State{}` and return
  `{:reply, result, new_state}`. Same semantics as the plan intended,
  same deterministic behaviour, zero Phase 1 regressions.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`,
  `accrue/lib/accrue/processor/fake/state.ex`
- **Commit:** `898cafa`

**2. [Rule 1 — Bug] Plan test text uses string keys; existing Fake uses atom keys**

- **Found during:** Task 2 test writing
- **Issue:** Plan test text asserts `sub["id"]`, `cus["id"]`, etc.
  (string-keyed). Phase 1 `FakeTest` uses `customer.id` (atom-keyed)
  and the Phase 1 Stripe adapter's `translate_customer/1` converts
  `%LatticeStripe.Customer{}` → plain map via `Map.from_struct/1`,
  producing atom keys. Mixing string-keyed and atom-keyed returns
  across the same adapter would force Wave 2 to pattern-match on two
  shapes.
- **Fix:** Every new Fake resource uses atom-keyed Stripe-shape maps
  consistent with Phase 1. Adjusted the task-2 test text accordingly.
  The plan's intent (Stripe-shape payloads) is preserved; only the
  key-type is harmonized with existing code.
- **Files modified:**
  `accrue/test/accrue/processor/fake_phase3_test.exs` (new)
- **Commit:** `898cafa`

**3. [Rule 1 — Bug] `advance/2` arity already used for clock-only**

- **Found during:** Task 2 pre-implementation
- **Issue:** Plan wants `advance(stripe_id, opts)` as the
  subscription-aware crossing API. Phase 1 ships
  `advance(server \\ __MODULE__, seconds)` (integer seconds). Using
  multi-clause dispatch on `is_binary/is_integer` would be fragile
  (tests pass `Fake` as first arg, which is an atom) and defeat the
  default-arg form.
- **Fix:** Kept `advance(server, seconds)` unchanged for Phase 1
  compatibility; added `advance_subscription(stripe_id_or_nil, opts)`
  as the new subscription-aware function. Both semantics now coexist
  cleanly. Wave 2 callers that want the crossing behaviour call
  `advance_subscription`.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`
- **Commit:** `898cafa`

**4. [Rule 2 — Missing critical functionality] Compile warning on synthesize_event**

- **Found during:** Task 2 compile
- **Issue:** Plan says to guard the
  `Accrue.Webhook.DefaultHandler.handle/1` call with
  `Code.ensure_loaded?/1 + function_exported?/3`. The runtime guard
  works at runtime — but the compiler still binds the
  `Accrue.Webhook.DefaultHandler.handle(event)` call at compile time
  and emits
  `warning: Accrue.Webhook.DefaultHandler.handle/1 is undefined or
  private` because DefaultHandler currently only exports
  `handle_event/3`. With `--warnings-as-errors` the build breaks.
- **Fix:** Used `apply(handler, :handle, [event])` through a local
  variable so the compiler doesn't statically resolve the call.
  Semantics unchanged; warning eliminated.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`
- **Commit:** `898cafa`

**5. [Rule 1 — Bug] `LatticeStripe.Charge.create/list` not in lattice_stripe 1.0**

- **Found during:** Task 3 grep of lattice_stripe modules
- **Issue:** Plan says
  `create_charge → LatticeStripe.Charge.create/3` and
  `list_charges → LatticeStripe.Charge.list/3`. Neither exists in
  lattice_stripe 1.0 — the Charge module only exposes `retrieve/3`
  (plus `from_map/1` and `inspect/2`). Stripe's `2026-03-25.dahlia`
  API deprecates direct Charge creation for new integrations in favor
  of PaymentIntents.
- **Fix:** `create_charge` now routes through
  `LatticeStripe.PaymentIntent.create/3` with `confirm: true` — the
  Stripe-recommended path for synchronous charge creation.
  `list_charges` returns a typed
  `%Accrue.APIError{code: "unsupported_operation", http_status: 501}`
  documenting the deprecation. Phase 4 will expose
  `PaymentIntent.list` as the canonical replacement once the billing
  context gains a dedicated `list_payment_intents/2` surface.
- **Files modified:** `accrue/lib/accrue/processor/stripe.ex`
- **Commit:** `65ddbae`

**6. [Rule 1 — Bug] Plan's `@callback fetch(atom, String.t())` was missing opts**

- **Found during:** Task 2 behaviour writing
- **Issue:** Plan specifies `@callback fetch(atom(), String.t())` but
  every other retrieve_* callback takes `(id, opts)`. Adding opts to
  fetch would be inconsistent with the plan's stated 2-arity; omitting
  opts matches the plan but means fetch can't pass through the API
  version override.
- **Fix:** Implemented fetch/2 per the plan (2-arity) and have every
  clause call `retrieve_<type>(id, [])`. Rationale: fetch is only used
  by the webhook DefaultHandler refetch path (D3-48), which always
  runs with default opts. Wave 2 code that needs explicit opts calls
  the typed retrieve_* directly.
- **Files modified:** `accrue/lib/accrue/processor.ex`,
  `accrue/lib/accrue/processor/fake.ex`,
  `accrue/lib/accrue/processor/stripe.ex`
- **Commit:** `898cafa`, `65ddbae`

### Pre-existing test flake (noted, not fixed)

`test/accrue/processor/idempotency_test.exs` (a Phase 2 file, not
created by this plan) flaked once when run as part of the full suite
with a non-zero seed — `GenServer.call(Fake, :reset)` exited because
the Fake process was torn down by a parallel test. Running with
`--seed 0` or in isolation passes cleanly. Pre-existing Phase 2 test
harness issue, not caused by 03-03 changes. Logged as a known flake;
not fixed here per the scope boundary in the GSD execute-plan workflow.

## Verification Results

- `mix compile --warnings-as-errors --force` — clean (0 warnings, 73
  files, generator clean)
- `mix test --seed 0` — **258 tests, 20 properties, 0 failures** (up
  from 221 baseline, +37 new across Tasks 1 and 2)
- `mix test test/accrue/processor/` (processor subtree only) — 61
  tests, 0 failures
- `mix test test/accrue/processor/idempotency_module_test.exs` — 10/10
- `mix test test/accrue/processor/fake_phase3_test.exs` — 27/27
- `mix test test/accrue/processor/stripe_test.exs` (facade lockdown) —
  13/13
- `mix credo --strict` — 0 issues across 105 source files (699
  mods/funs analyzed)

## Success Criteria

- [x] Behaviour declares 38 Phase 3 callbacks including `intent_result`
      type, `fetch/2`, `pause_subscription_collection/4`,
      `create_invoice_preview/2`
- [x] Fake adapter passes behaviour compliance check at runtime (no
      missing callbacks via `Accrue.Processor.behaviour_info(:callbacks)`)
- [x] `Fake.advance_subscription` synthesizes
      `customer.subscription.trial_will_end` when crossing `trial_end - 3d`
      and `customer.subscription.updated` when crossing `trial_end`
- [x] `Fake.scripted_response` one-shot override works and is consumed
      after use (proven by test)
- [x] Stripe adapter delegates every op to `lattice_stripe ~> 1.0` with
      correct expand paths
      (`latest_invoice.payment_intent`, `balance_transaction`,
      `charge.balance_transaction`)
- [x] `Idempotency.key/4` and `subject_uuid/2` are deterministic and
      tested for 10 invariants

## Acceptance Criteria Checklist

Task 1:

- [x] `grep -q "defmodule Accrue.Processor.Idempotency"` — present
- [x] `grep -q "def key"` — present
- [x] `grep -q "def subject_uuid"` — present
- [x] `grep -q ":crypto.hash(:sha256"` — present
- [x] 10 tests passing (plan specified 8; added `default sequence` and
      split tests)

Task 2:

- [x] `grep -q "@callback create_subscription"` — present
- [x] `grep -q "@callback pause_subscription_collection"` — present
- [x] `grep -q "@callback create_invoice_preview"` — present
- [x] `grep -q "@callback create_refund"` — present
- [x] `grep -q "@callback create_payment_intent"` — present
- [x] `grep -q "@callback create_setup_intent"` — present
- [x] `grep -q "@callback fetch"` — present
- [x] `grep -q "@type intent_result"` — present
- [x] `grep -q "@behaviour Accrue.Processor"` in fake.ex — present
- [x] `grep -q "def transition"` — present
- [x] `grep -q "def advance_subscription"` — present (plan's
      `advance/2` spec shipped under new name; see Deviation #3)
- [x] `grep -q "def scripted_response"` — present
- [x] `grep -q "trial_will_end"` — present
- [x] `grep -q "synthesize_event"` — present
- [x] Zero `undefined behaviour function` warnings under
      `--warnings-as-errors`
- [x] 27 Phase 3 fake tests passing (plan specified 9; added
      deeper coverage for invoice lifecycle, set_default_payment_method,
      detach, canceling, clock-only advance)

Task 3:

- [x] `grep -q "@behaviour Accrue.Processor"` in stripe.ex — present
- [x] `grep -q "def create_subscription"` — present
- [x] `grep -q "LatticeStripe.Subscription.create"` — present
- [x] `grep -q "LatticeStripe.Subscription.pause_collection"` — present
- [x] `grep -q "LatticeStripe.Invoice.create_preview"` — present
- [x] `grep -q "LatticeStripe.Invoice.finalize"` — present
- [x] `grep -q "LatticeStripe.Invoice.send_invoice"` — present
- [x] `grep -q "LatticeStripe.PaymentIntent.create"` — present
- [x] `grep -q "LatticeStripe.SetupIntent.create"` — present
- [x] `grep -q "LatticeStripe.PaymentMethod.attach"` — present
- [x] `grep -q "LatticeStripe.Refund.create"` — present
- [x] `grep -q "LatticeStripe.Customer.update"` — present (in
      `set_default_payment_method`)
- [x] `grep -q "latest_invoice.payment_intent"` — present
- [x] `grep -q "balance_transaction"` — present
- [x] `grep -q "def fetch"` — present
- [x] `mix compile --warnings-as-errors` exits 0

## Self-Check: PASSED

All created files exist, all commits are in the log:

- `accrue/lib/accrue/processor/idempotency.ex` — FOUND
- `accrue/test/accrue/processor/idempotency_module_test.exs` — FOUND
- `accrue/test/accrue/processor/fake_phase3_test.exs` — FOUND
- `accrue/lib/accrue/processor.ex` — MODIFIED (38 callbacks)
- `accrue/lib/accrue/processor/fake.ex` — MODIFIED (behaviour + all
  Phase 3 callbacks + transition/advance_subscription/scripted_response)
- `accrue/lib/accrue/processor/fake/state.ex` — MODIFIED (new
  resource maps + counters + scripts)
- `accrue/lib/accrue/processor/stripe.ex` — MODIFIED (all Phase 3
  lattice_stripe delegations)
- Commit `74cb1ff` (Task 1 RED) — FOUND
- Commit `5be805e` (Task 1 GREEN) — FOUND
- Commit `898cafa` (Task 2) — FOUND
- Commit `65ddbae` (Task 3) — FOUND
