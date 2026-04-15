defmodule Accrue.Emails.InvoicePaidTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.InvoicePaid

  defp fixture do
    %{
      context: %{
        branding: [
          business_name: "Acme",
          from_email: "no-reply@acme.test",
          support_email: "support@acme.test",
          font_stack: "Helvetica, Arial, sans-serif",
          logo_url: nil,
          company_address: nil,
          accent_color: "#1F6FEB",
          secondary_color: "#6B7280"
        ],
        customer: %{name: "Jo", email: "jo@acme.test"},
        invoice: %{
          number: "INV-2",
          hosted_invoice_url: "https://example.test/invoices/in_2"
        },
        line_items: [
          %{description: "Pro plan", quantity: 1, amount_minor: 2000}
        ],
        currency: :usd,
        locale: "en",
        formatted_total: "$20.00",
        formatted_subtotal: "$20.00",
        formatted_discount: nil,
        formatted_tax: nil
      },
      subject: "Payment received",
      preview: "Thanks!"
    }
  end

  test "module loaded" do
    assert Code.ensure_loaded?(InvoicePaid)
  end

  test "subject references invoice number" do
    assert InvoicePaid.subject(fixture()) =~ "INV-2"
  end

  test "subject fallback" do
    assert is_binary(InvoicePaid.subject(%{}))
  end

  test "render/1 is HTML with MSO conditionals" do
    html = InvoicePaid.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 contains total + line items" do
    html = InvoicePaid.render(fixture())
    assert html =~ "$20.00"
    assert html =~ "INV-2"
    assert html =~ "Pro plan"
  end

  test "render_text/1 plain confirmation" do
    text = InvoicePaid.render_text(fixture())
    refute text =~ ~r/<html|<body/i
    assert text =~ "$20.00"
    assert text =~ "INV-2"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(InvoicePaid.render(fixture())) =~ "unsubscribe"
    refute String.downcase(InvoicePaid.render_text(fixture())) =~ "unsubscribe"
  end
end
