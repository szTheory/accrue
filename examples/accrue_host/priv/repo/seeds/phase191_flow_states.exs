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

# Realistic fictional book-of-business for the 26 page customers (Part C).
#
# Every stable identifier is preserved EXACTLY — id, owner_id, and the
# `cus_phase191_host_page_NN` processor_id (asserted + counted by the host
# seed tests). Only name/email/owner_type/metadata/data and the NEW linked
# payment-method / subscription / invoice / charge rows are realistic.
#
# IDEMPOTENCY: every new row routes through `upsert_processor` keyed on a
# deterministic processor_id derived from the page index, so re-seeding is a
# no-op. Faker output is non-deterministic, but the idempotency test asserts
# COUNTS (not names) and `upsert_processor` keeps first-insert values stable.
#
# Card brands cycle deterministically for visual variety.
card_brands = {"Visa", "Mastercard", "American Express", "Discover"}

# Owner-type variety so the /admin/customers owner-type filter has real options.
owner_type_for = fn index ->
  cond do
    rem(index, 9) == 0 -> "Team"
    rem(index, 5) == 0 -> "Workspace"
    rem(index, 3) == 0 -> "User"
    true -> "Organization"
  end
end

# A page customer gets a payment method on file UNLESS rem(index, 7) == 0,
# leaving a few intentionally "Missing" so the column shows both states.
# (indices 7, 14, 21 → 3 missing, 23 with a PM on file.)
page_has_payment_method? = fn index -> rem(index, 7) != 0 end

# Bounded linked billing graph: the first N page customers each get a coherent
# subscription + invoice + charge so their detail pages, KPIs, and signals
# populate. N kept small to keep reset time bounded (T-knk-03).
linked_graph_count = 10
page_has_linked_graph? = fn index -> index <= linked_graph_count end

