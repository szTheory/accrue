# Phase 191 page-flow fixture stress seed.
#
# Adds deterministic host-dev billing rows for Phase 191 click-through coverage:
#
#   - Null optional fields on customer, invoice, charge, and Connect account
#   - Boundary pagination rows: zero-row filter, one-row filter, and 26-row page
#   - Bounded high-count values for count/KPI rendering without massive inserts
#   - Non-ASCII customer, coupon, and promotion-code labels
#   - Dead webhook and at-risk recovery references
#
# FULLY IDEMPOTENT: billing rows are keyed by deterministic processor IDs,
# Connect/webhook rows by their canonical external IDs, and the append-only event
# by a stable idempotency key. Re-running seeds.exs does not duplicate rows.
#
# Processor IDs live in the "phase191_host" namespace so local click-through
# data stays separate from browser-only "e2e_phase191" forcing fixtures.

alias Accrue.Connect.Account
alias Accrue.Events.Event
alias Accrue.Webhook.WebhookEvent
alias AccrueHost.Repo

alias Accrue.Billing.{
  Charge,
  Coupon,
  Customer,
  Invoice,
  PromotionCode,
  Subscription
}

now = Accrue.Clock.utc_now() |> DateTime.truncate(:microsecond)
days_ago = fn days -> DateTime.add(now, -days * 86_400, :second) end
days_from_now = fn days -> DateTime.add(now, days * 86_400, :second) end

owner_id = "19100000-0000-4000-8000-00000000f001"

upsert = fn schema, lookup, seed_id, changeset_fun, attrs ->
  case Repo.get_by(schema, lookup) do
    nil ->
      struct(schema, id: seed_id)
      |> changeset_fun.(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

upsert_processor = fn schema, changeset_fun, seed_id, processor_id, attrs ->
  attrs = attrs |> Map.put(:processor, "fake") |> Map.put(:processor_id, processor_id)

  upsert.(
    schema,
    [processor: "fake", processor_id: processor_id],
    seed_id,
    changeset_fun,
    attrs
  )
end

record_event = fn attrs, idempotency_key, at ->
  row =
    attrs
    |> Map.put(:idempotency_key, idempotency_key)
    |> Map.put(:inserted_at, at)
    |> Map.put_new(:actor_type, "admin")
    |> Map.put_new(:actor_id, "phase191_host")
    |> Map.put_new(:schema_version, 1)
    |> Map.put_new(:data, %{})

  Repo.insert_all(Event, [row],
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
  )

  Repo.get_by!(Event, idempotency_key: idempotency_key)
end

customer =
  upsert_processor.(
    Customer,
    &Customer.changeset/2,
    "19100000-0000-4000-8000-00000000a001",
    "cus_phase191_host_customer",
    %{
      owner_type: "Organization",
      owner_id: owner_id,
      name: "Phase 191 株式会社 Café Boundary Customer",
      email: "phase191-host-customer@example.com",
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
    }
  )

subscription =
  upsert_processor.(
    Subscription,
    &Subscription.changeset/2,
    "19100000-0000-4000-8000-00000000a002",
    "sub_phase191_host_active",
    %{
      customer_id: customer.id,
      status: :active,
      current_period_start: days_ago.(2),
      current_period_end: days_from_now.(28),
      lock_version: 1,
      metadata: %{"phase191_fixture" => "route"},
      data: %{"phase191_high_count" => 100_000}
    }
  )

_invoice =
  upsert_processor.(
    Invoice,
    &Invoice.force_status_changeset/2,
    "19100000-0000-4000-8000-00000000a003",
    "in_phase191_host_boundary",
    %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      status: :open,
      number: "PHASE191-JPY-001",
      currency: "jpy",
      subtotal_minor: 100_000,
      tax_minor: 0,
      total_minor: 100_000,
      total_cents: 100_000,
      amount_due_minor: 100_000,
      amount_paid_minor: 0,
      amount_remaining_minor: 100_000,
      hosted_url: nil,
      pdf_url: nil,
      collection_method: "send_invoice",
      billing_reason: "subscription_cycle",
      finalized_at: days_ago.(1),
      period_start: days_ago.(31),
      period_end: days_ago.(1),
      metadata: %{"phase191_fixture" => "null-optional-fields"},
      data: %{"memo" => nil, "phase191_non_ascii_note" => "請求書"}
    }
  )

_charge =
  upsert_processor.(
    Charge,
    &Charge.changeset/2,
    "19100000-0000-4000-8000-00000000a004",
    "ch_phase191_host_boundary",
    %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      status: "succeeded",
      currency: "jpy",
      amount_cents: 100_000,
      stripe_fee_amount_minor: nil,
      stripe_fee_currency: nil,
      fees_settled_at: nil,
      metadata: %{"phase191_fixture" => "high-count"},
      data: %{"phase191_high_count" => 100_000, "receipt_url" => nil}
    }
  )

