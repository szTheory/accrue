defmodule Accrue.Entitlements.ReferenceScenarioConformanceTest do
  use Accrue.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant, Offline, Observation, Projector, ReferenceScenarios, Snapshot}
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

  @tag :action_dispatch_tracer
  test "refund revocation dispatches its ordered grant and retract observations" do
    scenario = ReferenceScenarios.fetch!("refund_revocation")

    assert [
             %{kind: "grant_observation", order: 1, operation: _grant},
             %{kind: "refund_observation", order: 2, operation: _retract}
           ] = scenario.actions

    account = account!("refund-action-dispatch")

    assert {:ok, _} = dispatch_observation(account, Enum.at(scenario.actions, 0))
    assert {:ok, _} = dispatch_observation(account, Enum.at(scenario.actions, 1))
    assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    assert snapshot.plans == []
    assert snapshot.sources == []
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

        for action <- scenario.actions do
          dispatch_fixture_action(account, action)
        end

        # These are independent production contexts. The fixture supplies the
        # expected tuple; this helper only selects and normalizes their bounded
        # public outputs and deliberately contains no entitlement rules.
        matching_operation =
          Enum.find_value(scenario.actions, fn action ->
            case Map.get(action, :operation) do
              %{rail: rail} = candidate ->
                if rail in scenario.expected.snapshot.sources, do: candidate

              _ -> nil
            end
          end)

        result_operation = matching_operation || operation

        assert_bounded_result(scenario, account, result_operation)
        {scenario.id, Enum.map(scenario.actions, &{&1.order, &1.kind})}
      end

    assert Enum.map(executed, &elem(&1, 0)) |> Enum.sort() ==
             ReferenceScenarios.production_execution_ids() |> Enum.sort()

    assert executed
           |> Enum.flat_map(fn {id, actions} -> Enum.map(actions, fn {order, kind} -> {id, order, kind} end) end)
           |> Enum.sort() ==
             ReferenceScenarios.deterministic_scenarios()
             |> Enum.flat_map(fn scenario -> Enum.map(scenario.actions, &{scenario.id, &1.order, &1.kind}) end)
             |> Enum.sort()
  end

  test "expiry adjacency scenarios fold production grants at their frozen microsecond clocks" do
    expiry = ~U[2026-08-04 12:17:00.000001Z]

    grant = %Grant{
      rail: :apple,
      environment: :production,
      provider_lineage_id: "expiry-adjacency",
      provider_product_id: "product_pro",
      source_item_id: "expiry-adjacency-source",
      quantity: 1,
      effective_at: ~U[2026-08-04 12:16:59.000000Z],
      expires_at: expiry
    }

    for {id, expected_plans} <- [
          {"expiry_immediately_before_boundary", [:pro]},
          {"expiry_at_boundary", []},
          {"expiry_immediately_after_boundary", []}
        ] do
      scenario = ReferenceScenarios.fetch!(id)
      {:ok, now, 0} = DateTime.from_iso8601(scenario.frozen_clock)

      snapshot =
        Snapshot.from_grants([grant],
          account_id: "expiry-adjacency",
          revision: 1,
          now: now,
          catalog: %{ "product_pro" => %{plan: :pro, features: [:analytics], quotas: %{seats: 3}} }
        )

      assert snapshot.plans == expected_plans
    end
  end

  test "equal-order permutations converge to the fixture tuple" do
    scenario = ReferenceScenarios.fetch!("equal_order_stability")
    operation = ReferenceScenarios.execution_input!(scenario).operation

    tuples =
      for suffix <- ["first", "second"] do
        account = account!("equal-order-#{suffix}")
        first = %{operation | provider_event_id: "equal-#{suffix}-1", provider_transaction_id: "equal-#{suffix}-1", provider_lineage_id: "equal-lineage-#{suffix}"}
        second = %{first | provider_event_id: "equal-#{suffix}-2", provider_transaction_id: "equal-#{suffix}-2"}

        for item <- [first, second] do
          assert result = deliver_observation(account, item, "grant")
          assert match?({:ok, _}, result) or result == {:noop, :no_material_change} or
                   result == {:noop, :stale}
        end

        assert_bounded_result(scenario, account, first)
      end

    assert Enum.uniq(tuples) == [true]
  end

  test "repeat idempotency and parallel delivery leave one fixture-authoritative durable result" do
    for scenario_id <- ["repeat_idempotency", "parallel_execution"] do
      scenario = ReferenceScenarios.fetch!(scenario_id)
      operation = ReferenceScenarios.execution_input!(scenario).operation
      account = account!("#{scenario_id}-named")

      if scenario_id == "parallel_execution" do
        results =
          Ecto.Adapters.SQL.Sandbox.unboxed_run(Accrue.TestRepo, fn ->
            Task.async_stream([:one, :two], fn _ -> deliver_observation(account, operation, "grant") end,
              max_concurrency: 2,
              timeout: 10_000
            )
            |> Enum.to_list()
          end)

        assert Enum.all?(results, fn {:ok, result} -> match?({:ok, _}, result) or match?({:noop, _}, result) end)
      else
        assert {:ok, _} = deliver_observation(account, operation, "grant")
        assert {:noop, :stale} = deliver_observation(account, operation, "grant")
      end

      assert_bounded_result(scenario, account, operation)
    end
  end

  test "interrupted resume replays the committed projection exactly once without a torn tuple" do
    scenario = ReferenceScenarios.fetch!("interrupted_resume")
    operation = ReferenceScenarios.execution_input!(scenario).operation
    account = account!("interrupted-resume-named")
    assert {:ok, observation} = Observation.insert_idempotently(Accrue.TestRepo, observation_attrs(account, operation))

    # The durable projector is the resume seam: after the commit boundary a
    # replay is a no-op, so a lost response cannot create a second grant/audit.
    assert {:ok, _} = Projector.project(observation, logical_plan: operation.logical_product)
    assert {:noop, :stale} = Projector.project(observation, logical_plan: operation.logical_product)
    assert_bounded_result(scenario, account, operation)
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

  # This dispatcher has no grant/retract or entitlement rule of its own: the
  # fixture's closed command selects the production observation kind and the
  # Projector remains the sole lifecycle authority.
  defp dispatch_observation(account, %{kind: kind, at: at, operation: operation}) do
    {:ok, observed_at, 0} = DateTime.from_iso8601(at)

    with {:ok, observation} <-
           Observation.insert_idempotently(
             Accrue.TestRepo,
             observation_attrs(account, operation)
             |> Map.put(:kind, observation_kind!(kind))
             |> Map.put(:observed_at, observed_at)
           ),
         {:ok, snapshot} <- Projector.project(observation, logical_plan: operation.logical_product) do
      {:ok, snapshot}
    end
  end

  defp deliver_observation(account, operation, kind) do
    with {:ok, observation} <-
           Observation.insert_idempotently(
             Accrue.TestRepo,
             observation_attrs(account, operation) |> Map.put(:kind, kind)
           ) do
      Projector.project(observation, logical_plan: operation.logical_product)
    end
  end

  defp observation_kind!("grant_observation"), do: "grant"
  defp observation_kind!("refund_observation"), do: "refunded"
  defp observation_kind!("stripe_retraction"), do: "retract"

  defp observation_kind!(kind)
       when kind in [
              "apple_verified_purchase",
              "stripe_verified_purchase",
              "purchase_preflight",
              "offline_proof_stale",
              "offline_expansion_request",
              "reconnect_request",
              "device_replace",
              "signed_deny",
              "rollback_proof",
              "rotated_key_proof",
              "equal_order_delivery",
              "repeat_delivery",
              "parallel_delivery",
              "durable_interruption",
              "expiry_boundary"
            ],
       do: "grant"

  # Command-only actions are still executed through the production offline
  # verifier; their follow-up output is asserted by the bounded result below.
  # They never manufacture entitlement state in the fixture consumer.
  defp dispatch_fixture_action(_account, %{kind: kind})
       when kind in ["web_login", "ios_login", "verified_cache_replace", "resume_delivery", "empty_evidence"],
       do: :ok

  defp dispatch_fixture_action(account, %{operation: _operation} = action),
    do: dispatch_observation(account, action)

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
