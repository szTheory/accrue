defmodule AccrueHost.Phase252ScenarioCleanupTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Customer, Invoice, Subscription, SubscriptionItem}
  alias AccrueHost.Repo
  alias Ecto.Adapters.SQL.Sandbox

  @subscription_seed "priv/repo/seeds/phase252_subscription_scenarios.exs"
  @edge_seed "priv/repo/seeds/edge_states.exs"
  @edge_cleanup "priv/repo/seeds/phase248_cleanup_edge.exs"

  test "ordinary launch and team seeds persist shared facts, replay exactly, and exclude held-out input" do
    with_unboxed(fn ->
      with_env(
        ["PHASE252_SUBSCRIPTION_LANE", "PHASE252_SUBSCRIPTION_SCENARIO", "PHASE248_PROOF_LANE"],
        fn ->
          sentinel = insert_sentinel!()

          try do
            System.put_env("PHASE252_SUBSCRIPTION_LANE", "ordinary")
            System.put_env("PHASE252_SUBSCRIPTION_SCENARIO", "launch")
            System.put_env("PHASE248_PROOF_LANE", "ordinary")

            {first_graph, _binding} = Code.eval_file(@subscription_seed)
            launch = apply(facts_module(), :fetch!, [:launch])
            assert_graph_matches!(launch)

            replay_graph =
              apply(seed_module(), :run!, [
                Repo,
                %{
                  lane: "ordinary",
                  scenario: "launch"
                }
              ])

            assert replay_graph == first_graph
            assert_scenario_count!(launch, 1)
            assert sentinel_snapshot(sentinel) == sentinel

            launch_customer = Repo.get!(Customer, launch.customer.id)

            mismatched_customer =
              Repo.update!(Customer.changeset(launch_customer, %{email: "conflict@example.test"}))

            assert_raise ArgumentError, ~r/mismatched existing row/, fn ->
              apply(seed_module(), :run!, [Repo, %{lane: "ordinary", scenario: "launch"}])
            end

            assert Repo.get!(Customer, launch.customer.id) == mismatched_customer
            Repo.update!(Customer.changeset(mismatched_customer, %{email: launch.customer.email}))

            System.put_env("PHASE252_SUBSCRIPTION_SCENARIO", "growing_team")
            apply(seed_module(), :run_from_env!, [])
            growing_team = apply(facts_module(), :fetch!, [:growing_team])
            assert_graph_matches!(growing_team)
            assert_scenario_count!(growing_team, 1)

            held_out = apply(facts_module(), :held_out!, [:long_text])
            assert held_out.lane == :held_out
            assert held_out.held_out_case == :long_text

            ordinary_identities = identity_set([launch, growing_team])
            held_out_identities = identity_set([held_out])
            assert MapSet.disjoint?(ordinary_identities, held_out_identities)

            before = {scenario_count(launch), scenario_count(growing_team)}
            System.put_env("PHASE252_SUBSCRIPTION_SCENARIO", "held_out_long_text")

            assert_raise ArgumentError, ~r/unsupported ordinary subscription scenario/, fn ->
              apply(seed_module(), :run_from_env!, [])
            end

            System.put_env("PHASE252_SUBSCRIPTION_LANE", "heldout")
            System.put_env("PHASE252_SUBSCRIPTION_SCENARIO", "launch")

            assert_raise ArgumentError, ~r/ordinary lane/, fn ->
              apply(seed_module(), :run_from_env!, [])
            end

            assert {scenario_count(launch), scenario_count(growing_team)} == before
            assert sentinel_snapshot(sentinel) == sentinel
          after
            cleanup_subscription_facts!()
            cleanup_sentinel!(sentinel)
          end
        end
      )
    end)
  end

  test "an unrelated child makes exact held-out cleanup refuse without changing any row" do
    with_edge_fixture(fn customer, sentinel ->
      extra = insert_unrelated_subscription!(customer)
      before = edge_snapshot()

      assert_raise RuntimeError, ~r/unrelated customer child/, fn ->
        Code.eval_file(@edge_cleanup)
      end

      assert edge_snapshot() == before
      assert sentinel_snapshot(sentinel) == sentinel
      assert Repo.get!(Subscription, extra.id) == extra
    end)
  end

  test "exact cleanup succeeds, tolerates absence, and refuses mismatched same-ID ownership" do
    with_edge_fixture(fn customer, sentinel ->
      before = edge_snapshot()

      mismatched =
        Repo.update!(Customer.changeset(customer, %{owner_id: Ecto.UUID.generate()}))

      mismatched_snapshot = edge_snapshot()

      assert_raise RuntimeError, ~r/unexpected edge customer/, fn ->
        Code.eval_file(@edge_cleanup)
      end

      assert edge_snapshot() == mismatched_snapshot

      Repo.update!(Customer.changeset(mismatched, %{owner_id: customer.owner_id}))
      Code.eval_file(@edge_cleanup)
      assert edge_snapshot() == empty_edge_snapshot()
      assert sentinel_snapshot(sentinel) == sentinel

      Code.eval_file(@edge_cleanup)
      assert edge_snapshot() == empty_edge_snapshot()
      assert sentinel_snapshot(sentinel) == sentinel
      refute before == empty_edge_snapshot()
    end)
  end

  test "concurrent child insertion serializes before the cleanup child-set guard" do
    with_edge_fixture(fn customer, sentinel ->
      parent = self()

      insert_task =
        Task.async(fn ->
          with_repo_connection(fn ->
            Repo.transaction(fn ->
              extra = insert_unrelated_subscription!(Repo.get!(Customer, customer.id))
              send(parent, {:extra_child_inserted, extra.id})

              receive do
                :commit_extra_child -> :committed
              after
                5_000 -> raise "test did not release competing child insert"
              end
            end)
          end)
        end)

      assert_receive {:extra_child_inserted, extra_id}, 2_000

      cleanup_task =
        Task.async(fn ->
          with_repo_connection(fn ->
            try do
              Code.eval_file(@edge_cleanup)
              :cleaned
            rescue
              error -> {:error, error}
            end
          end)
        end)

      parent_lock_waited = await_parent_lock_wait?(2_000)
      send(insert_task.pid, :commit_extra_child)

      assert {:ok, :committed} = Task.await(insert_task, 5_000)
      cleanup_result = Task.await(cleanup_task, 5_000)

      assert parent_lock_waited, "cleanup must wait for the competing foreign-key child insert"
      assert {:error, %RuntimeError{message: message}} = cleanup_result
      assert message =~ "unrelated customer child"
      assert edge_snapshot() |> Map.fetch!(:subscriptions) |> Enum.any?(&(&1.id == extra_id))
      assert Enum.count(edge_snapshot().subscriptions) == 3
      assert sentinel_snapshot(sentinel) == sentinel
    end)
  end

  defp with_edge_fixture(fun) do
    with_unboxed(fn ->
      Code.eval_file(@edge_seed)
      original_customer = Repo.get_by!(Customer, processor_id: "cus_e2e_edge_1")
      sentinel = insert_sentinel!()

      try do
        fun.(original_customer, sentinel)
      after
        cleanup_unrelated_child!()
        restore_edge_customer!(original_customer)
        Code.eval_file(@edge_cleanup)
        cleanup_sentinel!(sentinel)
      end
    end)
  end

  defp with_unboxed(fun) do
    Task.async(fn -> with_repo_connection(fun) end)
    |> Task.await(15_000)
  end

  defp with_repo_connection(fun) do
    :ok = Sandbox.checkout(Repo, sandbox: false)

    try do
      fun.()
    after
      Sandbox.checkin(Repo)
    end
  end

  defp with_env(keys, fun) do
    previous = Map.new(keys, &{&1, System.get_env(&1)})

    try do
      fun.()
    after
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end
  end

  defp assert_graph_matches!(facts) do
    customer = Repo.get!(Customer, facts.customer.id)
    subscription = Repo.get!(Subscription, facts.subscription.id)

    items =
      Repo.all(
        from item in SubscriptionItem,
          where: item.subscription_id == ^subscription.id,
          order_by: item.id
      )

    assert customer.processor == facts.customer.processor
    assert customer.processor_id == facts.customer.processor_id
    assert customer.owner_type == facts.customer.owner_type
    assert customer.owner_id == facts.customer.owner_id
    assert customer.name == facts.customer.name
    assert customer.email == facts.customer.email
    assert subscription.customer_id == customer.id
    assert subscription.processor == facts.subscription.processor
    assert subscription.processor_id == facts.subscription.processor_id
    assert subscription.status == facts.subscription.status
    assert subscription.cancel_at_period_end == facts.subscription.cancel_at_period_end

    assert DateTime.compare(
             subscription.current_period_start,
             facts.subscription.current_period_start
           ) == :eq

    assert DateTime.compare(
             subscription.current_period_end,
             facts.subscription.current_period_end
           ) == :eq

    assert length(items) == length(facts.subscription.items)

    Enum.zip(items, facts.subscription.items)
    |> Enum.each(fn {item, expected} ->
      assert item.id == expected.id
      assert item.subscription_id == subscription.id
      assert item.processor == expected.processor
      assert item.processor_id == expected.processor_id
      assert item.price_id == expected.price_id
      assert item.quantity == expected.quantity
    end)
  end

  defp assert_scenario_count!(facts, expected) do
    assert scenario_count(facts) == %{
             customers: expected,
             subscriptions: expected,
             items: expected
           }
  end

  defp scenario_count(facts) do
    %{
      customers:
        Repo.aggregate(from(row in Customer, where: row.id == ^facts.customer.id), :count),
      subscriptions:
        Repo.aggregate(from(row in Subscription, where: row.id == ^facts.subscription.id), :count),
      items:
        Repo.aggregate(
          from(row in SubscriptionItem, where: row.id == ^hd(facts.subscription.items).id),
          :count
        )
    }
  end

  defp identity_set(facts_list) do
    facts_list
    |> Enum.flat_map(fn facts ->
      [
        facts.customer.id,
        facts.customer.processor_id,
        facts.subscription.id,
        facts.subscription.processor_id
        | Enum.flat_map(facts.subscription.items, &[&1.id, &1.processor_id])
      ]
    end)
    |> MapSet.new()
  end

  defp cleanup_subscription_facts! do
    if Code.ensure_loaded?(facts_module()) do
      for scenario <- [:launch, :growing_team] do
        facts = apply(facts_module(), :fetch!, [scenario])
        item_facts = hd(facts.subscription.items)

        if item = Repo.get(SubscriptionItem, item_facts.id) do
          if item.subscription_id == facts.subscription.id and
               item.processor_id == item_facts.processor_id,
             do: Repo.delete!(item)
        end

        if subscription = Repo.get(Subscription, facts.subscription.id) do
          if subscription.customer_id == facts.customer.id and
               subscription.processor_id == facts.subscription.processor_id,
             do: Repo.delete!(subscription)
        end

        if customer = Repo.get(Customer, facts.customer.id) do
          if customer.processor_id == facts.customer.processor_id and
               customer.owner_id == facts.customer.owner_id,
             do: Repo.delete!(customer)
        end
      end
    end
  end

  defp facts_module, do: Module.concat(["CadenceSubscriptionFacts"])

  defp seed_module, do: Module.concat(["AccrueHost", "Phase252SubscriptionScenarioSeed"])

  defp insert_unrelated_subscription!(customer) do
    attrs = %{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "sub_e2e_edge_unrelated_252",
      status: :active,
      metadata: %{},
      data: %{}
    }

    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert!()
  end

  defp insert_sentinel! do
    customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_phase252_unrelated_sentinel",
        name: "Phase 252 unrelated sentinel",
        email: "phase252-sentinel@example.test",
        metadata: %{},
        data: %{}
      })
      |> Repo.insert!()

    subscription =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_phase252_unrelated_sentinel",
        status: :active,
        metadata: %{},
        data: %{}
      })
      |> Repo.insert!()

    %{customer: customer, subscription: subscription}
  end

  defp sentinel_snapshot(sentinel) do
    %{
      customer: Repo.get(Customer, sentinel.customer.id),
      subscription: Repo.get(Subscription, sentinel.subscription.id)
    }
  end

  defp cleanup_sentinel!(sentinel) do
    if subscription = Repo.get(Subscription, sentinel.subscription.id) do
      if subscription.customer_id == sentinel.customer.id and
           subscription.processor_id == sentinel.subscription.processor_id,
         do: Repo.delete!(subscription)
    end

    if customer = Repo.get(Customer, sentinel.customer.id) do
      if customer.processor_id == sentinel.customer.processor_id and
           customer.owner_id == sentinel.customer.owner_id,
         do: Repo.delete!(customer)
    end
  end

  defp edge_snapshot do
    %{
      customer: Repo.get_by(Customer, processor_id: "cus_e2e_edge_1"),
      subscriptions:
        Repo.all(
          from row in Subscription,
            where:
              row.processor_id in [
                "sub_e2e_edge_at_risk",
                "sub_e2e_edge_canceling",
                "sub_e2e_edge_unrelated_252"
              ],
            order_by: row.processor_id
        ),
      charge: Repo.get_by(Charge, processor_id: "ch_e2e_edge_jpy"),
      invoice: Repo.get_by(Invoice, processor_id: "in_e2e_edge_jpy")
    }
  end

  defp empty_edge_snapshot do
    %{customer: nil, subscriptions: [], charge: nil, invoice: nil}
  end

  defp cleanup_unrelated_child! do
    if row = Repo.get_by(Subscription, processor_id: "sub_e2e_edge_unrelated_252") do
      if customer = Repo.get(Customer, row.customer_id) do
        if customer.processor_id == "cus_e2e_edge_1" and row.processor == "fake" do
          Repo.delete!(row)
        end
      end
    end
  end

  defp restore_edge_customer!(original) do
    if customer = Repo.get(Customer, original.id) do
      if customer.processor_id == original.processor_id and customer.owner_id == original.owner_id do
        Repo.update!(
          Customer.changeset(customer, %{owner_type: original.owner_type, email: original.email})
        )
      end
    end
  end

  defp await_parent_lock_wait?(timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    await_parent_lock_wait?(deadline, timeout_ms)
  end

  defp await_parent_lock_wait?(deadline, timeout_ms) do
    if System.monotonic_time(:millisecond) >= deadline do
      false
    else
      [[waiters]] =
        Repo.query!("""
        SELECT count(*)
        FROM pg_stat_activity
        WHERE datname = current_database()
          AND wait_event_type = 'Lock'
          AND query ILIKE '%FOR UPDATE%'
          AND pid <> pg_backend_pid()
        """).rows

      if waiters > 0 do
        true
      else
        Process.sleep(20)
        await_parent_lock_wait?(deadline, timeout_ms)
      end
    end
  end
end
