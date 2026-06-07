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
    # Updated to /payments (IA-06 route reshape)
    assert Enum.find(items, &(&1.label == "Payments")).href == "/billing/payments"
    assert Enum.find(items, &(&1.label == "Recovery")).href == "/billing/analytics/recovery"
  end

  # --- Phase 175-02: badge/collapsible contract ---

  test "items/3 with recovery > 0 returns Recovery group item with badge and collapsible: true" do
    items = Nav.items("/billing", "/billing", %{recovery: 2, developer: 0})
    recovery = Enum.find(items, &(&1.label == "Recovery"))
    assert recovery.badge == 2
    assert recovery.collapsible == true
  end

  test "items/3 with recovery == 0 returns Recovery group item with badge: nil" do
    items = Nav.items("/billing", "/billing", %{recovery: 0, developer: 0})
    recovery = Enum.find(items, &(&1.label == "Recovery"))
    assert recovery.badge == nil
    assert recovery.collapsible == true
  end

  test "items/2 backward compat call still works" do
    items = Nav.items("/billing", "/billing")
    assert is_list(items)
    assert [_ | _] = items
    # All items must have badge and collapsible keys
    Enum.each(items, fn item ->
      assert Map.has_key?(item, :badge)
      assert Map.has_key?(item, :collapsible)
    end)
  end

  test "Payments leaf href contains /payments not /charges" do
    items = Nav.items("/billing", "/billing")
    payments = Enum.find(items, &(&1.label == "Payments"))
    assert String.contains?(payments.href, "/payments")
    refute String.contains?(payments.href, "/charges")
  end

  test "Billing group items have collapsible: false" do
    items = Nav.items("/billing", "/billing", %{recovery: 5, developer: 3})
    billing_items = Enum.filter(items, &(&1.group == "Billing"))
    assert [_ | _] = billing_items

    Enum.each(billing_items, fn item ->
      assert item.collapsible == false,
             "Expected Billing item '#{item.label}' to have collapsible: false"
    end)
  end
end
