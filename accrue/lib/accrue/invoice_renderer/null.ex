defmodule Accrue.InvoiceRenderer.Null do
  @moduledoc """
  Null invoice renderer for Chrome-hostile or PDF-disabled deploys.
  """

  @behaviour Accrue.InvoiceRenderer

  alias Accrue.Error.PdfDisabled
  alias Accrue.Invoices.RenderContext

  require Logger

  @impl true
  def render(%RenderContext{}, _opts) do
    Logger.debug("Accrue.InvoiceRenderer.Null: skipping invoice PDF render (adapter disabled)")

    {:error,
     %PdfDisabled{
       reason: :adapter_disabled,
       docs_url: "https://hexdocs.pm/accrue/pdf.html#null-adapter"
     }}
  end
end
