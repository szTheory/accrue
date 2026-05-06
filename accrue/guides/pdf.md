# PDF Rendering

Accrue renders invoice PDFs from the same `Accrue.Invoices.Components`
that power the transactional emails, but the default invoice renderer is now
native Rendro rather than Chrome. The invoice entry point is
`Accrue.Invoices.render_invoice_pdf/2`, which resolves `:invoice_pdf_adapter`
and renders a PDF without requiring a browser process by default.

The older `Accrue.PDF` behaviour still exists for HTML-to-PDF adapters such as
ChromicPDF or a custom Gotenberg sidecar, but it is no longer the primary
invoice path.

If you only read one section: Rendro is the default. Jump to
**ChromicPDF explicit compatibility path** only if you explicitly want the
old HTML-based path.

## Adapters

Invoice rendering ships with three first-party adapters:

| Adapter | When to use | Returns |
| --- | --- | --- |
| `Accrue.InvoiceRenderer.Rendro` | Production default. Native Elixir invoice PDF rendering with no Chrome dependency. | `{:ok, pdf_binary}` |
| `Accrue.InvoiceRenderer.ChromicPDF` | Optional fallback. Preserves the older HTML → Chrome path via a host-supervised `ChromicPDF` pool. | `{:ok, pdf_binary}` |
| `Accrue.InvoiceRenderer.Null` | PDF-disabled / Chrome-hostile deploys. Returns a typed error without rendering. | `{:error, %Accrue.Error.PdfDisabled{}}` |

The invoice renderer is resolved via `:invoice_pdf_adapter`:

```elixir
# config/config.exs
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Rendro

# config/test.exs
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Test
```

If you still need the lower-level HTML seam, `:pdf_adapter` continues to
configure `Accrue.PDF` for ChromicPDF/custom HTML renderers.

## Rendro default

The default path needs no extra supervisor child and no Chrome/Chromium
binary on the host image. That keeps the default install/setup smaller and
easier to maintain.

The main tradeoff is honesty about assets and fonts:

- remote `logo_url` fetching is not part of the Rendro default path
- unsupported glyphs fail explicitly instead of silently degrading
- lazy render semantics are unchanged; Accrue still re-renders from current
  invoice data unless you explicitly store the bytes yourself

## ChromicPDF explicit compatibility path

If you want the previous HTML-based invoice rendering path, switch:

```elixir
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF
```

Accrue still does **not** start ChromicPDF itself. The host app owns the
supervision tree and supervises the pool.

This is an explicit compatibility path. Invoice rendering only switches when
you set `:invoice_pdf_adapter`; Accrue does not infer invoice behavior from
the lower-level `:pdf_adapter` HTML seam.

```elixir
# lib/my_app/application.ex
children = [
  MyApp.Repo,
  {ChromicPDF, on_demand: true},
  MyAppWeb.Endpoint
]
```

Keep `accrue_mailers` queue concurrency less than or equal to the
ChromicPDF pool size if you attach invoice PDFs from mailer jobs.

If this explicit compatibility path is configured without a running
`ChromicPDF` process, `Accrue.Invoices.render_invoice_pdf/2` returns
`{:error, %Accrue.Error.InvoiceRendererUnavailable{adapter: Accrue.InvoiceRenderer.ChromicPDF, reason: :chromic_pdf_not_started}}`.

## Migration

The seam split is explicit:

- `:invoice_pdf_adapter` owns invoice rendering.
- `:pdf_adapter` remains the lower-level `Accrue.PDF` HTML seam.

Invoice rendering does not infer behavior from `:pdf_adapter`. If you are
upgrading, use the host state that matches your app:

### 1. No custom PDF config

If you never customized Accrue's PDF settings, **no action needed**.
Rendro is now the default invoice renderer, so invoice PDFs render without
Chrome on the normal path.

### 2. You only set `:pdf_adapter`

If your host only set `config :accrue, :pdf_adapter, ...`, invoice PDFs no
longer follow that key. Set `:invoice_pdf_adapter` explicitly if you want the
legacy Chrome-backed invoice path:

```elixir
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF
```

Keep `:pdf_adapter` only if you also still use the lower-level HTML seam.

### 3. You use a custom HTML seam

If your host uses a custom `Accrue.PDF` adapter, keep `:pdf_adapter` for that
HTML seam. Invoice rendering remains on the default Rendro path unless you
also set `:invoice_pdf_adapter` explicitly.

That means a host can keep a custom HTML renderer for non-invoice callers
without changing invoice behavior, and a host can choose
`Accrue.InvoiceRenderer.ChromicPDF` only when it intentionally wants the old
invoice path back.

## Null graceful degradation {#null-adapter}

`Accrue.InvoiceRenderer.Null` is the escape hatch for PDF-disabled deploys.
It returns a typed error without rendering:

```elixir
iex> Accrue.Invoices.render_invoice_pdf(invoice)
{:error, %Accrue.Error.PdfDisabled{reason: :adapter_disabled, docs_url: "..."}}
```

The mailer path treats `%Accrue.Error.PdfDisabled{}` as terminal and falls
through to the hosted invoice URL instead of retrying forever.

## `@page` CSS warning (Chromic fallback only)

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
