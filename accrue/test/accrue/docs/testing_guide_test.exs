defmodule Accrue.Docs.TestingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/testing.md"

  test "testing guide starts with a Fake-first Phoenix scenario before helper reference headings" do
    guide = File.read!(@guide)

    assert guide =~ "# Testing Accrue Billing Flows"
    assert guide =~ "## Fake-first Phoenix scenario"

    fake_first = index_of(guide, "Fake-first")
    helper_reference = index_of(guide, "Helper reference") || index_of(guide, "Helpers")

    assert fake_first
    assert helper_reference
    assert fake_first < helper_reference
    assert guide =~ "Phoenix"
  end

  test "testing guide contains copy-paste public helper strings" do
    guide = File.read!(@guide)

    assert guide =~ "use Accrue.Test"
    assert guide =~ "Oban.Testing"
    assert guide =~ ~s|Accrue.Test.advance_clock(subscription, "1 month")|
    assert guide =~ "Accrue.Test.trigger_event(:invoice_payment_failed, invoice)"
    assert guide =~ "assert_email_sent(:receipt, to: user.email)"
    assert guide =~ "assert_pdf_rendered(invoice)"
    assert guide =~ "assert_event_recorded(user, type: :subscription_created)"
    assert guide =~ "MyApp.Billing"
  end

  test "testing guide covers required scenario and provider topics" do
    guide = File.read!(@guide)

    for phrase <- [
          "successful checkout",
          "trial conversion",
          "failed renewal",
          "cancellation/grace period",
          "invoice email/PDF",
          "webhook replay",
          "background jobs",
          "provider-parity",
          "Stripe test clocks",
          "3DS cards",
          "live webhook forwarding"
        ] do
      assert guide =~ phrase
    end
  end

  test "testing guide keeps Phase 9 release docs out of scope" do
    guide = File.read!(@guide)

    refute guide =~ "README quickstart"
    refute guide =~ "Release Please"
    refute guide =~ "Hex publishing"
    refute guide =~ "GitHub Actions release"
  end

  test "testing guide positions Fake tests before external providers" do
    guide = File.read!(@guide)

    fake_first = index_of(guide, "## Fake-first Phoenix scenario")
    external_provider = index_of(guide, "## External-provider appendix")

    assert fake_first
    assert external_provider
    assert fake_first < external_provider
  end

  test "testing guide warns against sleeps and real Stripe sandbox calls by default" do
    guide = File.read!(@guide)

    assert guide =~ "Process.sleep"
    assert guide =~ "Stripe sandbox"
    assert guide =~ "real Stripe sandbox calls"
  end

  defp index_of(binary, pattern) do
    case :binary.match(binary, pattern) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
