---
phase: 04-advanced-billing-webhook-hardening
plan: 07
subsystem: checkout-customer-portal
tags: [wave-7, chkt-01, chkt-02, chkt-03, chkt-04, chkt-05, chkt-06, checkout, billing-portal, inspect-mask]
dependency_graph:
  requires:
    - "04-01 (config + processor behaviour scaffolding)"
    - "Phase 2 D2-29 (processor canonical, refetch-then-mirror)"
    - "Phase 2 D2-30 (DefaultHandler dispatch chain non-disableable)"
    - "Phase 3 D3-17 (force_status_changeset on webhook path)"
    - "Phase 3 :deferred orphan tolerance pattern (Pattern §H)"
  provides:
    - "Accrue.Checkout context with create_session/1, retrieve_session/1, reconcile/1"
    - "Accrue.Checkout.Session struct (hosted + embedded ui_modes) with Inspect mask on :client_secret"
    - "Accrue.Checkout.LineItem.from_price/2 + from_price_data/1 helpers"
    - "Accrue.BillingPortal context with create_session/1 (+ bang variant)"
    - "Accrue.BillingPortal.Session struct with Inspect mask on bearer-credential :url"
    - "Processor callbacks: checkout_session_create/2, checkout_session_fetch/2, portal_session_create/2"
    - "DefaultHandler reduce_checkout_session for checkout.session.{completed,expired,async_payment_*}"
    - "guides/portal_configuration_checklist.md install-time gate (CHKT-05)"
  affects:
    - "Host apps gain a 1-call subscription/payment/setup checkout flow"
    - "Phase 7 admin LV can render checkout sessions + portal session history"
    - "Future BillingPortal.Configuration support is additive (drops in via :configuration param)"
tech_stack:
  added: []
  patterns:
    - "Single-context-with-struct (no ecto schema yet) — Checkout.Session and BillingPortal.Session are pure data wrappers around processor responses; no local table is required for v1.0 because every state mutation flows through the standard webhook reducer path"
    - "Inspect mask via defimpl Inspect → field allowlist (Phase 2 WebhookEvent.raw_body precedent) — chosen over Map.from_struct + redaction because algebra concat does not accept nested struct docs"
    - "NimbleOptions schema with explicit operation_id passthrough so callers using Accrue.Actor.put_operation_id/1 propagate to processor idempotency keys"
    - "reconcile/1 inside Repo.transact, Stripe call OUTSIDE — D2-09 hygiene; the processor.fetch leg is read-only so the order is the same as Phase 3 webhook reducers"
    - "checkout.session.completed reducer uses :deferred orphan tolerance for unknown customer (Pattern §H) — webhook may arrive before customer.created lands"
    - "Subscription mirroring inside checkout.session.completed delegates to Subscription.force_status_changeset/2 + SubscriptionProjection.decompose/1 — same path the customer.subscription.* reducer uses, no duplicate projection logic"
key_files:
  created:
    - "accrue/lib/accrue/checkout.ex"
    - "accrue/lib/accrue/checkout/session.ex"
    - "accrue/lib/accrue/checkout/line_item.ex"
    - "accrue/lib/accrue/billing_portal.ex"
    - "accrue/lib/accrue/billing_portal/session.ex"
    - "accrue/guides/portal_configuration_checklist.md"
    - "accrue/test/accrue/checkout_test.exs"
    - "accrue/test/accrue/billing_portal_test.exs"
    - "accrue/test/accrue/webhook/checkout_session_completed_test.exs"
  modified:
    - "accrue/lib/accrue/processor.ex (added @callback checkout_session_create/2, checkout_session_fetch/2, portal_session_create/2)"
    - "accrue/lib/accrue/processor/fake.ex (added @checkout_session_prefix, @billing_portal_session_prefix, callbacks + handle_call clauses, fetch dispatch for :checkout_session)"
    - "accrue/lib/accrue/processor/fake/state.ex (added :checkout_sessions, :billing_portal_sessions maps + :checkout_session/:billing_portal_session counters)"
    - "accrue/lib/accrue/processor/stripe.ex (added Stripe Checkout + Customer Portal delegations, fetch dispatch for :checkout_session)"
    - "accrue/lib/accrue/webhook/default_handler.ex (added checkout.session.* dispatch + reduce_checkout_session reducer with :deferred orphan tolerance)"
    - "accrue/test/support/stripe_fixtures.ex (added checkout_session_completed/1, checkout_session_expired/1, billing_portal_session/1)"
