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

  test "items include label, href, icon, and group keys expected by Sidebar" do
    [first | _] = Nav.items("/billing", "/billing")

    assert Map.has_key?(first, :label)
    assert Map.has_key?(first, :href)
    assert Map.has_key?(first, :icon)
    assert Map.has_key?(first, :group)
    assert first.href == "/billing"
    # Home stands alone with no group label.
    assert first.group == nil
  end

  test "groups follow the operator's mental model (Phase 169 regroup)" do
    items = Nav.items("/billing", "/billing")

    assert Enum.find(items, &(&1.label == "Customers")).group == "Billing"
    assert Enum.find(items, &(&1.label == "Invoices")).group == "Billing"
    assert Enum.find(items, &(&1.label == "Recovery")).group == "Recovery"
    assert Enum.find(items, &(&1.label == "Webhooks")).group == "Developer"
    assert Enum.find(items, &(&1.label == "Event log")).group == "Developer"
    assert Enum.find(items, &(&1.label == "Coupons")).group == "Catalog"
    assert Enum.find(items, &(&1.label == "Promotion codes")).group == "Catalog"
    assert Enum.find(items, &(&1.label == "Connect")).group == "Connect"
    assert Enum.find(items, &(&1.label == "Payments")).href == "/billing/charges"
    assert Enum.find(items, &(&1.label == "Recovery")).href == "/billing/analytics/recovery"
  end
end
