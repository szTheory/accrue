defmodule Accrue.Emails.CardExpiringSoonTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.CardExpiringSoon

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
        customer: %{name: "Jo", email: "jo@acme.test"}
      },
      subject: "Your card is expiring soon",
      preview: "Card expiring soon",
      brand: "visa",
      last4: "4242",
      exp_month: 12,
      exp_year: 2030,
      update_pm_url: "https://acme.test/pm"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(CardExpiringSoon)
  end

  test "subject/1 returns binary" do
    assert is_binary(CardExpiringSoon.subject(fixture()))
  end

  test "subject/1 fallback" do
    assert is_binary(CardExpiringSoon.subject(%{}))
  end

  test "render/1 contains MSO conditionals" do
    html = CardExpiringSoon.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 mentions card + expir + last4" do
    html = CardExpiringSoon.render(fixture())
    assert html =~ ~r/card/i
    assert html =~ ~r/expir/i
    assert html =~ "4242"
  end

  test "render_text/1 mentions card + expir + branding + last4" do
    text = CardExpiringSoon.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ ~r/card/i
    assert text =~ ~r/expir/i
    assert text =~ "4242"
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(CardExpiringSoon.render(fixture())) =~ "unsubscribe"
    refute String.downcase(CardExpiringSoon.render_text(fixture())) =~ "unsubscribe"
  end
end
