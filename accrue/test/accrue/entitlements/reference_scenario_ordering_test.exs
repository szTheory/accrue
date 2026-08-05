defmodule Accrue.Entitlements.ReferenceScenarioOrderingTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Ordering

  setup do
    previous = Application.get_env(:accrue, :entitlements)
    previous_rails = Application.get_env(:accrue, :rails)

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:analytics], products: [apple: [production: ["product_pro"]]]]]
    )

    Application.put_env(:accrue, :rails,
      apple: [environments: [:production], default_environment: :production]
    )

    on_exit(fn ->
      restore(:entitlements, previous)
      restore(:rails, previous_rails)
    end)
  end

  test "equal-order delivery uses every declared permutation and converges on production facts" do
    action = action!("equal_order_stability")

    observed =
      Ordering.equal_orders(Accrue.TestRepo, account!("equal-order"), action,
        account_owner: &account!/1
      )

    assert Ordering.matches_expected?(action, observed)
    assert length(observed.permutations) == length(action.command.payload.permutations)
    assert Enum.uniq(Enum.map(observed.permutations, & &1.final)) |> length() == 1

    assert Enum.all?(
             observed.permutations,
             &(&1.delivery_count == length(action.command.payload.deliveries))
           )
  end

  test "repeat delivery takes its count and complete payload from the fixture" do
    action = action!("repeat_idempotency")
    observed = Ordering.repeat(Accrue.TestRepo, account!("repeat"), action)

    assert Ordering.matches_expected?(action, observed)
    assert observed.delivery_count == action.command.payload.repeat_count
    assert observed.durable.observation_count == 1
    assert observed.durable.grant_count == 1
    assert observed.durable.snapshot_revision == 1
    assert observed.durable.audit_count == 1
    assert Enum.count(observed.results, &(&1.insert == :owner)) == 1

    assert Enum.all?(
             observed.results,
             &(&1.projection in [:projected, :stale, :no_material_change])
           )
  end

  test "parallel delivery releases declared workers through a real barrier and rejects substitutes" do
    action = action!("parallel_execution")
    observed = Ordering.parallel(Accrue.TestRepo, "parallel", action)

    assert Ordering.matches_parallel_expected?(action, observed)
    assert observed.worker_count == length(action.command.payload.workers)

    assert observed.durable == %{
             observation_count: 1,
             grant_count: 1,
             snapshot_revision: 1,
             audit_count: 1
           }

    assert Enum.all?(observed.results, &(&1.insert in [:owner, :existing]))

    assert Enum.all?(
             observed.results,
             &(&1.projection in [:projected, :stale, :no_material_change])
           )

    Enum.each([:generic_grant, :no_effect], fn adapter ->
      refute Ordering.matches_parallel_expected?(
               action,
               Ordering.parallel_adversarial(Accrue.TestRepo, "parallel-#{adapter}", action,
                 adapter: adapter
               )
             )
    end)
  end

  defp action!(scenario_id), do: ReferenceScenarios.fetch!(scenario_id).actions |> hd()

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
