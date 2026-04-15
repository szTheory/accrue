defmodule Accrue.Emails.TrialEndingTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.TrialEnding

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
      subject: "Your Acme trial is ending soon",
      preview: "Your trial is ending soon",
      days_until_end: 3,
      cta_url: "https://acme.test/billing"
    }
  end

  test "module is loaded" do
    assert Code.ensure_loaded?(TrialEnding)
  end

  test "subject/1 returns non-empty binary with business name" do
    subject = TrialEnding.subject(fixture())
    assert is_binary(subject)
    assert byte_size(subject) > 0
    assert subject =~ "Acme"
  end

  test "subject/1 fallback clause returns binary" do
    assert is_binary(TrialEnding.subject(%{}))
  end

  test "render/1 returns non-empty HTML with MSO conditionals (MAIL-19)" do
    html = TrialEnding.render(fixture())
    assert is_binary(html)
    assert byte_size(html) > 0
    assert html =~ "<!--[if mso"
  end

  test "render/1 contains type-specific copy (trial + days)" do
    html = TrialEnding.render(fixture())
    assert html =~ ~r/trial/i
    assert html =~ ~r/day/i
  end

  test "render_text/1 returns non-empty text with branding" do
    text = TrialEnding.render_text(fixture())
    assert is_binary(text)
    assert byte_size(text) > 0
    assert text =~ "Acme"
    assert text =~ "support@acme.test"
    assert text =~ ~r/trial/i
    assert text =~ ~r/day/i
  end

  test "no unsubscribe text (D6-07)" do
    html = TrialEnding.render(fixture())
    text = TrialEnding.render_text(fixture())
    refute String.downcase(html) =~ "unsubscribe"
    refute String.downcase(text) =~ "unsubscribe"
  end

  test "HEEx escapes customer-supplied HTML in customer name" do
    assigns =
      fixture()
      |> put_in([:context, :customer], %{name: "<script>alert(1)</script>", email: "x@y"})

    html = TrialEnding.render(assigns)
    refute html =~ "<script>alert(1)</script>"
  end
end
