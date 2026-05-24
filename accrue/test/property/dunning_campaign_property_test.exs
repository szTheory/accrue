defmodule Accrue.Property.DunningCampaignPropertyTest do
  @moduledoc """
  StreamData property tests for the pure `Accrue.Dunning.Campaign` step
  resolver (DUN-02, D-11).

  The resolver is a pure function — no DB, no Oban, no Stripe, no clock.
  Both `campaign_started_at` and `now` are passed in as arguments, which
  is exactly what makes this property test trivial and the Phase-131
  `Accrue.Dunning.Engine` extraction a clean seam.

  Contract under test (`next_step/3`):

      next_step(steps, campaign_started_at, now)
        steps               :: [keyword]  (ordered, strictly-increasing,
                                           unique `after_days`)
        campaign_started_at :: DateTime.t()  (passed in — NOT a clock read)
        now                 :: DateTime.t()  (passed in — NOT a clock read)

      => {:next, step, schedule_in}  -- next step to send + non-negative
                                        seconds until it (0 == send now)
      => :done                       -- journey exhausted / no steps

  `elapsed = DateTime.diff(now, campaign_started_at, :second)`. The next
  step is the FIRST step whose absolute `after_days * 86_400` is strictly
  greater than `elapsed`; `schedule_in = max(0, after_days_seconds - elapsed)`.

  Properties verified:

    * Day-0 (now == campaign_started_at) → first step, `schedule_in == 0`.
    * `schedule_in` is always non-negative and equals
      `max(0, after_days_seconds_of_next - elapsed)`.
    * Past-last-step (elapsed > last `after_days`) → `:done`.
    * Determinism — same inputs yield byte-identical output.

  Plus edge-case unit assertions: single-step list, at-exact-boundary
  (elapsed == an `after_days` boundary in seconds), and empty list → `:done`.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Dunning.Campaign

  @seconds_per_day 86_400

  # --- generators ------------------------------------------------------------

  # A strictly-increasing, unique list of absolute `after_days` offsets.
  # Generate a set of non-negative day offsets, sort+dedup them, then wrap
  # each into the [after_days:, key:, template:] step contract from Plan 01.
  defp steps_gen do
    StreamData.list_of(StreamData.integer(0..60), min_length: 1, max_length: 6)
    |> StreamData.map(fn days ->
      days
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.with_index()
      |> Enum.map(fn {after_days, idx} ->
        [
          after_days: after_days,
          key: :"step_#{idx}",
          template: :"Elixir.Accrue.Emails.Step#{idx}"
        ]
      end)
    end)
  end

  # A non-empty step list whose first offset is exactly 0, so day-0
  # immediate semantics are always exercisable.
  defp steps_starting_at_zero_gen do
    StreamData.list_of(StreamData.integer(1..60), min_length: 0, max_length: 5)
    |> StreamData.map(fn rest ->
      [0 | rest]
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.with_index()
      |> Enum.map(fn {after_days, idx} ->
        [after_days: after_days, key: :"step_#{idx}", template: :"Elixir.Step#{idx}"]
      end)
    end)
  end

  # A base anchor timestamp; offsets are applied relative to it.
  defp anchor_gen do
    StreamData.integer(0..2_000_000_000)
    |> StreamData.map(fn unix -> DateTime.from_unix!(unix) end)
  end

  # Elapsed seconds since the anchor — covers before-first, between, and
  # past-last by spanning 0 .. (62 days in seconds).
  defp elapsed_seconds_gen do
    StreamData.integer(0..(62 * @seconds_per_day))
  end

  defp last_after_days(steps), do: steps |> List.last() |> Keyword.fetch!(:after_days)

  # The expected next step under the resolver's contract, computed
  # independently of the implementation (the oracle).
  defp expected_next(steps, elapsed) do
    Enum.find(steps, fn step -> Keyword.fetch!(step, :after_days) * @seconds_per_day > elapsed end)
  end

  # --- properties ------------------------------------------------------------

  property "day-0 (now == campaign_started_at) returns first step with schedule_in 0" do
    check all(
            steps <- steps_starting_at_zero_gen(),
            anchor <- anchor_gen(),
            max_runs: 200
          ) do
      [first | _] = steps
      assert {:next, ^first, 0} = Campaign.next_step(steps, anchor, anchor)
    end
  end

  property "schedule_in is non-negative and equals max(0, next_after_days_seconds - elapsed)" do
    check all(
            steps <- steps_gen(),
            anchor <- anchor_gen(),
            elapsed <- elapsed_seconds_gen(),
            max_runs: 200
          ) do
      now = DateTime.add(anchor, elapsed, :second)

      case Campaign.next_step(steps, anchor, now) do
        {:next, step, schedule_in} ->
          after_days_seconds = Keyword.fetch!(step, :after_days) * @seconds_per_day
          assert schedule_in >= 0
          assert schedule_in == max(0, after_days_seconds - elapsed)
          # And the returned step matches the independent oracle.
          assert step == expected_next(steps, elapsed)

        :done ->
          # Resolver said done — the oracle must agree there is no next step.
          assert expected_next(steps, elapsed) == nil
      end
    end
  end

  property "past-last-step (elapsed > last after_days seconds) returns :done" do
    check all(
            steps <- steps_gen(),
            anchor <- anchor_gen(),
            extra <- StreamData.integer(1..(5 * @seconds_per_day)),
            max_runs: 200
          ) do
      elapsed = last_after_days(steps) * @seconds_per_day + extra
      now = DateTime.add(anchor, elapsed, :second)
      assert Campaign.next_step(steps, anchor, now) == :done
    end
  end

  property "next_step/3 is deterministic (same inputs -> same output)" do
    check all(
            steps <- steps_gen(),
            anchor <- anchor_gen(),
            elapsed <- elapsed_seconds_gen(),
            max_runs: 200
          ) do
      now = DateTime.add(anchor, elapsed, :second)
      assert Campaign.next_step(steps, anchor, now) == Campaign.next_step(steps, anchor, now)
    end
  end

  # --- edge-case unit tests --------------------------------------------------

  test "empty step list returns :done" do
    now = DateTime.utc_now()
    assert Campaign.next_step([], now, now) == :done
  end

  test "single-step list: before boundary returns the step, after returns :done" do
    anchor = ~U[2026-01-01 00:00:00Z]
    step = [after_days: 3, key: :only, template: :"Elixir.Only"]
    steps = [step]

    # Day 0 — step is in the future, schedule_in == 3 days.
    assert {:next, ^step, schedule_in} = Campaign.next_step(steps, anchor, anchor)
    assert schedule_in == 3 * @seconds_per_day

    # One second past the boundary — exhausted.
    past = DateTime.add(anchor, 3 * @seconds_per_day + 1, :second)
    assert Campaign.next_step(steps, anchor, past) == :done
  end

  test "at-exact-boundary (elapsed == after_days seconds) advances past that step" do
    anchor = ~U[2026-01-01 00:00:00Z]
    steps = [
      [after_days: 0, key: :s0, template: :"Elixir.S0"],
      [after_days: 5, key: :s5, template: :"Elixir.S5"],
      [after_days: 12, key: :s12, template: :"Elixir.S12"]
    ]

    # Exactly at day 5: the 5-day step is NOT in the future (strict >),
    # so the resolver returns the next one (day 12) with schedule_in 7 days.
    now = DateTime.add(anchor, 5 * @seconds_per_day, :second)
    assert {:next, step, schedule_in} = Campaign.next_step(steps, anchor, now)
    assert Keyword.fetch!(step, :key) == :s12
    assert schedule_in == 7 * @seconds_per_day

    # Exactly at day 0: day-0 step is not strictly in the future either,
    # so day-5 is next, due in 5 days.
    assert {:next, day5, day5_delay} = Campaign.next_step(steps, anchor, anchor)
    assert Keyword.fetch!(day5, :key) == :s5
    assert day5_delay == 5 * @seconds_per_day
  end

  test "default [0,5,12] journey resolves the expected step at each phase" do
    anchor = ~U[2026-01-01 00:00:00Z]
    steps = [
      [after_days: 0, key: :reminder, template: :"Elixir.Accrue.Emails.InvoicePaymentFailed"],
      [after_days: 5, key: :action_required, template: :"Elixir.Accrue.Emails.DunningActionRequired"],
      [after_days: 12, key: :final_notice, template: :"Elixir.Accrue.Emails.DunningFinalNotice"]
    ]

    # Between day 0 and day 5 -> next is the day-5 step.
    mid = DateTime.add(anchor, 2 * @seconds_per_day, :second)
    assert {:next, s, delay} = Campaign.next_step(steps, anchor, mid)
    assert Keyword.fetch!(s, :key) == :action_required
    assert delay == 3 * @seconds_per_day

    # Just past day 12 -> exhausted.
    after_last = DateTime.add(anchor, 12 * @seconds_per_day + 1, :second)
    assert Campaign.next_step(steps, anchor, after_last) == :done
  end
end
