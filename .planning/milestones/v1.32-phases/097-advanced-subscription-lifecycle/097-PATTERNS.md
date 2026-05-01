# Phase 97: advanced-subscription-lifecycle - Pattern Map

**Mapped:** 2026-04-30  
**Files analyzed:** 14  
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/processor/braintree.ex` | service | request-response | `accrue/lib/accrue/processor/stripe.ex` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | transactional CRUD | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue/lib/accrue/billing/subscription_projection.ex` | utility | transform | `accrue/lib/accrue/billing/subscription_projection.ex` | exact |
| `accrue/lib/accrue/billing/invoice_projection.ex` | utility | transform | `accrue/lib/accrue/billing/invoice_projection.ex` | exact |
| `accrue/lib/accrue/webhook/default_handler.ex` | service | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `accrue/test/accrue/processor/braintree_test.exs` | test | request-response | `accrue/test/accrue/processor/braintree_test.exs` | exact |
| `accrue/test/accrue/processor/capabilities_test.exs` | test | transform | `accrue/test/accrue/processor/capabilities_test.exs` | exact |
| `accrue/test/accrue/billing/subscription_actions_test.exs` | test | transactional CRUD | `accrue/test/accrue/billing/subscription_actions_test.exs` | exact |
| `accrue/test/accrue/billing/subscription_projection_provider_test.exs` | test | transform | `accrue/test/accrue/billing/subscription_projection_provider_test.exs` | exact |
| `accrue/test/accrue/webhook/default_handler_test.exs` | test | event-driven | `accrue/test/accrue/webhook/default_handler_test.exs` | exact |
| `accrue/test/accrue/webhook/default_handler_phase3_test.exs` | test | event-driven | `accrue/test/accrue/webhook/default_handler_phase3_test.exs` | exact |
| `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` | test | host proof | `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` | exact |
| `.planning/processor-support-matrix.md` | docs/config | transform | `.planning/processor-support-matrix.md` | exact |

## Pattern Assignments

### `accrue/lib/accrue/processor/braintree.ex`

**Analog:** `accrue/lib/accrue/processor/stripe.ex`

Reuse the same adapter shape:

- `processor_name/0`
- `capabilities/0`
- `create_*`, `retrieve_*`, `update_*`, `cancel_*`, `pause_*`, `resume_*` callbacks
- private request translation helpers
- provider error translation

Keep all provider-SDK knowledge inside this module.

### `accrue/lib/accrue/billing/subscription_actions.ex`

**Analog:** self

Reuse the existing transactional pattern:

1. validate public options;
2. compute idempotency key;
3. call `Processor.__impl__()` callback;
4. decompose projection;
5. update local row and items;
6. append `accrue_events`;
7. preload and return.

Phase 97 should branch only at request/semantic seams, not at the public API boundary.

### `accrue/lib/accrue/billing/subscription_projection.ex`

**Analog:** self

Continue using a provider branch per processor:

- `:stripe`
- `:paddle`
- `:braintree`

Add explicit Braintree lifecycle-field parsing here instead of leaking provider-specific projection logic into reducers or billing actions.

### `accrue/lib/accrue/webhook/default_handler.ex`

**Analog:** self

Reuse the existing reducer contract:

- normalize external event type;
- derive canonical local event family;
- refetch canonical object via `Processor.fetch/2`;
- project into local billing tables;
- record telemetry and event rows.

Avoid creating a second Braintree-only reducer tree.

### Focused test files

Use the existing pattern of:

- adapter-specific unit tests in `processor/*_test.exs`;
- billing-contract tests in `billing/*_test.exs`;
- shared reducer tests in `webhook/*_test.exs`;
- host/provider proof in `examples/accrue_host/test/accrue_host/*`.

## Concrete Read-First Anchors

These are the highest-signal analogs executors should read before Phase 97 implementation:

- `accrue/lib/accrue/processor/stripe.ex`
- `accrue/lib/accrue/processor/fake.ex`
- `accrue/lib/accrue/processor/braintree.ex`
- `accrue/lib/accrue/billing/subscription_actions.ex`
- `accrue/lib/accrue/billing/subscription_projection.ex`
- `accrue/lib/accrue/webhook/default_handler.ex`
- `accrue/test/accrue/processor/braintree_test.exs`
- `accrue/test/accrue/billing/subscription_actions_test.exs`
- `accrue/test/accrue/webhook/default_handler_test.exs`

## Phase-Specific Guidance

- Treat `Stripe` as the implementation analog for mutation callback shape, not for identical semantics.
- Treat `Fake` as the regression/proof analog for supported lifecycle behavior.
- Treat existing Braintree tests and webhook normalization as the starting point, not as finished parity work.
- Any new Braintree mutation capability must be mirrored in tests and support wording the same day it lands.
