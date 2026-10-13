defmodule AccrueAdmin.Components.TimestampTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.Timestamp

  test "renders explicit UTC and keeps the exact microsecond ISO value for copying" do
    instant = DateTime.from_iso8601("2026-10-11T15:04:05.123456Z") |> elem(1)
    html = render_component(&Timestamp.timestamp/1, %{id: "received-at", value: instant})

    assert html =~ "Oct 11, 2026 15:04:05 UTC"
    assert html =~ ~s(data-clipboard-text="2026-10-11T15:04:05.123456Z")
    assert html =~ ~s(data-clipboard-label="timestamp")
    assert html =~ ~s(<time datetime="2026-10-11T15:04:05.123456Z")
    assert html =~ ~s(phx-hook="Clipboard")
    assert html =~ ~s(phx-hook="TimeDisplay")
    assert html =~ "ax-timestamp-copy"
    assert html =~ ~s(data-time-copy-fallback tabindex="0")
  end

  test "normalizes non-UTC DateTime offsets to the same UTC instant before display and copy" do
    utc = DateTime.from_iso8601("2026-10-11T15:04:05.123456Z") |> elem(1)
    offset = %{utc | time_zone: "GMT+5", zone_abbr: "GMT+5", utc_offset: 18_000}
    html = render_component(&Timestamp.timestamp/1, %{id: "received-at-offset", value: offset})

    assert html =~ "Oct 11, 2026 10:04:05 UTC"
    assert html =~ ~s(data-clipboard-text="2026-10-11T10:04:05.123456Z")
    assert html =~ ~s(<time datetime="2026-10-11T10:04:05.123456Z")
  end

  test "missing timestamp renders unavailable text without a copy control" do
    html = render_component(&Timestamp.timestamp/1, %{id: "received-at", value: nil})

    assert html =~ "Time unavailable"
    refute html =~ "data-clipboard-text"
    refute html =~ "phx-hook"
  end
end
