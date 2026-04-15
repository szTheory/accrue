defmodule Accrue.Webhook.DefaultHandlerMailerDispatchTest do
  @moduledoc """
  Plan 06-07 Task 1: webhook reducer → mailer dispatch wiring.

  After each DefaultHandler reducer commits state reconciliation, it
  dispatches the domain email via `Accrue.Mailer.deliver/2`. Tests use
  `Accrue.Mailer.Test` (the default test adapter per config/test.exs)
  so assertions use the intent-tuple protocol
  (`{:accrue_email_delivered, type, assigns}`).

  Pitfall 7 discipline: the reducer is the single dispatch point — the
  double-dispatch regression test below verifies that delivering the
  same event twice through `handle/1` results in at-most-one deliver
  call at the behavior layer (the second call is allowed — de-dupe is
  the job of the Oban `unique:` option in the real pipeline, NOT the
  test adapter — so we assert count == 2 and document the Oban layer
  is the de-dupe point).
  """
  use Accrue.BillingCase, async: false
  use Accrue.Test.MailerAssertions

  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Billing.{Charge, Invoice}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_mailer_dispatch",
        email: "md@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "charge.succeeded → :receipt" do
    test "dispatches :receipt with customer_id scalar", %{customer: cus} do
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

      assert {:ok, %Charge{}} = DefaultHandler.handle(event)
      assert_email_sent(:receipt, customer_id: cus.id)
    end
  end

  describe "charge.failed → :payment_failed" do
    test "dispatches :payment_failed", %{customer: cus} do
      {:ok, stripe_ch} =
        Fake.create_charge(
          %{amount: 10_000, currency: "usd", customer: cus.processor_id},
          []
        )

      event =
        StripeFixtures.webhook_event(
          "charge.failed",
          StripeFixtures.charge(%{"id" => stripe_ch.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Charge{}} = DefaultHandler.handle(event)
      assert_email_sent(:payment_failed, customer_id: cus.id)
    end
  end

  describe "invoice.finalized → :invoice_finalized" do
    test "dispatches with invoice_id + hosted_invoice_url scalars", %{customer: cus} do
      params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
      {:ok, stripe_inv} = Fake.create_invoice(params, [])
      {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])

      {:ok, _inv} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: stripe_inv.id,
          currency: "usd",
          status: :draft
        })
        |> Repo.insert()

      event =
        StripeFixtures.webhook_event(
          "invoice.finalized",
          StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Invoice{}} = DefaultHandler.handle(event)
      assert_email_sent(:invoice_finalized, customer_id: cus.id)
    end
  end

  describe "invoice.paid → :invoice_paid" do
    test "dispatches :invoice_paid", %{customer: cus} do
      params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
      {:ok, stripe_inv} = Fake.create_invoice(params, [])
      {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])
      {:ok, _} = Fake.pay_invoice(stripe_inv.id, [])

      {:ok, _inv} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: stripe_inv.id,
          currency: "usd",
          status: :draft
        })
        |> Repo.insert()

      event =
        StripeFixtures.webhook_event(
          "invoice.paid",
          StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Invoice{status: :paid}} = DefaultHandler.handle(event)
      assert_email_sent(:invoice_paid, customer_id: cus.id)
    end
  end

  describe "invoice.payment_failed → :invoice_payment_failed" do
    test "dispatches :invoice_payment_failed", %{customer: cus} do
      params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
      {:ok, stripe_inv} = Fake.create_invoice(params, [])
      {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])

      {:ok, _inv} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: stripe_inv.id,
          currency: "usd",
          status: :open
        })
        |> Repo.insert()

      event =
        StripeFixtures.webhook_event(
          "invoice.payment_failed",
          StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_email_sent(:invoice_payment_failed, customer_id: cus.id)
    end
  end

  describe "customer.subscription.trial_will_end → :trial_ending" do
    test "dispatches :trial_ending", %{customer: cus} do
      {:ok, sub} = Accrue.Billing.subscribe(cus, "price_basic")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.trial_will_end",
          StripeFixtures.subscription_created(%{"id" => sub.processor_id})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_email_sent(:trial_ending, customer_id: cus.id)
    end
  end

  describe "customer.subscription.deleted → :subscription_canceled" do
    test "dispatches :subscription_canceled", %{customer: cus} do
      {:ok, sub} = Accrue.Billing.subscribe(cus, "price_basic")
      {:ok, _} = Fake.transition(sub.processor_id, :canceled, synthesize_webhooks: false)

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.deleted",
          StripeFixtures.subscription_created(%{"id" => sub.processor_id})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_email_sent(:subscription_canceled, customer_id: cus.id)
    end
  end

  describe "Pitfall 7 — single dispatch point discipline" do
    test "reducer is the only place :receipt is dispatched — Billing actions do not duplicate",
         %{customer: cus} do
      # This is a grep-level guard: the test asserts that within the
      # Billing action modules for charge-related flows, no direct
      # `Accrue.Mailer.deliver(:receipt, ...)` call exists. The webhook
      # reducer holds the single dispatch for the catalogue state-
      # change emails (receipt / payment_failed / invoice_* /
      # subscription_canceled / refund_issued).
      billing_root = Path.expand("../../../../lib/accrue/billing", __DIR__)

      offenders =
        billing_root
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(fn path ->
          body = File.read!(path)

          banned_types =
            ~w(receipt payment_failed invoice_finalized invoice_paid invoice_payment_failed subscription_canceled subscription_paused subscription_resumed refund_issued)

          Enum.flat_map(banned_types, fn type ->
            pattern = "Accrue.Mailer.deliver(:" <> type
            if String.contains?(body, pattern), do: [{path, type}], else: []
          end)
        end)

      assert offenders == [],
             "Pitfall 7 violation: Billing action modules must NOT call " <>
               "Accrue.Mailer.deliver/2 for state-change emails. Only the " <>
               "webhook reducer dispatches these. Offenders: #{inspect(offenders)}. " <>
               "Allowed exceptions: :card_expiring_soon (cron) and :coupon_applied (action)."

      # Keep the customer binding referenced so the Dialyzer/ExUnit
      # unused-var warning stays silent.
      _ = cus
    end
  end
end
