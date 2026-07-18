alias AccrueHost.Repo
import AccrueHost.Seeds.Helpers

now = Accrue.Clock.utc_now()
days_ago = fn days -> DateTime.add(now, -days * 86_400, :second) end
days_from_now = fn days -> DateTime.add(now, days * 86_400, :second) end

ensure_processor_row = fn schema, changeset_fun, lookup, attrs ->
  case Repo.get_by(schema, lookup) do
    nil ->
      struct(schema)
      |> changeset_fun.(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

# OPERATOR / SaaS-admin persona — grants access to the /admin console.
# This is NOT a customer account. It has no org, no subscription, no dunning events.
# The 5 accounts below are customer billing-lifecycle personas (tenant-facing flows only).
# Adding zero dunning events here keeps seeds_idempotency_test.exs "exactly 7" assertion intact.
ensure_demo_admin("admin@example.com")

# 1. HEALTHY demo account (banner-OFF) — subscribed, no dunning anchor.
healthy_user = ensure_demo_user("healthy@example.com")
healthy_org = ensure_demo_org(healthy_user, "Northwind Labs", "healthy-co")
ensure_owner_membership(healthy_org, healthy_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(healthy_org)
       ) do
  {:ok, _healthy_sub} = AccrueHost.Billing.subscribe(healthy_org, "price_basic")
end

# The mounted /billing portal resolves the signed-in user as the customer. Keep
# this B2C-shaped portal state separate from the workspace-owned /app/billing row.
{:ok, healthy_portal_customer} = AccrueHost.Billing.customer_for(healthy_user)

healthy_portal_subscription =
  case AccrueHost.Billing.billing_state_for(healthy_user) do
    {:ok, %{subscription: %Accrue.Billing.Subscription{} = subscription}} ->
      subscription

    {:ok, %{subscription: nil}} ->
      ensure_processor_row.(
        Accrue.Billing.Subscription,
        &Accrue.Billing.Subscription.force_status_changeset/2,
        [processor: "fake", processor_id: "sub_seed_healthy_portal_launch"],
        %{
          customer_id: healthy_portal_customer.id,
          processor: "fake",
          processor_id: "sub_seed_healthy_portal_launch",
          status: :active,
          current_period_start: days_ago.(1),
          current_period_end: days_from_now.(29),
          cancel_at_period_end: false,
          automatic_tax: false,
          metadata: %{"seed_persona" => "healthy_portal"},
          data: %{"portal_seed" => true}
        }
      )
  end

_healthy_portal_subscription_item =
  ensure_processor_row.(
    Accrue.Billing.SubscriptionItem,
    &Accrue.Billing.SubscriptionItem.changeset/2,
    [processor: "fake", processor_id: "si_seed_healthy_portal_launch"],
    %{
      subscription_id: healthy_portal_subscription.id,
      processor: "fake",
      processor_id: "si_seed_healthy_portal_launch",
      price_id: "price_basic",
      processor_plan_id: "price_basic",
      processor_product_id: "prod_fake_price_basic",
      quantity: 1,
      current_period_start: healthy_portal_subscription.current_period_start,
      current_period_end: healthy_portal_subscription.current_period_end,
      metadata: %{"seed_persona" => "healthy_portal"},
      data: %{}
    }
  )

healthy_portal_payment_method =
  ensure_processor_row.(
    Accrue.Billing.PaymentMethod,
    &Accrue.Billing.PaymentMethod.changeset/2,
    [processor: "fake", processor_id: "pm_seed_healthy_portal_default"],
    %{
      customer_id: healthy_portal_customer.id,
      processor: "fake",
      processor_id: "pm_seed_healthy_portal_default",
      type: "card",
      is_default: true,
      fingerprint: "fp_seed_healthy_portal_default",
      card_brand: "Visa",
      card_last4: "4242",
      card_exp_month: 12,
      card_exp_year: 2032,
      exp_month: 12,
      exp_year: 2032,
      metadata: %{"seed_persona" => "healthy_portal"},
      data: %{}
    }
  )

if healthy_portal_customer.default_payment_method_id != healthy_portal_payment_method.id do
  healthy_portal_customer
  |> Accrue.Billing.Customer.changeset(%{
    default_payment_method_id: healthy_portal_payment_method.id
  })
  |> Repo.update!()
end

_healthy_portal_invoice =
  ensure_processor_row.(
    Accrue.Billing.Invoice,
    &Accrue.Billing.Invoice.force_status_changeset/2,
    [processor: "fake", processor_id: "in_seed_healthy_portal_launch_paid"],
    %{
      customer_id: healthy_portal_customer.id,
      subscription_id: healthy_portal_subscription.id,
      processor: "fake",
      processor_id: "in_seed_healthy_portal_launch_paid",
      status: :paid,
      number: "PORTAL-LAUNCH-001",
      currency: "usd",
      subtotal_minor: 1_500,
      tax_minor: 0,
      total_minor: 1_500,
      total_cents: 1_500,
      amount_due_minor: 1_500,
      amount_paid_minor: 1_500,
      amount_remaining_minor: 0,
      hosted_url: "http://accrue.localhost/billing/invoices/PORTAL-LAUNCH-001",
      pdf_url: nil,
      collection_method: "charge_automatically",
      billing_reason: "subscription_cycle",
      finalized_at: days_ago.(1),
      paid_at: days_ago.(1),
      period_start: days_ago.(31),
      period_end: days_ago.(1),
      due_date: days_from_now.(29),
      metadata: %{"seed_persona" => "healthy_portal"},
      data: %{"portal_seed" => true}
    }
  )

# 2. PAST-DUE demo account (banner-ON) — subscribed, then flipped into a dunning campaign
past_due_user = ensure_demo_user("past-due@example.com")
past_due_org = ensure_demo_org(past_due_user, "Tidewater Systems", "past-due-co")
ensure_owner_membership(past_due_org, past_due_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(past_due_org)
       ) do
  {:ok, _past_due_sub} = AccrueHost.Billing.subscribe(past_due_org, "price_basic")
end

{:ok, %{subscription: past_due_subscription}} = AccrueHost.Billing.billing_state_for(past_due_org)

if is_nil(past_due_subscription.dunning_campaign_started_at) do
  past_due_subscription
  |> Accrue.Billing.Subscription.force_status_changeset(%{
    status: :past_due,
    past_due_since: now,
    dunning_campaign_started_at: now
  })
  |> Repo.update!()
end

# 3. CANCELED demo account
canceled_user = ensure_demo_user("canceled@example.com")
canceled_org = ensure_demo_org(canceled_user, "Redwood Studio", "canceled-co")
ensure_owner_membership(canceled_org, canceled_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(canceled_org)
       ) do
  {:ok, _canceled_sub} = AccrueHost.Billing.subscribe(canceled_org, "price_basic")
end

{:ok, %{subscription: canceled_subscription}} = AccrueHost.Billing.billing_state_for(canceled_org)

if canceled_subscription.status != :canceled do
  canceled_subscription
  |> Accrue.Billing.Subscription.force_status_changeset(%{
    status: :canceled,
    canceled_at: now
  })
  |> Repo.update!()
end

# 4. ENTERPRISE demo account
enterprise_user = ensure_demo_user("enterprise@example.com")
enterprise_org = ensure_demo_org(enterprise_user, "Meridian Group", "enterprise-co")
ensure_owner_membership(enterprise_org, enterprise_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(enterprise_org)
       ) do
  # The enterprise persona is the "Head of Engineering" — put it on the catalog Scale plan.
  {:ok, _enterprise_sub} = AccrueHost.Billing.subscribe(enterprise_org, "price_metered")
end

# 5. TRIALING demo account
trialing_user = ensure_demo_user("trialing@example.com")
trialing_org = ensure_demo_org(trialing_user, "Pilot Works", "trialing-co")
ensure_owner_membership(trialing_org, trialing_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(trialing_org)
       ) do
  {:ok, sub} = AccrueHost.Billing.subscribe(trialing_org, "price_basic")

  sub
  |> Accrue.Billing.Subscription.force_status_changeset(%{
    status: :trialing,
    trial_start: now,
    trial_end: DateTime.add(now, 14, :day)
  })
  |> Repo.update!()
end

# Insert deterministic Dunning events for 7d window (Recovered USD)
sub_7d = past_due_subscription.id
anchor_7d = DateTime.to_iso8601(days_ago.(5))

record_at(
  %{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d}
  },
  "seed-dunning-7d-campaign_started",
  days_ago.(5)
)

