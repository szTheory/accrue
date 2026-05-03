defmodule Accrue.Telemetry.MeteredBillingOpsTest do
  @moduledoc """
  Phase 103 Plan 04 RED tests for metered-billing ops telemetry and metrics.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{
    Customer,
    Invoice,
    MeterEvent,
    MeterDefinitions,
    MeteredRenewal,
    MeteredRenewalActions,
    PaymentMethod,
    Subscription,
    SubscriptionItem
  }

  alias Accrue.Telemetry.Metrics

  defmodule RenewalSaleGateway do
    def sale(_params, _opts) do
      {:error, %Elixir.Braintree.ErrorResponse{message: "Processor Declined: Do Not Honor"}}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_transaction = Application.get_env(:accrue, :braintree_transaction_gateway)
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_transaction_gateway, RenewalSaleGateway)

    on_exit(fn ->
      restore_env(:processor, previous_processor)
      restore_env(:braintree_transaction_gateway, previous_transaction)
    end)

    :ok
  end

  test "metered-billing ops events fire once per durable state transition instead of once per raw retry attempt" do
    test_pid = self()

    handlers = [
      {[:accrue, :ops, :metered_missing_definition], :missing_definition},
      {[:accrue, :ops, :metered_charge_awaiting_payment_method], :awaiting_payment_method},
      {[:accrue, :ops, :metered_charge_failed_exhausted], :failed_exhausted}
    ]

    Enum.each(handlers, fn {event, label} ->
      :telemetry.attach(
        "metered-billing-ops-#{label}",
        event,
        fn _event, measurements, metadata, _ ->
          send(test_pid, {label, measurements, metadata})
        end,
        nil
      )
    end)

    try do
      %{renewal: missing_definition_renewal} = insert_missing_definition_fixture()
      assert {:ok, _result} = MeteredRenewalActions.author_local_invoice(missing_definition_renewal.id)
      assert {:ok, _result} = MeteredRenewalActions.author_local_invoice(missing_definition_renewal.id)

      assert_received {:missing_definition, %{count: 1}, missing_metadata}
      assert missing_metadata.unmatched_event_count == 1
      refute_received {:missing_definition, _, _}

      %{customer: pm_missing_customer, renewal: pm_missing_renewal} = insert_settlement_fixture()

      {:ok, _customer} =
        pm_missing_customer
        |> Customer.changeset(%{default_payment_method_id: nil})
        |> Repo.update()

      assert {:error, %Accrue.Error.NoDefaultPaymentMethod{}} =
               MeteredRenewalActions.settle_metered_renewal(pm_missing_renewal.id)

      assert {:error, %Accrue.Error.NoDefaultPaymentMethod{}} =
               MeteredRenewalActions.settle_metered_renewal(pm_missing_renewal.id)

      assert_received {:awaiting_payment_method, %{count: 1}, awaiting_metadata}
      assert awaiting_metadata.state == :awaiting_payment_method
      assert awaiting_metadata.processor == "braintree"
      refute_received {:awaiting_payment_method, _, _}

      %{renewal: exhausted_renewal} = insert_settlement_fixture()

      assert {:error, %Accrue.CardError{decline_code: "do_not_honor"}} =
               MeteredRenewalActions.settle_metered_renewal(exhausted_renewal.id,
                 processor_error: :hard_decline
               )

      assert {:error, %Accrue.CardError{decline_code: "do_not_honor"}} =
               MeteredRenewalActions.settle_metered_renewal(exhausted_renewal.id,
                 processor_error: :hard_decline
               )

      assert_received {:failed_exhausted, %{count: 1}, exhausted_metadata}
      assert exhausted_metadata.state == :failed_exhausted
      assert exhausted_metadata.failure_class == "hard_decline"
      refute_received {:failed_exhausted, _, _}
    after
      Enum.each(handlers, fn {_event, label} ->
        :telemetry.detach("metered-billing-ops-#{label}")
      end)
    end
  end

  test "default metrics include the metered-billing ops counters" do
    assert has_metric?("accrue.ops.metered_renewal_stale_repaired.count")
    assert has_metric?("accrue.ops.metered_missing_definition.count")
    assert has_metric?("accrue.ops.metered_charge_awaiting_payment_method.count")
    assert has_metric?("accrue.ops.metered_charge_failed_exhausted.count")
  end

  defp insert_missing_definition_fixture do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_metered_missing_definition_" <> unique_suffix(),
        email: "metered-missing-definition@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_metered_missing_definition_" <> unique_suffix(),
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
        processor_id: "si_metered_missing_definition_" <> unique_suffix(),
        price_id: "price_metered_missing_definition",
        processor_plan_id: "plan_metered_missing_definition",
        quantity: 1,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("known_meter_event", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => subscription_item.price_id,
                 "processor_plan_id" => subscription_item.processor_plan_id,
                 "unit_amount_minor" => 5,
                 "description" => "Known meter event"
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
              "event_name" => "known_meter_event",
              "subscription_item_id" => subscription_item.id,
              "price_id" => subscription_item.price_id,
              "processor_plan_id" => subscription_item.processor_plan_id,
              "aggregation_mode" => "sum",
              "billing_snapshot" => %{
                "price_id" => subscription_item.price_id,
                "processor_plan_id" => subscription_item.processor_plan_id,
                "unit_amount_minor" => 5,
                "description" => "Known meter event"
              }
            }
          ]
        }
      })
      |> Repo.insert()

    {:ok, _matched_event} =
      %MeterEvent{}
      |> Ecto.Changeset.change(%{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: "known_meter_event",
        value: 3,
        identifier: "evt-metered-known-" <> unique_suffix(),
        occurred_at: ~U[2026-04-10 00:00:00.000000Z],
        stripe_status: "reported",
        operation_id: "test-" <> Ecto.UUID.generate()
      })
      |> Repo.insert()

    {:ok, _unmatched_event} =
      %MeterEvent{}
      |> Ecto.Changeset.change(%{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: "missing_meter_event",
        value: 2,
        identifier: "evt-metered-missing-" <> unique_suffix(),
        occurred_at: ~U[2026-04-11 00:00:00.000000Z],
        stripe_status: "reported",
        operation_id: "test-" <> Ecto.UUID.generate()
      })
      |> Repo.insert()

    %{customer: customer, renewal: renewal}
  end

  defp insert_settlement_fixture do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_metered_settlement_" <> unique_suffix(),
        email: "metered-settlement@example.com"
      })
      |> Repo.insert()

    {:ok, payment_method} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "pm_metered_settlement_" <> unique_suffix(),
        type: "card",
        fingerprint: "fp-metered-settlement-" <> unique_suffix(),
        card_brand: "Visa",
        card_last4: "1111",
        card_exp_month: 12,
        card_exp_year: 2037
      })
      |> Repo.insert()

    {:ok, customer} =
      customer
      |> Customer.changeset(%{default_payment_method_id: payment_method.id})
      |> Repo.update()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_metered_settlement_" <> unique_suffix(),
        status: :active,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, invoice} =
      %Invoice{}
      |> Invoice.changeset(%{
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id: "mrinv_" <> Ecto.UUID.generate(),
        status: :open,
        currency: "usd",
        subtotal_minor: 2400,
        total_minor: 2400,
        billing_reason: "metered_cycle",
        period_start: ~U[2026-04-01 00:00:00Z],
        period_end: ~U[2026-05-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, renewal} =
      %MeteredRenewal{}
      |> MeteredRenewal.changeset(%{
        subscription_id: subscription.id,
        customer_id: customer.id,
        processor: "braintree",
        state: :pending,
        period_start: ~U[2026-04-01 00:00:00Z],
        period_end: ~U[2026-05-01 00:00:00Z],
        trigger_source: "worker",
        invoice_id: invoice.id,
        invoice_status: "authored",
        invoice_authored_at: ~U[2026-05-01 00:05:00Z],
        snapshot: %{
          "subscription_id" => subscription.id,
          "subscription_processor_id" => subscription.processor_id,
          "meter_definitions" => []
        },
        data: %{"invoice_id" => invoice.id, "invoice_status" => "authored"}
      })
      |> Repo.insert()

    %{customer: customer, renewal: renewal}
  end

  defp has_metric?(name) do
    Enum.any?(Metrics.defaults(), fn metric -> metric_name(metric.name) == name end)
  end

  defp metric_name(name) when is_list(name),
    do: name |> Enum.map(&Atom.to_string/1) |> Enum.join(".")

  defp metric_name(name) when is_binary(name), do: name

  defp unique_suffix, do: Integer.to_string(System.unique_integer([:positive]))

  defp restore_env(key, nil), do: Application.delete_env(:accrue, key)
  defp restore_env(key, value), do: Application.put_env(:accrue, key, value)
end
