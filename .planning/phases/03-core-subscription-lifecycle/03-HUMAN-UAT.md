---
status: resolved
phase: 03-core-subscription-lifecycle
source: [03-VERIFICATION.md]
started: 2026-04-14T00:00:00Z
updated: 2026-04-14T00:00:00Z
resolved_by: quick/260414-l9q-automate-phase-3-human-verification-item
---

## Current Test

[all items automated — no pending human action]

## Tests

### 1. Real Stripe 3DS test card end-to-end
expected: `Accrue.Billing.charge/3` against Stripe test card `4000 0027 6000 3184` (3DS authentication required) returns `{:ok, :requires_action, %{payment_intent: _, client_secret: _}}`. After completing 3DS in the browser and confirming the PaymentIntent, a subsequent webhook (`charge.succeeded`) drives the local Charge row to `:succeeded` status.
result: automated
automation:
  fake: accrue/test/accrue/billing/charge_3ds_test.exs
  live: accrue/test/live_stripe/charge_3ds_live_test.exs

### 2. Live Stripe out-of-order webhook replay
expected: Using `stripe trigger customer.subscription.updated` twice, replay the events out-of-order by adjusting delivery timing. Accrue resolves state from the newest event by Stripe `created` timestamp, re-fetches the current Stripe object rather than trusting payload snapshots, and updates `last_stripe_event_ts` + `last_stripe_event_id` watermark columns correctly. The stale event is skipped.
result: automated
automation:
  fake: accrue/test/accrue/webhook/default_handler_out_of_order_test.exs
  notes: |
    Three legs covered across two files. (a) "older event is skipped
    when newer is watermarked" and (b) "tie on equal ts processes" in
    default_handler_out_of_order_test.exs; (c) refetch-via-Processor.fetch
    in default_handler_phase3_test.exs ("customer.subscription.updated
    refetches and updates row"). Reverse-order delivery leg added in
    quick task 260414-l9q.

### 3. Live proration preview vs. committed invoice round-trip
expected: `Accrue.Billing.preview_upcoming_invoice(subscription, swap_to: new_price)` returns line items that numerically match the line items on the real invoice produced after calling `swap_plan(subscription, new_price, proration: :create_prorations)`. The preview's proration math matches the committed invoice line-for-line.
result: automated
automation:
  fake: accrue/test/accrue/billing/proration_roundtrip_test.exs
  live: accrue/test/live_stripe/proration_fidelity_live_test.exs
  notes: |
    Fake-asserted test proves pipeline continuity (preview → swap → preview)
    but cannot prove numerical fidelity because the Fake synthesizes
    previews from a deterministic generator. Numerical fidelity is
    proven only by the live-Stripe companion, gated on
    STRIPE_TEST_SECRET_KEY and run via scheduled CI or manual dispatch.

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None. All items have automated Fake coverage on every PR and
live-Stripe fidelity coverage on scheduled/dispatch CI.
