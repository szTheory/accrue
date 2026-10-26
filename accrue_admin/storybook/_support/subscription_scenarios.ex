unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(
    Path.expand("../../../dev_support/ui_scenarios/cadence_subscriptions.exs", __DIR__)
  )
end

defmodule AccrueAdmin.Storybook.SubscriptionScenarios do
  @moduledoc false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias Accrue.Processor.Capabilities
  alias AccrueAdmin.OwnerScope

  @supported_providers %{"stripe" => :stripe, "braintree" => :braintree}
  @attribution %{
    actor: "vendor billing support operator",
    job: "understand subscription state and choose a supported next action",
    input_source: "deterministic Cadence scenario facts",
    production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
    proof_lane: "static render"
  }
  @allowed_attributes Map.keys(@attribution) ++ [:scenario]

  @doc "Returns the stable review attribution attached to a story variation."
  def attributes(scenario) when is_atom(scenario),
    do: Map.put(@attribution, :scenario, scenario)

  @doc "Validates a declared scenario or scenario attribute map against real billing changesets."
  def validate!(scenario_or_attributes) do
    scenario =
      case scenario_or_attributes do
        %{scenario: scenario} -> scenario
        scenario when is_atom(scenario) -> scenario
        _ -> nil
      end

    case validate_attributes(scenario_or_attributes) do
      :ok -> :ok
      {:error, message} -> raise ArgumentError, message
    end

    facts = CadenceSubscriptionFacts.fetch!(scenario)

    with :ok <- validate_actor(facts),
         :ok <- validate_owner(facts),
         :ok <- validate_provider(facts),
         :ok <- validate_scenario(facts),
         :ok <- validate_records(facts) do
      facts
    else
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc "Builds deterministic domain structs and owner-scoped assigns without starting Repo."
  def assigns!(scenario_or_attributes) do
    facts = validate!(scenario_or_attributes)

    customer =
      facts.customer
      |> Map.drop([:id])
      |> then(&Customer.changeset(%Customer{}, &1))
      |> apply_record!("customer")
      |> Map.put(:id, facts.customer.id)

    items =
      Enum.map(facts.subscription.items, fn attrs ->
        attrs
        |> Map.drop([:id])
        |> then(&SubscriptionItem.changeset(%SubscriptionItem{}, &1))
        |> apply_record!("subscription item")
        |> Map.put(:id, attrs.id)
      end)

    subscription =
      facts.subscription
      |> Map.drop([:id, :items])
      |> then(&Subscription.changeset(%Subscription{}, &1))
      |> apply_record!("subscription")
      |> Map.put(:id, facts.subscription.id)
      |> Map.put(:customer, customer)
      |> Map.put(:subscription_items, items)

    %{
      subscription: subscription,
      customer: customer,
      admin_mount_path: "/billing",
      current_owner_scope: owner_scope(facts),
      flashes: [],
      action_result: nil
    }
  end

  defp validate_actor(%{actor: %{type: :admin, id: id}}) when is_binary(id) and id != "",
    do: :ok

  defp validate_actor(_facts), do: {:error, "scenario requires an explicit admin actor"}

  defp validate_attributes(attributes) when is_map(attributes) do
    unknown = Map.keys(attributes) -- @allowed_attributes

    mismatch =
      Enum.find(@attribution, fn {key, expected} ->
        Map.has_key?(attributes, key) and Map.get(attributes, key) != expected
      end)

    cond do
      unknown != [] -> {:error, "story input contains unsupported fields: #{inspect(unknown)}"}
      mismatch -> {:error, "story attribution does not match the static review contract"}
      is_atom(Map.get(attributes, :scenario)) -> :ok
      true -> {:error, "story input requires a declared scenario"}
    end
  end

  defp validate_attributes(scenario) when is_atom(scenario), do: :ok

  defp validate_attributes(_),
    do: {:error, "story input must be a declared scenario or attribute map"}

  defp validate_owner(%{owner: owner, customer: customer}) do
    if owner.type == customer.owner_type and owner.id == customer.owner_id and
         is_binary(owner.slug) and owner.slug != "" do
      :ok
    else
      {:error, "scenario owner must match the billed customer and include an organization slug"}
    end
  end

  defp validate_provider(%{provider: provider} = facts) do
    with {:ok, provider_atom} <- Map.fetch(@supported_providers, provider),
         label when is_binary(label) and label != "unsupported" <-
           Capabilities.provider_support_label(provider_atom, [:subscription, :swap_plan]),
         true <- get_in(facts, [:customer, :processor]) == provider,
         true <- get_in(facts, [:subscription, :processor]) == provider,
         true <- Enum.all?(facts.subscription.items, &(&1.processor == provider)) do
      :ok
    else
      _ -> {:error, "scenario provider is not supported by the subscription action contract"}
    end
  end

  defp validate_records(facts) do
    customer = facts.customer
    subscription = facts.subscription
    items = subscription.items
    ids = [customer.id, subscription.id | Enum.map(items, & &1.id)]

    with true <- subscription.customer_id == customer.id,
         true <- items != [],
         true <- Enum.all?(items, &(&1.subscription_id == subscription.id)),
         true <- Enum.all?(ids, &valid_uuid?/1),
         true <- is_struct(facts.now, DateTime),
         true <- is_struct(subscription.current_period_start, DateTime),
         true <- is_struct(subscription.current_period_end, DateTime),
         true <- DateTime.compare(subscription.current_period_start, facts.now) == :lt,
         true <- DateTime.compare(facts.now, subscription.current_period_end) == :lt,
         :ok <-
           changeset_valid(Customer.changeset(%Customer{}, Map.drop(customer, [:id])), "customer"),
         :ok <-
           changeset_valid(
             Subscription.changeset(%Subscription{}, Map.drop(subscription, [:id, :items])),
             "subscription"
           ) do
      Enum.reduce_while(items, :ok, fn item, :ok ->
        case changeset_valid(
               SubscriptionItem.changeset(%SubscriptionItem{}, Map.drop(item, [:id])),
               "subscription item"
             ) do
          :ok -> {:cont, :ok}
          {:error, _} = error -> {:halt, error}
        end
      end)
    else
      false -> {:error, "scenario records require stable linked IDs and a current UTC period"}
      {:error, _message} = error -> error
    end
  end

  defp validate_scenario(%{lane: :ordinary}), do: :ok
  defp validate_scenario(_facts), do: {:error, "scenario must declare the ordinary review lane"}

  defp valid_uuid?(id), do: match?({:ok, _}, Ecto.UUID.cast(id))

  defp changeset_valid(changeset, label) do
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, _record} -> :ok
      {:error, invalid} -> {:error, "invalid #{label} scenario facts: #{inspect(invalid.errors)}"}
    end
  end

  defp apply_record!(changeset, label) do
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, record} ->
        record

      {:error, invalid} ->
        raise ArgumentError, "invalid #{label} facts: #{inspect(invalid.errors)}"
    end
  end

  defp owner_scope(facts) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: facts.actor.id, role: :admin},
      organization_id: facts.owner.id,
      organization_slug: facts.owner.slug,
      organization_display_name: facts.owner.name,
      platform_admin?: false,
      admin_org_ids: [facts.owner.id],
      active_organization_id: facts.owner.id,
      active_organization_slug: facts.owner.slug
    }
  end
end
