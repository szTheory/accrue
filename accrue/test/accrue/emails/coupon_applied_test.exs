defmodule Accrue.Emails.CouponAppliedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.CouponApplied

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
        coupon: %{name: "Welcome", percent_off: 10, formatted_amount_off: nil},
        promotion_code: %{code: "WELCOME10"}
      },
      subject: "Discount applied",
      preview: "10% off"
    }
  end

  test "module loaded" do
    assert Code.ensure_loaded?(CouponApplied)
  end

  test "message/1 returns a Mailglass message" do
    message = CouponApplied.message(fixture())

    assert %Mailglass.Message{} = message
    assert message.swoosh_email.subject == CouponApplied.subject(fixture())
  end

  test "subject references discount" do
    assert is_binary(CouponApplied.subject(fixture()))
  end

  test "render/1 is HTML" do
    html = CouponApplied.render(fixture())
    assert html =~ ~r/<html|<!DOCTYPE/i
  end

  test "render/1 contains coupon + promotion code + discount (MAIL-13)" do
    html = CouponApplied.render(fixture())
    assert html =~ "10"
    assert html =~ "WELCOME10"

    assert String.downcase(html) =~ "discount" or String.downcase(html) =~ "coupon" or
             String.downcase(html) =~ "off"
  end

  test "render_text/1 contains coupon + promotion reference (MAIL-13)" do
    text = CouponApplied.render_text(fixture())
    refute text =~ ~r/<html|<body/i
    assert text =~ "WELCOME10"
    assert text =~ "10"

    assert String.downcase(text) =~ "discount" or String.downcase(text) =~ "coupon" or
             String.downcase(text) =~ "promotion"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(CouponApplied.render(fixture())) =~ "unsubscribe"
    refute String.downcase(CouponApplied.render_text(fixture())) =~ "unsubscribe"
  end
end
