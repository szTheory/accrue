# Lifecycle Semantics

Accrue exposes one lifecycle facade, but the meaning stays provider-honest.
Use this guide as the lifecycle source of truth for docs, operator workflows,
and UI copy. API docs and provider-specific guides should point back here
instead of redefining actions or states independently.

## Action glossary

Active subscription changes should be described as the **official active-subscription-change**
contract centered on `swap_plan/3` plus `preview_upcoming_invoice/2`.

### `swap_plan/3`

Replace the current subscription price with a new `price_id` while keeping the
public lifecycle facade app-facing.

- Primary wording: `Swap plan` or `Change plan`
- Customer expectation: the host app still owns catalog copy and upgrade/downgrade
  framing; Accrue owns the billing mutation
- Provider labels:
  - Stripe: `native`
  - Braintree: `host-owned metadata + native mutation`
  - Fake: `testing/local-only`

For Braintree, `swap_plan/3` is first-party only within a bounded contract:
the host must configure `:plan_resolver` so Accrue can translate the app-facing
`price_id` into the target Braintree `plan_id`, amount, currency, and billing
cycle metadata. Keep quantity mutation, scheduled-end cancellation, pause, and
resume copy separate from plan-swap copy; Braintree does not gain those broader
lifecycle semantics through this path.

### `preview_upcoming_invoice/2`

Fetch a non-persistent invoice preview before committing a billing mutation.

- Primary wording: `Preview upcoming invoice` or `Preview before commit`
- Customer expectation: this is the canonical path where supported for checking
  proration and next-invoice shape before `swap_plan/3`
- Provider labels:
  - Stripe: `native`
  - Braintree: `unsupported`
  - Fake: `testing/local-only`

Keep Braintree wording explicit: there is no first-party preview parity through
Accrue today. Hosts may still explain direct bounded swaps on Braintree, but
they should not imply a broken or hidden preview button where the feature is
actually unsupported.

### `cancel_at_period_end`

Default self-serve cancellation posture. Turn off renewal now and preserve
paid-through access until the current period ends.

- Primary wording: `Cancel renewal` or `End at period end`
- Customer expectation: access continues until `current_period_end`
- Provider labels:
  - Stripe: `native`
  - Braintree: `host-owned`
  - Fake: `testing/local-only`

Prefer this action over immediate termination for normal customer self-serve
flows. Immediate termination is the exceptional path for fraud, compliance,
support-led hard stops, or similar operator-owned situations.

### `cancel/2`

Immediate cancellation. Use this only when you intentionally need to stop the
subscription now instead of at the paid-through boundary.

- Primary wording: `Cancel now`
- Customer expectation: access may end immediately or require explicit operator
  review of downstream entitlement effects
- Provider labels:
  - Stripe: `native`
  - Braintree: `native`
  - Fake: `testing/local-only`

Do not make `cancel/2` the primary self-serve example unless your product
explicitly wants a hard-stop cancellation flow.

Braintree supports this path through `Accrue.Billing.cancel/2` today. The
provider mismatch is on softer end-of-term and reversal semantics, not on the
immediate hard-stop action itself.

### `resume/2`

Undo a scheduled end created through `cancel_at_period_end`. This is the
"keep the subscription renewing" path, not a generic resurrect-anything action.

- Provider labels:
  - Stripe: `native`
  - Braintree: `unsupported`
  - Fake: `testing/local-only`

If Braintree does not support the same semantics for a hosted reversible
cancellation, keep the wording explicit: the mounted host flow owns the product
contract, and recreating a subscription may be the next step instead of
implying Stripe-shaped native reversibility.

### `pause/2`

Pause collection while preserving the local subscription record and the chosen
pause behavior.

- Provider labels:
  - Stripe: `native`
  - Braintree: `unsupported`
  - Fake: `testing/local-only`

Only surface `pause/2` where the processor and product contract actually
support the semantics. Do not imply that Braintree can natively mirror Stripe's
pause-collection lifecycle.

### `unpause/2`

Resume collection for a paused subscription.

- Provider labels:
  - Stripe: `native`
  - Braintree: `unsupported`
  - Fake: `testing/local-only`

Treat `unpause/2` as the inverse of `pause/2`, not as a general recovery tool
for every ended or canceling state.

## State glossary

Use `Accrue.Billing.Subscription` predicates and `Accrue.Billing.Query` when a
surface needs lifecycle meaning. Do not derive customer or operator meaning
from raw provider status strings alone.

### `active`

The subscription currently counts for entitlement purposes. In Accrue this
includes trialing subscriptions as well as normal active rows.

### `canceling`

The subscription is still active, but renewal has already been turned off
through `cancel_at_period_end` and the paid-through period has not ended yet.
Access continues until `current_period_end`.

### `paused`

Collection is paused. This may come from the legacy `:paused` status or from a
non-nil `pause_collection` payload, so rely on the predicate instead of one raw
status branch.

### `past_due`

The subscription is in dunning territory. In Accrue that includes `:past_due`
and `:unpaid`, and the operator experience should treat this as a billing
recovery state rather than normal active service.

### `ended`

The subscription has terminated. This maps to Accrue's canonical ended truth:
`canceled?/1` returns true for `:canceled`, `:incomplete_expired`, or any row
with a non-nil `ended_at`.

## Provider labels

Attach these labels when a guide or UI needs to explain lifecycle differences:

- `native`: the processor supports the lifecycle behavior directly
- `host-owned`: the host app or mounted Accrue surface owns the customer-facing
  semantics locally, or must supply local metadata before Accrue can perform
  the processor mutation
- `unsupported`: the processor does not support that Accrue lifecycle semantic
- `testing/local-only`: deterministic proof behavior used for Fake or local
  verification, not evidence of cross-provider parity

## Convergence and local truth

Lifecycle actions and webhook updates converge through local projection truth.
That means a page can acknowledge refresh or webhook timing without promising
impossible instant global truth. Use the local projection as the operational
truth and let webhook-oriented docs explain eventual convergence details.

## Related guides

- [Braintree local portal](braintree-local-portal.md)
- [Customer portal configuration checklist](portal_configuration_checklist.md)
- [Webhooks](webhooks.md)
- [Webhook gotchas](webhook_gotchas.md)
