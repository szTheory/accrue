defmodule Accrue.DunningTest do
  use Accrue.BillingCase, async: true

  alias Accrue.Dunning
  alias Accrue.Test.Factory
  alias Accrue.Repo
  alias Accrue.Billing.Subscription
  import Ecto.Query

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  describe "requires_attention?/1" do
    test "returns true when customer has an active dunning campaign" do
      %{customer: customer, subscription: sub} = Factory.active_subscription()
      owner_id = customer.owner_id

      now = Accrue.Clock.utc_now()

      Repo.update_all(from(s in Subscription, where: s.id == ^sub.id),
        set: [dunning_campaign_started_at: now]
      )

      assert Dunning.requires_attention?(customer) == true

      billable = %TestUser{id: owner_id}
      assert Dunning.requires_attention?(billable) == true
    end

    test "returns false when customer has no active dunning campaign" do
      %{customer: customer, subscription: sub} = Factory.active_subscription()
      owner_id = customer.owner_id

      Repo.update_all(from(s in Subscription, where: s.id == ^sub.id),
        set: [dunning_campaign_started_at: nil]
      )

      assert Dunning.requires_attention?(customer) == false

      billable = %TestUser{id: owner_id}
      assert Dunning.requires_attention?(billable) == false
    end

    test "returns false when billable has no customer" do
      billable = %TestUser{id: Ecto.UUID.generate()}
      assert Dunning.requires_attention?(billable) == false
    end
  end
end
