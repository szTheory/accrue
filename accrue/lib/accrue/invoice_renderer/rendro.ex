defmodule Accrue.InvoiceRenderer.Rendro do
  @moduledoc """
  Native Rendro-backed invoice renderer.

  Builds a deterministic Rendro document from Accrue's invoice render context
  so invoice PDFs no longer require Chrome by default.
  """

  @behaviour Accrue.InvoiceRenderer

  alias Accrue.Invoices.RenderContext

  @body_width 451
  @qty_width 48
  @amount_width 84

  @impl true
  def render(%RenderContext{} = context, _opts) do
    context
    |> build_document()
    |> Rendro.render(deterministic: true)
  end

  defp build_document(%RenderContext{} = context) do
    doc =
      Rendro.Document.new()
      |> Rendro.Document.put_metadata(%Rendro.Metadata{
        title: "Invoice #{context.invoice.number || context.invoice.id}"
      })
      |> Rendro.Document.add_template(page_template())
      |> Rendro.Document.set_template(:accrue_invoice)

    Enum.reduce(sections(context), doc, fn section, acc ->
      Rendro.Document.add_section(acc, section)
    end)
  end

  defp page_template do
    Rendro.page_template(
      name: :accrue_invoice,
      width: 595,
      height: 842,
      margin_top: 32,
      margin_right: 32,
      margin_bottom: 32,
      margin_left: 32,
      regions: [
        Rendro.region(
          name: :header,
          role: :header,
          anchor: :top,
          x: 40,
          y: 40,
          width: 515,
          height: 96
        ),
        Rendro.region(
          name: :body,
          role: :body,
          anchor: :flow,
          x: 40,
          y: 152,
          width: 515,
          height: 566
        ),
        Rendro.region(
          name: :footer,
          role: :footer,
          anchor: :bottom,
          x: 40,
          y: 740,
          width: 515,
          height: 52
        )
      ]
    )
  end

  defp sections(context) do
    [
      header_section(context),
      body_section(context),
      footer_section(context)
    ]
  end

  defp header_section(%RenderContext{} = context) do
    invoice_number = context.invoice.number || context.invoice.id || "draft"
    business_name = context.branding[:business_name] || "Accrue"

    issued_line =
      case context.formatted_issued_at do
        nil -> "Invoice ##{invoice_number}"
        issued_at -> "Invoice ##{invoice_number}  Issued #{issued_at}"
      end

    customer_line =
      case customer_name(context.customer) do
        nil -> nil
        name -> "Bill to #{name}"
      end

    content =
      [
        Rendro.block(Rendro.text(business_name, size: 18)),
        Rendro.block(Rendro.text(issued_line, size: 11))
      ]
      |> maybe_append_text(customer_line, 11)

    Rendro.section(name: :accrue_invoice_header, region: :header, content: content)
  end

  defp body_section(%RenderContext{} = context) do
    rows =
      Enum.map(context.line_items || [], fn item ->
        [
          to_string(item.description || ""),
          to_string(item.quantity || 1),
          Accrue.Invoices.Render.format_money(
            item.amount_minor || 0,
            context.currency,
            context.locale
          )
        ]
      end)

    body_content =
      [
        Rendro.block(
          Rendro.table(rows,
            header: ["Description", "Qty", "Amount"],
            columns: [
              {:fixed, @body_width - @qty_width - @amount_width},
              {:fixed, @qty_width},
              {:fixed, @amount_width}
            ]
          )
        ),
        text_block(total_line(context), 12),
        text_block(subtotal_line(context), 10),
        text_block(discount_line(context), 10),
        text_block(tax_line(context), 10)
      ]
      |> Enum.reject(&is_nil/1)

    Rendro.section(name: :accrue_invoice_body, region: :body, content: body_content)
  end

  defp footer_section(%RenderContext{} = context) do
    support_line =
      [
        context.branding[:business_name] || "Accrue",
        context.branding[:support_email]
      ]
      |> Enum.reject(&is_nil_or_empty?/1)
      |> Enum.join(" - ")

    content =
      [Rendro.block(Rendro.text(support_line, size: 9))]
      |> maybe_append_text(context.branding[:company_address], 9)

    Rendro.section(name: :accrue_invoice_footer, region: :footer, content: content)
  end

  defp maybe_append_text(blocks, nil, _size), do: blocks
  defp maybe_append_text(blocks, "", _size), do: blocks

  defp maybe_append_text(blocks, text, size) do
    blocks ++ [Rendro.block(Rendro.text(text, size: size))]
  end

  defp text_block(nil, _size), do: nil
  defp text_block("", _size), do: nil
  defp text_block(text, size), do: Rendro.block(Rendro.text(text, size: size))

  defp total_line(%RenderContext{formatted_total: total}) when is_binary(total),
    do: "Total #{total}"

  defp subtotal_line(%RenderContext{formatted_subtotal: nil}), do: nil
  defp subtotal_line(%RenderContext{formatted_subtotal: subtotal}), do: "Subtotal #{subtotal}"

  defp discount_line(%RenderContext{formatted_discount: nil}), do: nil
  defp discount_line(%RenderContext{formatted_discount: discount}), do: "Discount -#{discount}"

  defp tax_line(%RenderContext{formatted_tax: nil}), do: nil
  defp tax_line(%RenderContext{formatted_tax: tax}), do: "Tax #{tax}"

  defp customer_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp customer_name(%{email: email}) when is_binary(email) and email != "", do: email
  defp customer_name(_), do: nil

  defp is_nil_or_empty?(value), do: is_nil(value) or value == ""
end
