defmodule Accrue.Jobs.ProcessMeteredRenewalTest do
  @moduledoc """
  Phase 103 Plan 02 RED tests for the worker-owned BT-06 renewal processor.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{
    Customer,
    Invoice,
    InvoiceItem,
    MeterDefinitions,
    MeterEvent,
    MeteredRenewal,
    Subscription,
    SubscriptionItem
  }

  alias Accrue.Jobs.ProcessMeteredRenewal

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id:
          "cus_process_metered_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "process-metered@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "sub_process_metered_" <> Integer.to_string(System.unique_integer([:positive])),
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
          "si_process_metered_" <> Integer.to_string(System.unique_integer([:positive])),
        price_id: "price_process_metered",
        processor_plan_id: "plan_process_metered",
        quantity: 1,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("api_calls", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => "price_process_metered",
                 "processor_plan_id" => "plan_process_metered",
                 "unit_amount_minor" => 3,
                 "description" => "API call overage"
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
              "event_name" => "api_calls",
              "subscription_item_id" => subscription_item.id,
              "price_id" => "price_process_metered",
              "processor_plan_id" => "plan_process_metered",
              "aggregation_mode" => "sum",
              "billing_snapshot" => %{
                "price_id" => "price_process_metered",
                "processor_plan_id" => "plan_process_metered",
                "unit_amount_minor" => 3,
                "description" => "API call overage"
              }
            }
          ]
        }
      })
      |> Repo.insert()

    {:ok, _event} =
      %MeterEvent{}
      |> Ecto.Changeset.change(%{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: "api_calls",
        value: 10,
        identifier: "evt-process-metered",
        occurred_at: ~U[2026-04-10 00:00:00.000000Z],
        stripe_status: "reported",
        operation_id: "test-" <> Ecto.UUID.generate()
      })
      |> Repo.insert()

    %{renewal: renewal}
  end

  test "worker processes one renewal window and remains idempotent under replay", %{
    renewal: renewal
  } do
    job = %Oban.Job{args: %{"metered_renewal_id" => renewal.id}, attempt: 1, id: 123}

    assert :ok = ProcessMeteredRenewal.perform(job)
    assert :ok = ProcessMeteredRenewal.perform(job)

    invoice =
      Repo.one(
        from(i in Invoice,
          where:
            i.subscription_id == ^renewal.subscription_id and
              i.period_start == ^renewal.period_start
        )
      )

    assert %Invoice{} = invoice
    assert Repo.aggregate(InvoiceItem, :count, :id) == 1

    reloaded = Repo.get!(MeteredRenewal, renewal.id)
    assert reloaded.data["invoice_status"] == "authored"
    assert is_binary(reloaded.data["invoice_id"])
  end
end
