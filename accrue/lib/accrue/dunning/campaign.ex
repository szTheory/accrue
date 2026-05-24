defmodule Accrue.Dunning.Campaign do
  @moduledoc """
  Pure step resolver for the built-in dunning campaign (DUN-02, D-11).

  No side effects, no DB, no job queue, no Stripe, no clock — both `now`
  and `campaign_started_at` are passed in. The `Accrue.Workers.DunningStep`
  worker (Plan 05) reads the wall clock once and hands the timestamps to
  this module, then asks one question after delivering each step: "given
  the configured journey and how long the campaign has been running, what
  should I enqueue next, and when?"

  Keeping the resolver pure is deliberate:

    * the property test (`(steps, started_at, now)` generators) needs no
      sandbox and runs `async: true`, and
    * the Phase-131 `Accrue.Dunning.Engine` behaviour is a clean
      extraction of this exact contract (this plan does NOT introduce the
      behaviour — it only ships the pure function it will wrap).

  ## Step contract (from Plan 01 config)

      [after_days: non_neg_integer(), key: atom(), template: module() | atom()]

  `after_days` is an ABSOLUTE offset from the campaign anchor, and the
  step list is ordered with strictly-increasing, unique `after_days`. This
  module does not re-validate that invariant — `Accrue.Config` enforces it
  at boot; the resolver assumes a well-formed ordered list and is total
  over any input regardless.

  ## Resolution

  `elapsed = DateTime.diff(now, campaign_started_at, :second)`. The next
  step is the FIRST step whose `after_days * 86_400` is greater than or
  equal to `elapsed` — a step whose boundary has not yet *passed* is still
  pending. This is what gives day-0 its "first step immediately" semantics:
  with a `after_days: 0` first step at zero elapsed, `0 >= 0` holds, so the
  resolver returns that step with `schedule_in == 0`. A step strictly
  *behind* `elapsed` has already been delivered and is skipped. The delay
  until the next step is `schedule_in = max(0, after_days_seconds - elapsed)`,
  which is `0` on day-0 (immediate send) and can never go negative under
  clock skew or a stale anchor — that clamp is the T-128-05 mitigation
  (Oban rejects negative delays).

  ## Return values

    * `{:next, step, schedule_in}` — the next step to send (the original
      keyword from `steps`) and the non-negative number of seconds until
      it should be delivered. `schedule_in == 0` means "send now".
    * `:done` — the journey is exhausted (every step's boundary has
      already elapsed) or the step list is empty. The worker chain stops.
  """

  @type step :: keyword()
  @type result :: {:next, step(), non_neg_integer()} | :done

  @seconds_per_day 86_400

  @doc """
  Resolve the next dunning step and the delay until it.

  Pure: `campaign_started_at` and `now` are arguments — this function
  never reads a clock or touches the DB/Oban/Stripe.

  Returns `{:next, step, schedule_in}` for the first step whose absolute
  `after_days` boundary is still in the future relative to `now`, or
  `:done` when the journey is exhausted (or `steps` is empty).

  ## Examples

      iex> anchor = ~U[2026-01-01 00:00:00Z]
      iex> steps = [[after_days: 0, key: :reminder, template: A], [after_days: 5, key: :final, template: B]]
      iex> Accrue.Dunning.Campaign.next_step(steps, anchor, anchor)
      {:next, [after_days: 0, key: :reminder, template: A], 0}

      iex> anchor = ~U[2026-01-01 00:00:00Z]
      iex> Accrue.Dunning.Campaign.next_step([], anchor, anchor)
      :done
  """
  @spec next_step([step()], DateTime.t(), DateTime.t()) :: result()
  def next_step([], _campaign_started_at, _now), do: :done

  def next_step(steps, %DateTime{} = campaign_started_at, %DateTime{} = now)
      when is_list(steps) do
    elapsed = DateTime.diff(now, campaign_started_at, :second)

    case Enum.find(steps, &pending_step?(&1, elapsed)) do
      nil ->
        :done

      step ->
        after_days_seconds = Keyword.fetch!(step, :after_days) * @seconds_per_day
        {:next, step, max(0, after_days_seconds - elapsed)}
    end
  end

  # A step is still pending iff its absolute boundary has not yet passed
  # relative to `elapsed` (>= keeps an at-boundary step pending, which is
  # what gives day-0 its immediate semantics). A step strictly behind
  # `elapsed` has already been delivered, so the resolver advances past it.
  @spec pending_step?(step(), integer()) :: boolean()
  defp pending_step?(step, elapsed) do
    Keyword.fetch!(step, :after_days) * @seconds_per_day >= elapsed
  end
end
