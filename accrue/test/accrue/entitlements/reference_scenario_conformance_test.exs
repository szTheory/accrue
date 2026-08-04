defmodule Accrue.Entitlements.ReferenceScenarioConformanceTest do
  use Accrue.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Offline, Observation, Projector, ReferenceScenarios}
  alias Accrue.Events.Event

  defmodule FakeVerifier do
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
  end

  setup do
    prior_entitlements = Application.get_env(:accrue, :entitlements)
    prior_reconciliation = Application.get_env(:accrue, :apple_reconciliation)
    prior_rails = Application.get_env(:accrue, :rails)

    on_exit(fn ->
      restore(:entitlements, prior_entitlements)
      restore(:apple_reconciliation, prior_reconciliation)
      restore(:rails, prior_rails)
    end)

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

    Application.put_env(:accrue, :apple_reconciliation,
      admission: [
        verifier: FakeVerifier,
        verifier_config: :test,
        product_map: %{"product_pro" => :pro},
        verifier_version: "fake-v1",
        config_version: "test-v1"
      ]
    )
  end

  @tag :tracer
  @tag :production_scenario
  test "apple purchase to web login executes production authority" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")
    account = account!("scenario-apple-web")
    operation = purchase_operation!(scenario)

    assert {:ok, _outcome} =
             Accrue.Entitlements.observe_apple_evidence(
               account,
               apple_evidence(account, operation)
             )

    assert_production_result(scenario, account, operation, :stripe)
  end

  @tag :production_scenario
  test "stripe purchase to iOS login executes production authority" do
    scenario = ReferenceScenarios.fetch!("stripe_purchase_to_ios_login")
    account = account!("scenario-stripe-ios")
    operation = purchase_operation!(scenario)

    assert {:ok, observation} =
             Observation.insert_idempotently(
               Accrue.TestRepo,
               observation_attrs(account, operation)
             )

    assert {:ok, _snapshot} = Projector.project(observation)
    assert_production_result(scenario, account, operation, :apple)
  end

  test "the loader rejects scenario inputs that could become a second reducer" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")
    [action | rest] = scenario.actions

    refute ReferenceScenarios.valid?(%{scenario | actions: [%{action | operation: %{}} | rest]})
    assert "feasibility_blocked" == capability_report()["overall_status"]
  end

  test "every deterministic row has a closed production execution input" do
    deterministic_ids =
      ReferenceScenarios.all()
      |> Enum.filter(&(&1.evidence_lane == :deterministic_conformance))
      |> Enum.map(& &1.id)

    assert Enum.sort(deterministic_ids) ==
             Enum.sort(ReferenceScenarios.production_execution_ids())

    for scenario <- ReferenceScenarios.deterministic_scenarios() do
      assert %{account: account, operation: operation} =
               ReferenceScenarios.execution_input!(scenario)

      assert is_binary(account.owner_id)
      assert is_map(operation)
    end
  end

  test "every deterministic scenario executes a production projection, snapshot, purchase, offline, and audit path" do
    executed =
      for scenario <- ReferenceScenarios.deterministic_scenarios() do
        %{account: %{owner_id: owner_id}, operation: operation} =
          ReferenceScenarios.execution_input!(scenario)

        account = account!(owner_id)

        if scenario.id != "empty_evidence_fails_closed" do
          assert {:ok, observation} =
                   Observation.insert_idempotently(Accrue.TestRepo, observation_attrs(account, operation))

          assert {:ok, _snapshot} = Projector.project(observation, logical_plan: operation.logical_product)
        end

        # These are independent production contexts. The fixture supplies the
        # expected tuple; this helper only selects and normalizes their bounded
        # public outputs and deliberately contains no entitlement rules.
        assert_bounded_result(scenario, account, operation)
        scenario.id
      end

    assert Enum.sort(executed) == Enum.sort(ReferenceScenarios.production_execution_ids())
  end

  defp assert_production_result(scenario, account, operation, opposite_rail) do
    assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    assert snapshot.revision == scenario.expected.snapshot.revision

    assert snapshot.plans ==
             Enum.map(scenario.expected.snapshot.plans, &String.to_existing_atom/1)

    assert Enum.map(snapshot.sources, & &1.rail) == scenario.expected.snapshot.sources

    decision =
      Accrue.Entitlements.purchase_decision(
        account.id,
        opposite_rail,
        opposite_product(opposite_rail)
      )

    assert decision.status == scenario.expected.purchase.status
    assert Atom.to_string(decision.reason) == scenario.expected.purchase.reason

    assert {:ok, offline} =
             Offline.verify(
               offline_vector(operation.offline_vector)["compact_jws"],
               offline_context(operation.offline_vector)
             )

    assert %{action: action, allowed: true} =
             Offline.action_policy(offline, operation.offline_action)

    assert action == operation.offline_action
    assert scenario.expected.offline_policy.action == :allow_downloaded_study

    assert Accrue.TestRepo.aggregate(
             from(event in Event, where: event.subject_id == ^account.id),
             :count,
             :id
           ) == scenario.expected.audit_count
  end

  # This is intentionally only a bounded-result normalizer. It does not infer
  # an entitlement decision from fixture data: the persisted projection,
  # purchase context, Offline verifier, and audit ledger remain authoritative.
  defp assert_bounded_result(scenario, account, operation) do
    assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)
    assert snapshot.revision == scenario.expected.snapshot.revision
    assert snapshot.plans == Enum.map(scenario.expected.snapshot.plans, &String.to_existing_atom/1)
    assert Enum.map(snapshot.sources, & &1.rail) == scenario.expected.snapshot.sources

    decision =
      Accrue.Entitlements.purchase_decision(
        account.id,
        opposite_rail(operation.rail),
        opposite_product(opposite_rail(operation.rail))
      )

    assert decision.status == scenario.expected.purchase.status
    assert Atom.to_string(decision.reason) == scenario.expected.purchase.reason

    assert {:ok, offline} =
             Offline.verify(offline_vector(operation.offline_vector)["compact_jws"], offline_context(operation.offline_vector))

    assert %{action: action, allowed: allowed} = Offline.action_policy(offline, operation.offline_action)
    assert action == operation.offline_action
    assert is_boolean(allowed)

    assert Accrue.TestRepo.aggregate(
             from(event in Event, where: event.subject_id == ^account.id),
             :count,
             :id
           ) == scenario.expected.audit_count
  end

  defp purchase_operation!(scenario),
    do: scenario.actions |> Enum.find(&Map.has_key?(&1, :operation)) |> Map.fetch!(:operation)

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp opposite_product(:stripe), do: "price_pro"
  defp opposite_product(:apple), do: "product_pro"
  defp opposite_rail(:stripe), do: :apple
  defp opposite_rail(:apple), do: :stripe

  defp apple_evidence(account, operation) do
    Jason.encode!(%{
      "originalTransactionId" => operation.provider_lineage_id,
      "appAccountToken" => account.id,
      "transactionId" => operation.provider_transaction_id,
      "productId" => operation.provider_product_id,
      "signedDate" => 1_754_000_000_000,
      "expiresDate" => 1_800_000_000_000
    })
  end

  defp observation_attrs(account, operation),
    do: %{
      account_id: account.id,
      rail: operation.rail,
      environment: operation.environment,
      provider_event_id: operation.provider_event_id,
      provider_transaction_id: operation.provider_transaction_id,
      kind: "grant",
      provider_lineage_id: operation.provider_lineage_id,
      provider_product_id: operation.provider_product_id,
      provider_order: operation.provider_order,
      observed_at: ~U[2026-08-04 12:01:00.000000Z],
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "fake_observer"},
      evidence_digest: String.duplicate("a", 64)
    }

  defp offline_vector(id), do: offline_fixture()["vectors"] |> Enum.find(&(&1["id"] == id))

  defp offline_fixture,
    do:
      "../../../priv/entitlements/v1.59-offline-golden-vectors.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

  defp capability_report,
    do:
      "../../../../examples/crosswake_tracer/capability-report.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

  defp offline_context(id) do
    offline_vector(id)["verification_context"]
    |> Map.put("public_keys", offline_fixture()["public_jwks"]["keys"])
    |> Map.new(fn {key, value} -> {offline_key(key), offline_value(key, value)} end)
  end

  defp offline_key(key),
    do:
      %{
        "issuer" => :issuer,
        "audience" => :audience,
        "account_subject" => :account_subject,
        "installation_id" => :installation_id,
        "device_thumbprint" => :device_thumbprint,
        "now" => :now,
        "clock_high_water" => :clock_high_water,
        "accepted_revision" => :accepted_revision,
        "accepted_disposition" => :accepted_disposition,
        "accepted_iat" => :accepted_iat,
        "accepted_fresh_until" => :accepted_fresh_until,
        "public_keys" => :public_keys
      }[key]

  defp offline_value("clock_high_water", value),
    do: Map.new(value, fn {key, item} -> {String.to_existing_atom(key), item} end)

  defp offline_value("accepted_disposition", value) when is_binary(value),
    do: String.to_existing_atom(value)

  defp offline_value(_, value), do: value
  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
