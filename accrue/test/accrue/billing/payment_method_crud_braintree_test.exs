defmodule Accrue.Billing.PaymentMethodCrudBraintreeTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, PaymentMethod, Subscription}

  defmodule BraintreeCRUDStub do
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> %{payment_methods: %{}} end, name: __MODULE__)
    end

    def reset(payment_methods \\ %{}) do
      if Process.whereis(__MODULE__) do
        Agent.update(__MODULE__, fn _ -> %{payment_methods: payment_methods} end)
      else
        {:ok, _pid} = start_link([])
        reset(payment_methods)
      end

      :ok
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

    def create_payment_method(params, _opts) do
      vault =
        params
        |> Map.get(:vault_acquisition, Map.get(params, "vault_acquisition", %{}))

      reference = vault[:reference] || vault["reference"]

      case reference do
        nil ->
          {:error,
           %Accrue.APIError{
             code: "invalid_request_error",
             http_status: 400,
             message: "Braintree add_payment_method requires vault_acquisition.reference"
           }}

        _ ->
          pm = payment_method(reference, params)
          Agent.update(__MODULE__, &put_in(&1, [:payment_methods, pm.id], pm))
          {:ok, pm}
      end
    end

    def retrieve_payment_method(id, _opts) do
      case Agent.get(__MODULE__, &get_in(&1, [:payment_methods, id])) do
        nil ->
          {:error,
           %Accrue.APIError{
             code: "not_found",
             http_status: 404,
             message: "payment method #{id} not found"
           }}

        pm ->
          {:ok, pm}
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
           replacement <- payment_method(Map.get(params, :replacement_reference) || params["replacement_reference"], params) do
        updated =
          existing
          |> Map.merge(replacement)
          |> Map.put(:id, "pm_bt_repl_" <> suffix(replacement.id))
          |> Map.put(:customer, existing.customer)

        Agent.update(__MODULE__, fn state ->
          state
          |> update_in([:payment_methods], &Map.delete(&1, id))
          |> put_in([:payment_methods, updated.id], updated)
        end)

        {:ok, updated}
      end
    end

    def detach_payment_method(id, _opts) do
      with {:ok, pm} <- retrieve_payment_method(id, []) do
        Agent.update(__MODULE__, fn state ->
          update_in(state.payment_methods, &Map.delete(&1, id))
        end)

        {:ok, pm}
      end
    end

    def set_default_payment_method(customer_id, params, _opts) do
      default_id =
        get_in(params, [:invoice_settings, :default_payment_method]) ||
          get_in(params, ["invoice_settings", "default_payment_method"])

      {:ok, %{id: customer_id, default_payment_method: default_id}}
    end

    defp payment_method(reference, params) do
      attrs = Map.new(params)
      default? = Map.get(attrs, :make_default, Map.get(attrs, "make_default", false))

      %{
        id: "pm_bt_" <> suffix(reference),
        object: "payment_method",
        type: "card",
        customer: Map.get(attrs, :customer, Map.get(attrs, "customer")),
        default: default?,
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
    Application.put_env(:accrue, :processor, BraintreeCRUDStub)
    :ok = BraintreeCRUDStub.reset()

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_bt_phase98",
        email: "phase98@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "add_payment_method/3 requires vault_acquisition.reference for braintree", %{
    customer: customer
  } do
    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Billing.add_payment_method(customer, %{}, [])

    assert error.message =~ "vault_acquisition.reference"
  end

  test "add_payment_method/3 writes through and refreshes the local projection", %{
    customer: customer
  } do
    assert {:ok, %PaymentMethod{} = payment_method} =
             Billing.add_payment_method(
               customer,
               %{vault_acquisition: %{reference: "vault_tok_4242"}},
               []
             )

    assert payment_method.processor == "braintree"
    assert payment_method.card_last4 == "4242"
    assert payment_method.customer_id == customer.id

    assert {:ok, listed} = Billing.list_payment_methods(customer, [])
    assert Enum.map(listed, & &1.id) == [payment_method.id]
  end

  test "update_payment_method/3 performs replacement semantics and can reassign default", %{
    customer: customer
  } do
    {:ok, original} =
      Billing.add_payment_method(
        customer,
        %{vault_acquisition: %{reference: "vault_tok_1111"}},
        []
      )

    {:ok, customer} = Billing.set_default_payment_method(customer, original, [])

    assert {:ok, %PaymentMethod{} = replacement} =
             Billing.update_payment_method(
               original,
               %{replacement_reference: "vault_tok_2222", make_default: true},
               []
             )

    assert replacement.id != original.id
    assert replacement.card_last4 == "2222"
    assert Repo.get(PaymentMethod, original.id) == nil
    assert Repo.get!(Customer, customer.id).default_payment_method_id == replacement.id
  end

  test "delete_payment_method/2 blocks default deletion when another usable method exists", %{
    customer: customer
  } do
    {:ok, default_pm} =
      Billing.add_payment_method(customer, %{vault_acquisition: %{reference: "vault_tok_1111"}}, [])

    {:ok, _other_pm} =
      Billing.add_payment_method(customer, %{vault_acquisition: %{reference: "vault_tok_2222"}}, [])

    {:ok, _customer} = Billing.set_default_payment_method(customer, default_pm, [])

    assert {:error, %Accrue.APIError{code: "payment_method_replacement_required"} = error} =
             Billing.delete_payment_method(default_pm, [])

    assert error.message =~ "replacement"
  end

  test "delete_payment_method/2 blocks deletion when an active braintree subscription still uses the token",
       %{customer: customer} do
    {:ok, payment_method} =
      Billing.add_payment_method(customer, %{vault_acquisition: %{reference: "vault_tok_3333"}}, [])

    {:ok, customer} = Billing.set_default_payment_method(customer, payment_method, [])

    {:ok, _subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_bt_active",
        status: :active,
        data: %{"payment_method_token" => payment_method.processor_id}
      })
      |> Repo.insert()

    assert {:error, %Accrue.APIError{code: "payment_method_still_in_use"} = error} =
             Billing.delete_payment_method(payment_method, [])

    assert error.message =~ "active subscription"
  end

  test "delete_payment_method/2 allows deleting the last remaining default when no active dependency blocks removal",
       %{customer: customer} do
    {:ok, payment_method} =
      Billing.add_payment_method(customer, %{vault_acquisition: %{reference: "vault_tok_4444"}}, [])

    {:ok, customer} = Billing.set_default_payment_method(customer, payment_method, [])

    assert {:ok, %PaymentMethod{id: deleted_id}} = Billing.delete_payment_method(payment_method, [])
    assert deleted_id == payment_method.id
    assert Repo.get(PaymentMethod, payment_method.id) == nil
    assert Repo.get!(Customer, customer.id).default_payment_method_id == nil
  end

  test "sync_payment_methods/2 repairs local drift while list_payment_methods/2 stays local-row-first",
       %{customer: customer} do
    stale =
      Repo.insert!(PaymentMethod.changeset(%PaymentMethod{}, %{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "pm_bt_stale",
        type: "card",
        fingerprint: "fp_stale",
        card_brand: "visa",
        card_last4: "0000"
      }))

    :ok =
      BraintreeCRUDStub.reset(%{
        "pm_bt_live5555" => %{
          id: "pm_bt_live5555",
          object: "payment_method",
          type: "card",
          customer: customer.processor_id,
          card: %{brand: "visa", last4: "5555", exp_month: 12, exp_year: 2035, fingerprint: "fp_live5555"}
        }
      })

    assert {:ok, listed_before_sync} = Billing.list_payment_methods(customer, [])
    assert Enum.map(listed_before_sync, & &1.id) == [stale.id]

    assert {:ok, synced} = Billing.sync_payment_methods(customer, [])
    assert Enum.map(synced, & &1.card_last4) == ["5555"]

    assert {:ok, listed_after_sync} = Billing.list_payment_methods(customer, [])
    assert Enum.map(listed_after_sync, & &1.card_last4) == ["5555"]
  end
end
