defmodule Accrue.Billing.DunningTest do
  @moduledoc """
  Phase 4 Plan 04 — BILL-15 dunning (D4-02). Pure policy module tests
  for `Accrue.Billing.Dunning.compute_terminal_action/2` and
  `grace_elapsed?/3`. No DB, no Stripe, no telemetry — this is the
  side-effect-free core that `Accrue.Jobs.DunningSweeper` asks about
  each candidate row.
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Billing.Dunning
  alias Accrue.Billing.Subscription

  @base_policy [
    mode: :stripe_smart_retries,
    grace_days: 14,
    terminal_action: :unpaid,
    telemetry_prefix: [:accrue, :ops]
  ]

  defp sub(attrs), do: struct(%Subscription{}, attrs)

  defp days_ago(days) do
    DateTime.add(DateTime.utc_now(), -days * 86_400, :second)
  end

  describe "compute_terminal_action/2" do
    test "active subscription returns :skip" do
      assert Dunning.compute_terminal_action(sub(status: :active), @base_policy) == :skip
    end

    test "past_due within grace window returns :hold" do
      s = sub(status: :past_due, past_due_since: days_ago(10))
      assert Dunning.compute_terminal_action(s, @base_policy) == :hold
    end

    test "past_due outside grace with nil sweep_attempted_at returns {:sweep, terminal}" do
      s = sub(status: :past_due, past_due_since: days_ago(20), dunning_sweep_attempted_at: nil)

      assert Dunning.compute_terminal_action(s, @base_policy) == {:sweep, :unpaid}

      assert Dunning.compute_terminal_action(
               s,
               Keyword.put(@base_policy, :terminal_action, :canceled)
             ) == {:sweep, :canceled}
    end

    test "past_due outside grace but already swept returns :skip" do
      s =
        sub(
          status: :past_due,
          past_due_since: days_ago(20),
          dunning_sweep_attempted_at: DateTime.add(DateTime.utc_now(), -3600, :second)
        )

      assert Dunning.compute_terminal_action(s, @base_policy) == :skip
    end

    test "disabled mode always returns :skip even when otherwise sweepable" do
      s = sub(status: :past_due, past_due_since: days_ago(40))
      policy = Keyword.put(@base_policy, :mode, :disabled)
      assert Dunning.compute_terminal_action(s, policy) == :skip
    end

    test "past_due with nil past_due_since (never recorded) returns :hold" do
      s = sub(status: :past_due, past_due_since: nil)
      assert Dunning.compute_terminal_action(s, @base_policy) == :hold
    end
  end

  describe "grace_elapsed?/3" do
    test "nil past_due_since returns false" do
      refute Dunning.grace_elapsed?(nil, 14, DateTime.utc_now())
    end

    test "past_due_since younger than grace returns false" do
      refute Dunning.grace_elapsed?(days_ago(5), 14, DateTime.utc_now())
    end

    test "past_due_since older than grace returns true" do
      assert Dunning.grace_elapsed?(days_ago(30), 14, DateTime.utc_now())
    end
  end

  describe "property: grace window" do
    property "past_due older than grace_days with nil sweep_attempted yields {:sweep, _}" do
      check all(
              grace_days <- integer(1..365),
              extra_days <- integer(1..30)
            ) do
        past_due_since = days_ago(grace_days + extra_days)

        s =
          sub(
            status: :past_due,
            past_due_since: past_due_since,
            dunning_sweep_attempted_at: nil
          )

        policy = Keyword.put(@base_policy, :grace_days, grace_days)

        assert {:sweep, :unpaid} = Dunning.compute_terminal_action(s, policy)
      end
    end

    property "past_due younger than grace_days always yields :hold" do
      check all(
              grace_days <- integer(2..365),
              inside_days <- integer(0..(grace_days - 1))
            ) do
        past_due_since = days_ago(inside_days)

        s =
          sub(
            status: :past_due,
            past_due_since: past_due_since,
            dunning_sweep_attempted_at: nil
          )

        policy = Keyword.put(@base_policy, :grace_days, grace_days)

        assert Dunning.compute_terminal_action(s, policy) == :hold
      end
    end
  end
end

defmodule Accrue.Billing.DunningCounterTest do
  @moduledoc """
  Phase 129 Plan 02 — DUN-08 SC#4 recovered-vs-lost ledger counter.

  Exercises `Accrue.Billing.Dunning.recovered_vs_lost/1`, the flat fold
  over `accrue_events` that answers "how much past-due revenue did
  dunning recover vs. lose to terminal action?" by counting the two
  confirmed-transition ledger types from Plan 01:

    * `dunning.recovered`  -> recovered
    * `dunning.exhausted`  -> lost

  The sweeper's request-time `dunning.terminal_action_requested` is
  STRUCTURALLY EXCLUDED (D-06): it is request-time intent that may exist
  with no campaign, so it must never inflate "lost".

  DB-backed (the counter is a real Ecto read against the ledger), so this
  lives in its own `Accrue.RepoCase` module rather than the pure
  `Accrue.Billing.DunningTest` above. Events are inserted directly with an
  explicit `inserted_at` (mirroring `Accrue.Events.QueryAPITest`) because a
  sandboxed transaction freezes Postgres `now()` to the txn start time.
  """
  use Accrue.RepoCase
  use ExUnitProperties

  alias Accrue.Billing.Dunning
  alias Accrue.Events.Event

  @recovered "dunning.recovered"
  @exhausted "dunning.exhausted"
  # Sweeper request-time intent — must NEVER be counted (D-06).
  @terminal_requested "dunning.terminal_action_requested"

  setup do
    {:ok, base_ts: ~U[2026-05-01 12:00:00.000000Z]}
  end

  describe "recovered_vs_lost/1" do
    test "counts dunning.recovered as recovered and dunning.exhausted as lost", %{base_ts: t0} do
      for _ <- 1..3, do: insert_event!(@recovered, t0)
      for _ <- 1..2, do: insert_event!(@exhausted, t0)

      assert Dunning.recovered_vs_lost() == %{recovered: 3, lost: 2}
    end

    test "returns zeros when the ledger has no dunning lifecycle events" do
      assert Dunning.recovered_vs_lost() == %{recovered: 0, lost: 0}
    end

    test "never counts the sweeper's request-time terminal_action_requested", %{base_ts: t0} do
      insert_event!(@recovered, t0)
      insert_event!(@exhausted, t0)
      # A terminal-action REQUEST exists but no exhaustion confirmed it.
      for _ <- 1..5, do: insert_event!(@terminal_requested, t0)

      assert Dunning.recovered_vs_lost() == %{recovered: 1, lost: 1}
    end

    test "honors the since:/until: %DateTime{} window via parameterized Ecto", %{base_ts: t0} do
      before = DateTime.add(t0, -1, :day)
      inside1 = DateTime.add(t0, 1, :day)
      inside2 = DateTime.add(t0, 2, :day)
      later = DateTime.add(t0, 10, :day)

      # Out of window (too early / too late) — excluded.
      insert_event!(@recovered, before)
      insert_event!(@exhausted, later)
      # In window.
      insert_event!(@recovered, inside1)
      insert_event!(@recovered, inside2)
      insert_event!(@exhausted, inside1)

      result =
        Dunning.recovered_vs_lost(
          since: t0,
          until: DateTime.add(t0, 3, :day)
        )

      assert result == %{recovered: 2, lost: 1}
    end

    test "since: lower bound is inclusive", %{base_ts: t0} do
      insert_event!(@recovered, t0)
      assert Dunning.recovered_vs_lost(since: t0) == %{recovered: 1, lost: 0}
    end

    test "until: upper bound is inclusive", %{base_ts: t0} do
      insert_event!(@exhausted, t0)
      assert Dunning.recovered_vs_lost(until: t0) == %{recovered: 0, lost: 1}
    end
  end

  describe "property: type-filter invariant" do
    property "recovered == count(recovered) and lost == count(exhausted) regardless of noise",
             %{base_ts: t0} do
      check all(
              recovered_n <- integer(0..8),
              exhausted_n <- integer(0..8),
              requested_n <- integer(0..8)
            ) do
        # Fresh sandbox per check iteration isn't automatic; scope each
        # generated trial to a unique subject + window so prior trials
        # cannot leak into this trial's count.
        sid = Ecto.UUID.generate()

        for _ <- safe_range(recovered_n), do: insert_event!(@recovered, t0, sid)
        for _ <- safe_range(exhausted_n), do: insert_event!(@exhausted, t0, sid)
        for _ <- safe_range(requested_n), do: insert_event!(@terminal_requested, t0, sid)

        # Window is the whole-of-time; counts are global so we assert the
        # DELTA contributed by THIS trial via direct scoped queries.
        recovered = scoped_count(@recovered, sid)
        exhausted = scoped_count(@exhausted, sid)

        assert recovered == recovered_n
        assert exhausted == exhausted_n
        # The terminal_action_requested rows exist but the global counter
        # must never let them inflate "lost": global lost == global exhausted.
        global = Dunning.recovered_vs_lost()
        assert global.lost == scoped_count_all(@exhausted)
        assert global.recovered == scoped_count_all(@recovered)
      end
    end
  end

  # --- helpers ----------------------------------------------------------

  defp safe_range(0), do: []
  defp safe_range(n) when n > 0, do: 1..n

  defp insert_event!(type, ts, subject_id \\ Ecto.UUID.generate()) do
    %Event{}
    |> Ecto.Changeset.change(%{
      type: type,
      schema_version: 1,
      actor_type: "system",
      subject_type: "Subscription",
      subject_id: subject_id,
      data: %{},
      inserted_at: ts
    })
    |> Accrue.TestRepo.insert!()
  end

  defp scoped_count(type, subject_id) do
    import Ecto.Query

    Accrue.TestRepo.aggregate(
      from(e in Event, where: e.type == ^type and e.subject_id == ^subject_id),
      :count,
      :id
    )
  end

  defp scoped_count_all(type) do
    import Ecto.Query
    Accrue.TestRepo.aggregate(from(e in Event, where: e.type == ^type), :count, :id)
  end
end
