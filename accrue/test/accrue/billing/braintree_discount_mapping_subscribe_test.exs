defmodule Accrue.Billing.BraintreeDiscountMappingSubscribeTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.DiscountMapping
  alias Accrue.Error.DiscountMappingInvalid
  alias Accrue.Events.Event

  defmodule SubscriptionGatewayStub do
    def create(params, _opts) do
      send(self(), {:gateway_create, params})

      redemption_count =
        Repo.one!(
          from mapping in DiscountMapping,
            where: mapping.processor == "braintree",
            select: mapping.times_redeemed
        )

      send(self(), {:gateway_redemption_count, redemption_count})

      discount_id =
        get_in(params, [:discounts, :add])
        |> case do
          [%{inherited_from_id: inherited_from_id} | _] -> inherited_from_id
          _ -> nil
        end

      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_discount_#{System.unique_integer([:positive])}",
         plan_id: params[:plan_id],
         payment_method_token: params[:payment_method_token],
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z",
         discounts:
           if(discount_id, do: [%{id: discount_id, inherited_from_id: discount_id}], else: [])
       )}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)

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

  describe "subscribe/3 with promotion_code" do
    test "revalidates the local mapping at create time, attaches it to the request, and consumes redemption state" do
      customer = insert_braintree_customer!()

      assert {:ok, _mapping} =
               Billing.upsert_discount_mapping("SPRING25", %{
                 discount_id: "bt_discount_25",
                 amount_off_minor: 2_500,
                 currency: "USD",
                 max_redemptions: 3,
                 times_redeemed: 0
               })

      assert {:ok, %Subscription{} = subscription} =
               Billing.subscribe(
                 customer,
                 "plan_premium",
                 promotion_code: "spring25",
                 payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
               )

      assert_received {:gateway_create,
                       %{
                         payment_method_token: "pm_token_123",
                         plan_id: "plan_premium",
                         discounts: %{add: [%{inherited_from_id: "bt_discount_25"}]}
                       }}
      assert_received {:gateway_redemption_count, 1}

      assert subscription.discount_id == "bt_discount_25"

      assert {:ok, mapping} = Billing.get_discount_mapping("SPRING25")
      assert mapping.times_redeemed == 1

      assert Repo.aggregate(Subscription, :count) == 1

      assert %Event{} =
               Repo.one!(
                 from e in Event,
                   where: e.type == "subscription.created" and e.subject_id == ^subscription.id
               )
    end

    test "returns local invalid-code atoms before any processor call" do
      customer = insert_braintree_customer!()

      assert {:error, :not_found} =
               Billing.subscribe(
                 customer,
                 "plan_premium",
                 promotion_code: "NOPE",
                 payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
               )

      refute_received {:gateway_create, _}
      assert Repo.aggregate(Subscription, :count) == 0
    end

    test "hard-fails drift with DiscountMappingInvalid and does not create an undiscounted subscription" do
      customer = insert_braintree_customer!()
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, _} =
        Ecto.Adapters.SQL.query(
          Repo,
          """
          INSERT INTO accrue_discount_mappings
            (id, processor, code, discount_id, active, amount_off_minor, currency, metadata, data,
             lock_version, inserted_at, updated_at)
          VALUES
            ($1, 'braintree', 'DRIFTED', '', true, 500, 'USD', '{}'::jsonb, '{}'::jsonb,
             1, $2, $2)
          """,
          [Ecto.UUID.generate() |> Ecto.UUID.dump!(), now]
        )

      assert {:error, %DiscountMappingInvalid{} = error} =
               Billing.subscribe(
                 customer,
                 "plan_premium",
                 promotion_code: "DRIFTED",
                 payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
               )

      assert error.code == "DRIFTED"
      refute_received {:gateway_create, _}
      assert Repo.aggregate(Subscription, :count) == 0
    end
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
