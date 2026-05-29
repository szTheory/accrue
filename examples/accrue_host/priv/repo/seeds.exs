# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AccrueHost.Repo.insert!(%AccrueHost.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AccrueHost.Accounts
alias AccrueHost.Accounts.OrganizationMembership
alias AccrueHost.Accounts.Scope
alias AccrueHost.Accounts.User
alias AccrueHost.Organizations
alias AccrueHost.Repo

now = Accrue.Clock.utc_now()
now_iso = DateTime.to_iso8601(now)

# ---------------------------------------------------------------------------
# Demo accounts for the in-app dunning banner (BAN-04).
#
# A reviewer can log in side-by-side to see the conditional banner render:
#
#   healthy@example.com   / accrue-demo-password   -> NO banner   (healthy org)
#   past-due@example.com  / accrue-demo-password    -> banner shown (past-due / dunning)
#
# Both accounts are seeded idempotently (guarded by Repo.get_by on email) so
# `mix ecto.reset` / re-running this script never crashes on a unique-email or
# unique-slug constraint. The dunning ledger events seeded further down are
# also idempotent via stable `idempotency_key`s, so re-running without a DB
# reset does not double-count the dashboard MRR roll-ups. Demo-only
# credentials — never a production recipe.
# ---------------------------------------------------------------------------

demo_password = "accrue-demo-password"

ensure_demo_user = fn email ->
  case Repo.get_by(User, email: email) do
    %User{} = user ->
      user

    nil ->
      {:ok, user} = Accounts.register_user(%{email: email})

      # Password-login requires a confirmed user — confirm + set a password so a
      # reviewer can actually log in through the UI.
      {:ok, user} =
        user
        |> User.confirm_changeset()
        |> Repo.update()

      {:ok, {user, _expired_tokens}} =
        Accounts.update_user_password(user, %{password: demo_password})

      user
  end
end

ensure_demo_org = fn owner, name, slug ->
  case Repo.get_by(AccrueHost.Accounts.Organization, slug: slug) do
    %AccrueHost.Accounts.Organization{} = organization ->
      organization

    nil ->
      {:ok, organization} =
        Organizations.create_organization(Scope.for_user(owner), %{name: name, slug: slug})

      organization
  end
end

ensure_owner_membership = fn organization, user ->
  case Repo.get_by(OrganizationMembership,
         organization_id: organization.id,
         user_id: user.id
       ) do
    %OrganizationMembership{} = membership ->
      membership

    nil ->
      {:ok, membership} =
        %OrganizationMembership{}
        |> OrganizationMembership.changeset(%{
          role: :owner,
          organization_id: organization.id,
          user_id: user.id
        })
        |> Repo.insert()

      membership
  end
end

# 1. HEALTHY demo account (banner-OFF) — subscribed, no dunning anchor.
healthy_user = ensure_demo_user.("healthy@example.com")
healthy_org = ensure_demo_org.(healthy_user, "Healthy Co", "healthy-co")
ensure_owner_membership.(healthy_org, healthy_user)

{:ok, _healthy_state} = AccrueHost.Billing.billing_state_for(healthy_org)

unless match?(
         {:ok, %{subscription: %Accrue.Billing.Subscription{}}},
         AccrueHost.Billing.billing_state_for(healthy_org)
       ) do
  {:ok, _healthy_sub} = AccrueHost.Billing.subscribe(healthy_org, "price_basic")
end

# 2. PAST-DUE demo account (banner-ON) — subscribed, then flipped into a
#    dunning campaign by writing the single anchor column (Fake processor only).
past_due_user = ensure_demo_user.("past-due@example.com")
past_due_org = ensure_demo_org.(past_due_user, "Past Due Co", "past-due-co")
ensure_owner_membership.(past_due_org, past_due_user)

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

days_ago = fn days ->
  DateTime.add(now, -days * 86_400, :second)
end

# The recovery analytics window on `inserted_at`, so seeded events must land at
# a back-dated `inserted_at` to populate distinct analytics windows. We CANNOT
# do this via `Events.record/1` + `Repo.update_all`: `accrue_events` carries a
# `BEFORE UPDATE OR DELETE` immutability trigger (the tamper-evident ledger
# invariant) that raises SQLSTATE `45A01` on any UPDATE — so back-dating after
# insert crashes `mix ecto.reset`. INSERT is permitted, so we set `inserted_at`
# at insert time via `Repo.insert_all/3` against the `Event` schema (which
# dumps `data` to jsonb and casts the timestamp). We replicate the defaults
# `Accrue.Events.normalize/1` would apply (`actor_type: "system"`,
# `schema_version: 1`, `data: %{}`).
# Each call passes a stable, deterministic `idempotency_key` (independent of
# the random per-run `subject_id`) so re-running this script — e.g. without a
# `mix ecto.reset` — collapses to a no-op via the same `on_conflict: :nothing`
# partial-unique conflict target `Accrue.Events.insert_opts/1` uses, rather
# than appending a fresh duplicate set of dunning events (which would inflate
# the dashboard's Recovered/Exhausted MRR roll-ups).
record_at = fn attrs, idempotency_key, at ->
  row =
    attrs
    |> Map.put(:idempotency_key, idempotency_key)
    |> Map.put(:inserted_at, at)
    |> Map.put_new(:actor_type, "system")
    |> Map.put_new(:schema_version, 1)
    |> Map.put_new(:data, %{})

  {_count, _} =
    Repo.insert_all(Accrue.Events.Event, [row],
      on_conflict: :nothing,
      conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
    )

  :ok
end

# NOTE: `sub_7d` / `sub_30d` / `sub_90d` below are roll-up-only fixtures —
# freshly generated UUIDs that intentionally do NOT correspond to rows in
# `accrue_subscriptions`. They drive the MRR roll-up analytics
# (`recovered_vs_lost_mrr/1`), which read events by `type` + `currency` only.
# The sibling At-Risk analytics (`Accrue.Analytics.Dunning`, which joins
# `accrue_subscriptions` by `subject_id`) will therefore find nothing for
# these IDs — the At-Risk table is intentionally empty for these fixtures.
# The real `past_due_subscription` seeded above is the only subscription with
# a live dunning campaign.

# Insert deterministic Dunning events for 7d window (Recovered USD)
sub_7d = Ecto.UUID.generate()
anchor_7d = DateTime.to_iso8601(days_ago.(5))

record_at.(
  %{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d}
  },
  "seed-dunning-7d-campaign_started",
  days_ago.(5)
)

record_at.(
  %{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d}
  },
  "seed-dunning-7d-step_sent",
  days_ago.(4)
)

record_at.(
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

record_at.(
  %{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub_30d,
    data: %{campaign_anchor: anchor_30d}
  },
  "seed-dunning-30d-campaign_started",
  days_ago.(25)
)

record_at.(
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

record_at.(
  %{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub_90d,
    data: %{campaign_anchor: anchor_90d}
  },
  "seed-dunning-90d-campaign_started",
  days_ago.(60)
)

record_at.(
  %{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub_90d,
    data: %{campaign_anchor: anchor_90d}
  },
  "seed-dunning-90d-step_sent",
  days_ago.(50)
)
