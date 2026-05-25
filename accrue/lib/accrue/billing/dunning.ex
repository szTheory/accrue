defmodule Accrue.Billing.Dunning do
  @moduledoc """
  Pure policy module for dunning.

  No side effects, no DB, no Stripe calls — `Accrue.Jobs.DunningSweeper`
  owns those. This module's job is to answer one question for each
  candidate subscription: "given the configured policy, what should we
  ask the processor facade to do next?"

  The sweeper is a thin grace-period overlay on top of Stripe Smart
  Retries. Stripe still owns the retry cadence. Accrue only asks the
  processor to move the subscription to the terminal action once the
  grace window has elapsed and we have not already asked (tracked via
  `dunning_sweep_attempted_at`).

  ## Policy shape

      [
        mode: :stripe_smart_retries | :disabled,
        grace_days: pos_integer(),
        terminal_action: :unpaid | :canceled,
        telemetry_prefix: [atom()]
      ]

  ## Decisions

    * `:skip` — do nothing (not past_due, already swept, or disabled).
    * `:hold` — past_due but still inside the grace window.
    * `{:sweep, terminal_action}` — grace elapsed; sweeper should ask
      the processor facade to move the subscription to `terminal_action`.

  Local subscription status is NEVER touched by the sweeper (D2-29 —
  Stripe is canonical; the webhook flips the row).
  """

  import Ecto.Query, only: [from: 2, where: 3]

  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event

  @type decision :: {:sweep, :unpaid | :canceled} | :hold | :skip
  @type policy :: keyword()

  # Confirmed-transition lifecycle ledger types this counter folds.
  # The sweeper's request-time terminal-action-request ledger type is
  # DELIBERATELY ABSENT — counting request-time intent would let "lost"
  # double-count (D-06).
  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"

  @doc """
  Pure decision function. Given a subscription row and a dunning policy,
  returns whether the sweeper should `:skip`, `:hold`, or
  `{:sweep, terminal_action}`.
  """
  @spec compute_terminal_action(Subscription.t(), policy()) :: decision()
  def compute_terminal_action(%Subscription{} = sub, policy) when is_list(policy) do
    cond do
      Keyword.get(policy, :mode) == :disabled ->
        :skip

      not Subscription.dunning_sweepable?(sub) ->
        :skip

      not is_nil(sub.dunning_sweep_attempted_at) ->
        :skip

      grace_elapsed?(
        sub.past_due_since,
        Keyword.fetch!(policy, :grace_days),
        DateTime.utc_now()
      ) ->
        {:sweep, Keyword.fetch!(policy, :terminal_action)}

      true ->
        :hold
    end
  end

  @doc """
  Returns `true` when `now` is more than `grace_days` past `past_due_since`.

  A `nil` `past_due_since` returns `false` — with no recorded start of
  the past_due window, there is no grace to elapse.
  """
  @spec grace_elapsed?(DateTime.t() | nil, pos_integer(), DateTime.t()) :: boolean()
  def grace_elapsed?(nil, _grace_days, _now), do: false

  def grace_elapsed?(%DateTime{} = past_due_since, grace_days, %DateTime{} = now)
      when is_integer(grace_days) and grace_days > 0 do
    DateTime.diff(now, past_due_since, :second) > grace_days * 86_400
  end

  @doc """
  Folds the `accrue_events` ledger into a flat
  `%{recovered: n, lost: n}` counter answering the merchant question
  "how much past-due revenue did dunning recover vs. lose to terminal
  action?" (DUN-08 SC#4).

  This is the **derivable** recovered-vs-lost signal — a query API, not a
  dashboard (the full analytics dashboard is milestone Out-of-Scope). It
  adds NO new table: it counts the two confirmed-transition lifecycle
  ledger types written by the campaign:

    * `recovered` = count of `dunning.recovered` events
    * `lost`      = count of `dunning.exhausted` events

  It DELIBERATELY excludes the sweeper's request-time terminal-action
  request event — that is request-time intent (sweeper-only, may exist
  with no campaign), so counting it would let "lost" double-count (D-06).
  The excluded type is never referenced here.

  ## Options

    * `:since` — `%DateTime{}` lower bound (inclusive), inclusive on
      `inserted_at >= since`.
    * `:until` — `%DateTime{}` upper bound (inclusive), `inserted_at <= until`.

  Both bounds are bound as Ecto query parameters (`^since` / `^until`) —
  no string interpolation into SQL (parameterized query, V5).

  Returns the raw counts only; callers compute any recovery rate
  themselves (no derived rate field — D-08).

  ## Examples

      iex> Accrue.Billing.Dunning.recovered_vs_lost()
      %{recovered: 12, lost: 3}

      iex> Accrue.Billing.Dunning.recovered_vs_lost(since: ~U[2026-05-01 00:00:00Z])
      %{recovered: 4, lost: 1}
  """
  @spec recovered_vs_lost(keyword()) :: %{recovered: non_neg_integer(), lost: non_neg_integer()}
  def recovered_vs_lost(opts \\ []) when is_list(opts) do
    %{
      recovered: count_events(@recovered_type, opts),
      lost: count_events(@exhausted_type, opts)
    }
  end

  # Flat parameterized count of a single ledger type over the optional
  # since:/until: window. Mirrors the type-filter + since/until shape of
  # `Accrue.Events` `bucket_query/1` but as a flat count — it does NOT call
  # that private query nor the time-bucketed `bucket_by/2`.
  @spec count_events(String.t(), keyword()) :: non_neg_integer()
  defp count_events(type, opts) do
    from(e in Event, where: e.type == ^type)
    |> apply_window(opts)
    |> Accrue.Repo.aggregate(:count, :id)
  end

  defp apply_window(query, opts) do
    query
    |> maybe_since(opts[:since])
    |> maybe_until(opts[:until])
  end

  defp maybe_since(query, %DateTime{} = since),
    do: where(query, [e], e.inserted_at >= ^since)

  defp maybe_since(query, _), do: query

  defp maybe_until(query, %DateTime{} = until),
    do: where(query, [e], e.inserted_at <= ^until)

  defp maybe_until(query, _), do: query
end
