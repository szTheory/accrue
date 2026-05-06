defmodule Accrue.InvoiceRenderer.ChromicPDF do
  @moduledoc """
  Invoice renderer that preserves the existing HEEx-to-ChromicPDF path.

  This remains the optional first-party fallback for hosts that explicitly
  prefer the older HTML-based invoice rendering story.
  """

  @behaviour Accrue.InvoiceRenderer

  alias Accrue.Invoices.{Layouts, RenderContext}

  @impl true
  def render(%RenderContext{} = context, opts) when is_list(opts) do
    html =
      Layouts.print_shell(%{context: context})
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    Accrue.PDF.ChromicPDF.render(html, chromic_opts(opts))
  end

  defp chromic_opts(opts) do
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
end
