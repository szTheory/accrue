defmodule Accrue.Entitlements.PastDueGraceTest do
  @moduledoc """
  Unit tests for the pure, clock-driven `within_grace?/2` helper (ENT-09,
  D-17). Drives `Accrue.Clock` via the Fake test clock so the grace-window
  math is deterministic — never wall-clock.

  Fail-closed contract: a nil `past_due_since`, a non-positive `grace_days`,
  or a non-DateTime `past_due_since` all resolve to `false`. The only path to
  `true` is an in-window `past_due_since` measured from `Accrue.Clock.utc_now/0`.
  """

  use ExUnit.Case, async: false

  alias Accrue.Entitlements.PastDueGrace

  setup do
    prior_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :test)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    on_exit(fn ->
      if prior_env do
        Application.put_env(:accrue, :env, prior_env)
      else
        Application.delete_env(:accrue, :env)
      end
    end)

    :ok
  end

  describe "within_grace?/2 fail-closed heads" do
    test "nil past_due_since returns false" do
      refute PastDueGrace.within_grace?(%{past_due_since: nil}, 14)
    end

    test "missing past_due_since key returns false (catch-all)" do
      refute PastDueGrace.within_grace?(%{}, 14)
    end

    test "non-DateTime past_due_since returns false (catch-all)" do
      refute PastDueGrace.within_grace?(%{past_due_since: "not-a-datetime"}, 14)
    end

    test "non-positive grace_days returns false" do
      since = DateTime.add(Accrue.Clock.utc_now(), -1 * 86_400, :second)
      refute PastDueGrace.within_grace?(%{past_due_since: since}, 0)
      refute PastDueGrace.within_grace?(%{past_due_since: since}, -3)
    end
  end

  describe "within_grace?/2 window (clock-driven)" do
    test "past_due_since within the window returns true" do
      # 1 day ago, 14-day window -> still inside.
      since = DateTime.add(Accrue.Clock.utc_now(), -1 * 86_400, :second)
      assert PastDueGrace.within_grace?(%{past_due_since: since}, 14)
    end

    test "past_due_since beyond the window returns false" do
      # 30 days ago, 14-day window -> lapsed.
      since = DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second)
      refute PastDueGrace.within_grace?(%{past_due_since: since}, 14)
    end

    test "exactly at the cutoff is still in-window (since >= cutoff)" do
      # past_due_since == now - grace_days*86_400 == cutoff -> :eq, not :lt -> true.
      since = DateTime.add(Accrue.Clock.utc_now(), -14 * 86_400, :second)
      assert PastDueGrace.within_grace?(%{past_due_since: since}, 14)
    end

    test "advancing the fake clock past the window flips a previously-in-window row to false" do
      since = DateTime.add(Accrue.Clock.utc_now(), -10 * 86_400, :second)
      assert PastDueGrace.within_grace?(%{past_due_since: since}, 14)

      # Advance the clock by 10 more days -> since is now 20 days old, beyond 14.
      :ok = Accrue.Processor.Fake.advance(10 * 86_400)
      refute PastDueGrace.within_grace?(%{past_due_since: since}, 14)
    end
  end
end
