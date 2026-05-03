defmodule Accrue.Webhook.BraintreeMeteredRenewalTest do
  @moduledoc """
  Phase 103 Plan 01 RED tests for webhook-opened metered renewal windows.

  D-08/D-10/D-11/D-14 require webhook-primary renewal classification that
  opens one immutable local window only after canonical Braintree
  subscription state proves the cycle advanced.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Customer, MeterDefinition, MeterDefinitions, MeteredRenewal, Subscription,
    SubscriptionItem}
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Webhook.DefaultHandler

  defmodule BraintreeRenewalGatewayStub do
    def find(id, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: id,
         plan_id: "price_metered",
         status: "Active",
         billing_period_start_date: "2026-05-01T00:00:00Z",
         billing_period_end_date: "2026-06-01T00:00:00Z",
         updated_at: "2026-05-01T00:00:00Z"
       )}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeRenewalGatewayStub)

    on_exit(fn ->
      if previous_processor do
        Application.put_env(:accrue, :processor, previous_processor)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_gateway do
        Application.put_env(:accrue, :braintree_subscription_gateway, previous_gateway)
      else
        Application.delete_env(:accrue, :braintree_subscription_gateway)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_bt_metered_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "metered-renewal@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_bt_metered_" <> Integer.to_string(System.unique_integer([:positive])),
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
        processor_id: "si_bt_metered_" <> Integer.to_string(System.unique_integer([:positive])),
        price_id: "price_metered",
        processor_plan_id: "plan_metered",
        quantity: 1,
        current_period_start: ~U[2026-04-01 00:00:00Z],
        current_period_end: ~U[2026-05-01 00:00:00Z]
      })
      |> Repo.insert()

    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => "price_metered",
                 "processor_plan_id" => "plan_metered"
               }
             })

    assert definition.__struct__ == MeterDefinition

    %{customer: customer, subscription: subscription, subscription_item: subscription_item}
  end

  test "D-10/D-11 creates exactly one immutable renewal row per subscription + UTC window under replay",
       %{subscription: subscription} do
    event =
      %Accrue.Webhook.Event{
        processor: :braintree,
        object_id: subscription.processor_id,
        processor_event_id: "evt_bt_renewal_1",
        created_at: ~U[2026-05-01 00:05:00Z]
      }

    assert :ok =
             DefaultHandler.handle_event("subscription_charged_successfully", event, %{})

    assert :ok =
             DefaultHandler.handle_event("subscription_charged_successfully", event, %{})

    renewals =
      Repo.all(
        from(r in MeteredRenewal,
          where: r.subscription_id == ^subscription.id,
          order_by: [asc: r.period_start]
        )
      )

    assert length(renewals) == 1
    [renewal] = renewals
    assert renewal.__struct__ == MeteredRenewal
    assert renewal.state == :pending
    assert renewal.subscription_id == subscription.id
    assert renewal.customer_id == subscription.customer_id
    assert renewal.period_start == ~U[2026-04-01 00:00:00Z]
    assert renewal.period_end == ~U[2026-05-01 00:00:00Z]
    assert renewal.trigger_source == "braintree_webhook"
    assert renewal.last_processor_event_id == "evt_bt_renewal_1"

    ledger_events =
      Repo.all(
        from(e in LedgerEvent,
          where:
            e.type == "metered_renewal.opened" and
              e.subject_type == "MeteredRenewal" and e.subject_id == ^renewal.id
        )
      )

    assert length(ledger_events) == 1
  end

  test "D-09/D-10 stale or non-advancing lifecycle events do not open a billable renewal window",
       %{subscription: subscription} do
    event = %Accrue.Webhook.Event{
      processor: :braintree,
      object_id: subscription.processor_id,
      processor_event_id: "evt_bt_stale_1",
      created_at: ~U[2026-04-15 00:00:00Z]
    }

    assert :ok = DefaultHandler.handle_event("subscription_went_active", event, %{})

    assert Repo.aggregate(MeteredRenewal, :count, :id) == 0
  end

  test "D-05/D-14 renewal rows snapshot UTC boundaries even if the subscription item changes later",
       %{subscription: subscription, subscription_item: subscription_item} do
    event =
      %Accrue.Webhook.Event{
        processor: :braintree,
        object_id: subscription.processor_id,
        processor_event_id: "evt_bt_snapshot_1",
        created_at: ~U[2026-05-01 00:05:00Z]
      }

    assert :ok =
             DefaultHandler.handle_event("subscription_charged_successfully", event, %{})

    [renewal] =
      Repo.all(
        from(r in MeteredRenewal,
          where: r.subscription_id == ^subscription.id
        )
      )

    assert renewal.__struct__ == MeteredRenewal

    {:ok, _updated_item} =
      subscription_item
      |> SubscriptionItem.changeset(%{
        price_id: "price_metered_v2",
        processor_plan_id: "plan_metered_v2",
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.update()

    reloaded = Repo.get!(MeteredRenewal, renewal.id)

    assert reloaded.period_start == ~U[2026-04-01 00:00:00Z]
    assert reloaded.period_end == ~U[2026-05-01 00:00:00Z]
    assert reloaded.snapshot["subscription_item_id"] == subscription_item.id
    assert reloaded.snapshot["price_id"] == "price_metered"
    assert reloaded.snapshot["processor_plan_id"] == "plan_metered"
  end
end
