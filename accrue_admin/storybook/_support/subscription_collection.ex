defmodule AccrueAdmin.Storybook.SubscriptionCollection do
  @moduledoc false

  use Phoenix.LiveComponent

  alias AccrueAdmin.Live.SubscriptionsLive
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Storybook.SubscriptionCollectionQuery
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @scenarios [:launch, :growing_team]
  @collection_states [
    :new_host_empty,
    :filtered_empty,
    :queue_empty,
    :one_row,
    :multiple_rows,
    :page_boundary,
    :loading,
    :unavailable,
    :partial_cursor_error,
    :incomplete_projection
  ]

  @impl true
  def update(assigns, socket) do
    scenario = normalize_scenario!(Map.get(assigns, :scenario, :launch))

    collection_state =
      normalize_collection_state!(Map.get(assigns, :collection_state, :one_row))

    scoped_facts = Enum.map(@scenarios, &CadenceSubscriptionFacts.fetch!/1)
    Enum.each(scoped_facts, &SubscriptionScenarios.validate!/1)

    story_instance =
      socket.assigns[:story_instance] || System.unique_integer([:positive, :monotonic])

    owner_scope = %OwnerScope{
      mode: :global,
      current_admin: %{id: "admin_cadence_collection", role: :admin},
      platform_admin?: true,
      admin_org_ids: Enum.map(scoped_facts, & &1.owner.id)
    }

    # Story state lives only on this dev-only scope instance, never in route params.
    owner_scope =
      Map.put(owner_scope, :story_collection_context, %{
        state: collection_state,
        scenario: scenario,
        instance: story_instance
      })

    params = params_for(collection_state)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:scenario, scenario)
     |> assign(:collection_state, collection_state)
     |> assign(:story_instance, story_instance)
     |> assign(:current_owner_scope, owner_scope)
     |> assign(:table_path, "/billing/subscriptions")
     |> assign(:params, params)
     |> assign(:summary, summary_for(collection_state, scoped_facts))
     |> assign(:limit, if(collection_state in [:multiple_rows], do: 2, else: 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      data-storybook-subscription-collection={Atom.to_string(@scenario)}
      data-storybook-subscription-state={Atom.to_string(@collection_state)}
    >
      <SubscriptionsLive.subscriptions_collection
        admin_mount_path="/billing"
        current_owner_scope={@current_owner_scope}
        table_path={@table_path}
        params={@params}
        summary={@summary}
        flash={%{}}
        query_module={SubscriptionCollectionQuery}
        limit={@limit}
      />
    </div>
    """
  end

  defp normalize_scenario!(:launch), do: :launch
  defp normalize_scenario!(:growing_team), do: :growing_team
  defp normalize_scenario!("launch"), do: :launch
  defp normalize_scenario!("growing_team"), do: :growing_team

  defp normalize_scenario!(scenario),
    do: raise(ArgumentError, "unsupported collection scenario: #{inspect(scenario)}")

  defp normalize_collection_state!(state) when state in @collection_states, do: state

  defp normalize_collection_state!(state) when is_binary(state) do
    case Enum.find(@collection_states, &(Atom.to_string(&1) == state)) do
      nil -> normalize_collection_state!(state)
      normalized -> normalized
    end
  end

  defp normalize_collection_state!(state),
    do: raise(ArgumentError, "unsupported collection state: #{inspect(state)}")

  defp params_for(:new_host_empty), do: %{"view" => "all"}

  defp params_for(:filtered_empty),
    do: %{"view" => "all", "q" => "phase253-no-matching-subscriptions"}

  defp params_for(:queue_empty), do: %{"status" => "past_due,canceling"}

  defp params_for(:loading),
    do: %{"view" => "all", "phase196_state" => "loading-skeleton"}

  defp params_for(:unavailable), do: %{"view" => "all"}
  defp params_for(:partial_cursor_error), do: %{"view" => "all"}
  defp params_for(_state), do: %{"view" => "all"}

  defp summary_for(:new_host_empty, _scoped_facts) do
    %{active_count: 0, canceling_count: 0, past_due_count: 0, paused_count: 0, total_count: 0}
  end

  defp summary_for(state, _scoped_facts) when state in [:one_row, :incomplete_projection] do
    %{active_count: 1, canceling_count: 0, past_due_count: 0, paused_count: 0, total_count: 1}
  end

  defp summary_for(_state, scoped_facts) do
    %{
      active_count: length(scoped_facts),
      canceling_count: 0,
      past_due_count: 0,
      paused_count: 0,
      total_count: length(scoped_facts)
    }
  end
end

defmodule AccrueAdmin.Storybook.SubscriptionCollectionQuery do
  @moduledoc false

  @behaviour AccrueAdmin.Queries.Behaviour

  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.{Behaviour, Cursor, Subscriptions}
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @scenarios [:launch, :growing_team]

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    owner_scope = Keyword.get(opts, :owner_scope)
    context = story_context(owner_scope)
    if context.state == :unavailable do
      raise DBConnection.ConnectionError, message: "fixture subscription history unavailable"
    end

    if (context.state == :partial_cursor_error and Keyword.get(opts, :cursor)) &&
         fail_partial_cursor_once?(context.instance) do
      raise DBConnection.ConnectionError, message: "fixture next subscription page unavailable"
    end

    rows =
      context
      |> scenarios_for_state()
      |> Enum.map(&row_for/1)
      |> Enum.filter(&visible_to_scope?(&1, owner_scope))
      |> Enum.filter(&matches_filter?(&1, filter))
      |> Enum.sort_by(&{DateTime.to_unix(&1.inserted_at, :microsecond), &1.id}, :desc)
      |> after_cursor(Keyword.get(opts, :cursor))

    limit = if context.state == :page_boundary, do: 1, else: Behaviour.normalize_limit(opts)

    Behaviour.paginate(rows, limit, :inserted_at)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    context = story_context(Keyword.get(opts, :owner_scope))

    rows =
      context
      |> scenarios_for_state()
      |> Enum.map(&row_for/1)
      |> Enum.filter(&visible_to_scope?(&1, Keyword.get(opts, :owner_scope)))
      |> Enum.filter(&matches_filter?(&1, Keyword.get(opts, :filter, %{})))

    case Cursor.decode(Keyword.get(opts, :cursor)) do
      {:ok, {timestamp, id}} -> Enum.count(rows, &newer_than?(&1, timestamp, id))
      :error -> 0
    end
  end

  @impl true
  def decode_filter(params), do: Subscriptions.decode_filter(params)

  @impl true
  def encode_filter(filter), do: Subscriptions.encode_filter(filter)

  defp story_context(%{story_collection_context: context}) when is_map(context), do: context
  defp story_context(_owner_scope), do: %{state: :multiple_rows, scenario: :launch, instance: nil}

  defp scenarios_for_state(%{state: :new_host_empty}), do: []
  defp scenarios_for_state(%{state: :queue_empty}), do: []

  defp scenarios_for_state(%{state: :one_row, scenario: scenario}),
    do: [normalize_scenario!(scenario)]

  defp scenarios_for_state(%{state: :incomplete_projection, scenario: scenario}),
    do: [normalize_scenario!(scenario)]

  defp scenarios_for_state(%{state: state})
       when state in [:multiple_rows, :page_boundary, :loading],
       do: @scenarios

  defp scenarios_for_state(%{state: state}) when state in [:unavailable, :partial_cursor_error],
    do: @scenarios

  defp scenarios_for_state(%{state: :filtered_empty}), do: @scenarios
  defp scenarios_for_state(_context), do: @scenarios

  defp normalize_scenario!(scenario) when scenario in @scenarios, do: scenario
  defp normalize_scenario!("launch"), do: :launch
  defp normalize_scenario!("growing_team"), do: :growing_team

  defp fail_partial_cursor_once?(instance) do
    key = {__MODULE__, :partial_cursor_failed, instance}

    if Process.get(key) do
      false
    else
      Process.put(key, true)
      true
    end
  end

  defp row_for(scenario) do
    facts = CadenceSubscriptionFacts.fetch!(scenario)
    SubscriptionScenarios.validate!(facts)
    %{subscription: subscription, customer: customer} = SubscriptionScenarios.assigns!(facts)
    [item | _] = subscription.subscription_items

    %{
      id: subscription.id,
      customer_id: customer.id,
      customer_name: customer.name,
      customer_email: customer.email,
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      automatic_tax: subscription.automatic_tax,
      automatic_tax_disabled_reason: subscription.automatic_tax_disabled_reason,
      processor_id: subscription.processor_id,
      status: subscription.status,
      cancel_at_period_end: subscription.cancel_at_period_end,
      current_period_end: subscription.current_period_end,
      trial_end: subscription.trial_end,
      ended_at: subscription.ended_at,
      plan_price_id: item.price_id,
      plan_quantity: item.quantity,
      plan_item_count: length(subscription.subscription_items),
      inserted_at: facts.now
    }
  end

  defp visible_to_scope?(row, %OwnerScope{mode: :organization, organization_id: owner_id}),
    do: row.owner_type == "Organization" and row.owner_id == owner_id

  defp visible_to_scope?(
         row,
         %OwnerScope{mode: :global, platform_admin?: true, admin_org_ids: owner_ids}
       ),
       do: row.owner_type == "Organization" and row.owner_id in owner_ids

  defp visible_to_scope?(_row, _scope), do: false

  defp matches_filter?(row, filter) do
    matches_search?(row, Map.get(filter, :q) || Map.get(filter, "q")) and
      matches_status?(row, Map.get(filter, :status) || Map.get(filter, "status")) and
      matches_customer?(row, Map.get(filter, :customer_id) || Map.get(filter, "customer_id"))
  end

  defp matches_search?(_row, nil), do: true

  defp matches_search?(row, query) when is_binary(query) do
    query = String.downcase(query)

    [row.customer_name, row.customer_email, row.processor_id, row.id]
    |> Enum.any?(&(is_binary(&1) and String.contains?(String.downcase(&1), query)))
  end

  defp matches_search?(_row, _query), do: true

  defp matches_status?(_row, nil), do: true

  defp matches_status?(row, statuses) do
    statuses
    |> to_string()
    |> String.split(",", trim: true)
    |> Enum.any?(&(&1 == to_string(row.status)))
  end

  defp matches_customer?(_row, nil), do: true

  defp matches_customer?(row, customer_id),
    do: to_string(row.customer_id) == to_string(customer_id)

  defp after_cursor(rows, nil), do: rows

  defp after_cursor(rows, cursor) do
    case Cursor.decode(cursor) do
      {:ok, {timestamp, id}} -> Enum.filter(rows, &older_than?(&1, timestamp, id))
      :error -> []
    end
  end

  defp older_than?(row, timestamp, id) do
    case DateTime.compare(row.inserted_at, timestamp) do
      :lt -> true
      :eq -> row.id < id
      :gt -> false
    end
  end

  defp newer_than?(row, timestamp, id) do
    case DateTime.compare(row.inserted_at, timestamp) do
      :gt -> true
      :eq -> row.id > id
      :lt -> false
    end
  end
end
