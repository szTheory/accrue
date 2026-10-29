defmodule AccrueAdmin.SubscriptionScenarioRepoTest do
  use AccrueAdmin.RepoCase

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias AccrueAdmin.TestRepo
  alias Ecto.Adapters.SQL.Sandbox

  @ordinary_fields [:id, :owner_type, :owner_id, :processor, :processor_id, :name, :email]
  @subscription_fields [
    :id,
    :customer_id,
    :processor,
    :processor_id,
    :status,
    :cancel_at_period_end,
    :current_period_start,
    :current_period_end,
    :dunning_campaign_started_at
  ]
  @item_fields [:id, :subscription_id, :processor, :processor_id, :price_id, :quantity]

  setup do
    [[database, role, address]] =
      TestRepo.query!("SELECT current_database(), current_user, host(inet_server_addr())").rows

    partition = System.get_env("MIX_TEST_PARTITION")

    assert is_binary(partition) and Regex.match?(~r/^\d{8,16}$/, partition)
    assert database == "accrue_admin_test#{partition}"
    assert database == System.get_env("PHASE252_E2E_DATABASE")
    assert role == "postgres"
    assert role == System.get_env("PHASE252_E2E_ROLE")
    assert System.get_env("PHASE252_E2E_LANE") == "admin-test"
    # Strict loopback everywhere; on a hosted CI runner the PostgreSQL service container reports
    # its RFC 1918 bridge address instead (mirrors phase252_lab.mjs acceptedServerAddress/2).
    private_range =
      ~r/^(?:10(?:\.\d{1,3}){3}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2}|192\.168(?:\.\d{1,3}){2})$/

    assert address in ["127.0.0.1", "::1"] or
             (System.get_env("GITHUB_ACTIONS") == "true" and
                Regex.match?(private_range, address))

    :ok
  end

  test "persists launch and growing-team source facts and reloads their exact linked rows" do
    adapter = adapter!()

    for scenario <- [:launch, :growing_team] do
      facts = validated_facts!(scenario)
      graph = persist!(adapter, facts)
      reloaded = reload(adapter, facts.subscription.id)

      assert_graph_matches(graph, facts)
      assert_graph_matches(reloaded, facts)
      assert reloaded.subscription.customer.id == facts.customer.id

      assert Enum.map(reloaded.subscription.subscription_items, & &1.id) ==
               Enum.map(facts.subscription.items, & &1.id)
    end
  end

  test "replay is stable and conflicting source or processor identities are refused" do
    adapter = adapter!()
    launch = validated_facts!(:launch)
    persisted = persist!(adapter, launch)

    assert persist!(adapter, launch) == persisted

    changed_same_identity = put_in(launch, [:customer, :name], "Conflicting synthetic name")

    assert_raise ArgumentError, fn -> persist!(adapter, changed_same_identity) end
    assert reload(adapter, launch.subscription.id).customer.name == launch.customer.name

    processor_collision =
      :growing_team
      |> CadenceSubscriptionFacts.fetch!()
      |> put_in([:customer, :processor_id], launch.customer.processor_id)
      |> validated_facts!()

    assert_raise ArgumentError, fn -> persist!(adapter, processor_collision) end
    assert TestRepo.get(Customer, processor_collision.customer.id) == nil
  end

  test "migrated Postgres rejects invalid foreign keys, null relationships, and duplicate provider references" do
    adapter = adapter!()
    facts = validated_facts!(:launch)
    graph = persist!(adapter, facts)
    missing_subscription_id = Ecto.UUID.generate() |> Ecto.UUID.dump!()

    foreign_key_error =
      expect_postgres_error(fn ->
        TestRepo.query!(
          "INSERT INTO billing.accrue_subscription_items (subscription_id, processor, inserted_at, updated_at) VALUES ($1, $2, now(), now())",
          [missing_subscription_id, "stripe"]
        )
      end)

    assert foreign_key_error.postgres.code == :foreign_key_violation

    not_null_error =
      expect_postgres_error(fn ->
        TestRepo.query!(
          "INSERT INTO billing.accrue_subscription_items (processor, inserted_at, updated_at) VALUES ($1, now(), now())",
          ["stripe"]
        )
      end)

    assert not_null_error.postgres.code == :not_null_violation

    unique_error =
      expect_postgres_error(fn ->
        TestRepo.query!(
          "INSERT INTO billing.accrue_subscription_items (subscription_id, processor, processor_id, inserted_at, updated_at) VALUES ($1, $2, $3, now(), now())",
          [
            Ecto.UUID.dump!(graph.subscription.id),
            "stripe",
            facts.subscription.items |> hd() |> Map.fetch!(:processor_id)
          ]
        )
      end)

    assert unique_error.postgres.code == :unique_violation
    assert reload(adapter, facts.subscription.id) == graph
  end

  test "rolls back a failed middle insert and serializes competing inserts without duplicate rows" do
    adapter = adapter!()
    duplicate_item_facts = duplicate_processor_item_facts!(:launch)

    assert_raise ArgumentError, fn ->
      run_unboxed(fn -> persist!(adapter, duplicate_item_facts) end)
    end

    assert TestRepo.get(Customer, duplicate_item_facts.customer.id) == nil
    assert TestRepo.get(Subscription, duplicate_item_facts.subscription.id) == nil
    assert TestRepo.get(SubscriptionItem, hd(duplicate_item_facts.subscription.items).id) == nil

    facts = validated_facts!(:growing_team)

    results =
      1..2
      |> Enum.map(fn _ ->
        Task.async(fn ->
          run_unboxed(fn -> persist!(adapter, facts) end)
        end)
      end)
      |> Task.await_many(30_000)

    assert Enum.uniq(results) |> length() == 1
    assert_graph_matches(reload(adapter, facts.subscription.id), facts)

    assert TestRepo.aggregate(from(row in Customer, where: row.id == ^facts.customer.id), :count) ==
             1

    assert TestRepo.aggregate(
             from(row in Subscription, where: row.id == ^facts.subscription.id),
             :count
           ) == 1

    run_unboxed(fn ->
      TestRepo.transaction(fn ->
        TestRepo.delete_all(
          from(item in SubscriptionItem, where: item.subscription_id == ^facts.subscription.id)
        )

        TestRepo.delete_all(from(row in Subscription, where: row.id == ^facts.subscription.id))
        TestRepo.delete_all(from(row in Customer, where: row.id == ^facts.customer.id))
      end)
    end)
  end

  defp adapter! do
    module = AccrueAdmin.Test.SubscriptionScenarioRepo

    assert Code.ensure_loaded?(module),
           "expected the Repo-backed scenario adapter to be available"

    assert function_exported?(module, :persist!, 2)
    assert function_exported?(module, :reload, 2)
    module
  end

  defp persist!(adapter, facts), do: apply(adapter, :persist!, [TestRepo, facts])
  defp reload(adapter, id), do: apply(adapter, :reload, [TestRepo, id])

  defp validated_facts!(input),
    do: AccrueAdmin.Storybook.SubscriptionScenarios.validate!(input)

  defp duplicate_processor_item_facts!(scenario) do
    facts = validated_facts!(scenario)
    first = hd(facts.subscription.items)
    duplicate = %{first | id: Ecto.UUID.generate()}
    put_in(facts, [:subscription, :items], [first, duplicate])
  end

  defp assert_graph_matches(graph, facts) do
    assert_fields_match(graph.customer, facts.customer, @ordinary_fields)

    assert_fields_match(graph.subscription, facts.subscription, @subscription_fields)

    assert Enum.map(graph.items, &Map.take(&1, @item_fields)) ==
             Enum.map(facts.subscription.items, &Map.take(&1, @item_fields))
  end

  defp assert_fields_match(actual, expected, fields) do
    for field <- fields do
      actual_value = Map.fetch!(actual, field)
      expected_value = Map.fetch!(expected, field)

      if match?(%DateTime{}, actual_value) and match?(%DateTime{}, expected_value) do
        assert DateTime.compare(actual_value, expected_value) == :eq
      else
        assert actual_value == expected_value
      end
    end
  end

  defp expect_postgres_error(fun) do
    assert_raise Postgrex.Error, fun
  end

  defp run_unboxed(fun) do
    task =
      Task.async(fn ->
        :ok = Sandbox.checkout(TestRepo, sandbox: false)

        try do
          {:returned, fun.()}
        rescue
          error -> {:raised, error, __STACKTRACE__}
        after
          Sandbox.checkin(TestRepo)
        end
      end)

    case Task.await(task, 30_000) do
      {:returned, value} -> value
      {:raised, error, stacktrace} -> reraise error, stacktrace
    end
  end
end
