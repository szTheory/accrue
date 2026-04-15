# Accrue Connect — Marketplace Platforms Guide

Accrue's Connect surface (`Accrue.Connect`) gives Phoenix SaaS platforms
first-class support for Stripe Connect: onboarding connected accounts,
routing charges with destination or separate-charge semantics,
computing platform fees, rendering Express dashboard login links, and
receiving Connect webhooks on a dedicated endpoint.

This guide walks through the full public API in the order a platform
builder will encounter it, and calls out the Phase 5 footguns that
will silently cost you money if ignored (Pitfalls section).

> **Tagline:** one process dictionary key, one changeset module, one
> webhook endpoint. The rest is host code.

---

## Getting Started — multi-endpoint webhook config

Stripe Connect requires TWO webhook endpoints: one for platform events
(customer/subscription/invoice on the platform account) and one for
Connect events (account.updated, account.application.authorized,
capability.updated, payout.*, and mirrored charge events under a
connected account).

Configure both under `:webhook_endpoints` in `config/runtime.exs`:

```elixir
config :accrue,
  webhook_endpoints: [
    primary: [
      secret: System.fetch_env!("STRIPE_WEBHOOK_SECRET")
    ],
    connect: [
      secret: System.fetch_env!("STRIPE_CONNECT_WEBHOOK_SECRET"),
      mode: :connect
    ]
  ]
```

Mount the plug twice — once per endpoint — passing `endpoint:` so the
plug knows which secret to verify against:

```elixir
# lib/my_app_web/router.ex
pipeline :stripe_webhooks do
  plug Accrue.Plug.VerifyStripeSignature, endpoint: :primary
end

pipeline :stripe_connect_webhooks do
  plug Accrue.Plug.VerifyStripeSignature, endpoint: :connect
end

scope "/webhooks" do
  post "/stripe", MyAppWeb.StripeWebhookController, :handle
  post "/stripe/connect", MyAppWeb.StripeConnectWebhookController, :handle
end
```

Register the two webhook endpoints separately in your Stripe Dashboard.
Each endpoint will get its OWN signing secret — see the **Pitfalls**
section below before copy-pasting.

---

## Onboarding a connected account

Accrue supports Standard, Express, and Custom account types. Each one
is created the same way via `Accrue.Connect.create_account/2`, then a
short-lived `AccountLink` is generated to redirect the merchant into
Stripe's hosted onboarding flow.

### Example 1: Onboarding a Standard account

```elixir
{:ok, account} =
  Accrue.Connect.create_account(%{
    type: "standard",
    country: "US",
    email: "merchant@example.com",
    capabilities: %{
      "card_payments" => %{requested: true},
      "transfers" => %{requested: true}
    }
  })

{:ok, %Accrue.Connect.AccountLink{} = link} =
  Accrue.Connect.create_account_link(account,
    return_url: "https://platform.example.com/connect/return?acct=#{account.stripe_account_id}",
    refresh_url: "https://platform.example.com/connect/refresh?acct=#{account.stripe_account_id}",
    type: "account_onboarding",
    collect: "currently_due"
  )

# Inspect output redacts the URL:
#  #Accrue.Connect.AccountLink<url: <redacted>, expires_at: ~U[2026-04-15 14:30:00Z], ...>

# Host's controller redirects:
redirect(conn, external: link.url)
```

`AccountLink.url` is masked by a custom `Inspect` implementation so
accidental logging (`IO.inspect`, exception context, Sentry breadcrumbs)
never leaks a valid onboarding bearer.

For Express and Custom, pass `type: "express"` or `type: "custom"` —
the changeset allows either.

---

## Destination charges

A destination charge routes a single `charges.create` call through the
platform, with `transfer_data.destination` pointing at the connected
account and `application_fee_amount` reserved for the platform. Stripe
automatically moves funds minus the fee into the destination account's
balance.

### Example 2: Destination charge with platform fee

```elixir
gross = Accrue.Money.new(10_000, :usd)              # $100.00
{:ok, fee} = Accrue.Connect.platform_fee(gross)     # %Money{amount_minor: 320, currency: :usd}

{:ok, %Accrue.Billing.Charge{} = charge} =
  Accrue.Connect.destination_charge(%{
    amount: gross,
    currency: :usd,
    customer: customer,
    destination: account,                            # %Connect.Account{} OR "acct_..."
    application_fee_amount: fee,
    description: "Order #1234"
  })
```

`destination_charge/2` always runs platform-scoped regardless of any
surrounding `with_account/2` block (Pitfall 2). The destination is
carried in the request body, not the `Stripe-Account` header.

---

## Separate charges + transfers

Use a separate charge and transfer when you need more flexibility — for
example, holding funds on the platform before releasing a subset to the
seller, or splitting a single customer charge across multiple sellers.

### Example 3: Separate charge + transfer

