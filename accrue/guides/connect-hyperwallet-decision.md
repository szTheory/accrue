# Hyperwallet Decision Boundary for Braintree Connect Questions

Accrue does not treat Braintree plus Hyperwallet as first-party
marketplace parity under `Accrue.Connect`.

## Final verdict

Braintree marketplace parity through Hyperwallet is **out of scope for
Accrue's current Connect surface**. This is not a soft "maybe later"
note. **Revisit it only if Accrue explicitly adds first-party Braintree
marketplace support in a future release**.

## Why the answer is no

- Braintree recurring billing is incompatible with Marketplace.
- Hyperwallet is a separate payout program with separate webhook URLs, admin users, and API-credential recipients.
- Braintree pay-ins and Hyperwallet payouts are separate truths.
- Pretending the combined system behaves like Stripe Connect would
  create misleading product semantics and support debt.

## Narrow if-go contract, if Accrue ever adds this support

If Accrue's product boundary changes in a future release, the smallest
honest slice is **minimal seller onboarding + payouts only**.

That slice still does not imply Stripe-style marketplace semantics.
The following remain loud exclusions:

- destination charges
- separate charge-and-transfer
- login-link parity
- unified connected-account balance

Any future work must keep Braintree pay-ins and Hyperwallet payouts as
separate truths in docs, capability labels, and failure modes.

## What this means for Accrue today

`Accrue.Connect` remains a Stripe-first marketplace surface. Accrue does
not currently offer Braintree marketplace parity, and it does not add
new runtime APIs, callbacks, dependencies, or pseudo-abstractions that
would imply otherwise.
