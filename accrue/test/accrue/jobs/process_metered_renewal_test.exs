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
    MeteredChargeAttempt,
    MeteredRenewal,
    PaymentMethod,
    Subscription,
    SubscriptionItem
  }

  alias Accrue.Jobs.ProcessMeteredRenewal

  defmodule RenewalSaleGateway do
    def sale(params, opts) do
      send(self(), {:braintree_sale, params, opts})

      {:ok,
       %{
         id: "txn_metered_" <> Integer.to_string(System.unique_integer([:positive])),
         status: "submitted_for_settlement",
         type: "sale",
         amount: params[:amount] || params["amount"],
         currency_iso_code: "USD",
         customer_details: %{id: params[:customer_id] || params["customer_id"]},
         payment_instrument_type: "credit_card",
         credit_card_details: %{token: params[:payment_method_token] || params["payment_method_token"]}
       }}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_transaction = Application.get_env(:accrue, :braintree_transaction_gateway)
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_transaction_gateway, RenewalSaleGateway)

    on_exit(fn ->
      if previous_processor do
        Application.put_env(:accrue, :processor, previous_processor)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_transaction do
        Application.put_env(:accrue, :braintree_transaction_gateway, previous_transaction)
      else
        Application.delete_env(:accrue, :braintree_transaction_gateway)
      end
    end)

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

    {:ok, payment_method} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "pm_process_metered_" <> Integer.to_string(System.unique_integer([:positive])),
        type: "card",
        fingerprint: "fp-process-" <> Integer.to_string(System.unique_integer([:positive])),
        card_brand: "Visa",
        card_last4: "1111",
        card_exp_month: 12,
        card_exp_year: 2036
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

    %{customer: customer, payment_method: payment_method, renewal: renewal}
  end

  test "worker settles one authored renewal window exactly once and replays against the same charge unit",
       %{renewal: renewal, payment_method: payment_method} do
    job = %Oban.Job{args: %{"metered_renewal_id" => renewal.id}, attempt: 1, id: 123}

    assert :ok = ProcessMeteredRenewal.perform(job)
    assert_receive {:braintree_sale, sale_params, sale_opts}
    assert :ok = ProcessMeteredRenewal.perform(job)
    refute_receive {:braintree_sale, _, _}

    assert sale_params[:payment_method_token] == payment_method.processor_id
    assert sale_params[:customer_id] =~ "cus_process_metered_"
    assert is_binary(sale_opts[:idempotency_key])

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
    assert Repo.aggregate(MeteredChargeAttempt, :count, :id) == 1

    attempt =
      Repo.one!(
        from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id)
      )

    assert attempt.status == "paid"
    assert attempt.attempted_payment_method_id == payment_method.processor_id

    reloaded = Repo.get!(MeteredRenewal, renewal.id)
    assert reloaded.state == :paid
    assert reloaded.data["invoice_status"] == "authored"
    assert is_binary(reloaded.data["invoice_id"])
  end

  test "worker reuses the same renewal settlement after payment-method repair instead of creating a second charge unit",
       %{customer: customer, renewal: renewal} do
    {:ok, _customer} =
      customer
      |> Customer.changeset(%{default_payment_method_id: nil})
      |> Repo.update()

    job = %Oban.Job{args: %{"metered_renewal_id" => renewal.id}, attempt: 1, id: 123}

    assert {:error, %Accrue.Error.NoDefaultPaymentMethod{}} = ProcessMeteredRenewal.perform(job)

    first_attempt =
      Repo.one!(
        from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id)
      )

    {:ok, repaired_payment_method} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "pm_process_metered_repair_" <> Integer.to_string(System.unique_integer([:positive])),
        type: "card",
        fingerprint: "fp-process-repair-" <> Integer.to_string(System.unique_integer([:positive])),
        card_brand: "Visa",
        card_last4: "4242",
        card_exp_month: 3,
        card_exp_year: 2039
      })
      |> Repo.insert()

    {:ok, _customer} =
      Repo.get!(Customer, customer.id)
      |> Customer.changeset(%{default_payment_method_id: repaired_payment_method.id})
      |> Repo.update()

    assert :ok = ProcessMeteredRenewal.perform(job)
    assert_receive {:braintree_sale, repaired_sale_params, _opts}
    assert repaired_sale_params[:payment_method_token] == repaired_payment_method.processor_id

    assert Repo.aggregate(MeteredChargeAttempt, :count, :id) == 1

    repaired_attempt =
      Repo.one!(
        from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id)
      )

    assert repaired_attempt.subject_uuid == first_attempt.subject_uuid
    assert repaired_attempt.original_failure_class == "payment_method_required"
    assert repaired_attempt.status == "paid"
  end
end
