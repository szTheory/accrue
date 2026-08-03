defmodule Accrue.Entitlements.AppleReconciliationTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.Apple.{Client, Reconciliation}

  @tag :status
  test "the deterministic client preserves status authority and ascending history scripts" do
    fake = Client.Fake.new(
      statuses: [{:ok, [%{transaction: "status-1"}]}],
      history: [
        {:ok, %{signed_transactions: ["page-1"], revision: "r1", has_more: true}},
        {:ok, %{signed_transactions: ["page-2"], revision: "r2", has_more: false}}
      ]
    )

    assert {:ok, [%{transaction: "status-1"}]} = Client.subscription_statuses(fake, "lineage", :production)
    assert {:ok, %{revision: "r1", has_more: true}} = Client.transaction_history(fake, "lineage", %{sort: :ascending}, nil)
    assert {:ok, %{revision: "r2", has_more: false}} = Client.transaction_history(fake, "lineage", %{sort: :ascending}, "r1")
  end

  @tag :status
  test "cadence is bounded and preserves a known provider bound during an outage" do
    now = ~U[2026-08-03 12:00:00Z]

    assert Reconciliation.due(%{next_due_at: nil}, now)
    refute Reconciliation.due(%{next_due_at: DateTime.add(now, 1, :second)}, now)
    assert Reconciliation.retry_after({:error, {:rate_limited, 120}}, 1, now) == DateTime.add(now, 120, :second)
    assert Reconciliation.retry_after({:error, :provider_unavailable}, 20, now) == DateTime.add(now, 21_600, :second)
  end

  @tag :status
  test "filter fingerprints are stable and reject drift" do
    filters = %{product_types: ["AUTO_RENEWABLE"], sort: :ascending}

    assert Reconciliation.query_fingerprint(filters) == Reconciliation.query_fingerprint(%{sort: :ascending, product_types: ["AUTO_RENEWABLE"]})
    refute Reconciliation.query_fingerprint(filters) == Reconciliation.query_fingerprint(%{sort: :descending, product_types: ["AUTO_RENEWABLE"]})
  end
end
