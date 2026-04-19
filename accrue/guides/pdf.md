# PDF Rendering

Accrue renders invoice PDFs from the same `Accrue.Invoices.Components`
that power the transactional emails, via the `Accrue.PDF` behaviour.
The default adapter drives ChromicPDF (headless Chrome) in-process on
the host app. Two alternate adapters ship for test and Chrome-hostile
environments, and the behaviour is open so hosts can add their own
(for example, a Gotenberg sidecar).

If you only read one section: jump to **ChromicPDF setup** for the
production wiring, or **`Accrue.PDF.Null` graceful degradation** if
your deployment target cannot run Chromium.

## Adapters

Three adapters ship with v1.0:

| Adapter | When to use | Returns |
| --- | --- | --- |
| `Accrue.PDF.ChromicPDF` | Production default. Renders HTML → PDF via a host-supervised `ChromicPDF` pool. | `{:ok, pdf_binary}` |
| `Accrue.PDF.Test` | Test env. Sends `{:pdf_rendered, html, opts}` to `self()` and returns a `"%PDF-TEST"` stub. Chrome-free. | `{:ok, "%PDF-TEST"}` |
| `Accrue.PDF.Null` | Chrome-hostile deploys (minimal Alpine, locked-down containers). Returns a typed error without rendering. | `{:error, %Accrue.Error.PdfDisabled{}}` |

The adapter is resolved via `:storage_adapter`'s sibling config key:

```elixir
# config/config.exs
config :accrue, :pdf_adapter, Accrue.PDF.ChromicPDF

# config/test.exs
config :accrue, :pdf_adapter, Accrue.PDF.Test
```

All three adapters implement `@behaviour Accrue.PDF`, so hosts that
need a custom backend can follow the same shape — see **Custom
adapter: Gotenberg sidecar** below.

## ChromicPDF setup

Accrue does **not** start ChromicPDF itself. The host app owns
the supervision tree and supervises the pool. Pick the right shape for
the environment:

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    MyApp.Repo,
    {Phoenix.PubSub, name: MyApp.PubSub},
    chromic_pdf_child(),
    MyAppWeb.Endpoint
  ]

  Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
end

# Dev + test: lazy, one-shot browser session per render.
defp chromic_pdf_child do
  if Application.get_env(:my_app, :env) in [:dev, :test] do
    {ChromicPDF, on_demand: true}
  else
    {ChromicPDF, session_pool: [size: 3]}
  end
end
```

### Performance posture — keep Oban concurrency ≤ pool size

ChromicPDF's `session_pool[:size]` caps the number of concurrent
Chromium sessions. If Accrue's `accrue_mailers` Oban queue concurrency
exceeds that cap, workers will block on `:poolboy` checkouts and
silently balloon job runtimes.

**Rule:** the `accrue_mailers` queue concurrency MUST be less
than or equal to the ChromicPDF `session_pool[:size]`. Start at
`session_pool[:size]: 3` and `accrue_mailers: 3`; scale both together.

```elixir
# config/runtime.exs
config :my_app, Oban,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 3  # matches ChromicPDF session_pool[:size]
  ]
```

### Docker / container notes

ChromicPDF requires Chrome or Chromium on the host image (Chrome ≥ 91
for full-page screenshot features; core rendering works on older).
For PDF/A archival output, Ghostscript is additionally required.
On Alpine, install `chromium` and `ghostscript` in the image; on
Debian-slim, `chromium` + `fonts-liberation` gets you sane defaults.

If your target image cannot ship Chromium (smallest Alpine,
distroless, some serverless platforms), use `Accrue.PDF.Null` and
fall back to the Stripe-hosted invoice URL path described below.

## `Accrue.PDF.Null` graceful degradation {#null-adapter}

`Accrue.PDF.Null` is the escape hatch for Chrome-hostile deploys.
It implements `@behaviour Accrue.PDF` but never renders:

```elixir
iex> Accrue.PDF.render("<html/>", [])
{:error, %Accrue.Error.PdfDisabled{reason: :adapter_disabled, docs_url: "..."}}
```

### How the invoice email worker handles it

The invoice email worker (`Accrue.Workers.Mailer` with
`Accrue.Emails.InvoicePaid`) pattern-matches on the tagged error and
falls through to appending the Stripe `hosted_invoice_url` as a link
in the email body instead of attaching a rendered binary:

```elixir
case Accrue.PDF.Invoice.render(invoice_id) do
  {:ok, pdf_binary} ->
    email
    |> Swoosh.Email.attachment(
      Swoosh.Attachment.new(
        {:data, pdf_binary},
        filename: "invoice-#{invoice.number}.pdf",
        content_type: "application/pdf"
      )
    )

  {:error, %Accrue.Error.PdfDisabled{}} ->
    # Expected, terminal — NOT a transient retry. Log at :debug,
    # attach the hosted link instead.
    Swoosh.Email.assign(email, :invoice_link, invoice.hosted_invoice_url)
