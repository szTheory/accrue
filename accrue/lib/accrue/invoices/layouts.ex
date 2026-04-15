defmodule Accrue.Invoices.Layouts do
  @moduledoc """
  HEEx layout wrappers for PDF (and optionally, shared email shells).

  `print_shell/1` assembles the four `Accrue.Invoices.Components` into
  a standalone HTML document suitable for ChromicPDF input.

  ## Paper size via adapter options, NOT CSS paper rules (Pitfall 6)

  Chromium reliably honors the ChromicPDF `print_to_pdf` options for
  paper size / margins (`:paper_width`, `:paper_height`, `:margin_top`,
  etc.), and does NOT reliably honor CSS paper-size rules. The layout
  therefore ships print-friendly CSS (`body { margin: 0 }`,
  `page-break-inside: avoid` on line-item rows) — paper size is a
  property of the PDF adapter call, not the template.

  See `accrue/guides/pdf.md` for the full pitfall writeup.
  """

  use Phoenix.Component

  import Accrue.Invoices.Components

  attr(:context, :map, required: true)

  def print_shell(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Invoice #<%= @context.invoice.number %></title>
        <style>
          body {
            margin: 0;
            padding: 24px;
            font-family: <%= @context.branding[:font_stack] || "Helvetica, Arial, sans-serif" %>;
            color: #111827;
            background: #ffffff;
          }
          table { border-collapse: collapse; }
          tr { page-break-inside: avoid; }
        </style>
      </head>
      <body>
        <.invoice_header context={@context} />
        <.line_items context={@context} />
        <.totals context={@context} />
        <.footer context={@context} />
      </body>
    </html>
    """
  end
end
