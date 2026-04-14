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
      check all grace_days <- integer(1..365),
                extra_days <- integer(1..30) do
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
      check all grace_days <- integer(2..365),
                inside_days <- integer(0..(grace_days - 1)) do
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
