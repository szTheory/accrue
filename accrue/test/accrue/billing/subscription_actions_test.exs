defmodule Accrue.Billing.SubscriptionActionsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  defmodule BraintreePlanResolver do
    @behaviour Accrue.PlanResolver

    @impl Accrue.PlanResolver
    def resolve_price("plan_basic") do
      {:ok,
       %{
         price_id: "plan_basic",
         processor: "braintree",
         processor_plan_id: "plan_basic",
         unit_amount_minor: 1_500,
         currency: "USD",
         billing_cycle: %{unit: :month, count: 1}
       }}
    end

    def resolve_price("plan_pro") do
      {:ok,
       %{
         price_id: "plan_pro",
         processor: "braintree",
         processor_plan_id: "plan_pro",
         unit_amount_minor: 3_000,
         currency: "USD",
         billing_cycle: %{unit: :month, count: 1}
       }}
    end

    def resolve_price("plan_yearly") do
      {:ok,
       %{
         price_id: "plan_yearly",
         processor: "braintree",
         processor_plan_id: "plan_yearly",
         unit_amount_minor: 25_000,
         currency: "USD",
         billing_cycle: %{unit: :year, count: 1}
       }}
    end

    def resolve_price("plan_eur") do
      {:ok,
       %{
         price_id: "plan_eur",
         processor: "braintree",
         processor_plan_id: "plan_eur",
         unit_amount_minor: 2_800,
         currency: "EUR",
         billing_cycle: %{unit: :month, count: 1}
       }}
    end

    def resolve_price(_price_id), do: {:error, :unknown_price_id}
  end

  defmodule BraintreeGatewayStub do
    def create(params, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_created",
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
         plan_id: "plan_basic",
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end

    def update(id, params, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
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
       struct!(Braintree.Subscription,
         id: id,
         plan_id: "plan_basic",
         status: "Canceled",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-03T00:00:00Z"
       )}
    end
  end

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
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)
    previous_plan_resolver = Application.get_env(:accrue, :plan_resolver)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_gateway do
        Application.put_env(:accrue, :braintree_subscription_gateway, previous_gateway)
      else
        Application.delete_env(:accrue, :braintree_subscription_gateway)
      end

      if previous_plan_resolver do
        Application.put_env(:accrue, :plan_resolver, previous_plan_resolver)
      else
        Application.delete_env(:accrue, :plan_resolver)
      end
    end)

    %{previous_processor: previous}
  end

  test "subscribe/3 keeps the fake-backed direct-create slice working", %{
    previous_processor: _previous
  } do
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
             Billing.subscribe(customer, "price_premium",
               payment_method: %{vault_acquisition: %{}}
             )

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

  test "Braintree cancel/2 converges local subscription state through the generic facade" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert length(subscription.subscription_items) == 1

    assert {:ok, canceled} = Billing.cancel(subscription)
    assert canceled.status == :canceled
    assert %DateTime{} = canceled.canceled_at
    assert %DateTime{} = canceled.ended_at
  end

  test "Braintree swap_plan/3 succeeds when the host configures a resolver" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)
    Application.put_env(:accrue, :plan_resolver, BraintreePlanResolver)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert {:ok, updated} =
             Billing.swap_plan(subscription, "plan_pro", proration: :none)

    assert updated.id == subscription.id
  end

  test "Braintree swap_plan/3 fails cleanly when no plan resolver is configured" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)
    Application.delete_env(:accrue, :plan_resolver)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert {:error, %Accrue.APIError{code: "plan_resolution_unavailable"} = error} =
             Billing.swap_plan(subscription, "plan_pro", proration: :none)

    assert error.message =~ "requires a configured :plan_resolver"
  end

  test "Braintree swap_plan/3 rejects billing-cycle mismatches explicitly" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)
    Application.put_env(:accrue, :plan_resolver, BraintreePlanResolver)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Billing.swap_plan(subscription, "plan_yearly", proration: :none)

    assert error.message =~ "only supports plan changes within the same billing cycle"
  end

  test "Braintree swap_plan/3 rejects currency mismatches explicitly" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)
    Application.put_env(:accrue, :plan_resolver, BraintreePlanResolver)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
             Billing.swap_plan(subscription, "plan_eur", proration: :none)

    assert error.message =~ "requires matching currencies"
  end

  test "update_quantity/3 stays in the official Fake-first active-change lane" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_quantity_guard",
        email: "quantity-guard@example.com"
      })
      |> Repo.insert()

    assert {:ok, subscription} = Billing.subscribe(customer, "price_basic")

    assert {:ok, updated} = Billing.update_quantity(subscription, 4)

    assert updated.id == subscription.id
    assert Enum.map(updated.subscription_items, & &1.quantity) == [4]
  end

  test "Braintree update_quantity/3 rejects unsupported quantity semantics explicitly" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
             Billing.update_quantity(subscription, 4)

    assert error.message =~ "update_quantity/3 semantic"
  end

  test "Braintree pause/2 rejects unsupported collection semantics explicitly" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
             Billing.pause(subscription)

    assert error.message =~ "pause/2"
  end

  test "Braintree unpause/2 and resume/2 reject provider semantics explicitly" do
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)

    customer = insert_braintree_customer!()

    assert {:ok, subscription} =
             Billing.subscribe(
               customer,
               "plan_basic",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    paused = %{subscription | pause_collection: %{"behavior" => "void"}}

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = unpause_error} =
             Billing.unpause(paused)

    assert unpause_error.message =~ "unpause/2"

    canceling = %{
      subscription
      | cancel_at_period_end: true,
        current_period_end: DateTime.add(Accrue.Clock.utc_now(), 3600, :second)
    }

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = resume_error} =
             Billing.resume(canceling)

    assert resume_error.message =~ "resume/2"
  end

  defp insert_braintree_customer! do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_braintree_test_#{System.unique_integer([:positive])}",
        email: "bt-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    customer
  end
end