decisions:
  - "Did NOT introduce a local accrue_checkout_sessions or accrue_billing_portal_sessions table — both Stripe objects are short-lived bearer credentials; persisting them adds zero correctness value and creates new PII surface. The one piece of state that matters (the linked subscription) flows through the existing customer.subscription.* projection path."
  - "reduce_checkout_session links the subscription via Processor.fetch(:subscription, sub_id) → Subscription.force_status_changeset/2 inside the same Repo.transact as the event recording — refetches canonical state per D2-29 instead of trusting the webhook payload."
  - "Used field-allowlist Inspect impls (not Map.from_struct + replace) because Inspect.Algebra.concat/2 rejects nested struct docs — same shape as LatticeStripe.Checkout.Session and LatticeStripe.BillingPortal.Session use upstream."
  - "BillingPortal.Configuration support is documented as a Stripe Dashboard install-time gate (guides/portal_configuration_checklist.md) per D4-01 footnote. The :configuration option already accepts bpc_* ids so future programmatic Configuration support is additive."
  - "Customer-or-string accepted on both Checkout.Session.create/1 and BillingPortal.Session.create/1 so host apps can use either an %Accrue.Billing.Customer{} struct or a raw cus_* id without a customer fetch."
  - "from_price_data/1 stringifies all keys but hoists :quantity to the top level (Stripe expects quantity outside price_data)."
metrics:
  duration: "~8m"
  completed_date: "2026-04-15"
  tasks_completed: 2
  tests_added: 21
  files_created: 9
  files_modified: 6
---

# Phase 04 Plan 07: Checkout + Customer Portal Summary

## One-Liner

Day-one Stripe Checkout (`Accrue.Checkout`) and Customer Portal
(`Accrue.BillingPortal`) wrappers with hosted/embedded mode support,
line-item helpers, success-URL state reconciliation via
`Accrue.Checkout.reconcile/1`, `checkout.session.completed` webhook
linking with `:deferred` orphan tolerance, Inspect masking on the
embedded `client_secret` and the portal bearer URL, and an install-time
Stripe Dashboard checklist that defends against the
"cancel-without-dunning" footgun — closing CHKT-01 through CHKT-06.

## What Was Built

### 1. `Accrue.Checkout` context (CHKT-01/02/03/06)

- `Accrue.Checkout.Session.create/1` — single function for both
  hosted and embedded modes, defaulted to `:subscription` + `:hosted`.
  Returns `{:ok, %Session{}}` with `:url` populated for hosted and
  `:client_secret` for embedded.
- `Accrue.Checkout.Session.retrieve/1` — by-id refetch through
  `Processor.checkout_session_fetch/2`.
- `Accrue.Checkout.LineItem.from_price/2` and `from_price_data/1` —
  stateless constructors for the `line_items` array. `from_price_data/1`
  stringifies keys and hoists `:quantity` to the top level.
- `Accrue.Checkout.reconcile/1` — host success-URL controllers call
  this with the `cs_*` id from the redirect URL. Refetches the session
  from the processor, then mirrors any linked subscription into local
  rows via `Subscription.force_status_changeset/2`. Idempotent.

`Accrue.Checkout.Session` is a struct, not an Ecto schema — there is
no local `accrue_checkout_sessions` table because the Stripe object
is a short-lived bearer credential. The state that matters (the
linked subscription) flows through the standard webhook projection
path.

### 2. `Accrue.BillingPortal` context (CHKT-04/05)

- `Accrue.BillingPortal.Session.create/1` — wraps the processor's
  `portal_session_create/2`. Accepts a `%Customer{}` or a raw
  `cus_*` id, plus optional `:return_url`, `:configuration` (the
  `bpc_*` Dashboard configuration id), `:flow_data`, `:locale`, and
  `:on_behalf_of`.