coupon =
  upsert_processor.(
    Coupon,
    &Coupon.changeset/2,
    "19100000-0000-4000-8000-00000000a005",
    "coupon_phase191_host_unicode",
    %{
      name: "Crème Phase 191 株式会社 Coupon",
      duration: "repeating",
      duration_in_months: 3,
      percent_off: Decimal.new("19.1"),
      max_redemptions: 100_000,
      times_redeemed: 1,
      valid: true,
      metadata: %{"phase191_fixture" => "non_ascii"},
      data: %{"copy_state" => "promotion boundary"}
    }
  )

_promo_code =
  upsert_processor.(
    PromotionCode,
    &PromotionCode.changeset/2,
    "19100000-0000-4000-8000-00000000a006",
    "promo_phase191_host_unicode",
    %{
      code: "ÉTÉ191",
      coupon_id: coupon.id,
      active: true,
      max_redemptions: 100_000,
      times_redeemed: 1,
      expires_at: days_from_now.(60),
      metadata: %{"phase191_fixture" => "non_ascii"},
      data: %{"phase191_non_ascii_name" => "été"}
    }
  )

_connect_account =
  upsert.(
    Account,
    [stripe_account_id: "acct_phase191_host_boundary"],
    "19100000-0000-4000-8000-00000000a007",
    &Account.changeset/2,
    %{
      stripe_account_id: "acct_phase191_host_boundary",
      owner_type: "Organization",
      owner_id: owner_id,
      type: "express",
      country: "US",
      email: "phase191-connect@example.com",
      charges_enabled: false,
      payouts_enabled: false,
      details_submitted: false,
      requirements: %{"currently_due" => ["external_account"]},
      capabilities: %{"card_payments" => "pending"},
      data: %{"phase191_null_future_requirement" => nil}
    }
  )

_webhook =
  case Repo.get_by(WebhookEvent,
         processor: "stripe",
         processor_event_id: "evt_phase191_host_dead"
       ) do
    nil ->
      %{
        processor: "stripe",
        processor_event_id: "evt_phase191_host_dead",
        type: "invoice.payment_failed",
        livemode: false,
        endpoint: :default,
        raw_body:
          ~s({"id":"evt_phase191_host_dead","type":"invoice.payment_failed","phase191_host":true}),
        received_at: days_ago.(1),
        data: %{
          "id" => "evt_phase191_host_dead",
          "object" => "event",
          "phase191_host" => true,
          "data" => %{
            "object" => %{
              "id" => "in_phase191_host_boundary",
              "customer" => customer.processor_id,
              "subscription" => subscription.processor_id
            }
          }
        }
      }
      |> WebhookEvent.ingest_changeset()
      |> Ecto.Changeset.put_change(:id, "19100000-0000-4000-8000-00000000a008")
      |> Ecto.Changeset.change(%{status: :dead, processed_at: days_ago.(1)})
      |> Repo.insert!()

    existing ->
      existing
  end

_source_event =
  record_event.(
    %{
      type: "phase191.fixture.seeded",
      subject_type: "Phase191Fixture",
      subject_id: customer.id,
      data: %{"namespace" => "phase191_host"}
    },
    "seed-phase191-fixture-seeded",
    days_ago.(1)
  )

_at_risk_sub =
  upsert_processor.(
    Subscription,
    &Subscription.force_status_changeset/2,
    "19100000-0000-4000-8000-00000000a010",
    "sub_phase191_host_at_risk",
    %{
      customer_id: customer.id,
      status: :past_due,
      past_due_since: days_ago.(5),
      dunning_campaign_started_at: days_ago.(5),
      cancel_at_period_end: false,
      current_period_start: days_ago.(25),
      current_period_end: days_from_now.(5),
      lock_version: 1,
      metadata: %{"phase191_fixture" => "at-risk"},
      data: %{"recovery_state" => "phase191_host"}
    }
  )

_one_row_customer =
  upsert_processor.(
    Customer,
    &Customer.changeset/2,
    "19100000-0000-4000-8000-00000000a009",
    "cus_phase191_host_one",
    %{
      owner_type: "Organization",
      owner_id: "19100000-0000-4000-8000-00000000f009",
      name: "Phase 191 One Row Customer",
      email: "phase191-one@example.com",
      metadata: %{"phase191_boundary" => "one-row"},
      data: %{"phase191_index" => 1}
    }
  )

Enum.each(1..26, fn index ->
  padded = String.pad_leading(Integer.to_string(index), 2, "0")
  suffix = String.pad_leading(Integer.to_string(index), 12, "0")

  upsert_processor.(
    Customer,
    &Customer.changeset/2,
    "19100000-0000-4000-8000-#{suffix}",
    "cus_phase191_host_page_#{padded}",
    %{
      owner_type: "Organization",
      owner_id: "19100000-0000-4001-8000-#{suffix}",
      name: "Phase 191 Page Customer #{padded}",
      email: "phase191-page-#{padded}@example.com",
      metadata: %{"phase191_boundary" => "more-than-one-page"},
      data: %{"phase191_index" => index}
    }
  )
end)

:ok
