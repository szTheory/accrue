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
    * `:grace_plans` — `MapSet` of plan atoms admitted via the past-due
      grace window (a SUBSET of `:active_plans`). Empty when
      `past_due_grace` is `:none` (the default). `Accrue.Entitlements` reads
      it to select the `:past_due_grace` telemetry reason without re-querying.
    * `:grace_features` — `MapSet` of features contributed by `:grace_plans`;
      lets `Accrue.Entitlements` decide whether a feature grant was decided
      by grace (and so should report `:past_due_grace`).
    * `:expired_grace_plans` — `MapSet` of plan atoms whose `:past_due` grace
      window has lapsed; these do NOT grant, but let `Accrue.Entitlements`
      report the distinct `:past_due_expired` reason on the resulting deny.

  Resolvers that do not implement the past-due grace overlay MAY omit the
  three grace fields; `Accrue.Entitlements` treats absent grace fields as
  empty.
  """
  @type resolved :: %{
          required(:plan) => term(),
          required(:active_plans) => MapSet.t(),
          required(:features) => MapSet.t(),
          required(:quantities) => map(),
          optional(:grace_plans) => MapSet.t(),
          optional(:grace_features) => MapSet.t(),
          optional(:expired_grace_plans) => MapSet.t()
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
    config = Application.get_env(:accrue, :entitlements, [])

    if Keyword.has_key?(config, :multi_rail) do
      Accrue.Entitlements.Compatibility
    else
      Keyword.get(config, :resolver, Accrue.Entitlements.Resolver.LocalMap)
    end
  end
end
