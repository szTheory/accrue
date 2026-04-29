defmodule Accrue.Billing.SubscriptionActionsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  defmodule ReadOnlyProcessor do
    def processor_name, do: "read_only"

    def capabilities do
      %{
        customer: %{
          create: true,
          retrieve: true
        },
        subscription: %{
          fetch: true,
          lifecycle_webhook_projection: true
        },
        invoice: %{
          lifecycle_webhook_projection: true
        },
        webhook: %{
          verify: true,
          parse: true
        }
      }
    end
  end

  setup do
    previous = Application.get_env(:accrue, :processor)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    %{previous_processor: previous}
  end

  test "subscribe/3 keeps the fake-backed direct-create slice working", %{previous_processor: _previous} do
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_sub_guard",
        email: "sub-guard@example.com"
      })
      |> Repo.insert()

    assert {:ok, subscription} = Billing.subscribe(customer, "price_basic")
    assert subscription.processor == "fake"
    assert subscription.status in [:active, :trialing]
  end

  test "subscribe/3 returns invalid_request_error for malformed Braintree handoff" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_braintree_123",
        email: "bt@example.com"
      })
      |> Repo.insert()

    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Billing.subscribe(customer, "price_premium", payment_method: "pm_123")

    assert error.message =~ "require a vaulted payment_method_token passed as"

    assert {:error, %Accrue.APIError{code: "invalid_request_error"}} =
             Billing.subscribe(customer, "price_premium", payment_method: %{vault_acquisition: %{}})

    assert {:error, %Accrue.APIError{code: "invalid_request_error"}} =
             Billing.subscribe(customer, "price_premium")
  end

  test "subscribe/3 returns the unsupported-operation tuple when direct create is outside the slice" do
    Application.put_env(:accrue, :processor, ReadOnlyProcessor)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "read_only",
        processor_id: "cus_read_only_sub_guard",
        email: "read-only-sub-guard@example.com"
      })
      |> Repo.insert()

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
             Billing.subscribe(customer, "price_basic")

    assert error.message =~ "does not support subscription creation"
  end

  test "subscribe!/3 raises the same unsupported-operation error" do
    Application.put_env(:accrue, :processor, ReadOnlyProcessor)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "read_only",
        processor_id: "cus_read_only_sub_guard_bang",
        email: "read-only-sub-guard-bang@example.com"
      })
      |> Repo.insert()

    assert_raise Accrue.APIError, ~r/does not support subscription creation/, fn ->
      Billing.subscribe!(customer, "price_basic")
    end
  end
end
