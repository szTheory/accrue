# Custom PDF Adapter

Accrue renders invoice PDFs through a behaviour boundary so hosts can replace
the default ChromicPDF path when their deployment shape requires something
else. Common examples are a sidecar renderer, an internal document service, or
an environment that cannot run Chromium locally.

The public contract is the `Accrue.PDF` behaviour. Keep adapters focused on
HTML-in, PDF-binary-out, and avoid reaching into invoice or email internals.

## Behaviour contract

Define a module that implements the behaviour:

```elixir
defmodule MyApp.PDF.Adapter do
  @behaviour Accrue.PDF

  @impl true
  def render(html, opts) when is_binary(html) and is_list(opts) do
    _ = {html, opts}
    {:ok, "%PDF-CUSTOM"}
  end
end
```

The required marker is:

```elixir
@behaviour Accrue.PDF
```

Keep secrets, endpoints, and credentials in host-app runtime config or env
vars. Guide snippets should use placeholders such as `"https://pdf.example.test"`
or `"PDF_SERVICE_TOKEN"` rather than real values.

## Runtime configuration

Wire the adapter in config:

```elixir
config :accrue, :pdf_adapter, MyApp.PDF.Adapter
```

That keeps calls on the stable facade:

```elixir
Accrue.PDF.render("<html><body>invoice preview</body></html>", size: :a4)
```

See `guides/pdf.md` for the built-in adapter behavior, paper-size options, and
the shared template path used by invoice email and PDF rendering.

## Null adapter fallback

If the deployment target cannot render PDFs at all, point Accrue at
`Accrue.PDF.Null`:

```elixir
config :accrue, :pdf_adapter, Accrue.PDF.Null
```

`Accrue.PDF.Null` satisfies the same behaviour but returns a typed disabled-PDF
error instead of raising. That lets invoice mail flows degrade to hosted links
without pretending a PDF binary exists.

## Dry-run verification

Verify the adapter in the host app before shipping:

1. Configure the adapter in `config/runtime.exs` or an environment-specific
   config file with placeholder endpoint values.
2. Render a sample invoice HTML through `Accrue.PDF.render/2`.
3. Confirm the adapter returns `{:ok, pdf_binary}` for the enabled path, or the
   documented disabled error for the null path.
4. Run the docs gate so guide references stay valid:

```bash
mix docs --warnings-as-errors
```

That last step matters because a custom adapter guide is only useful if the
release docs still build cleanly in the consuming app and in Accrue itself.
