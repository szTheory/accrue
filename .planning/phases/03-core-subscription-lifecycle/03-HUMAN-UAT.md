---
status: partial
phase: 03-core-subscription-lifecycle
source: [03-VERIFICATION.md]
started: 2026-04-14T00:00:00Z
updated: 2026-04-14T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Real Stripe 3DS test card end-to-end
expected: `Accrue.Billing.charge/3` against Stripe test card `4000 0027 6000 3184` (3DS authentication required) returns `{:ok, :requires_action, %{payment_intent: _, client_secret: _}}`. After completing 3DS in the browser and confirming the PaymentIntent, a subsequent webhook (`charge.succeeded`) drives the local Charge row to `:succeeded` status.
result: [pending]

### 2. Live Stripe out-of-order webhook replay
expected: Using `stripe trigger customer.subscription.updated` twice, replay the events out-of-order by adjusting delivery timing. Accrue resolves state from the newest event by Stripe `created` timestamp, re-fetches the current Stripe object rather than trusting payload snapshots, and updates `last_stripe_event_ts` + `last_stripe_event_id` watermark columns correctly. The stale event is skipped.
result: [pending]

### 3. Live proration preview vs. committed invoice round-trip
expected: `Accrue.Billing.preview_upcoming_invoice(subscription, swap_to: new_price)` returns line items that numerically match the line items on the real invoice produced after calling `swap_plan(subscription, new_price, proration: :create_prorations)`. The preview's proration math matches the committed invoice line-for-line.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
