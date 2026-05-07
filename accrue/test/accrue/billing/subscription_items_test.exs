defmodule Accrue.Billing.SubscriptionItemsTest do
  @moduledoc """
  Phase 4 Plan 03 (BILL-12) — multi-item subscription mutations via
  `add_item/3`, `remove_item/2`, `update_item_quantity/3`.

  All three mutations flow through the Fake processor and persist via
  the WR-09 non-bang `reduce_while` pattern. `:proration` is required
  on `update_item_quantity/3` per BILL-09 carryover.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_items",
        email: "items@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    sub = Repo.preload(sub, :subscription_items, force: true)
    %{customer: customer, sub: sub}
  end

  describe "add_item/3" do
    test "adds a new SubscriptionItem row via Processor.subscription_item_create", %{sub: sub} do
      assert {:ok, %SubscriptionItem{} = item} =
               Billing.add_item(sub, "price_pro", quantity: 2, proration: :create_prorations)

      assert item.price_id == "price_pro"
      assert item.quantity == 2
      assert item.subscription_id == sub.id
    end

    test "records a subscription.item_added event", %{sub: sub} do
      {:ok, item} =
        Billing.add_item(sub, "price_addon", quantity: 1, proration: :none)

      row =
        Repo.one!(
          from(e in Accrue.Events.Event,
            where:
              e.type == "subscription.item_added" and
                e.subject_id == ^sub.id
          )
        )

      assert row.data["item_id"] == item.id or row.data[:item_id] == item.id
    end

    test "rejects missing :proration (BILL-09 carryover)", %{sub: sub} do
      assert_raise NimbleOptions.ValidationError, ~r/proration/, fn ->
        Billing.add_item(sub, "price_pro", quantity: 1)
      end
    end
  end

  describe "remove_item/2" do
    test "deletes local SubscriptionItem row via Processor.subscription_item_delete", %{sub: sub} do
      {:ok, item} =
        Billing.add_item(sub, "price_removeme", quantity: 1, proration: :none)

      assert {:ok, _} = Billing.remove_item(item, proration: :none)
      refute Repo.get(SubscriptionItem, item.id)
    end
  end

  test "the official Fake-first lane supports quantity and item mutations together", %{sub: sub} do
    assert {:ok, quantity_updated} = Billing.update_quantity(sub, 3)

    [base_item] = quantity_updated.subscription_items
    assert base_item.quantity == 3

    assert {:ok, added_item} =
             Billing.add_item(quantity_updated, "price_support_addon",
               quantity: 2,
               proration: :create_prorations
             )

    assert {:ok, resized_item} =
             Billing.update_item_quantity(added_item, 5, proration: :create_prorations)

    assert resized_item.quantity == 5
    assert resized_item.price_id == "price_support_addon"

    assert {:ok, removed_item} = Billing.remove_item(resized_item, proration: :none)
    assert removed_item.id == resized_item.id
    refute Repo.get(SubscriptionItem, resized_item.id)
  end

  describe "update_item_quantity/3" do
    test "updates local SubscriptionItem quantity with explicit :proration", %{sub: sub} do
      [item | _] = sub.subscription_items

      assert {:ok, updated} =
               Billing.update_item_quantity(item, 5, proration: :create_prorations)

      assert updated.quantity == 5
    end

    test "requires explicit :proration (BILL-09 carryover)", %{sub: sub} do
      [item | _] = sub.subscription_items

      assert_raise NimbleOptions.ValidationError, ~r/proration/, fn ->
        Billing.update_item_quantity(item, 3, [])
      end
    end
  end
end
