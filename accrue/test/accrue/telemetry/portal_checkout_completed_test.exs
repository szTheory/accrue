defmodule Accrue.Telemetry.PortalCheckoutCompletedTest do
  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Checkout.LocalSession
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Portal.Checkout.CompletionJob
  alias Accrue.Webhook.WebhookEvent

  defmodule BraintreeGatewayStub do
    def create(params, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_completed_" <> Integer.to_string(System.unique_integer([:positive])),
         plan_id: params[:plan_id],
         payment_method_token: params[:payment_method_token],
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end

    def find(id, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: id,
         plan_id: "price_portal",
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)

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

    :ok
  end

  test "completion job persists the synthetic event and emits portal checkout telemetry" do
    attach_telemetry([:accrue, :portal, :checkout, :completed])

    customer = insert_braintree_customer!()
    checkout_session = insert_checkout_session!(customer)

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "price_portal",
               payment_method: %{vault_acquisition: %{reference: "pm_portal_456"}}
             )

    assert {:ok, job} = CompletionJob.enqueue(checkout_session.id, subscription.id)

    assert_enqueued(
      worker: CompletionJob,
      args: %{
        "checkout_session_id" => checkout_session.id,
        "subscription_id" => subscription.id
      }
    )

    assert :ok = CompletionJob.perform(job)

    row =
      Repo.get_by!(WebhookEvent,
        processor: "braintree",
        type: "accrue.portal.checkout.completed"
      )

    assert row.status == :succeeded
    assert get_in(row.data, ["data", "object", "id"]) == checkout_session.id
    assert get_in(row.data, ["data", "object", "customer"]) == customer.processor_id
    assert get_in(row.data, ["data", "object", "subscription"]) == subscription.processor_id

    assert_received {:telemetry_event, [:accrue, :portal, :checkout, :completed], %{count: 1},
                     metadata}

    assert metadata.checkout_session_id == checkout_session.id
    assert metadata.customer_id == customer.id
    assert metadata.subscription_id == subscription.id
    assert metadata.customer_processor_id == customer.processor_id
    assert metadata.subscription_processor_id == subscription.processor_id
    assert metadata.processor == :braintree
    assert metadata.source == :default_handler

    ledger_events =
      Repo.all(
        from(e in LedgerEvent,
          where:
            e.type == "checkout.session.completed" and
              e.subject_type == "CheckoutSession" and
              e.subject_id == ^checkout_session.id
        )
      )

    assert length(ledger_events) == 1
  end

  defp attach_telemetry(event_name) do
    test_pid = self()
    handler_id = "portal-checkout-" <> Integer.to_string(System.unique_integer([:positive]))

    :telemetry.attach(
      handler_id,
      event_name,
      fn evt, measurements, metadata, _ ->
        send(test_pid, {:telemetry_event, evt, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
  end

  defp insert_braintree_customer! do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_bt_portal_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "portal-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    customer
  end

  defp insert_checkout_session!(customer) do
    {:ok, session} =
      LocalSession.create_or_reuse(customer, %{
        processor: "braintree",
        mode: "subscription",
        ui_mode: "hosted",
        status: "completed",
        price_id: "price_portal",
        line_items: [%{"price" => "price_portal", "amount" => "49.00"}],
        success_url: "https://app.example.test/billing/success",
        cancel_url: "https://app.example.test/billing/cancel",
        return_url: "https://app.example.test/settings/billing",
        operation_id: "portal-op-" <> Integer.to_string(System.unique_integer([:positive])),
        metadata: %{"source" => "portal-test"},
        data: %{"local_portal" => true}
      })

    session
  end
end
