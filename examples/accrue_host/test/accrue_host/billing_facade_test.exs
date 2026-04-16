defmodule AccrueHost.BillingFacadeTest do
  use AccrueHost.AccrueCase, async: false

  @moduletag :phase10
  @host_root Path.expand("../..", __DIR__)

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias AccrueHost.Accounts.User
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  import Ecto.Query

  setup do
    user = AccountsFixtures.user_fixture()
    %{user: user}
  end

  test "host user schema is the billable boundary" do
    assert User.__accrue__(:billable_type) == "User"
    assert function_exported?(User, :customer, 1)
  end

  test "generated facade exports the expected public functions" do
    exports = Billing.__info__(:functions)

    assert {:subscribe, 2} in exports
    assert {:subscribe, 3} in exports
    assert {:swap_plan, 3} in exports
    assert {:cancel, 1} in exports
    assert {:cancel, 2} in exports
    assert {:customer_for, 1} in exports
    assert {:billing_state_for, 1} in exports
  end

  test "customer_for/1 round-trips through Accrue.Billing.customer/1", %{user: user} do
    assert {:ok, %Customer{} = customer} = Billing.customer_for(user)
    assert {:ok, %Customer{} = same_customer} = Accrue.Billing.customer(user)

    assert customer.id == same_customer.id
    assert customer.owner_type == "User"
    assert customer.owner_id == user.id
    assert customer.processor == "fake"
  end

  test "subscribe/3 creates a fake-backed subscription through the generated facade", %{
    user: user
  } do
    assert {:ok, %Subscription{} = subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    subscription = Repo.preload(subscription, :subscription_items)
    assert subscription.customer_id
    assert subscription.processor == "fake"
    assert subscription.status == :trialing
    assert [item] = subscription.subscription_items
    assert item.price_id == "price_basic"

    customer = Repo.get!(Customer, subscription.customer_id)
    assert customer.owner_type == "User"
    assert customer.owner_id == user.id
  end

  test "billing_state_for/1 returns nil state before the first subscription", %{user: user} do
    assert {:ok, %{customer: nil, subscription: nil}} = Billing.billing_state_for(user)
  end

  test "billing_state_for/1 returns the fake-backed customer and latest subscription", %{
    user: user
  } do
    assert {:ok, %Subscription{} = first_subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    assert {:ok, %Subscription{} = latest_subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    assert {:ok, %{customer: %Customer{} = customer, subscription: %Subscription{} = subscription}} =
             Billing.billing_state_for(user)

    assert customer.owner_type == "User"
    assert customer.owner_id == user.id
    assert customer.processor == "fake"
    assert subscription.id == latest_subscription.id
    refute subscription.id == first_subscription.id
    assert subscription.customer_id == customer.id
    assert subscription.processor == "fake"
  end

  test "generated facade source stays thin and explicit" do
    billing_source = File.read!(Path.join(@host_root, "lib/accrue_host/billing.ex"))

    assert billing_source =~ "alias Accrue.Billing"
    assert billing_source =~ "def subscribe(billable, price_id, opts \\\\ []) do"
    assert billing_source =~ "Billing.subscribe(billable, price_id, opts)"
    assert billing_source =~ "def swap_plan(subscription, price_id, opts) do"
    assert billing_source =~ "Billing.swap_plan(subscription, price_id, opts)"
    assert billing_source =~ "def cancel(subscription, opts \\\\ []) do"
    assert billing_source =~ "Billing.cancel(subscription, opts)"
    assert billing_source =~ "def customer_for(billable) do"
    assert billing_source =~ "Billing.customer(billable)"
    assert billing_source =~ "def billing_state_for(billable) do"
    assert billing_source =~ "{:ok, %{customer: customer, subscription: subscription}}"
  end

  test "subscribe/3 proof path creates customer state without direct fixture inserts", %{
    user: user
  } do
    customer_count =
      fn ->
        Repo.aggregate(
          from(c in Customer, where: c.owner_type == "User" and c.owner_id == ^user.id),
          :count
        )
      end

    assert customer_count.() == 0

    assert {:ok, %Subscription{} = subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    assert customer_count.() == 1
    assert Repo.get!(Subscription, subscription.id).customer_id == subscription.customer_id
  end
end
