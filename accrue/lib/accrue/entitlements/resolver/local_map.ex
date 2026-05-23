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
         * `quantities` — merged `quota_key => min(cap, quantity)`,
         * `grace_plans` — the SUBSET of `active_plans` admitted via the
           past-due grace window (empty unless `past_due_grace` is enabled).

  Past-due grace overlay (ENT-09): when `Accrue.Config.past_due_grace/0` is
  `:none` (default) the base fetch stays `Query.entitling/1` with the lean
  `{price_id, quantity}` select — zero query/compute change. When grace is
  enabled the fetch widens to `Query.entitling_with_grace_candidates/1` (adds
  `:past_due` only, never `:unpaid`), and each `:past_due` candidate (per
  `Subscription.dunning_sweepable?/1`) is kept only if
  `PastDueGrace.within_grace?/2` is true for its `past_due_since`; kept rows
  are tagged into `grace_plans`. A grace grant is an affirmative, resolved,
  configured decision — never a fail-open.

  An active item whose `price_id` is unmapped is dropped under the default
  `:deny` (and its plan is NOT added to `active_plans`); under `:raise` the
  resolver raises so the context's `try/rescue` collapses it to fail-closed.

  `:plan` carries a single representative active plan (the last folded one,
  or `nil`) for display only — membership decisions use `active_plans`.
  """

  @behaviour Accrue.Entitlements.Resolver

  import Ecto.Query

  alias Accrue.Billing.{Customer, Query, Subscription, SubscriptionItem}
  alias Accrue.Entitlements.PastDueGrace

  @empty %{
    plan: nil,
    active_plans: MapSet.new(),
    features: MapSet.new(),
    quantities: %{},
    grace_plans: MapSet.new(),
    grace_features: MapSet.new(),
    expired_grace_plans: MapSet.new()
  }

  # The fold carries one extra internal accumulator (`:non_grace_features`)
  # used only to compute the exclusive `:grace_features` set; it is stripped
  # before the resolved map is returned.
  @fold_seed Map.put(@empty, :non_grace_features, MapSet.new())

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

  # Public seam for the admin read-only diagnostic (ENT-11). Reuses fold_active/1 —
  # the SSOT fold — so there is zero drift; it does NOT widen the public gate API
  # (@doc false keeps it off the published docs surface).
  @doc false
  def fold_for_customer(%Customer{} = customer), do: fold_active(customer)

  # The entitling price_ids the resolver structurally discards under :deny
  # (handle_unmapped/3) — the resolved map can never show this drift, so the seam
  # re-derives it from the same catalog()/active_items() privates the fold uses.
  @doc false
  def unmapped_entitling_price_ids(%Customer{id: customer_id}) do
    {reverse_index, _plans, _action} = catalog()

    customer_id
    |> active_items()
    |> Enum.map(fn {price_id, _qty, _via} -> price_id end)
    |> Enum.reject(&Map.has_key?(reverse_index, &1))
    |> Enum.uniq()
  end

  defp fold_active(%Customer{id: customer_id}) do
    {reverse_index, plans, unmapped_action} = catalog()

    folded =
      customer_id
      |> active_items()
      |> Enum.reduce(@fold_seed, fn item, acc ->
        fold_item(item, acc, reverse_index, plans, unmapped_action)
      end)

    # A feature granted by BOTH a grace plan and a normal active plan is decided
    # by the normal plan (`:entitled`), not by grace — so the exclusive grace
    # feature set subtracts every feature any non-grace plan also grants. Strip
    # the internal accumulator before returning the public resolved map.
    folded
    |> Map.put(:grace_features, MapSet.difference(folded.grace_features, folded.non_grace_features))
    |> Map.delete(:non_grace_features)
  end

  # An out-of-window `:past_due` candidate does NOT grant, but its (mapped)
  # plan is recorded in `expired_grace_plans` so `Accrue.Entitlements` can
  # surface the `:past_due_expired` reason (distinct from
  # `:no_active_subscription`). Unmapped expired rows have no plan to record.
  defp fold_item({price_id, _quantity, :expired}, acc, reverse_index, _plans, _unmapped) do
    case Map.fetch(reverse_index, price_id) do
      {:ok, plan_atom} ->
        %{acc | expired_grace_plans: MapSet.put(acc.expired_grace_plans, plan_atom)}

      :error ->
        acc
    end
  end

  defp fold_item({price_id, quantity, via_grace?}, acc, reverse_index, plans, unmapped_action) do
    case Map.fetch(reverse_index, price_id) do
      {:ok, plan_atom} ->
        plan_entry = Keyword.get(plans, plan_atom, [])
        merge_plan(acc, plan_atom, plan_entry, quantity, via_grace?)

      :error ->
        handle_unmapped(acc, price_id, unmapped_action)
    end
  end

  # Returns a normalized list of `{price_id, quantity, via_grace?}` tuples.
  #
  # Cost-aware (D-18): the common `past_due_grace: :none` case keeps the lean
  # `{price_id, quantity}` select via the entitlement-grade `Query.entitling/1`
  # (zero query/compute change, every row `via_grace? == false`). When grace is
  # enabled the fetch widens to `Query.entitling_with_grace_candidates/1` (adds
  # `:past_due` only, never `:unpaid`) with a richer select carrying the row so
  # the per-row clock window check runs in Elixir; out-of-window `:past_due`
  # rows are dropped BEFORE folding, and kept `:past_due` rows are tagged so the
  # resolver can record them in `:grace_plans`.
  defp active_items(customer_id) do
    case Accrue.Config.past_due_grace() do
      :none -> none_lane_items(customer_id)
      grace -> grace_lane_items(customer_id, grace)
    end
  end

  # `Query.entitling/1` is the entitlement-grade base fetch: active/trialing,
  # not paused, not ended. It is the database twin of `Subscription.entitling?/1`,
  # so it closes the paused fail-open gap (a `status: :active` row with a non-nil
  # `pause_collection` no longer grants entitlement) and folds in the WR-04
  # ended-row exclusion. The status-only active fragment keeps its semantics for
  # other callers (dunning sweeper, projections) and is intentionally NOT used
  # for the entitlement gate.
  defp none_lane_items(customer_id) do
    Subscription
    |> Query.entitling()
    |> where([s], s.customer_id == ^customer_id)
    |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
    |> select([_s, i], {i.price_id, i.quantity})
    |> Accrue.Repo.all()
    |> Enum.map(fn {price_id, quantity} -> {price_id, quantity, false} end)
  end

  defp grace_lane_items(customer_id, grace) do
    grace_days = grace_days(grace)

    Subscription
    |> Query.entitling_with_grace_candidates()
    |> where([s], s.customer_id == ^customer_id)
    |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
    |> select([s, i], {i.price_id, i.quantity, s})
    |> Accrue.Repo.all()
    |> Enum.flat_map(fn {price_id, quantity, sub} -> grace_row(price_id, quantity, sub, grace_days) end)
  end

  # A `:past_due` candidate (per `Subscription.dunning_sweepable?/1`, the
  # Credo-clean strict-`:past_due` check) is kept (tagged `true`) only inside
  # the grace window; outside it, it is marked `:expired` so the resolver can
  # record `expired_grace_plans` (it does NOT grant). Non-candidate rows (the
  # active/trialing rows the widen fragment also returns) always fold (`false`),
  # never tagged as grace.
  defp grace_row(price_id, quantity, sub, grace_days) do
    cond do
      not Subscription.dunning_sweepable?(sub) -> [{price_id, quantity, false}]
      PastDueGrace.within_grace?(sub, grace_days) -> [{price_id, quantity, true}]
      true -> [{price_id, quantity, :expired}]
    end
  end

  # Resolve the configured policy to a concrete day count: `:dunning` reuses the
  # dunning overlay's `grace_days`; an integer N is used directly.
  defp grace_days(:dunning), do: Accrue.Config.dunning() |> Keyword.fetch!(:grace_days)
  defp grace_days(n) when is_integer(n) and n > 0, do: n

  defp merge_plan(acc, plan_atom, plan_entry, quantity, via_grace?) do
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

    feature_set = MapSet.new(features)

    {grace_plans, grace_features, non_grace_features} =
      if via_grace? do
        {MapSet.put(acc.grace_plans, plan_atom), MapSet.union(acc.grace_features, feature_set),
         acc.non_grace_features}
      else
        {acc.grace_plans, acc.grace_features, MapSet.union(acc.non_grace_features, feature_set)}
      end

    %{
      acc
      | plan: plan_atom,
        active_plans: MapSet.put(acc.active_plans, plan_atom),
        features: MapSet.union(acc.features, feature_set),
        quantities: quantities,
        grace_plans: grace_plans,
        grace_features: grace_features,
        non_grace_features: non_grace_features
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
