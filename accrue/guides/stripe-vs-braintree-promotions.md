# Stripe vs Braintree Promotions

Stripe promotions are processor-backed. Braintree promotions are local-code
mappings that point at Control Panel discounts managed outside the customer
checkout flow.

That distinction matters because Accrue does not pretend the processors expose
the same upstream object model:

- Stripe promotion codes are created through processor-native coupon and
  promotion-code APIs, then projected locally.
- Braintree promotion codes are stored locally in Accrue and resolved to a
  Braintree `discount_id` when a subscription is created.

## Local-Code Mappings

For Braintree, the supported setup path is:

```elixir
{:ok, _mapping} =
  Accrue.Billing.upsert_discount_mapping("SPRING25", %{
    discount_id: "bt_discount_25",
    amount_off_minor: 2_500,
    currency: "USD",
    active: true,
    max_redemptions: 100
  })
```

`max_redemptions` is enforced through local redemption state. It is not ignored
metadata, and it is not delegated to a processor-native Braintree promotion
object because that object does not exist.

## Preview vs Final Submit

Accrue's portal flow previews savings locally before payment submit, then
revalidates the selected code inside `Accrue.Billing.subscribe/3`. The preview
is intentionally provisional. Expiry, deactivation, redemption-cap changes, or
operator drift can invalidate a mapping between preview and final submit.

If the local row has drifted into an unusable state, submit returns
`%Accrue.Error.DiscountMappingInvalid{}` and the customer sees safe copy such
as "This promotion is temporarily unavailable."

## Troubleshooting

Use the `[:accrue, :ops, :discount_mapping_invalid]` telemetry event to alert
operators when a locally valid code points at a broken Braintree discount id.
The event carries allowlisted metadata only: mapping id, code, discount id,
reason, and the surrounding operation id when available.

When the event fires:

1. Find the code in the local `accrue_discount_mappings` row.
2. Confirm the mapped `discount_id` still exists and is the intended Control
   Panel discount.
3. Repair the row with `Accrue.Billing.upsert_discount_mapping/3`.
4. Ask the customer to retry after the mapping is fixed.
