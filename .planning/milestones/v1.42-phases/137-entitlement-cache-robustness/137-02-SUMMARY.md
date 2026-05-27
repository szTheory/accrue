# 137-02 Summary: WR-05 Race-Safe Entitlement Summary Upsert

Resolved the webhook concurrency failure on entitlement summary writes.

## Delivered

- Reworked `upsert_entitlement_summary` to use a DB-level atomic upsert.
- Enforced the monotonic `last_stripe_event_ts` watermark in the conflict path.
- Eliminated the `Ecto.StaleEntryError` path during concurrent deliveries for the same customer.

## Verification

- `mix test test/accrue/webhook/wr05_concurrency_test.exs`

## Traceability

- FIX-01
- WR-05
