defmodule AccrueAdmin.SubscriptionScenariosTapFormatter do
  use GenServer

  def init(_opts), do: {:ok, []}

  def handle_cast({:test_finished, test}, results), do: {:noreply, [test | results]}

  def handle_cast({:suite_finished, _times}, results) do
    tests = Enum.reverse(results)
    IO.puts("TAP version 13")

    tests
    |> Enum.with_index(1)
    |> Enum.each(fn {test, index} ->
      name = "#{inspect(test.module)}::#{test.name}" |> String.replace(~r/[\r\n]+/u, " ")

      case test.state do
        nil ->
          IO.puts("ok #{index} - #{name}")

        {:skipped, _reason} ->
          IO.puts("ok #{index} - #{name} # SKIP")

        {:failed, failures} ->
          IO.puts("not ok #{index} - #{name}")

          Enum.each(failures, fn failure ->
            failure
            |> inspect(pretty: false, limit: :infinity)
            |> String.split("\n")
            |> Enum.each(&IO.puts("# " <> &1))
          end)

        _ ->
          IO.puts("not ok #{index} - #{name}")
      end
    end)

    IO.puts("1..#{length(tests)}")
    {:noreply, []}
  end

  def handle_cast(_event, results), do: {:noreply, results}
end

ExUnit.start(formatters: [AccrueAdmin.SubscriptionScenariosTapFormatter])

repo_root = Path.expand("../../../../", __DIR__)

unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(Path.join(repo_root, "dev_support/ui_scenarios/cadence_subscriptions.exs"))
end

unless Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionScenarios) do
  Code.require_file(
    Path.join(repo_root, "accrue_admin/storybook/_support/subscription_scenarios.ex")
  )
end

