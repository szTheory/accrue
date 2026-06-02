<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### 1. Domain & Persona
**Decision:** B2B SaaS (e.g., "PingPal" Uptime Monitoring or similar Developer Tool).
**Rationale:** A B2B DevTool naturally features tiered subscriptions (Hobby, Pro, Enterprise), seat-based/metered usage (monitors, SMS alerts), and demonstrates the full suite of Accrue features (Admin UI, Dunning, Invoicing) seamlessly. It aligns perfectly with typical Phoenix live dashboard use cases.

#### 2. Seed Scale & Variety
**Decision:** Hybrid approach: 5-10 curated "Hero" accounts + ~100 random background accounts.
**Rationale:** Hero accounts (e.g., `past-due@example.com`, `enterprise@example.com`) provide predictable, stable fixtures for Playwright E2E tests and manual QA without flakiness. Background accounts (generated) populate the analytics charts, pagination, and MRR funnels so the app doesn't look like a toy. This avoids the footgun of massive seed times while still providing a rich "click-around" experience.

#### 3. Generation Strategy
**Decision:** Hardcode Hero accounts; use `faker` (via standard Ecto patterns) for background accounts.
**Rationale:** Hardcoding Hero accounts ensures Playwright E2E tests have deterministic, rock-solid data. `faker` provides variety for the background accounts without bloating `seeds.exs`. We will use `Repo.insert_all` for the bulk background data to keep `mix ecto.reset` fast and idiomatic.

#### 4. Historical Depth
**Decision:** Seed time-series events (invoices, subscriptions, dunning events) spanning the last 90 days.
**Rationale:** Accrue's analytics windows (7d, 30d, 90d) need historical data to show meaningful trend lines. A flat "today" spike looks broken. We will expand the existing `record_at` backdating technique (bypassing Ecto's `inserted_at` defaults via `Repo.insert_all`) to ensure the dashboard feels "alive" on first boot.

### the agent's Discretion
None explicitly declared in CONTEXT.md (all main items locked).

### Deferred Ideas (OUT OF SCOPE)
None explicitly deferred in CONTEXT.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVD-01 | Define a realistic SaaS cohort persona and JTBD domain for `examples/accrue_host`. | Selected "PingPal" Uptime Monitoring. Defined Hero accounts (Healthy, Past Due, Canceled, Enterprise, Trialing). |
| EVD-02 | Implement rich, realistic database seeds (users, plans, subscriptions, usage) that populate the demo app to immediately demonstrate the Admin UI value. | Established `Faker` integration and `Repo.insert_all` fast-path insertion strategy, plus backdating events for 90-day historical chart data. |
</phase_requirements>

# Phase 163: Realistic Domain & Rich Seeds - Research

**Researched:** 2025-02-04
**Domain:** Elixir/Ecto Database Seeding & Application Persona
**Confidence:** HIGH

## Summary

This phase transforms the `examples/accrue_host` demo from a blank slate into a realistic, lived-in SaaS product. Following the "PingPal" Uptime Monitoring persona, the seed strategy employs a dual-pronged approach. First, 5-10 "Hero" accounts will be deterministically created using the `AccrueHost.Billing.subscribe/2` facade, ensuring all application callbacks and Fake processor states are triggered perfectly for E2E testing. 

Second, to provide the volume necessary to demonstrate Accrue Admin's pagination and analytics, ~100 random background accounts will be generated using `faker`. To avoid the N+1 database connection overhead of looping through application facades, these background accounts will be mapped in-memory using pre-generated Ecto UUIDs and bulk-inserted via `Repo.insert_all/3`. Time-series events (MRR growth, dunning) will be explicitly backdated over a 90-day window to populate the dashboard charts.

**Primary recommendation:** Use `Ecto.UUID.generate/0` to pre-link associations in-memory (User -> Organization -> Customer -> Subscription), then insert them per-table using chunked `Repo.insert_all` to achieve sub-second seeding of 100+ nested accounts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| E2E/Hero Seed Data | API / Backend | Database | Deterministic seeds use the actual application facades (`AccrueHost.Billing.subscribe`) to guarantee behavior parity for Playwright tests. |
| Bulk Background Data | Database | — | Background seeds bypass application layers and use `Repo.insert_all` for raw speed. They do not trigger Fake processor syncs, existing solely to flesh out Admin UI lists. |
| Time-series Analytics | Database | API / Backend | Analytics queries rely directly on `accrue_events` timestamps (`inserted_at`), bypassing `updated_at` (due to SQL triggers). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `faker` | `~> 0.18` | Generates realistic names, emails, and companies. | Standard Elixir library for dummy data. Used by default in most Phoenix generators. |
| `Ecto.Repo` | Core | `insert_all/3` for bulk writes. | Bypasses schema casting and validation for raw speed during `mix ecto.reset`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Repo.insert_all` | `AccrueHost.Billing.subscribe` loop | Looping standard logic ensures 100% data integrity with the Fake processor but causes extreme delays (N+1 inserts per user) during standard `mix ecto.reset`, heavily degrading developer experience. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `faker` | Hex | 10+ yrs | 70M+ | github.com/elixirs/faker | [OK] | Approved |

*Verified package exists on Hex registry via `mix hex.info faker`.*

## Architecture Patterns

### Recommended Project Structure
```
examples/accrue_host/
├── mix.exs                         # Will add {:faker, "~> 0.18", only: [:dev, :test]}
└── priv/repo/
    ├── seeds.exs                   # Main entrypoint, delegates or runs logic
    └── seeds/
        ├── hero_accounts.exs       # (Optional) Extracted PingPal deterministic fixtures
        └── background_data.exs     # (Optional) Extracted faker/insert_all generator
