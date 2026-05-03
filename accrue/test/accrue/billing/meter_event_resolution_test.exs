defmodule Accrue.Billing.MeterEventResolutionTest do
  @moduledoc """
  Phase 103 Plan 02 RED tests for durable meter-event billing outcomes.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{
    Customer,
    MeterDefinitions,
    MeterEvent,
    MeteredRenewal,
    MeteredRenewalInvoice,
    Subscription,
    SubscriptionItem
  }

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id:
          "cus_meter_resolution_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "meter-resolution@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "sub_meter_resolution_" <> Integer.to_string(System.unique_integer([:positive])),
        status: :active,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, subscription_item} =
      %SubscriptionItem{}
      |> SubscriptionItem.changeset(%{
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id:
          "si_meter_resolution_" <> Integer.to_string(System.unique_integer([:positive])),
        price_id: "price_ai_tokens",
        processor_plan_id: "plan_ai_tokens",
        quantity: 1,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => "price_ai_tokens",
                 "processor_plan_id" => "plan_ai_tokens",
                 "unit_amount_minor" => 1,
                 "description" => "AI token overage"
               }
             })

    {:ok, renewal} =
      %MeteredRenewal{}
      |> MeteredRenewal.changeset(%{
        subscription_id: subscription.id,
        customer_id: customer.id,
        processor: "braintree",
        state: :pending,
        period_start: ~U[2026-04-01 00:00:00Z],
        period_end: ~U[2026-05-01 00:00:00Z],
        trigger_source: "braintree_webhook",
        snapshot: %{
          "subscription_id" => subscription.id,
          "subscription_processor_id" => subscription.processor_id,
          "meter_definitions" => [
            %{
              "meter_definition_id" => definition.id,
              "event_name" => "ai_tokens",
              "subscription_item_id" => subscription_item.id,
              "price_id" => "price_ai_tokens",
              "processor_plan_id" => "plan_ai_tokens",
              "aggregation_mode" => "sum",
              "billing_snapshot" => %{
                "price_id" => "price_ai_tokens",
                "processor_plan_id" => "plan_ai_tokens",
                "unit_amount_minor" => 1,
                "description" => "AI token overage"
              }
            }
          ]
        }
      })
      |> Repo.insert()

    matched =
      insert_meter_event(customer, %{
        event_name: "ai_tokens",
        value: 25,
        identifier: "evt-resolution-matched"
      })

    unmatched =
      insert_meter_event(customer, %{
        event_name: "unknown_metric",
        value: 9,
        identifier: "evt-resolution-unmatched"
      })

    unusable =
      insert_meter_event(customer, %{
        event_name: "ai_tokens",
        value: -1,
        identifier: "evt-resolution-unusable"
      })

    %{renewal: renewal, matched: matched, unmatched: unmatched, unusable: unusable}
  end

  test "marks matched, unmatched, and unusable events durably instead of silently skipping rows",
       %{renewal: renewal, matched: matched, unmatched: unmatched, unusable: unusable} do
    assert {:ok, _result} = MeteredRenewalInvoice.author_invoice(renewal.id)

    assert Repo.get!(MeterEvent, matched.id).billing_status == "matched"

    unmatched_row = Repo.get!(MeterEvent, unmatched.id)
    assert unmatched_row.billing_status == "unmatched"
    assert unmatched_row.billing_error == "no_meter_definition"

    unusable_row = Repo.get!(MeterEvent, unusable.id)
    assert unusable_row.billing_status == "unusable"
    assert unusable_row.billing_error == "invalid_value"
  end

  defp insert_meter_event(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      event_name: "ai_tokens",
      value: 10,
      identifier: "evt-" <> Integer.to_string(System.unique_integer([:positive])),
      occurred_at: ~U[2026-04-20 00:00:00.000000Z],
      operation_id: "test-" <> Ecto.UUID.generate()
    }

    event =
      defaults
      |> Map.merge(attrs)
      |> Map.put(:stripe_status, "reported")

    {:ok, inserted} =
      %MeterEvent{}
      |> Ecto.Changeset.change(event)
      |> Repo.insert()

    inserted
  end
end
