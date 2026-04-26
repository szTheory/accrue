defmodule Accrue.Emails.PaymentFailedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.PaymentFailed

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
      subject: "Payment failed",
      preview: "Payment failed",
      update_pm_url: "https://acme.test/pm"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(PaymentFailed)
  end

  test "subject/1 binary" do
    assert is_binary(PaymentFailed.subject(fixture()))
  end

  test "subject/1 fallback" do
    assert is_binary(PaymentFailed.subject(%{}))
  end

  test "message/1 builds a Mailglass payment_failed mailable" do
    msg = PaymentFailed.message(fixture())

    assert msg.mailable == PaymentFailed
    assert msg.mailable_function == :payment_failed
    assert msg.swoosh_email.subject == "Action required: payment failed at Acme"
  end

  test "render/1 MSO conditionals" do
    html = PaymentFailed.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 mentions payment + failed + invoice + update" do
    html = PaymentFailed.render(fixture())
    assert html =~ ~r/payment/i
    assert html =~ ~r/failed/i
    assert html =~ "INV-1"
    assert html =~ ~r/update/i
  end

  test "render_text/1 MAIL-04 retry guidance present" do
    text = PaymentFailed.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ ~r/update/i
    assert text =~ "INV-1"
    assert text =~ "$10.00"
    assert text =~ "https://acme.test/pm"
  end

  test "no unsubscribe and CTA preserved" do
    html = PaymentFailed.render(fixture())
    text = PaymentFailed.render_text(fixture())

    refute String.downcase(html) =~ "unsubscribe"
    refute String.downcase(text) =~ "unsubscribe"
    assert html =~ "Update payment method"
    assert text =~ "Update payment method"
    assert text =~ "https://acme.test/pm"
  end
end
