# Custom Processors

Accrue ships with Stripe and the Fake Processor, but the processor boundary is
an explicit extension point. A custom adapter should implement the documented
behaviour and return the same shape of `{:ok, map}` or `{:error, exception}`
results that the billing context already expects.

Do not use a custom processor to fake undocumented parity with every Stripe
feature. The contract is the public `Accrue.Processor` behaviour, and host apps
should rely on the documented billing facade rather than adapter internals.

## Behaviour contract

A custom adapter starts with the behaviour declaration:

```elixir
defmodule MyApp.Billing.AcmePay do
  @behaviour Accrue.Processor

  @impl Accrue.Processor
  def create_customer(params, opts), do: {:ok, %{id: "cus_custom_123", params: params, opts: opts}}

  @impl Accrue.Processor
  def retrieve_customer(id, _opts), do: {:ok, %{id: id}}

  @impl Accrue.Processor
  def update_customer(id, params, _opts), do: {:ok, %{id: id, params: params}}

  # Implement the rest of the documented callbacks your billing flow uses.
end
```

The important part is the contract marker:

```elixir
@behaviour Accrue.Processor
```

Match the existing callback names and keep return values plain. Billing context
functions wrap higher-level behavior such as intent branches, telemetry, and
event recording around those adapter calls.

## Wiring your adapter

Set the processor module in config:

```elixir
config :accrue, :processor, MyApp.Billing.AcmePay
```

That keeps all host-facing calls on the usual entrypoint:

```elixir
Accrue.Processor.create_customer(%{email: "user@example.test"})
```

Use runtime config rather than hard-coding a module alias in the application.
That is the same dispatch model the built-in adapters use.

## Keep the fake path first

`Accrue.Processor.Fake` remains the baseline for most host-app tests even if a
production deployment uses a custom adapter. The Fake gives deterministic ids,
clock control, and webhook synthesis without any network dependency.

Treat your custom processor tests as adapter-contract tests and keep the main
billing suite on the Fake unless the external processor itself is the thing
under test.

## Test with Accrue.Test

For normal billing flows, keep the primary assertions on the host billing
context and use the built-in fake surface:

```elixir
use Accrue.Test

setup do
  Accrue.Test.setup_fake_processor()
  :ok
end
```

`Accrue.Processor.Fake` is the primary test surface because it proves the flow
through the same reducer, event, mailer, and PDF paths that the host app uses.
Once that is green, add a narrower suite around the custom adapter module to
prove callback conformance and error mapping.
