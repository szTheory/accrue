defmodule Accrue.Entitlements.CompatibilityTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements.Compatibility
  alias Accrue.Entitlements.{Account, Grant}
  alias Accrue.Entitlements.Resolver.LocalMap

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "CompatibilityUser"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "compatibility_test_users" do
    end
  end

  setup do
    previous = Application.get_env(:accrue, :entitlements)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:accrue, :entitlements, previous),
        else: Application.delete_env(:accrue, :entitlements)
    end)

    :ok
  end

  test "omitted and disabled compatibility configuration select LocalMap" do
    Application.delete_env(:accrue, :entitlements)

    assert {:ok, LocalMap, %{mode: :disabled}} =
             Compatibility.authority(%TestUser{id: Ecto.UUID.generate()})

    Application.put_env(:accrue, :entitlements, multi_rail: [mode: :disabled])

    assert {:ok, LocalMap, %{mode: :disabled}} =
             Compatibility.authority(%TestUser{id: Ecto.UUID.generate()})
  end

  test "shadow and enabled modes require an explicit cohort and fail closed" do
    for mode <- [:shadow, :enabled] do
      Application.put_env(:accrue, :entitlements, multi_rail: [mode: mode])

      assert {:error, :missing_cohort} =
               Compatibility.authority(%TestUser{id: Ecto.UUID.generate()})
    end
  end

  test "clean windows are half-open and require one comparison" do
    start = ~U[2026-08-02 10:00:00Z]
    ending = ~U[2026-08-02 10:00:01Z]

    assert {:error, :invalid_clean_window} =
             Compatibility.validate_clean_window(
               started_at: start,
               ended_at: start,
               comparison_count: 1
             )

    assert {:error, :invalid_clean_window} =
             Compatibility.validate_clean_window(
               started_at: start,
               ended_at: ending,
               comparison_count: 0
             )

    assert {:ok, %{started_at: ^start, ended_at: ^ending, comparison_count: 1}} =
             Compatibility.validate_clean_window(
               started_at: start,
               ended_at: ending,
               comparison_count: 1
             )
  end

  test "backfill derives one durable grant from a mapped entitling Stripe subscription and repeats safely" do
    owner_id = Ecto.UUID.generate()

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [price_ids: ["price_compat_pro"]]],
      multi_rail: [mode: :disabled]
    )

    %{subscription: subscription} =
      Accrue.Test.Factory.active_subscription(%{owner_id: owner_id, price_id: "price_compat_pro"})

    {:ok, _} =
      subscription
      |> Accrue.Billing.Subscription.force_status_changeset(%{processor: "stripe"})
      |> Accrue.TestRepo.update()

    assert {:ok, %{processed: 1, inserted: 1, cursor: cursor}} =
             Compatibility.backfill(nil, limit: 1)

    assert {:ok, %{processed: 0}} = Compatibility.backfill(cursor, limit: 1)
    assert {:ok, %{processed: 1}} = Compatibility.backfill(nil, limit: 1)
    assert Accrue.TestRepo.aggregate(Account, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1
  end
end
