defmodule Accrue.Billing.Query do
  @moduledoc """
  Composable `Ecto.Query` fragments mirroring the
  `Accrue.Billing.Subscription` predicates.

  Every predicate in `Accrue.Billing.Subscription` has a matching query
  fragment here so you can filter subscriptions in the database with the
  same semantics as the in-memory predicates. Prefer these fragments over
  direct `.status` comparisons in `where` clauses — the predicates on
  `Accrue.Billing.Subscription` are the correct way to check subscription
  state, as direct comparisons miss edge cases like `cancel_at_period_end`
  and `ended_at` that the predicates cover.

  All functions accept an optional queryable (default
  `Accrue.Billing.Subscription`) and compose via `|>`:

      import Ecto.Query

      from(s in Subscription, where: s.customer_id == ^id)
      |> Accrue.Billing.Query.active()
      |> Repo.all()
  """

  import Ecto.Query

  alias Accrue.Billing.Subscription

  @doc "Subscriptions counted as active (includes `:trialing`)."
  @spec active(Ecto.Queryable.t()) :: Ecto.Query.t()
  def active(query \\ Subscription) do
    from(s in query, where: s.status in [:active, :trialing])
  end

  @doc "Subscriptions currently in trial."
  @spec trialing(Ecto.Queryable.t()) :: Ecto.Query.t()
  def trialing(query \\ Subscription) do
    from(s in query, where: s.status == :trialing)
  end

  @doc """
  Subscriptions that are `:active` with `cancel_at_period_end` set and a
  period end still in the future — i.e. the cancel hasn't landed yet.
  """
  @spec canceling(Ecto.Queryable.t()) :: Ecto.Query.t()
  def canceling(query \\ Subscription) do
    now = Accrue.Clock.utc_now()

    from(s in query,
      where:
        s.status == :active and s.cancel_at_period_end == true and
          s.current_period_end > ^now
    )
  end

  @doc "Subscriptions that are terminated (`:canceled`, `:incomplete_expired`, or any ended_at)."
  @spec canceled(Ecto.Queryable.t()) :: Ecto.Query.t()
  def canceled(query \\ Subscription) do
    from(s in query,
      where: s.status in [:canceled, :incomplete_expired] or not is_nil(s.ended_at)
    )
  end

  @doc "Subscriptions that are past due or unpaid (dunning territory)."
  @spec past_due(Ecto.Queryable.t()) :: Ecto.Query.t()
  def past_due(query \\ Subscription) do
    from(s in query, where: s.status in [:past_due, :unpaid])
  end

  @doc "Subscriptions that are paused (legacy `:paused` status or non-nil `pause_collection`)."
  @spec paused(Ecto.Queryable.t()) :: Ecto.Query.t()
  def paused(query \\ Subscription) do
    from(s in query, where: s.status == :paused or not is_nil(s.pause_collection))
  end

  @doc """
  Subscriptions eligible for a dunning sweep tick: strictly
  `:past_due`, with `past_due_since` older than the grace window, and
  with no prior `dunning_sweep_attempted_at` stamp.
  """
  @spec dunning_sweep_candidates(pos_integer(), Ecto.Queryable.t()) :: Ecto.Query.t()
  def dunning_sweep_candidates(grace_days, query \\ Subscription)
      when is_integer(grace_days) and grace_days > 0 do
    cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)

    from(s in query,
      where:
        s.status == :past_due and
          not is_nil(s.past_due_since) and
          s.past_due_since < ^cutoff and
          is_nil(s.dunning_sweep_attempted_at)
    )
  end
end