```
*Note: If `seeds.exs` is small enough, both can live inline, but extracting them keeps logic tidy.*

### Pattern 1: Memory-Mapped Associations for `insert_all`
**What:** Generating UUIDs in memory to link `has_many` / `belongs_to` relationships before bulk inserting.
**When to use:** When inserting 100s of nested records (User + Org + Customer + Subscription) to avoid multiple round-trips and returning IDs.
**Example:**
```elixir
now = DateTime.utc_now() |> DateTime.truncate(:second)
password_hash = Bcrypt.hash_pwd_salt("password") # Hash once, reuse for speed

accounts = Enum.map(1..100, fn _ ->
  user_id = Ecto.UUID.generate()
  org_id = Ecto.UUID.generate()
  customer_id = Ecto.UUID.generate()
  sub_id = Ecto.UUID.generate()
  
  user = %{
    id: user_id, 
    email: Faker.Internet.email(), 
    hashed_password: password_hash,
    confirmed_at: now,
    inserted_at: now,
    updated_at: now
  }
  
  org = %{
    id: org_id,
    name: Faker.Company.name(),
    slug: Faker.Internet.slug(),
    owner_user_id: user_id,
    inserted_at: now,
    updated_at: now
  }
  
  customer = %{
    id: customer_id,
    owner_type: "Organization",
    owner_id: org_id,
    processor: "fake",
    processor_id: "cus_#{customer_id}",
    name: org.name,
    email: user.email,
    inserted_at: now,
    updated_at: now
  }
  
  subscription = %{
    id: sub_id,
    customer_id: customer_id,
    processor: "fake",
    processor_id: "sub_#{sub_id}",
    status: :active,
    current_period_start: now,
    current_period_end: DateTime.add(now, 30, :day),
    inserted_at: now,
    updated_at: now
  }
  
  {user, org, customer, subscription}
end)

# Unzip and insert in correct dependency order
{users, orgs, customers, subscriptions} = unzip4(accounts)
Repo.insert_all(User, users, on_conflict: :nothing)
Repo.insert_all(Organization, orgs, on_conflict: :nothing)
Repo.insert_all(Accrue.Billing.Customer, customers, on_conflict: :nothing)
Repo.insert_all(Accrue.Billing.Subscription, subscriptions, on_conflict: :nothing)
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fake names & emails | Hand-rolled lists or random strings (`Enum.random(["A", "B"])`) | `Faker` | Hardcoded lists get repetitive and look fake. Random strings break email validations. |
| Mass Inserts | `Enum.each(list, &Repo.insert!/1)` | `Repo.insert_all/3` | Standard Ecto inserts take ~5-10ms each. Inserting 100 accounts (400 nested rows) takes 2-4 seconds. `insert_all` reduces this to < 50ms. |

## Common Pitfalls

### Pitfall 1: Bypassing Schema Defaults with `insert_all`
**What goes wrong:** Records inserted via `Repo.insert_all` lack timestamps or schema-defined default values (like `lock_version: 1`).
**Why it happens:** `insert_all` bypasses `Ecto.Schema` completely and talks directly to the adapter.
**How to avoid:** Explicitly define `inserted_at`, `updated_at`, `lock_version: 1`, and `id` (if `:binary_id`) in every map passed to `insert_all`.

### Pitfall 2: Ecto Immutability Triggers on Events
**What goes wrong:** Attempting to update `inserted_at` on an event after inserting it throws SQLSTATE `45A01`.
**Why it happens:** Accrue's `accrue_events` table implements a strict `BEFORE UPDATE OR DELETE` Postgres trigger to ensure ledger immutability.
**How to avoid:** For backdated historical seeds, `inserted_at` MUST be provided at the exact moment of INSERT via `Repo.insert_all`. (The current `seeds.exs` already demonstrates this via the `record_at` helper).

### Pitfall 3: Crashing `mix ecto.setup` on Reruns
**What goes wrong:** Re-running seeds without dropping the DB throws unique constraint errors (e.g. duplicate email).
**Why it happens:** `insert_all` does not gracefully fail unless instructed.
**How to avoid:** Always include `on_conflict: :nothing` and a `conflict_target` if applicable, or wrap the generation logic in a check (e.g. `if Repo.aggregate(User, :count) < 10 do ...`).

## Code Examples

### Backdating Analytics Events for MRR
To populate the 30-day and 90-day charts, backdated `subscription.created` events must be inserted with specific MRR values:
```elixir
event = %{
  idempotency_key: "seed-sub-#{sub_id}",
  type: "subscription.created",
  subject_type: "Subscription",
  subject_id: sub_id,
  data: %{
    mrr_value_cents: 1500, # e.g. price_basic amount
    currency: "usd"
  },
  actor_type: "system",
  schema_version: 1,
  inserted_at: Faker.DateTime.backward(90) |> DateTime.truncate(:second)
}

Repo.insert_all(Accrue.Events.Event, [event], 
  on_conflict: :nothing, 
  conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
)
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | Dev/Seeding | ✓ | `~> 1.17` | — |
| `faker` | Seeds | ✗ | `0.18.0` | Planner must add to `mix.exs` |

**Missing dependencies with fallback:**
- `faker`: Needs to be added to `mix.exs` as `{:faker, "~> 0.18", only: [:dev, :test]}`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` (aliases) |
| Quick run command | `mix test` |
| Full suite command | `mix verify.full` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVD-02 | Seeds run cleanly without crashing | smoke | `mix run priv/repo/seeds.exs` | ✅ Yes |
| EVD-02 | Background data populated | e2e | `mix test e2e/` (Playwright) | ✅ Yes |

### Sampling Rate
- **Per task commit:** `mix run priv/repo/seeds.exs` (ensure no constraint crashes).
- **Per wave merge:** `mix verify.full`
- **Phase gate:** Full suite green before `/gsd:verify-work`
