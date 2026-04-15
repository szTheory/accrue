defmodule Accrue.Emails.ReceiptTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.Receipt

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
        invoice: %{number: "INV-1"},
        formatted_total: "$10.00"
      },
      subject: "Receipt from Acme",
      preview: "Receipt"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(Receipt)
  end

  test "subject/1 references business name" do
    assert Receipt.subject(fixture()) =~ "Acme"
  end

  test "subject/1 fallback" do
    assert is_binary(Receipt.subject(%{}))
  end

  test "render/1 has MSO conditionals" do
    html = Receipt.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 contains total + invoice number" do
    html = Receipt.render(fixture())
    assert html =~ "$10.00"
    assert html =~ "INV-1"
  end

  test "render_text/1 has branding + total + invoice" do
    text = Receipt.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ "$10.00"
    assert text =~ "INV-1"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(Receipt.render(fixture())) =~ "unsubscribe"
    refute String.downcase(Receipt.render_text(fixture())) =~ "unsubscribe"
  end

  test "legacy Accrue.Emails.PaymentSucceeded still exists and is distinct" do
    assert Code.ensure_loaded?(Accrue.Emails.PaymentSucceeded)
    refute Accrue.Emails.PaymentSucceeded == Receipt
  end
end
