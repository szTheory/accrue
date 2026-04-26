defmodule Accrue.Emails.InvoicePaymentFailedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.InvoicePaymentFailed

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
          number: "INV-3",
          hosted_invoice_url: "https://example.test/invoices/in_3"
        },
        formatted_total: "$30.00"
      },
      subject: "Payment failed",
      preview: "Action required"
    }
  end

  test "module loaded" do
    assert Code.ensure_loaded?(InvoicePaymentFailed)
  end

  test "message/1 returns a Mailglass message" do
    message = InvoicePaymentFailed.message(fixture())

    assert %Mailglass.Message{} = message
    assert message.swoosh_email.subject == InvoicePaymentFailed.subject(fixture())
  end

  test "subject is action-required" do
    s = InvoicePaymentFailed.subject(fixture())
    assert String.downcase(s) =~ "action required" or String.downcase(s) =~ "failed"
    assert s =~ "INV-3"
  end

  test "subject fallback" do
    assert is_binary(InvoicePaymentFailed.subject(%{}))
  end

  test "render/1 is HTML with MSO conditionals" do
    html = InvoicePaymentFailed.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 contains total + hosted_invoice_url (MAIL-09)" do
    html = InvoicePaymentFailed.render(fixture())
    assert html =~ "$30.00"
    assert html =~ "https://example.test/invoices/in_3"
  end

  test "render_text/1 contains hosted_invoice_url link (MAIL-09)" do
    text = InvoicePaymentFailed.render_text(fixture())
    refute text =~ ~r/<html|<body/i
    assert text =~ "https://example.test/invoices/in_3"
    assert text =~ "$30.00"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(InvoicePaymentFailed.render(fixture())) =~ "unsubscribe"
    refute String.downcase(InvoicePaymentFailed.render_text(fixture())) =~ "unsubscribe"
  end
end
