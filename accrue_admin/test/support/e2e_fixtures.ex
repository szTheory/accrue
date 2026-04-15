defmodule AccrueAdmin.E2E.Fixtures do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Customer, Invoice, Refund, Subscription}
  alias Accrue.Events
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.TestRepo

  @tables ~w(
    oban_jobs
    accrue_events
    accrue_refunds
    accrue_charges
    accrue_invoice_items
    accrue_invoices
    accrue_subscription_items
    accrue_subscriptions
    accrue_payment_methods
    accrue_promotion_codes
    accrue_coupons
    accrue_connect_accounts
    accrue_webhook_events
    accrue_customers
  )

  def reset! do
    TestRepo.query!("TRUNCATE TABLE #{Enum.join(@tables, ", ")} RESTART IDENTITY CASCADE", [])
    :ok = Accrue.Processor.Fake.reset()
    :ok = Accrue.Actor.put_operation_id("e2e-" <> Ecto.UUID.generate())
    :ok
  end

  def seed_dashboard! do
    customer =
      insert_customer(%{
        name: "E2E Dashboard Customer",
        email: "dashboard-e2e@example.com"
      })

    subscription =
      insert_subscription(customer, %{status: :active, processor_id: "sub_e2e_dashboard"})

    insert_invoice(customer, subscription, %{
      processor_id: "in_e2e_dashboard",
      status: :open,
      amount_due_minor: 4_250,
      amount_remaining_minor: 4_250,
      total_minor: 4_250
    })

    insert_webhook(%{
      processor_event_id: "evt_e2e_dashboard_dead",
      type: "invoice.payment_failed",
      status: :dead,
      data: %{"id" => "evt_e2e_dashboard_dead"},
      raw_body: ~s({"id":"evt_e2e_dashboard_dead","type":"invoice.payment_failed"})
    })

    {:ok, event} =
      Events.record(%{
        type: "customer.updated",
        subject_type: "Customer",
        subject_id: customer.id,
        actor_type: "admin",
        actor_id: "e2e_admin"
      })

    %{customer_id: customer.id, subscription_id: subscription.id, event_id: event.id}
  end

  def seed_operator_flows! do
    customer =
      insert_customer(%{
        name: "E2E Charge Customer",
        email: "charge-e2e@example.com"
      })

    subscription =
      insert_subscription(customer, %{status: :active, processor_id: "sub_e2e_refund"})

    charge =
      insert_charge(customer, subscription, %{
        processor_id: "ch_e2e_refund",
        status: "succeeded",
        amount_cents: 10_000,
        stripe_fee_amount_minor: 320,
        fees_settled_at: ~U[2026-04-15 12:00:00Z],
        data: %{
          "application_fee_amount" => 200,
          "balance_transaction" => %{"net" => 9_680}
        }
      })

    insert_refund(charge, %{
      stripe_id: "re_e2e_seeded",
      amount_minor: 1_000,
      status: :succeeded,
      stripe_fee_refunded_amount_minor: 32,
      merchant_loss_amount_minor: 18
    })

    {:ok, source_event} =
      Events.record(%{
        type: "charge.succeeded",
        subject_type: "Charge",
        subject_id: charge.id,
        actor_type: "system"
      })

    single_webhook =
      insert_webhook(%{
        processor_event_id: "evt_e2e_single",
        type: "invoice.payment_failed",
        status: :dead,
        raw_body: ~s({"id":"evt_e2e_single","type":"invoice.payment_failed"})
      })

    bulk_webhook =
      insert_webhook(%{
        processor_event_id: "evt_e2e_bulk",
        type: "customer.subscription.updated",
        status: :failed,
        raw_body: ~s({"id":"evt_e2e_bulk","type":"customer.subscription.updated"})
      })

    %{
      charge_id: charge.id,
      source_event_id: source_event.id,
      single_webhook_id: single_webhook.id,
      bulk_webhook_id: bulk_webhook.id
    }
  end

  def current_counts do
    %{
      webhook_replayed:
        WebhookEvent
        |> where([event], event.status == :replayed)
        |> TestRepo.aggregate(:count, :id),
      admin_events:
        Accrue.Events.Event
        |> where([event], event.actor_type == "admin")
        |> TestRepo.aggregate(:count, :id)
    }
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      status: :trialing,
      metadata: %{},
      data: %{},
      cancel_at_period_end: false,
      lock_version: 1
    }

    %Subscription{}
    |> Subscription.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: "fake",
      processor_id: "in_" <> Integer.to_string(System.unique_integer([:positive])),
      status: :open,
      number: "E2E-001",
      currency: "usd",
      metadata: %{},
      data: %{},
      collection_method: "charge_automatically",
      total_discount_amounts: %{},
      amount_due_minor: 0,
      amount_paid_minor: 0,
      amount_remaining_minor: 0,
      total_minor: 0
    }

    %Invoice{}
    |> Invoice.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_charge(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: "fake",
      processor_id: "ch_" <> Integer.to_string(System.unique_integer([:positive])),
      status: "succeeded",
      currency: "usd",
      amount_cents: 1_000,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Charge{}
    |> Charge.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_refund(charge, attrs) do
    defaults = %{
      charge_id: charge.id,
      amount_minor: 1_000,
      currency: "usd",
      status: :succeeded,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Refund{}
    |> Refund.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      status: :received,
      endpoint: :default,
      livemode: false,
      raw_body: ~s({"id":"evt_e2e","object":"event"}),
      data: %{},
      received_at: DateTime.utc_now()
    }

    attrs = Map.merge(defaults, attrs)
    status = attrs.status

    attrs
    |> Map.delete(:status)
    |> WebhookEvent.ingest_changeset()
    |> Ecto.Changeset.put_change(:status, status)
    |> TestRepo.insert!()
  end
end
