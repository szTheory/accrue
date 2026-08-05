defmodule Accrue.Entitlements.ReferenceScenarioReadTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read

  setup do
    previous_entitlements = Application.get_env(:accrue, :entitlements)
    previous_rails = Application.get_env(:accrue, :rails)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics],
          quotas: [seats: 3],
          products: [stripe: [production: ["price_pro"]], apple: [production: ["product_pro"]]]
        ]
      ]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production],
      apple: [environments: [:production], default_environment: :production]
    )

    on_exit(fn ->
      restore(:entitlements, previous_entitlements)
      restore(:rails, previous_rails)
    end)
  end

  test "web and iOS login collect a fresh canonical snapshot without writes" do
    for {scenario_id, expected_rail} <- [
          {"apple_purchase_to_web_login", :apple},
          {"stripe_purchase_to_ios_login", :stripe}
        ] do
      scenario = ReferenceScenarios.fetch!(scenario_id)
      [purchase, login] = scenario.actions
      account = account!("reference-scenario-read-#{scenario_id}")

      :ok = Read.seed_equivalent_grant(Accrue.TestRepo, account, purchase.command.payload)
      result = Read.execute(Accrue.TestRepo, account, login)

      assert result.result.disposition == login.kind
      assert result.snapshot.revision == 1
      assert result.snapshot.plans == [:pro]
      assert result.snapshot.sources == [expected_rail]
      assert result.durable.observation_delta == 0
      assert result.durable.grant_delta == 0
      assert result.durable.audit_delta == 0
    end
  end

  test "purchase preflight calls the production decision and records its revision-bound result" do
    scenario = ReferenceScenarios.fetch!("duplicate_purchase_prevention")
    [preflight] = scenario.actions
    account = account!("reference-scenario-read-preflight")

    result = Read.execute(Accrue.TestRepo, account, preflight)

    assert result.result == %{
             tag: "executed",
             disposition: "purchase_preflight",
             status: "block",
             reason: "equivalent_other_rail",
             target_rail: "apple",
             product_id: "product_pro"
           }

    assert result.durable.snapshot_revision == 1
    assert result.durable.observation_delta == 0
    assert result.durable.grant_delta == 0
    assert result.durable.audit_delta == 0
  end

  test "generic grant, no effect, and snapshot-only adapters cannot satisfy preflight" do
    scenario = ReferenceScenarios.fetch!("duplicate_purchase_prevention")
    [preflight] = scenario.actions

    assert {:error, :preflight_mismatch} =
             Read.adversarial_result(Accrue.TestRepo, account!("reference-scenario-read-generic"), preflight,
               adapter: :generic_grant
             )

    assert {:error, :preflight_mismatch} =
             Read.adversarial_result(Accrue.TestRepo, account!("reference-scenario-read-no-effect"), preflight,
               adapter: :no_effect
             )

    assert {:error, :preflight_mismatch} =
             Read.adversarial_result(Accrue.TestRepo, account!("reference-scenario-read-snapshot-only"), preflight,
               adapter: :snapshot_only
             )
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
