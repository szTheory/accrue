defmodule AccrueAdmin.NavTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Nav

  test "Home is first and Webhooks precedes Event log" do
    items = Nav.items("/billing", "/billing")
    labels = Enum.map(items, & &1.label)

    assert hd(labels) == "Home"

    webhooks_idx = Enum.find_index(labels, &(&1 == "Webhooks"))
    events_idx = Enum.find_index(labels, &(&1 == "Event log"))

    assert is_integer(webhooks_idx) and is_integer(events_idx)
    assert webhooks_idx < events_idx
  end

  test "items include href and eyebrow keys expected by Sidebar" do
    [first | _] = Nav.items("/billing", "/billing")

    assert Map.has_key?(first, :label)
    assert Map.has_key?(first, :href)
    assert Map.has_key?(first, :eyebrow)
    assert first.href == "/billing"
  end
end
