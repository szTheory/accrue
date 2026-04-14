defmodule Accrue.Billing.Charge3DSTest do
  @moduledoc """
  Quick task 260414-l9q: Fake-asserted correctness test for Phase 3
  HUMAN-UAT Item 1 (3DS charge end-to-end).

  Two-leg coverage:

    * **1A — scripted 3DS requires_action.** `Billing.charge/3` with a
      scripted `:create_charge` response whose shape says
      `status: :requires_action` + `client_secret` returns
      `{:ok, :requires_action, %{payment_intent_fields...}}`. No local
      `accrue_charges` row is persisted (see BILL-20 and
      `charge_actions.ex:121` — processor call runs OUTSIDE `Repo.transact`
      so SCA branches before insert).

    * **1B — subsequent `charge.succeeded` webhook drives Charge row to
      :succeeded.** After the SCA gate returns, the customer completes
      3DS out-of-band and Stripe emits a `charge.succeeded` event.
      `DefaultHandler.handle/1` refetches canonical state via
      `Processor.__impl__().fetch(:charge, id)` and upserts a local
      `accrue_charges` row with `status: "succeeded"`. Since the SCA
      branch never inserted a row, the reducer's `nil`-row branch
      inserts fresh — exactly the path a real 3DS-completing charge
      takes through the system.

  The live-Stripe fidelity companion for Item 1 lives at
  `test/live_stripe/charge_3ds_live_test.exs` — gated on
  `STRIPE_TEST_SECRET_KEY`, runs on schedule/dispatch only.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, PaymentMethod}
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_3ds_test",
        email: "3ds@example.com"
      })
      |> Repo.insert()

    {:ok, pm} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "pm_fake_3ds_00001",
        type: "card",
        fingerprint: "fp_3ds_default",
        card_brand: "visa",
        card_last4: "3184"
      })
      |> Repo.insert()

    %{customer: customer, pm: pm}
  end

  test "1A: scripted 3DS response returns {:ok, :requires_action, pi} and persists no local Charge row",
       %{customer: cus} do
    scripted_pi = %{
      id: "pi_fake_3ds_requires_action",
      object: "payment_intent",
      status: "requires_action",
      client_secret: "pi_fake_3ds_requires_action_secret",
      next_action: %{type: "use_stripe_sdk", use_stripe_sdk: %{}},
      amount: 5_000,
      currency: "usd"
    }

    Fake.scripted_response(:create_charge, {:ok, scripted_pi})

    assert {:ok, :requires_action, returned_pi} =
             Billing.charge(cus, Accrue.Money.new(5_000, :usd),
               payment_method: "pm_fake_3ds_00001"
             )

    # IntentResult.wrap passes through the processor map, so either atom
    # or string key shape is possible — tolerate both per intent_result.ex:107.
    assert (returned_pi[:id] || returned_pi["id"]) == "pi_fake_3ds_requires_action"
    assert (returned_pi[:client_secret] || returned_pi["client_secret"]) ==
             "pi_fake_3ds_requires_action_secret"

    assert (returned_pi[:status] || returned_pi["status"]) == "requires_action"

    # No local row written: BILL-20 invariant — the SCA branch MUST NOT
    # insert a half-baked Charge row while the PaymentIntent still needs
    # customer action.
    assert Repo.aggregate(Charge, :count) == 0
  end

  test "1B: charge.succeeded webhook upserts local Charge row to status 'succeeded'",
       %{customer: cus} do
    # Precondition: no local Charge row exists — mirrors the post-SCA-gate
    # state (see test 1A above). The customer has completed 3DS
    # out-of-band and Stripe has fired charge.succeeded at us.
    assert Repo.aggregate(Charge, :count) == 0

    # Seed a canonical charge in the Fake adapter so the reducer's
    # `Processor.__impl__().fetch(:charge, id)` call resolves. Using
    # Fake.create_charge keeps the shape identical to what Stripe would
    # hand us on retrieve_charge and auto-builds balance_transaction with
    # fee: 30 (Fake.build_charge, fake.ex:1282).
    {:ok, stripe_ch} =
      Fake.create_charge(
        %{amount: 5_000, currency: "usd", customer: cus.processor_id},
        []
      )

    event =
      StripeFixtures.webhook_event(
        "charge.succeeded",
        StripeFixtures.charge(%{"id" => stripe_ch.id, "customer" => cus.processor_id})
      )

    assert {:ok, %Charge{} = charge} = DefaultHandler.handle(event)

    # Reducer resolved canonical state and upserted a fresh row.
    assert charge.processor_id == stripe_ch.id
    assert charge.status == "succeeded"
    assert charge.customer_id == cus.id
    # fee projected from canonical balance_transaction (Fake fee: 30)
    assert charge.stripe_fee_amount_minor == 30
    assert charge.stripe_fee_currency == "usd"
    assert %DateTime{} = charge.fees_settled_at
    # watermark tracks the event
    assert charge.last_stripe_event_id == event["id"]

    # Exactly one row (the reducer inserted — nothing else wrote).
    assert Repo.aggregate(Charge, :count) == 1
  end
end
