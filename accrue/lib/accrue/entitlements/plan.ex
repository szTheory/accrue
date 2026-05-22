defmodule Accrue.Entitlements.Plan do
  @moduledoc """
  Pure value struct for a resolved entitlement plan.

  This is **not** an Ecto schema and touches no database — it is the
  in-memory shape a resolver folds active subscription state into. The
  optional Stripe-native entitlement *cache* schema is a later-phase
  concern and is intentionally not modeled here.

  ## Fields

    * `:plan_id` — the logical plan name (atom) this entry represents, or
      `nil` for an empty/unresolved result.
    * `:features` — a `MapSet` of feature atoms granted by the plan.
    * `:quantities` — a map of `quota_key => non_neg_integer` seat/quota
      caps (already reduced to `min(cap, quantity)` by the resolver where a
      cap exists).
  """

  @type t :: %__MODULE__{
          plan_id: term(),
          features: MapSet.t(),
          quantities: map()
        }

  defstruct plan_id: nil, features: MapSet.new(), quantities: %{}
end
