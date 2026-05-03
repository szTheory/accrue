defmodule Accrue.Jobs.MeteredRenewalReconcilerTest do
  @moduledoc """
  Phase 103 Plan 04 RED tests for the stale-window metered renewal backstop.
  """
  use Accrue.BillingCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, MeterDefinition, MeteredRenewal, Subscription, SubscriptionItem}
  alias Accrue.Jobs.MeteredRenewalReconciler

  defmodule SubscriptionGatewayStub do
    def find(id, _opts) do
      periods = Application.fetch_env!(:accrue, :metered_renewal_reconciler_periods)
      %{next_start: next_start, next_end: next_end} = Map.fetch!(periods, id)

      {:ok,
       struct!(Elixir.Braintree.Subscription,
         id: id,
         plan_id: "plan_metered_reconciler",
         status: "Active",
         billing_period_start_date: DateTime.to_iso8601(next_start),
         billing_period_end_date: DateTime.to_iso8601(next_end),
         updated_at: DateTime.to_iso8601(DateTime.utc_now())
       )}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)
    previous_periods = Application.get_env(:accrue, :metered_renewal_reconciler_periods)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)
    Application.put_env(:accrue, :metered_renewal_reconciler_periods, %{})

    on_exit(fn ->
      restore_env(:processor, previous_processor)
      restore_env(:braintree_subscription_gateway, previous_gateway)
      restore_env(:metered_renewal_reconciler_periods, previous_periods)
    end)

    :ok
  end

  test "repairs only stale expected-renewal windows and reuses the renewal-opening contract" do
    now = Accrue.Clock.utc_now() |> DateTime.truncate(:microsecond)
    stale_end = DateTime.add(now, -120, :second)
    fresh_end = DateTime.add(now, -10, :second)

    stale =
      insert_subscription_fixture(
        "stale",
        DateTime.add(stale_end, -30 * 24 * 60 * 60, :second),
        stale_end
      )

    fresh =
      insert_subscription_fixture(
        "fresh",
        DateTime.add(fresh_end, -30 * 24 * 60 * 60, :second),
        fresh_end
      )

    Application.put_env(:accrue, :metered_renewal_reconciler_periods, %{
      stale.subscription.processor_id => %{
        next_start: stale.subscription.current_period_end,
        next_end: DateTime.add(stale.subscription.current_period_end, 30 * 24 * 60 * 60, :second)
      },
      fresh.subscription.processor_id => %{
        next_start: fresh.subscription.current_period_end,
        next_end: DateTime.add(fresh.subscription.current_period_end, 30 * 24 * 60 * 60, :second)
      }
    })

    test_pid = self()

    :telemetry.attach(
      "test-metered-renewal-stale-repaired",
      [:accrue, :ops, :metered_renewal_stale_repaired],
      fn _event, measurements, metadata, _ ->
        send(test_pid, {:metered_renewal_stale_repaired, measurements, metadata})
      end,
      nil
    )

    try do
      assert {:ok, 1} = MeteredRenewalReconciler.reconcile()
      assert {:ok, 0} = MeteredRenewalReconciler.reconcile()
    after
      :telemetry.detach("test-metered-renewal-stale-repaired")
    end

    stale_renewal =
      Repo.one(
        from(r in MeteredRenewal,
          where:
            r.subscription_id == ^stale.subscription.id and
              r.period_start == ^stale.subscription.current_period_start and
              r.period_end == ^stale.subscription.current_period_end
        )
      )

    assert %MeteredRenewal{} = stale_renewal
    assert stale_renewal.data["raw_event_type"] == "scheduled_reconciler"

    assert Repo.aggregate(
             from(r in MeteredRenewal, where: r.subscription_id == ^fresh.subscription.id),
             :count,
             :id
           ) == 0

    assert_received {:metered_renewal_stale_repaired, %{count: 1}, metadata}
    assert metadata.subscription_id == stale.subscription.id
    assert metadata.processor == "braintree"
    refute_received {:metered_renewal_stale_repaired, _, _}
  end

  test "queue is :accrue_meters" do
    assert MeteredRenewalReconciler.__opts__()[:queue] == :accrue_meters
  end

  defp insert_subscription_fixture(suffix, period_start, period_end) do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_metered_reconciler_#{suffix}",
        email: "metered-reconciler-#{suffix}@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_metered_reconciler_#{suffix}",
        status: :active,
        current_period_start: period_start,
        current_period_end: period_end
      })
      |> Repo.insert()

    {:ok, subscription_item} =
      %SubscriptionItem{}
      |> SubscriptionItem.changeset(%{
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id: "si_metered_reconciler_#{suffix}",
        price_id: "price_metered_reconciler_#{suffix}",
        processor_plan_id: "plan_metered_reconciler_#{suffix}",
        quantity: 1,
        current_period_start: period_start,
        current_period_end: period_end
      })
      |> Repo.insert()

    {:ok, _definition} =
      %MeterDefinition{}
      |> MeterDefinition.changeset(%{
        subscription_item_id: subscription_item.id,
        processor: "braintree",
        event_name: "api_calls_#{suffix}",
        price_id: subscription_item.price_id,
        aggregation_mode: "sum",
        active: true,
        billing_snapshot: %{
          "description" => "API call overage",
          "price_id" => subscription_item.price_id,
          "processor_plan_id" => subscription_item.processor_plan_id,
          "unit_amount_minor" => 3
        }
      })
      |> Repo.insert()

    %{customer: customer, subscription: subscription}
  end

  defp restore_env(key, nil), do: Application.delete_env(:accrue, key)
  defp restore_env(key, value), do: Application.put_env(:accrue, key, value)
end
