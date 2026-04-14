defmodule Accrue.Billing.Dunning do
  @moduledoc """
  Pure policy module for BILL-15 dunning (D4-02 hybrid).

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

  alias Accrue.Billing.Subscription

  @type decision :: {:sweep, :unpaid | :canceled} | :hold | :skip
  @type policy :: keyword()

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
end
