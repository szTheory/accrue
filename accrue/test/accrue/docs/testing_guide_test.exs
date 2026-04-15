defmodule Accrue.Docs.TestingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/testing.md"

  test "testing guide starts with a Fake-first Phoenix scenario before helper reference headings" do
    guide = File.read!(@guide)

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
    assert guide =~ "Accrue.Test.advance_clock"
    assert guide =~ "Accrue.Test.trigger_event"
    assert guide =~ "assert_email_sent"
    assert guide =~ "assert_pdf_rendered"
    assert guide =~ "assert_event_recorded"
    assert guide =~ "Oban.Testing"
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