```elixir
{:ok, %{charge: charge, transfer: transfer}} =
  Accrue.Connect.separate_charge_and_transfer(%{
    amount: Accrue.Money.new(10_000, :usd),
    currency: :usd,
    customer: customer,
    destination: account,
    transfer_amount: Accrue.Money.new(8_000, :usd)   # $80 to seller, $20 platform
  })
```

Two distinct Stripe API calls fire: first the platform charge, then a
standalone `transfers.create` to the connected account. Both are
recorded in `accrue_events` so the audit trail shows the fund movement
explicitly.

---

## Scoped operations — `with_account/2`

Every call inside `Accrue.Connect.with_account/2` automatically carries
the connected account ID through to the processor layer via the
`:accrue_connected_account_id` process dictionary key. This lets you
write the same billing code platform-scoped and account-scoped.

### Example 4: Scoped operation across multiple billing calls

```elixir
Accrue.Connect.with_account("acct_marketplace_seller_42", fn ->
  # All three calls inside this block carry the Stripe-Account header
  # automatically.
  {:ok, customer} = Accrue.Billing.fetch_or_create_customer(buyer_user)
  {:ok, sub}      = Accrue.Billing.subscribe(customer, "price_pro_monthly")
  {:ok, invoice}  = Accrue.Billing.preview_upcoming_invoice(sub)
  {:ok, sub, invoice}
end)
```

The block's prior pdict value is restored (or cleared) in an `after`
clause — nested `with_account/2` calls save and restore cleanly, and
exceptions never leak scope across test boundaries.

CONN-11 guarantees: the exact same `Accrue.Billing.*` call must work
inside and outside `with_account/2`. The Phase 5 dual-scope test
(`test/accrue/connect/dual_scope_test.exs`) proves this contract by
calling `create_customer/1` in both scopes and asserting the Fake
processor's keyspaces are isolated.

---

## Express dashboard login links

Express accounts don't see the Stripe dashboard directly — platform
operators generate a short-lived Stripe-hosted login URL on demand.

### Example 5: Express dashboard login link

```elixir
{:ok, %Accrue.Connect.LoginLink{} = link} =
  Accrue.Connect.create_login_link(account)

# Host's admin UI:
redirect(conn, external: link.url)   # 5-min Express dashboard bearer
```

`LoginLink.url` is `Inspect`-masked identically to `AccountLink`.

---

## Platform fee computation

`Accrue.Connect.platform_fee/2` is a pure Money-math helper. It does
NOT auto-apply to charges or transfers — the caller threads the
result into `application_fee_amount:` at the call site so the fee is
always auditable.

### Config schema

```elixir
# Source: D5-04 — extends Accrue.Config with :connect key
config :accrue,
  connect: [
    default_stripe_account: nil,
    platform_fee: [
      percent: Decimal.new("2.9"),
      fixed: Accrue.Money.new(30, :usd),
      min: nil,
      max: nil
    ]
  ]
```

### Order of operations

1. `percent` component — `gross * (percent / 100)` in minor units,
   banker's rounding (`:half_even`) at integer precision. Currency-
   exponent-agnostic: JPY (0-decimal), USD (2-decimal), and KWD
   (3-decimal) all round at the same integer boundary.
2. `fixed` component — added verbatim.
3. `min` floor clamp — raises result to minimum if below.
4. `max` ceiling clamp — lowers result to maximum if above.

Zero-gross short-circuits to zero fee before any math.

### Per-account fee override recipe

Host applications often want to charge different platform fees for
different sellers (e.g. 2.9% for standard, 1.9% for premium partners).
Accrue does not provide a fee-per-account table — the host owns that
data. Pass opts at the call site:

```elixir
# Host-owned schema:
#     field :platform_fee_override, :map, default: %{}
# Stored as `%{"percent" => "1.9", "fixed_cents" => 30}`.
defp fee_for(account, gross) do
  override = account.platform_fee_override || %{}

  opts =
    []
    |> put_if_present(:percent, override["percent"], &Decimal.new/1)
    |> put_if_present(:fixed, override["fixed_cents"], &Accrue.Money.new(&1, gross.currency))

  Accrue.Connect.platform_fee(gross, opts)
end

defp put_if_present(opts, _key, nil, _cast), do: opts
defp put_if_present(opts, key, value, cast), do: Keyword.put(opts, key, cast.(value))
```

Any unset opt falls back to the `:connect` config defaults. This gives
hosts per-account overrides without Accrue owning the schema.

---

## Testing — Fake keyspace scoping

`Accrue.Processor.Fake` tags every write with a scope key read from
`Process.get(:accrue_connected_account_id)`. This lets test assertions
verify keyspace isolation directly:

