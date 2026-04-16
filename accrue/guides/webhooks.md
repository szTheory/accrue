# Webhooks

Keep webhook setup on the public host boundary. The recommended shape is:

- mount `/webhooks/stripe` in a dedicated raw-body pipeline
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

## Replay

Replay is for reprocessing persisted webhook events after you fix host setup or
handler code. Verify the end-to-end proof path with:

```bash
mix test test/accrue_host_web/webhook_ingest_test.exs
```
