defmodule Accrue.Emails.InvoiceFinalizedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.InvoiceFinalized

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
          number: "INV-1",
          hosted_invoice_url: "https://example.test/invoices/in_1"
        },
        line_items: [
          %{description: "Pro plan", quantity: 1, amount_minor: 2000},
          %{description: "Extra seat", quantity: 3, amount_minor: 900}
        ],
        currency: :usd,
        locale: "en",
        formatted_total: "$29.00",
        formatted_subtotal: "$29.00",
        formatted_discount: nil,
        formatted_tax: nil
      },
      subject: "Invoice available",
      preview: "Your invoice is ready"
    }
  end

  test "module loaded" do
    assert Code.ensure_loaded?(InvoiceFinalized)
  end

  test "message/1 returns a Mailglass message" do
    message = InvoiceFinalized.message(fixture())

    assert %Mailglass.Message{} = message
    assert message.swoosh_email.subject == InvoiceFinalized.subject(fixture())
  end

  test "subject references invoice number + business" do
    s = InvoiceFinalized.subject(fixture())
    assert s =~ "Acme" or s =~ "INV-1"
  end

  test "subject fallback" do
    assert is_binary(InvoiceFinalized.subject(%{}))
  end

  test "render/1 is HTML" do
    html = InvoiceFinalized.render(fixture())
    assert html =~ ~r/<html|<!DOCTYPE/i
  end

  test "render/1 contains formatted total + invoice number + line items" do
    html = InvoiceFinalized.render(fixture())
    assert html =~ "$29.00"
    assert html =~ "INV-1"
    assert html =~ "Pro plan"
    assert html =~ "Extra seat"
  end

  test "render_text/1 is plain text" do
    text = InvoiceFinalized.render_text(fixture())
    refute text =~ ~r/<html|<body|<script/i
    assert text =~ "Acme"
    assert text =~ "$29.00"
    assert text =~ "INV-1"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(InvoiceFinalized.render(fixture())) =~ "unsubscribe"
    refute String.downcase(InvoiceFinalized.render_text(fixture())) =~ "unsubscribe"
  end

  test "escapes customer name injection" do
    ctx = put_in(fixture(), [:context, :customer, :name], "<script>alert(1)</script>")
    html = InvoiceFinalized.render(ctx)
    refute html =~ "<script>alert(1)</script>"
  end
end
