defmodule AccrueAdmin.E2E.Fixtures do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Refund, Subscription}
  alias Accrue.Connect.Account
  alias Accrue.Events
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.TestRepo

  @public_tables ~w(
    oban_jobs
  )

  @accrue_tables ~w(
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
    tables =
      @public_tables ++
        Enum.map(@accrue_tables, &Accrue.Migration.qualified_table/1)

    TestRepo.query!("TRUNCATE TABLE #{Enum.join(tables, ", ")} RESTART IDENTITY CASCADE", [])
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

  def seed_phase191_matrix! do
    reset!()

    owner_id = "19100000-0000-4000-8000-00000000f001"
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    five_days_ago = DateTime.add(now, -5 * 86_400, :second)
    next_period = DateTime.add(now, 30 * 86_400, :second)

    customer =
      insert_customer(%{
        id: "19100000-0000-4000-8000-000000000001",
        owner_id: owner_id,
        name: "E2E Phase 191 株式会社 Café Boundary Customer",
        email: "phase191-customer@example.com",
        processor_id: "cus_e2e_phase191_customer",
        preferred_locale: nil,
        preferred_timezone: nil,
        metadata: %{
          "phase191_fixture" => "non_ascii",
          "phase191_boundary" => "primary-route"
        },
        data: %{
          "phase191_high_count" => 100_000,
          "optional_profile_fields" => nil
        }
      })

    subscription =
      insert_subscription(customer, %{
        id: "19100000-0000-4000-8000-000000000002",
        processor_id: "sub_e2e_phase191_active",
        status: :active,
        current_period_start: now,
        current_period_end: next_period,
        metadata: %{"phase191_fixture" => "route"},
        data: %{"phase191_high_count" => 100_000}
      })

    at_risk_sub =
      %Subscription{id: "19100000-0000-4000-8000-000000000010"}
      |> Subscription.force_status_changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_e2e_phase191_at_risk",
        status: :past_due,
        past_due_since: five_days_ago,
        dunning_campaign_started_at: five_days_ago,
        cancel_at_period_end: false,
        current_period_start: DateTime.add(now, -25 * 86_400, :second),
        current_period_end: DateTime.add(now, 5 * 86_400, :second),
        lock_version: 1,
        metadata: %{"phase191_fixture" => "at-risk"},
        data: %{"recovery_state" => "phase191"}
      })
      |> TestRepo.insert!()

    invoice =
      insert_invoice(customer, subscription, %{
        id: "19100000-0000-4000-8000-000000000003",
        processor_id: "in_e2e_phase191_boundary",
        status: :open,
        number: "E2E-191-JPY-001",
        currency: "jpy",
        total_minor: 100_000,
        amount_due_minor: 100_000,
        amount_remaining_minor: 100_000,
        amount_paid_minor: 0,
        hosted_url: nil,
        pdf_url: nil,
        collection_method: "send_invoice",
        metadata: %{"phase191_fixture" => "null-optional-fields"},
        data: %{"memo" => nil, "phase191_non_ascii_note" => "請求書"}
      })

    charge =
      insert_charge(customer, subscription, %{
        id: "19100000-0000-4000-8000-000000000004",
        processor_id: "ch_e2e_phase191_boundary",
        status: "succeeded",
        currency: "jpy",
        amount_cents: 100_000,
        stripe_fee_amount_minor: nil,
        fees_settled_at: nil,
        metadata: %{"phase191_fixture" => "high-count"},
        data: %{"phase191_high_count" => 100_000, "receipt_url" => nil}
      })

    coupon =
      insert_coupon(%{
        id: "19100000-0000-4000-8000-000000000005",
        processor_id: "coupon_e2e_phase191_unicode",
        name: "Crème Phase 191 株式会社 Coupon",
        duration: "repeating",
        duration_in_months: 3,
        percent_off: Decimal.new("19.1"),
        max_redemptions: 100_000,
        times_redeemed: 1,
        metadata: %{"phase191_fixture" => "non_ascii"},
        data: %{"copy_state" => "promotion boundary"}
      })

    promo_code =
      insert_promo_code(coupon, %{
        id: "19100000-0000-4000-8000-000000000006",
        processor_id: "promo_e2e_phase191_unicode",
        code: "ÉTÉ191",
        max_redemptions: 100_000,
        times_redeemed: 1,
        metadata: %{"phase191_fixture" => "non_ascii"},
        data: %{"phase191_non_ascii_name" => "été"}
      })

    connect_account =
      insert_connect_account(owner_id, %{
        id: "19100000-0000-4000-8000-000000000007",
        stripe_account_id: "acct_e2e_phase191",
        email: "phase191-connect@example.com",
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: false,
        requirements: %{"currently_due" => ["external_account"]},
        capabilities: %{"card_payments" => "pending"},
        data: %{"phase191_null_future_requirement" => nil}
      })

    webhook =
      insert_webhook(%{
        id: "19100000-0000-4000-8000-000000000008",
        processor_event_id: "evt_e2e_phase191_dead",
        type: "invoice.payment_failed",
        status: :dead,
        data: %{
          "id" => "evt_e2e_phase191_dead",
          "object" => "event",
          "phase191" => true
        },
        raw_body:
          ~s({"id":"evt_e2e_phase191_dead","type":"invoice.payment_failed","phase191":true})
      })

    {:ok, source_event} =
      Events.record(%{
        type: "phase191.fixture.seeded",
        subject_type: "Phase191Fixture",
        subject_id: customer.id,
        actor_type: "admin",
        actor_id: "e2e_phase191",
        idempotency_key: "e2e_phase191_event",
        data: %{"namespace" => "e2e_phase191"}
      })

    insert_customer(%{
      id: "19100000-0000-4000-8000-000000000009",
      owner_id: "19100000-0000-4000-8000-00000000f009",
      name: "E2E Phase 191 One Row Customer",
      email: "phase191-one@example.com",
      processor_id: "cus_e2e_phase191_one",
      metadata: %{"phase191_boundary" => "one-row"}
    })

    Enum.each(1..26, fn index ->
      padded = String.pad_leading(Integer.to_string(index), 2, "0")

      insert_customer(%{
        name: "E2E Phase 191 Page Customer #{padded}",
        email: "phase191-page-#{padded}@example.com",
        processor_id: "cus_e2e_phase191_page_#{padded}",
        metadata: %{"phase191_boundary" => "more-than-one-page"},
        data: %{"phase191_index" => index}
      })
    end)

    zero_rows =
      Customer
      |> where([customer], customer.processor_id == "cus_e2e_phase191_zero")
      |> TestRepo.aggregate(:count, :id)

    one_row =
      Customer
      |> where([customer], customer.processor_id == "cus_e2e_phase191_one")
      |> TestRepo.aggregate(:count, :id)

    more_than_one_page =
      Customer
      |> where([customer], like(customer.processor_id, "cus_e2e_phase191_page_%"))
      |> TestRepo.aggregate(:count, :id)

    %{
      namespace: "e2e_phase191",
      customer_id: customer.id,
      subscription_id: subscription.id,
      jpy_invoice_id: invoice.id,
      charge_id: charge.id,
      coupon_id: coupon.id,
      promo_code_id: promo_code.id,
      connect_account_id: connect_account.id,
      source_event_id: source_event.id,
      single_webhook_id: webhook.id,
      at_risk_sub_id: at_risk_sub.id,
      phase191_customer_id: customer.id,
      phase191_subscription_id: subscription.id,
      phase191_invoice_id: invoice.id,
      phase191_charge_id: charge.id,
      phase191_coupon_id: coupon.id,
      phase191_promo_code_id: promo_code.id,
      phase191_connect_account_id: connect_account.id,
      phase191_event_id: source_event.id,
      phase191_webhook_id: webhook.id,
      phase191_at_risk_sub_id: at_risk_sub.id,
      boundary_counts: %{
        zero_rows: zero_rows,
        one_row: one_row,
        more_than_one_page: more_than_one_page,
        high_count: 100_000
      },
      boundary_filters: %{
        zero_rows: "processor_id=cus_e2e_phase191_zero",
        one_row: "processor_id=cus_e2e_phase191_one",
        more_than_one_page: "processor_id starts with cus_e2e_phase191_page_"
      }
    }
  end

  def seed_phase199_interactions! do
    reset!()

    owner_id = "19900000-0000-4000-8000-00000000f001"
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    five_days_ago = DateTime.add(now, -5 * 86_400, :second)
    next_period = DateTime.add(now, 30 * 86_400, :second)
    long_processor_id = "proc_phase199_" <> String.duplicate("edge-route-overflow-", 4)
    long_email = "phase199." <> String.duplicate("route-edge-", 8) <> "@example.com"

    customer =
      insert_customer(%{
        id: "19900000-0000-4000-8000-000000000001",
        owner_id: owner_id,
        name: "E2E Phase 199 Boundary Customer " <> String.duplicate("LongNameCo ", 12),
        email: long_email,
        processor_id: "cus_e2e_phase199_customer",
        preferred_locale: nil,
        preferred_timezone: nil,
        metadata: %{
          "phase199_fixture" => "route-flow",
          "phase199_boundary" => "long-content"
        },
        data: %{
          "phase199_long_processor_id" => long_processor_id,
          "phase199_overflow_payload" => String.duplicate("payload-", 64)
        }
      })

    subscription =
      insert_subscription(customer, %{
        id: "19900000-0000-4000-8000-000000000002",
        processor_id: "sub_e2e_phase199_active",
        status: :active,
        current_period_start: now,
        current_period_end: next_period,
        metadata: %{"phase199_fixture" => "subscription-route"},
        data: %{"phase199_long_processor_id" => long_processor_id}
      })

    invoice =
      insert_invoice(customer, subscription, %{
        id: "19900000-0000-4000-8000-000000000003",
        processor_id: "in_e2e_phase199_jpy",
        status: :open,
        number: "E2E-199-JPY-001",
        currency: "jpy",
        total_minor: 55_000,
        amount_due_minor: 55_000,
        amount_remaining_minor: 55_000,
        amount_paid_minor: 0,
        hosted_url: nil,
        pdf_url: nil,
        collection_method: "send_invoice",
        metadata: %{"phase199_fixture" => "zero-decimal"},
        data: %{"phase199_long_processor_id" => long_processor_id}
      })

    charge =
      insert_charge(customer, subscription, %{
        id: "19900000-0000-4000-8000-000000000004",
        processor_id: "ch_e2e_phase199_refund",
        status: "succeeded",
        amount_cents: 10_000,
        stripe_fee_amount_minor: 320,
        fees_settled_at: ~U[2026-06-30 00:00:00Z],
        metadata: %{"phase199_fixture" => "charge-route"},
        data: %{"application_fee_amount" => 200}
      })

    insert_refund(charge, %{
      stripe_id: "re_e2e_phase199_seeded",
      amount_minor: 1_000,
      status: :succeeded,
      stripe_fee_refunded_amount_minor: 32,
      merchant_loss_amount_minor: 18
    })

    jpy_charge =
      insert_charge(customer, subscription, %{
        id: "19900000-0000-4000-8000-000000000005",
        processor_id: "ch_e2e_phase199_jpy",
        status: "succeeded",
        currency: "jpy",
        amount_cents: 55_000,
        metadata: %{"phase199_fixture" => "zero-decimal"},
        data: %{"phase199_long_processor_id" => long_processor_id}
      })

    webhook =
      insert_webhook(%{
        id: "19900000-0000-4000-8000-000000000006",
        processor_event_id: "evt_e2e_phase199_dead",
        type: "invoice.payment_failed",
        status: :dead,
        data: %{
          "id" => "evt_e2e_phase199_dead",
          "object" => "event",
          "phase199" => true,
          "payload" => String.duplicate("raw-payload-overflow-", 48)
        },
        raw_body:
          ~s({"id":"evt_e2e_phase199_dead","type":"invoice.payment_failed","phase199":true,"payload":") <>
            String.duplicate("raw-payload-overflow-", 48) <> ~s("})
      })

    {:ok, event} =
      Events.record(%{
        type: "charge.succeeded",
        subject_type: "Charge",
        subject_id: charge.id,
        actor_type: "admin",
        actor_id: "e2e_phase199",
        idempotency_key: "e2e_phase199_event",
        caused_by_webhook_event_id: webhook.id,
        data: %{"namespace" => "e2e_phase199", "phase199" => true}
      })

    recovery_subscription =
      %Subscription{id: "19900000-0000-4000-8000-000000000007"}
      |> Subscription.force_status_changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_e2e_phase199_recovery",
        status: :past_due,
        past_due_since: five_days_ago,
        dunning_campaign_started_at: five_days_ago,
        cancel_at_period_end: false,
        current_period_start: DateTime.add(now, -25 * 86_400, :second),
        current_period_end: DateTime.add(now, 5 * 86_400, :second),
        lock_version: 1,
        metadata: %{"phase199_fixture" => "recovery"},
        data: %{"recovery_state" => "phase199"}
      })
      |> TestRepo.insert!()

    long_name_customer =
      insert_customer(%{
        id: "19900000-0000-4000-8000-000000000008",
        owner_id: "19900000-0000-4000-8000-00000000f008",
        name: "E2E Phase 199 " <> String.duplicate("Overflow Business ", 10),
        email: "phase199-long-name@example.com",
        processor_id: "cus_e2e_phase199_long_name",
        metadata: %{"phase199_fixture" => "long-name"}
      })

    connect_account =
      insert_connect_account(owner_id, %{
        id: "19900000-0000-4000-8000-000000000009",
        stripe_account_id: "acct_e2e_phase199_attention",
        email: "phase199-connect@example.com",
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: false,
        requirements: %{
          "currently_due" => ["external_account", "representative.verification.document"]
        },
        capabilities: %{"card_payments" => "pending", "transfers" => "pending"},
        data: %{"phase199_long_processor_id" => long_processor_id}
      })

    %{
      namespace: "e2e_phase199",
      customer_id: customer.id,
      subscription_id: subscription.id,
      invoice_id: invoice.id,
      jpy_invoice_id: invoice.id,
      charge_id: charge.id,
      jpy_charge_id: jpy_charge.id,
      webhook_id: webhook.id,
      single_webhook_id: webhook.id,
      event_id: event.id,
      source_event_id: event.id,
      connect_account_id: connect_account.id,
      recovery_subscription_id: recovery_subscription.id,
      at_risk_sub_id: recovery_subscription.id,
      long_name_customer_id: long_name_customer.id,
      edge_data: %{
        long_email: long_email,
        long_processor_id: long_processor_id,
        raw_payload_bytes: byte_size(webhook.raw_body)
      }
    }
  end

  def seed_phase199_interaction_matrix!, do: seed_phase199_interactions!()

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
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer, attrs) do
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, subscription, attrs) do
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> TestRepo.insert!()
  end

  defp insert_charge(customer, subscription, attrs) do
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
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
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> TestRepo.insert!()
  end

  defp insert_promo_code(coupon, attrs) do
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> TestRepo.insert!()
  end

  defp insert_connect_account(owner_id, attrs) do
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> TestRepo.insert!()
  end

  defp insert_webhook(attrs) do
    {id, attrs} = Map.pop(attrs, :id)

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
    |> put_id(id)
    |> Ecto.Changeset.put_change(:status, status)
    |> TestRepo.insert!()
  end

  defp put_id(changeset, nil), do: changeset
  defp put_id(changeset, id), do: Ecto.Changeset.put_change(changeset, :id, id)
end
