defmodule Accrue.Invoices do
  @moduledoc """
  Invoice facade (D6-04). Owns lazy PDF rendering + storage delegation.

  v1.0 persists ZERO PDF bytes — every `render_invoice_pdf/2` call
  re-hydrates the invoice from the current DB state + current branding
  snapshot (roadmap SC #2 — retroactive brand consistency). Hosts that
  need to persist a PDF MUST call `store_invoice_pdf/2` explicitly; it
  is never implicit.

  ## Contract

    * `render_invoice_pdf/2` — returns `{:ok, binary}` on success,
      `{:error, %Accrue.Error.PdfDisabled{}}` when the configured
      adapter is `Accrue.PDF.Null`, and `{:error, :chromic_pdf_not_started}`
      when the configured adapter is `Accrue.PDF.ChromicPDF` but the
      ChromicPDF GenServer is not running in the host supervision tree
      (D6-04 safety net — Pitfall 4).
    * `store_invoice_pdf/2` — renders via `render_invoice_pdf/2` and
      writes the binary to `Accrue.Storage` under the derived key
      `"invoices/<invoice.id>.pdf"`.
    * `fetch_invoice_pdf/1` — reads the binary back from
      `Accrue.Storage`. Returns `{:error, :not_configured}` on the
      `Accrue.Storage.Null` adapter (v1.0 default).

  ## Lazy render rationale

  The `v1.0` design intentionally never persists PDF bytes because:

    1. A PDF is a snapshot of (invoice, branding) at one instant.
       Re-rendering from current DB + current branding preserves
       visual consistency after a logo/brand change.
    2. Storage adapters are pluggable and default to `Null`; forcing a
       PDF cache would mean forcing a storage backend.
    3. ChromicPDF renders a typical invoice in < 200ms — cheaper than
       a DB lookup + byte transfer on most deployments.

  See `Accrue.Invoices.Render.build_assigns/2` for `RenderContext`
  construction and `Accrue.Invoices.Layouts.print_shell/1` for the PDF
  HTML shell.
  """

  alias Accrue.Emails.HtmlBridge
  alias Accrue.Invoices.{Layouts, Render}

  @type invoice_or_id :: Accrue.Billing.Invoice.t() | String.t()

  @doc """
  Renders an invoice to a PDF binary via the configured `Accrue.PDF`
  adapter.

  Accepts either an `%Accrue.Billing.Invoice{}` struct or an invoice
  id string.

  ## Options

    * `:locale` — overrides `customer.preferred_locale` for money +
      date formatting (D6-03 precedence: opts > customer > "en")
    * `:timezone` — overrides `customer.preferred_timezone`
    * `:archival` — when `true`, produces PDF/A (threaded through to
      ChromicPDF's `print_to_pdfa/1`)
    * `:size`, `:paper_width`, `:paper_height`, `:margin_top`,
      `:margin_bottom`, `:margin_left`, `:margin_right` — forwarded
      to the PDF adapter (Pitfall 6: paper size is an adapter option,
      NOT a CSS rule, because Chromium ignores CSS `@page` size)

  ## Return values

    * `{:ok, binary}` — rendered PDF body
    * `{:error, %Accrue.Error.PdfDisabled{}}` — adapter is
      `Accrue.PDF.Null`; caller should fall through to the Stripe
      `hosted_invoice_url` link instead of attaching a PDF
    * `{:error, :chromic_pdf_not_started}` — adapter is
      `Accrue.PDF.ChromicPDF` but the host app has not started
      ChromicPDF in its supervision tree (Accrue does NOT start
      ChromicPDF — D-33). Surfaces as a clear, non-retriable error.
    * `{:error, term}` — any other error raised by `Render.build_assigns/2`
      (e.g., `Ecto.NoResultsError` when the id does not exist) is
      caught and returned as a tagged tuple
  """
  @spec render_invoice_pdf(invoice_or_id(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  def render_invoice_pdf(invoice_or_id, opts \\ []) do
    adapter = Accrue.PDF.impl()

    with :ok <- ensure_adapter_available(adapter),
         {:ok, context} <- safe_build_assigns(invoice_or_id, opts),
         html <- render_shell_html(context),
         {:ok, binary} <- Accrue.PDF.render(html, adapter_opts(opts)) do
      {:ok, binary}
    end
  end

  @doc """
  Renders an invoice and writes the resulting PDF binary to storage
  under the derived key `"invoices/<invoice.id>.pdf"`.

  Returns the canonical storage key on success, the same error tuples
  as `render_invoice_pdf/2` on render failure, or whatever the storage
  adapter returns on write failure.

  On the default `Accrue.Storage.Null` adapter, the key is echoed
  back — no bytes are written.
  """
  @spec store_invoice_pdf(invoice_or_id(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def store_invoice_pdf(invoice_or_id, opts \\ []) do
    with {:ok, binary} <- render_invoice_pdf(invoice_or_id, opts) do
      id = extract_id(invoice_or_id)

      Accrue.Storage.put(
        "invoices/#{id}.pdf",
        binary,
        %{content_type: "application/pdf"}
      )
    end
  end

  @doc """
  Fetches a previously-stored invoice PDF from `Accrue.Storage`.

  Returns `{:error, :not_configured}` on the default `Accrue.Storage.Null`
  adapter. Hosts that enable real storage get the bytes back.
  """
  @spec fetch_invoice_pdf(invoice_or_id()) :: {:ok, binary()} | {:error, term()}
  def fetch_invoice_pdf(invoice_or_id) do
    id = extract_id(invoice_or_id)
    Accrue.Storage.get("invoices/#{id}.pdf")
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  # D6-04 safety net — Pitfall 4. Accrue does NOT start ChromicPDF; if the
  # host app has `Accrue.PDF.ChromicPDF` configured but forgot to add
  # `{ChromicPDF, on_demand: true}` to its supervisor, surface a clear
  # non-retriable error instead of the raw GenServer crash.
  defp ensure_adapter_available(Accrue.PDF.ChromicPDF) do
    if Process.whereis(ChromicPDF) do
      :ok
    else
      {:error, :chromic_pdf_not_started}
    end
  end

  defp ensure_adapter_available(_other), do: :ok

  defp safe_build_assigns(invoice_or_id, opts) do
    {:ok, Render.build_assigns(invoice_or_id, opts)}
  rescue
    e -> {:error, e}
  end

  defp render_shell_html(context) do
    HtmlBridge.render(&Layouts.print_shell/1, %{context: context})
  end

  defp adapter_opts(opts) do
    Keyword.take(opts, [
      :size,
      :paper_width,
      :paper_height,
      :margin_top,
      :margin_bottom,
      :margin_left,
      :margin_right,
      :archival,
      :header_html,
      :footer_html
    ])
  end

  defp extract_id(%{id: id}) when is_binary(id), do: id
  defp extract_id(id) when is_binary(id), do: id
end
