# Opt-in only: this consumer persists the ordinary shared launch/team facts
# into a guarded disposable host test database. It is not part of seeds.exs.
defmodule AccrueHost.Phase252SubscriptionScenarioSeed do
  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias AccrueHost.{OrdinarySeedBoundary, Repo}

  @facts_path Path.expand(
                "../../../../../dev_support/ui_scenarios/cadence_subscriptions.exs",
                __DIR__
              )
  @scenarios %{"launch" => :launch, "growing_team" => :growing_team}

  @doc "Persist one explicitly selected ordinary shared fact set after both lane and DB checks."
  def run_from_env! do
    run!(Repo, %{
      lane: System.fetch_env!("PHASE252_SUBSCRIPTION_LANE"),
      scenario: System.fetch_env!("PHASE252_SUBSCRIPTION_SCENARIO")
    })
  end

  @doc false
  def run!(repo, %{lane: lane, scenario: scenario})
      when is_binary(lane) and is_binary(scenario) do
    unless lane == "ordinary" and System.get_env("PHASE248_PROOF_LANE") != "heldout" do
      raise ArgumentError, "Phase 252 subscription seed requires the ordinary lane"
    end

    [[database, role, server_address]] =
      repo.query!("SELECT current_database(), current_user, host(inet_server_addr())").rows

    unless OrdinarySeedBoundary.allowed?(Mix.env(), database, role, server_address, nil) do
      raise ArgumentError, "Phase 252 subscription seed requires a disposable host test database"
    end

    source_scenario = Map.get(@scenarios, scenario)

    unless source_scenario do
      raise ArgumentError, "unsupported ordinary subscription scenario selection"
    end

    Code.require_file(@facts_path)
    facts = CadenceSubscriptionFacts.fetch!(source_scenario)

    unless facts.lane == :ordinary do
      raise ArgumentError, "Phase 252 subscription seed refuses non-ordinary source facts"
    end

    case repo.transaction(fn -> persist_graph!(repo, facts) end) do
      {:ok, graph} ->
        graph

      {:error, reason} ->
        raise "Phase 252 subscription seed transaction failed: #{inspect(reason)}"
    end
  end

  def run!(_repo, _opts),
    do: raise(ArgumentError, "Phase 252 subscription seed requires explicit lane and scenario")

  defp persist_graph!(repo, facts) do
    customer_attrs = Map.drop(facts.customer, [:id])
    customer = insert_exact!(repo, Customer, facts.customer.id, customer_attrs)

    subscription_attrs = Map.drop(facts.subscription, [:id, :items])
    subscription = insert_exact!(repo, Subscription, facts.subscription.id, subscription_attrs)

    items =
      Enum.map(facts.subscription.items, fn item_facts ->
        insert_exact!(repo, SubscriptionItem, item_facts.id, Map.drop(item_facts, [:id]))
      end)
      |> Enum.sort_by(& &1.id)

    %{customer: customer, subscription: subscription, items: items}
  end

  defp insert_exact!(repo, schema, id, attrs) do
    case repo.get(schema, id) do
      nil ->
        schema
        |> struct(id: id)
        |> schema.changeset(attrs)
        |> repo.insert!()

      existing ->
        if existing.id == id and matches?(existing, attrs) do
          existing
        else
          raise ArgumentError, "Phase 252 subscription seed refused a mismatched existing row"
        end
    end
  end

  defp matches?(row, attrs) do
    Enum.all?(attrs, fn {field, expected} -> equal?(Map.fetch!(row, field), expected) end)
  end

  defp equal?(%DateTime{} = actual, %DateTime{} = expected),
    do: DateTime.compare(actual, expected) == :eq

  defp equal?(actual, expected), do: actual == expected
end

AccrueHost.Phase252SubscriptionScenarioSeed.run_from_env!()
