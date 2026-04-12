defmodule Accrue.PDF do
  @moduledoc """
  Behaviour + facade for PDF rendering (PDF-01, D-32).

  Callers pass pre-rendered HTML + opts; the adapter returns a binary
  PDF body. Two adapters ship with Phase 1:

  - `Accrue.PDF.ChromicPDF` — production default. Delegates to the host
    application's ChromicPDF instance. **Accrue does NOT start ChromicPDF**
    (D-33, Pitfall #4) — the host app starts it in its own supervision tree.
  - `Accrue.PDF.Test` — Chrome-free test adapter. Sends
    `{:pdf_rendered, html, opts}` to `self()` and returns `{:ok, "%PDF-TEST"}`
    (D-34). Use in tests to avoid Chrome binary dependency.

  ## Telemetry (T-PDF-01)

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
    that `ChromicPDF.Template.source_and_options/1` expects (RESEARCH
    Summary point 5).
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
