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

    # Operator / billing-admin persona
    admin_user = Repo.get_by(User, email: "admin@example.com")
    assert %User{billing_admin: true} = admin_user,
           "admin@example.com must have billing_admin: true — required to reach /admin"

    # Lock: customer personas must NOT have admin access
    healthy_user = Repo.get_by(User, email: "healthy@example.com")
    assert %User{billing_admin: false} = healthy_user,
           "healthy@example.com must remain billing_admin: false (customer persona)"

    org = Repo.get_by!(Organization, slug: "healthy-co")
    assert {:ok, %{subscription: %Accrue.Billing.Subscription{status: :active}}} = Billing.billing_state_for(org)

    org_past_due = Repo.get_by!(Organization, slug: "past-due-co")
    assert {:ok, %{subscription: %Accrue.Billing.Subscription{status: :past_due}}} = Billing.billing_state_for(org_past_due)

    org_canceled = Repo.get_by!(Organization, slug: "canceled-co")
    assert {:ok, %{subscription: %Accrue.Billing.Subscription{status: :canceled}}} = Billing.billing_state_for(org_canceled)
  end

  test "dunning campaign_started events have subject_ids that match real subscriptions" do
    alias Accrue.Billing.Subscription
    alias Accrue.Events.Event
    import Ecto.Query

    events =
      Repo.all(
        from e in Event,
          where: e.type == "dunning.campaign_started" and e.subject_type == "Subscription"
      )

    assert length(events) >= 1, "Expected at least 1 dunning.campaign_started event"

    Enum.each(events, fn event ->
      assert Repo.get(Subscription, event.subject_id) != nil,
             "dunning.campaign_started event #{event.idempotency_key} has phantom subject_id #{event.subject_id}"
    end)
  end
end
