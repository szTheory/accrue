defmodule Accrue.Billing.SubscriptionTest do
  @moduledoc """
  Plan 04 headline: `Accrue.Billing.subscribe/2..3` creates a trialing
  subscription against the Fake processor, auto-preloads items,
  surfaces SCA/3DS via `{:ok, :requires_action, pi}`, and supports the
  dual API (`subscribe!/3` raises on requires_action).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_test",
        email: "sub-test@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "subscribe/2 with bare price_id creates trialing subscription", %{customer: cus} do
    assert {:ok, sub} = Billing.subscribe(cus, "price_basic", trial_end: {:days, 14})
    assert sub.status == :trialing
    assert sub.processor_id =~ ~r/^sub_fake_/
    assert length(sub.subscription_items) == 1
    [item] = sub.subscription_items
    assert item.price_id == "price_basic"
  end

  test "subscribe/2 with {price_id, quantity} tuple sets quantity", %{customer: cus} do
    assert {:ok, sub} = Billing.subscribe(cus, {"price_seats", 5}, trial_end: :now)
    assert hd(sub.subscription_items).quantity == 5
  end

  test "subscribe/2 with list raises ArgumentError", %{customer: cus} do
    assert_raise ArgumentError, ~r/single price_id/, fn ->
      Billing.subscribe(cus, ["price_a", "price_b"])
    end
  end

  test "subscribe/2 returns intent_result on requires_action", %{customer: cus} do
    fake_sub = %{
      id: "sub_fake_scripted",
      object: "subscription",
      customer: cus.processor_id,
      status: :incomplete,
      cancel_at_period_end: false,
      pause_collection: nil,
      current_period_start: DateTime.to_unix(Accrue.Clock.utc_now()),
      current_period_end: DateTime.to_unix(DateTime.add(Accrue.Clock.utc_now(), 30, :day)),
      trial_start: nil,
      trial_end: nil,
      metadata: %{},
      items: %{
        object: "list",
        data: [
          %{
            id: "si_fake_scripted",
            object: "subscription_item",
            price: %{id: "price_basic", product: "prod_basic"},
            quantity: 1
          }
        ]
      },
      latest_invoice: %{
        id: "in_fake_scripted",
        object: "invoice",
        status: :open,
        payment_intent: %{
          id: "pi_fake_scripted",
          object: "payment_intent",
          status: "requires_action",
          client_secret: "pi_fake_scripted_secret",
          next_action: %{type: "use_stripe_sdk"}
        }
      }
    }

    Fake.scripted_response(:create_subscription, {:ok, fake_sub})

    assert {:ok, :requires_action, pi} = Billing.subscribe(cus, "price_basic")
    assert pi[:status] == "requires_action" or pi["status"] == "requires_action"
  end

  test "subscribe!/2 raises Accrue.ActionRequiredError on requires_action", %{customer: cus} do
    fake_sub = %{
      id: "sub_fake_scripted2",
      object: "subscription",
      customer: cus.processor_id,
      status: :incomplete,
      cancel_at_period_end: false,
      pause_collection: nil,
      current_period_start: DateTime.to_unix(Accrue.Clock.utc_now()),
      current_period_end: DateTime.to_unix(DateTime.add(Accrue.Clock.utc_now(), 30, :day)),
      trial_start: nil,
      trial_end: nil,
      metadata: %{},
      items: %{
        object: "list",
        data: [
          %{
            id: "si_fake_scripted2",
            object: "subscription_item",
            price: %{id: "price_basic", product: "prod_basic"},
            quantity: 1
          }
        ]
      },
      latest_invoice: %{
        id: "in_fake_scripted2",
        object: "invoice",
        status: :open,
        payment_intent: %{
          id: "pi_fake_scripted2",
          object: "payment_intent",
          status: "requires_action",
          client_secret: "pi_fake_scripted2_secret",
          next_action: %{type: "use_stripe_sdk"}
        }
      }
    }

    Fake.scripted_response(:create_subscription, {:ok, fake_sub})

    assert_raise Accrue.ActionRequiredError, fn ->
      Billing.subscribe!(cus, "price_basic")
    end
  end

  test "subscribe/2 raises ArgumentError when trial_end is a unix int", %{customer: cus} do
    assert_raise ArgumentError, ~r/unix ints rejected/, fn ->
      Billing.subscribe(cus, "price_basic", trial_end: 1_800_000_000)
    end
  end

  test "get_subscription/1 auto-preloads items", %{customer: cus} do
    {:ok, sub} = Billing.subscribe(cus, "price_basic")
    {:ok, fetched} = Billing.get_subscription(sub.id)
    assert is_list(fetched.subscription_items)
    assert length(fetched.subscription_items) == 1
  end

  test "get_subscription/2 with preload: false skips items", %{customer: cus} do
    {:ok, sub} = Billing.subscribe(cus, "price_basic")
    {:ok, fetched} = Billing.get_subscription(sub.id, preload: false)
    assert match?(%Ecto.Association.NotLoaded{}, fetched.subscription_items)
  end

  test "every subscribe/2 emits a subscription.created event row", %{customer: cus} do
    {:ok, sub} = Billing.subscribe(cus, "price_basic")

    event_count =
      Repo.one(
        from(e in Accrue.Events.Event,
          where: e.type == "subscription.created" and e.subject_id == ^sub.id,
          select: count(e.id)
        )
      )

    assert event_count == 1
  end
end