record_at(
  %{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d}
  },
  "seed-dunning-7d-step_sent",
  days_ago.(4)
)

record_at(
  %{
    type: "dunning.recovered",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d, mrr_value_cents: 12000, currency: "usd"}
  },
  "seed-dunning-7d-recovered",
  days_ago.(3)
)

# Insert deterministic Dunning events for 30d window (Exhausted JPY)
sub_30d = canceled_subscription.id
anchor_30d = DateTime.to_iso8601(days_ago.(25))

record_at(
  %{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub_30d,
    data: %{campaign_anchor: anchor_30d}
  },
  "seed-dunning-30d-campaign_started",
  days_ago.(25)
)

record_at(
  %{
    type: "dunning.exhausted",
    subject_type: "Subscription",
    subject_id: sub_30d,
    data: %{campaign_anchor: anchor_30d, mrr_value_cents: 30000, currency: "jpy"}
  },
  "seed-dunning-30d-exhausted",
  days_ago.(15)
)

# Insert deterministic Dunning events for Active (90d window)
sub_90d = past_due_subscription.id
anchor_90d = DateTime.to_iso8601(days_ago.(60))

record_at(
  %{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub_90d,
    data: %{campaign_anchor: anchor_90d}
  },
  "seed-dunning-90d-campaign_started",
  days_ago.(60)
)

record_at(
  %{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub_90d,
    data: %{campaign_anchor: anchor_90d}
  },
  "seed-dunning-90d-step_sent",
  days_ago.(50)
)
