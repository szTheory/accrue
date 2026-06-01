alias AccrueHost.Repo
alias AccrueHost.Accounts.User
alias AccrueHost.Accounts.Organization
alias AccrueHost.Accounts.OrganizationMembership
import AccrueHost.Seeds.Helpers

# Create ~100 background accounts
accounts_count = 100

password_hash = Bcrypt.hash_pwd_salt("password")

accounts = Enum.map(1..accounts_count, fn _ ->
  user_id = Ecto.UUID.generate()
  org_id = Ecto.UUID.generate()
  membership_id = Ecto.UUID.generate()
  customer_id = Ecto.UUID.generate()
  sub_id = Ecto.UUID.generate()

  # Backdate the creation to simulate 90 days of history
  created_at_usec =
    Faker.DateTime.backward(90)
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.truncate(:microsecond)
    
  created_at = DateTime.truncate(created_at_usec, :second)

  user = %{
    id: user_id,
    email: Faker.Internet.email(),
    hashed_password: password_hash,
    confirmed_at: created_at,
    inserted_at: created_at,
    updated_at: created_at
  }

  org = %{
    id: org_id,
    name: Faker.Company.name(),
    slug: Faker.Internet.slug() <> "-" <> String.slice(Ecto.UUID.generate(), 0, 8),
    owner_user_id: user_id,
    personal: false,
    inserted_at: created_at,
    updated_at: created_at
  }

  membership = %{
    id: membership_id,
    organization_id: org_id,
    user_id: user_id,
    role: :owner,
    inserted_at: created_at,
    updated_at: created_at
  }

  customer = %{
    id: customer_id,
    owner_type: "Organization",
    owner_id: org_id,
    processor: "fake",
    processor_id: "cus_#{customer_id}",
    name: org.name,
    email: user.email,
    lock_version: 1,
    inserted_at: created_at_usec,
    updated_at: created_at_usec
  }

  subscription = %{
    id: sub_id,
    customer_id: customer_id,
    processor: "fake",
    processor_id: "sub_#{sub_id}",
    status: :active,
    current_period_start: created_at_usec,
    current_period_end: DateTime.add(created_at_usec, 30, :day),
    lock_version: 1,
    inserted_at: created_at_usec,
    updated_at: created_at_usec
  }

  event = %{
    type: "subscription.created",
    subject_type: "Subscription",
    subject_id: sub_id,
    data: %{
      mrr_value_cents: Enum.random([1200, 2400, 4900, 9900]),
      currency: "usd"
    },
    idempotency_key: "seed-bg-sub-#{sub_id}",
    actor_type: "system",
    schema_version: 1,
    inserted_at: created_at_usec
  }

  {user, org, membership, customer, subscription, event}
end)

users = Enum.map(accounts, &elem(&1, 0))
orgs = Enum.map(accounts, &elem(&1, 1))
memberships = Enum.map(accounts, &elem(&1, 2))
customers = Enum.map(accounts, &elem(&1, 3))
subscriptions = Enum.map(accounts, &elem(&1, 4))
events = Enum.map(accounts, &elem(&1, 5))

# We use chunk_every to insert in batches just to be safe
Enum.chunk_every(users, 500) |> Enum.each(&Repo.insert_all(User, &1, on_conflict: :nothing))
Enum.chunk_every(orgs, 500) |> Enum.each(&Repo.insert_all(Organization, &1, on_conflict: :nothing))
Enum.chunk_every(memberships, 500) |> Enum.each(&Repo.insert_all(OrganizationMembership, &1, on_conflict: :nothing))
Enum.chunk_every(customers, 500) |> Enum.each(&Repo.insert_all(Accrue.Billing.Customer, &1, on_conflict: :nothing))
Enum.chunk_every(subscriptions, 500) |> Enum.each(&Repo.insert_all(Accrue.Billing.Subscription, &1, on_conflict: :nothing))

# Insert events backdated for time-series charts
Enum.chunk_every(events, 500) |> Enum.each(&Repo.insert_all(Accrue.Events.Event, &1, on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}))
