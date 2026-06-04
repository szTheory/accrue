defmodule AccrueAdmin.E2E.Fixtures do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Refund, Subscription}
  alias Accrue.Connect.Account
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

  def seed_edge_states! do
    owner_id = Ecto.UUID.generate()

    customer =
      insert_customer(%{
        owner_id: owner_id,
        name: "E2E Dunning Customer",
        email: "dunning-e2e@example.com"
      })

    at_risk_sub =
      %Subscription{}
      |> Subscription.force_status_changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_e2e_dunning_at_risk",
        status: :past_due,
        past_due_since: DateTime.add(DateTime.utc_now(), -5 * 86_400, :second),
        dunning_campaign_started_at: DateTime.add(DateTime.utc_now(), -5 * 86_400, :second),
        cancel_at_period_end: false,
        lock_version: 1,
        metadata: %{},
        data: %{}
      })
      |> TestRepo.insert!()

    canceling_sub =
      insert_subscription(customer, %{
        processor_id: "sub_e2e_canceling",
        status: :active,
        cancel_at_period_end: true,
        current_period_end: DateTime.add(DateTime.utc_now(), 7 * 86_400, :second)
      })

    jpy_invoice =
      insert_invoice(customer, at_risk_sub, %{
        processor_id: "in_e2e_jpy",
        currency: "jpy",
        total_minor: 55_000,
        amount_due_minor: 55_000,
        amount_remaining_minor: 55_000,
        status: :open,
        number: "E2E-JPY-001"
      })

    jpy_charge =
      insert_charge(customer, at_risk_sub, %{
        processor_id: "ch_e2e_jpy",
        currency: "jpy",
        amount_cents: 55_000,
        status: "succeeded"
      })

    long_name_customer =
      insert_customer(%{
        name: String.duplicate("A", 100) <> " LongNameCo",
        email: "long-name-e2e@example.com"
      })

    coupon = insert_coupon(%{processor_id: "coupon_e2e_edge"})

    promo_code =
      insert_promo_code(coupon, %{
        processor_id: "promo_e2e_edge",
        code: "E2E-EDGE"
      })

    connect_account = insert_connect_account(owner_id, %{stripe_account_id: "acct_e2e_edge"})

    %{
      at_risk_sub_id: at_risk_sub.id,
      canceling_sub_id: canceling_sub.id,
      jpy_invoice_id: jpy_invoice.id,
      jpy_charge_id: jpy_charge.id,
      dunning_customer_id: customer.id,
      long_name_customer_id: long_name_customer.id,
      coupon_id: coupon.id,
      promo_code_id: promo_code.id,
      connect_account_id: connect_account.id
    }
  end

  def seed_overflow! do
    customers =
      Enum.map(1..26, fn i ->
        insert_customer(%{
          name: "E2E Overflow Customer #{i}",
          email: "overflow-e2e-#{i}@example.com",
          processor_id: "cus_e2e_overflow_#{i}"
        })
      end)

    _subscriptions =
      Enum.map(customers, fn customer ->
        insert_subscription(customer, %{
          processor_id: "sub_e2e_overflow_#{customer.processor_id}",
          status: :active
        })
      end)

    %{first_customer_id: List.first(customers).id}
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

  defp insert_coupon(attrs) do
    defaults = %{
      processor: "fake",
      processor_id: "coupon_" <> Integer.to_string(System.unique_integer([:positive])),
      name: "E2E Edge Coupon",
      duration: "once",
      percent_off: Decimal.new("10.0"),
      currency: "usd",
      valid: true,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Coupon{}
    |> Coupon.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_promo_code(coupon, attrs) do
    defaults = %{
      processor: "fake",
      processor_id: "promo_" <> Integer.to_string(System.unique_integer([:positive])),
      code: "E2E-" <> Integer.to_string(System.unique_integer([:positive])),
      coupon_id: coupon.id,
      active: true,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %PromotionCode{}
    |> PromotionCode.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_connect_account(owner_id, attrs) do
    defaults = %{
      stripe_account_id: "acct_e2e_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "standard",
      owner_type: "User",
      owner_id: owner_id,
      email: "connect-e2e@example.com",
      country: "us",
      charges_enabled: true,
      payouts_enabled: true,
      details_submitted: true,
      capabilities: %{},
      requirements: %{},
      data: %{}
    }

    %Account{}
    |> Account.changeset(Map.merge(defaults, attrs))
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
