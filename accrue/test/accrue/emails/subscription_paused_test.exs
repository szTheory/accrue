defmodule Accrue.Emails.SubscriptionPausedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.SubscriptionPaused

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
      subject: "Your subscription is paused",
      preview: "Subscription paused",
      pause_behavior: "keep_as_draft"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(SubscriptionPaused)
  end

  test "subject/1 references business" do
    assert is_binary(SubscriptionPaused.subject(fixture()))
  end

  test "subject/1 fallback" do
    assert is_binary(SubscriptionPaused.subject(%{}))
  end

  test "render/1 is HTML" do
    html = SubscriptionPaused.render(fixture())
    assert html =~ ~r/<html|<!DOCTYPE/i
  end

  test "render/1 mentions paused" do
    html = SubscriptionPaused.render(fixture())
    assert html =~ ~r/paused/i
  end

  test "render_text/1 mentions paused + branding" do
    text = SubscriptionPaused.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ ~r/paused/i
  end

  test "no unsubscribe (D6-07)" do
    refute String.downcase(SubscriptionPaused.render(fixture())) =~ "unsubscribe"
    refute String.downcase(SubscriptionPaused.render_text(fixture())) =~ "unsubscribe"
  end
end
