defmodule Accrue.InvoiceRenderer do
  @moduledoc """
  Behaviour + facade for invoice-specific PDF rendering.

  This seam is intentionally narrower than `Accrue.PDF`: invoice rendering
  starts from `Accrue.Invoices.RenderContext`, not from raw HTML.
  That lets Accrue use a native document engine like Rendro by default while
  preserving the legacy HTML-based `Accrue.PDF` contract for ChromicPDF and
  custom callers.
  """

  alias Accrue.Invoices.RenderContext

  @type opts :: keyword()

  @callback render(RenderContext.t(), opts()) :: {:ok, binary()} | {:error, term()}

  @spec render(RenderContext.t(), opts()) :: {:ok, binary()} | {:error, term()}
  def render(%RenderContext{} = context, opts \\ []) when is_list(opts) do
    impl().render(context, opts)
  end

  @spec impl() :: module()
  def impl do
    Application.get_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Rendro)
  end
end
