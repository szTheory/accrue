defmodule Accrue.Emails.SubscriptionCanceledTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.SubscriptionCanceled

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
        subscription: %{id: "sub_1", current_period_end: "2026-05-01"}
      },
      subject: "Your Acme subscription has been canceled",
      preview: "Subscription canceled"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(SubscriptionCanceled)
  end

  test "subject/1 references business name" do
    assert SubscriptionCanceled.subject(fixture()) =~ "Acme"
  end

  test "subject/1 fallback clause" do
    assert is_binary(SubscriptionCanceled.subject(%{}))
  end

  test "render/1 contains MSO conditionals" do
    html = SubscriptionCanceled.render(fixture())
    assert html =~ "<!--[if mso"
  end

  test "render/1 mentions canceled" do
    html = SubscriptionCanceled.render(fixture())
    assert html =~ ~r/cancel(l)?ed/i
  end

  test "render_text/1 mentions canceled + branding" do
    text = SubscriptionCanceled.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ ~r/cancel(l)?ed/i
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(SubscriptionCanceled.render(fixture())) =~ "unsubscribe"
    refute String.downcase(SubscriptionCanceled.render_text(fixture())) =~ "unsubscribe"
  end
end