- `Accrue.BillingPortal.create_session/1` — facade module delegating
  to `Session.create/1`.
- `defimpl Inspect, for: Accrue.BillingPortal.Session` — masks the
  bearer-credential `:url` field as `"<redacted>"`. Mirrors the
  upstream processor struct's Inspect mask but at Accrue's wrapper
  layer too, defense-in-depth.

### 3. Webhook handler — `checkout.session.completed` (CHKT-06)

`Accrue.Webhook.DefaultHandler.reduce_checkout_session/4`:

- Wires up `dispatch("checkout.session." <> action, ...)` for
  `completed`, `expired`, `async_payment_succeeded`, and
  `async_payment_failed`.
- On `completed`: looks up the local customer by `processor_id`, then
  refetches the linked subscription via `Processor.fetch(:subscription, sub_id)`,
  decomposes via `SubscriptionProjection.decompose/1`, and upserts via
  `Subscription.force_status_changeset/2` inside `Repo.transact/2`.
- Records an `accrue_events` row `checkout.session.completed`.
- Returns `{:ok, :deferred}` and emits
  `[:accrue, :webhooks, :orphan_checkout_session]` telemetry when the
  customer or subscription isn't yet projected locally — webhook can
  arrive before `customer.created` (Pattern §H, T-04-07-05).

### 4. Inspect masks (T-04-07-01, T-04-07-08)

- `Accrue.Checkout.Session` — masks `:client_secret` (embedded-mode
  bearer credential).
- `Accrue.BillingPortal.Session` — masks `:url` (portal bearer
  credential).
- Both impls use field-allowlist `concat` (not `Inspect.Map.inspect`)
  because Inspect.Algebra rejects nested struct docs in `concat/2`.

### 5. Processor behaviour additions

```elixir
@callback checkout_session_create(params(), opts()) :: result()
@callback checkout_session_fetch(id(), opts()) :: result()
@callback portal_session_create(params(), opts()) :: result()
```

- **Fake adapter** (`Accrue.Processor.Fake`): in-memory state with
  deterministic `cs_fake_NNNNN` and `bps_fake_NNNNN` ids. Hosted
  sessions populate `:url`; embedded sessions populate
  `:client_secret`. Round-trip via `checkout_session_fetch/2` and
  `fetch(:checkout_session, id)`.
- **Stripe adapter** (`Accrue.Processor.Stripe`): delegates to
  `LatticeStripe.Checkout.Session.create/3` /
  `LatticeStripe.Checkout.Session.retrieve/3` /
  `LatticeStripe.BillingPortal.Session.create/3` with the standard
  `stripe_opts` idempotency-key wiring.

### 6. `guides/portal_configuration_checklist.md` (CHKT-05)

Install-time install gate documenting the three Stripe Dashboard
toggles every host must enable on its Customer Portal configuration:

1. **Retain offers — ENABLED** (Cancellations → Retain offers)
2. **Require cancellation reason — ENABLED** (Cancellations →
   Cancellation reason)
3. **Cancellation timing = `at_period_end`** (Cancellations → When
   to cancel — NOT "Immediately")

Plus a worked `:configuration` `bpc_*` example showing how to pin
production sessions to a specific Dashboard configuration so a future
Dashboard edit can't silently reset the toggles.

## Verification Results

```
mix compile --warnings-as-errors                                       → clean
mix test test/accrue/checkout_test.exs                                 → 15/15 pass
mix test test/accrue/webhook/checkout_session_completed_test.exs       → 3/3  pass
mix test test/accrue/billing_portal_test.exs                           → 6/6  pass
mix test                                                               → 545 tests, 36 properties, 0 failures (2 excluded)
mix credo --strict                                                     → 1417 mods/funs, 0 issues
```

Net additions: +21 tests (524 → 545).

## Commits

