alias AccrueHost.Repo
import AccrueHost.Seeds.Helpers

now = Accrue.Clock.utc_now()
days_ago = fn days -> DateTime.add(now, -days * 86_400, :second) end

# 1. HEALTHY demo account (banner-OFF) — subscribed, no dunning anchor.
healthy_user = ensure_demo_user("healthy@example.com")
healthy_org = ensure_demo_org(healthy_user, "Healthy Co", "healthy-co")
ensure_owner_membership(healthy_org, healthy_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(healthy_org)
       ) do
  {:ok, _healthy_sub} = AccrueHost.Billing.subscribe(healthy_org, "price_basic")
end

# 2. PAST-DUE demo account (banner-ON) — subscribed, then flipped into a dunning campaign
past_due_user = ensure_demo_user("past-due@example.com")
past_due_org = ensure_demo_org(past_due_user, "Past Due Co", "past-due-co")
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
canceled_org = ensure_demo_org(canceled_user, "Canceled Co", "canceled-co")
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
enterprise_org = ensure_demo_org(enterprise_user, "Enterprise Co", "enterprise-co")
ensure_owner_membership(enterprise_org, enterprise_user)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(enterprise_org)
       ) do
  # assuming "price_premium" or similar exists, fallback to basic if needed.
  # Let's use "price_premium" for variety if it's supported by the system, if not, we can use price_basic.
  {:ok, _enterprise_sub} = AccrueHost.Billing.subscribe(enterprise_org, "price_premium")
end

# 5. TRIALING demo account
trialing_user = ensure_demo_user("trialing@example.com")
trialing_org = ensure_demo_org(trialing_user, "Trialing Co", "trialing-co")
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
sub_7d = Ecto.UUID.generate()
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
sub_30d = Ecto.UUID.generate()
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
sub_90d = Ecto.UUID.generate()
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
