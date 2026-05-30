defmodule Accrue.Billing.SubscriptionPredicatesTest do
  @moduledoc """
  Unit tests for the BILL-05 canonical subscription predicates. Every
  predicate in this file is the single source of truth for "is this
  subscription X?". Raw `.status == :active` access is banned elsewhere
  (enforced by Accrue.Credo.NoRawStatusAccess).
  """
  use ExUnit.Case, async: false

  alias Accrue.Billing.Subscription

  setup do
    Application.put_env(:accrue, :env, :test)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    :ok
  end

  test "active? true for :active and :trialing" do
    assert Subscription.active?(%Subscription{status: :active})
    assert Subscription.active?(%Subscription{status: :trialing})
    refute Subscription.active?(%Subscription{status: :past_due})
    refute Subscription.active?(%Subscription{status: :canceled})
    refute Subscription.active?(%Subscription{status: :incomplete})
  end

  test "trialing? narrow" do
    assert Subscription.trialing?(%Subscription{status: :trialing})
    refute Subscription.trialing?(%Subscription{status: :active})
  end

  test "canceled? true for :canceled, :incomplete_expired, and any ended_at" do
    assert Subscription.canceled?(%Subscription{status: :canceled})
    assert Subscription.canceled?(%Subscription{status: :incomplete_expired})
    assert Subscription.canceled?(%Subscription{ended_at: ~U[2026-01-01 00:00:00.000000Z]})
    refute Subscription.canceled?(%Subscription{status: :active})
  end

  test "canceling? requires status=:active + cancel_at_period_end + future period end" do
    now = Accrue.Clock.utc_now()
    future = DateTime.add(now, 7, :day)
    past = DateTime.add(now, -1, :day)

    assert Subscription.canceling?(%Subscription{
             status: :active,
             cancel_at_period_end: true,
             current_period_end: future
           })

    refute Subscription.canceling?(%Subscription{
             status: :active,
             cancel_at_period_end: true,
             current_period_end: past
           })

    refute Subscription.canceling?(%Subscription{
             status: :active,
             cancel_at_period_end: false,
             current_period_end: future
           })

    refute Subscription.canceling?(%Subscription{
             status: :canceled,
             cancel_at_period_end: true,
             current_period_end: future
           })
  end

  test "paused? true for legacy :paused and non-nil pause_collection" do
    assert Subscription.paused?(%Subscription{status: :paused})
    assert Subscription.paused?(%Subscription{pause_collection: %{"behavior" => "void"}})
    refute Subscription.paused?(%Subscription{status: :active, pause_collection: nil})
  end

  test "past_due? true for :past_due and :unpaid" do
    assert Subscription.past_due?(%Subscription{status: :past_due})
    assert Subscription.past_due?(%Subscription{status: :unpaid})
    refute Subscription.past_due?(%Subscription{status: :active})
  end

  # Lifecycle -> entitlement truth-table pin (D-12/D-14). entitling?/1 is the
  # single source of truth for which pure-lifecycle states grant entitlement;
  # this enumerates every status in @statuses plus the pause/ended/cancel
  # modifiers and pins the exact truth from guides/lifecycle_semantics.md.
  # The two gap rows the table flags (pause_collection-on-active and
  # ended_at-on-active) are merge-blocking refutes.
  test "entitling?/1 truth table over all statuses and modifiers" do
    now = Accrue.Clock.utc_now()
    future = DateTime.add(now, 7, :day)
    past = DateTime.add(now, -1, :day)

    # ✅ entitling lifecycle states
    assert Subscription.entitling?(%Subscription{status: :trialing})
    assert Subscription.entitling?(%Subscription{status: :active})

    assert Subscription.entitling?(%Subscription{
             status: :active,
             cancel_at_period_end: true,
             current_period_end: future
           })

    # ✗ paused fail-open gap: status:active + non-nil pause_collection (D-11)
    refute Subscription.entitling?(%Subscription{
             status: :active,
             pause_collection: %{"behavior" => "void"}
           })

    # ✗ terminal override: status:active + non-nil ended_at (WR-04)
    refute Subscription.entitling?(%Subscription{status: :active, ended_at: past})

    # ✗ remaining non-entitling statuses
    refute Subscription.entitling?(%Subscription{status: :paused})
    refute Subscription.entitling?(%Subscription{status: :past_due})
    refute Subscription.entitling?(%Subscription{status: :unpaid})
    refute Subscription.entitling?(%Subscription{status: :canceled})
    refute Subscription.entitling?(%Subscription{status: :incomplete})
    refute Subscription.entitling?(%Subscription{status: :incomplete_expired})

    # Coverage guard: every status in @statuses is exercised above.
    exercised =
      MapSet.new([
        :trialing,
        :active,
        :paused,
        :past_due,
        :unpaid,
        :canceled,
        :incomplete,
        :incomplete_expired
      ])

    assert MapSet.equal?(MapSet.new(Subscription.statuses()), exercised)
  end
end
