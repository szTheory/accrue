defmodule AccrueAdmin.NavTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Nav

  test "Home is first and journey groups preserve operations order" do
    items = Nav.items("/billing", "/billing")
    labels = Enum.map(items, & &1.label)

    assert hd(labels) == "Home"
    assert "Payments" in labels
    assert "Recovery" in labels

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
    assert Map.has_key?(first, :group)
    assert first.href == "/billing"
  end

  test "groups discounts and revenue surfaces for the sidebar" do
    items = Nav.items("/billing", "/billing")

    assert Enum.find(items, &(&1.label == "Coupons")).group == "Discounts"
    assert Enum.find(items, &(&1.label == "Promotion codes")).group == "Discounts"
    assert Enum.find(items, &(&1.label == "Invoices")).group == "Revenue"
    assert Enum.find(items, &(&1.label == "Payments")).href == "/billing/charges"
    assert Enum.find(items, &(&1.label == "Recovery")).href == "/billing/analytics/recovery"
  end
end
