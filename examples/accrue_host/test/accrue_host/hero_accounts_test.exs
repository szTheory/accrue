defmodule AccrueHost.HeroAccountsTest do
  use AccrueHost.DataCase

  setup do
    Application.put_env(:accrue, :env, :dev)
    
    Code.compiler_options(ignore_module_conflict: true)
    Code.eval_file("priv/repo/seeds.exs")
    Code.compiler_options(ignore_module_conflict: false)
    
    Application.put_env(:accrue, :env, :test)
    :ok
  end

  test "pingpal hero accounts are created with correct subscriptions" do
    alias AccrueHost.Accounts.{User, Organization}
    alias AccrueHost.Billing

    assert %User{} = Repo.get_by(User, email: "healthy@example.com")
    assert %User{} = Repo.get_by(User, email: "past-due@example.com")
    assert %User{} = Repo.get_by(User, email: "canceled@example.com")
    assert %User{} = Repo.get_by(User, email: "enterprise@example.com")
    assert %User{} = Repo.get_by(User, email: "trialing@example.com")

    org = Repo.get_by!(Organization, slug: "healthy-co")
    assert {:ok, %{subscription: %Accrue.Billing.Subscription{status: :active}}} = Billing.billing_state_for(org)

    org_past_due = Repo.get_by!(Organization, slug: "past-due-co")
    assert {:ok, %{subscription: %Accrue.Billing.Subscription{status: :past_due}}} = Billing.billing_state_for(org_past_due)

    org_canceled = Repo.get_by!(Organization, slug: "canceled-co")
    assert {:ok, %{subscription: %Accrue.Billing.Subscription{status: :canceled}}} = Billing.billing_state_for(org_canceled)
  end
end
