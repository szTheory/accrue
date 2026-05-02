defmodule Accrue.Webhook.DefaultHandlerPortalEventTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Checkout.LocalSession
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Webhook.Event, as: WebhookEventStruct

  defmodule BraintreeGatewayStub do
    def create(params, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_portal_" <> Integer.to_string(System.unique_integer([:positive])),
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

  test "reduces accrue.portal.checkout.completed through the checkout-session projection path" do
    customer = insert_braintree_customer!()
    checkout_session = insert_checkout_session!(customer)

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "price_portal",
               payment_method: %{vault_acquisition: %{reference: "pm_portal_123"}}
             )

    {1, _} =
      Repo.delete_all(from(s in Subscription, where: s.id == ^subscription.id))

    refute Repo.get(Subscription, subscription.id)

    event = %WebhookEventStruct{
      type: "accrue.portal.checkout.completed",
      object_id: checkout_session.id,
      livemode: false,
      created_at: DateTime.utc_now(),
      processor_event_id: "evt_portal_" <> Integer.to_string(System.unique_integer([:positive])),
      processor: :braintree
    }

    ctx = %{
      portal_checkout_object: %{
        "id" => checkout_session.id,
        "customer" => customer.processor_id,
        "subscription" => subscription.processor_id
      }
    }

    assert :ok = DefaultHandler.handle_event(event.type, event, ctx)

    restored = Repo.get_by!(Subscription, processor_id: subscription.processor_id)
    assert restored.customer_id == customer.id
    assert restored.processor == "braintree"
    assert restored.status == :active

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
