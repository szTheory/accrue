defmodule AccrueHost.BraintreePaymentMethodFlowTest do
  use AccrueHost.AccrueCase, async: false

  @host_root Path.expand("../..", __DIR__)

  alias Accrue.Billing.PaymentMethod
  alias Accrue.Processor.Braintree
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  defmodule BraintreePaymentMethodStub do
    use Agent

    def start_link(_opts) do
      Agent.start_link(
        fn ->
          %{
            customer: nil,
            payment_methods: %{},
            default_payment_method_id: nil,
            last_create_params: nil,
            last_update_call: nil
          }
        end,
        name: __MODULE__
      )
    end

    def reset do
      if Process.whereis(__MODULE__) do
        Agent.update(__MODULE__, fn _ ->
          %{
            customer: nil,
            payment_methods: %{},
            default_payment_method_id: nil,
            last_create_params: nil,
            last_update_call: nil
          }
        end)
      else
        {:ok, _pid} = start_link([])
      end

      :ok
    end

    def last_create_params do
      Agent.get(__MODULE__, & &1.last_create_params)
    end

    def last_update_call do
      Agent.get(__MODULE__, & &1.last_update_call)
    end

    def create_customer(params) do
      customer = %{
        id: "cus_bt_host_scope",
        company: params["company"],
        email: params["email"],
        custom_fields: %{}
      }

      Agent.update(__MODULE__, &Map.put(&1, :customer, customer))
      {:ok, customer}
    end

    def retrieve_customer(id) do
      {:ok,
       Agent.get(__MODULE__, fn state ->
         base = state.customer || %{id: id, company: nil, email: nil, custom_fields: %{}}

         base
         |> Map.put(:payment_methods, Map.values(state.payment_methods))
         |> Map.put(:default_payment_method_token, state.default_payment_method_id)
       end)}
    end

    def create_payment_method(params) do
      reference = params[:payment_method_nonce] || params["payment_method_nonce"]

      payment_method = payment_method(reference, params)

      Agent.update(__MODULE__, fn state ->
        state
        |> Map.put(:last_create_params, Map.new(params))
        |> put_in([:payment_methods, payment_method.token], payment_method)
        |> maybe_set_initial_default(payment_method.token)
      end)

      {:ok, payment_method}
    end

    def retrieve_payment_method(id) do
      case Agent.get(__MODULE__, &get_in(&1, [:payment_methods, id])) do
        nil ->
          {:error,
           %Accrue.APIError{
             code: "not_found",
             http_status: 404,
             message: "payment method #{id} not found"
           }}

        payment_method ->
          {:ok, payment_method}
      end
    end

    def list_payment_methods(%{customer: customer_id}) do
      methods =
        __MODULE__
        |> Agent.get(& &1.payment_methods)
        |> Map.values()
        |> Enum.filter(&(&1.customer_id == customer_id))

      {:ok, %{data: methods}}
    end

    def list_payment_methods(_params), do: {:ok, %{data: []}}

    def update_payment_method(id, params) do
      with {:ok, existing} <- retrieve_payment_method(id),
           replacement_reference when is_binary(replacement_reference) <-
             Map.get(params, :payment_method_nonce) || params["payment_method_nonce"] do
        replacement =
          replacement_reference
          |> payment_method(params)
          |> Map.put(:token, "pm_bt_repl_" <> suffix(replacement_reference))
          |> Map.put(:customer_id, existing.customer_id)

        Agent.update(__MODULE__, fn state ->
          state
          |> Map.put(:last_update_call, %{id: id, params: Map.new(params)})
          |> update_in([:payment_methods], &Map.delete(&1, id))
          |> put_in([:payment_methods, replacement.token], replacement)
          |> maybe_promote_default(replacement, id)
        end)

        {:ok, replacement}
      else
        _ ->
          {:error,
           %Accrue.APIError{
             code: "invalid_request_error",
             http_status: 400,
             message: "replacement_reference is required"
           }}
      end
    end

    def detach_payment_method(id), do: retrieve_payment_method(id)

    def set_default_payment_method(_customer_id, params) do
      default_id =
        get_in(params, [:invoice_settings, :default_payment_method]) ||
          get_in(params, ["invoice_settings", "default_payment_method"])

      Agent.update(__MODULE__, &Map.put(&1, :default_payment_method_id, default_id))
      {:ok, %{id: "cus_bt_host_scope", default_payment_method: default_id}}
    end

    defp payment_method(reference, params) do
      %{
        token: "pm_bt_" <> suffix(reference),
        customer_id:
          params[:customer_id] || params["customer_id"] || params[:customer] || params["customer"],
        default:
          get_in(params, [:options, :make_default]) ||
            get_in(params, ["options", "make_default"]) ||
            Map.get(params, :make_default, Map.get(params, "make_default", false)),
        card_type: "visa",
        last_4: String.slice(reference, -4, 4),
        expiration_month: 12,
        expiration_year: 2035,
        unique_number_identifier: "fp_" <> suffix(reference)
      }
    end

    defp suffix(reference) when is_binary(reference) do
      reference
      |> String.replace(~r/[^a-zA-Z0-9]/, "")
      |> String.downcase()
    end

    defp maybe_promote_default(state, replacement, previous_token) do
      if state.default_payment_method_id == previous_token || replacement.default do
        Map.put(state, :default_payment_method_id, replacement.token)
      else
        state
      end
    end

    defp maybe_set_initial_default(state, token) do
      if is_nil(state.default_payment_method_id) do
        Map.put(state, :default_payment_method_id, token)
      else
        state
      end
    end
  end

  defmodule CustomerGatewayStub do
    def create(params, _opts), do: BraintreePaymentMethodStub.create_customer(params)
    def find(id, _opts), do: BraintreePaymentMethodStub.retrieve_customer(id)
    def update(id, _params, _opts), do: BraintreePaymentMethodStub.retrieve_customer(id)
  end

  defmodule PaymentMethodGatewayStub do
    def create(params, _opts), do: BraintreePaymentMethodStub.create_payment_method(params)
    def find(id, _opts), do: BraintreePaymentMethodStub.retrieve_payment_method(id)

    def update(id, params, _opts),
      do: BraintreePaymentMethodStub.update_payment_method(id, params)

    def delete(id, _opts), do: BraintreePaymentMethodStub.detach_payment_method(id)
  end

  setup do
    previous = Application.get_env(:accrue, :processor)
    previous_customer_gateway = Application.get_env(:accrue, :braintree_customer_gateway)

    previous_payment_method_gateway =
      Application.get_env(:accrue, :braintree_payment_method_gateway)

    Application.put_env(:accrue, :processor, Braintree)
    Application.put_env(:accrue, :braintree_customer_gateway, CustomerGatewayStub)
    Application.put_env(:accrue, :braintree_payment_method_gateway, PaymentMethodGatewayStub)
    :ok = BraintreePaymentMethodStub.reset()

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_customer_gateway do
        Application.put_env(:accrue, :braintree_customer_gateway, previous_customer_gateway)
      else
        Application.delete_env(:accrue, :braintree_customer_gateway)
      end

      if previous_payment_method_gateway do
        Application.put_env(
          :accrue,
          :braintree_payment_method_gateway,
          previous_payment_method_gateway
        )
      else
        Application.delete_env(:accrue, :braintree_payment_method_gateway)
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

    %{scope: scope}
  end

  test "add_payment_method_with_vault_reference/3 stays host-owned and uses Billing.add_payment_method/3",
       %{scope: scope} do
    assert {:ok, customer} = Billing.customer_for_scope(scope)

    assert {:ok, %PaymentMethod{} = payment_method} =
             Billing.add_payment_method_with_vault_reference(scope, "host_nonce_4242")

    assert payment_method.processor == "braintree"
    assert payment_method.card_last4 == "4242"
    assert payment_method.customer_id == customer.id

    create_params = BraintreePaymentMethodStub.last_create_params()

    assert create_params[:customer_id] == customer.processor_id
    assert create_params[:payment_method_nonce] == "host_nonce_4242"

    source = File.read!(Path.join(@host_root, "lib/accrue_host/billing.ex"))

    assert source =~
             "def add_payment_method_with_vault_reference(%Scope{} = scope, vault_reference, opts \\\\ []) do"

    assert source =~ "Billing.add_payment_method("
    assert source =~ "%{vault_acquisition: %{reference: vault_reference}}"
    assert source =~ "opts"

    refute source =~ "AccrueAdmin"
    refute source =~ "Drop-in"
  end

  test "replace_payment_method_with_vault_reference/4 stays host-owned and uses Billing.update_payment_method/3",
       %{scope: scope} do
    assert {:ok, original} =
             Billing.add_payment_method_with_vault_reference(scope, "host_nonce_1111")

    assert {:ok, %PaymentMethod{} = replacement} =
             Billing.replace_payment_method_with_vault_reference(
               scope,
               original,
               "host_nonce_2222"
             )

    assert replacement.id != original.id
    assert replacement.card_last4 == "2222"
    assert Repo.get(PaymentMethod, original.id) == nil

    update_call = BraintreePaymentMethodStub.last_update_call()

    assert update_call.id == original.processor_id
    assert get_in(update_call.params, [:options, :make_default]) == true
    assert update_call.params[:payment_method_nonce] == "host_nonce_2222"
  end
end
