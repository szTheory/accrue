defmodule Accrue.Billing.SubscriptionStateMachineTest do
  @moduledoc """
  D3-04 subscription status transitions using `Fake.transition/3`.
  These tests bypass the webhook reconcile path (Plan 07) and mutate
  status directly via Fake + SubscriptionProjection so the predicate
  layer is exercised without pulling in the DispatchWorker.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.SubscriptionProjection

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_sm",
        email: "sm@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    %{customer: customer, sub: sub}
  end

  defp reproject(sub) do
    {:ok, stripe_sub} = Fake.retrieve_subscription(sub.processor_id, [])
    {:ok, attrs} = SubscriptionProjection.decompose(stripe_sub)

    {:ok, updated} =
      sub
      |> Subscription.changeset(attrs)
      |> Repo.update()

    updated
  end

  test "trialing → active via Fake.advance_subscription trial crossing", %{sub: sub} do
    # Start by planting a trialing subscription.
    {:ok, _} = Fake.transition(sub.processor_id, :trialing, synthesize_webhooks: false)

    updated = reproject(sub)
    assert Subscription.trialing?(updated)
  end

  test "active → past_due via Fake.transition", %{sub: sub} do
    {:ok, _} = Fake.transition(sub.processor_id, :past_due, synthesize_webhooks: false)
    updated = reproject(sub)
    assert Subscription.past_due?(updated)
    refute Subscription.active?(updated)
  end

  test "past_due → active via Fake.transition", %{sub: sub} do
    {:ok, _} = Fake.transition(sub.processor_id, :past_due, synthesize_webhooks: false)
    {:ok, _} = Fake.transition(sub.processor_id, :active, synthesize_webhooks: false)
    updated = reproject(sub)
    assert Subscription.active?(updated)
    refute Subscription.past_due?(updated)
  end

  test "past_due → unpaid via Fake.transition", %{sub: sub} do
    {:ok, _} = Fake.transition(sub.processor_id, :unpaid, synthesize_webhooks: false)
    updated = reproject(sub)
    assert Subscription.past_due?(updated)
  end

  test "active → canceled via Billing.cancel/2", %{sub: sub} do
    assert {:ok, canceled} = Billing.cancel(sub)
    assert Subscription.canceled?(canceled)
  end

  test "incomplete → active via Fake.transition", %{sub: sub} do
    {:ok, _} = Fake.transition(sub.processor_id, :incomplete, synthesize_webhooks: false)
    incomplete = reproject(sub)
    refute Subscription.active?(incomplete)

    {:ok, _} = Fake.transition(sub.processor_id, :active, synthesize_webhooks: false)
    active = reproject(incomplete)
    assert Subscription.active?(active)
  end

  test "incomplete → incomplete_expired via Fake.transition", %{sub: sub} do
    {:ok, _} = Fake.transition(sub.processor_id, :incomplete, synthesize_webhooks: false)
    {:ok, _} = Fake.transition(sub.processor_id, :incomplete_expired, synthesize_webhooks: false)
    updated = reproject(sub)
    assert Subscription.canceled?(updated)
  end
end