Enum.each(1..26, fn index ->
  padded = String.pad_leading(Integer.to_string(index), 2, "0")
  suffix = String.pad_leading(Integer.to_string(index), 12, "0")

  owner_type = owner_type_for.(index)

  display_name =
    case owner_type do
      "User" -> Faker.Person.name()
      _ -> Faker.Company.name()
    end

  customer_id = "19100000-0000-4000-8000-#{suffix}"

  page_customer =
    upsert_processor.(
      Customer,
      &Customer.changeset/2,
      customer_id,
      "cus_phase191_host_page_#{padded}",
      %{
        owner_type: owner_type,
        owner_id: "19100000-0000-4001-8000-#{suffix}",
        name: display_name,
        email: Faker.Internet.email(),
        metadata: %{
          "phase191_boundary" => "more-than-one-page",
          "phase191_persona" => "demo-book-of-business"
        },
        data: %{"phase191_index" => index}
      }
    )

  # --- Payment method on file (drives the "With payment method" KPI) --------
  if page_has_payment_method?.(index) do
    brand = elem(card_brands, rem(index, tuple_size(card_brands)))
    last4 = padded <> padded
    pm_id = "19100000-0000-4002-8000-#{suffix}"

    payment_method =
      upsert_processor.(
        Accrue.Billing.PaymentMethod,
        &Accrue.Billing.PaymentMethod.changeset/2,
        pm_id,
        "pm_phase191_host_page_#{padded}",
        %{
          customer_id: page_customer.id,
          type: "card",
          is_default: true,
          fingerprint: "fp_phase191_host_page_#{padded}",
          card_brand: brand,
          card_last4: last4,
          card_exp_month: rem(index, 12) + 1,
          card_exp_year: 2030 + rem(index, 4),
          exp_month: rem(index, 12) + 1,
          exp_year: 2030 + rem(index, 4),
          metadata: %{"phase191_persona" => "demo-book-of-business"},
          data: %{"phase191_index" => index}
        }
      )

    if page_customer.default_payment_method_id != payment_method.id do
      page_customer
      |> Customer.changeset(%{default_payment_method_id: payment_method.id})
      |> Repo.update!()
    end
  end

  # --- Coherent linked subscription + invoice + charge (bounded subset) ------
  #
  # Status / currency mix across the first 10: mostly active USD, a couple
  # trialing, one past_due (with a dunning anchor so the recovery signal
  # lights up), and one JPY zero-decimal invoice for currency variety.
  if page_has_linked_graph?.(index) do
    {sub_status, charge_status, invoice_status, currency} =
      cond do
        index == 3 -> {:past_due, "failed", :open, "usd"}
        index == 6 -> {:trialing, "succeeded", :open, "usd"}
        index == 9 -> {:trialing, "succeeded", :paid, "usd"}
        index == 10 -> {:active, "succeeded", :paid, "jpy"}
        true -> {:active, "succeeded", :paid, "usd"}
      end

    # Internally-consistent amounts. JPY is zero-decimal (no ×100).
    amount_minor =
      case currency do
        "jpy" -> 50_000
        _ -> 4900 + index * 100
      end

    sub_attrs = %{
      customer_id: page_customer.id,
      status: sub_status,
      current_period_start: days_ago.(rem(index, 20) + 1),
      current_period_end: days_from_now.(28 - rem(index, 10)),
      cancel_at_period_end: false,
      lock_version: 1,
      metadata: %{"phase191_persona" => "demo-book-of-business"},
      data: %{"phase191_index" => index}
    }

    sub_attrs =
      if sub_status == :past_due do
        Map.merge(sub_attrs, %{
          past_due_since: days_ago.(5),
          dunning_campaign_started_at: days_ago.(5)
        })
      else
        sub_attrs
      end

    sub_attrs =
      if sub_status == :trialing do
        Map.merge(sub_attrs, %{
          trial_start: days_ago.(3),
          trial_end: days_from_now.(11)
        })
      else
        sub_attrs
      end

    sub_changeset_fun =
      if sub_status == :active do
        &Subscription.changeset/2
      else
        &Subscription.force_status_changeset/2
      end

    page_subscription =
      upsert_processor.(
        Subscription,
        sub_changeset_fun,
        "19100000-0000-4003-8000-#{suffix}",
        "sub_phase191_host_page_#{padded}",
        sub_attrs
      )

    {amount_paid_minor, amount_remaining_minor, paid_at} =
      case invoice_status do
        :paid -> {amount_minor, 0, days_ago.(rem(index, 10) + 1)}
        _ -> {0, amount_minor, nil}
      end

    _page_invoice =
      upsert_processor.(
        Invoice,
        &Invoice.force_status_changeset/2,
        "19100000-0000-4004-8000-#{suffix}",
        "in_phase191_host_page_#{padded}",
        %{
          customer_id: page_customer.id,
          subscription_id: page_subscription.id,
          status: invoice_status,
          number: "PHASE191-PAGE-#{padded}",
          currency: currency,
          subtotal_minor: amount_minor,
          tax_minor: 0,
          total_minor: amount_minor,
          total_cents: amount_minor,
          amount_due_minor: amount_minor,
          amount_paid_minor: amount_paid_minor,
          amount_remaining_minor: amount_remaining_minor,
          collection_method: "charge_automatically",
          billing_reason: "subscription_cycle",
          finalized_at: days_ago.(rem(index, 10) + 2),
          paid_at: paid_at,
          period_start: days_ago.(31),
          period_end: days_ago.(1),
          metadata: %{"phase191_persona" => "demo-book-of-business"},
          data: %{"phase191_index" => index}
        }
      )

    _page_charge =
      upsert_processor.(
        Charge,
        &Charge.changeset/2,
        "19100000-0000-4005-8000-#{suffix}",
        "ch_phase191_host_page_#{padded}",
        %{
          customer_id: page_customer.id,
          subscription_id: page_subscription.id,
          status: charge_status,
          currency: currency,
          amount_cents: amount_minor,
          metadata: %{"phase191_persona" => "demo-book-of-business"},
          data: %{"phase191_index" => index}
        }
      )
  end
end)

# Fixture-count totals AFTER this loop (for seeds_idempotency_test.exs):
#   subscriptions sub_phase191_host%: 2 existing (active + at_risk) + 10 page = 12
#   invoices      in_phase191_host%:  1 existing (boundary)        + 10 page = 11
#   charges       ch_phase191_host%:  1 existing (boundary)        + 10 page = 11
#   payment_methods pm_phase191_host_page%: 23 (NOT asserted by any test)
#   customers cus_phase191_host%: unchanged at 28

:ok
