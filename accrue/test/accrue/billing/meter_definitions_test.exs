defmodule Accrue.Billing.MeterDefinitionsTest do
  @moduledoc """
  Phase 103 Plan 01 RED tests for the local meter-definition contract.

  D-01/D-02/D-04 pin the host-light contract:
  `report_usage/3` remains the ingress seam while local meter definitions
  bind one ingress event name to one concrete billable subscription item.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{
    Customer,
    MeterDefinition,
    MeterDefinitions,
    MeterEvent,
    Subscription,
    SubscriptionItem
  }

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_meter_defs_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "meter-defs@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_meter_defs_" <> Integer.to_string(System.unique_integer([:positive])),
        status: :active,
        current_period_start: ~U[2026-04-01 00:00:00Z],
        current_period_end: ~U[2026-05-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, subscription_item} =
      %SubscriptionItem{}
      |> SubscriptionItem.changeset(%{
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id: "si_meter_defs_" <> Integer.to_string(System.unique_integer([:positive])),
        price_id: "price_ai_tokens",
        processor_plan_id: "plan_ai_tokens",
        quantity: 1,
        current_period_start: ~U[2026-04-01 00:00:00Z],
        current_period_end: ~U[2026-05-01 00:00:00Z]
      })
      |> Repo.insert()

    %{customer: customer, subscription: subscription, subscription_item: subscription_item}
  end

  test "D-01/D-02 lookup binds report_usage event_name to one metered subscription item without host-supplied item ids",
       %{customer: customer, subscription_item: subscription_item} do
    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => subscription_item.price_id,
                 "processor_plan_id" => subscription_item.processor_plan_id
               }
             })

    assert definition.__struct__ == MeterDefinition
    assert definition.event_name == "ai_tokens"
    assert definition.subscription_item_id == subscription_item.id
    assert definition.price_id == subscription_item.price_id
    assert definition.aggregation_mode == "sum"

    assert {:ok, %MeterEvent{} = event} = Billing.report_usage(customer, "ai_tokens", value: 1200)
    assert event.event_name == "ai_tokens"

    assert {:ok, looked_up} = MeterDefinitions.get_meter_definition("ai_tokens")
    assert looked_up.id == definition.id
    assert looked_up.subscription_item_id == subscription_item.id
  end

  test "D-04 rejects orphan definitions that do not bind the ingress event to a concrete billable target" do
    assert {:error, changeset} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{"price_id" => "price_ai_tokens"}
             })

    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).subscription_item_id
  end

  test "D-05 later edits do not silently rewrite the snapshot contract for previously-created definitions",
       %{subscription_item: subscription_item} do
    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => "price_ai_tokens_v1",
                 "processor_plan_id" => "plan_ai_tokens_v1"
               }
             })

    assert definition.__struct__ == MeterDefinition

    assert {:ok, updated} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => "price_ai_tokens_v2",
                 "processor_plan_id" => "plan_ai_tokens_v2"
               }
             })

    assert updated.__struct__ == MeterDefinition
    assert updated.id == definition.id
    assert updated.billing_snapshot["price_id"] == "price_ai_tokens_v2"
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
