defmodule AccrueHost.BraintreeSubscribeTest do
  use AccrueHost.AccrueCase, async: false

  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Billing

  # We define a Mock processor inline to bypass network calls
  # Named `...Braintree` so `SubscriptionActions.processor_name` correctly infers "braintree"
  defmodule BraintreeMockAdapter.Braintree do
    @behaviour Accrue.Processor

    def processor_name, do: "braintree"

    def capabilities, do: Accrue.Processor.Braintree.capabilities()

    def create_subscription(params, _opts) do
      item = hd(params[:items] || params["items"] || [%{}])
      plan_id = item[:price] || item["price"] || "plan_sandbox_recurring"

      # Return a shape that `SubscriptionProjection.stripe_attrs/1` can digest,
      # because our mock module isn't strictly `Accrue.Processor.Braintree` so
      # `processor_atom()` defaults to `:stripe`.
      {:ok,
       %{
         id: "sub_braintree_123",
         status: "active",
         cancel_at_period_end: false,
         current_period_start: System.os_time(:second),
         current_period_end: System.os_time(:second) + 30 * 86_400,
         items: %{
           data: [
             %{
               id: "si_braintree_123",
               price: %{id: plan_id},
               quantity: 1
             }
           ]
         }
       }}
    end

    def retrieve_subscription(id, _opts) do
      {:ok,
       %{
         id: id,
         status: "active"
       }}
    end

    def create_customer(params, _opts) do
      {:ok,
       %{
         id: "cus_braintree_host_123",
         email: params[:email],
         name: params[:name],
         metadata: %{}
       }}
    end

    def retrieve_customer(id, _opts) do
      {:ok,
       %{
         id: id,
         email: "host-braintree@example.com",
         name: "Host Braintree Customer",
         metadata: %{}
       }}
    end

    def cancel_subscription(id, _opts) do
      {:ok,
       %{
         id: id,
         status: "canceled",
         cancel_at_period_end: false,
         canceled_at: System.os_time(:second),
         current_period_start: System.os_time(:second) - 86_400,
         current_period_end: System.os_time(:second),
         items: %{
           data: [
             %{
               id: "si_braintree_123",
               price: %{id: "plan_sandbox_recurring"},
               quantity: 1
             }
           ]
         }
       }}
    end

    def cancel_subscription(id, _params, _opts) do
      cancel_subscription(id, [])
    end

    # Minimal implementation of other callbacks to satisfy behaviour
    def fetch(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def update_customer(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def update_subscription(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def resume_subscription(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def pause_subscription_collection(_, _, _, _),
      do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def create_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def retrieve_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def update_invoice(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def finalize_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def void_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def pay_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def send_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def mark_uncollectible_invoice(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def create_invoice_preview(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def invoice_item_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def invoice_item_delete(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def create_payment_intent(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def retrieve_payment_intent(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def confirm_payment_intent(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def create_setup_intent(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def retrieve_setup_intent(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def confirm_setup_intent(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def create_payment_method(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def retrieve_payment_method(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def attach_payment_method(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def detach_payment_method(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def list_payment_methods(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def update_payment_method(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def set_default_payment_method(_, _, _),
      do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def create_charge(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def retrieve_charge(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def list_charges(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def create_refund(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def retrieve_refund(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def report_meter_event(_), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def subscription_item_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def subscription_item_update(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def subscription_item_delete(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def subscription_schedule_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def subscription_schedule_update(_, _, _),
      do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def subscription_schedule_release(_, _),
      do: {:error, %Accrue.APIError{message: "Unsupported"}}

    def subscription_schedule_cancel(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def subscription_schedule_fetch(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def coupon_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def coupon_retrieve(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def promotion_code_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def promotion_code_retrieve(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def checkout_session_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def checkout_session_fetch(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
    def portal_session_create(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
  end

  defmodule SubscriptionGatewayStub do
    def cancel(id, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: id,
         plan_id: "plan_sandbox_recurring",
         status: "Canceled",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-03T00:00:00Z"
       )}
    end
  end

  setup do
    # Save original processor config
    orig_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)
    Application.put_env(:accrue, :processor, BraintreeMockAdapter.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)

    on_exit(fn ->
      Application.put_env(:accrue, :processor, orig_processor)

      if previous_gateway do
        Application.put_env(:accrue, :braintree_subscription_gateway, previous_gateway)
      else
        Application.delete_env(:accrue, :braintree_subscription_gateway)
      end
    end)

    user = AccountsFixtures.user_fixture()
    organization = AccountsFixtures.organization_fixture(%{owner: user})

    membership =
      AccountsFixtures.organization_membership_fixture(%{
        organization: organization,
        user: user,
        role: :owner
      })

    scope = Scope.for_user(user) |> Scope.put_active_organization(organization, membership)

    %{scope: scope, user: user, organization: organization}
  end

  test "host Braintree path converts browser acquisition result, forwards it, and persists as braintree",
       %{scope: scope} do
    vault_reference = "fake-valid-nonce"
    sandbox_plan_id = "plan_sandbox_recurring"

    assert {:ok, %Accrue.Billing.Subscription{} = subscription} =
             Billing.subscribe_with_vault_reference(scope, sandbox_plan_id, vault_reference)

    assert subscription.processor == "braintree"
    assert subscription.processor_id == "sub_braintree_123"

    assert [item] = subscription.subscription_items
    assert item.price_id == sandbox_plan_id
  end

  test "hermetic Braintree proof exercises a lifecycle mutation through the generic billing facade",
       %{scope: scope} do
    assert {:ok, %Accrue.Billing.Subscription{} = subscription} =
             Billing.subscribe_with_vault_reference(
               scope,
               "plan_sandbox_recurring",
               "fake-valid-nonce"
             )

    assert {:ok, %Accrue.Billing.Subscription{} = canceled} = Billing.cancel(subscription)

    assert canceled.processor == "braintree"
    assert canceled.status == :canceled
  end
end
