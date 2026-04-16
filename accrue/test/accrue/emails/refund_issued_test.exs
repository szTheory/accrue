defmodule Accrue.Emails.RefundIssuedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.RefundIssued

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
        refund: %{
          id: "re_1",
          formatted_amount: "$10.00",
          formatted_stripe_fee_refunded: "$0.30",
          formatted_merchant_loss: "$0.00"
        },
        charge: %{id: "ch_1"}
      },
      subject: "Refund issued",
      preview: "We refunded your payment"
    }
  end

  test "module loaded" do
    assert Code.ensure_loaded?(RefundIssued)
  end

  test "subject references refund" do
    assert is_binary(RefundIssued.subject(fixture()))
    assert RefundIssued.subject(fixture()) =~ "efund"
  end

  test "render/1 is HTML with MSO conditionals" do
    html = RefundIssued.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 contains fee breakdown (MAIL-12)" do
    html = RefundIssued.render(fixture())
    assert html =~ "$10.00"
    assert html =~ "$0.30"
    assert html =~ "$0.00"
    assert String.downcase(html) =~ "merchant loss"
    assert String.downcase(html) =~ "stripe fee"
  end

  test "render_text/1 contains fee breakdown labels (MAIL-12)" do
    text = RefundIssued.render_text(fixture())
    refute text =~ ~r/<html|<body/i
    assert text =~ "$10.00"
    assert text =~ "$0.30"

    assert String.downcase(text) =~ "merchant_loss" or
             String.downcase(text) =~ "merchant loss"

    assert String.downcase(text) =~ "stripe_fee_refunded" or
             String.downcase(text) =~ "stripe fee"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(RefundIssued.render(fixture())) =~ "unsubscribe"
    refute String.downcase(RefundIssued.render_text(fixture())) =~ "unsubscribe"
  end
end
