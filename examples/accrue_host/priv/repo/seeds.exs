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

alias Accrue.Events
alias AccrueHost.Accounts
alias AccrueHost.Accounts.OrganizationMembership
alias AccrueHost.Accounts.Scope
alias AccrueHost.Accounts.User
alias AccrueHost.Organizations
alias AccrueHost.Repo

import Ecto.Query, only: [from: 2]

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
# unique-slug constraint. Demo-only credentials — never a production recipe.
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

# `Accrue.Events.record/1` has no `timestamp` (or `inserted_at`) field on the
# event schema — `inserted_at` is `read_after_writes` and set by the DB at
# insert, and it is not in the changeset's cast fields. Passing `timestamp:`
# is silently dropped, collapsing every event to `now()`. The recovery
# analytics window on `inserted_at`, so we record the event and then
# explicitly back-date `inserted_at` via `Repo.update_all` to land the event
# in its intended analytics window.
record_at = fn attrs, at ->
  {:ok, %Accrue.Events.Event{id: id}} = Events.record(attrs)

  Repo.update_all(
    from(e in Accrue.Events.Event, where: e.id == ^id),
    set: [inserted_at: at]
  )

  id
end

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
  days_ago.(5)
)

record_at.(
  %{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d}
  },
  days_ago.(4)
)

record_at.(
  %{
    type: "dunning.recovered",
    subject_type: "Subscription",
    subject_id: sub_7d,
    data: %{campaign_anchor: anchor_7d, mrr_value_cents: 12000, currency: "usd"}
  },
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
  days_ago.(25)
)

record_at.(
  %{
    type: "dunning.exhausted",
    subject_type: "Subscription",
    subject_id: sub_30d,
    data: %{campaign_anchor: anchor_30d, mrr_value_cents: 30000, currency: "jpy"}
  },
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
  days_ago.(60)
)

record_at.(
  %{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub_90d,
    data: %{campaign_anchor: anchor_90d}
  },
  days_ago.(50)
)
