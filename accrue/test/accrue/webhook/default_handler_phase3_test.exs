defmodule Accrue.Webhook.DefaultHandlerPhase3Test do
  @moduledoc """
  Plan 07 Task 1: DefaultHandler Phase 3 reducers cover the subscription,
  invoice, charge, refund, and payment_method event families. Each reducer
  refetches canonical state via `Processor.fetch/2`, applies the change
  via the webhook-path changeset, and records an `accrue_events` row.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Charge, Invoice, PaymentMethod, Refund}
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_phase3",
        email: "phase3@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "customer.subscription.updated refetches and updates row", %{customer: cus} do
    {:ok, sub} = Accrue.Billing.subscribe(cus, "price_basic")
    # Transition in Fake directly so the refetch sees a new status.
    {:ok, _} = Fake.transition(sub.processor_id, :active, synthesize_webhooks: false)

    event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub.processor_id})
      )

    assert {:ok, updated} = DefaultHandler.handle(event)
    assert updated.status == :active
    assert updated.last_stripe_event_id == event["id"]
  end

  test "invoice.paid uses force_status_changeset", %{customer: cus} do
    # Seed an invoice directly via the Fake.
    params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
    {:ok, stripe_inv} = Fake.create_invoice(params, [])

    # Insert local invoice row in :draft state.
    {:ok, inv} =
      %Invoice{customer_id: cus.id, processor: "fake"}
      |> Invoice.force_status_changeset(%{
        processor_id: stripe_inv.id,
        currency: "usd",
        status: :draft
      })
      |> Repo.insert()

    # Move Fake to paid without synthesizing its own event.
    {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])
    {:ok, _} = Fake.pay_invoice(stripe_inv.id, [])

    event =
      StripeFixtures.webhook_event(
        "invoice.paid",
        StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
      )

    assert {:ok, updated} = DefaultHandler.handle(event)
    assert updated.id == inv.id
    assert updated.status == :paid
  end

  test "charge.succeeded records fee data from balance_transaction", %{customer: cus} do
    {:ok, stripe_ch} =
      Fake.create_charge(
        %{amount: 10_000, currency: "usd", customer: cus.processor_id},
        []
      )

    event =
      StripeFixtures.webhook_event(
        "charge.succeeded",
        StripeFixtures.charge(%{"id" => stripe_ch.id, "customer" => cus.processor_id})
      )

    assert {:ok, charge} = DefaultHandler.handle(event)
    assert charge.processor_id == stripe_ch.id
    assert charge.stripe_fee_amount_minor == 30
    assert charge.fees_settled_at
  end

  test "payment_method.updated patches exp_month/exp_year", %{customer: cus} do
    {:ok, stripe_pm} = Fake.create_payment_method(%{type: "card"}, [])
    {:ok, _} = Fake.attach_payment_method(stripe_pm.id, %{customer: cus.processor_id}, [])

    event =
      StripeFixtures.webhook_event(
        "payment_method.updated",
        StripeFixtures.payment_method_card(%{
          "id" => stripe_pm.id,
          "customer" => cus.processor_id
        })
      )

    assert {:ok, pm} = DefaultHandler.handle(event)
    assert %PaymentMethod{} = pm
    assert pm.exp_month == 12
    assert pm.exp_year == 2030
  end

  test "charge.refund.updated upserts refund row even when no local row exists", %{customer: cus} do
    {:ok, stripe_ch} =
      Fake.create_charge(
        %{amount: 10_000, currency: "usd", customer: cus.processor_id},
        []
      )

    # Local charge row so refund can find its parent.
    {:ok, _} =
      %Charge{customer_id: cus.id, processor: "fake"}
      |> Charge.changeset(%{
        processor_id: stripe_ch.id,
        amount_cents: 10_000,
        currency: "usd",
        status: "succeeded"
      })
      |> Repo.insert()

    {:ok, stripe_refund} = Fake.create_refund(%{charge: stripe_ch.id, amount: 10_000}, [])

    event =
      StripeFixtures.webhook_event(
        "charge.refund.updated",
        StripeFixtures.refund(%{"id" => stripe_refund.id, "charge" => stripe_ch.id})
      )

    assert {:ok, ref} = DefaultHandler.handle(event)
    assert %Refund{} = ref
    assert ref.stripe_id == stripe_refund.id
    assert Repo.get_by(Refund, stripe_id: stripe_refund.id)
  end
end
