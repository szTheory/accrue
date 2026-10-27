defmodule AccrueAdmin.Storybook.SubscriptionCollection do
  @moduledoc false

  use Phoenix.LiveComponent

  alias AccrueAdmin.Live.SubscriptionsLive
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Storybook.SubscriptionCollectionQuery
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @scenarios [:launch, :growing_team]

  @impl true
  def update(assigns, socket) do
    scenario = normalize_scenario!(Map.get(assigns, :scenario, :launch))
    scoped_facts = Enum.map(@scenarios, &CadenceSubscriptionFacts.fetch!/1)
    Enum.each(scoped_facts, &SubscriptionScenarios.validate!/1)

    owner_scope = %OwnerScope{
      mode: :global,
      current_admin: %{id: "admin_cadence_collection", role: :admin},
      platform_admin?: true,
      admin_org_ids: Enum.map(scoped_facts, & &1.owner.id)
    }

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:scenario, scenario)
     |> assign(:current_owner_scope, owner_scope)
     |> assign(:table_path, "/billing/subscriptions")
     |> assign(:params, %{"view" => "all", "status" => "active"})
     |> assign(:summary, %{
       active_count: 2,
       canceling_count: 0,
       past_due_count: 0,
       paused_count: 0,
       total_count: length(scoped_facts)
     })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-storybook-subscription-collection={Atom.to_string(@scenario)}>
      <SubscriptionsLive.subscriptions_collection
        admin_mount_path="/billing"
        current_owner_scope={@current_owner_scope}
        table_path={@table_path}
        params={@params}
        summary={@summary}
        flash={%{}}
        query_module={SubscriptionCollectionQuery}
        limit={1}
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

    rows =
      @scenarios
      |> Enum.map(&row_for/1)
      |> Enum.filter(&visible_to_scope?(&1, owner_scope))
      |> Enum.filter(&matches_filter?(&1, filter))
      |> Enum.sort_by(&{DateTime.to_unix(&1.inserted_at, :microsecond), &1.id}, :desc)
      |> after_cursor(Keyword.get(opts, :cursor))

    Behaviour.paginate(rows, Behaviour.normalize_limit(opts), :inserted_at)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    rows =
      @scenarios
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