end
```

The adapter logs the skip at `:debug` only. Oban workers must NOT
treat `%Accrue.Error.PdfDisabled{}` as a transient failure — it is
stable configuration, not an outage.

## Custom adapter: Gotenberg sidecar

When ChromicPDF is not viable (no Chromium in the image, locked-down
container, hard size budget), the idiomatic alternative is to run
[Gotenberg](https://gotenberg.dev) as a sidecar service and POST HTML
to its REST API from a custom adapter. The following example is
illustrative — **Gotenberg is not a first-party adapter in v1.0**.
Copy-paste, adjust to your HTTP client and endpoint shape, and point
`:pdf_adapter` at your module.

```elixir
defmodule MyApp.PDF.Gotenberg do
  @moduledoc """
  Illustrative, not first-party. `@behaviour Accrue.PDF` adapter that
  POSTs HTML to a Gotenberg sidecar and returns the rendered PDF
  binary. Useful when the host image cannot ship Chromium.
  """

  @behaviour Accrue.PDF

  @finch MyApp.Finch
  @endpoint "http://gotenberg:3000/forms/chromium/convert/html"

  @impl true
  def render(html, opts) when is_binary(html) and is_list(opts) do
    boundary = "gotenberg-#{System.unique_integer([:positive])}"

    body =
      [
        {"files", html, {"form-data", [{"name", "index.html"}, {"filename", "index.html"}]},
         [{"content-type", "text/html"}]}
      ]
      |> multipart(boundary)

    headers = [{"content-type", "multipart/form-data; boundary=#{boundary}"}]

    case Finch.build(:post, @endpoint, headers, body) |> Finch.request(@finch) do
      {:ok, %{status: 200, body: pdf}} -> {:ok, pdf}
      {:ok, %{status: status, body: err}} -> {:error, {:gotenberg, status, err}}
      {:error, reason} -> {:error, {:gotenberg_transport, reason}}
    end
  end

  defp multipart(_parts, _boundary), do: "..." # host-specific encoding
end
```

Wire it in:

```elixir
# config/runtime.exs
config :accrue, :pdf_adapter, MyApp.PDF.Gotenberg
```

When to choose Gotenberg over ChromicPDF:

- Host image cannot bundle Chromium (smallest Alpine, distroless).
- Locked-down containers that forbid `execve` of subprocess browsers.
- A central PDF service already exists in the fleet.
- You want horizontal PDF rendering separated from BEAM capacity.

When to stay on ChromicPDF:

- Standard Phoenix deployments with control over the base image.
- Single-node or small-fleet SaaS where the sidecar cost is pure
  overhead.
- Latency-sensitive renders (ChromicPDF persistent pool ≈ 50ms;
  Gotenberg adds a network hop).

## `@page` CSS warning (Pitfall 6)

ChromicPDF does **not** interpret `@page` CSS rules. Setting page
size, margins, or paper dimensions via a stylesheet has no effect —
the output will silently use ChromicPDF's defaults.

**Wrong:**

```css
/* Ignored by ChromicPDF — do NOT do this. */
@page {
  size: A4 portrait;
  margin: 20mm 15mm;
}
```

**Right:** pass paper options through the adapter `opts`:

```elixir
Accrue.PDF.render(html,
  size: :a4,
  paper_width: 8.27,
  paper_height: 11.69,
  margin_top: 0.5,
  margin_bottom: 0.5,
  margin_left: 0.4,
  margin_right: 0.4
)
```

For explicit page breaks inside content, use the CSS `page-break-*`
properties (`page-break-before: always;` works as expected inside the
printed document, just not `@page` at the top level).

## Font strategy

Webfonts via `<link rel="stylesheet" href="https://fonts.googleapis.com/...">`
are unreliable under headless Chromium — the fetch may race the render
deadline. The recommended pattern is to base64-embed the font bytes
directly into the HTML via `@font-face` `src: url(data:...)`:

```html
<style>
  @font-face {
    font-family: "Inter";
    font-weight: 400;
    src: url(data:font/woff2;base64,d09GMgABAAAAA...) format("woff2");
  }
  body { font-family: "Inter", sans-serif; }
</style>
```

Keep the embedded font files small — a single weight is usually
enough for an invoice. If you do not need a custom typeface, the
default `Accrue.Config.branding/0` `:font_stack`
(`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`)
renders cleanly on every platform Chromium ships on, with zero
embedding overhead. That is the recommended default for v1.0.

## See also

- `Accrue.PDF` — behaviour + facade module docs
- `Accrue.PDF.ChromicPDF` — production adapter
- `Accrue.PDF.Null` — disabled adapter
- `Accrue.Error.PdfDisabled` — tagged error returned by `Null`
- `Accrue.Storage` — storage behaviour for persisted PDFs
