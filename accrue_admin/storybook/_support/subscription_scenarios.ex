unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(
    Path.expand("../../../dev_support/ui_scenarios/cadence_subscriptions.exs", __DIR__)
  )
end

defmodule AccrueAdmin.Storybook.SubscriptionScenarios do
  @moduledoc false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias Accrue.Money
  alias Accrue.Processor.Capabilities
  alias AccrueAdmin.OwnerScope

  @supported_providers %{"stripe" => :stripe, "braintree" => :braintree}
  @capability_paths %{
    swap_plan: [:subscription, :swap_plan],
    update_quantity: [:subscription, :update_quantity]
  }
  @attribution %{
    actor: "vendor billing support operator",
    job: "understand subscription state and choose a supported next action",
    input_source: "deterministic Cadence scenario facts",
    production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
    proof_lane: "static render"
  }
  @allowed_attributes Map.keys(@attribution) ++ [:scenario]

  @doc "Lists the stable scenario identifiers made available to ordinary story consumers."
  def list, do: CadenceSubscriptionFacts.list()

  @doc "Returns the stable review attribution attached to a known story variation."
  def attributes(scenario) when is_atom(scenario) do
    if scenario in list() do
      Map.put(@attribution, :scenario, scenario)
    else
      raise ArgumentError, "unsupported Cadence subscription scenario: #{inspect(scenario)}"
    end
  end

  @doc "Validates scenario facts or a declared story input against real billing rules."
  def validate!(input) when is_atom(input),
    do: input |> CadenceSubscriptionFacts.fetch!() |> validate_facts!()

  def validate!(input) when is_map(input) do
    if facts_input?(input) do
      validate_facts!(input)
    else
      validate_story_input!(input)
    end
  end

  def validate!(_input),
    do: raise(ArgumentError, "story input must be a known scenario or fact map")

  @doc "Builds deterministic domain structs and owner-scoped assigns without starting Repo."
  def assigns!(input) do
    facts = validate!(input)

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

  defp validate_story_input!(attributes) do
    case validate_attributes(attributes) do
      :ok -> :ok
      {:error, message} -> raise ArgumentError, message
    end

    scenario = Map.fetch!(attributes, :scenario)
    scenario |> CadenceSubscriptionFacts.fetch!() |> validate_facts!()
  end

  defp facts_input?(input) do
    Enum.any?([:owner, :customer, :subscription, :billing], &Map.has_key?(input, &1))
  end

  defp validate_facts!(facts) do
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

  defp validate_attributes(attributes) do
    unknown = Map.keys(attributes) -- @allowed_attributes

    mismatch =
      Enum.find(@attribution, fn {key, expected} ->
        Map.has_key?(attributes, key) and Map.get(attributes, key) != expected
      end)

    scenario = Map.get(attributes, :scenario)

    cond do
      unknown != [] ->
        {:error, "story input contains unsupported fields: #{inspect(unknown)}"}

      mismatch ->
        {:error, "story attribution does not match the static review contract"}

      scenario not in list() ->
        {:error, "story input requires a declared scenario"}

      true ->
        :ok
    end
  end

  defp validate_actor(%{actor: %{type: :admin, id: id}})
       when is_binary(id) and id != "",
       do: :ok

  defp validate_actor(_facts), do: {:error, "scenario requires an explicit admin actor"}

  defp validate_owner(%{
         owner: %{type: owner_type, id: owner_id, slug: slug},
         customer: %{owner_type: owner_type, owner_id: owner_id}
       })
       when is_binary(owner_id) and owner_id != "" and is_binary(slug) and slug != "",
       do: :ok

  defp validate_owner(_facts),
    do: {:error, "scenario owner must match the billed customer and include an organization slug"}

  defp validate_provider(%{
         provider: provider,
         capability: capability,
         customer: customer,
         subscription: %{items: items} = subscription
       })
       when is_binary(provider) and is_map(customer) and is_list(items) do
    with {:ok, provider_atom} <- Map.fetch(@supported_providers, provider),
         {:ok, capability_path} <- Map.fetch(@capability_paths, capability),
         label when is_binary(label) and label not in ["unsupported", "out of slice"] <-
           Capabilities.provider_support_label(provider_atom, capability_path),
         true <- Map.get(customer, :processor) == provider,
         true <- Map.get(subscription, :processor) == provider,
         true <- Enum.all?(items, &(is_map(&1) and Map.get(&1, :processor) == provider)) do
      :ok
    else
      _ -> {:error, "scenario provider is not supported by the subscription action contract"}
    end
  end

  defp validate_provider(_facts),
    do: {:error, "scenario requires a supported provider and subscription items"}

  defp validate_scenario(%{lane: :ordinary, scenario: scenario}) do
    if is_atom(scenario) and scenario in CadenceSubscriptionFacts.list() do
      :ok
    else
      {:error, "scenario must be a declared ordinary Cadence fact"}
    end
  end

  defp validate_scenario(_facts), do: {:error, "scenario must declare the ordinary review lane"}

  defp validate_records(%{
         customer: customer,
         subscription: subscription,
         now: now,
         billing: billing
       })
       when is_map(customer) and is_map(subscription) and is_struct(now, DateTime) do
    items = Map.get(subscription, :items)

    with true <- is_list(items) and items != [],
         true <- Enum.all?(items, &is_map/1),
         true <- Map.get(subscription, :customer_id) == Map.get(customer, :id),
         true <- Enum.all?(items, &(Map.get(&1, :subscription_id) == Map.get(subscription, :id))),
         true <- valid_ids?(customer, subscription, items),
         :ok <- validate_period(subscription),
         :ok <- validate_billing(billing),
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
          {:error, _message} = error -> {:halt, error}
        end
      end)
    else
      false ->
        {:error, "scenario records require stable linked customer, subscription, and item IDs"}

      {:error, _message} = error ->
        error
    end
  end

  defp validate_records(_facts),
    do: {:error, "scenario requires customer, subscription, clock, and billing facts"}

  defp valid_ids?(customer, subscription, items) do
    ids = [
      Map.get(customer, :id),
      Map.get(subscription, :id) | Enum.map(items, &Map.get(&1, :id))
    ]

    Enum.all?(ids, &match?({:ok, _}, Ecto.UUID.cast(&1)))
  end

  defp validate_period(subscription) do
    starts_at = Map.get(subscription, :current_period_start)
    ends_at = Map.get(subscription, :current_period_end)

    cond do
      not is_nil(starts_at) and not is_struct(starts_at, DateTime) ->
        {:error, "scenario period start must be a DateTime when projected"}

      not is_nil(ends_at) and not is_struct(ends_at, DateTime) ->
        {:error, "scenario period end must be a DateTime when projected"}

      is_struct(starts_at, DateTime) and is_struct(ends_at, DateTime) and
          DateTime.compare(starts_at, ends_at) != :lt ->
        {:error, "scenario current period chronology is reversed"}

      true ->
        :ok
    end
  end

  defp validate_billing(%{amount_minor: amount_minor, currency: currency}) do
    try do
      money = Money.new(amount_minor, currency)

      if money.amount_minor >= 0 do
        :ok
      else
        {:error, "scenario billed amount cannot be negative"}
      end
    rescue
      ArgumentError ->
        {:error, "scenario billed amount must use a known integer minor-unit currency"}
    end
  end

  defp validate_billing(_billing),
    do: {:error, "scenario requires an integer minor-unit billed amount and currency"}

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
