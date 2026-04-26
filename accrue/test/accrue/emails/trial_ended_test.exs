defmodule Accrue.Emails.TrialEndedTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.TrialEnded

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
      subject: "Your Acme trial has ended",
      preview: "Trial ended",
      cta_url: "https://acme.test/billing"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(TrialEnded)
  end

  test "message/1 returns a Mailglass message" do
    message = TrialEnded.message(fixture())

    assert %Mailglass.Message{} = message
    assert message.swoosh_email.subject == TrialEnded.subject(fixture())
  end

  test "subject/1 returns non-empty binary with business name" do
    subject = TrialEnded.subject(fixture())
    assert is_binary(subject)
    assert subject =~ "Acme"
  end

  test "subject/1 fallback clause returns binary" do
    assert is_binary(TrialEnded.subject(%{}))
  end

  test "render/1 returns HTML with MSO conditionals" do
    html = TrialEnded.render(fixture())
    assert is_binary(html)
    assert html =~ "trial"
  end

  test "render/1 includes trial + ended copy" do
    html = TrialEnded.render(fixture())
    assert html =~ ~r/trial/i
    assert html =~ ~r/ended/i
  end

  test "render_text/1 includes trial + ended copy + branding" do
    text = TrialEnded.render_text(fixture())
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ ~r/trial/i
    assert text =~ ~r/ended/i
  end

  test "no unsubscribe (D6-07)" do
    assert is_binary(TrialEnded.render(fixture()))
    refute String.downcase(TrialEnded.render(fixture())) =~ "unsubscribe"
    refute String.downcase(TrialEnded.render_text(fixture())) =~ "unsubscribe"
  end
end
