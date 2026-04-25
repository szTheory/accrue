defmodule Accrue.PDF do
  @moduledoc """
  Behaviour + facade for PDF rendering.

  You rarely call this module directly. The typical entry point is
  `Accrue.Invoices.render_invoice_pdf/2`, which renders an invoice to HTML
  and then calls `Accrue.PDF.render/2` under the hood. You interact with
  this module mainly through two concerns:

  1. **Adapter configuration** — choose which backend renders PDFs.
  2. **Test setup** — swap in `Accrue.PDF.Test` so your test suite does not
     require a Chrome binary.

  ## Adapters

  - `Accrue.PDF.ChromicPDF` — production default. Delegates to the host
    application's ChromicPDF instance. **Accrue does NOT start ChromicPDF** —
    the host app must add it to its own supervision tree.
  - `Accrue.PDF.Test` — Chrome-free test adapter. Sends
    `{:pdf_rendered, html, opts}` to `self()` and returns `{:ok, "%PDF-TEST"}`.
    Use in tests to avoid the Chrome binary dependency in CI.

  ## Telemetry

  `[:accrue, :pdf, :render, :start | :stop | :exception]` is emitted with
  metadata `%{size, archival, adapter}`. The HTML body is NEVER placed in
  metadata — it may contain PII.
  """

  @type html :: binary()
  @type opts :: keyword()

  @callback render(html(), opts()) :: {:ok, binary()} | {:error, term()}

  @doc """
  Renders `html` to a PDF binary via the configured adapter.

  ## Options

  - `:size` — paper size (atom or tuple, adapter-specific). Default `:a4`.
  - `:archival` — when `true`, produces PDF/A (long-term archival format).
    ChromicPDF uses `print_to_pdfa/1` in this case.
  - `:header_html`, `:footer_html` — optional header/footer HTML. The
    ChromicPDF adapter translates these to the `:header`/`:footer` keys
    that `ChromicPDF.Template.source_and_options/1` expects.
  """
  @spec render(html(), opts()) :: {:ok, binary()} | {:error, term()}
  def render(html, opts \\ []) when is_binary(html) and is_list(opts) do
    adapter = impl()

    metadata = %{
      size: opts[:size],
      archival: opts[:archival] == true,
      adapter: adapter
    }

    Accrue.Telemetry.span([:accrue, :pdf, :render], metadata, fn ->
      adapter.render(html, opts)
    end)
  end

  @doc false
  def impl, do: Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)
end
