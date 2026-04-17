defmodule AccrueHost.BillingFacadeTest do
  use AccrueHost.AccrueCase, async: false

  @moduletag :phase10
  @host_root Path.expand("../..", __DIR__)

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias AccrueHost.Accounts.Organization
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Accounts.User
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  import Ecto.Query

  setup do
    user = AccountsFixtures.user_fixture()
    organization = AccountsFixtures.organization_fixture(%{owner: user})
    %{user: user, organization: organization}
  end

  test "host user schema is the billable boundary" do
    assert User.__accrue__(:billable_type) == "User"
    assert function_exported?(User, :customer, 1)
  end

  test "host organization schema is the billable boundary" do
    assert Organization.__accrue__(:billable_type) == "Organization"
    assert function_exported?(Organization, :customer, 1)
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
    assert {:update_customer_tax_location, 2} in exports
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

  test "customer_for/1 accepts a Sigra-backed organization fixture", %{organization: organization} do
    assert {:ok, %Customer{} = customer} = Billing.customer_for(organization)

    assert customer.owner_type == "Organization"
    assert customer.owner_id == organization.id
    assert customer.processor == "fake"
  end

  test "billing_state_for/1 accepts a Sigra-backed organization fixture", %{
    organization: organization
  } do
    assert {:ok, %{customer: nil, subscription: nil}} = Billing.billing_state_for(organization)

    assert {:ok, %Subscription{} = latest_subscription} =
             Billing.subscribe(organization, "price_basic", trial_end: {:days, 14})

    assert {:ok,
            %{customer: %Customer{} = customer, subscription: %Subscription{} = subscription}} =
             Billing.billing_state_for(organization)

    assert customer.owner_type == "Organization"
    assert customer.owner_id == organization.id
    assert subscription.id == latest_subscription.id
    assert subscription.customer_id == customer.id
  end

  test "scope-scoped facade returns no_active_organization without an active organization", %{
    user: user
  } do
    scope = Scope.for_user(user)

    assert {:error, :no_active_organization} = Billing.customer_for_scope(scope)
    assert {:error, :no_active_organization} = Billing.billing_state_for_scope(scope)

    assert {:error, :no_active_organization} =
             Billing.subscribe_active_organization(scope, "price_basic", trial_end: {:days, 14})
  end

  test "cancel_active_organization/2 forbids cancelling a subscription owned by another organization" do
    user = AccountsFixtures.user_fixture()
    org_a = AccountsFixtures.organization_fixture(%{owner: user})
    org_b = AccountsFixtures.organization_fixture(%{owner: user})

    membership_a =
      AccountsFixtures.organization_membership_fixture(%{
        organization: org_a,
        user: user,
        role: :owner
      })

    scope_on_a = Scope.put_active_organization(Scope.for_user(user), org_a, membership_a)

    assert {:ok, other_org_subscription} =
             Billing.subscribe(org_b, "price_basic", trial_end: {:days, 14})

    assert {:error, :forbidden} =
             Billing.cancel_active_organization(scope_on_a, other_org_subscription)
  end

  test "fixtures create Sigra role memberships for downstream organization coverage" do
    owner_membership = AccountsFixtures.organization_membership_fixture(%{role: :owner})
    admin_membership = AccountsFixtures.organization_membership_fixture(%{role: :admin})
    member_membership = AccountsFixtures.organization_membership_fixture(%{role: :member})

    assert owner_membership.role == :owner
    assert admin_membership.role == :admin
    assert member_membership.role == :member
  end

  test "billing_state_for/1 returns the fake-backed customer and latest subscription", %{
    user: user
  } do
    assert {:ok, %Subscription{} = first_subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    assert {:ok, %Subscription{} = latest_subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    assert {:ok,
            %{customer: %Customer{} = customer, subscription: %Subscription{} = subscription}} =
             Billing.billing_state_for(user)

    assert customer.owner_type == "User"
    assert customer.owner_id == user.id
    assert customer.processor == "fake"
    assert subscription.id == latest_subscription.id
    refute subscription.id == first_subscription.id
    assert subscription.customer_id == customer.id
    assert subscription.processor == "fake"
  end

  test "update_customer_tax_location/2 delegates to Accrue.Billing.update_customer_tax_location/2",
       %{user: user} do
    assert {:ok, customer} = Billing.customer_for(user)

    assert {:ok, updated} =
             Billing.update_customer_tax_location(user, %{
               address: %{
                 line1: "27 Fredrick Ave",
                 city: "Albany",
                 state: "NY",
                 postal_code: "12207",
                 country: "US"
               }
             })

    assert updated.id == customer.id
    refute Map.has_key?(updated.data || %{}, "address")
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

    assert billing_source =~
             "def update_customer_tax_location(billable, attrs) when is_map(attrs) do"

    assert billing_source =~ "Billing.update_customer_tax_location(customer, attrs)"
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