defmodule AccrueAdmin.SubscriptionScenariosTest do
  use ExUnit.Case, async: false

  alias Accrue.Billing.Subscription
  alias Accrue.Processor.Fake
  alias AccrueAdmin.Storybook.SubscriptionManifest
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @fixed_now ~U[2026-10-25 12:00:00Z]

  setup do
    case Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    previous_env = Application.get_env(:accrue, :env, :unset)
    Application.put_env(:accrue, :env, :test)
    {:ok, _started} = Application.ensure_all_started(:localize)
    :ok = Fake.reset()
    :ok = Fake.advance(DateTime.diff(@fixed_now, Fake.current_time(), :second))

    on_exit(fn ->
      :ok = Fake.reset()

      case previous_env do
        :unset -> Application.delete_env(:accrue, :env)
        value -> Application.put_env(:accrue, :env, value)
      end
    end)

    :ok
  end

  test "launch and growing-team facts share a deterministic DB-free Cadence source" do
    assert function_exported?(CadenceSubscriptionFacts, :list, 0)

    # CURATE-01 / AMD-254-01: the compatibility members of the ordinary list follow the curation
    # ledger (frozen baseline compatibility ids minus the retired ones) instead of a literal.
    %{present: present, absent: absent} =
      compatibility_expectations(SubscriptionManifest.curation_ledger())

    listed = CadenceSubscriptionFacts.list()

    assert Enum.take(listed, 5) ==
             [:active, :launch, :growing_team, :scheduled_cancellation, :incomplete_evidence]

    listed_ids = Enum.map(listed, &Atom.to_string/1)

    assert listed |> Enum.drop(5) |> Enum.map(&Atom.to_string/1) |> Enum.sort() ==
             Enum.sort(present)

    for id <- absent do
      refute id in listed_ids, "retired compatibility id #{id} is still in the ordinary list"
    end

    launch = CadenceSubscriptionFacts.fetch!(:launch)
    team = CadenceSubscriptionFacts.fetch!(:growing_team)

    assert launch == CadenceSubscriptionFacts.fetch!(:launch)
    assert team == CadenceSubscriptionFacts.fetch!(:growing_team)
    assert launch.now == @fixed_now
    assert team.now == @fixed_now
    assert launch.actor.type == :admin
    assert team.actor.type == :admin
    assert launch.owner.id == launch.customer.owner_id
    assert team.owner.id == team.customer.owner_id
    assert launch.customer.processor == launch.subscription.processor
    assert team.customer.processor == team.subscription.processor
    assert hd(launch.subscription.items).quantity == 1
    assert hd(team.subscription.items).quantity == 12
    assert Process.whereis(AccrueAdmin.TestRepo) == nil
  end

  test "the shared fact source stays plain, DB-free, and outside Admin runtime sources" do
    repo_root = Path.expand("../../../../", __DIR__)
    source_path = Path.expand("dev_support/ui_scenarios/cadence_subscriptions.exs", repo_root)
    package_source = Path.expand("accrue_admin/lib", repo_root)
    source = File.read!(source_path)

    assert Path.relative_to(source_path, repo_root) ==
             "dev_support/ui_scenarios/cadence_subscriptions.exs"

    refute source_path == package_source
    refute String.starts_with?(source_path, package_source <> "/")
    refute source =~ "AccrueAdmin"
    refute source =~ "Storybook"
    refute Regex.match?(~r/\bRepo\b/, source)
    assert Process.whereis(AccrueAdmin.TestRepo) == nil
  end

  test "all canonical lifecycle facts validate while missing projections remain valid" do
    for scenario <- [:active, :scheduled_cancellation, :incomplete_evidence] do
      facts = CadenceSubscriptionFacts.fetch!(scenario)
      assert SubscriptionScenarios.validate!(facts) == facts
      assert is_map(SubscriptionScenarios.assigns!(facts))
    end

    incomplete = CadenceSubscriptionFacts.fetch!(:incomplete_evidence)
    assert incomplete.subscription.current_period_start == nil
    assert incomplete.subscription.current_period_end == nil
    assert hd(incomplete.subscription.items).price_id == nil
  end

  test "repeated fact fetches retain stable IDs and never consult wall-clock time" do
    first = CadenceSubscriptionFacts.fetch!(:active)
    second = CadenceSubscriptionFacts.fetch!(:active)

    assert first == second
    assert first.now == @fixed_now
    assert first.customer.id == second.customer.id
    assert first.subscription.id == second.subscription.id

    assert Enum.map(first.subscription.items, & &1.id) ==
             Enum.map(second.subscription.items, & &1.id)

    %{present: present, absent: absent} =
      compatibility_expectations(SubscriptionManifest.curation_ledger())

    # A kept compatibility id either has its own facts or aliases the active scenario.
    for id <- present, atom = String.to_atom(id) do
      assert CadenceSubscriptionFacts.fetch!(atom).scenario in [atom, :active]
    end

    # A retired compatibility id is no longer a supported scenario.
    for id <- absent do
      assert_raise ArgumentError, fn -> CadenceSubscriptionFacts.fetch!(String.to_atom(id)) end
    end

    assert_raise ArgumentError, fn -> CadenceSubscriptionFacts.fetch!(:unrecognized) end
  end

  test "invalid enum control is rejected through Subscription changeset before assigns" do
    facts = put_in(CadenceSubscriptionFacts.fetch!(:active), [:subscription, :status], :rooted)

    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(facts) end
  end

  test "orphan and mismatched-owner controls are rejected before assigns" do
    orphaned =
      put_in(
        CadenceSubscriptionFacts.fetch!(:active),
        [:subscription, :customer_id],
        "0f4d7bb9-3d7f-4fa5-a9b5-ea0219485037"
      )

    mismatched_owner =
      put_in(CadenceSubscriptionFacts.fetch!(:active), [:customer, :owner_id], "different-owner")

    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(orphaned) end
    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(mismatched_owner) end
  end

  test "unsupported provider capability and cross-record provider controls are rejected" do
    unsupported = put_in(CadenceSubscriptionFacts.fetch!(:active), [:provider], "unsupported")

    unsupported_capability =
      put_in(CadenceSubscriptionFacts.fetch!(:braintree_pruned), [:capability], :update_quantity)

    mismatched_item =
      put_in(
        CadenceSubscriptionFacts.fetch!(:active),
        [:subscription, :items, Access.at(0), :processor],
        "braintree"
      )

    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(unsupported) end

    assert_raise ArgumentError, fn ->
      SubscriptionScenarios.assigns!(unsupported_capability)
    end

    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(mismatched_item) end
  end

  test "money controls accept exact zero and large minor units and reject invalid amounts or currencies" do
    facts = CadenceSubscriptionFacts.fetch!(:active)
    zero = put_in(facts, [:billing, :amount_minor], 0)
    large = put_in(facts, [:billing, :amount_minor], 9_007_199_254_740_993)

    assert SubscriptionScenarios.validate!(zero).billing.amount_minor == 0
    assert SubscriptionScenarios.validate!(large).billing.amount_minor == 9_007_199_254_740_993

    for amount <- [-1, 12.5, "100"] do
      invalid = put_in(facts, [:billing, :amount_minor], amount)
      assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(invalid) end
    end

    unknown_currency = put_in(facts, [:billing, :currency], :not_a_currency)
    untyped_currency = put_in(facts, [:billing, :currency], "not_a_currency")

    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(unknown_currency) end
    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(untyped_currency) end
  end

  test "reversed chronology is rejected while optional period projections may be absent" do
    assert function_exported?(CadenceSubscriptionFacts, :list, 0)
    assert :incomplete_evidence in CadenceSubscriptionFacts.list()

    facts = CadenceSubscriptionFacts.fetch!(:active)

    reversed =
      put_in(facts, [:subscription, :current_period_end], facts.subscription.current_period_start)

    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(reversed) end
    empty = put_in(facts, [:subscription, :items], [])
    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(empty) end
    assert SubscriptionScenarios.validate!(CadenceSubscriptionFacts.fetch!(:incomplete_evidence))
  end

  test "canceling boundary follows the canonical predicate at, before, and after fixed time" do
    assert Fake.current_time() == @fixed_now

    for {offset, expected} <- [{-1, false}, {0, false}, {1, true}] do
      subscription = %Subscription{
        status: :active,
        cancel_at_period_end: true,
        current_period_end: DateTime.add(@fixed_now, offset, :second)
      }

      assert Subscription.canceling?(subscription) == expected
    end
  end

  test "held-out long text is explicitly separated from ordinary scenarios" do
    assert function_exported?(CadenceSubscriptionFacts, :held_out!, 1)

    held_out = CadenceSubscriptionFacts.held_out!(:long_text)

    assert held_out.lane == :held_out
    assert held_out.held_out_case == :long_text
    assert String.length(held_out.customer.name) > 120
    refute :held_out_long_text in CadenceSubscriptionFacts.list()
  end

  test "nil, absent and unrecognized story inputs fail clearly" do
    assert_raise ArgumentError, fn -> SubscriptionScenarios.validate!(nil) end
    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(%{}) end
    assert_raise ArgumentError, fn -> SubscriptionScenarios.assigns!(%{scenario: :unknown}) end
  end

  test "compatibility expectations follow the ledger: a retired id must be absent, the rest present" do
    ledger = %{
      frozen_baseline: %{compatibility_ids: ["alpha", "beta", "gamma"]},
      records: []
    }

    assert compatibility_expectations(ledger) == %{
             present: ["alpha", "beta", "gamma"],
             absent: []
           }

    retired = %{
      disposition: "retire",
      subject: %{story_path: "/components/subscription_detail", variation_id: "beta"}
    }

    mutated = %{ledger | records: [retired]}
    assert compatibility_expectations(mutated) == %{present: ["alpha", "gamma"], absent: ["beta"]}

    # Only a removal of a subscription_detail variation changes the expectation.
    for other <- [
          %{retired | disposition: "retain"},
          %{retired | subject: %{retired.subject | story_path: "/components/action_menu"}},
          %{retired | subject: %{retired.subject | variation_id: nil}}
        ] do
      assert compatibility_expectations(%{ledger | records: [other]}).absent == []
    end
  end

  defp compatibility_expectations(ledger) do
    retired =
      for record <- ledger.records,
          record.disposition in ["retire", "merge"],
          record.subject.story_path == "/components/subscription_detail",
          is_binary(record.subject.variation_id),
          do: record.subject.variation_id

    compatibility = ledger.frozen_baseline.compatibility_ids
    %{present: compatibility -- retired, absent: Enum.filter(compatibility, &(&1 in retired))}
  end
end
