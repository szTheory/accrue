defmodule Accrue.Entitlements.Resolver do
  @moduledoc """
  Behaviour + runtime-dispatch seam for entitlement resolution.

  A resolver derives a billable's current entitlements from local
  subscription state (the default `Accrue.Entitlements.Resolver.LocalMap`)
  or — for a host that opts in — from an alternate source. The
  `Accrue.Entitlements` context dispatches to the configured resolver via
  `__impl__/0`; swap it with:

      config :accrue, :entitlements, resolver: MyApp.Entitlements.Resolver

  ## The `active_plans` SET is the membership source of truth

  `resolve/2` returns a map whose `:active_plans` is the **SET of ALL active
  plan atoms** for the billable. `Accrue.Entitlements.has_active_plan?/2`
  tests membership against this set, never against the representative
  `:plan` field. A single representative would wrongly answer `false` for a
  billable holding two active subscriptions on two different mapped plans —
  carrying the full set keeps `has_active_plan?/2` consistent with the
  UNION semantics of `entitled?/2` and `features_for/1` (which already union
  features across all active subscriptions).

  `:plan` is a single representative (the last folded plan, or `nil`) kept
  for display / back-compat only — it MUST NOT be used for membership.
  """

  @typedoc """
  Resolved entitlement state.

    * `:plan` — representative active plan atom (or `nil`); display only,
      NOT the membership source.
    * `:active_plans` — `MapSet` of ALL active plan atoms; the membership
      source of truth.
    * `:features` — `MapSet` UNION of features across all active subs.
    * `:quantities` — merged `quota_key => min(cap, quantity)` map.
  """
  @type resolved :: %{
          plan: term(),
          active_plans: MapSet.t(),
          features: MapSet.t(),
          quantities: map()
        }

  @doc """
  Resolves the entitlement state for `billable`.

  Returns `{:ok, resolved}` (see `t:resolved/0`) — note `:active_plans` is
  the SET of all active plan atoms and is the membership source of truth
  (`:plan` is a representative only). May return `{:error, term}`; the
  context collapses any error/exception to the fail-closed value.
  """
  @callback resolve(billable :: term(), opts :: keyword()) ::
              {:ok, resolved()} | {:error, term()}

  @doc false
  @spec __impl__() :: module()
  def __impl__ do
    Application.get_env(:accrue, :entitlements, [])
    |> Keyword.get(:resolver, Accrue.Entitlements.Resolver.LocalMap)
  end
end
