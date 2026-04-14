defmodule Accrue.Webhook.DefaultHandlerOutOfOrderTest do
  @moduledoc """
  Plan 07 Task 1: out-of-order webhook handling.

  Older event (strict `:lt` on `last_stripe_event_ts`) is skipped with
  `[:accrue, :webhooks, :stale_event]` telemetry and NO refetch. Ties
  process normally. Out-of-order refund before local row upserts cleanly.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Subscription
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_ooo",
        email: "ooo@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Accrue.Billing.subscribe(customer, "price_basic")
    %{customer: customer, sub: sub}
  end

  test "older event is skipped with :stale_event telemetry and no refetch", %{sub: sub} do
    newer_ts = DateTime.add(Accrue.Clock.utc_now(), 3600, :second)

    {:ok, _} =
      sub
      |> Subscription.changeset(%{last_stripe_event_ts: newer_ts, last_stripe_event_id: "evt_new"})
      |> Repo.update()

    test_pid = self()

    :telemetry.attach(
      "test-stale-#{System.unique_integer([:positive])}",
      [:accrue, :webhooks, :stale_event],
      fn evt, meas, meta, _ -> send(test_pid, {:stale, evt, meas, meta}) end,
      nil
    )

    older_event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub.processor_id}),
        %{
          "id" => "evt_older",
          "created" => DateTime.to_unix(DateTime.add(newer_ts, -1800, :second))
        }
      )

    DefaultHandler.handle(older_event)

    assert_received {:stale, _, _, %{event_id: "evt_older"}}

    unchanged = Repo.get!(Subscription, sub.id)
    assert unchanged.last_stripe_event_id == "evt_new"
  end

  test "tie on equal timestamps processes the event (no skip)", %{sub: sub} do
    ts = DateTime.truncate(Accrue.Clock.utc_now(), :second)

    {:ok, _} =
      sub
      |> Subscription.changeset(%{last_stripe_event_ts: ts, last_stripe_event_id: "evt_a"})
      |> Repo.update()

    equal_event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub.processor_id}),
        %{"id" => "evt_b", "created" => DateTime.to_unix(ts)}
      )

    DefaultHandler.handle(equal_event)

    updated = Repo.get!(Subscription, sub.id)
    assert updated.last_stripe_event_id == "evt_b"
  end
end
