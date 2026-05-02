defmodule Accrue.Processor.BraintreeTest do
  use ExUnit.Case, async: true

  alias Accrue.Processor.Braintree

  defmodule CustomerGatewayStub do
    def create(params, _opts) do
      {:ok,
       %{
         id: "cus_bt_123",
         company: params["company"],
         email: params["email"],
         custom_fields: %{"source" => "stubbed"}
       }}
    end

    def find(id, _opts) do
      {:ok,
       %{
         id: id,
         company: "ACME Billing",
         email: "billing@example.com",
         custom_fields: %{"source" => "stubbed"},
         default_payment_method_token: "pm_bt_default_1111",
         payment_methods: [
           %{
             token: "pm_bt_default_1111",
             default: true,
             card_type: "Visa",
             last_4: "1111",
             expiration_month: "12",
             expiration_year: "2035",
             unique_number_identifier: "fingerprint_1111"
           },
           %{
             token: "pm_bt_second_2222",
             default: false,
             card_type: "Mastercard",
             last_4: "2222",
             expiration_month: "10",
             expiration_year: "2036",
             unique_number_identifier: "fingerprint_2222"
           }
         ]
       }}
    end

    def update(id, params, _opts) do
      {:ok,
       %{
         id: id,
         company: params["company"] || "ACME Billing",
         email: params["email"] || "billing@example.com",
         custom_fields: %{"source" => "stubbed"}
       }}
    end
  end

  defmodule PaymentMethodGatewayStub do
    def create(params, _opts) do
      {:ok,
       %{
         token: "pm_bt_created_4242",
         customer_id: params[:customer_id],
         default: false,
         card_type: "Visa",
         last_4: "4242",
         expiration_month: "12",
         expiration_year: "2035",
         unique_number_identifier: "fingerprint_4242"
       }}
    end

    def find(id, _opts) do
      {:ok,
       %{
         token: id,
         customer_id: "cus_bt_123",
         default: false,
         card_type: "Visa",
         last_4: "1111",
         expiration_month: "12",
         expiration_year: "2035",
         unique_number_identifier: "fingerprint_1111"
       }}
    end

    def update(id, params, _opts) do
      {:ok,
       %{
         token: id,
         customer_id: "cus_bt_123",
         default: params[:options][:make_default],
         card_type: "Visa",
         last_4: "9999",
         expiration_month: "01",
         expiration_year: "2037",
         unique_number_identifier: "fingerprint_9999"
       }}
    end

    def delete(id, _opts) do
      {:ok, %{token: id}}
    end
  end

  defmodule SubscriptionGatewayStub do
    def create(params, _opts) do
      {:ok,
       struct!(Elixir.Braintree.Subscription,
         id: "sub_bt_123",
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
       struct!(Elixir.Braintree.Subscription,
         id: id,
         plan_id: "plan_basic",
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end

    def update(id, params, _opts) do
      {:ok,
       struct!(Elixir.Braintree.Subscription,
         id: id,
         plan_id: params[:plan_id] || "plan_basic",
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-02T00:00:00Z"
       )}
    end

    def cancel(id, _opts) do
      {:ok,
       struct!(Elixir.Braintree.Subscription,
         id: id,
         plan_id: "plan_basic",
         status: "Canceled",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-03T00:00:00Z"
       )}
    end
  end

  defmodule TransactionGatewayStub do
    def refund(id, amount, _opts \\ []) do
      if amount == "invalid" do
        {:error, %Elixir.Braintree.ErrorResponse{message: "Amount is invalid"}}
      else
        {:ok,
         %{
           id: "ref_bt_456",
           type: "credit",
           status: "submitted_for_settlement",
           amount: amount || "10.00",
           currency_iso_code: "USD",
           refunded_transaction_id: id
         }}
      end
    end

    def find(id, _opts) do
      if id == "not_found" do
        {:error, %Elixir.Braintree.ErrorResponse{message: "Not Found"}}
      else
        {:ok,
         %{
           id: id,
           type: "credit",
           status: "settled",
           amount: "10.00",
           currency_iso_code: "USD",
           refunded_transaction_id: "ch_bt_123"
         }}
      end
    end
  end

  setup do
    previous = Application.get_env(:accrue, :braintree_subscription_gateway)
    previous_customer = Application.get_env(:accrue, :braintree_customer_gateway)
    previous_payment_method = Application.get_env(:accrue, :braintree_payment_method_gateway)
    previous_transaction = Application.get_env(:accrue, :braintree_transaction_gateway)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)
    Application.put_env(:accrue, :braintree_customer_gateway, CustomerGatewayStub)
    Application.put_env(:accrue, :braintree_payment_method_gateway, PaymentMethodGatewayStub)
    Application.put_env(:accrue, :braintree_transaction_gateway, TransactionGatewayStub)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :braintree_subscription_gateway, previous)
      else
        Application.delete_env(:accrue, :braintree_subscription_gateway)
      end

      if previous_customer do
        Application.put_env(:accrue, :braintree_customer_gateway, previous_customer)
      else
        Application.delete_env(:accrue, :braintree_customer_gateway)
      end

      if previous_payment_method do
        Application.put_env(:accrue, :braintree_payment_method_gateway, previous_payment_method)
      else
        Application.delete_env(:accrue, :braintree_payment_method_gateway)
      end

      if previous_transaction do
        Application.put_env(:accrue, :braintree_transaction_gateway, previous_transaction)
      else
        Application.delete_env(:accrue, :braintree_transaction_gateway)
      end
    end)

    :ok
  end

  test "processor_name/0 returns braintree" do
    assert Braintree.processor_name() == "braintree"
  end

  test "capabilities/0 exposes payment-method CRUD alongside the supported gateway-subscription-core callbacks" do
    caps = Braintree.capabilities()

    assert caps.payment_method.vault_acquisition == true
    assert get_in(caps, [:payment_method, :create]) == true
    assert get_in(caps, [:payment_method, :list]) == true
    assert get_in(caps, [:payment_method, :update]) == true
    assert get_in(caps, [:payment_method, :delete]) == true
    assert get_in(caps, [:payment_method, :set_default]) == true
    assert caps.subscription.direct_create == true
    assert caps.subscription.cancel == true
    assert caps.subscription.fetch == true
    assert caps.subscription.lifecycle_webhook_projection == true
    assert caps.subscription.update == true
    assert caps.subscription.cancel_immediately == true
    assert caps.subscription.cancel_at_period_end == false
    assert caps.subscription.pause == false
    assert caps.subscription.resume == false
    assert get_in(caps, [:checkout, :create]) == true
    assert get_in(caps, [:checkout, :fetch]) == true
    assert get_in(caps, [:checkout, :hosted]) == true
    assert get_in(caps, [:checkout, :embedded]) == false
    assert caps.invoice.lifecycle_webhook_projection == true
    assert caps.webhook.verify == true
    assert caps.webhook.parse == true
    assert get_in(caps, [:billing_portal, :create]) == true
  end

  test "build_request/1 maps price_id to plan_id and accepts only payment_method.vault_acquisition.reference" do
    params = %{
      payment_method: %{vault_acquisition: %{reference: "vaulted_token_abc"}},
      items: [%{price: "premium_monthly"}]
    }

    assert Braintree.build_request(params) == %{
             payment_method_token: "vaulted_token_abc",
             plan_id: "premium_monthly"
           }
  end

  test "translate_subscription/1 converts Braintree.Subscription struct to a plain map" do
    braintree_sub = %Elixir.Braintree.Subscription{
      id: "sub_123",
      plan_id: "premium_monthly",
      status: "Active"
    }

    accrue_map = Braintree.translate_subscription(braintree_sub)

    assert is_map(accrue_map)
    refute Map.has_key?(accrue_map, :__struct__)
    assert accrue_map.id == "sub_123"
    assert accrue_map.plan_id == "premium_monthly"
    assert accrue_map.status == "Active"

    assert [%{id: "sub_123:plan", price: %{id: "premium_monthly"}, quantity: 1}] =
             accrue_map.items
  end

  test "customer callbacks create, retrieve, and update through the gateway" do
    assert {:ok, created} =
             Braintree.create_customer(%{name: "ACME Billing", email: "billing@example.com"}, [])

    assert created.id == "cus_bt_123"
    assert created.name == "ACME Billing"
    assert created.email == "billing@example.com"
    assert created.metadata == %{"source" => "stubbed"}

    assert {:ok, retrieved} = Braintree.retrieve_customer("cus_bt_123", [])
    assert retrieved.name == "ACME Billing"
    assert retrieved.email == "billing@example.com"

    assert {:ok, updated} =
             Braintree.update_customer("cus_bt_123", %{name: "Updated Billing"}, [])

    assert updated.id == "cus_bt_123"
    assert updated.name == "Updated Billing"
  end

  test "update_subscription/3 maps a plan swap onto Braintree update" do
    assert {:ok, updated} =
             Braintree.update_subscription(
               "sub_bt_123",
               %{items: [%{id: "sub_bt_123:plan", price: "plan_pro"}]},
               []
             )

    assert updated.plan_id == "plan_pro"
  end

  test "update_subscription/3 rejects quantity updates explicitly" do
    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Braintree.update_subscription(
               "sub_bt_123",
               %{items: [%{id: "sub_bt_123:plan", quantity: 4}]},
               []
             )

    assert error.message =~ "quantity mutation semantics"
  end

  test "cancel_subscription/2 and /3 route immediate cancellation and reject unsupported flags" do
    assert {:ok, canceled} = Braintree.cancel_subscription("sub_bt_123", [])
    assert canceled.status == "Canceled"

    assert {:ok, canceled} =
             Braintree.cancel_subscription(
               "sub_bt_123",
               %{invoice_now: false, prorate: false},
               []
             )

    assert canceled.status == "Canceled"

    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Braintree.cancel_subscription("sub_bt_123", %{invoice_now: true}, [])

    assert error.message =~ "invoice_now"
  end

  test "resume_subscription/2 and pause_subscription_collection/4 reject unsupported semantics" do
    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = resume_error} =
             Braintree.resume_subscription("sub_bt_123", [])

    assert resume_error.message =~ "resume"

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = pause_error} =
             Braintree.pause_subscription_collection("sub_bt_123", :void, %{}, [])

    assert pause_error.message =~ "pause collection"
  end

  test "create_payment_method/2 requires vault_acquisition.reference and translates the gateway response" do
    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Braintree.create_payment_method(%{}, [])

    assert error.message =~ "vault_acquisition.reference"

    assert {:ok, payment_method} =
             Braintree.create_payment_method(
               %{customer: "cus_bt_123", vault_acquisition: %{reference: "nonce-from-host"}},
               []
             )

    assert payment_method.id == "pm_bt_created_4242"
    assert payment_method.customer == "cus_bt_123"
    assert payment_method.card.last4 == "4242"
  end

  test "retrieve/list/update/delete/set_default payment-method callbacks are provider-honest" do
    assert {:ok, payment_method} = Braintree.retrieve_payment_method("pm_bt_default_1111", [])
    assert payment_method.id == "pm_bt_default_1111"
    assert payment_method.card.fingerprint == "fingerprint_1111"

    assert {:ok, %{data: methods}} = Braintree.list_payment_methods(%{customer: "cus_bt_123"}, [])
    assert Enum.map(methods, & &1.id) == ["pm_bt_default_1111", "pm_bt_second_2222"]

    assert {:ok, updated} =
             Braintree.update_payment_method(
               "pm_bt_default_1111",
               %{replacement_reference: "replacement_nonce", make_default: true},
               []
             )

    assert updated.card.last4 == "9999"
    assert updated.default == true

    assert {:ok, %{id: "cus_bt_123", default_payment_method: "pm_bt_second_2222"}} =
             Braintree.set_default_payment_method(
               "cus_bt_123",
               %{invoice_settings: %{default_payment_method: "pm_bt_second_2222"}},
               []
             )

    assert {:ok, %{id: "pm_bt_default_1111"}} =
             Braintree.detach_payment_method("pm_bt_default_1111", [])
  end

  test "create_refund/2 creates a refund via Transaction gateway" do
    assert {:ok, refund} = Braintree.create_refund(%{charge: "ch_bt_123", amount: "15.00"}, [])
    assert refund.id == "ref_bt_456"
    assert refund.status == "pending"
    assert refund.amount == "15.00"
    assert refund.currency == "USD"
    assert refund.charge == "ch_bt_123"

    assert {:error, %Accrue.APIError{code: "invalid_request_error"}} =
             Braintree.create_refund(%{charge: "ch_bt_123", amount: "invalid"}, [])
  end

  test "retrieve_refund/2 retrieves a refund via Transaction gateway" do
    assert {:ok, refund} = Braintree.retrieve_refund("ref_bt_456", [])
    assert refund.id == "ref_bt_456"
    assert refund.status == "succeeded"
    assert refund.amount == "10.00"
    assert refund.currency == "USD"
    assert refund.charge == "ch_bt_123"

    assert {:error, %Accrue.APIError{code: "braintree_error"}} =
             Braintree.retrieve_refund("not_found", [])
  end

  test "fetch/2 fetches a refund" do
    assert {:ok, refund} = Braintree.fetch(:refund, "ref_bt_456")
    assert refund.id == "ref_bt_456"
    assert refund.status == "succeeded"
  end
end
