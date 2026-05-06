defmodule Accrue.InvoiceRenderer.Test do
  @moduledoc false

  @behaviour Accrue.InvoiceRenderer

  alias Accrue.Invoices.RenderContext

  @impl true
  def render(%RenderContext{} = context, opts) do
    send(self(), {:invoice_pdf_rendered, context, opts})
    {:ok, "%PDF-TEST"}
  end
end
