defmodule Accrue.Entitlements.Resolver.LocalMap do
  @moduledoc """
  Default entitlement resolver — derives a billable's entitlements from
  **local subscription state only**, with zero processor calls.

  Resolution path:

    1. Read-only `accrue_customers` lookup by `(owner_type, owner_id)` —
       a clone of the private `Accrue.Billing.fetch_customer/2`, NEVER the
       effectful get-or-create customer path (which would hit the processor
       on a miss). A `nil`/wrong-shape billable resolves to no customer.
    2. Entitling-subscription read via `Accrue.Billing.Query.entitling/1`
       (active/trialing, not paused, not ended; the database twin of
       `Accrue.Billing.Subscription.entitling?/1`; never raw `.status`)
       joined to its items, selecting `{price_id, quantity}`. Using the
       entitlement-grade fragment closes the paused fail-open gap: a
       `status: :active` row with a non-nil `pause_collection` no longer
       grants entitlement.
    3. Fold each active item through the `price_id -> plan` reverse index
       built from `Accrue.Config.entitlements/0`, accumulating:
         * `active_plans` — the SET of ALL active plan atoms (membership
           source of truth for `has_active_plan?/2`),
         * `features` — the UNION of every active plan's features,
         * `quantities` — merged `quota_key => min(cap, quantity)`.

  An active item whose `price_id` is unmapped is dropped under the default
  `:deny` (and its plan is NOT added to `active_plans`); under `:raise` the
  resolver raises so the context's `try/rescue` collapses it to fail-closed.

  `:plan` carries a single representative active plan (the last folded one,
  or `nil`) for display only — membership decisions use `active_plans`.
  """

  @behaviour Accrue.Entitlements.Resolver

  import Ecto.Query

  alias Accrue.Billing.{Customer, Query, Subscription, SubscriptionItem}

  @empty %{plan: nil, active_plans: MapSet.new(), features: MapSet.new(), quantities: %{}}

  @impl true
  def resolve(billable, _opts \\ []) do
    case lookup_customer(billable) do
      %Customer{} = customer -> {:ok, fold_active(customer)}
      nil -> {:ok, @empty}
    end
  end

  # Read-only customer lookup — clones the private fetch_customer/2 query.
  # NEVER calls the effectful get-or-create customer path (no processor).
  defp lookup_customer(%{__struct__: mod, id: id}) when not is_nil(id) do
    owner_type = mod.__accrue__(:billable_type)
    owner_id = to_string(id)

    Accrue.Repo.one(
      from(c in Customer,
        where: c.owner_type == ^owner_type and c.owner_id == ^owner_id,
        limit: 1
      )
    )
  rescue
    # A struct that does not implement __accrue__/1 (i.e. not a billable)
    # fails closed to "no customer".
    UndefinedFunctionError -> nil
  end

  defp lookup_customer(_), do: nil

  defp fold_active(%Customer{id: customer_id}) do
    active_items =
      Subscription
      # `Query.entitling/1` is the entitlement-grade base fetch: active/trialing,
      # not paused, not ended. It is the database twin of
      # `Subscription.entitling?/1`, so it closes the paused fail-open gap (a
      # `status: :active` row with a non-nil `pause_collection` no longer grants
      # entitlement) and folds in the WR-04 ended-row exclusion (`is_nil(ended_at)`)
      # that used to live here as a local `where`. The status-only active
      # fragment keeps its semantics for other callers (dunning sweeper,
      # projections) and is intentionally NOT used for the entitlement gate.
      |> Query.entitling()
      |> where([s], s.customer_id == ^customer_id)
      |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
      |> select([_s, i], {i.price_id, i.quantity})
      |> Accrue.Repo.all()

    {reverse_index, plans, unmapped_action} = catalog()

    Enum.reduce(active_items, @empty, fn {price_id, quantity}, acc ->
      case Map.fetch(reverse_index, price_id) do
        {:ok, plan_atom} ->
          plan_entry = Keyword.get(plans, plan_atom, [])
          merge_plan(acc, plan_atom, plan_entry, quantity)

        :error ->
          handle_unmapped(acc, price_id, unmapped_action)
      end
    end)
  end

  defp merge_plan(acc, plan_atom, plan_entry, quantity) do
    features = Keyword.get(plan_entry, :features, [])
    limits = Keyword.get(plan_entry, :limits, [])

    # WR-01: when two active plans share a quota key, merge with the
    # most-generous (max) per-plan `min(cap, quantity)` rather than a blind
    # `Map.put/3` overwrite. `Map.put/3` was last-write-wins over the
    # DB-return order of active items — non-deterministic, and able to both
    # under- and over-grant. `Map.update/4` with `max/2` is deterministic and
    # order-independent (matches the union semantics used for active_plans and
    # features).
    quantities =
      Enum.reduce(limits, acc.quantities, fn {quota_key, cap}, q ->
        capped = min(cap, quantity)
        Map.update(q, quota_key, capped, &max(&1, capped))
      end)

    %{
      acc
      | plan: plan_atom,
        active_plans: MapSet.put(acc.active_plans, plan_atom),
        features: Enum.reduce(features, acc.features, &MapSet.put(&2, &1)),
        quantities: quantities
    }
  end

  defp handle_unmapped(acc, _price_id, :deny), do: acc

  defp handle_unmapped(_acc, price_id, :raise) do
    raise "Accrue.Entitlements: active price_id #{inspect(price_id)} is unmapped " <>
            "(unmapped_action: :raise)"
  end

  # Builds {price_id => plan_atom reverse index, plans keyword list, unmapped_action}
  # from the boot-validated :entitlements config.
  defp catalog do
    config = Accrue.Config.entitlements()
    plans = Keyword.get(config, :plans, [])
    unmapped_action = Keyword.get(config, :unmapped_action, :deny)

    reverse_index =
      Enum.reduce(plans, %{}, fn {plan_atom, entry}, acc ->
        entry
        |> Keyword.get(:price_ids, [])
        |> Enum.reduce(acc, fn price_id, inner -> Map.put(inner, price_id, plan_atom) end)
      end)

    {reverse_index, plans, unmapped_action}
  end
end
