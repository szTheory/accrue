# Webhooks

For the canonical lifecycle glossary behind webhook-driven local projection
updates, see [Lifecycle Semantics](lifecycle_semantics.md). Use that guide for
the meaning of `active`, `canceling`, `paused`, `past_due`, and ended states;
use this guide for delivery, verification, and convergence wiring.

Keep webhook setup on the public host boundary. The recommended shape is:

- mount `/webhooks/stripe` in a dedicated raw-body pipeline
- mount `/webhooks/braintree` in a standard params pipeline that accepts
  `bt_signature` and `bt_payload`
- implement a host handler with `use Accrue.Webhook.Handler`
- configure the signing secret in `config/runtime.exs`
- use replay through the supported admin and task surfaces

## Route and raw body

Stripe signatures are checked against the original request body, so the webhook
scope must use a parser pipeline with a raw body reader:

```elixir
pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
end

scope "/webhooks" do
  pipe_through :accrue_webhook_raw_body
  accrue_webhook "/stripe", :stripe
end
```

Apple App Store Server Notifications V2 must use that same dedicated pipeline:

```elixir
scope "/webhooks" do
  pipe_through :accrue_webhook_raw_body

  accrue_apple_notifications "/apple",
    verifier_config: apple_verifier_config,
    rate_limiter: &MyApp.AppleRateLimiter.check/1
end
```

The host supplies the Apple verifier configuration and rate policy. If the route
does not preserve a non-empty exact capture in `conn.assigns[:raw_body]`, Accrue
returns a retryable `503` before verification or persistence. Do not substitute
parsed params, reconstructed JSON, or another byte sequence. See
[Troubleshooting — `ACCRUE-DX-WEBHOOK-RAW-BODY`](troubleshooting.md#accrue-dx-webhook-raw-body)
for parser placement and capture diagnostics.

Braintree does not require Stripe's raw-body reader. The handler still belongs
at the same host boundary, but the plug path reads `bt_signature` and
`bt_payload`, then passes them through `Signature.parse_braintree!/2` before
Accrue persists the normalized event.

```elixir
scope "/webhooks" do
  pipe_through :browser
  accrue_webhook "/braintree", :braintree
end
```

## Host handler boundary

Use `use Accrue.Webhook.Handler` in a host-owned module:

```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    MyApp.Billing.handle_webhook(type, event, ctx)
  end
end
```

## Signature failures and generic HTTP failures

Invalid signatures should return a generic `400`. Host misconfiguration should
surface as a generic server failure, with the actionable detail carried by the
stable diagnostic code and linked fix path in the troubleshooting guide.
Raw-body ordering and parser placement issues map to **`ACCRUE-DX-WEBHOOK-RAW-BODY`** — see [Troubleshooting — `ACCRUE-DX-WEBHOOK-RAW-BODY`](troubleshooting.md#accrue-dx-webhook-raw-body) for the fix matrix row.

For Braintree, the support-visible failure shape is different: wrong
`portal_base_url` or `portal_mount_path` does not break an upstream hosted
redirect because there is none. It breaks the local checkout or billing-portal
URL generation that the mounted portal returns to the host.

## Processor-aware event handling

Stripe and Braintree share the same Accrue ingest boundary, but they do not
prove the same thing:

- Stripe webhook truth comes from upstream event delivery and hosted URLs.
- Braintree webhook truth is normalized into Accrue event shapes and may finish
  local portal work by persisting `accrue.portal.checkout.completed`.

That local checkout-completion event is projection-backed. On Braintree, the
authoritative completion story is not an upstream hosted redirect callback; it
is the persisted local event that `Accrue.Webhook.DefaultHandler` reduces after
the mounted checkout flow succeeds. The same reducer also normalizes Braintree
subscription webhook kinds through `normalize_braintree_type/1` so replay and
recovery stay inside the existing invoice and subscription reducers.

## Replay

Replay is for reprocessing persisted webhook events after you fix host setup or
handler code. Use it when the host boundary is fixed, when the async dispatcher
dead-lettered a row, or when Braintree local checkout completion or metered
renewal recovery needs the persisted event stream to converge again.

Core entry points:

- `mix accrue.webhooks.replay` for the bounded CLI path
- `Accrue.Webhooks.DLQ.requeue/1` and `Accrue.Webhooks.DLQ.requeue_where/2`
  for explicit replay of persisted dead or failed rows
- the admin replay surface in the example host for operator-driven recovery

Verify the end-to-end proof path with:

```bash
mix test test/accrue_host_web/webhook_ingest_test.exs
```

Webhook delivery is the convergence path, not a separate lifecycle glossary.
After lifecycle actions run, local projection truth may briefly lead or lag
external provider state; the lifecycle guide defines what the resulting states
mean, and webhook replay helps those local projections converge cleanly.

When triaging Braintree-specific failures, keep the support contract provider
honest: replay fixes the persisted Accrue event path, not an upstream hosted
checkout session. If `portal_base_url`, `portal_mount_path`, auth continuity,
or Hosted Fields readiness is wrong, fix the host setup first, then replay the
stored event so the local projection and telemetry catch back up.