```elixir
use Accrue.ConnectCase, async: false

test "customer lands in the connected-account keyspace" do
  {:ok, acct} = Accrue.Connect.create_account(%{type: :standard, country: "US"})

  Accrue.Connect.with_account(acct.stripe_account_id, fn ->
    {:ok, _customer} = Accrue.Billing.create_customer(some_billable)
  end)

  scoped   = Accrue.Processor.Fake.customers_on(acct.stripe_account_id)
  platform = Accrue.Processor.Fake.customers_on(:platform)

  assert length(scoped)   == 1
  assert Enum.empty?(platform)
end
```

`Accrue.ConnectCase` clears the `:accrue_connected_account_id` pdict
key at both setup and `on_exit` so scope cannot leak between tests
even when they share a GenServer-backed Fake.

### Live Stripe test mode

`accrue/test/live_stripe/connect_test.exs` exercises the real
`Accrue.Processor.Stripe` adapter against Stripe test mode. Run it
explicitly:

```
STRIPE_TEST_SECRET_KEY=sk_test_... mix test --only live_stripe
```

The suite is excluded from default `mix test` runs via
`test/test_helper.exs`. It refuses to run against keys that don't
start with `sk_test_` (T-05-07-03 spoofing guard).

---

## Pitfalls

The six footguns that will bite you if you ignore them. Each pitfall
has a mitigation either shipped in code or documented below.

### Pitfall 1 — Destination-field routing vs. header scoping

Destination charges carry `destination` in the REQUEST BODY via
`transfer_data[destination]`. They do NOT set the `Stripe-Account`
header. `Accrue.Connect.destination_charge/2` enforces this by forcing
platform scope regardless of any surrounding `with_account/2` block.

### Pitfall 2 — Silent scope leak across async boundaries

The process dictionary does not survive `Task.async`, GenServer
dispatch, or Oban job enqueue. Plan 01's Oban middleware re-reads
`:accrue_connected_account_id` at enqueue time and restores it at
perform time — use `Accrue.Workers.ConnectAwareWorker` or enqueue
through a helper that threads the scope through job args.

### Pitfall 3 — Missing `application_fee_amount` currency check

`application_fee_amount` must match the charge currency. Accrue's
`platform_fee/2` validates currency symmetry up front and returns an
error before any Stripe call fires.

### Pitfall 4 — Rounding drift between JPY and USD

Zero-decimal currencies (JPY, KRW) and three-decimal currencies (KWD,
BHD) round at different boundaries. `platform_fee/2` performs banker's
rounding at the minor-unit integer level, which is the same boundary
Stripe uses. Property tests in
`test/property/connect_platform_fee_property_test.exs` enforce this
across all supported currencies.

### Pitfall 5 — Connect-variant secret confused with platform secret

**This is the one you'll hit.** Stripe issues a **SEPARATE signing secret per Connect endpoint** in the Stripe Dashboard. If you
accidentally configure your `:connect` endpoint with your `:primary`
endpoint's secret (or vice versa), signature verification will **fail
silently** — Stripe-hosted test mode happily accepts either secret on
either endpoint, so this bug only surfaces in production under real
Connect traffic.

Two mitigations:

1. Accrue emits a `Logger.warning/1` at application boot if any
   `:connect`-tagged endpoint secret is byte-identical to any
   non-Connect endpoint secret. See
   `Accrue.Application.warn_on_secret_collision/0`.
2. Name your env vars distinctly:
   `STRIPE_WEBHOOK_SECRET` for `:primary`, and
   `STRIPE_CONNECT_WEBHOOK_SECRET` for `:connect`. Treat them as
   two independent credentials — they are.

### Pitfall 6 — `charges_enabled` reads before onboarding completes

`Accrue.Connect.Account.charges_enabled?/1` returns `false` until the
merchant finishes Stripe-hosted onboarding AND an `account.updated`
webhook mirrors the state change into `accrue_connect_accounts`. Do
not gate checkout on `create_account/2` return alone — wait for the
webhook to flip the local row, or call `retrieve_account/2` to
refresh from Stripe on demand.

---

## Related guides

- `guides/webhooks.md` — platform webhook verification + DLQ replay
- `guides/testing-live-stripe.md` — live-mode CI workflow
- `guides/billing.md` — the non-Connect billing surface this guide
  composes on top of

## References

- Phase 5 RESEARCH: `.planning/phases/05-connect/05-RESEARCH.md`
- D5-01 (pdict scope) — `Accrue.Connect.with_account/2`
- D5-02 (hybrid projection) — `Accrue.Connect.Account` schema
- D5-03 (destination vs separate) — `destination_charge/2`, `separate_charge_and_transfer/2`
- D5-04 (platform fee) — `Accrue.Connect.PlatformFee`
- D5-05 (audit soft-delete) — `delete_account/2` tombstones via `deauthorized_at`
- D5-06 (LoginLink/AccountLink) — `Accrue.Connect.LoginLink`, `Accrue.Connect.AccountLink`
