defmodule Accrue.Emails.DunningStepEmailsTest do
  @moduledoc """
  Phase 128 Plan 04 Task 1 (D-01, D-02): render coverage for the two new
  dunning-step email templates — `Accrue.Emails.DunningActionRequired`
  (step-2, firmer) and `Accrue.Emails.DunningFinalNotice` (step-3,
  urgent/last-chance). Each deep-links the portal update-payment-method
  flow via the `@update_pm_url` CTA, cloning the `CardExpiringSoon`
  convention.
  """
  use ExUnit.Case, async: true

  alias Accrue.Emails.DunningActionRequired
  alias Accrue.Emails.DunningFinalNotice

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
      to: "jo@acme.test",
      update_pm_url: "https://acme.test/portal/update-payment-method"
    }
  end

  for mod <- [DunningActionRequired, DunningFinalNotice] do
    @mod mod

    test "#{inspect(mod)} module is loaded" do
      assert Code.ensure_loaded?(@mod)
    end

    test "#{inspect(mod)} subject/1 returns binary" do
      assert is_binary(@mod.subject(fixture()))
    end

    test "#{inspect(mod)} subject/1 fallback on empty assigns" do
      assert is_binary(@mod.subject(%{}))
    end

    test "#{inspect(mod)} render/1 returns non-empty HTML with the portal CTA" do
      html = @mod.render(fixture())
      assert is_binary(html)
      assert html != ""
      # The portal update-payment-method CTA URL must be present.
      assert html =~ "https://acme.test/portal/update-payment-method"
    end

    test "#{inspect(mod)} render_text/1 returns non-empty text mentioning branding" do
      text = @mod.render_text(fixture())
      assert is_binary(text)
      assert text != ""
      assert text =~ "Acme"
    end

    test "#{inspect(mod)} carries no PDF attachment intent in render" do
      # These step emails carry no invoice PDF; render must not require one.
      assert is_binary(@mod.render(fixture()))
    end
  end

  test "DunningActionRequired stamps the :dunning_action_required Mailglass function" do
    msg = DunningActionRequired.message(fixture())
    assert msg.mailable_function == :dunning_action_required
  end

  test "DunningFinalNotice stamps the :dunning_final_notice Mailglass function" do
    msg = DunningFinalNotice.message(fixture())
    assert msg.mailable_function == :dunning_final_notice
  end
end
