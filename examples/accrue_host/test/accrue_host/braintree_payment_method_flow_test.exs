defmodule AccrueHost.BraintreePaymentMethodFlowTest do
  use AccrueHost.AccrueCase, async: false

  @host_root Path.expand("../..", __DIR__)

  alias Accrue.Billing.PaymentMethod
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

    def processor_name, do: "braintree"

    def capabilities do
      %{
        customer: %{create: true, retrieve: true, update: true},
        payment_method: %{
          vault_acquisition: true,
          list: true,
          create: true,
          update: true,
          delete: true,
          set_default: true
        },
        subscription: %{direct_create: true, fetch: true, cancel: true, update: true},
        invoice: %{lifecycle_webhook_projection: true},
        webhook: %{verify: true, parse: true}
      }
    end

    def create_customer(params, _opts) do
      customer = %{
        id: "cus_bt_host_scope",
        email: params[:email] || params["email"],
        name: params[:name] || params["name"],
        metadata: %{}
      }

      Agent.update(__MODULE__, &Map.put(&1, :customer, customer))
      {:ok, customer}
    end

    def retrieve_customer(id, _opts) do
      {:ok, Agent.get(__MODULE__, &(&1.customer || %{id: id, email: nil, name: nil, metadata: %{}}))}
    end

    def create_payment_method(params, _opts) do
      reference = get_in(params, [:vault_acquisition, :reference]) || get_in(params, ["vault_acquisition", "reference"])

      payment_method = payment_method(reference, params)

      Agent.update(__MODULE__, fn state ->
        state
        |> Map.put(:last_create_params, Map.new(params))
        |> put_in([:payment_methods, payment_method.id], payment_method)
      end)

      {:ok, payment_method}
    end

    def retrieve_payment_method(id, _opts) do
      case Agent.get(__MODULE__, &get_in(&1, [:payment_methods, id])) do
        nil -> {:error, %Accrue.APIError{code: "not_found", http_status: 404, message: "payment method #{id} not found"}}
        payment_method -> {:ok, payment_method}
      end
    end

    def list_payment_methods(%{customer: customer_id}, _opts) do
      methods =
        __MODULE__
        |> Agent.get(& &1.payment_methods)
        |> Map.values()
        |> Enum.filter(&(&1.customer == customer_id))

      {:ok, %{data: methods}}
    end

    def list_payment_methods(_params, _opts), do: {:ok, %{data: []}}

    def update_payment_method(id, params, _opts) do
      with {:ok, existing} <- retrieve_payment_method(id, []),
           replacement_reference when is_binary(replacement_reference) <-
             Map.get(params, :replacement_reference) || params["replacement_reference"] do
        replacement =
          replacement_reference
          |> payment_method(params)
          |> Map.put(:id, "pm_bt_repl_" <> suffix(replacement_reference))
          |> Map.put(:customer, existing.customer)

        Agent.update(__MODULE__, fn state ->
          state
          |> Map.put(:last_update_call, %{id: id, params: Map.new(params)})
          |> update_in([:payment_methods], &Map.delete(&1, id))
          |> put_in([:payment_methods, replacement.id], replacement)
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

    def detach_payment_method(id, _opts), do: retrieve_payment_method(id, [])

    def set_default_payment_method(_customer_id, params, _opts) do
      default_id =
        get_in(params, [:invoice_settings, :default_payment_method]) ||
          get_in(params, ["invoice_settings", "default_payment_method"])

      Agent.update(__MODULE__, &Map.put(&1, :default_payment_method_id, default_id))
      {:ok, %{id: "cus_bt_host_scope", default_payment_method: default_id}}
    end

    defp payment_method(reference, params) do
      %{
        id: "pm_bt_" <> suffix(reference),
        object: "payment_method",
        type: "card",
        customer: params[:customer] || params["customer"],
        default: Map.get(params, :make_default, Map.get(params, "make_default", false)),
        card: %{
          brand: "visa",
          last4: String.slice(reference, -4, 4),
          exp_month: 12,
          exp_year: 2035,
          fingerprint: "fp_" <> suffix(reference)
        }
      }
    end

    defp suffix(reference) when is_binary(reference) do
      reference
      |> String.replace(~r/[^a-zA-Z0-9]/, "")
      |> String.downcase()
    end
  end

  setup do
    previous = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :processor, BraintreePaymentMethodStub)
    :ok = BraintreePaymentMethodStub.reset()

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
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

    assert create_params["customer"] == customer.processor_id
    assert get_in(create_params, ["vault_acquisition", "reference"]) == "host_nonce_4242"

    source = File.read!(Path.join(@host_root, "lib/accrue_host/billing.ex"))
    assert source =~ "def add_payment_method_with_vault_reference(%Scope{} = scope, vault_reference, opts \\\\ []) do"
    assert source =~ "Billing.add_payment_method(customer, %{vault_acquisition: %{reference: vault_reference}}, opts)"
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
    assert update_call.params["make_default"] == true
    assert update_call.params["replacement_reference"] == "host_nonce_2222"
  end
end