| Hash      | Message                                                                                                  |
| --------- | -------------------------------------------------------------------------------------------------------- |
| `8a2a70e` | test(04-07): add failing tests for Accrue.Checkout context + webhook handler                             |
| `5f93617` | feat(04-07): Accrue.Checkout context with hosted/embedded sessions, reconcile/1, webhook handler         |
| `ba3f26e` | test(04-07): add failing tests for Accrue.BillingPortal session wrapper                                  |
| `4d92310` | feat(04-07): Accrue.BillingPortal session wrapper + portal config checklist guide                        |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] NimbleOptions `{:list, :map}` rejected string-keyed line items**
- **Found during:** Task 1 first GREEN run
- **Issue:** Plan's example schema used `line_items: [type: {:list, :map}, default: []]`. NimbleOptions' `:map` constraint requires atom keys, but `LineItem.from_price/2` returns string-keyed maps (Stripe wire format), so `Session.create/1` raised `NimbleOptions.ValidationError: invalid value for map key: expected atom, got: "price"`.
- **Fix:** Loosened to `{:list, {:map, :any, :any}}` so any map shape is accepted. Stripe still validates server-side.
- **Files modified:** `accrue/lib/accrue/checkout/session.ex`

**2. [Rule 1 - Bug] `defimpl Inspect` using `Inspect.Map.inspect/2` failed `concat/2` type check**
- **Found during:** Task 1 first GREEN run on the Inspect mask test
- **Issue:** Initial impl wrapped `Inspect.Map.inspect(Map.from_struct(sanitized), opts)` inside `concat([...])`, but `Inspect.Map.inspect/2` returns a `doc_group` algebra node that `Inspect.Algebra.concat/2` rejects with `FunctionClauseError`.
- **Fix:** Switched to a field-allowlist Inspect impl matching the upstream `LatticeStripe.Checkout.Session` and `LatticeStripe.BillingPortal.Session` shapes — explicit `[id: ..., status: ..., ...]` keyword + `to_doc(v, opts)` per pair, joined with intersperse. Same pattern for both `Accrue.Checkout.Session` and `Accrue.BillingPortal.Session`.
- **Files modified:** `accrue/lib/accrue/checkout/session.ex`, `accrue/lib/accrue/billing_portal/session.ex`

**3. [Rule 1 - Bug] Compiler "clause will never match" warning on `SubscriptionProjection.decompose/1`**
- **Found during:** Task 1 `mix compile`
- **Issue:** `link_subscription_to_customer/3` had a `case SubscriptionProjection.decompose(canonical) do {:ok, attrs} -> ... ; {:error, _} = err -> err end` shape, but the projection function's static type is `dynamic({:ok, ...})` — never errors. With `--warnings-as-errors` the dead clause stops the build.
- **Fix:** Replaced with `{:ok, attrs} = SubscriptionProjection.decompose(canonical)`. Matches how `reduce_subscription/4` already handles the same call.
- **Files modified:** `accrue/lib/accrue/webhook/default_handler.ex`

### Authentication Gates

None — Task 1 and Task 2 are pure library work with no external auth.

## Threat Flags

None new beyond the plan's `<threat_model>`. Both Inspect masks
(T-04-07-01 portal `:url`, T-04-07-08 checkout `:client_secret`) are
implemented and verified by runtime tests. The CHKT-05 install-time
checklist (T-04-07-03 mitigation) is in place and tested for
existence + content.

## Self-Check: PASSED

Verified files exist:

- `accrue/lib/accrue/checkout.ex` — FOUND
- `accrue/lib/accrue/checkout/session.ex` — FOUND
- `accrue/lib/accrue/checkout/line_item.ex` — FOUND
- `accrue/lib/accrue/billing_portal.ex` — FOUND
- `accrue/lib/accrue/billing_portal/session.ex` — FOUND
- `accrue/guides/portal_configuration_checklist.md` — FOUND
- `accrue/test/accrue/checkout_test.exs` — FOUND
- `accrue/test/accrue/billing_portal_test.exs` — FOUND
- `accrue/test/accrue/webhook/checkout_session_completed_test.exs` — FOUND

Commits verified in `git log`:

- `8a2a70e` — FOUND
- `5f93617` — FOUND
- `ba3f26e` — FOUND
- `4d92310` — FOUND

Test suite green: `mix test → 545 tests, 0 failures`.
Lint green: `mix credo --strict → 0 issues`.
Compile clean: `mix compile --warnings-as-errors → no warnings`.
