defmodule Accrue.Test.FactoryTest do
  @moduledoc """
  Plan 03-08 Task 1: first-class factories for every subscription state
  (D3-79..85). All factories route through `Accrue.Processor.Fake`, derive
  timestamps from `Accrue.Clock.utc_now/0`, and are safe to call from the
  `:dev` env via `mix accrue.seed` (Phase 8).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Test.Factory
  alias Accrue.Billing.Subscription

  test "customer/1 creates customer via Fake" do
    %{customer: c} = Factory.customer()
    assert c.id
    assert c.processor_id =~ ~r/^cus_fake_/
    assert c.processor == "fake"
  end

  test "customer/1 accepts owner_id override" do
    owner_id = Ecto.UUID.generate()
    %{customer: c, owner_id: ^owner_id} = Factory.customer(%{owner_id: owner_id})
    assert c.owner_id == owner_id
  end

  test "trialing_subscription/1 returns trialing sub with items" do
    %{subscription: s, items: items} = Factory.trialing_subscription()
    assert s.status == :trialing
    assert Subscription.trialing?(s)
    assert length(items) == 1
    assert s.processor_id =~ ~r/^sub_fake_/
  end

  test "active_subscription/1 returns active sub" do
    %{subscription: s} = Factory.active_subscription()
    assert s.status == :active
    assert Subscription.active?(s)
  end

  test "past_due_subscription/1 returns past_due sub" do
    %{subscription: s} = Factory.past_due_subscription()
    assert s.status == :past_due
    assert Subscription.past_due?(s)
  end

  test "incomplete_subscription/1 returns incomplete sub" do
    %{subscription: s} = Factory.incomplete_subscription()
    assert s.status == :incomplete
    refute Subscription.active?(s)
  end

  test "canceled_subscription/1 returns canceled sub" do
    %{subscription: s} = Factory.canceled_subscription()
    assert Subscription.canceled?(s)
  end

  test "canceling_subscription/1 passes canceling?/1 predicate" do
    %{subscription: s} = Factory.canceling_subscription()
    assert s.cancel_at_period_end == true
    assert Subscription.active?(s)
    refute Subscription.canceled?(s)
    assert Subscription.canceling?(s)
  end

  test "grace_period_subscription/1 is canceled with future current_period_end" do
    %{subscription: s} = Factory.grace_period_subscription()
    assert Subscription.canceled?(s)
    assert DateTime.compare(s.current_period_end, Accrue.Clock.utc_now()) == :gt
  end

  test "trial_ending_subscription/1 has trial_end within 72h" do
    %{subscription: s} = Factory.trial_ending_subscription()
    assert s.status == :trialing
    diff = DateTime.diff(s.trial_end, Accrue.Clock.utc_now(), :second)
    assert diff < 3 * 86_400
    assert diff > 0
  end

  test "factories derive timestamps from Accrue.Clock (test-clock-safe)" do
    before_now = Accrue.Clock.utc_now()
    :ok = Accrue.Processor.Fake.advance(5 * 86_400)
    after_now = Accrue.Clock.utc_now()
    assert DateTime.compare(after_now, before_now) == :gt

    %{subscription: s} = Factory.trialing_subscription()
    # trial_end should be ~14 days from the advanced clock, i.e. > 13d from now.
    expected_min = DateTime.add(after_now, 13 * 86_400, :second)
    assert DateTime.compare(s.trial_end, expected_min) == :gt
  end

  test "100 concurrent trialing_subscription calls have unique IDs (D3-85)" do
    parent = self()

    tasks =
      for _ <- 1..100 do
        Task.async(fn ->
          # BillingCase runs with shared: true when async: false, so child
          # processes inherit the owner connection automatically.
          Ecto.Adapters.SQL.Sandbox.allow(Accrue.TestRepo, parent, self())
          Factory.trialing_subscription()
        end)
      end

    results = Task.await_many(tasks, 30_000)
    ids = Enum.map(results, & &1.subscription.id)
    assert length(Enum.uniq(ids)) == 100

    processor_ids = Enum.map(results, & &1.subscription.processor_id)
    assert length(Enum.uniq(processor_ids)) == 100
  end
end
