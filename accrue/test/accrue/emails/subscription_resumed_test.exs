defmodule Accrue.Emails.SubscriptionResumedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.SubscriptionResumed

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
        customer: %{name: "Jo"},
        subscription: %{id: "sub_1"}
      },
      subject: "Your subscription has resumed",
      preview: "Subscription resumed"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(SubscriptionResumed)
  end

  test "subject/1 binary" do
    assert is_binary(SubscriptionResumed.subject(fixture()))
  end

  test "subject/1 fallback" do
    assert is_binary(SubscriptionResumed.subject(%{}))
  end

  test "render/1 is HTML" do
    html = SubscriptionResumed.render(fixture())
    assert html =~ ~r/<html|<!DOCTYPE/i
  end

  test "render/1 mentions resumed" do
    html = SubscriptionResumed.render(fixture())
    assert html =~ ~r/resumed/i
  end

  test "render_text/1 mentions resumed + branding" do
    text = SubscriptionResumed.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ ~r/resumed/i
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(SubscriptionResumed.render(fixture())) =~ "unsubscribe"
    refute String.downcase(SubscriptionResumed.render_text(fixture())) =~ "unsubscribe"
  end
end
